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
      print('BookingService.getAvailableTimes: courtId=$courtId date=$date headers=${headers.keys}');
      final response = await http.get(
        Uri.parse('$baseUrl/bookings/available-times?court_id=$courtId&date=$date'),
        headers: headers,
      );
      print('GET /available-times -> status: ${response.statusCode}');
      if (response.statusCode != 200) {
        print('Response body: ${response.body}');
      }

      if (response.statusCode == 200) {
        final List<dynamic> data = json.decode(response.body);
        return data.cast<Map<String, dynamic>>();
      }

      // Try to parse error body for a clearer message
      String errorMessage = 'Failed to load available times (HTTP ${response.statusCode})';
      try {
        final dynamic body = json.decode(response.body);
        if (body is Map<String, dynamic>) {
          if (body['message'] is String && (body['message'] as String).isNotEmpty) {
            errorMessage = body['message'];
          } else if (body['errors'] is Map) {
            final Map errs = body['errors'] as Map;
            if (errs['time_slot'] != null) {
              final ts = errs['time_slot'];
              if (ts is List && ts.isNotEmpty) {
                errorMessage = ts.first.toString();
              } else {
                errorMessage = ts.toString();
              }
            }
          }
        }
      } catch (_) {
        // ignore JSON parse failures; keep default errorMessage
      }
      print('Throwing error from getAvailableTimes: ' + errorMessage);
      throw Exception(errorMessage);
    } catch (e, st) {
      print('Error fetching available times: $e');
      print(st);
      throw Exception('Error fetching available times: $e');
    }
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
}
