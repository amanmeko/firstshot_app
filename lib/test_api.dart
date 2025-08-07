import 'dart:convert';
import 'package:http/http.dart' as http;

class ApiTest {
  static const String baseUrl = 'https://firstshot.my/api/auth';
  
  static Future<void> testCourtsEndpoint() async {
    print('🧪 Testing Courts API Endpoint...');
    
    try {
      // Test without authentication
      final response = await http.get(
        Uri.parse('$baseUrl/courts'),
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
        },
      );
      
      print('📡 Status Code: ${response.statusCode}');
      print('📄 Response Body: ${response.body}');
      
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        print('✅ Success! Found ${data['courts']?.length ?? 0} courts');
      } else {
        print('❌ Failed with status: ${response.statusCode}');
      }
    } catch (e) {
      print('💥 Exception: $e');
    }
  }
}
