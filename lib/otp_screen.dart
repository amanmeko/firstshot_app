import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:pin_code_fields/pin_code_fields.dart';

class OtpScreen extends StatefulWidget {
  const OtpScreen({super.key});

  @override
  State<OtpScreen> createState() => _OtpScreenState();
}

class _OtpScreenState extends State<OtpScreen> {
  String mobileNumber = '';
  String otpCode = '';

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final args = ModalRoute.of(context)?.settings.arguments;
    if (args is String) {
      mobileNumber = args;
    }
  }

  void _verifyOtp() {
  if (otpCode.length != 6) {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text("Please enter a 6-digit OTP")),
    );
    return;
  }

  // OTP verification successful, proceed to password reset
  Navigator.pushNamed(context, '/new_password');
}


  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF9FBFD),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              const SizedBox(height: 20),
              SvgPicture.asset(
                'assets/images/otpicon.svg',
                height: 220,
              ),

              const SizedBox(height: 30),
              const Text(
                "OTP Verification",
                style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
              ),

              const SizedBox(height: 12),
              Text(
                "We will send you a one-time verification\npassword to  +$mobileNumber mobile number",
                textAlign: TextAlign.center,
                style: const TextStyle(fontSize: 16, color: Colors.black54),
              ),

              const SizedBox(height: 32),

              // 🔢 6-digit OTP Input
              PinCodeTextField(
                appContext: context,
                length: 6,
                animationType: AnimationType.fade,
                cursorColor: Colors.black,
                textStyle: const TextStyle(fontSize: 20),
                pinTheme: PinTheme(
                  shape: PinCodeFieldShape.underline,
                  activeColor: Colors.deepOrange,
                  selectedColor: Colors.deepOrange,
                  inactiveColor: Colors.grey.shade300,
                ),
                onChanged: (value) => otpCode = value,
              ),

              const SizedBox(height: 30),

              ElevatedButton(
                onPressed: _verifyOtp,
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF4997D0),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(30),
                  ),
                  minimumSize: const Size.fromHeight(50),
                ),
                child: const Text("Verify Now", style: TextStyle(color: Colors.white, fontSize: 16)),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
