import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:http/http.dart' as http;
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'dart:convert';

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
  final storage = FlutterSecureStorage();

  Future<void> _submitForm() async {
    if (_formKey.currentState!.validate()) {
      setState(() {
        _isLoading = true;
      });

      // Clean input and prepend +60 to form +60123456789
      String cleanedMobile = _mobileController.text.replaceAll(RegExp(r'[^0-9]'), '');
      cleanedMobile = '+60$cleanedMobile';

      final payload = {
        'mobile_no': cleanedMobile,
        'password': _passwordController.text,
      };

      try {
        final response = await http.post(
          Uri.parse('https://firstshot.my/api/auth/login/mobile'),
          headers: {'Content-Type': 'application/json'},
          body: jsonEncode(payload),
        );

        setState(() {
          _isLoading = false;
        });

        print('Login API Response: ${response.statusCode} - ${response.body}');
        print('Payload: $payload');

        if (response.statusCode == 200 || response.statusCode == 201) {
          final responseData = jsonDecode(response.body);
          final token = responseData['data']?['access_token'];
          if (token != null) {
            // Store token and user data in FlutterSecureStorage
            await storage.write(key: 'auth_token', value: token);
            await storage.write(
                key: 'user_name',
                value: responseData['data']['customer']['name']?.trim() ?? 'User');
            await storage.write(
                key: 'member_since',
                value: responseData['data']['customer']['created_at'] ?? '');
            await storage.write(
                key: 'pickleball_level',
                value: [
                  'Beginner',
                  'Intermediate',
                  'Advanced'
                ].contains(responseData['data']['customer']['level'])
                    ? responseData['data']['customer']['level']
                    : 'N/A');
            await storage.write(
                key: 'avatar_url',
                value: responseData['data']['customer']['avatar_url'] ?? '');
            await storage.write(
                key: 'mobile_no',
                value: responseData['data']['customer']['mobile_no'] ?? '');
            await storage.write(
                key: 'email',
                value: responseData['data']['customer']['email'] ?? '');
            await storage.write(
                key: 'dupr_id',
                value: responseData['data']['customer']['dupr_id'] ?? '');
            await storage.write(
                key: 'location',
                value: [
                  'Kuala Lumpur',
                  'Putrajaya',
                  'Johor',
                  'Kedah',
                  'Kelantan',
                  'Malacca',
                  'Negeri Sembilan',
                  'Pahang',
                  'Perak',
                  'Perlis',
                  'Penang',
                  'Sabah',
                  'Sarawak',
                  'Terengganu',
                  'Labuan'
                ].contains(responseData['data']['customer']['location'])
                    ? responseData['data']['customer']['location']
                    : 'N/A');

            print('Stored Data: token=$token, name=${await storage.read(key: 'user_name')}, '
                'member_since=${await storage.read(key: 'member_since')}, '
                'level=${await storage.read(key: 'pickleball_level')}, '
                'avatar=${await storage.read(key: 'avatar_url')}');

            Navigator.pushReplacementNamed(context, '/main');
          } else {
            _showErrorSnackBar('Login successful, but no token received. Please try again.');
          }
        } else {
          final errorData = jsonDecode(response.body);
          final errorMessage = errorData['message'] ?? 'Invalid mobile number or password.';
          _showErrorSnackBar(errorMessage);
        }
      } catch (e) {
        setState(() {
          _isLoading = false;
        });
        print('Login Error: $e');
        _showErrorSnackBar('Network error. Please check your connection and try again.');
      }
    } else {
      _showErrorSnackBar('Please enter a valid mobile number and password.');
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
      inputFormatters: isPhone ? [MobileNumberFormatter()] : [],
      decoration: InputDecoration(
        labelText: label,
        prefixText: isPhone ? '+60' : prefix,
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
        suffixIcon: isPassword ? const Icon(Icons.lock) : null,
        helperText: isPhone ? "Enter a valid 9-digit Malaysian number (e.g., 123456789)" : null,
      ),
      validator: (value) {
        if (value == null || value.trim().isEmpty) return "Required";
        if (isPhone) {
          final cleaned = value.replaceAll(RegExp(r'[^0-9]'), '');
          final pattern = RegExp(r'^\d{9}$');
          if (!pattern.hasMatch(cleaned)) {
            return "Enter a valid 9-digit Malaysian mobile number (e.g., 123456789)";
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

class MobileNumberFormatter extends TextInputFormatter {
  @override
  TextEditingValue formatEditUpdate(
    TextEditingValue oldValue,
    TextEditingValue newValue,
  ) {
    final raw = newValue.text.replaceAll(RegExp(r'[^0-9]'), '');
    if (raw.length > 9) {
      return oldValue;
    }
    return TextEditingValue(
      text: raw,
      selection: TextSelection.collapsed(offset: raw.length),
    );
  }
}