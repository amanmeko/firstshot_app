<?php

namespace App\Http\Controllers\Api;

use App\Http\Controllers\Controller;
use App\Models\Booking;
use App\Models\Court;
use App\Models\PromoCode;
use Illuminate\Http\Request;
use Illuminate\Support\Facades\Auth;
use Illuminate\Support\Facades\Validator;
use Carbon\Carbon;

class BookingApiController extends Controller
{
    /**
     * Store a new booking
     */
    public function store(Request $request)
    {
        $validator = Validator::make($request->all(), [
            'court_id' => 'required|exists:courts,id',
            'date' => 'required|date|after:today',
            'start_time' => 'required|date_format:H:i',
            'end_time' => 'required|date_format:H:i|after:start_time',
            'promo_code' => 'nullable|string',
        ]);

        if ($validator->fails()) {
            return response()->json([
                'success' => false,
                'message' => 'Validation failed',
                'errors' => $validator->errors()
            ], 422);
        }

        // Check if the time slot is already booked
        $existingBooking = Booking::where('court_id', $request->court_id)
            ->where('date', $request->date)
            ->where(function ($query) use ($request) {
                $query->whereBetween('start_time', [$request->start_time, $request->end_time])
                    ->orWhereBetween('end_time', [$request->start_time, $request->end_time])
                    ->orWhere(function ($q) use ($request) {
                        $q->where('start_time', '<=', $request->start_time)
                            ->where('end_time', '>=', $request->end_time);
                    });
            })
            ->first();

        if ($existingBooking) {
            return response()->json([
                'success' => false,
                'message' => 'This time slot is already booked'
            ], 409);
        }

        // Calculate price
        $startTime = Carbon::parse($request->start_time);
        $endTime = Carbon::parse($request->end_time);
        $duration = $startTime->diffInHours($endTime);
        $court = Court::find($request->court_id);
        $price = $court->price_per_hour * $duration;

        // Apply promo code if provided
        if ($request->promo_code) {
            $promoCode = PromoCode::where('code', $request->promo_code)
                ->where('is_active', true)
                ->where('expires_at', '>', now())
                ->first();

            if ($promoCode) {
                $price = $price * (1 - ($promoCode->discount_percentage / 100));
            }
        }

        $booking = Booking::create([
            'user_id' => Auth::id(),
            'court_id' => $request->court_id,
            'date' => $request->date,
            'start_time' => $request->start_time,
            'end_time' => $request->end_time,
            'price' => $price,
            'status' => 'confirmed',
        ]);

        return response()->json([
            'success' => true,
            'message' => 'Booking created successfully',
            'data' => $booking
        ], 201);
    }

    /**
     * Get available time slots (V2) - Fixed to exclude booked slots
     */
    public function getAvailableTimesV2(Request $request)
    {
        $validator = Validator::make($request->all(), [
            'court_id' => 'required|exists:courts,id',
            'date' => 'required|date|after:today',
        ]);

        if ($validator->fails()) {
            return response()->json([
                'success' => false,
                'message' => 'Validation failed',
                'errors' => $validator->errors()
            ], 422);
        }

        $court = Court::find($request->court_id);
        $date = $request->date;

        // Get court operating hours
        $openingTime = $court->opening_time ?? '06:00';
        $closingTime = $court->closing_time ?? '22:00';
        $slotDuration = 60; // 1 hour slots

        // Generate all possible time slots
        $allTimeSlots = [];
        $currentTime = Carbon::parse($openingTime);
        $closingTimeObj = Carbon::parse($closingTime);

        while ($currentTime < $closingTimeObj) {
            $slotStart = $currentTime->format('H:i');
            $slotEnd = $currentTime->addHour()->format('H:i');
            
            $allTimeSlots[] = [
                'start_time' => $slotStart,
                'end_time' => $slotEnd,
                'is_available' => true
            ];
        }

        // Get all existing bookings for this court and date
        $existingBookings = Booking::where('court_id', $request->court_id)
            ->where('date', $date)
            ->where('status', '!=', 'cancelled')
            ->get();

        // Mark booked slots as unavailable
        foreach ($existingBookings as $booking) {
            foreach ($allTimeSlots as &$slot) {
                // Check if the slot overlaps with the booking
                if ($this->timeSlotsOverlap(
                    $slot['start_time'], 
                    $slot['end_time'], 
                    $booking->start_time, 
                    $booking->end_time
                )) {
                    $slot['is_available'] = false;
                    $slot['booking_id'] = $booking->id;
                    $slot['status'] = 'booked';
                }
            }
        }

        // Filter to show only available slots
        $availableSlots = array_filter($allTimeSlots, function ($slot) {
            return $slot['is_available'] === true;
        });

        return response()->json([
            'success' => true,
            'data' => [
                'court_id' => $request->court_id,
                'date' => $date,
                'available_slots' => array_values($availableSlots),
                'total_available' => count($availableSlots),
                'court_info' => [
                    'name' => $court->name,
                    'opening_time' => $openingTime,
                    'closing_time' => $closingTime,
                    'price_per_hour' => $court->price_per_hour
                ]
            ]
        ]);
    }

    /**
     * Check if two time slots overlap
     */
    private function timeSlotsOverlap($start1, $end1, $start2, $end2)
    {
        $start1Time = Carbon::parse($start1);
        $end1Time = Carbon::parse($end1);
        $start2Time = Carbon::parse($start2);
        $end2Time = Carbon::parse($end2);

        return $start1Time < $end2Time && $start2Time < $end1Time;
    }

    /**
     * Get available time slots (Original method)
     */
    public function getAvailableTimes(Request $request)
    {
        // This method can be kept for backward compatibility
        return $this->getAvailableTimesV2($request);
    }

    /**
     * Validate promo code
     */
    public function validatePromoCode(Request $request)
    {
        $validator = Validator::make($request->all(), [
            'promo_code' => 'required|string',
        ]);

        if ($validator->fails()) {
            return response()->json([
                'success' => false,
                'message' => 'Validation failed',
                'errors' => $validator->errors()
            ], 422);
        }

        $promoCode = PromoCode::where('code', $request->promo_code)
            ->where('is_active', true)
            ->where('expires_at', '>', now())
            ->first();

        if (!$promoCode) {
            return response()->json([
                'success' => false,
                'message' => 'Invalid or expired promo code'
            ], 404);
        }

        return response()->json([
            'success' => true,
            'data' => [
                'code' => $promoCode->code,
                'discount_percentage' => $promoCode->discount_percentage,
                'description' => $promoCode->description,
                'expires_at' => $promoCode->expires_at
            ]
        ]);
    }

    /**
     * Get customer bookings
     */
    public function getCustomerBookings(Request $request)
    {
        $bookings = Booking::where('user_id', Auth::id())
            ->with(['court'])
            ->orderBy('date', 'desc')
            ->orderBy('start_time', 'desc')
            ->paginate(10);

        return response()->json([
            'success' => true,
            'data' => $bookings
        ]);
    }

    /**
     * Show a specific booking
     */
    public function show(Booking $booking)
    {
        if ($booking->user_id !== Auth::id()) {
            return response()->json([
                'success' => false,
                'message' => 'Unauthorized'
            ], 403);
        }

        return response()->json([
            'success' => true,
            'data' => $booking->load('court')
        ]);
    }

    /**
     * Update a booking
     */
    public function update(Request $request, Booking $booking)
    {
        if ($booking->user_id !== Auth::id()) {
            return response()->json([
                'success' => false,
                'message' => 'Unauthorized'
            ], 403);
        }

        $validator = Validator::make($request->all(), [
            'date' => 'sometimes|date|after:today',
            'start_time' => 'sometimes|date_format:H:i',
            'end_time' => 'sometimes|date_format:H:i|after:start_time',
        ]);

        if ($validator->fails()) {
            return response()->json([
                'success' => false,
                'message' => 'Validation failed',
                'errors' => $validator->errors()
            ], 422);
        }

        // Check for conflicts if time/date is being changed
        if ($request->has('date') || $request->has('start_time') || $request->has('end_time')) {
            $date = $request->date ?? $booking->date;
            $startTime = $request->start_time ?? $booking->start_time;
            $endTime = $request->end_time ?? $booking->end_time;

            $existingBooking = Booking::where('court_id', $booking->court_id)
                ->where('id', '!=', $booking->id)
                ->where('date', $date)
                ->where('status', '!=', 'cancelled')
                ->where(function ($query) use ($startTime, $endTime) {
                    $query->whereBetween('start_time', [$startTime, $endTime])
                        ->orWhereBetween('end_time', [$startTime, $endTime])
                        ->orWhere(function ($q) use ($startTime, $endTime) {
                            $q->where('start_time', '<=', $startTime)
                                ->where('end_time', '>=', $endTime);
                        });
                })
                ->first();

            if ($existingBooking) {
                return response()->json([
                    'success' => false,
                    'message' => 'This time slot is already booked'
                ], 409);
            }
        }

        $booking->update($request->only(['date', 'start_time', 'end_time']));

        return response()->json([
            'success' => true,
            'message' => 'Booking updated successfully',
            'data' => $booking
        ]);
    }

    /**
     * Delete a booking
     */
    public function destroy(Booking $booking)
    {
        if ($booking->user_id !== Auth::id()) {
            return response()->json([
                'success' => false,
                'message' => 'Unauthorized'
            ], 403);
        }

        $booking->delete();

        return response()->json([
            'success' => true,
            'message' => 'Booking deleted successfully'
        ]);
    }

    /**
     * Get all courts
     */
    public function getCourts()
    {
        $courts = Court::where('is_active', true)->get();

        return response()->json([
            'success' => true,
            'data' => $courts
        ]);
    }
}