import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

class AuthHelper {
  static Future<bool> isAuthenticated() async {
    final prefs = await SharedPreferences.getInstance();
    // Try both token keys to handle different storage methods
    String? token = prefs.getString('auth_token');
    if (token == null) {
      token = prefs.getString('token');
    }
    
    // Check for user data in secure storage or shared preferences
    String? userData = prefs.getString('user_data');
    if (userData == null) {
      // Try to get user data from secure storage
      final storage = const FlutterSecureStorage();
      final userId = await storage.read(key: 'user_id');
      if (userId != null) {
        userData = 'present'; // Just check if user data exists
      }
    }
    
    return token != null && userData != null;
  }

  static Future<void> logout(BuildContext context) async {
    final prefs = await SharedPreferences.getInstance();
    final storage = const FlutterSecureStorage();
    
    // Clear all possible token storage locations
    await prefs.remove('token');
    await prefs.remove('auth_token');
    await prefs.remove('user_data');
    
    // Clear secure storage
    await storage.deleteAll();
    
    // Navigate to login
    Navigator.pushNamedAndRemoveUntil(
      context, 
      '/login', 
      (route) => false,
    );
  }

  static Future<void> requireAuth(BuildContext context, VoidCallback onAuthenticated) async {
    if (await isAuthenticated()) {
      onAuthenticated();
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please log in to continue'),
          duration: Duration(seconds: 2),
        ),
      );
      Navigator.pushReplacementNamed(context, '/login');
    }
  }
}
