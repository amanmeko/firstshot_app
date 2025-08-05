import 'package:flutter/material.dart';

class ClassBookingInfo extends StatelessWidget {
  const ClassBookingInfo({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Your Booking Info")),
      body: const Center(child: Text("Your class booking info goes here")),
    );
  }
}
