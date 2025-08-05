import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';

class AboutUsPage extends StatelessWidget {
  const AboutUsPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.only(bottom: 24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Top Banner Section with fixed height
              LayoutBuilder(
                builder: (context, constraints) {
                  final double centerX = constraints.maxWidth / 2 - 40;

                  return SizedBox(
                    height: 180,
                    child: Stack(
                      children: [
                        SvgPicture.asset(
                          'assets/images/aboutusbanner.svg',
                          width: double.infinity,
                          fit: BoxFit.cover,
                        ),
                        Positioned(
                          top: 130,
                          left: 16,
                          child: GestureDetector(
                            onTap: () => Navigator.pop(context),
                            child: Container(
                              width: 42,
                              height: 42,
                              decoration: BoxDecoration(
                                border: Border.all(color: Colors.black),
                                borderRadius: BorderRadius.circular(12),
                                color: Colors.white,
                              ),
                              child: const Icon(Icons.arrow_back, size: 20),
                            ),
                          ),
                        ),
                        Positioned(
                          top: 80,
                          left: centerX,
                          child: SvgPicture.asset(
                            'assets/images/about1.svg',
                            width: 100,
                            height: 120,
                            fit: BoxFit.cover,
                          ),
                        ),
                      ],
                    ),
                  );
                },
              ),

              const SizedBox(height: 32),

              const Padding(
                padding: EdgeInsets.symmetric(horizontal: 20),
                child: Text(
                  "🎾 Welcome to FirstShot Sdn Bhd – Your Premier Pickleball Experience Starts Here!\n\n"
                      "FirstShot Sdn Bhd is Malaysia’s leading provider of dedicated Pickleball courts, offering a vibrant, tech-powered way to enjoy one of the world’s fastest-growing sports. Whether you're a beginner or a seasoned player, FirstShot delivers the ultimate game experience – simple, accessible, and hassle-free.\n\n"
                      "Introducing the FirstShot Mobile App\n"
                      "Take control of your Pickleball game with the FirstShot App – your all-in-one solution to manage court bookings, join matches, and connect with fellow players.\n\n"
                      "Key Features:\n"
                      "✅ Real-Time Court Booking – Reserve your preferred court instantly, anytime, anywhere\n"
                      "✅ Smart Matchmaking – Join games with players of similar skill levels\n"
                      "✅ Event Listings – Stay updated with local Pickleball events and tournaments\n"
                      "✅ Profile & Stats – Track your games, wins, and progress over time\n"
                      "✅ Group Play & Friend Invites – Play with your crew or make new friends on court\n\n"

                      "Whether you're playing for fun, fitness, or competition, FirstShot brings you closer to the game you love. Download the app and step into the court today – FirstShot, Your Game Starts Here!",
                  style: TextStyle(fontSize: 13.5, height: 1.6),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
