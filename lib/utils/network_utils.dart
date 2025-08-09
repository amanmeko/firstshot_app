import 'dart:io';
import 'package:http/http.dart' as http;
import 'dart:convert';

class NetworkUtils {
  /// Test basic internet connectivity
  static Future<bool> hasInternetConnection() async {
    try {
      final result = await InternetAddress.lookup('google.com');
      return result.isNotEmpty && result[0].rawAddress.isNotEmpty;
    } on SocketException catch (_) {
      return false;
    }
  }

  /// Test if the FirstShot API is reachable
  static Future<Map<String, dynamic>> testApiConnectivity() async {
    const baseUrl = 'https://firstshot.my/api/auth';
    
    try {
      print('🔍 Testing API connectivity to: $baseUrl');
      
      // Test 1: Basic connectivity
      final connectivityResult = await hasInternetConnection();
      if (!connectivityResult) {
        return {
          'success': false,
          'error': 'No internet connection available',
          'details': 'Unable to reach external servers'
        };
      }

      // Test 2: DNS resolution
      try {
        final uri = Uri.parse(baseUrl);
        final host = uri.host;
        final addresses = await InternetAddress.lookup(host);
        print('✅ DNS resolution successful for $host: ${addresses.length} addresses found');
      } catch (e) {
        return {
          'success': false,
          'error': 'DNS resolution failed',
          'details': 'Unable to resolve hostname: $e'
        };
      }

      // Test 3: HTTP connection
      try {
        final response = await http.get(
          Uri.parse('$baseUrl/courts'),
          headers: {
            'Content-Type': 'application/json',
            'Accept': 'application/json',
          },
        ).timeout(const Duration(seconds: 15));

        print('📡 HTTP test successful: ${response.statusCode}');
        
        return {
          'success': true,
          'statusCode': response.statusCode,
          'responseBody': response.body,
          'headers': response.headers,
          'message': 'API is reachable'
        };
      } catch (e) {
        if (e.toString().contains('timeout')) {
          return {
            'success': false,
            'error': 'Request timeout',
            'details': 'Server took too long to respond (over 15 seconds)'
          };
        } else if (e.toString().contains('SocketException')) {
          return {
            'success': false,
            'error': 'Connection refused',
            'details': 'Unable to establish connection to server: $e'
          };
        } else if (e.toString().contains('HandshakeException')) {
          return {
            'success': false,
            'error': 'SSL/TLS error',
            'details': 'Unable to establish secure connection: $e'
          };
        } else {
          return {
            'success': false,
            'error': 'HTTP request failed',
            'details': 'Unexpected error: $e'
          };
        }
      }
    } catch (e) {
      return {
        'success': false,
        'error': 'Unexpected error',
        'details': 'Error during connectivity test: $e'
      };
    }
  }

  /// Test multiple possible base URLs
  static Future<List<Map<String, dynamic>>> testMultipleUrls() async {
    final urls = [
      'https://firstshot.my/api/auth',
      'https://firstshot.my/api',
      'https://firstshot.my',
      'http://firstshot.my/api/auth',
      'http://firstshot.my/api',
      'http://firstshot.my',
    ];

    final results = <Map<String, dynamic>>[];

    for (final url in urls) {
      try {
        print('🔍 Testing URL: $url');
        
        final response = await http.get(
          Uri.parse('$url/courts'),
          headers: {
            'Content-Type': 'application/json',
            'Accept': 'application/json',
          },
        ).timeout(const Duration(seconds: 10));

        results.add({
          'url': url,
          'success': true,
          'statusCode': response.statusCode,
          'responseBody': response.body,
          'message': 'URL is reachable'
        });
        
        print('✅ $url: ${response.statusCode}');
      } catch (e) {
        results.add({
          'url': url,
          'success': false,
          'error': e.toString(),
          'message': 'URL is not reachable'
        });
        
        print('❌ $url: $e');
      }
    }

    return results;
  }

  /// Get detailed network diagnostics
  static Future<Map<String, dynamic>> getNetworkDiagnostics() async {
    final diagnostics = <String, dynamic>{};
    
    // Basic connectivity
    diagnostics['internet'] = await hasInternetConnection();
    
    // API connectivity
    diagnostics['api'] = await testApiConnectivity();
    
    // Multiple URL test
    diagnostics['multipleUrls'] = await testMultipleUrls();
    
    // Network info
    try {
      final result = await InternetAddress.lookup('firstshot.my');
      diagnostics['dns'] = {
        'success': true,
        'addresses': result.map((addr) => addr.address).toList(),
        'hostname': 'firstshot.my'
      };
    } catch (e) {
      diagnostics['dns'] = {
        'success': false,
        'error': e.toString()
      };
    }

    return diagnostics;
  }
}