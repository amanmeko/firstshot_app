import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:intl/intl.dart';
import 'dart:convert';
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
  TimeSlot? selectedTimeSlot;
  bool isLoading = false;
  bool isLoadingTimeSlots = false;
  int? currentCustomerId;

  final List<String> durations = ["1 hour", "2 hours", "3 hours"];

  @override
  void initState() {
    super.initState();
    _checkAuthenticationAndLoad();
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
        print('⚠️ Found formatted customer ID: $customerId, will use user_id instead');
        customerId = null; // Reset to null so we use user_id
      } else {
        parsedId = int.tryParse(customerId);
      }
      
      if (parsedId != null) {
        setState(() {
          currentCustomerId = parsedId;
        });
        print('✅ Customer ID loaded successfully: $currentCustomerId');
        
        // Save to shared preferences as backup for future use
        if (customerId != null) {
          await prefs.setString('customer_id', customerId);
          print('💾 Saved customer ID to shared preferences as backup');
        }
      }
    }
    
    // If we still don't have a valid customer ID, try to get user_id
    if (currentCustomerId == null) {
      print('🔍 Trying to get user_id as customer ID...');
      
      // Try to get all keys from secure storage
      try {
        final allKeys = await storage.readAll();
        print('🔐 Available keys in secure storage: ${allKeys.keys.toList()}');
        
        // Use user_id as the primary customer ID
        if (allKeys.containsKey('user_id')) {
          final userId = allKeys['user_id'];
          if (userId != null && userId.isNotEmpty) {
            final parsedId = int.tryParse(userId);
            if (parsedId != null) {
              setState(() {
                currentCustomerId = parsedId;
              });
              print('✅ Using user_id as customer_id: $currentCustomerId');
              
              // Save this as customer_id for future use
              await prefs.setString('customer_id', userId);
              await storage.write(key: 'customer_id', value: userId);
              print('💾 Saved user_id as customer_id for future use');
            }
          }
        }
      } catch (e) {
        print('❌ Error reading secure storage keys: $e');
      }
    }
    
    if (currentCustomerId == null) {
      print('❌ No valid customer ID found in any storage location');
    }
  }

  Future<void> _loadCourts() async {
    setState(() {
      isLoading = true;
    });

    try {
      print('🔍 Loading courts from API...');
      final response = await BookingService.getCourts();
      print('📡 API Response: $response');
      
      if (response['success']) {
        final courtsData = response['courts'] as List;
        print('🏟️ Courts data: $courtsData');
        
        setState(() {
          courts = courtsData.map((court) => Court.fromJson(court)).toList();
          isLoading = false;
        });
        
        print('✅ Loaded ${courts.length} courts successfully');
      } else {
        print('❌ API returned success: false');
        setState(() {
          isLoading = false;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('API Error: ${response['message'] ?? 'Unknown error'}')),
        );
      }
    } catch (e) {
      print('💥 Exception loading courts: $e');
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
      final timeSlots = await BookingService.getAvailableTimes(
        courtId: selectedCourt!.id,
        date: dateString,
      );
      
      setState(() {
        availableTimeSlots = timeSlots.map((slot) => TimeSlot.fromJson(slot)).toList();
        isLoadingTimeSlots = false;
      });
    } catch (e) {
      setState(() {
        isLoadingTimeSlots = false;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error loading time slots: $e')),
      );
    }
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
          selectedTimeSlot = null; // Clear selected time slot when court changes
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
          const Text("Available Time Slots", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
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
                  final bool isSelected = selectedTimeSlot?.start == slot.start;
                  
                  return Container(
                    width: MediaQuery.of(context).size.width > 600 ? 120 : 100,
                    margin: const EdgeInsets.only(right: 12),
                    child: ElevatedButton(
                      onPressed: () {
                        setState(() {
                          selectedTimeSlot = slot;
                          selectedTime = TimeOfDay.fromDateTime(
                            DateTime.parse('2024-01-01 ${slot.start}:00')
                          );
                        });
                        print('🕐 Selected time slot: ${slot.display} (${slot.start} - ${slot.end})');
                      },
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
                          // Duration
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                            decoration: BoxDecoration(
                              color: Colors.white.withOpacity(0.2),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Text(
                              '${slot.duration}h',
                              style: const TextStyle(
                                fontSize: 11,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ),
                          const SizedBox(height: 4),
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
                    selectedTimeSlot = null; // Clear selected time slot when date changes
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
        selectedTimeSlot = null; // Clear selected time slot when date changes
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
    final bool hasSelectedTimeSlot = selectedTimeSlot != null;
    final bool hasCustomerId = currentCustomerId != null;
    
    print('🔍 Booking button check:');
    print('  - Court selected: $hasCourt');
    print('  - Time slots available: $hasTimeSlots');
    print('  - Time slot selected: $hasSelectedTimeSlot');
    print('  - Customer ID: $hasCustomerId');
    print('  - Total enabled: ${hasCourt && hasTimeSlots && hasSelectedTimeSlot && hasCustomerId}');
    
    return hasCourt && hasTimeSlots && hasSelectedTimeSlot && hasCustomerId;
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
    if (selectedTimeSlot == null) {
      return "Select a Time Slot";
    }
    return "Book Now";
  }

  // Debug method to show all stored data
  Future<void> _debugStorage() async {
    final prefs = await SharedPreferences.getInstance();
    final storage = const FlutterSecureStorage();
    
    print('🔍 === DEBUG STORAGE ===');
    print('📱 Shared Preferences Keys: ${prefs.getKeys()}');
    
    // Show all shared preferences values
    for (String key in prefs.getKeys()) {
      final value = prefs.getString(key);
      print('📱 $key: $value');
    }
    
    // Show all secure storage values
    try {
      final allKeys = await storage.readAll();
      print('🔐 Secure Storage Keys: ${allKeys.keys.toList()}');
      for (String key in allKeys.keys) {
        print('🔐 $key: ${allKeys[key]}');
      }
    } catch (e) {
      print('❌ Error reading secure storage: $e');
    }
    
    print('👤 Current Customer ID: $currentCustomerId');
    print('🔍 === END DEBUG ===');
    
    // Show dialog with debug info
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Debug Information'),
        content: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text('Current Customer ID: $currentCustomerId', 
                style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
              const SizedBox(height: 12),
              FutureBuilder<Map<String, String>>(
                future: storage.readAll(),
                builder: (context, snapshot) {
                  if (snapshot.hasData) {
                    final allKeys = snapshot.data!;
                    return Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('🔐 User ID (Primary): ${allKeys['user_id'] ?? 'null'}',
                          style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.green)),
                        const SizedBox(height: 8),
                        Text('📱 Customer ID (Formatted): ${allKeys['customer_id'] ?? 'null'}',
                          style: const TextStyle(color: Colors.orange)),
                        const SizedBox(height: 8),
                        Text('👤 User Name: ${allKeys['user_name'] ?? 'null'}'),
                        const SizedBox(height: 8),
                        Text('📧 Email: ${allKeys['email'] ?? 'null'}'),
                        const SizedBox(height: 8),
                        Text('📱 Mobile: ${allKeys['mobile_no'] ?? 'null'}'),
                        const SizedBox(height: 8),
                        Text('🎯 Level: ${allKeys['level'] ?? 'null'}'),
                        const SizedBox(height: 8),
                        Text('💰 Credit Balance: ${allKeys['credit_balance'] ?? 'null'}'),
                      ],
                    );
                  }
                  return const Text('Loading secure storage data...');
                },
              ),
              const SizedBox(height: 12),
              Text('📱 Shared Prefs Keys: ${prefs.getKeys().join(', ')}'),
              const SizedBox(height: 8),
              Text('Auth Token Present: ${prefs.getString('auth_token') != null ? 'Yes' : 'No'}'),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => _showManualCustomerIdInput(),
            child: const Text('Set Customer ID'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }

  // Manual customer ID input for testing
  void _showManualCustomerIdInput() {
    final controller = TextEditingController();
    
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Set Customer ID'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text('Enter customer ID for testing:'),
            const SizedBox(height: 8),
            TextField(
              controller: controller,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(
                labelText: 'Customer ID',
                border: OutlineInputBorder(),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              final customerId = int.tryParse(controller.text);
              if (customerId != null) {
                setState(() {
                  currentCustomerId = customerId;
                });
                print('✅ Manual customer ID set: $currentCustomerId');
                Navigator.pop(context);
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text('Customer ID set to: $customerId')),
                );
              } else {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Please enter a valid number')),
                );
              }
            },
            child: const Text('Set'),
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
                  Row(
                    children: [
                      IconButton(
                        icon: const Icon(Icons.refresh),
                        onPressed: _loadCourts,
                        tooltip: 'Reload Courts',
                      ),
                      IconButton(
                        icon: const Icon(Icons.person),
                        onPressed: _loadCustomerId,
                        tooltip: 'Reload Customer ID',
                      ),
                      IconButton(
                        icon: const Icon(Icons.bug_report),
                        onPressed: _debugStorage,
                        tooltip: 'Debug Storage',
                      ),
                    ],
                  ),
                ],
              ),

              // 🔶 Banner
              SvgPicture.asset('assets/images/orderbanner.svg', width: double.infinity, height: 140, fit: BoxFit.fitWidth),

              const Text("Select Date", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
              const SizedBox(height: 8),
              _buildDateSelector(),
              const SizedBox(height: 20),
              const Text("Select Time & Duration", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
              const SizedBox(height: 10),
              Row(
                children: [
                  GestureDetector(
                    onTap: _pickTime,
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        border: Border.all(color: Colors.grey.shade300),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Text(selectedTime.format(context), style: const TextStyle(fontSize: 16)),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: SingleChildScrollView(
                      scrollDirection: Axis.horizontal,
                      child: Row(
                        children: durations
                            .map((d) => Padding(
                          padding: const EdgeInsets.only(right: 8),
                          child: _buildDurationButton(d),
                        ))
                            .toList(),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 20),
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
                            ? 'Ready to book! All selections complete.'
                            : 'Please complete all selections to book.',
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
                onPressed: _isBookingEnabled ? () {
                  // Convert duration to hours (e.g., "1 hour" -> 1, "2 hours" -> 2)
                  final durationHours = int.parse(selectedDuration.split(' ')[0]);
                  
                  print('📋 Booking details:');
                  print('  - Court: ${selectedCourt!.name}');
                  print('  - Date: ${DateFormat('yyyy-MM-dd').format(selectedDate)}');
                  print('  - Time: ${selectedTimeSlot!.start}');
                  print('  - Duration: $durationHours hours');
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
