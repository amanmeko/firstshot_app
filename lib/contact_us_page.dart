import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:url_launcher/url_launcher.dart';


class ContactUsPage extends StatelessWidget {
  const ContactUsPage({super.key});

  void _launchUrl(String url) async {
    final uri = Uri.parse(url);
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    }
  }

  Widget _buildContactCard(String type, String title, String description) {
    return Container(
      padding: const EdgeInsets.all(16),
      width: 160,
      decoration: BoxDecoration(
        color: const Color(0xFFFEEFEF),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Column(
        children: [
          Icon(
            type == 'call' ? Icons.phone : Icons.email_outlined,
            color: Colors.red,
            size: 25,
          ),
          const SizedBox(height: 12),
          Text(title, style: const TextStyle(fontWeight: FontWeight.bold)),
          const SizedBox(height: 6),
          Text(
            description,
            style: const TextStyle(color: Colors.black, fontSize: 13),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildSocialRow({
    required Widget leading,
    required String label,
    required VoidCallback onTap,
  }) {
    return Container(
      margin: const EdgeInsets.symmetric(vertical: 8),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      decoration: BoxDecoration(
        border: Border.all(color: Colors.grey.shade300),
        borderRadius: BorderRadius.circular(14),
      ),
      child: Row(
        children: [
          CircleAvatar(
            backgroundColor: Colors.white,
            radius: 20,
            child: leading,
          ),
          const SizedBox(width: 16),
          Expanded(child: Text(label, style: const TextStyle(fontSize: 16))),
          InkWell(
            onTap: onTap,
            child: Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Colors.green.shade100,
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.open_in_new, size: 18),
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF9FBFD),
      body: SafeArea(
        child: Column(
          children: [
            // Top banner with back button
            Stack(
              children: [
                Image.asset('assets/images/contactus_top.png'),
                Positioned(
                  top: 15,
                  left: 15,
                  child: GestureDetector(
                    onTap: () => Navigator.pop(context),
                    child: Container(
                      padding: const EdgeInsets.all(6),
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(12),
                        color: Colors.white.withOpacity(0.9),
                      ),
                      child: const Icon(Icons.arrow_back_ios,
                          size: 20, color: Colors.black),
                    ),
                  ),
                ),
              ],
            ),

            Expanded(
              child: SingleChildScrollView(
                padding:
                const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text("Contact Us",
                        style: TextStyle(
                            fontSize: 20, fontWeight: FontWeight.bold)),
                    const SizedBox(height: 8),
                    const Text(
                      "Don’t hesitate to contact us whether you have a suggestion on our improvement, a complaint to discuss or an issue to solve.",
                      style: TextStyle(color: Colors.black),
                    ),
                    const SizedBox(height: 24),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        _buildContactCard('call', 'Call us',
                            '+60161234567\nMon–Fri • 9am–5pm'),
                        _buildContactCard('email', 'Email us',
                            'admin@firstshot.com\n'),
                      ],
                    ),
                    const SizedBox(height: 10),

                    // Social Rows
                    _buildSocialRow(
                      leading: const Icon(Icons.camera_alt_outlined),
                      label: "Instagram",
                      onTap: () => _launchUrl('https://instagram.com'),
                    ),
                    _buildSocialRow(
                      leading: const Icon(Icons.facebook),
                      label: "Facebook",
                      onTap: () => _launchUrl('https://facebook.com'),
                    ),
                    _buildSocialRow(
                      leading: const Icon(Icons.work),
                      label: "Available Mon–Fri",
                      onTap: () => _launchUrl('https://wa.me/60123456789'),
                    ),

                    const SizedBox(height: 30),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
