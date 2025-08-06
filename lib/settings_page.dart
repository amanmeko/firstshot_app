import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:curved_navigation_bar/curved_navigation_bar.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';

class SettingsPage extends StatefulWidget {
  const SettingsPage({super.key});

  @override
  State<SettingsPage> createState() => _SettingsPageState();
}

class _SettingsPageState extends State<SettingsPage> {
  int _selectedIndex = 4;

  Widget _buildSettingItem(String iconAsset, String title, String subtitle, VoidCallback onTap) {
    return ListTile(
      leading: SizedBox(
        width: 40,
        height: 40,
        child: SvgPicture.asset(iconAsset, fit: BoxFit.contain),
      ),
      title: Text(title, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
      subtitle: Text(subtitle, style: const TextStyle(fontSize: 13, color: Colors.grey)),
      trailing: const Icon(Icons.arrow_forward_ios, size: 16),
      onTap: onTap,
    );
  }

  Future<void> _logout() async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('auth_token');
    if (token == null) {
      _showSnackBar('No active session found.', Colors.redAccent);
      Navigator.pushNamedAndRemoveUntil(context, '/login', (route) => false);
      return;
    }

    try {
      final response = await http.post(
        Uri.parse('https://firstshot.my/api/auth/logout'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
      );

      print('Logout API Response: ${response.statusCode} - ${response.body}'); // Debug print

      if (response.statusCode == 200) {
        final responseData = jsonDecode(response.body);
        if (responseData['success'] == true) {
          // Clear all stored data
          await prefs.remove('auth_token');
          await prefs.remove('user_name');
          await prefs.remove('member_since');
          await prefs.remove('pickleball_level');
          _showSnackBar('Logged out successfully.', Colors.green);
          Navigator.pushNamedAndRemoveUntil(context, '/login', (route) => false);
        } else {
          _showSnackBar(responseData['message'] ?? 'Logout failed.', Colors.redAccent);
        }
      } else {
        _showSnackBar('Logout failed. Please try again.', Colors.redAccent);
      }
    } catch (e) {
      print('Logout Error: $e'); // Debug print
      _showSnackBar('Network error. Please check your connection.', Colors.redAccent);
    }
  }

  void _confirmLogout(BuildContext context) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text("Logout Confirmation"),
        content: const Text("Are you sure you want to logout?"),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: const Text("No"),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.of(ctx).pop();
              _logout(); // Call the logout API
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF4997D0),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
            ),
            child: const Text("Yes", style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  void _showSnackBar(String message, Color backgroundColor) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          message,
          style: const TextStyle(color: Colors.white),
        ),
        backgroundColor: backgroundColor,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        margin: const EdgeInsets.all(16),
        duration: const Duration(seconds: 3),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final bool showBack = Navigator.canPop(context);
    final List<String> _labels = ['Booking', 'Lessons', 'Home', 'Instructors', 'Settings'];
    final List<IconData> _icons = [
      Icons.calendar_today,
      Icons.assignment,
      Icons.home,
      Icons.sports_tennis_rounded,
      Icons.settings,
    ];

    return Scaffold(
      backgroundColor: const Color(0xFFF9FBFD),
      appBar: showBack
          ? AppBar(
              backgroundColor: Colors.white,
              elevation: 0,
              leading: IconButton(
                icon: const Icon(Icons.arrow_back, color: Colors.black),
                onPressed: () => Navigator.pop(context),
              ),
              title: const Text('Settings', style: TextStyle(color: Colors.black)),
              centerTitle: true,
            )
          : null,
      bottomNavigationBar: showBack
          ? null
          : CurvedNavigationBar(
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
                      color: Colors.white,
                      size: 24,
                    ),
                    if (_selectedIndex != index)
                      Text(_labels[index], style: const TextStyle(color: Colors.white, fontSize: 10)),
                  ],
                );
              }),
              onTap: (index) {
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
                    // stay
                    break;
                }
              },
            ),
      body: SafeArea(
        child: Column(
          children: [
            Stack(
              clipBehavior: Clip.none,
              alignment: Alignment.bottomCenter,
              children: [
                SvgPicture.asset(
                  'assets/images/newtops.svg',
                  width: double.infinity,
                  height: 240,
                  fit: BoxFit.cover,
                ),
                const Positioned(
                  bottom: -20,
                  child: CircleAvatar(
                    radius: 50,
                    backgroundImage: AssetImage('assets/icons/avatar.png'),
                  ),
                ),
              ],
            ),
            Expanded(
              child: ListView(
                padding: const EdgeInsets.fromLTRB(6, 30, 30, 10),
                children: [
                  _buildSettingItem(
                    'assets/icons/profileicon.svg',
                    'Profile',
                    'Edit User Profile',
                    () => Navigator.pushNamed(context, '/profile').then((_) {
                      // Return true to indicate profile might have been updated
                      Navigator.pop(context, true);
                    }),
                  ),
                  _buildSettingItem(
                    'assets/icons/transicon.svg',
                    'Transactions',
                    'Orders & Payment Details',
                    () => Navigator.pushNamed(context, '/transactions'),
                  ),
                  _buildSettingItem(
                    'assets/icons/matchicon.svg',
                    'Game Match Making',
                    'Find Pickleball Buddies',
                    () => Navigator.pushNamed(context, '/matchmaking'),
                  ),
                  _buildSettingItem(
                    'assets/icons/abouticon.svg',
                    'About Us',
                    'About FirstShot',
                    () => Navigator.pushNamed(context, '/about'),
                  ),
                  _buildSettingItem(
                    'assets/icons/privacyicon.svg',
                    'Privacy & Policy',
                    'FirstShot Privacy & Policy',
                    () => Navigator.pushNamed(context, '/privacy'),
                  ),
                  _buildSettingItem(
                    'assets/icons/contacticon.svg',
                    'Contact Us',
                    'Need Help? Contact Us',
                    () => Navigator.pushNamed(context, '/contact'),
                  ),
                  _buildSettingItem(
                    'assets/icons/deleteicon.svg',
                    'Data Deletion',
                    'Account Deletion Request',
                    () => Navigator.pushNamed(context, '/DataDeletionPage'),
                  ),
                  const SizedBox(height: 20),
                  ElevatedButton(
                    onPressed: () => _confirmLogout(context),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF4997D0),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      minimumSize: const Size.fromHeight(50),
                    ),
                    child: const Text(
                      'Logout',
                      style: TextStyle(color: Colors.white, fontSize: 16),
                    ),
                  ),
                  const SizedBox(height: 20),
                ],
              ),
            ),
            const Padding(
              padding: EdgeInsets.only(bottom: 10),
              child: Text(
                "© Copyrighted by First Shot Sdn Bhd with ❤️",
                style: TextStyle(fontSize: 12, color: Colors.black),
                textAlign: TextAlign.center,
              ),
            ),
          ],
        ),
      ),
    );
  }
}