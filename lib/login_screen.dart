import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:http/http.dart' as http;
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'dart:convert';
import 'services/api_service.dart';
import 'package:provider/provider.dart';
import 'user_profile.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _formKey = GlobalKey<FormState>();
  final TextEditingController _mobileController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  bool _isLoading = false;
  final storage = const FlutterSecureStorage();

  // Test different API endpoints
  Future<void> _testApiEndpoints() async {
    final endpoints = [
      'https://firstshot.my/api/customer/login',
      'https://firstshot.my/api/customer/login/mobile',
      'https://firstshot.my/api/auth/login',
      'https://firstshot.my/api/login',
    ];
    
    for (String endpoint in endpoints) {
      try {
        print('Testing endpoint: $endpoint');
        final response = await http.get(Uri.parse(endpoint));
        print('$endpoint - Status: ${response.statusCode}');
        print('$endpoint - Response: ${response.body.substring(0, response.body.length > 100 ? 100 : response.body.length)}...');
      } catch (e) {
        print('$endpoint - Error: $e');
      }
    }
  }

  Future<void> _submitForm() async {
    if (_formKey.currentState!.validate()) {
      setState(() {
        _isLoading = true;
      });

      String cleanedMobile = _mobileController.text.replaceAll(RegExp(r'[^0-9]'), '');
      // Add +60 country code if not present
      if (!cleanedMobile.startsWith('60')) {
        cleanedMobile = '+60$cleanedMobile';
      } else {
        cleanedMobile = '+$cleanedMobile';
      }

      try {
        print('Attempting login with mobile: $cleanedMobile');
        
        // Use the correct endpoint based on your Laravel routes
        final endpoint = 'https://firstshot.my/api/auth/login/mobile';
        print('Using endpoint: $endpoint');
        
        final response = await http.post(
          Uri.parse(endpoint),
          headers: {
            'Content-Type': 'application/json',
            'Accept': 'application/json',
          },
          body: jsonEncode({
            'mobile_no': cleanedMobile,
            'password': _passwordController.text,
          }),
        );
        
        print('Response status: ${response.statusCode}');
        print('Response headers: ${response.headers}');
        print('Response body: ${response.body}');
        
        // Check if response is HTML (error page)
        if (response.body.trim().startsWith('<!DOCTYPE') || response.body.trim().startsWith('<html')) {
          print('Received HTML response instead of JSON');
          _showErrorSnackBar('Server error. Please check the API endpoint configuration.');
          return;
        }

        if (response.statusCode == 200 || response.statusCode == 201) {
          final responseData = jsonDecode(response.body);
          final token = responseData['data']['access_token'];
          final userData = responseData['data']['customer'];

          if (token != null && userData != null) {
            // Save authentication token
            await ApiService.saveAuthToken(token);
            
            // Save user data to secure storage
            await storage.write(key: 'user_id', value: userData['id']?.toString() ?? '');
            await storage.write(key: 'customer_id', value: userData['customer_id']?.toString() ?? '');
            await storage.write(key: 'user_name', value: userData['name']?.toString() ?? '');
            await storage.write(key: 'email', value: userData['email']?.toString() ?? '');
            await storage.write(key: 'mobile_no', value: userData['mobile_no']?.toString() ?? '');
            await storage.write(key: 'level', value: userData['level']?.toString() ?? 'Beginner');
            await storage.write(key: 'location', value: userData['location']?.toString() ?? 'Not set');
            await storage.write(key: 'dupr_id', value: userData['dupr_id']?.toString() ?? '');
            await storage.write(key: 'avatar_url', value: userData['avatar_url']?.toString() ?? '');
            await storage.write(key: 'about', value: userData['about']?.toString() ?? '');
            await storage.write(key: 'credit_balance', value: userData['credit_balance']?.toString() ?? '0');
            await storage.write(key: 'suspend', value: userData['suspend']?.toString() ?? 'false');
            
            if (userData['created_at'] != null) {
              await storage.write(key: 'created_at', value: userData['created_at'].toString());
            }
            if (userData['updated_at'] != null) {
              await storage.write(key: 'updated_at', value: userData['updated_at'].toString());
            }

            // Update UserProfile provider
            if (mounted) {
              final userProfile = Provider.of<UserProfile>(context, listen: false);
              userProfile.updateFromMap(userData);
              await userProfile.saveToStorage();
            }

            print('Login successful for user: ${userData['name']}');

            if (mounted) {
              Navigator.pushReplacementNamed(context, '/main');
            }
          } else {
            _showErrorSnackBar('Login successful, but no token received. Please try again.');
          }
        } else {
          // Handle error response
          String errorMessage = 'Login failed. Please check your credentials.';
          
          try {
            final errorData = jsonDecode(response.body);
            errorMessage = errorData['message'] ?? errorMessage;
          } catch (jsonError) {
            print('Failed to parse error response as JSON: $jsonError');
            // If response is not JSON, show generic error
            if (response.statusCode == 404) {
              errorMessage = 'API endpoint not found. Please check the server configuration.';
            } else if (response.statusCode == 500) {
              errorMessage = 'Server error. Please try again later.';
            } else {
              errorMessage = 'Login failed. Status code: ${response.statusCode}';
            }
          }
          
          _showErrorSnackBar(errorMessage);
        }
      } catch (e) {
        print('Login error: $e');
        String errorMessage = 'Network error. Please check your connection and try again.';
        
        // Provide more specific error messages
        if (e.toString().contains('FormatException')) {
          errorMessage = 'Server returned invalid response. Please check API configuration.';
        } else if (e.toString().contains('SocketException')) {
          errorMessage = 'Cannot connect to server. Please check your internet connection.';
        } else if (e.toString().contains('TimeoutException')) {
          errorMessage = 'Request timed out. Please try again.';
        }
        
        _showErrorSnackBar(errorMessage);
      } finally {
        if (mounted) {
          setState(() {
            _isLoading = false;
          });
        }
      }
    }
  }

  void _showErrorSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          message,
          style: const TextStyle(color: Colors.white),
        ),
        backgroundColor: Colors.redAccent,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        margin: const EdgeInsets.all(16),
        duration: const Duration(seconds: 3),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF9FBFD),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Form(
            key: _formKey,
            autovalidateMode: AutovalidateMode.onUserInteraction,
            child: Column(
              children: [
                const SizedBox(height: 8),
                SvgPicture.asset('assets/images/register_illustration.svg', height: 240),
                const SizedBox(height: 1),
                const Text(
                  "Log In to FirstShot",
                  style: TextStyle(fontSize: 17, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 18),
                _buildTextField("Mobile No:", _mobileController, prefix: "+60", isPhone: true),
                const SizedBox(height: 12),
                _buildTextField("Password:", _passwordController, isPassword: true),
                const SizedBox(height: 20),
                ElevatedButton(
                  onPressed: _isLoading ? null : _submitForm,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF4997D0),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(30)),
                    minimumSize: const Size.fromHeight(50),
                  ),
                  child: _isLoading
                      ? const SizedBox(
                          height: 20,
                          width: 20,
                          child: CircularProgressIndicator(
                            color: Colors.white,
                            strokeWidth: 2,
                          ),
                        )
                      : const Text(
                          "Log In",
                          style: TextStyle(color: Colors.white, fontSize: 17),
                        ),
                ),
                const SizedBox(height: 12),
                OutlinedButton(
                  onPressed: () {
                    Navigator.pushNamed(context, '/welcome');
                  },
                  style: OutlinedButton.styleFrom(
                    foregroundColor: Colors.black,
                    side: const BorderSide(color: Colors.black12),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(30),
                    ),
                    minimumSize: const Size.fromHeight(50),
                  ),
                  child: const Text('Back', style: TextStyle(fontSize: 16)),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildTextField(String label, TextEditingController controller,
      {bool isPhone = false, bool isPassword = false, String? prefix}) {
    return TextFormField(
      controller: controller,
      keyboardType: isPhone ? TextInputType.phone : TextInputType.text,
      obscureText: isPassword,
      inputFormatters: isPhone ? [
        FilteringTextInputFormatter.digitsOnly,
        LengthLimitingTextInputFormatter(9),
      ] : [],
      decoration: InputDecoration(
        labelText: label,
        prefixText: isPhone ? '+60' : prefix,
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
        suffixIcon: isPassword ? const Icon(Icons.lock) : null,
        helperText: isPhone ? "Enter 9 digits only (e.g., 123456789)" : null,
      ),
      validator: (value) {
        if (value == null || value.trim().isEmpty) return "Required";
        if (isPhone) {
          final cleaned = value.replaceAll(RegExp(r'[^0-9]'), '');
          // User should only enter 9 digits (without +60)
          if (cleaned.length != 9) {
            return "Enter exactly 9 digits (without +60)";
          }
          // First digit should be 1-9 (Malaysian mobile format)
          if (!RegExp(r'^[1-9][0-9]{8}$').hasMatch(cleaned)) {
            return "Enter a valid Malaysian mobile number";
          }
        }
        if (isPassword && value.length < 6) {
          return "Password must be at least 6 characters";
        }
        return null;
      },
    );
  }
}

// MobileNumberFormatter removed - now using FilteringTextInputFormatter.digitsOnly