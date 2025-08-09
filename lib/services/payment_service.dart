import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

class PaymentService {
  // Try different base URLs for different environments
  static const List<String> possibleBaseUrls = [
    'http://localhost:8000', // Local development
    'http://127.0.0.1:8000', // Local development alternative
    'https://firstshot.my', // Production
    'http://10.0.2.2:8000', // Android emulator localhost
  ];
  
  static const storage = FlutterSecureStorage();

  // Get payment initiation data
  static Future<Map<String, dynamic>> initiatePayment(int saleId) async {
    Exception? lastException;
    
    for (final baseUrl in possibleBaseUrls) {
      try {
        final token = await storage.read(key: 'auth_token');
        
        print('🔍 Trying to initiate payment for sale ID: $saleId');
        print('🔍 Base URL: $baseUrl');
        print('🔍 Token: ${token != null ? 'Present' : 'Missing'}');
        
        final url = '$baseUrl/api/payment/initiate/$saleId';
        print('🔍 Request URL: $url');
        
        final response = await http.get(
          Uri.parse(url),
          headers: {
            'Content-Type': 'application/json',
            'Accept': 'application/json',
            if (token != null) 'Authorization': 'Bearer $token',
          },
        ).timeout(const Duration(seconds: 10));

        print('🔍 Response status: ${response.statusCode}');
        print('🔍 Response body: ${response.body}');

        if (response.statusCode == 200) {
          final data = json.decode(response.body);
          print('🔍 Payment data received: $data');
          return data;
        } else {
          print('❌ Payment initiation failed: ${response.statusCode} - ${response.body}');
          lastException = Exception('Failed to initiate payment: ${response.statusCode} - ${response.body}');
          continue; // Try next URL
        }
      } catch (e) {
        print('❌ Error with $baseUrl: $e');
        lastException = Exception('Error with $baseUrl: $e');
        continue; // Try next URL
      }
    }
    
    // If we get here, all URLs failed
    throw lastException ?? Exception('All payment endpoints failed');
  }

  // Submit payment to gateway
  static Future<Map<String, dynamic>> submitPayment(Map<String, dynamic> paymentData) async {
    try {
      print('🔍 Submitting payment to: ${paymentData['action_url']}');
      print('🔍 Payment params: ${paymentData['params']}');
      
      final response = await http.post(
        Uri.parse(paymentData['action_url']),
        headers: {
          'Content-Type': 'application/x-www-form-urlencoded',
          'Accept': 'text/html,application/xhtml+xml,application/xml;q=0.9,*/*;q=0.8',
        },
        body: buildPaymentFormData(paymentData),
      );

      print('🔍 Payment gateway response status: ${response.statusCode}');
      print('🔍 Payment gateway response headers: ${response.headers}');

      if (response.statusCode == 200 || response.statusCode == 302) {
        // Parse the response from payment gateway
        return _parsePaymentGatewayResponse(response.body);
      } else {
        throw Exception('Payment gateway error: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Error submitting payment: $e');
    }
  }

  // Check payment status
  static Future<Map<String, dynamic>> checkPaymentStatus(String transactionId) async {
    Exception? lastException;
    
    for (final baseUrl in possibleBaseUrls) {
      try {
        final token = await storage.read(key: 'auth_token');
        
        final response = await http.post(
          Uri.parse('$baseUrl/api/payment/check-status'),
          headers: {
            'Content-Type': 'application/json',
            'Accept': 'application/json',
            if (token != null) 'Authorization': 'Bearer $token',
          },
          body: json.encode({
            'transaction_id': transactionId,
          }),
        ).timeout(const Duration(seconds: 10));

        if (response.statusCode == 200) {
          return json.decode(response.body);
        } else {
          lastException = Exception('Failed to check payment status: ${response.statusCode}');
          continue;
        }
      } catch (e) {
        lastException = Exception('Error checking payment status: $e');
        continue;
      }
    }
    
    throw lastException ?? Exception('All payment status endpoints failed');
  }

  // Poll payment status until completed or failed
  static Future<Map<String, dynamic>> pollPaymentStatus(String transactionId, {
    int maxAttempts = 30,
    Duration interval = const Duration(seconds: 2),
  }) async {
    int attempts = 0;
    
    while (attempts < maxAttempts) {
      try {
        print('🔍 Polling payment status - attempt ${attempts + 1}');
        final status = await checkPaymentStatus(transactionId);
        
        if (status['success'] == true) {
          final paymentStatus = status['status'];
          print('🔍 Payment status: $paymentStatus');
          
          if (paymentStatus == 'completed' || paymentStatus == 'failed') {
            return status;
          }
        }
        
        // Wait before next attempt
        await Future.delayed(interval);
        attempts++;
        
      } catch (e) {
        print('❌ Error polling payment status: $e');
        attempts++;
        await Future.delayed(interval);
      }
    }
    
    throw Exception('Payment status polling timeout');
  }

  // Parse payment gateway response
  static Map<String, dynamic> _parsePaymentGatewayResponse(String responseBody) {
    try {
      print('🔍 Parsing payment gateway response: ${responseBody.substring(0, responseBody.length > 200 ? 200 : responseBody.length)}...');
      
      // Try to parse as JSON first
      return json.decode(responseBody);
    } catch (e) {
      print('🔍 Not JSON, trying to extract from HTML');
      // If not JSON, try to extract parameters from HTML response
      return _extractParamsFromHtml(responseBody);
    }
  }

  // Extract parameters from HTML response
  static Map<String, dynamic> _extractParamsFromHtml(String html) {
    final Map<String, dynamic> params = {};
    
    // For now, just return empty params to avoid regex issues
    // TODO: Implement proper HTML parsing when needed
    print('🔍 HTML parsing not implemented yet');
    
    return params;
  }

  // Build payment form data
  static Map<String, String> buildPaymentFormData(Map<String, dynamic> paymentData) {
    final Map<String, String> formData = {};
    
    for (final entry in paymentData['params'].entries) {
      formData[entry.key] = entry.value.toString();
    }
    
    return formData;
  }

  // Validate payment response
  static bool isValidPaymentResponse(Map<String, dynamic> response) {
    final requiredFields = ['tranID', 'status', 'orderid'];
    
    for (final field in requiredFields) {
      if (!response.containsKey(field) || response[field] == null) {
        print('❌ Missing required field: $field');
        return false;
      }
    }
    
    print('✅ Payment response is valid');
    return true;
  }

  // Get payment status description
  static String getPaymentStatusDescription(String status) {
    switch (status.toLowerCase()) {
      case 'completed':
      case '00':
        return 'Payment successful';
      case 'failed':
      case '11':
        return 'Payment failed';
      case 'pending':
      case '22':
        return 'Payment pending';
      default:
        return 'Payment status unknown';
    }
  }
}
