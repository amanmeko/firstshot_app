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
      final response = await http.get(
        Uri.parse('$baseUrl/bookings/available-times?court_id=$courtId&date=$date'),
        headers: headers,
      );

      if (response.statusCode == 200) {
        final List<dynamic> data = json.decode(response.body);
        return data.cast<Map<String, dynamic>>();
      } else {
        throw Exception('Failed to load available times: ${response.statusCode}');
      }
    } catch (e) {
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
        if (notes != null) 'notes': notes,
        if (promoCode != null) 'promo_code': promoCode,
      };

      final response = await http.post(
        Uri.parse('$baseUrl/bookings'),
        headers: headers,
        body: json.encode(body),
      );

      if (response.statusCode == 200 || response.statusCode == 201) {
        return json.decode(response.body);
      } else {
        final errorBody = json.decode(response.body);
        throw Exception(errorBody['message'] ?? 'Failed to create booking');
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
