import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

class BookingService {
  static const String baseUrl = 'https://firstshot.my/api/auth';
  
  static Future<String?> _getToken() async {
    final prefs = await SharedPreferences.getInstance();
    // Try both token keys to handle different storage methods
    String? token = prefs.getString('auth_token');
    if (token == null) {
      token = prefs.getString('token');
    }
    return token;
  }

  static Future<Map<String, String>> _getHeaders() async {
    final token = await _getToken();
    return {
      'Content-Type': 'application/json',
      'Accept': 'application/json',
      if (token != null) 'Authorization': 'Bearer $token',
    };
  }

  static Future<Map<String, dynamic>> getCourts() async {
    try {
      final headers = await _getHeaders();
      
      final response = await http.get(
        Uri.parse('$baseUrl/courts'),
        headers: headers,
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        return data;
      } else {
        throw Exception('Failed to load courts: ${response.statusCode} - ${response.body}');
      }
    } catch (e) {
      throw Exception('Error fetching courts: $e');
    }
  }

  static Future<List<Map<String, dynamic>>> getAvailableTimes({
    required int courtId,
    required String date,
  }) async {
    try {
      final headers = await _getHeaders();
      print('🔍 BookingService.getAvailableTimes: courtId=$courtId date=$date');
      print('🔑 Headers: ${headers.keys}');
      
      final response = await http.get(
        Uri.parse('$baseUrl/bookings/available-times?court_id=$courtId&date=$date'),
        headers: headers,
      );
      
      print('📡 GET /available-times -> status: ${response.statusCode}');
      print('📄 Response body: ${response.body}');
      
      if (response.statusCode == 200) {
        try {
          final List<dynamic> data = json.decode(response.body);
          print('✅ Successfully parsed ${data.length} time slots');
          
          // Enhanced client-side filtering to ensure only available slots are returned
          final filteredData = <Map<String, dynamic>>[];
          for (final slot in data) {
            if (slot is Map<String, dynamic>) {
              // Check all possible availability flags
              final isBooked = slot['booked'] == true;
              final isAvailable = slot['available'] != false; // Default to true if not specified
              final isReserved = slot['reserved'] == true;
              final isOccupied = slot['occupied'] == true;
              final isCourtAvailable = slot['court_available'] != false; // Default to true if not specified
              final isMaintenance = slot['maintenance'] == true;
              final isSpecialEvent = slot['special_event'] == true;
              final isClosed = slot['closed'] == true;
              final isUnavailable = slot['unavailable'] == true;
              
              // Additional safety checks for time slots
              final startTime = slot['start']?.toString();
              final endTime = slot['end']?.toString();
              final hasValidTimes = startTime != null && endTime != null && 
                                  startTime.isNotEmpty && endTime.isNotEmpty;
              
              // Only include slots that are explicitly available and not booked/reserved/occupied
              if (!isBooked && isAvailable && !isReserved && !isOccupied && 
                  isCourtAvailable && !isMaintenance && !isSpecialEvent && !isClosed && !isUnavailable &&
                  hasValidTimes) {
                // Add availability flags to the slot data for consistency
                final enhancedSlot = Map<String, dynamic>.from(slot);
                enhancedSlot['booked'] = false;
                enhancedSlot['available'] = true;
                enhancedSlot['reserved'] = false;
                enhancedSlot['occupied'] = false;
                enhancedSlot['court_available'] = true;
                enhancedSlot['maintenance'] = false;
                enhancedSlot['special_event'] = false;
                enhancedSlot['closed'] = false;
                enhancedSlot['unavailable'] = false;
                
                filteredData.add(enhancedSlot);
                print('✅ Legacy: Including available slot: ${slot['start']}-${slot['end']}');
              } else {
                print('🚫 Legacy: Excluding unavailable slot: ${slot['start']}-${slot['end']} (booked: $isBooked, available: $isAvailable, reserved: $isReserved, occupied: $isOccupied, court_available: $isCourtAvailable, maintenance: $isMaintenance, special_event: $isSpecialEvent, closed: $isClosed, unavailable: $isUnavailable)');
              }
            }
          }
          
          print('🔍 Legacy: Filtered ${data.length} slots down to ${filteredData.length} available slots');
          return filteredData;
        } catch (parseError) {
          print('❌ JSON parse error: $parseError');
          print('📄 Raw response: ${response.body}');
          throw Exception('Invalid response format from server');
        }
      }

      // Handle different error status codes
      String errorMessage = 'Failed to load available times (HTTP ${response.statusCode})';
      
      try {
        final dynamic body = json.decode(response.body);
        if (body is Map<String, dynamic>) {
          if (body['message'] is String && (body['message'] as String).isNotEmpty) {
            errorMessage = body['message'];
            print('📝 Server error message: $errorMessage');
          } else if (body['errors'] is Map) {
            final Map errs = body['errors'] as Map;
            if (errs['time_slot'] != null) {
              final ts = errs['time_slot'];
              if (ts is List && ts.isNotEmpty) {
                errorMessage = ts.first.toString();
              } else {
                errorMessage = ts.toString();
              }
              print('📝 Time slot error: $errorMessage');
            }
          }
        }
      } catch (parseError) {
        print('❌ Error parsing error response: $parseError');
        // Keep default errorMessage
      }
      
      // Log the full error for debugging
      print('❌ API Error Details:');
      print('  - Status: ${response.statusCode}');
      print('  - Headers: ${response.headers}');
      print('  - Body: ${response.body}');
      print('  - Error Message: $errorMessage');
      
      throw Exception(errorMessage);
    } catch (e, st) {
      print('💥 Exception in getAvailableTimes: $e');
      print('📚 Stack trace: $st');
      
      // Re-throw with more context
      if (e.toString().contains('SocketException') || e.toString().contains('Connection refused')) {
        throw Exception('Network error: Unable to connect to server. Please check your internet connection.');
      } else if (e.toString().contains('TimeoutException')) {
        throw Exception('Request timeout: Server is taking too long to respond. Please try again.');
      } else {
        throw Exception('Error fetching available times: $e');
      }
    }
  }

  // New v2 endpoint: returns slots with explicit availability flags
  static Future<List<Map<String, dynamic>>> getAvailableTimesV2({
    required int courtId,
    required String date,
  }) async {
    try {
      final headers = await _getHeaders();
      final uri = Uri.parse('$baseUrl/bookings/available-times-v2?court_id=$courtId&date=$date');
      print('🌐 Calling V2 endpoint: ${uri.toString()}');
      print('🔑 Headers: ${headers.keys}');
      
      final response = await http.get(uri, headers: headers);
      
      print('📡 V2 endpoint response: HTTP ${response.statusCode}');
      print('📄 Response body: ${response.body}');
      
      if (response.statusCode == 200) {
        try {
          final List<dynamic> data = json.decode(response.body);
          print('✅ V2 endpoint returned ${data.length} time slots');
          
          // Enhanced client-side filtering to ensure only available slots are returned
          final filteredData = <Map<String, dynamic>>[];
          for (final slot in data) {
            if (slot is Map<String, dynamic>) {
              // Check all possible availability flags
              final isBooked = slot['booked'] == true;
              final isAvailable = slot['available'] != false; // Default to true if not specified
              final isReserved = slot['reserved'] == true;
              final isOccupied = slot['occupied'] == true;
              final isCourtAvailable = slot['court_available'] != false; // Default to true if not specified
              final isMaintenance = slot['maintenance'] == true;
              final isSpecialEvent = slot['special_event'] == true;
              final isClosed = slot['closed'] == true;
              final isUnavailable = slot['unavailable'] == true;
              
              // Additional safety checks for time slots
              final startTime = slot['start']?.toString();
              final endTime = slot['end']?.toString();
              final hasValidTimes = startTime != null && endTime != null && 
                                  startTime.isNotEmpty && endTime.isNotEmpty;
              
              // Only include slots that are explicitly available and not booked/reserved/occupied
              if (!isBooked && isAvailable && !isReserved && !isOccupied && 
                  isCourtAvailable && !isMaintenance && !isSpecialEvent && !isClosed && !isUnavailable &&
                  hasValidTimes) {
                // Add availability flags to the slot data for consistency
                final enhancedSlot = Map<String, dynamic>.from(slot);
                enhancedSlot['booked'] = false;
                enhancedSlot['available'] = true;
                enhancedSlot['reserved'] = false;
                enhancedSlot['occupied'] = false;
                enhancedSlot['court_available'] = true;
                enhancedSlot['maintenance'] = false;
                enhancedSlot['special_event'] = false;
                enhancedSlot['closed'] = false;
                enhancedSlot['unavailable'] = false;
                
                filteredData.add(enhancedSlot);
                print('✅ V2: Including available slot: ${slot['start']}-${slot['end']}');
              } else {
                print('🚫 V2: Excluding unavailable slot: ${slot['start']}-${slot['end']} (booked: $isBooked, available: $isAvailable, reserved: $isReserved, occupied: $isOccupied, court_available: $isCourtAvailable, maintenance: $isMaintenance, special_event: $isSpecialEvent, closed: $isClosed, unavailable: $isUnavailable)');
              }
            }
          }
          
          print('🔍 V2: Filtered ${data.length} slots down to ${filteredData.length} available slots');
          return filteredData;
        } catch (parseError) {
          print('❌ V2 JSON parse error: $parseError');
          print('📄 Raw V2 response: ${response.body}');
          throw Exception('Invalid response format from V2 endpoint');
        }
      }
      
      // Handle V2 endpoint errors
      String errorMessage = 'V2 endpoint failed (HTTP ${response.statusCode})';
      
      try {
        final dynamic body = json.decode(response.body);
        if (body is Map<String, dynamic>) {
          if (body['message'] is String && (body['message'] as String).isNotEmpty) {
            errorMessage = body['message'];
            print('📝 V2 server error message: $errorMessage');
          }
        }
      } catch (parseError) {
        print('❌ Error parsing V2 error response: $parseError');
      }
      
      print('❌ V2 API Error Details:');
      print('  - Status: ${response.statusCode}');
      print('  - Headers: ${response.headers}');
      print('  - Body: ${response.body}');
      print('  - Error Message: $errorMessage');
      
      throw Exception(errorMessage);
    } catch (e) {
      print('💥 V2 endpoint exception: $e');
      
      // Re-throw with more context
      if (e.toString().contains('SocketException') || e.toString().contains('Connection refused')) {
        throw Exception('Network error: Unable to connect to V2 endpoint. Please check your internet connection.');
      } else if (e.toString().contains('TimeoutException')) {
        throw Exception('V2 request timeout: Server is taking too long to respond. Please try again.');
      } else {
        throw e; // Re-throw the original error
      }
    }
  }

  // Smart fetch: try v2 with availability flag, else fallback to legacy
  static Future<List<Map<String, dynamic>>> getAvailableTimesSmart({
    required int courtId,
    required String date,
  }) async {
    try {
      
      final v2 = await getAvailableTimesV2(courtId: courtId, date: date);
      
      return v2;
    } catch (e) {
      
      
      // Fallback to legacy endpoint
      final legacy = await getAvailableTimes(courtId: courtId, date: date);
      
      return legacy;
    }
  }

  // Force v2 endpoint only (for testing)
  static Future<List<Map<String, dynamic>>> getAvailableTimesV2Only({
    required int courtId,
    required String date,
  }) async {
    return await getAvailableTimesV2(courtId: courtId, date: date);
  }

  static Future<Map<String, dynamic>> createBooking({
    required int courtId,
    required int customerId,
    required String bookingDate,
    required String startTime,
    required String endTime,
    required double price,
    required String paymentMethod,
    String? notes,
    String? promoCode,
    int? durationHours,
  }) async {
    try {
      // Double-check slot availability before creating booking
      print('🔍 Verifying slot availability before creating booking...');
      final isAvailable = await verifySlotAvailability(
        courtId: courtId,
        date: bookingDate,
        startTime: startTime,
        endTime: endTime,
      );
      
      if (!isAvailable) {
        throw Exception('The selected time slot is no longer available. Please choose a different time.');
      }
      
      print('✅ Slot availability confirmed, proceeding with booking creation...');
      
      final headers = await _getHeaders();
      final body = {
        'court_id': courtId,
        'customer_id': customerId,
        'booking_date': bookingDate,
        'start_time': startTime,
        'end_time': endTime,
        'price': price,
        'payment_method': paymentMethod,
        if (durationHours != null) 'duration': durationHours,
        if (notes != null) 'notes': notes,
        if (promoCode != null) 'promo_code': promoCode,
      };

      final response = await http.post(
        Uri.parse('$baseUrl/bookings'),
        headers: headers,
        body: json.encode(body),
      );

      final status = response.statusCode;
      final contentType = response.headers['content-type'] ?? '';
      final requestUrl = response.request?.url.toString();

      // Handle redirects (e.g., to payment gateway)
      if (status >= 300 && status < 400) {
        final location = response.headers['location'] ?? requestUrl ?? '';
        if (location.isNotEmpty) {
          return {
            'success': true,
            'payment_url': location,
          };
        }
      }

      // JSON success
      if (status == 200 || status == 201) {
        if (contentType.contains('application/json')) {
          return json.decode(response.body);
        }
        // Non-JSON response (likely HTML payment page)
        return {
          'success': true,
          'payment_url': requestUrl ?? '',
          'html': response.body,
        };
      }

      // Error paths: try to parse JSON message, else return raw snippet
      try {
        final errorBody = json.decode(response.body);
        throw Exception(errorBody['message'] ?? 'Failed to create booking');
      } catch (_) {
        final snippet = response.body.length > 200
            ? response.body.substring(0, 200)
            : response.body;
        throw Exception('HTTP $status: $snippet');
      }
    } catch (e) {
      throw Exception('Error creating booking: $e');
    }
  }

  static Future<Map<String, dynamic>> validatePromoCode({
    required String code,
    required double subtotal,
  }) async {
    try {
      final headers = await _getHeaders();
      final body = {
        'code': code,
        'subtotal': subtotal,
      };

      final response = await http.post(
        Uri.parse('$baseUrl/bookings/validate-promo'),
        headers: headers,
        body: json.encode(body),
      );

      return json.decode(response.body);
    } catch (e) {
      throw Exception('Error validating promo code: $e');
    }
  }

  // Get a specific booking
  static Future<Map<String, dynamic>> getBooking(int bookingId) async {
    try {
      final headers = await _getHeaders();
      final response = await http.get(
        Uri.parse('$baseUrl/bookings/$bookingId'),
        headers: headers,
      );

      if (response.statusCode == 200) {
        return json.decode(response.body);
      } else {
        throw Exception('Failed to load booking: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Error fetching booking: $e');
    }
  }

  // Delete a booking
  static Future<Map<String, dynamic>> deleteBooking(int bookingId) async {
    try {
      final headers = await _getHeaders();
      final response = await http.delete(
        Uri.parse('$baseUrl/bookings/$bookingId'),
        headers: headers,
      );

      return json.decode(response.body);
    } catch (e) {
      throw Exception('Error deleting booking: $e');
    }
  }

  // Get customer bookings
  static Future<Map<String, dynamic>> getCustomerBookings({
    required int customerId,
    String? status,
    String? dateFrom,
    String? dateTo,
  }) async {
    try {
      final headers = await _getHeaders();
      final queryParams = <String, String>{
        'customer_id': customerId.toString(),
      };
      
      if (status != null) queryParams['status'] = status;
      if (dateFrom != null) queryParams['date_from'] = dateFrom;
      if (dateTo != null) queryParams['date_to'] = dateTo;

      final uri = Uri.parse('$baseUrl/bookings/customer').replace(queryParameters: queryParams);
      final response = await http.get(uri, headers: headers);

      if (response.statusCode == 200) {
        return json.decode(response.body);
      } else {
        throw Exception('Failed to load bookings: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Error fetching bookings: $e');
    }
  }

  /// Verify if a specific time slot is actually available by checking with the backend
  static Future<bool> verifySlotAvailability({
    required int courtId,
    required String date,
    required String startTime,
    required String endTime,
  }) async {
    try {
      // Make a test call to check if the slot is actually available
      // This can be used as an additional safety check
      final response = await http.get(
        Uri.parse('$baseUrl/bookings/available-times-v2?court_id=$courtId&date=$date'),
        headers: await _getHeaders(),
      );

      if (response.statusCode == 200) {
        final List<dynamic> data = json.decode(response.body);
        
        // Look for the specific slot and check its availability
        for (final slot in data) {
          if (slot is Map<String, dynamic>) {
            final slotStart = slot['start']?.toString() ?? '';
            final slotEnd = slot['end']?.toString() ?? '';
            
            if (slotStart == startTime && slotEnd == endTime) {
              // Check all availability flags
              final isBooked = slot['booked'] == true;
              final isAvailable = slot['available'] != false;
              final isReserved = slot['reserved'] == true;
              final isOccupied = slot['occupied'] == true;
              final isCourtAvailable = slot['court_available'] != false;
              final isMaintenance = slot['maintenance'] == true;
              final isSpecialEvent = slot['special_event'] == true;
              final isClosed = slot['closed'] == true;
              final isUnavailable = slot['unavailable'] == true;
              
              return !isBooked && isAvailable && !isReserved && !isOccupied && 
                     isCourtAvailable && !isMaintenance && !isSpecialEvent && !isClosed && !isUnavailable;
            }
          }
        }
      }
      
      return false; // Slot not found or not available
    } catch (e) {
      print('❌ Error verifying slot availability: $e');
      return false; // Assume not available on error
    }
  }
}
