import 'dart:convert';
import 'package:http/http.dart' as http;

class ApiService {
  static const String baseUrl = "https://firstshot.my/api/customer"; // ✅ Replace with your domain

  static Future<http.Response> register(Map<String, dynamic> data) async {
    final url = Uri.parse('$baseUrl/register');
    return await http.post(url, body: data);
  }

  static Future<http.Response> login(Map<String, dynamic> data) async {
    final url = Uri.parse('$baseUrl/login');
    return await http.post(url, body: data);
  }

  static Future<http.Response> verifyOtp(Map<String, dynamic> data) async {
    final url = Uri.parse('$baseUrl/verify-otp');
    return await http.post(url, body: data);
  }
}
