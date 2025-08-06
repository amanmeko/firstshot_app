import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

class ApiService {
  static const String baseUrl = "https://firstshot.my/api/auth"; // Updated base URL

  // Get auth headers with token
  static Future<Map<String, String>> _getAuthHeaders() async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('auth_token') ?? '';
    
    return {
      'Content-Type': 'application/json',
      'Accept': 'application/json',
      'Authorization': 'Bearer $token',
    };
  }

  // Authentication methods
  static Future<http.Response> register(Map<String, dynamic> data) async {
    final url = Uri.parse('$baseUrl/register');
    return await http.post(url, body: data);
  }

  static Future<http.Response> login(Map<String, dynamic> data) async {
    final url = Uri.parse('$baseUrl/login');
    return await http.post(url, body: data);
  }

  static Future<http.Response> verifyOtp(Map<String, dynamic> data) async {
    final url = Uri.parse('$baseUrl/otp-login');
    return await http.post(url, body: data);
  }

  // Profile methods
  static Future<Map<String, dynamic>?> getUserProfile() async {
    try {
      final headers = await _getAuthHeaders();
      final url = Uri.parse('$baseUrl/profile');
      final response = await http.get(url, headers: headers);

      if (response.statusCode == 200) {
        return json.decode(response.body);
      }
      return null;
    } catch (e) {
      print('Error fetching user profile: $e');
      return null;
    }
  }

  static Future<bool> updateProfile(Map<String, dynamic> data) async {
    try {
      final headers = await _getAuthHeaders();
      final url = Uri.parse('$baseUrl/profile/update');
      final response = await http.put(
        url,
        headers: headers,
        body: json.encode(data),
      );

      return response.statusCode == 200;
    } catch (e) {
      print('Error updating profile: $e');
      return false;
    }
  }

  // Friend management methods
  static Future<List<Map<String, dynamic>>> getFriends() async {
    try {
      final headers = await _getAuthHeaders();
      final url = Uri.parse('$baseUrl/friends');
      final response = await http.get(url, headers: headers);

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        return List<Map<String, dynamic>>.from(data['friends'] ?? []);
      }
      return [];
    } catch (e) {
      print('Error fetching friends: $e');
      return [];
    }
  }

  static Future<List<Map<String, dynamic>>> getPendingRequests() async {
    try {
      final headers = await _getAuthHeaders();
      final url = Uri.parse('$baseUrl/friends/pending');
      final response = await http.get(url, headers: headers);

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        return List<Map<String, dynamic>>.from(data['pending_requests'] ?? []);
      }
      return [];
    } catch (e) {
      print('Error fetching pending requests: $e');
      return [];
    }
  }

  static Future<bool> sendFriendRequest(int receiverId) async {
    try {
      final headers = await _getAuthHeaders();
      final url = Uri.parse('$baseUrl/friends/send/$receiverId');
      final response = await http.post(url, headers: headers);

      return response.statusCode == 200;
    } catch (e) {
      print('Error sending friend request: $e');
      return false;
    }
  }

  static Future<bool> acceptFriendRequest(int senderId) async {
    try {
      final headers = await _getAuthHeaders();
      final url = Uri.parse('$baseUrl/friends/accept/$senderId');
      final response = await http.post(url, headers: headers);

      return response.statusCode == 200;
    } catch (e) {
      print('Error accepting friend request: $e');
      return false;
    }
  }

  static Future<bool> rejectFriendRequest(int senderId) async {
    try {
      final headers = await _getAuthHeaders();
      final url = Uri.parse('$baseUrl/friends/reject/$senderId');
      final response = await http.post(url, headers: headers);

      return response.statusCode == 200;
    } catch (e) {
      print('Error rejecting friend request: $e');
      return false;
    }
  }

  static Future<List<Map<String, dynamic>>> searchUsers(String query) async {
    try {
      final headers = await _getAuthHeaders();
      // TODO: Add this endpoint to your Laravel routes
      // Route::get('/users/search', [CustomerAuthController::class, 'searchUsers']);
      final url = Uri.parse('$baseUrl/users/search?q=$query');
      final response = await http.get(url, headers: headers);

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        return List<Map<String, dynamic>>.from(data['users'] ?? []);
      }
      return [];
    } catch (e) {
      print('Error searching users: $e');
      // Return empty list if endpoint doesn't exist yet
      return [];
    }
  }

  // Auth token management
  static Future<void> saveAuthToken(String token) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('auth_token', token);
  }

  static Future<String?> getAuthToken() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString('auth_token');
  }

  static Future<void> removeAuthToken() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('auth_token');
  }

  static Future<bool> logout() async {
    try {
      final headers = await _getAuthHeaders();
      final url = Uri.parse('$baseUrl/logout');
      final response = await http.post(url, headers: headers);
      
      await removeAuthToken();
      return response.statusCode == 200;
    } catch (e) {
      print('Error during logout: $e');
      await removeAuthToken();
      return false;
    }
  }
}
