import 'package:flutter/material.dart';
import 'package:curved_navigation_bar/curved_navigation_bar.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:http/http.dart' as http;
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:image_picker/image_picker.dart';
import 'package:intl/intl.dart';
import 'dart:io';
import 'dart:convert';
import 'package:flutter/services.dart';
import 'user_profile.dart';

class EditProfilePage extends StatefulWidget {
  const EditProfilePage({super.key});

  @override
  State<EditProfilePage> createState() => _EditProfilePageState();
}

class _EditProfilePageState extends State<EditProfilePage> {
  final _formKey = GlobalKey<FormState>();
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _mobileController = TextEditingController();
  final TextEditingController _duprIdController = TextEditingController();
  final TextEditingController _emailController = TextEditingController();
  String? _selectedLevel;
  String? _selectedLocation;
  File? _avatarImage;
  bool _isLoading = false;
  bool _isDataLoaded = false;

  final List<String> _levels = ['Beginner', 'Intermediate', 'Advanced'];
  final List<String> _locations = [
    'Kuala Lumpur', 'Putrajaya', 'Johor', 'Kedah', 'Kelantan', 'Malacca',
    'Negeri Sembilan', 'Pahang', 'Perak', 'Perlis', 'Penang', 'Sabah',
    'Sarawak', 'Terengganu', 'Labuan'
  ];

  final List<IconData> _icons = [
    Icons.calendar_today, Icons.assignment, Icons.home, Icons.sports_tennis, Icons.settings,
  ];

  final List<String> _labels = ['Booking', 'Lessons', 'Home', 'Instructors', 'Settings'];
  int _selectedIndex = 4;

  @override
  void initState() {
    super.initState();
    _loadProfileData();
  }

  Future<void> _loadProfileData() async {
    final userProfile = Provider.of<UserProfile>(context, listen: false);
    await userProfile.loadProfileData();
    setState(() {
      _nameController.text = userProfile.name.isNotEmpty ? userProfile.name : '';
      _emailController.text = userProfile.email.isNotEmpty ? userProfile.email : '';
      _mobileController.text = userProfile.mobileNo.isNotEmpty
          ? userProfile.mobileNo.replaceAll(RegExp(r'^\+60'), '')
          : '';
      _duprIdController.text = userProfile.duprId.isNotEmpty ? userProfile.duprId : '';
      _selectedLevel = _levels.contains(userProfile.level) ? userProfile.level : null;
      _selectedLocation = _locations.contains(userProfile.location) ? userProfile.location : null;
      _isDataLoaded = true;
      print('Loaded Profile Data: name="${_nameController.text}", email="${_emailController.text}", '
            'mobile="${_mobileController.text}", duprId="${_duprIdController.text}", '
            'level="$_selectedLevel", location="$_selectedLocation"');
    });
  }

  void _onItemTapped(int index) {
    setState(() => _selectedIndex = index);
    switch (index) {
      case 0:
        Navigator.pushNamed(context, '/booking');
        break;
      case 1:
        Navigator.pushNamed(context, '/coaching');
        break;
      case 2:
        Navigator.pushNamed(context, '/main');
        break;
      case 3:
        Navigator.pushNamed(context, '/instructors');
        break;
      case 4:
        Navigator.pushNamed(context, '/settings');
        break;
    }
  }

  Future<void> _pickImage() async {
    final picker = ImagePicker();
    final pickedFile = await picker.pickImage(source: ImageSource.gallery);
    if (pickedFile != null) {
      setState(() {
        _avatarImage = File(pickedFile.path);
      });
    }
  }

  Future<void> _updateProfile() async {
    if (!_isDataLoaded) {
      _showSnackBar('Data is still loading. Please wait.');
      return;
    }

    final name = _nameController.text.trim();
    final email = _emailController.text.trim();
    final mobile = _mobileController.text.trim();

    print('Form Input: name="$name", email="$email", mobile="$mobile", '
          'duprId="${_duprIdController.text.trim()}", level="$_selectedLevel", '
          'location="$_selectedLocation", avatarImage="${_avatarImage?.path}"');

    if (name.isEmpty || email.isEmpty) {
      _showSnackBar('Name and email cannot be empty.');
      return;
    }

    if (!_formKey.currentState!.validate()) {
      print('Form validation failed.');
      return;
    }

    setState(() {
      _isLoading = true;
    });

    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('auth_token');
    print('Auth Token: $token');
    if (token == null) {
      _showSnackBar('No authentication token found. Please log in again.');
      setState(() {
        _isLoading = false;
      });
      return;
    }

    // Use http.put to test field submission
    final payload = {
      'name': name,
      'email': email,
      'mobile_no': '+60$mobile',
      'dupr_id': _duprIdController.text.trim(),
      if (_selectedLevel != null) 'level': _selectedLevel,
      if (_selectedLocation != null) 'location': _selectedLocation,
    };

    print('Sending http.put with payload: $payload');

    try {
      final response = await http.put(
        Uri.parse('https://firstshot.my/api/auth/profile'),
        headers: {
          'Authorization': 'Bearer $token',
          'Accept': 'application/json',
          'Content-Type': 'application/json',
        },
        body: jsonEncode(payload),
      ).timeout(
        const Duration(seconds: 30),
        onTimeout: () {
          setState(() {
            _isLoading = false;
          });
          _showSnackBar('Request timed out. Please try again.');
          return http.Response('Timeout', 408);
        },
      );

      setState(() {
        _isLoading = false;
      });

      print('Update Profile Response: ${response.statusCode} - ${response.body}');

      if (response.statusCode == 200) {
        final responseData = jsonDecode(response.body);
        if (responseData['success'] == true) {
          final userProfile = Provider.of<UserProfile>(context, listen: false);
          String? avatarUrl = responseData['data']['customer']?['avatar_url'];
          if (avatarUrl != null && !avatarUrl.startsWith('http')) {
            avatarUrl = 'https://firstshot.my/storage/$avatarUrl';
          }

          await userProfile.updateProfileData(
            name: name,
            email: email,
            level: _selectedLevel ?? 'N/A',
            mobileNo: '+60$mobile',
            duprId: _duprIdController.text.trim(),
            location: _selectedLocation ?? 'N/A',
            avatarUrl: avatarUrl ?? '',
            memberSince: responseData['data']?['created_at'] != null
                ? DateFormat('dd.MM.yyyy').format(DateTime.parse(responseData['data']['created_at']))
                : userProfile.memberSince,
          );

          _showSnackBar('Profile updated successfully!');
          Navigator.pop(context, true);
        } else {
          _showSnackBar(responseData['message'] ?? 'Failed to update profile.');
        }
      } else {
        String errorMessage = 'Failed to update profile.';
        if (response.body.isNotEmpty) {
          final responseData = jsonDecode(response.body);
          errorMessage = responseData['message'] ?? errorMessage;
          if (response.statusCode == 422 && responseData['errors'] != null) {
            errorMessage = responseData['errors'].entries.map((e) => '${e.key}: ${e.value.join(', ')}').join(', ');
          } else if (response.statusCode == 401) {
            errorMessage = 'Unauthorized. Please log in again.';
          }
        }
        _showSnackBar(errorMessage);

        // Fallback to MultipartRequest if http.put fails
        if (response.statusCode == 422) {
          print('Trying fallback MultipartRequest');
          final request = http.MultipartRequest(
            'PUT',
            Uri.parse('https://firstshot.my/api/auth/profile'),
          );
          request.headers['Authorization'] = 'Bearer $token';
          request.headers['Accept'] = 'application/json';
          request.fields.addAll(payload.map((key, value) => MapEntry(key, value.toString())));
          if (_avatarImage != null) {
            request.files.add(await http.MultipartFile.fromPath('avatar', _avatarImage!.path));
            print('Avatar file added: ${_avatarImage!.path}');
          }

          print('Sending MultipartRequest with fields: ${request.fields}');

          try {
            final streamedResponse = await request.send().timeout(
              const Duration(seconds: 30),
              onTimeout: () {
                setState(() {
                  _isLoading = false;
                });
                _showSnackBar('MultipartRequest timed out. Please try again.');
                return http.StreamedResponse(Stream.value([]), 408);
              },
            );
            final fallbackResponse = await http.Response.fromStream(streamedResponse);
            print('Fallback Response: ${fallbackResponse.statusCode} - ${fallbackResponse.body}');
            if (fallbackResponse.statusCode == 200) {
              _showSnackBar('Profile updated successfully via fallback.');
              Navigator.pop(context, true);
            } else {
              _showSnackBar('Fallback failed: ${fallbackResponse.body}');
            }
          } catch (e) {
            print('Fallback Error: $e');
            _showSnackBar('Fallback network error. Please try again.');
          }
        }
      }
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
      print('Update Profile Error: $e');
      _showSnackBar('Network error. Please check your connection and try again.');
    }
  }

  void _showSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          message,
          style: const TextStyle(color: Colors.white),
        ),
        backgroundColor: message.contains('successfully') ? Colors.green : Colors.redAccent,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        margin: const EdgeInsets.all(16),
        duration: const Duration(seconds: 3),
      ),
    );
  }

  Future<void> _launchDUPR() async {
    const url = 'https://dashboard.dupr.com/login';
    if (await canLaunchUrl(Uri.parse(url))) {
      await launchUrl(Uri.parse(url), mode: LaunchMode.externalApplication);
    } else {
      _showSnackBar('Could not launch DUPR URL');
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _mobileController.dispose();
    _duprIdController.dispose();
    _emailController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: _isDataLoaded
            ? SingleChildScrollView(
                child: Form(
                  key: _formKey,
                  autovalidateMode: AutovalidateMode.onUserInteraction,
                  child: Column(
                    children: [
                      Stack(
                        alignment: Alignment.center,
                        children: [
                          ClipPath(
                            clipper: TopCurveClipper(),
                            child: Image.asset(
                              'assets/images/splash_bgnew.png',
                              width: double.infinity,
                              height: 200,
                              fit: BoxFit.cover,
                            ),
                          ),
                          Positioned(
                            top: 12,
                            left: 12,
                            child: IconButton(
                              icon: const Icon(Icons.arrow_back, color: Colors.white, size: 28),
                              onPressed: () => Navigator.pop(context),
                            ),
                          ),
                          Positioned(
                            bottom: -1,
                            child: Stack(
                              alignment: Alignment.center,
                              children: [
                                GestureDetector(
                                  onTap: _pickImage,
                                  child: CircleAvatar(
                                    radius: 50,
                                    backgroundColor: Colors.grey[200],
                                    backgroundImage: _avatarImage != null
                                        ? FileImage(_avatarImage!)
                                        : const AssetImage('assets/icons/avatar.png') as ImageProvider,
                                    child: _avatarImage == null
                                        ? const Icon(Icons.person, size: 50, color: Colors.grey)
                                        : null,
                                  ),
                                ),
                                Positioned(
                                  right: -1,
                                  bottom: 30,
                                  child: Container(
                                    decoration: const BoxDecoration(
                                      color: Colors.white,
                                      shape: BoxShape.circle,
                                    ),
                                    child: const Icon(Icons.add, size: 24),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 20),
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 24),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            _buildInputField("Name", _nameController),
                            _buildInputField("Mobile No", _mobileController, isPhone: true),
                            _buildDropdown("Level", _levels, _selectedLevel, (value) {
                              setState(() => _selectedLevel = value);
                            }),
                            _buildInputField("DUPR ID", _duprIdController),
                            GestureDetector(
                              onTap: _launchDUPR,
                              child: const Padding(
                                padding: EdgeInsets.only(left: 8, bottom: 12),
                                child: Text(
                                  "Click here to get your DUPR ID",
                                  style: TextStyle(
                                    color: Colors.blueAccent,
                                    fontSize: 13,
                                    decoration: TextDecoration.underline,
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                              ),
                            ),
                            _buildDropdown("Location", _locations, _selectedLocation, (value) {
                              setState(() => _selectedLocation = value);
                            }),
                            _buildInputField("Email", _emailController, isEmail: true),
                            const SizedBox(height: 2),
                            ElevatedButton(
                              onPressed: _isLoading ? null : _updateProfile,
                              style: ElevatedButton.styleFrom(
                                backgroundColor: const Color(0xFF4997D0),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(40),
                                ),
                                minimumSize: const Size.fromHeight(55),
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
                                      "Update my Profile",
                                      style: TextStyle(fontSize: 16, color: Colors.white, fontWeight: FontWeight.bold),
                                    ),
                            ),
                            const SizedBox(height: 30),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              )
            : const Center(child: CircularProgressIndicator()),
      ),
      bottomNavigationBar: CurvedNavigationBar(
        index: _selectedIndex,
        backgroundColor: Colors.transparent,
        color: Colors.black,
        height: 65,
        animationDuration: const Duration(milliseconds: 300),
        items: List.generate(_icons.length, (index) {
          return Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                _icons[index],
                color: _selectedIndex == index ? const Color(0xFF4997D0) : Colors.white,
                size: 24,
              ),
              if (_selectedIndex != index)
                Text(_labels[index], style: const TextStyle(color: Colors.white, fontSize: 10)),
            ],
          );
        }),
        onTap: _onItemTapped,
      ),
    );
  }

  Widget _buildInputField(String label, TextEditingController controller, {bool isPhone = false, bool isEmail = false}) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16.0),
      child: TextFormField(
        controller: controller,
        keyboardType: isPhone ? TextInputType.phone : isEmail ? TextInputType.emailAddress : TextInputType.text,
        inputFormatters: isPhone ? [MobileNumberFormatter()] : [],
        decoration: InputDecoration(
          labelText: "$label :",
          labelStyle: const TextStyle(color: Colors.brown),
          contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(30),
            borderSide: const BorderSide(color: Colors.blue),
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(30),
            borderSide: const BorderSide(color: Colors.blue),
          ),
          prefixText: isPhone ? '+60' : null,
          helperText: isPhone ? "Enter a valid 9-digit Malaysian number (e.g., 123456789)" : null,
        ),
        validator: (value) {
          final trimmedValue = value?.trim() ?? '';
          if (label == "Name" && trimmedValue.isEmpty) {
            return 'Name is required.';
          }
          if (label == "Email") {
            if (trimmedValue.isEmpty) {
              return 'Email is required.';
            }
            if (!RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$').hasMatch(trimmedValue)) {
              return 'Valid email is required.';
            }
          }
          if (label == "Mobile No") {
            final cleaned = trimmedValue.replaceAll(RegExp(r'[^0-9]'), '');
            final pattern = RegExp(r'^\d{9}$');
            if (!pattern.hasMatch(cleaned)) {
              return "Enter a valid 9-digit Malaysian mobile number (e.g., 123456789)";
            }
          }
          return null;
        },
      ),
    );
  }

  Widget _buildDropdown(String label, List<String> items, String? selected, ValueChanged<String?> onChanged) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16.0),
      child: DropdownButtonFormField<String>(
        value: selected,
        onChanged: onChanged,
        icon: const Icon(Icons.keyboard_arrow_down_rounded, color: Colors.brown),
        style: const TextStyle(fontSize: 15, color: Colors.black),
        dropdownColor: Colors.white,
        decoration: InputDecoration(
          labelText: "$label :",
          labelStyle: const TextStyle(color: Colors.brown),
          contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(30),
            borderSide: const BorderSide(color: Colors.blue),
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(30),
            borderSide: const BorderSide(color: Colors.blue),
          ),
        ),
        items: items
            .map((item) => DropdownMenuItem<String>(
                  value: item,
                  child: Text(item),
                ))
            .toList(),
      ),
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

class TopCurveClipper extends CustomClipper<Path> {
  @override
  Path getClip(Size size) {
    final path = Path();
    path.lineTo(0, size.height - 40);
    path.quadraticBezierTo(size.width / 2, size.height, size.width, size.height - 40);
    path.lineTo(size.width, 0);
    path.close();
    return path;
  }

  @override
  bool shouldReclip(CustomClipper<Path> oldClipper) => false;
}