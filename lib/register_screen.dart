import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';

class RegisterScreen extends StatefulWidget {
  const RegisterScreen({super.key});

  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
  final _formKey = GlobalKey<FormState>();
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _mobileController = TextEditingController();
  final TextEditingController _dobController = TextEditingController();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  final TextEditingController _passwordConfirmController = TextEditingController();
  bool _isLoading = false;

  void _pickDate() async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: DateTime(2013),
      firstDate: DateTime(1900),
      lastDate: DateTime.now(),
      builder: (context, child) {
        return Theme(
          data: ThemeData.light().copyWith(
            colorScheme: const ColorScheme.light(
              primary: Color(0xFF4997D0),
              onPrimary: Colors.white,
              surface: Colors.white,
              onSurface: Colors.black,
            ),
            textButtonTheme: TextButtonThemeData(
              style: TextButton.styleFrom(foregroundColor: Color(0xFF4997D0)),
            ),
          ),
          child: child!,
        );
      },
    );

    if (picked != null) {
      final age = DateTime.now().difference(picked).inDays ~/ 365;
      if (age < 12) {
        _showErrorSnackBar("Users below 12 years old are not allowed");
        return;
      }

      _dobController.text =
          "${picked.year}-${picked.month.toString().padLeft(2, '0')}-${picked.day.toString().padLeft(2, '0')}";
    }
  }

  Future<void> _submitForm() async {
    if (_formKey.currentState!.validate()) {
      setState(() {
        _isLoading = true;
      });

      // Ensure mobile number is in +60167413625 format
      String cleanedMobile = _mobileController.text.replaceAll(RegExp(r'[^0-9+]'), '');
      if (!cleanedMobile.startsWith('+60')) {
        cleanedMobile = '+60$cleanedMobile'; // Prepend +60 if not present
      }

      final payload = {
        'name': _nameController.text,
        'email': _emailController.text,
        'mobile_no': cleanedMobile,
        'password': _passwordController.text,
        'password_confirmation': _passwordConfirmController.text,
        'date_of_birth': _dobController.text,
      };

      try {
        final response = await http.post(
          Uri.parse('https://firstshot.my/api/auth/register'),
          headers: {'Content-Type': 'application/json'},
          body: jsonEncode(payload),
        );

        setState(() {
          _isLoading = false;
        });

        if (response.statusCode == 200 || response.statusCode == 201) {
          final responseData = jsonDecode(response.body);
          final token = responseData['data']?['access_token'];
          if (token != null) {
            final prefs = await SharedPreferences.getInstance();
            final name = responseData['data']['customer']['name']?.trim() ?? 'User';
            final apiLevel = responseData['data']['customer']['level'] ?? 'N/A';
            final validLevel = ['Beginner', 'Intermediate', 'Advanced'].contains(apiLevel) ? apiLevel : 'N/A';
            final apiLocation = responseData['data']['customer']['location'] ?? 'N/A';
            final validLocation = [
              'Kuala Lumpur', 'Putrajaya', 'Johor', 'Kedah', 'Kelantan', 'Malacca',
              'Negeri Sembilan', 'Pahang', 'Perak', 'Perlis', 'Penang', 'Sabah',
              'Sarawak', 'Terengganu', 'Labuan'
            ].contains(apiLocation) ? apiLocation : 'N/A';

            await prefs.setString('auth_token', token);
            await prefs.setString('user_name', name);
            await prefs.setString('member_since', responseData['data']['customer']['created_at'] ?? '');
            await prefs.setString('pickleball_level', validLevel);
            await prefs.setString('avatar_url', responseData['data']['customer']['avatar_url'] ?? '');
            await prefs.setString('mobile_no', responseData['data']['customer']['mobile_no'] ?? '');
            await prefs.setString('email', responseData['data']['customer']['email'] ?? '');
            await prefs.setString('dupr_id', responseData['data']['customer']['dupr_id'] ?? '');
            await prefs.setString('location', validLocation);
          }
          Navigator.pushNamed(context, '/main', arguments: cleanedMobile);
        } else {
          final errorData = jsonDecode(response.body);
          final errorMessage = errorData['message'] ?? 'Registration failed. Please try again.';
          _showErrorSnackBar(errorMessage);
        }
      } catch (e) {
        setState(() {
          _isLoading = false;
        });
        _showErrorSnackBar('Network error. Please check your connection and try again.');
      }
    } else {
      _showErrorSnackBar('Please fill in all required fields correctly.');
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
                  "Let’s get to know you better",
                  style: TextStyle(fontSize: 17, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 18),

                _buildTextField("Name:", _nameController),
                const SizedBox(height: 12),
                _buildTextField("Mobile No:", _mobileController, prefix: "+60", isPhone: true),
                const SizedBox(height: 12),
                _buildDateField("Date of Birth:", _dobController),
                const SizedBox(height: 12),
                _buildTextField("Email ID:", _emailController, isEmail: true),
                const SizedBox(height: 12),
                _buildTextField("Password:", _passwordController, isPassword: true),
                const SizedBox(height: 12),
                _buildTextField("Confirm Password:", _passwordConfirmController, isPassword: true),

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
                          "Next",
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
      {bool isPhone = false, bool isEmail = false, bool isPassword = false, String? prefix}) {
    return TextFormField(
      controller: controller,
      keyboardType: isPhone
          ? TextInputType.phone
          : isEmail
              ? TextInputType.emailAddress
              : TextInputType.text,
      obscureText: isPassword,
      inputFormatters: isPhone ? [MobileNumberFormatter()] : [],
      decoration: InputDecoration(
        labelText: label,
        prefixText: prefix,
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
        suffixIcon: isPassword ? const Icon(Icons.lock) : null,
        helperText: isPhone ? "Enter a valid Malaysian number (e.g., +60167413625)" : null,
      ),
      validator: (value) {
        if (value == null || value.trim().isEmpty) return "Required";
        if (isPhone) {
          final cleaned = value.replaceAll(RegExp(r'[^0-9+]'), '');
          final pattern = RegExp(r'^\+60[1-9][0-9]{8}$'); // Strictly +60 followed by 9 digits
          if (!pattern.hasMatch(cleaned)) {
            return "Enter a valid Malaysian mobile number (e.g., +60167413625)";
          }
        }
        if (isEmail && !RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$').hasMatch(value)) {
          return "Invalid email";
        }
        if (isPassword && value.length < 6) {
          return "Password must be at least 6 characters";
        }
        if (label == "Confirm Password:" && value != _passwordController.text) {
          return "Passwords do not match";
        }
        return null;
      },
    );
  }

  Widget _buildDateField(String label, TextEditingController controller) {
    return TextFormField(
      controller: controller,
      readOnly: true,
      onTap: _pickDate,
      decoration: InputDecoration(
        labelText: label,
        suffixIcon: const Icon(Icons.calendar_today),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
      ),
      validator: (value) => value == null || value.isEmpty ? "Required" : null,
    );
  }
}

class MobileNumberFormatter extends TextInputFormatter {
  @override
  TextEditingValue formatEditUpdate(
    TextEditingValue oldValue,
    TextEditingValue newValue,
  ) {
    final raw = newValue.text.replaceAll(RegExp(r'[^0-9+]'), '');
    if (!raw.startsWith('+60') && raw.isNotEmpty) {
      // Automatically prepend +60 if not present
      final numericPart = raw.startsWith('+') ? raw.substring(1) : raw;
      final formatted = '+60$numericPart';
      return TextEditingValue(
        text: formatted,
        selection: TextSelection.collapsed(offset: formatted.length),
      );
    }
    // Limit to +60 followed by up to 9 digits
    if (raw.length > 12) {
      return oldValue; // Prevent further input
    }
    return TextEditingValue(
      text: raw,
      selection: TextSelection.collapsed(offset: raw.length),
    );
  }
}