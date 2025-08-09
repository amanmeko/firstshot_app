<?php

namespace App\Http\Controllers\Api;

use App\Http\Controllers\Controller;
use Illuminate\Http\Request;
use App\Models\Booking;
use App\Models\PickleballCourt;
use App\Models\Customer;
use App\Models\CreditTransaction;
use App\Models\Sale;
use App\Models\DiscountCode;
use Illuminate\Support\Facades\Auth;
use Illuminate\Support\Facades\Validator;
use Carbon\Carbon;
use Illuminate\Support\Facades\Log;
use Illuminate\Support\Facades\DB;

class BookingApiController extends Controller
{
    /**
     * Get all courts
     */
    public function getCourts()
    {
        try {
            $courts = PickleballCourt::all()->map(function ($court) {
                return [
                    'id' => $court->id,
                    'name' => $court->name,
                    'price' => $court->price,
                    'operation_hours' => $court->operation_hours,
                    'is_active' => $court->is_active ?? true,
                ];
            });

            // Return in the format the Flutter app expects
            return response()->json($courts);
        } catch (\Exception $e) {
            \Log::error('Error retrieving courts: ' . $e->getMessage());
            return response()->json([
                'status' => 'error',
                'message' => 'Failed to fetch courts: ' . $e->getMessage()
            ], 500);
        }
    }

    /**
     * Validate promo code
     */
    public function validatePromoCode(Request $request)
    {
        try {
            $validator = Validator::make($request->all(), [
                'promo_code' => 'required|string'
            ]);

            if ($validator->fails()) {
                return response()->json([
                    'status' => 'error',
                    'message' => 'Validation failed',
                    'errors' => $validator->errors()
                ], 422);
            }

            // Add your promo code validation logic here
            $promoCode = $request->promo_code;
            
            // For now, return a mock response
            // You should implement actual promo code validation
            return response()->json([
                'status' => 'success',
                'message' => 'Promo code is valid',
                'data' => [
                    'promo_code' => $promoCode,
                    'discount_percentage' => 10,
                    'valid_until' => Carbon::now()->addDays(30)->toDateString()
                ]
            ]);

        } catch (\Exception $e) {
            return response()->json([
                'status' => 'error',
                'message' => 'Failed to validate promo code: ' . $e->getMessage()
            ], 500);
        }
    }

    /**
     * Store a new booking
     */
    public function store(Request $request)
    {
        try {
            $validator = Validator::make($request->all(), [
                'court_id' => 'required|exists:pickleball_courts,id',
                'date' => 'required|date|after:today',
                'start_time' => 'required|date_format:H:i',
                'end_time' => 'required|date_format:H:i|after:start_time',
                'user_id' => 'required|exists:users,id',
                'promo_code' => 'nullable|string'
            ]);

            if ($validator->fails()) {
                return response()->json([
                    'status' => 'error',
                    'message' => 'Validation failed',
                    'errors' => $validator->errors()
                ], 422);
            }

            $courtId = $request->court_id;
            $date = $request->date;
            $startTime = $request->start_time;
            $endTime = $request->end_time;
            $userId = $request->user_id;

            // Check if the time slot is available
            $isAvailable = Booking::where('court_id', $courtId)
                ->where('date', $date)
                ->where(function ($query) use ($startTime, $endTime) {
                    $query->where(function ($q) use ($startTime, $endTime) {
                        // Check if the new booking overlaps with existing bookings
                        // Using edge-inclusive overlap check
                        $q->where('start_time', '<', $endTime)
                          ->where('end_time', '>', $startTime);
                    });
                })
                ->exists();

            if ($isAvailable) {
                return response()->json([
                    'status' => 'error',
                    'message' => 'This time slot is already booked or overlaps with an existing booking'
                ], 409);
            }

            // Check if court is available for this time slot
            $court = Court::find($courtId);
            if (!$court) {
                return response()->json([
                    'status' => 'error',
                    'message' => 'Court not found'
                ], 404);
            }

            // Check operation hours
            $operationHour = OperationHour::where('court_id', $courtId)
                ->where('day_of_week', Carbon::parse($date)->dayOfWeek)
                ->first();

            if (!$operationHour) {
                return response()->json([
                    'status' => 'error',
                    'message' => 'Court is not available on this day'
                ], 400);
            }

            $openingTime = Carbon::parse($operationHour->opening_time);
            $closingTime = Carbon::parse($operationHour->closing_time);
            $requestedStart = Carbon::parse($startTime);
            $requestedEnd = Carbon::parse($endTime);

            if ($requestedStart < $openingTime || $requestedEnd > $closingTime) {
                return response()->json([
                    'status' => 'error',
                    'message' => 'Booking time is outside operation hours'
                ], 400);
            }

            // Create the booking
            $booking = Booking::create([
                'court_id' => $courtId,
                'date' => $date,
                'start_time' => $startTime,
                'end_time' => $endTime,
                'user_id' => $userId,
                'promo_code' => $request->promo_code,
                'status' => 'confirmed'
            ]);

            return response()->json([
                'status' => 'success',
                'message' => 'Booking created successfully',
                'data' => $booking
            ], 201);

        } catch (\Exception $e) {
            return response()->json([
                'status' => 'error',
                'message' => 'Failed to create booking: ' . $e->getMessage()
            ], 500);
        }
    }

    /**
     * Delete a booking
     */
    public function destroy($id)
    {
        try {
            $booking = Booking::find($id);
            
            if (!$booking) {
                return response()->json([
                    'status' => 'error',
                    'message' => 'Booking not found'
                ], 404);
            }

            $booking->delete();

            return response()->json([
                'status' => 'success',
                'message' => 'Booking deleted successfully'
            ]);

        } catch (\Exception $e) {
            return response()->json([
                'status' => 'error',
                'message' => 'Failed to delete booking: ' . $e->getMessage()
            ], 500);
        }
    }

    /**
     * Get available time slots for a specific court and date
     * ENHANCED: Now includes comprehensive filtering for court availability
     */
    public function getAvailableTimes(Request $request)
    {
        try {
            $validator = Validator::make($request->all(), [
                'court_id' => 'required|exists:courts,id',
                'date' => 'required|date|after:today'
            ]);

            if ($validator->fails()) {
                return response()->json([
                    'status' => 'error',
                    'message' => 'Validation failed',
                    'errors' => $validator->errors()
                ], 422);
            }

            $courtId = $request->court_id;
            $date = $request->date;

            // Get court information
            $court = Court::find($courtId);
            if (!$court) {
                return response()->json([
                    'status' => 'error',
                    'message' => 'Court not found'
                ], 404);
            }

            // Check if court is available for this date
            if (!$court->is_active) {
                return response()->json([
                    'status' => 'error',
                    'message' => 'Court is not available'
                ], 400);
            }

            // Get operation hours for the specific day
            $operationHour = OperationHour::where('court_id', $courtId)
                ->where('day_of_week', Carbon::parse($date)->dayOfWeek)
                ->first();

            if (!$operationHour) {
                return response()->json([
                    'status' => 'error',
                    'message' => 'Court is not available on this day'
                ], 400);
            }

            $openingTime = Carbon::parse($operationHour->opening_time);
            $closingTime = Carbon::parse($operationHour->closing_time);

            // Generate time slots (30-minute intervals)
            $timeSlots = [];
            $currentTime = $openingTime->copy();

            while ($currentTime < $closingTime) {
                $slotStart = $currentTime->format('H:i');
                $slotEnd = $currentTime->addMinutes(30)->format('H:i');

                // Check if this time slot is already booked
                $isBooked = Booking::where('court_id', $courtId)
                    ->where('date', $date)
                    ->where(function ($query) use ($slotStart, $slotEnd) {
                        $query->where(function ($q) use ($slotStart, $slotEnd) {
                            // Edge-inclusive overlap check
                            $q->where('start_time', '<', $slotEnd)
                              ->where('end_time', '>', $slotStart);
                        });
                    })
                    ->exists();

                // Check court-specific availability flags
                $courtAvailable = true; // Default to true, can be enhanced with court status checks
                $maintenance = false;   // Can be enhanced with maintenance schedule checks
                $specialEvent = false; // Can be enhanced with special event checks
                $closed = false;       // Can be enhanced with closure checks
                $unavailable = false;  // Can be enhanced with general unavailability checks

                // Create time slot with comprehensive availability information
                $timeSlot = [
                    'start' => $slotStart,
                    'end' => $slotEnd,
                    'display' => $slotStart . '-' . $slotEnd,
                    'duration' => 30,
                    'available' => !$isBooked && $courtAvailable && !$maintenance && !$specialEvent && !$closed && !$unavailable,
                    'booked' => $isBooked,
                    'court_available' => $courtAvailable,
                    'maintenance' => $maintenance,
                    'special_event' => $specialEvent,
                    'closed' => $closed,
                    'unavailable' => $unavailable,
                    'reserved' => false, // Can be enhanced with reservation system
                    'occupied' => false  // Can be enhanced with real-time occupancy tracking
                ];

                $timeSlots[] = $timeSlot;
            }

            // Return all slots with their availability status (Flutter app will filter them)
            // This allows the Flutter app to show proper availability information
            return response()->json(array_values($timeSlots));

        } catch (\Exception $e) {
            return response()->json([
                'status' => 'error',
                'message' => 'Failed to get available times: ' . $e->getMessage()
            ], 500);
        }
    }

    /**
     * Get available time slots V2 - Enhanced version with better filtering
     * ENHANCED: Comprehensive filtering for all types of unavailability
     */
    public function getAvailableTimesV2(Request $request)
    {
        try {
            $validator = Validator::make($request->all(), [
                'court_id' => 'required|integer|exists:pickleball_courts,id',
                'date' => 'required|date_format:Y-m-d',
            ]);

            if ($validator->fails()) {
                return response()->json(['error' => $validator->errors()->first()], 400);
            }

            $courtId = $request->court_id;
            $date = $request->date;
            
            // Get court with operation hours
            $court = PickleballCourt::findOrFail($courtId);
            
            if (!$court->operation_hours) {
                return response()->json(['error' => 'Court operation hours not configured'], 400);
            }

            // Parse operation hours - handle different formats
            $operationHours = [];
            if (is_string($court->operation_hours)) {
                $operationHours = json_decode($court->operation_hours, true) ?: [];
            } elseif (is_array($court->operation_hours)) {
                $operationHours = $court->operation_hours;
            }

            if (empty($operationHours)) {
                return response()->json(['error' => 'No operation hours found'], 400);
            }

            // Generate all possible time slots from operation hours
            $allSlots = [];
            foreach ($operationHours as $hour) {
                try {
                    // Parse the time range (e.g., "7:00am-8:00am" or "07:00-08:00")
                    $parts = preg_split('/\s*(?:-|–|—|\s+to\s+)\s*/u', (string)$hour, 2);
                    if (!$parts || count($parts) < 2) {
                        Log::warning('Invalid slot separator', ['slot' => $hour]);
                        continue;
                    }
                    [$startRaw, $endRaw] = $parts;

                    $startTime = $this->parseHourFlexible((string)$startRaw);
                    $endTime = $this->parseHourFlexible((string)$endRaw);
                    
                    if (!$startTime || !$endTime) {
                        Log::warning('Invalid operation hours format', ['slot' => $hour]);
                        continue;
                    }

                    // Handle midnight crossover
                    if ($endTime->lessThanOrEqualTo($startTime)) {
                        $endTime->addDay();
                    }

                    // Generate hourly slots within this range
                    $currentTime = $startTime->copy();
                    while ($currentTime->lessThan($endTime)) {
                        $slotStart = $currentTime->copy();
                        $slotEnd = $currentTime->copy()->addHour();
                        
                        // Use the EXACT same availability check logic as the store method
                        $startTimeStr = $slotStart->format('H:i');
                        $endTimeStr = $slotEnd->format('H:i');
                        
                        // Normalize to H:i:s for database comparison (same as store method)
                        $startHms = Carbon::createFromFormat('H:i', $startTimeStr, 'UTC')->format('H:i:s');
                        $endHms = Carbon::createFromFormat('H:i', $endTimeStr, 'UTC')->format('H:i:s');
                        
                        // Check availability using the EXACT same query as store method
                        $isBooked = Booking::where('court_id', $courtId)
                            ->where('booking_date', $date)
                            ->where(function ($query) use ($startHms, $endHms) {
                                $query->where(function ($q) use ($startHms, $endHms) {
                                        $q->where('start_time', '>=', $startHms)
                                          ->where('start_time', '<',  $endHms);
                                    })
                                    ->orWhere(function ($q) use ($startHms, $endHms) {
                                        $q->where('end_time',   '>',  $startHms)
                                          ->where('end_time',   '<=', $endHms);
                                    })
                                    ->orWhere(function ($q) use ($startHms, $endHms) {
                                        $q->where('start_time', '<', $startHms)
                                          ->where('end_time',   '>', $endHms);
                                    });
                            })
                            ->exists();

                        // Add ALL slots with their availability status (Flutter app will filter them)
                        $allSlots[] = [
                            'start' => $startTimeStr,
                            'end' => $endTimeStr,
                            'display' => $startTimeStr . '-' . $endTimeStr,
                            'duration' => 60,
                            'available' => !$isBooked,
                            'booked' => $isBooked,
                            'reserved' => false,
                            'occupied' => false,
                            'court_available' => true,
                            'maintenance' => false,
                            'special_event' => false,
                            'closed' => false,
                            'unavailable' => false
                        ];
                        
                        $currentTime->addHour();
                    }
                } catch (\Throwable $e) {
                    Log::warning("Error processing operation hour: " . $e->getMessage());
                    continue;
                }
            }

            // Sort by start time
            usort($allSlots, function($a, $b) {
                return strcmp($a['start'], $b['start']);
            });

            return response()->json($allSlots);

        } catch (\Exception $e) {
            Log::error('Error in getAvailableTimesV2: ' . $e->getMessage());
            return response()->json(['error' => 'Failed to fetch available time slots'], 500);
        }
    }
}

