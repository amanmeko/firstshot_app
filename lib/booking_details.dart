import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:curved_navigation_bar/curved_navigation_bar.dart';
import 'package:intl/intl.dart';
import 'services/booking_service.dart';

class BookingDetailsPage extends StatefulWidget {
  final int bookingId;

  const BookingDetailsPage({super.key, required this.bookingId});

  @override
  State<BookingDetailsPage> createState() => _BookingDetailsPageState();
}

class _BookingDetailsPageState extends State<BookingDetailsPage> {
  int _selectedIndex = 0;
  Map<String, dynamic>? bookingData;
  bool isLoading = true;
  bool isCancelling = false;

  final List<String> _labels = ['Booking', 'Lessons', 'Home', 'Instructors', 'Settings'];
  final List<IconData> _icons = [
    Icons.calendar_today,
    Icons.assignment,
    Icons.home,
    Icons.sports_tennis_rounded,
    Icons.settings,
  ];

  @override
  void initState() {
    super.initState();
    _loadBookingDetails();
  }

  Future<void> _loadBookingDetails() async {
    try {
      final response = await BookingService.getBooking(widget.bookingId);
      if (response['success'] == true) {
        setState(() {
          bookingData = Map<String, dynamic>.from(response['booking'] ?? {});
          isLoading = false;
        });
      } else {
        setState(() { isLoading = false; });
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(response['message'] ?? 'Failed to load booking details')),
          );
        }
      }
    } catch (e) {
      setState(() { isLoading = false; });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error loading booking details: $e')),
        );
      }
    }
  }

  // Helpers: null-safe access and parsing
  String? _firstString(List<String> keys) {
    if (bookingData == null) return null;
    for (final k in keys) {
      final v = bookingData![k];
      if (v != null) {
        final s = v.toString();
        if (s.isNotEmpty) return s;
      }
    }
    return null;
  }

  String _courtName() {
    final name = bookingData?['court'] != null
        ? (bookingData!['court']['name']?.toString())
        : null;
    return name ?? bookingData?['court_name']?.toString() ?? 'Court';
  }

  DateTime? _parseDate(String? s) {
    if (s == null) return null;
    try {
      return DateTime.parse(s);
    } catch (_) {
      try {
        return DateFormat('yyyy-MM-dd').parse(s);
      } catch (_) {
        return null;
      }
    }
  }

  TimeOfDay? _parseTime(String? s) {
    if (s == null || s.isEmpty) return null;
    try {
      // Handle HH:mm format first (most common)
      if (s.contains(':') && !s.contains('T') && !s.contains('-') && !s.contains(' ')) {
        final parts = s.split(':');
        if (parts.length >= 2) {
          final h = int.tryParse(parts[0]) ?? 0;
          final m = int.tryParse(parts[1]) ?? 0;
          if (h >= 0 && h < 24 && m >= 0 && m < 60) {
            return TimeOfDay(hour: h, minute: m);
          }
        }
      }
      
      // Handle ISO or full datetime format
      if (s.contains('T') || s.contains('-') || s.contains(' ')) {
        try {
          final dt = DateTime.parse(s);
          return TimeOfDay.fromDateTime(dt);
        } catch (e) {
          print('Error parsing datetime: $e');
          return null;
        }
      }
      
      // Handle other formats
      if (s.length == 4) {
        // Format: HHMM
        final h = int.tryParse(s.substring(0, 2)) ?? 0;
        final m = int.tryParse(s.substring(2, 4)) ?? 0;
        if (h >= 0 && h < 24 && m >= 0 && m < 60) {
          return TimeOfDay(hour: h, minute: m);
        }
      }
      
      return null;
    } catch (e) {
      print('Error parsing time: $e for value: $s');
      return null;
    }
  }

  Future<void> _cancelBooking() async {
    setState(() { isCancelling = true; });
    try {
      final response = await BookingService.deleteBooking(widget.bookingId);
      setState(() { isCancelling = false; });
      if (response['success'] == true) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Booking cancelled successfully')),
          );
        }
        Navigator.pop(context);
      } else {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(response['message'] ?? 'Failed to cancel booking')),
          );
        }
      }
    } catch (e) {
      setState(() { isCancelling = false; });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error cancelling booking: $e')),
        );
      }
    }
  }

  void _navigate(int index) {
    setState(() { _selectedIndex = index; });
    switch (index) {
      case 0: Navigator.pushNamed(context, '/booking'); break;
      case 1: Navigator.pushNamed(context, '/coaching'); break;
      case 2: Navigator.pushNamed(context, '/main'); break;
      case 3: Navigator.pushNamed(context, '/instructors'); break;
      case 4: Navigator.pushNamed(context, '/settings'); break;
    }
  }

  @override
  Widget build(BuildContext context) {
    final dateStr = _firstString(['booking_date', 'date']);
    final date = _parseDate(dateStr);
    final startStr = _firstString(['start_time', 'start']);
    final endStr = _firstString(['end_time', 'end']);
    final startT = _parseTime(startStr);
    final endT = _parseTime(endStr);

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
      body: isLoading
          ? const Center(child: CircularProgressIndicator())
          : bookingData == null
              ? const Center(child: Text('Booking not found'))
              : SingleChildScrollView(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    children: [
                      _sectionBox(
                        children: [
                          Text(_courtName(), style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                          const SizedBox(height: 4),
                          const Row(
                            children: [
                              Icon(Icons.location_pin, size: 16, color: Colors.grey),
                              SizedBox(width: 4),
                              Text("First Shot Pickleball Kuala Lumpur"),
                            ],
                          ),
                          const Divider(height: 24),
                          _infoRowWithIcon(
                            Icons.calendar_today,
                            "Date:",
                            date != null ? DateFormat('dd MMMM yyyy').format(date) : '-',
                          ),
                          const Divider(height: 24),
                          _infoRowWithIcon(
                            Icons.access_time,
                            "Time:",
                            '${startT != null ? startT.format(context) : (startStr ?? '-')}'
                            ' - '
                            '${endT != null ? endT.format(context) : (endStr ?? '-')}',
                          ),
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
                          _builderCancelButton(date),
                        ],
                      ),
                      const SizedBox(height: 16),
                      _sectionBox(
                        children: [
                          const SizedBox(height: 8),
                          _infoRow("Total Paid :", 'RM${bookingData?['price'] ?? '-'}'),
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
                          const Align(
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

  Widget _builderCancelButton(DateTime? bookingDate) {
    if (bookingData == null) return const SizedBox.shrink();
    final canCancel = bookingDate != null && DateTime.now().difference(bookingDate).inHours < 24;

    return SizedBox(
      width: double.infinity,
      child: OutlinedButton.icon(
        onPressed: canCancel && !isCancelling
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
                          _cancelBooking();
                        },
                        child: const Text("Yes"),
                      ),
                    ],
                  ),
                );
              }
            : null,
        icon: isCancelling
            ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2))
            : const Icon(Icons.cancel),
        label: Text(isCancelling ? "Cancelling..." : "Cancel this Booking"),
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
