import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';

class PrivacyPolicyPage extends StatelessWidget {
  const PrivacyPolicyPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Top SVG with back button and diagonal background
              Stack(
                children: [
                  // Diagonal background layer
                  ClipPath(
                    clipper: DiagonalClipper(),
                    child: Container(
                      height: 220,
                      color: Colors.white,
                    ),
                  ),
                  // SVG foreground
                  SvgPicture.asset(
                    'assets/images/Bookingtop.svg', // 👈 Your SVG image
                    width: double.infinity,
                    height: 240,
                    fit: BoxFit.cover,
                  ),
                  // Back button
                  Positioned(
                    top: 16,
                    left: 16,
                    child: GestureDetector(
                      onTap: () => Navigator.pop(context),
                      child: Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.9),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: const Icon(Icons.arrow_back, size: 22),
                      ),
                    ),
                  ),
                ],
              ),

              const Padding(
                padding: EdgeInsets.symmetric(horizontal: 20, vertical: 20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      "Privacy & Policy",
                      style: TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    SizedBox(height: 16),
                    Text(
                      "We are committed to protecting everyone's intellectual property and have a comprehensive policy to that end. "
                          "This Intellectual Property Policy explains how we address allegations of infringement, how authorized parties can "
                          "submit reports of infringement regarding content on our website and mobile applications, and how responsible parties "
                          "can respond when their listings are affected by a report. We will remove material cited for alleged intellectual "
                          "property infringement when provided with a report that complies with our policies. The intellectual property hereof "
                          "means copyright, trademark, patent and other intellectual properties prescribed by laws.",
                      style: TextStyle(fontSize: 13.5, height: 1.6),
                    ),
                    SizedBox(height: 16),
                    Text(
                      "1. Report Infringement",
                      style: TextStyle(fontWeight: FontWeight.bold),
                    ),
                    SizedBox(height: 8),
                    Text(
                      "(1) To submit a notice of IP infringement, you must be the rights owner who owns the IP being reported or an agent "
                          "with permission from the rights owner to submit notices on his or her behalf.",
                      style: TextStyle(fontSize: 13.5, height: 1.6),
                    ),
                    SizedBox(height: 10),
                    Text(
                      "(2) We will investigate the listings or penalty of perjury and ownership.",
                      style: TextStyle(fontSize: 13.5, height: 1.6),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// Simulated diagonal background clipper
class DiagonalClipper extends CustomClipper<Path> {
  @override
  Path getClip(Size size) {
    final path = Path();
    path.lineTo(0, size.height - 40);
    path.lineTo(size.width, size.height);
    path.lineTo(size.width, 0);
    path.close();
    return path;
  }

  @override
  bool shouldReclip(CustomClipper<Path> oldClipper) => false;
}
