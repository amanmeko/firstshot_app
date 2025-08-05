import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:curved_navigation_bar/curved_navigation_bar.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import 'user_profile.dart';
import 'booking_page.dart';
import 'coaching_select.dart';
import 'settings_page.dart';
import 'instructors_page.dart';
import 'listproducts.dart';
import 'all_event_page.dart';

class MainPage extends StatefulWidget {
  const MainPage({super.key});

  @override
  State<MainPage> createState() => _MainPageState();
}

class _MainPageState extends State<MainPage> {
  int _selectedIndex = 2;

  final List<String> _labels = ['Booking', 'Lessons', 'Home', 'Instructors', 'Settings'];
  final List<IconData> _icons = [
    Icons.calendar_today,
    Icons.assignment,
    Icons.home,
    Icons.sports_tennis_rounded,
    Icons.settings,
  ];

  final List<Widget> _pages = [
    const BookingPage(),
    const CoachingSelect(),
    const HomePage(),
    const InstructorsPage(),
    const SettingsPage(),
  ];

  @override
  void initState() {
    super.initState();
    _checkAuthStatus();
  }

  Future<void> _checkAuthStatus() async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('auth_token');
    if (token == null) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        Navigator.pushReplacementNamed(context, '/login');
      });
    } else {
      Provider.of<UserProfile>(context, listen: false).loadProfileData();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF9FBFD),
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
                color: Colors.white,
                size: 24,
              ),
              if (_selectedIndex != index)
                Text(_labels[index], style: const TextStyle(color: Colors.white, fontSize: 10)),
            ],
          );
        }),
        onTap: (index) {
          setState(() {
            _selectedIndex = index;
          });
        },
      ),
      body: SafeArea(child: _pages[_selectedIndex]),
    );
  }
}

class HomePage extends StatelessWidget {
  const HomePage({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer<UserProfile>(
      builder: (context, userProfile, child) {
        return SingleChildScrollView(
          padding: const EdgeInsets.only(bottom: 80),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Stack(
                children: [
                  ClipPath(
                    clipper: CurvedHeaderClipper(),
                    child: Container(
                      height: 150,
                      width: double.infinity,
                      color: Colors.black12,
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.fromLTRB(16, 30, 20, 16),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Column(
                          children: [
                            GestureDetector(
                              onTap: () async {
                                final result = await Navigator.pushNamed(context, '/settings');
                                if (result == true) {
                                  await Provider.of<UserProfile>(context, listen: false).loadProfileData();
                                }
                              },
                              child: CircleAvatar(
                                radius: 38,
                                backgroundColor: Colors.grey[200],
                                backgroundImage: userProfile.avatarUrl.isNotEmpty
                                    ? NetworkImage('${userProfile.avatarUrl}?${DateTime.now().millisecondsSinceEpoch}')
                                    : const AssetImage('assets/icons/avatar.png') as ImageProvider,
                                onBackgroundImageError: userProfile.avatarUrl.isNotEmpty
                                    ? (error, stackTrace) {
                                        print('Avatar Load Error: $error, URL: ${userProfile.avatarUrl}');
                                        Provider.of<UserProfile>(context, listen: false).updateProfileData(
                                          name: userProfile.name,
                                          email: userProfile.email,
                                          mobileNo: userProfile.mobileNo,
                                          duprId: userProfile.duprId,
                                          level: userProfile.level,
                                          location: userProfile.location,
                                          avatarUrl: '',
                                          memberSince: userProfile.memberSince,
                                        );
                                      }
                                    : null,
                              ),
                            ),
                            const SizedBox(height: 15),
                            Text(
                              userProfile.name,
                              style: const TextStyle(color: Colors.black, fontWeight: FontWeight.bold),
                            ),
                            Text(
                              "Member Since: ${userProfile.memberSince}",
                              style: const TextStyle(color: Colors.black, fontSize: 12),
                            ),
                            Text(
                              "Level: ${userProfile.level.isNotEmpty ? userProfile.level : 'N/A'}",
                              style: const TextStyle(color: Colors.black, fontSize: 12),
                            ),
                          ],
                        ),
                        const Spacer(),
                        Padding(
                          padding: const EdgeInsets.only(top: 8),
                          child: SvgPicture.asset('assets/images/logo2.svg', height: 75),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 20),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: TextField(
                  style: const TextStyle(fontSize: 13),
                  decoration: InputDecoration(
                    hintText: 'Search by Booking No, Players, Events...',
                    hintStyle: const TextStyle(color: Colors.black45),
                    prefixIcon: const Icon(Icons.search, color: Color(0xFF4997D0)),
                    filled: true,
                    fillColor: Colors.white,
                    contentPadding: const EdgeInsets.symmetric(vertical: 12),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(30),
                      borderSide: const BorderSide(color: Color(0xFF4997D0), width: 1),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(30),
                      borderSide: const BorderSide(color: Color(0xFF4997D0), width: 2),
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 10),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Row(
                  children: [
                    Expanded(
                      child: Container(
                        height: 60,
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(16),
                          gradient: const LinearGradient(
                            colors: [Color(0xFF131A1C), Color(0xFF26405E)],
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                          ),
                          boxShadow: const [BoxShadow(color: Colors.black26, blurRadius: 4)],
                        ),
                        child: ElevatedButton.icon(
                          onPressed: () => Navigator.pushNamed(context, '/booking'),
                          icon: const Icon(Icons.book_online, color: Colors.white),
                          label: const Text("Book Courts", style: TextStyle(fontSize: 16)),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.transparent,
                            foregroundColor: Colors.white,
                            shadowColor: Colors.transparent,
                            elevation: 0,
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Container(
                        height: 60,
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(16),
                          gradient: const LinearGradient(
                            colors: [Color(0xFF131A1C), Color(0xFF26405E)],
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                          ),
                          boxShadow: const [BoxShadow(color: Colors.black26, blurRadius: 4)],
                        ),
                        child: ElevatedButton.icon(
                          onPressed: () => Navigator.pushNamed(context, '/coaching'),
                          icon: const Icon(Icons.leaderboard, color: Colors.white),
                          label: const Text("Coaching Program", style: TextStyle(fontSize: 16)),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.transparent,
                            foregroundColor: Colors.white,
                            shadowColor: Colors.transparent,
                            elevation: 0,
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text("Events", style: TextStyle(fontWeight: FontWeight.bold)),
                    GestureDetector(
                      onTap: () => Navigator.pushNamed(context, '/event'),
                      child: const Text("See All >>", style: TextStyle(color: Colors.blue, fontWeight: FontWeight.bold)),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 8),
              SizedBox(
                height: 210,
                child: ListView(
                  scrollDirection: Axis.horizontal,
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  children: [
                    _buildEventItem(context, 'assets/images/event1.svg', '12 Jun', 'Beginner Bootcamp: Join our Pickleball Beginner Bootcamp'),
                    _buildEventItem(context, 'assets/images/event2.svg', '25 Aug', 'Join our weekly challenge'),
                    _buildEventItem(context, 'assets/images/event3.svg', '01 Aug', 'Exclusive members tournament'),
                  ],
                ),
              ),
              const SizedBox(height: 24),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text("Merchandise", style: TextStyle(fontWeight: FontWeight.bold)),
                    GestureDetector(
                      onTap: () => Navigator.pushNamed(context, '/merchandise'),
                      child: const Text("See All >>", style: TextStyle(color: Colors.blue, fontWeight: FontWeight.bold)),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 8),
              SizedBox(
                height: 250,
                child: ListView(
                  scrollDirection: Axis.horizontal,
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  children: [
                    _buildMerchItem(context, 'assets/images/paddle_m5.svg', "Pickleball Paddle", "RM 87.99", "5% Members Discount"),
                    _buildMerchItem(context, 'assets/images/ball_set.svg', "Ball Set Premium", "RM 45.50", "10% Off Today"),
                    _buildMerchItem(context, 'assets/images/bag_pro.svg', "Pro Carry Bag", "RM 150.00", "Free Shipping"),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildEventItem(BuildContext context, String imagePath, String date, String title) {
    return GestureDetector(
      onTap: () => Navigator.pushNamed(context, '/news'),
      child: Container(
        width: 200,
        margin: const EdgeInsets.only(right: 16),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(16),
          color: Colors.white,
          boxShadow: const [BoxShadow(color: Colors.black12, blurRadius: 4)],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            ClipRRect(
              borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
              child: SvgPicture.asset(imagePath, height: 120, fit: BoxFit.cover),
            ),
            Padding(
              padding: const EdgeInsets.all(8),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(date, style: const TextStyle(color: Colors.black54, fontSize: 12)),
                  const SizedBox(height: 4),
                  Text(
                    title,
                    style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMerchItem(BuildContext context, String imagePath, String title, String price, String discount) {
    return GestureDetector(
      onTap: () => Navigator.pushNamed(context, '/product_checkout'),
      child: Container(
        width: 160,
        margin: const EdgeInsets.only(right: 16),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(16),
          color: Colors.white,
          boxShadow: const [BoxShadow(color: Colors.black12, blurRadius: 4)],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            ClipRRect(
              borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
              child: SvgPicture.asset(imagePath, height: 120, fit: BoxFit.cover),
            ),
            Padding(
              padding: const EdgeInsets.all(8),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                  const SizedBox(height: 4),
                  Text(price, style: const TextStyle(color: Colors.black54, fontSize: 12)),
                  const SizedBox(height: 4),
                  Text(discount, style: const TextStyle(color: Colors.green, fontSize: 12)),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class CurvedHeaderClipper extends CustomClipper<Path> {
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