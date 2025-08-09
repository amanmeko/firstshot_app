import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:intl/intl.dart';
import 'dart:convert';
import 'dart:async';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:http/http.dart' as http;
import 'services/booking_service.dart';
import 'models/court.dart';
import 'models/time_slot.dart';
import 'bookingdetails.dart' as booking_details_create;

class BookingPage extends StatefulWidget {
  const BookingPage({Key? key}) : super(key: key);

  @override
  State<BookingPage> createState() => _BookingPageState();
}

class _BookingPageState extends State<BookingPage> {
  DateTime selectedDate = DateTime.now();
  TimeOfDay selectedTime = TimeOfDay.now();
  String selectedDuration = "1 hour";
  Court? selectedCourt;
  
  List<Court> courts = [];
  List<TimeSlot> availableTimeSlots = [];
  // Multi-select consecutive slots (max 3)
  List<TimeSlot> selectedSlots = [];
  bool isLoading = false;
  bool isLoadingTimeSlots = false;
  int? currentCustomerId;
  
  // Timer for auto-refresh
  Timer? _refreshTimer;
  DateTime? _lastRefreshTime;
  bool _isRunningInFallbackMode = false;

  final List<String> durations = ["1 hour", "2 hours", "3 hours"];

  @override
  void initState() {
    super.initState();
    _checkAuthenticationAndLoad();
    _startAutoRefresh();
  }

  @override
  void dispose() {
    _refreshTimer?.cancel();
    super.dispose();
  }

  void _startAutoRefresh() {
    // Refresh available time slots every 2 minutes to keep them current
    _refreshTimer = Timer.periodic(const Duration(minutes: 2), (timer) {
      if (selectedCourt != null && mounted) {
        _loadAvailableTimeSlots();
      }
    });
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    // Refresh time slots when returning to the page
    if (selectedCourt != null && availableTimeSlots.isNotEmpty) {
      _loadAvailableTimeSlots();
    }
  }

  void _toggleSlotSelection(TimeSlot slot) {
    setState(() {
      final exists = selectedSlots.any((s) => s.start == slot.start);
      if (exists) {
        selectedSlots.removeWhere((s) => s.start == slot.start);
        return;
      }
      if (selectedSlots.length >= 3) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Maximum 3 consecutive slots allowed')),
        );
        return;
      }
      if (selectedSlots.isEmpty) {
        selectedSlots.add(slot);
        return;
      }
      final sorted = [...selectedSlots]..sort((a, b) => a.start.compareTo(b.start));
      final first = sorted.first;
      final last = sorted.last;
      final isAdjacentToStart = slot.end == first.start;
      final isAdjacentToEnd = last.end == slot.start;
      if (!isAdjacentToStart && !isAdjacentToEnd) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Please select consecutive slots only')),
        );
        return;
      }
      selectedSlots.add(slot);
      selectedSlots.sort((a, b) => a.start.compareTo(b.start));
    });
  }

  Future<void> _checkAuthenticationAndLoad() async {
    final prefs = await SharedPreferences.getInstance();
    final storage = const FlutterSecureStorage();
    
    // Try both token keys to handle different storage methods
    String? token = prefs.getString('auth_token');
    if (token == null) {
      token = prefs.getString('token');
    }
    
    // Check for user data in multiple locations
    String? userData = prefs.getString('user_data');
    if (userData == null) {
      final userId = await storage.read(key: 'user_id');
      if (userId != null) {
        userData = 'present';
      }
    }
    
    print('🔐 Checking authentication...');
    print('🔑 Token: ${token != null ? 'Present' : 'Missing'}');
    print('👤 User data: ${userData != null ? 'Present' : 'Missing'}');
    
    if (token == null || userData == null) {
      // User is not logged in, redirect to login
      setState(() {
        isLoading = false;
      });
      
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Authentication required. Please log in to book courts.'),
          duration: Duration(seconds: 2),
        ),
      );
      
      // Navigate to login page immediately
      Navigator.pushReplacementNamed(context, '/login');
      return;
    }
    
    // User is logged in, proceed with loading
    print('✅ User authenticated, loading courts...');
    _loadCourts();
    _loadCustomerId();
  }



  Future<void> _loadCustomerId() async {
    final prefs = await SharedPreferences.getInstance();
    final storage = const FlutterSecureStorage();
    
    print('🔍 Loading customer ID from storage...');
    
    // Try to get customer ID from multiple sources
    String? customerId;
    
    // First try secure storage
    customerId = await storage.read(key: 'customer_id');
    print('🔐 Secure storage customer_id: $customerId');
    
    // If not found, try shared preferences
    if (customerId == null) {
      customerId = prefs.getString('customer_id');
      print('📱 Shared prefs customer_id: $customerId');
    }
    
    // Try user_id from secure storage
    if (customerId == null) {
      customerId = await storage.read(key: 'user_id');
      print('🔐 Secure storage user_id: $customerId');
    }
    
    // Try user_id from shared preferences
    if (customerId == null) {
      customerId = prefs.getString('user_id');
      print('📱 Shared prefs user_id: $customerId');
    }
    
    // If still not found, try to parse from user_data
    if (customerId == null) {
      final userData = prefs.getString('user_data');
      print('📄 User data from shared prefs: ${userData != null ? 'Present' : 'Missing'}');
      if (userData != null) {
        try {
          final user = json.decode(userData);
          print('📋 Parsed user data: $user');
          customerId = user['id']?.toString();
          print('🆔 Customer ID from user data: $customerId');
        } catch (e) {
          print('❌ Error parsing user data: $e');
        }
      }
    }
    
    // Try to get from auth_token if it contains user info
    if (customerId == null) {
      final authToken = prefs.getString('auth_token');
      if (authToken != null) {
        print('🎫 Auth token found, checking for user info...');
        // Some tokens might contain user info in payload
        try {
          // This is a simple check - in real apps you'd decode JWT properly
          if (authToken.contains('"id"')) {
            final startIndex = authToken.indexOf('"id"') + 5;
            final endIndex = authToken.indexOf(',', startIndex);
            if (endIndex == -1) {
              final endIndex = authToken.indexOf('}', startIndex);
            }
            if (endIndex != -1) {
              customerId = authToken.substring(startIndex, endIndex).replaceAll('"', '').trim();
              print('🆔 Customer ID from auth token: $customerId');
            }
          }
        } catch (e) {
          print('❌ Error parsing auth token: $e');
        }
      }
    }
    
    if (customerId != null && customerId.isNotEmpty) {
      // Check if it's a numeric ID or a formatted ID like #FS00011
      int? parsedId;
      if (customerId.startsWith('#')) {
        // Skip formatted IDs like #FS00011, we'll use user_id instead
        customerId = null; // Reset to null so we use user_id
      } else {
        parsedId = int.tryParse(customerId);
      }
      
      if (parsedId != null) {
        setState(() {
          currentCustomerId = parsedId;
        });
        
        // Save to shared preferences as backup for future use
        if (customerId != null) {
          await prefs.setString('customer_id', customerId);
        }
      }
    }
    
    // If we still don't have a valid customer ID, try to get user_id
    if (currentCustomerId == null) {
      // Try to get all keys from secure storage
      try {
        final allKeys = await storage.readAll();
        
        // Use user_id as the primary customer ID
        if (allKeys.containsKey('user_id')) {
          final userId = allKeys['user_id'];
          if (userId != null && userId.isNotEmpty) {
            final parsedId = int.tryParse(userId);
            if (parsedId != null) {
              setState(() {
                currentCustomerId = parsedId;
              });
              
              // Save this as customer_id for future use
              await prefs.setString('customer_id', userId);
              await storage.write(key: 'customer_id', value: userId);
            }
          }
        }
      } catch (e) {
        // Handle error silently
      }
    }
  }

  Future<void> _loadCourts() async {
    setState(() {
      isLoading = true;
    });

    try {
      final response = await BookingService.getCourts();
      
      if (response['success']) {
        final courtsData = response['courts'] as List;
        
        setState(() {
          courts = courtsData.map((court) => Court.fromJson(court)).toList();
          isLoading = false;
        });
      } else {
        setState(() {
          isLoading = false;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('API Error: ${response['message'] ?? 'Unknown error'}')),
        );
      }
    } catch (e) {
      setState(() {
        isLoading = false;
      });
      
      // Show specific error for authentication issues
      if (e.toString().contains('401') || e.toString().contains('Unauthenticated')) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Authentication expired. Please log in again.'),
            duration: Duration(seconds: 3),
          ),
        );
        // Redirect to login
        Future.delayed(const Duration(seconds: 2), () {
          Navigator.pushReplacementNamed(context, '/login');
        });
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error loading courts: $e')),
        );
      }
    }
  }

  Future<void> _loadAvailableTimeSlots() async {
    if (selectedCourt == null) return;

    setState(() {
      isLoadingTimeSlots = true;
    });

    try {
      final dateString = DateFormat('yyyy-MM-dd').format(selectedDate);
      
      // Get both available time slots and existing bookings
      final timeSlots = await BookingService.getAvailableTimes(
        courtId: selectedCourt!.id,
        date: dateString,
      );
      
      // Get existing bookings for this court and date
      final existingBookings = await BookingService.getCourtBookings(
        courtId: selectedCourt!.id,
        date: dateString,
      );
      
      // Filter out time slots that conflict with existing bookings
      final filteredTimeSlots = _filterConflictingTimeSlots(timeSlots, existingBookings);
      
      setState(() {
        availableTimeSlots = filteredTimeSlots
            .map((slot) => TimeSlot.fromJson(slot))
            .where((s) => (s.start).toString().isNotEmpty && (s.end).toString().isNotEmpty)
            .toList();
        isLoadingTimeSlots = false;
        _lastRefreshTime = DateTime.now();
        _isRunningInFallbackMode = existingBookings.isEmpty;
      });
    } catch (e) {
      setState(() {
        isLoadingTimeSlots = false;
        availableTimeSlots = [];
      });
      // Console logging for debugging
      // ignore: avoid_print
      print('Error loading time slots for court ${selectedCourt?.id} on ' + DateFormat('yyyy-MM-dd').format(selectedDate) + ': ' + e.toString());
      final err = e.toString();
      if (err.contains('401') || err.toLowerCase().contains('unauthenticated')) {
        // Auth expired
        _showErrorCard(
          title: 'Authentication required',
          message: 'Please log in again to view available time slots.',
          icon: Icons.lock_outline,
          color: Colors.orange,
        );
        Future.delayed(const Duration(seconds: 2), () {
          if (mounted) Navigator.pushReplacementNamed(context, '/login');
        });
        return;
      }

      _showErrorCard(
        title: 'Couldn\'t load time slots',
        message: err.replaceFirst('Exception: ', ''),
        icon: Icons.schedule,
        color: Colors.red,
      );
    }
  }

  // Helper method to filter out time slots that conflict with existing bookings
  List<Map<String, dynamic>> _filterConflictingTimeSlots(
    List<Map<String, dynamic>> timeSlots,
    List<Map<String, dynamic>> existingBookings,
  ) {
    if (existingBookings.isEmpty) {
      // If we couldn't get existing bookings, we can't filter them out
      // This is a fallback to ensure the app still works
      print('Warning: No existing bookings data available, showing all time slots from API');
      return timeSlots;
    }

    final filteredSlots = timeSlots.where((slot) {
      final slotStart = slot['start'] as String;
      final slotEnd = slot['end'] as String;
      
      // Check if this time slot conflicts with any existing booking
      for (final booking in existingBookings) {
        final bookingStart = booking['start_time'] as String?;
        final bookingEnd = booking['end_time'] as String?;
        
        if (bookingStart != null && bookingEnd != null) {
          // Check for time overlap
          if (_hasTimeOverlap(slotStart, slotEnd, bookingStart, bookingEnd)) {
            print('Filtering out conflicting time slot: $slotStart-$slotEnd (conflicts with booking: $bookingStart-$bookingEnd)');
            return false; // This slot conflicts, filter it out
          }
        }
      }
      
      return true; // No conflicts, keep this slot
    }).toList();
    
    print('Filtered ${timeSlots.length} time slots to ${filteredSlots.length} available slots');
    return filteredSlots;
  }

  // Helper method to check if two time ranges overlap
  bool _hasTimeOverlap(String start1, String end1, String start2, String end2) {
    // Convert time strings to comparable values (assuming HH:MM format)
    final start1Minutes = _timeStringToMinutes(start1);
    final end1Minutes = _timeStringToMinutes(end1);
    final start2Minutes = _timeStringToMinutes(start2);
    final end2Minutes = _timeStringToMinutes(end2);
    
    // Check for overlap: if one range starts before another ends and ends after another starts
    return start1Minutes < end2Minutes && end1Minutes > start2Minutes;
  }

  // Helper method to convert time string (HH:MM) to minutes since midnight
  int _timeStringToMinutes(String timeString) {
    final parts = timeString.split(':');
    if (parts.length == 2) {
      final hours = int.tryParse(parts[0]) ?? 0;
      final minutes = int.tryParse(parts[1]) ?? 0;
      return hours * 60 + minutes;
    }
    return 0; // Default fallback
  }

  void _showErrorCard({required String title, required String message, required IconData icon, required Color color}) {
    final overlay = Overlay.of(context);
    if (overlay == null) return;
    final entry = OverlayEntry(
      builder: (_) => Positioned(
        left: 16,
        right: 16,
        bottom: 24,
        child: Material(
          color: Colors.transparent,
          child: Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: color.withOpacity(0.1),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: color.withOpacity(0.3)),
            ),
            child: Row(
              children: [
                Icon(icon, color: color),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(title, style: TextStyle(color: color, fontWeight: FontWeight.bold)),
                      const SizedBox(height: 4),
                      Text(message, style: TextStyle(color: color.withOpacity(0.9))),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
    overlay.insert(entry);
    Future.delayed(const Duration(seconds: 3)).then((_) => entry.remove());
  }

  void _pickTime() async {
    final picked = await showTimePicker(
      context: context,
      initialTime: selectedTime,
    );
    if (picked != null) {
      setState(() => selectedTime = picked);
    }
  }

  Widget _buildLegend(Color color, String label) {
    return Row(
      children: [
        Container(width: 14, height: 14, decoration: BoxDecoration(color: color, shape: BoxShape.circle)),
        const SizedBox(width: 4),
        Text(label, style: const TextStyle(fontSize: 12)),
      ],
    );
  }

  Widget _buildCourt(Court court, {bool available = true}) {
    final bool isSelected = selectedCourt?.id == court.id;
    final Color bgColor = isSelected ? Colors.black : available ? const Color(0xFF4997D0) : Colors.grey.shade300;
    final Color textColor = isSelected || available ? Colors.white : Colors.black54;

    return GestureDetector(
      onTap: available ? () {
        setState(() {
          selectedCourt = court;
          selectedSlots.clear(); // Clear selections when court changes
        });
        _loadAvailableTimeSlots();
      } : null,
      child: Container(
        alignment: Alignment.center,
        height: 50,
        margin: const EdgeInsets.all(2),
        color: bgColor,
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(court.name, style: TextStyle(color: textColor, fontSize: 13, fontWeight: FontWeight.bold)),
            Text('RM${court.price}/hr', style: TextStyle(color: textColor, fontSize: 10)),
          ],
        ),
      ),
    );
  }

  Widget _buildStaticBox(String label) {
    return Container(
      alignment: Alignment.center,
      height: 160,
      margin: const EdgeInsets.all(2),
      color: const Color(0xFF4997D0),
      child: Text(label, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
    );
  }

  Widget _buildCourtGrid() {
    if (isLoading) {
      return const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            CircularProgressIndicator(),
            SizedBox(height: 16),
            Text('Loading courts...'),
          ],
        ),
      );
    }

    if (courts.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.sports_tennis, size: 64, color: Colors.grey),
            const SizedBox(height: 16),
            const Text(
              'No courts available',
              style: TextStyle(fontSize: 18, color: Colors.grey),
            ),
            const SizedBox(height: 8),
            const Text(
              'Please check your connection or try again later',
              style: TextStyle(fontSize: 14, color: Colors.grey),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: _loadCourts,
              child: const Text('Retry'),
            ),
          ],
        ),
      );
    }

    return Column(
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            _buildLegend(const Color(0xFF4997D0), "Available"),
            const SizedBox(width: 12),
            _buildLegend(Colors.grey.shade300, "Not Available"),
            const SizedBox(width: 12),
            _buildLegend(Colors.black, "Selected"),
          ],
        ),
        const SizedBox(height: 16),
        GridView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 3,
            childAspectRatio: 2.5,
            crossAxisSpacing: 4,
            mainAxisSpacing: 4,
          ),
          itemCount: courts.length,
          itemBuilder: (context, index) {
            final court = courts[index];
            return _buildCourt(court);
          },
        ),
        const SizedBox(height: 16),
        if (selectedCourt != null && availableTimeSlots.isNotEmpty) ...[
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text("Available Time Slots", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
              IconButton(
                onPressed: _loadAvailableTimeSlots,
                icon: const Icon(Icons.refresh, color: Color(0xFF4997D0)),
                tooltip: 'Refresh time slots',
              ),
            ],
          ),
          if (_lastRefreshTime != null) ...[
            const SizedBox(height: 4),
            Row(
              children: [
                Text(
                  'Last updated: ${DateFormat('HH:mm').format(_lastRefreshTime!)}',
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.grey[600],
                    fontStyle: FontStyle.italic,
                  ),
                ),
                if (DateTime.now().difference(_lastRefreshTime!).inMinutes > 5) ...[
                  const SizedBox(width: 8),
                  Icon(
                    Icons.warning_amber,
                    size: 16,
                    color: Colors.orange,
                  ),
                  Text(
                    'Slots may be outdated',
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.orange,
                      fontStyle: FontStyle.italic,
                    ),
                  ),
                ],
              ],
            ),
          ],
          // Show warning if running in fallback mode
          if (_isRunningInFallbackMode) ...[
            const SizedBox(height: 8),
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Colors.orange.withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.orange.withOpacity(0.3)),
              ),
              child: Row(
                children: [
                  Icon(Icons.info_outline, color: Colors.orange, size: 16),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'Limited validation: Some time slots may not be available due to recent bookings',
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.orange[700],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
          const SizedBox(height: 12),
          if (isLoadingTimeSlots)
            const Center(child: CircularProgressIndicator())
          else
            Container(
              height: MediaQuery.of(context).size.width > 600 ? 160 : 140,
              child: ListView.builder(
                scrollDirection: Axis.horizontal,
                itemCount: availableTimeSlots.length,
                itemBuilder: (context, index) {
                  final slot = availableTimeSlots[index];
                  final bool isSelected = selectedSlots.any((s) => s.start == slot.start);
                  
                  return Container(
                    width: MediaQuery.of(context).size.width > 600 ? 120 : 100,
                    margin: const EdgeInsets.only(right: 12),
                    child: ElevatedButton(
                      onPressed: () => _toggleSlotSelection(slot),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: isSelected ? Colors.black : const Color(0xFF4997D0),
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 16),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        elevation: isSelected ? 4 : 2,
                      ),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
            children: [
                          // Time display
                          Text(
                            slot.display,
                                                    style: TextStyle(
                          fontSize: MediaQuery.of(context).size.width > 600 ? 16 : 14,
                          fontWeight: FontWeight.bold,
                        ),
                            textAlign: TextAlign.center,
                          ),
                          const SizedBox(height: 4),
                          // Removed duration badge per requirements
                          // Time range
                          Text(
                            '${slot.start} - ${slot.end}',
                            style: const TextStyle(
                              fontSize: 10,
                              fontWeight: FontWeight.w400,
                            ),
                            textAlign: TextAlign.center,
                          ),
                        ],
                      ),
                    ),
                  );
                },
              ),
            ),
        ],
        
        // Show message when no time slots available
        if (selectedCourt != null && availableTimeSlots.isEmpty && !isLoadingTimeSlots) ...[
          const SizedBox(height: 16),
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.orange.withOpacity(0.1),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Colors.orange.withOpacity(0.3)),
            ),
            child: Row(
              children: [
                Icon(Icons.schedule, color: Colors.orange, size: 24),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'No Available Time Slots',
                        style: TextStyle(
                          color: Colors.orange,
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Try selecting a different date or court.',
                        style: TextStyle(
                          color: Colors.orange.withOpacity(0.8),
                          fontSize: 14,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ],
    );
  }

  Widget _buildDurationButton(String label) {
    final bool isSelected = selectedDuration == label;

    return GestureDetector(
      onTap: () {
        setState(() => selectedDuration = label);
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 12),
        decoration: BoxDecoration(
          color: isSelected ? const Color(0xFF4997D0) : Colors.white,
          border: Border.all(
            color: isSelected ? const Color(0xFF4997D0) : Colors.grey.shade300,
          ),
          borderRadius: BorderRadius.circular(10),
        ),
        child: Row(
          children: [
            if (isSelected)
              const Icon(Icons.check, color: Colors.white, size: 16),
            if (isSelected) const SizedBox(width: 4),
            Text(
              label,
              style: TextStyle(
                color: isSelected ? Colors.white : Colors.black,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDateSelector() {
    return Column(
      children: [
        // Calendar button for full date picker
        Container(
          margin: const EdgeInsets.only(bottom: 12),
          child: ElevatedButton.icon(
            onPressed: _showDatePicker,
            icon: const Icon(Icons.calendar_month, color: Colors.white),
            label: Text(
              'Choose Any Date (Up to 1 Year)',
              style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w600),
            ),
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF4997D0),
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
            ),
          ),
        ),
        
        // Quick date selector (next 12 days)
        SizedBox(
      height: 90,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        itemCount: 12,
        itemBuilder: (context, index) {
          DateTime date = DateTime.now().add(Duration(days: index));
          bool isSelected = date.day == selectedDate.day &&
              date.month == selectedDate.month &&
              date.year == selectedDate.year;

          return GestureDetector(
                onTap: () {
                    setState(() {
                      selectedDate = date;
                      selectedSlots.clear(); // Clear selections when date changes
                    });
                  if (selectedCourt != null) {
                    _loadAvailableTimeSlots();
                  }
                },
            child: Container(
              width: 70,
              margin: const EdgeInsets.symmetric(horizontal: 6),
              decoration: BoxDecoration(
                color: isSelected ? const Color(0xFF4997D0) : Colors.white,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.grey.shade300),
              ),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                      Text(
                        DateFormat('E').format(date), 
                        style: TextStyle(
                          fontWeight: FontWeight.bold, 
                          color: isSelected ? Colors.white : Colors.black,
                          fontSize: 12,
                        ),
                      ),
                  const SizedBox(height: 4),
                      Text(
                        '${date.day}', 
                        style: TextStyle(
                          fontSize: 18, 
                          fontWeight: FontWeight.bold, 
                          color: isSelected ? Colors.white : Colors.black,
                        ),
                      ),
                  const SizedBox(height: 4),
                      Text(
                        DateFormat('MMM').format(date), 
                        style: TextStyle(
                          color: isSelected ? Colors.white : Colors.black,
                          fontSize: 11,
                        ),
                      ),
                ],
              ),
            ),
          );
        },
      ),
        ),
        
        // Selected date description
        Container(
          margin: const EdgeInsets.only(top: 8),
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
          decoration: BoxDecoration(
            color: const Color(0xFF4997D0).withOpacity(0.1),
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: const Color(0xFF4997D0).withOpacity(0.3)),
          ),
          child: Text(
            'Selected: ${DateFormat('EEEE, MMMM d, yyyy').format(selectedDate)} (${_getDateDescription(selectedDate)})',
            style: const TextStyle(
              color: Color(0xFF4997D0),
              fontWeight: FontWeight.w600,
              fontSize: 14,
            ),
          ),
        ),
      ],
    );
  }

  // Add enhanced date picker method
  Future<void> _showDatePicker() async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: selectedDate,
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 365)), // Allow booking up to 1 year ahead
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: const ColorScheme.light(
              primary: Color(0xFF4997D0),
              onPrimary: Colors.white,
              surface: Colors.white,
              onSurface: Colors.black,
            ),
            dialogBackgroundColor: Colors.white,
          ),
          child: child!,
        );
      },
    );
    
    if (picked != null && picked != selectedDate) {
      setState(() {
        selectedDate = picked;
        selectedSlots.clear(); // Clear selections when date changes
      });
      if (selectedCourt != null) {
        _loadAvailableTimeSlots();
      }
    }
  }

  String _getDateDescription(DateTime date) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final tomorrow = today.add(const Duration(days: 1));
    final selectedDay = DateTime(date.year, date.month, date.day);
    
    if (selectedDay == today) {
      return 'Today';
    } else if (selectedDay == tomorrow) {
      return 'Tomorrow';
    } else {
      final difference = selectedDay.difference(today).inDays;
      if (difference > 0) {
        return 'In $difference day${difference == 1 ? '' : 's'}';
      } else {
        return 'Past date';
      }
    }
  }

  // Check if booking button should be enabled
  bool get _isBookingEnabled {
    final bool hasCourt = selectedCourt != null;
    final bool hasTimeSlots = availableTimeSlots.isNotEmpty;
    final bool hasSelected = selectedSlots.isNotEmpty;
    final bool withinLimit = selectedSlots.length <= 3;
    final bool consecutive = _areSlotsConsecutive(selectedSlots);
    final bool hasCustomerId = currentCustomerId != null;

    print('🔍 Booking button check:');
    print('  - Court selected: $hasCourt');
    print('  - Time slots available: $hasTimeSlots');
    print('  - Selected slots: ${selectedSlots.length}');
    print('  - Consecutive: $consecutive');
    print('  - Customer ID: $hasCustomerId');
    print('  - Total enabled: ${hasCourt && hasTimeSlots && hasSelected && withinLimit && consecutive && hasCustomerId}');

    return hasCourt && hasTimeSlots && hasSelected && withinLimit && consecutive && hasCustomerId;
  }

  bool _areSlotsConsecutive(List<TimeSlot> slots) {
    if (slots.isEmpty) return false;
    final sorted = [...slots]..sort((a,b) => a.start.compareTo(b.start));
    for (int i = 1; i < sorted.length; i++) {
      if (sorted[i-1].end != sorted[i].start) return false;
    }
    return true;
  }

  // Get appropriate booking button text
  String _getBookingButtonText() {
    if (currentCustomerId == null) {
      return "Please Login to Book";
    }
    if (selectedCourt == null) {
      return "Select a Court";
    }
    if (availableTimeSlots.isEmpty) {
      return "No Available Times";
    }
    if (selectedSlots.isEmpty) return "Select Time Slots (max 3)";
    if (!_areSlotsConsecutive(selectedSlots)) return "Select Consecutive Slots";
    if (selectedSlots.length > 3) return "Max 3 Slots";
    return "Book Now";
  }

  Future<bool> _performFinalAvailabilityCheck() async {
    final dateString = DateFormat('yyyy-MM-dd').format(selectedDate);
    final courtId = selectedCourt!.id;

    try {
      // Get available time slots
      final availableSlots = await BookingService.getAvailableTimes(
        courtId: courtId,
        date: dateString,
      );
      
      // Get existing bookings for this court and date
      final existingBookings = await BookingService.getCourtBookings(
        courtId: courtId,
        date: dateString,
      );
      
      // Filter out conflicting slots
      final filteredSlots = _filterConflictingTimeSlots(availableSlots, existingBookings);

      final selectedSlotStarts = selectedSlots.map((s) => s.start).toList();
      final availableSlotStarts = filteredSlots.map((s) => s['start'] as String).toList();

      // Check if all selected slots are still available
      for (final selectedSlotStart in selectedSlotStarts) {
        if (!availableSlotStarts.contains(selectedSlotStart)) {
          _showErrorCard(
            title: 'Slots Unavailable',
            message: 'One or more selected time slots are no longer available. Please select new slots.',
            icon: Icons.warning,
            color: Colors.red,
          );
          
          // Refresh the available time slots to show current availability
          _loadAvailableTimeSlots();
          return false;
        }
      }
      return true;
    } catch (e) {
      _showErrorCard(
        title: 'Error Checking Availability',
        message: 'Failed to verify slot availability. Please try again.',
        icon: Icons.error,
        color: Colors.red,
      );
      return false;
    }
  }

  Future<bool> _showFallbackModeConfirmation() async {
    return await showDialog<bool>(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Warning'),
          content: const Text(
            'You are in fallback mode. Some time slots might not be accurate due to recent bookings. '
            'Are you sure you want to proceed with booking?',
          ),
          actions: <Widget>[
            TextButton(
              onPressed: () => Navigator.of(context).pop(false),
              child: const Text('Cancel'),
            ),
            TextButton(
              onPressed: () => Navigator.of(context).pop(true),
              child: const Text('Proceed'),
            ),
          ],
        );
      },
    ) ?? false;
  }


  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF9FBFD),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // 🔙 Back Button and Debug
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
              IconButton(
                icon: const Icon(Icons.arrow_back),
                onPressed: () => Navigator.pop(context),
                  ),
                  IconButton(
                    icon: const Icon(Icons.list),
                    onPressed: () => Navigator.pushNamed(context, '/booking-list'),
                    tooltip: 'View My Bookings',
                  ),
                ],
              ),

              // 🔶 Banner
              SvgPicture.asset('assets/images/orderbanner.svg', width: double.infinity, height: 140, fit: BoxFit.fitWidth),

              const Text("Select Date", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
              const SizedBox(height: 8),
              _buildDateSelector(),
              const SizedBox(height: 20),
              // Removed manual time & duration selectors for multi-select slot flow
              const SizedBox(height: 8),
              const Text("Select Court", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
              const SizedBox(height: 10),
              _buildCourtGrid(),
              const SizedBox(height: 30),
              
              // Booking status indicator
              if (selectedCourt != null) ...[
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: _isBookingEnabled ? Colors.green.withOpacity(0.1) : Colors.orange.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(
                      color: _isBookingEnabled ? Colors.green : Colors.orange,
                      width: 1,
                    ),
                  ),
                  child: Row(
                    children: [
                      Icon(
                        _isBookingEnabled ? Icons.check_circle : Icons.info,
                        color: _isBookingEnabled ? Colors.green : Colors.orange,
                        size: 20,
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          _isBookingEnabled 
                            ? 'Ready to book! ${selectedSlots.length} slot(s) selected.'
                            : 'Select up to 3 consecutive time slots to proceed.',
                          style: TextStyle(
                            color: _isBookingEnabled ? Colors.green : Colors.orange,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),
              ],
              
              ElevatedButton(
                onPressed: _isBookingEnabled ? () async {
                  // Final availability check before proceeding
                  if (!await _performFinalAvailabilityCheck()) {
                    return; // Stop if slots are no longer available
                  }
                  
                  // Show confirmation dialog if running in fallback mode
                  if (_isRunningInFallbackMode) {
                    final confirmed = await _showFallbackModeConfirmation();
                    if (!confirmed) {
                      return;
                    }
                  }
                  
                  final sorted = [...selectedSlots]..sort((a,b) => a.start.compareTo(b.start));
                  final first = sorted.first;
                  final hours = sorted.length; // 1h per slot

                  // compute selectedTime from first slot
                  final parts = first.start.split(':');
                  final hour = int.tryParse(parts[0]) ?? 0;
                  final minute = int.tryParse(parts[1]) ?? 0;
                  selectedTime = TimeOfDay(hour: hour, minute: minute);
                  selectedDuration = hours == 1 ? '1 hour' : '$hours hours';

                  print('📋 Booking details:');
                  print('  - Court: ${selectedCourt!.name}');
                  print('  - Date: ${DateFormat('yyyy-MM-dd').format(selectedDate)}');
                  print('  - Start: ${first.start}');
                  print('  - Slots: ${hours}');
                  print('  - Customer ID: $currentCustomerId');

                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => booking_details_create.BookingDetailsPage(
                        selectedCourt: selectedCourt!,
                        selectedDate: selectedDate,
                        selectedTime: selectedTime,
                        selectedDuration: selectedDuration,
                        customerId: currentCustomerId!,
                      ),
                    ),
                  );
                } : null,
                style: ElevatedButton.styleFrom(
                  backgroundColor: _isBookingEnabled ? const Color(0xFF4997D0) : Colors.grey.shade400,
                  minimumSize: const Size.fromHeight(50),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(25)),
                ),
                child: Text(
                  _getBookingButtonText(), 
                  style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w600)
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
