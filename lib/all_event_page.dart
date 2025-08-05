import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'booking_page.dart';
import 'coaching_select.dart';
import 'main_page.dart';
import 'instructors_page.dart';
import 'settings_page.dart';
import 'package:curved_navigation_bar/curved_navigation_bar.dart';

class AllEventPage extends StatefulWidget {
  const AllEventPage({super.key});

  @override
  State<AllEventPage> createState() => _AllEventPageState();
}

class _AllEventPageState extends State<AllEventPage> {
  int _selectedIndex = 2;
  DateTime _selectedDate = DateTime.now();

  final List<String> _labels = ['Booking', 'Lessons', 'Home', 'Instructors', 'Settings'];
  final List<IconData> _icons = [
    Icons.calendar_today,
    Icons.assignment,
    Icons.home,
    Icons.sports_tennis_rounded,
    Icons.settings,
  ];

  final List<Map<String, String>> events = [
    {
      'image': 'assets/images/event1.svg',
      'date': '10\nJUNE',
      'title': 'C1 Group',
      'desc': 'Enjoy your favorite pickleball game and a lovely your friends Read More...'
    },
    {
      'image': 'assets/images/event2.svg',
      'date': '10\nJUNE',
      'title': 'South Key class',
      'desc': 'Enjoy your favorite pickleball game and a lovely your  Read More...'
    },
    {
      'image': 'assets/images/event1.svg',
      'date': '10\nJUNE',
      'title': 'HTP pickleball',
      'desc': 'Enjoy your favorite pickleball game and a lovely your friends and Read More...'
    },
    {
      'image': 'assets/images/event2.svg',
      'date': '10\nJUNE',
      'title': 'Master Hoo Class',
      'desc': 'Enjoy your favorite pickleball game and a lovely your friends and Read More...'
    },
  ];

  Future<void> _selectDate() async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate,
      firstDate: DateTime(2023),
      lastDate: DateTime(2026),
    );
    if (picked != null && picked != _selectedDate) {
      setState(() => _selectedDate = picked);
    }
  }

  void _onBottomTap(int index) {
    setState(() {
      _selectedIndex = index;
    });
    switch (index) {
      case 0:
        Navigator.pushReplacement(context, MaterialPageRoute(builder: (_) => const BookingPage()));
        break;
      case 1:
        Navigator.pushReplacement(context, MaterialPageRoute(builder: (_) => const CoachingSelect()));
        break;
      case 2:
        Navigator.pushReplacement(context, MaterialPageRoute(builder: (_) => const MainPage()));
        break;
      case 3:
        Navigator.pushReplacement(context, MaterialPageRoute(builder: (_) => const InstructorsPage()));
        break;
      case 4:
        Navigator.pushReplacement(context, MaterialPageRoute(builder: (_) => const SettingsPage()));
        break;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF9FBFD),
      body: SafeArea(
        child: Column(
          children: [
            // 🧡 HEADER IMAGE + BACK BUTTON + TITLE + SELECT DATE
            Stack(
              children: [
                SvgPicture.asset(
                  'assets/images/newtops.svg',
                  width: double.infinity,
                  height: 240,
                  fit: BoxFit.cover,
                ),
                Positioned(
                  top: 16,
                  left: 16,
                  child: IconButton(
                    icon: const Icon(Icons.arrow_back, color: Colors.white),
                    onPressed: () => Navigator.pop(context),
                  ),
                ),
                Positioned(
                  bottom: 0,
                  left: 0,
                  right: 0,
                  child: Container(
                    margin: const EdgeInsets.symmetric(horizontal: 30),
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(30),
                      boxShadow: const [BoxShadow(color: Colors.black26, blurRadius: 6)],
                    ),
                    child: Column(
                      children: [
                        const Text(
                          "Our Upcoming Events",
                          style: TextStyle(
                            fontSize: 18,
                            color: Color(0xFFEC6040),
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        TextButton.icon(
                          onPressed: _selectDate,
                          icon: const Icon(Icons.arrow_right),
                          label: const Text("Select Date"),
                          style: TextButton.styleFrom(
                            foregroundColor: Colors.black,
                          ),
                        ),
                      ],
                    ),
                  ),
                )
              ],
            ),

            const SizedBox(height: 16),

            // 💥 EVENT GRID
            Expanded(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 26),
                child: GridView.builder(
                  itemCount: events.length,
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 2,
                    mainAxisSpacing: 15,
                    crossAxisSpacing: 12,
                    childAspectRatio: 0.7,
                  ),
                  itemBuilder: (context, index) {
                    final event = events[index];
                    return _buildEventItem(
                      event['image']!,
                      event['date']!,
                      event['title']!,
                      event['desc']!,
                    );
                  },
                ),
              ),
            ),
          ],
        ),
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
              Icon(_icons[index], color: Colors.white, size: 24),
              if (_selectedIndex != index)
                Text(_labels[index], style: const TextStyle(color: Colors.white, fontSize: 10)),
            ],
          );
        }),
        onTap: _onBottomTap,
      ),
    );
  }

  Widget _buildEventItem(String imagePath, String date, String title, String desc) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: const [BoxShadow(color: Colors.black12, blurRadius: 4)],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Stack(
            children: [
              ClipRRect(
                borderRadius: const BorderRadius.vertical(top: Radius.circular(12)),
                child: SvgPicture.asset(imagePath, height: 100, width: double.infinity, fit: BoxFit.cover),
              ),
              Positioned(
                top: 8,
                left: 8,
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: Colors.white70,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    date,
                    style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.red),
                  ),
                ),
              ),
            ],
          ),
          Padding(
            padding: const EdgeInsets.all(10),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: const TextStyle(fontWeight: FontWeight.bold)),
                const SizedBox(height: 4),
                Text(desc, style: const TextStyle(fontSize: 12)),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
