import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:curved_navigation_bar/curved_navigation_bar.dart';

class BookingDetailsPage extends StatefulWidget {
  const BookingDetailsPage({super.key});

  @override
  State<BookingDetailsPage> createState() => _BookingDetailsPageState();
}

class _BookingDetailsPageState extends State<BookingDetailsPage> {
  int _selectedIndex = 0;

  final List<String> _labels = ['Booking', 'Lessons', 'Home', 'Instructors', 'Settings'];
  final List<IconData> _icons = [
    Icons.calendar_today,
    Icons.assignment,
    Icons.home,
    Icons.sports_tennis_rounded,
    Icons.settings,
  ];

  void _navigate(int index) {
    setState(() {
      _selectedIndex = index;
    });

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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF9FBFD),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.black),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text(
          'Booking Details',
          style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold, fontSize: 16),
        ),
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            _sectionBox(
              children: [
                const Text("Court 2", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                const SizedBox(height: 4),
                const Row(
                  children: [
                    Icon(Icons.location_pin, size: 16, color: Colors.grey),
                    SizedBox(width: 4),
                    Text("First Shot Pickleball Kuala Lumpur"),
                  ],
                ),
                const Divider(height: 24),
                _infoRowWithIcon(Icons.calendar_today, "Date:", "15 July 2025"),
                const Divider(height: 24),
                _infoRowWithIcon(Icons.access_time, "Time :", "2.00pm - 3.00 pm"),
              ],
            ),
            const SizedBox(height: 16),
            _sectionBox(
              children: [
                const Align(
                  alignment: Alignment.centerLeft,
                  child: Text("Our Location", style: TextStyle(fontWeight: FontWeight.bold)),
                ),
                const SizedBox(height: 8),
                SvgPicture.asset(
                  'assets/images/map.svg',
                  height: 180,
                  width: double.infinity,
                  fit: BoxFit.cover,
                ),
                const SizedBox(height: 12),
                SizedBox(
                  width: double.infinity,
                  child: OutlinedButton.icon(
                    onPressed: () {},
                    icon: const Icon(Icons.location_on),
                    label: const Text("Get Direction"),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: const Color(0xFF1A73E8),
                      side: const BorderSide(color: Color(0xFF1A73E8)),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(30)),
                    ),
                  ),
                ),
                const SizedBox(height: 12),
                _builderCancelButton(),
              ],
            ),
            const SizedBox(height: 16),
            _sectionBox(
              children: [

                const SizedBox(height: 8),
                _infoRow("Total Paid :", "RM249"),
                const SizedBox(height: 12),
                const Divider(height: 16),
                ListTile(
                  dense: true,
                  contentPadding: EdgeInsets.zero,
                  leading: const Icon(Icons.receipt_long),
                  title: const Text("Get receipt"),
                  trailing: const Icon(Icons.chevron_right),
                  onTap: () {
                    Navigator.pushNamed(context, '/receipts');
                  },
                ),
              ],
            ),
            const SizedBox(height: 16),
            _sectionBox(
              children: [
                Row(
                  children: [
                    Container(
                      decoration: const BoxDecoration(shape: BoxShape.circle, color: Color(0xFFFFF0EC)),
                      padding: const EdgeInsets.all(8),
                      child: const Icon(Icons.cancel, color: Colors.deepOrange),
                    ),
                    const SizedBox(width: 12),
                    const Text("Cancellation Policy", style: TextStyle(fontWeight: FontWeight.bold)),
                  ],
                ),
                const SizedBox(height: 2),
                Align(
                  alignment: Alignment.centerLeft,
                  child: Text(
                    "Free cancellation is available within 12 hours of booking. Any paid amount will be refunded as FirstShot Credit.",
                    style: TextStyle(color: Colors.black87, fontSize: 13),
                  ),
                ),
              ],
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
              Icon(
                _icons[index],
                color: _selectedIndex == index ? const Color(0xFF4997D0) : Colors.white,
                size: 24,
              ),
              if (_selectedIndex != index)
                Text(
                  _labels[index],
                  style: const TextStyle(color: Colors.white, fontSize: 10),
                ),
            ],
          );
        }),
        onTap: _navigate,
      ),
    );
  }

  Widget _builderCancelButton() {
    final DateTime bookingDate = DateTime(2025, 2, 20, 14, 00);
    final bool canCancel = DateTime.now().difference(bookingDate).inHours < 24;

    return SizedBox(
      width: double.infinity,
      child: OutlinedButton.icon(
        onPressed: canCancel
            ? () {
          showDialog(
            context: context,
            builder: (context) => AlertDialog(
              title: const Text("Cancel Booking?"),
              content: const Text("Are you sure you want to cancel this booking?"),
              actions: [
                TextButton(onPressed: () => Navigator.pop(context), child: const Text("No")),
                TextButton(
                  onPressed: () {
                    Navigator.pop(context);
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text("Booking has been cancelled")),
                    );
                  },
                  child: const Text("Yes"),
                ),
              ],
            ),
          );
        }
            : null,
        icon: const Icon(Icons.cancel),
        label: const Text("Cancel this Booking"),
        style: OutlinedButton.styleFrom(
          foregroundColor: canCancel ? Colors.red : Colors.grey,
          side: BorderSide(color: canCancel ? Colors.red : Colors.grey),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(30)),
        ),
      ),
    );
  }

  Widget _infoRow(String label, String value) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(label),
        Text(value, style: const TextStyle(fontWeight: FontWeight.bold)),
      ],
    );
  }

  Widget _infoRowWithIcon(IconData icon, String title, String value) {
    return Row(
      children: [
        Icon(icon, size: 20, color: Colors.blue),
        const SizedBox(width: 10),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(title, style: const TextStyle(color: Colors.black54)),
            Text(value, style: const TextStyle(fontWeight: FontWeight.bold)),
          ],
        )
      ],
    );
  }

  Widget _sectionBox({required List<Widget> children}) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: children,
      ),
    );
  }
}
