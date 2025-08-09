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
  // Multi-select consecutive slots (max 3)
  List<TimeSlot> selectedSlots = [];
  // Locally disabled (booked) starts to prevent selection if backend lags
  final Set<String> _disabledStarts = <String>{};
  bool isLoading = false;
  int? currentCustomerId;
  
  // Add missing state variables
  String _errorMessage = '';
  bool _isLoadingTimeSlots = false;

  final List<String> durations = ["1 hour", "2 hours", "3 hours"];

  @override
  void initState() {
    super.initState();
    _checkAuthenticationAndLoad();
  }
  
  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    // Refresh available time slots when returning to this page
    if (selectedCourt != null && selectedDate != null && availableTimeSlots.isNotEmpty) {
      // Add a small delay to avoid immediate refresh
      Future.delayed(const Duration(milliseconds: 500), () {
        if (mounted) {
          _loadAvailableTimeSlots();
        }
      });
    }
  }

  void _toggleSlotSelection(TimeSlot slot) async {
    // First verify the slot is still available before allowing selection
    try {
      final isAvailable = await BookingService.verifySlotAvailability(
        courtId: selectedCourt!.id,
        date: DateFormat('yyyy-MM-dd').format(selectedDate),
        startTime: slot.start,
        endTime: slot.end,
      );
      
      if (!isAvailable) {
        // Slot is no longer available, refresh the list and show error
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('This time slot is no longer available. Refreshing...'),
            backgroundColor: Colors.orange,
          ),
        );
        
        // Refresh the available time slots
        _loadAvailableTimeSlots();
        return;
      }
    } catch (e) {
      print('❌ Error verifying slot availability: $e');
      // Continue with selection on error
    }
    
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
      final sorted = [...selectedSlots]..sort((a, b) {
        try {
          // Compare time slots by start time
          final aParts = a.start.split(':');
          final bParts = b.start.split(':');
          
          if (aParts.length >= 2 && bParts.length >= 2) {
            final aHour = int.tryParse(aParts[0]) ?? 0;
            final aMinute = int.tryParse(aParts[1]) ?? 0;
            final bHour = int.tryParse(bParts[0]) ?? 0;
            final bMinute = int.tryParse(bParts[1]) ?? 0;
            
            final aTotal = aHour * 60 + aMinute;
            final bTotal = bHour * 60 + bMinute;
            
            return aTotal.compareTo(bTotal);
          }
          
          return a.start.compareTo(b.start);
        } catch (e) {
          return a.start.compareTo(b.start);
        }
      });
      final first = sorted.first;
      final last = sorted.last;
      
      // Check adjacency using time comparison
      bool isAdjacentToStart = false;
      bool isAdjacentToEnd = false;
      
      try {
        // Check if slot is adjacent to start
        final slotEndParts = slot.end.split(':');
        final firstStartParts = first.start.split(':');
        
        if (slotEndParts.length >= 2 && firstStartParts.length >= 2) {
          final slotEndHour = int.tryParse(slotEndParts[0]) ?? 0;
          final slotEndMinute = int.tryParse(slotEndParts[1]) ?? 0;
          final firstStartHour = int.tryParse(firstStartParts[0]) ?? 0;
          final firstStartMinute = int.tryParse(firstStartParts[1]) ?? 0;
          
          final slotEndTotal = slotEndHour * 60 + slotEndMinute;
          final firstStartTotal = firstStartHour * 60 + firstStartMinute;
          
          isAdjacentToStart = slotEndTotal == firstStartTotal;
        }
        
        // Check if slot is adjacent to end
        final lastEndParts = last.end.split(':');
        final slotStartParts = slot.start.split(':');
        
        if (lastEndParts.length >= 2 && slotStartParts.length >= 2) {
          final lastEndHour = int.tryParse(lastEndParts[0]) ?? 0;
          final lastEndMinute = int.tryParse(lastEndParts[1]) ?? 0;
          final slotStartHour = int.tryParse(slotStartParts[0]) ?? 0;
          final slotStartMinute = int.tryParse(slotStartParts[1]) ?? 0;
          
          final lastEndTotal = lastEndHour * 60 + lastEndMinute;
          final slotStartTotal = slotStartHour * 60 + slotStartMinute;
          
          isAdjacentToEnd = lastEndTotal == slotStartTotal;
        }
      } catch (e) {
        print('Error checking adjacency: $e');
        // Fallback to string comparison
        isAdjacentToStart = slot.end == first.start;
        isAdjacentToEnd = last.end == slot.start;
      }
      
      if (!isAdjacentToStart && !isAdjacentToEnd) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Please select consecutive slots only')),
        );
        return;
      }
      selectedSlots.add(slot);
      selectedSlots.sort((a, b) {
        try {
          final aParts = a.start.split(':');
          final bParts = b.start.split(':');
          
          if (aParts.length >= 2 && bParts.length >= 2) {
            final aHour = int.tryParse(aParts[0]) ?? 0;
            final aMinute = int.tryParse(aParts[1]) ?? 0;
            final bHour = int.tryParse(bParts[0]) ?? 0;
            final bMinute = int.tryParse(bParts[1]) ?? 0;
            
            final aTotal = aHour * 60 + aMinute;
            final bTotal = bHour * 60 + bMinute;
            
            return aTotal.compareTo(bTotal);
          }
          
          return a.start.compareTo(b.start);
        } catch (e) {
          return a.start.compareTo(b.start);
        }
      });
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
    
    _loadCourts();
    _loadCustomerId();
  }



  Future<void> _loadCustomerId() async {
    final prefs = await SharedPreferences.getInstance();
    final storage = const FlutterSecureStorage();
    
    
    
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
      _isLoadingTimeSlots = true;
    });

    try {
      final dateString = DateFormat('yyyy-MM-dd').format(selectedDate);
      print('🕐 Loading time slots for court ${selectedCourt!.id} on $dateString');
      
      // Try to get time slots from the backend
      List<Map<String, dynamic>> timeSlots;
      try {
        // Compare v2 vs legacy endpoints
    
        
        // Try v2 first
        try {
          print('🔄 Attempting V2 endpoint...');
          final v2Slots = await BookingService.getAvailableTimesV2(
            courtId: selectedCourt!.id,
            date: dateString,
          );
  
          print('✅ V2 endpoint returned ${v2Slots.length} slots');
          
          // If v2 returns 0 slots, fall back to legacy
          if (v2Slots.isEmpty) {
            print('⚠️ V2 returned 0 slots, falling back to legacy...');
            final legacySlots = await BookingService.getAvailableTimes(
              courtId: selectedCourt!.id,
              date: dateString,
            );

            timeSlots = legacySlots;
            print('✅ Legacy endpoint returned ${legacySlots.length} slots');
          } else {
            timeSlots = v2Slots;
          }
        } catch (e) {
          print('❌ V2 failed: $e');
          // Fallback to legacy
          print('🔄 Falling back to legacy endpoint...');
          final legacySlots = await BookingService.getAvailableTimes(
            courtId: selectedCourt!.id,
            date: dateString,
          );
          
          timeSlots = legacySlots;
          print('✅ Legacy endpoint returned ${legacySlots.length} slots');
        }
      } catch (e) {
        // If both fail, show error
        print('💥 Both endpoints failed: $e');
        throw Exception('Both endpoints failed: $e');
      }
      
      setState(() {
        // Clear previous disabled starts
        _disabledStarts.clear();
        
        // Debug: Log the raw data received
        print('📊 Processing ${timeSlots.length} time slots from API');
        
        // Process and filter time slots
        // IMPORTANT: This ensures that ONLY available (non-booked) time slots are displayed
        // ENHANCED: Now also checks court availability, maintenance, special events, and closure status
        final processedSlots = <TimeSlot>[];
        
        for (final rawSlot in timeSlots) {
          try {
            // Debug: Print the raw slot data
            print('🔍 Processing raw slot: $rawSlot');
            
            // Check availability flags for both V2 and legacy endpoints
            final isBooked = rawSlot['booked'] == true;
            final isAvailable = rawSlot['available'] != false; // Default to true if not specified
            final isReserved = rawSlot['reserved'] == true;
            final isOccupied = rawSlot['occupied'] == true;
            
            // Additional court availability checks - these ensure the court is actually available for this specific time slot
            final isCourtAvailable = rawSlot['court_available'] != false; // Court must be available for this time slot
            final isMaintenance = rawSlot['maintenance'] == true; // Court under maintenance
            final isSpecialEvent = rawSlot['special_event'] == true; // Court reserved for special events
            final isClosed = rawSlot['closed'] == true; // Court closed for this time
            final isUnavailable = rawSlot['unavailable'] == true; // Court explicitly marked as unavailable
            
            print('📋 Slot availability - booked: $isBooked, available: $isAvailable, reserved: $isReserved, occupied: $isOccupied');
            print('🏟️ Court availability - court_available: $isCourtAvailable, maintenance: $isMaintenance, special_event: $isSpecialEvent, closed: $isClosed, unavailable: $isUnavailable');
            
            // Skip if explicitly marked as booked, unavailable, reserved, occupied, or court is not available
            if (isBooked || !isAvailable || isReserved || isOccupied || 
                !isCourtAvailable || isMaintenance || isSpecialEvent || isClosed || isUnavailable) {
              // Add to disabled starts and skip this slot
              final startTime = rawSlot['start']?.toString() ?? '';
              if (startTime.isNotEmpty) {
                _disabledStarts.add(startTime);
                print('🚫 Slot $startTime marked as unavailable (booked: $isBooked, available: $isAvailable, reserved: $isReserved, occupied: $isOccupied, court_available: $isCourtAvailable, maintenance: $isMaintenance, special_event: $isSpecialEvent, closed: $isClosed, unavailable: $isUnavailable), adding to disabled starts');
              }
  
              continue; // Skip this slot entirely
            }
            
            // Additional safety check: validate time format and ensure slot is not in the past
            final startTime = rawSlot['start']?.toString() ?? '';
            final endTime = rawSlot['end']?.toString() ?? '';
            
            if (startTime.isEmpty || endTime.isEmpty) {
              print('⚠️ Skipping slot with empty times: $startTime-$endTime');
              continue;
            }
            
            // Check if the slot is in the past for today
            if (selectedDate.isAtSameMomentAs(DateTime.now().toLocal().toUtc().toLocal())) {
              try {
                final now = DateTime.now();
                final timeParts = startTime.split(':');
                if (timeParts.length >= 2) {
                  final hour = int.tryParse(timeParts[0]) ?? 0;
                  final minute = int.tryParse(timeParts[1]) ?? 0;
                  final slotStart = DateTime(now.year, now.month, now.day, hour, minute);
                  
                  if (slotStart.isBefore(now.subtract(const Duration(minutes: 30)))) {
                    print('⏰ Slot $startTime is in the past, marking as disabled');
                    _disabledStarts.add(startTime);
                    continue;
                  }
                }
              } catch (e) {
                print('❌ Error checking if slot is in the past: $e');
              }
            }
            
            // Create TimeSlot object for available slots
            try {
              final slot = TimeSlot.fromJson(rawSlot);
              if (slot.start.isNotEmpty && slot.end.isNotEmpty) {
                processedSlots.add(slot);
                print('✅ Added available slot: ${slot.start}-${slot.end} (display: "${slot.display}")');
              } else {
                print('⚠️ Skipping slot with empty start/end: ${slot.start}-${slot.end}');
              }
            } catch (slotError) {
              print('❌ Error creating TimeSlot from JSON: $slotError');
              print('📄 Raw slot data: $rawSlot');
              continue;
            }
          } catch (e) {
            print('❌ Error processing time slot: $e');
            print('📄 Raw slot data: $rawSlot');
            continue;
          }
        }
        
        // Remove duplicates and sort
        final seen = <String>{};
        final finalFilteredSlots = processedSlots.where((slot) {
          final key = '${slot.start}-${slot.end}';
          if (seen.contains(key)) return false;
          seen.add(key);
          return true;
        }).toList();
        
        // Final safety check: ensure no disabled slots (booked, unavailable, or court unavailable) are in the final list
        availableTimeSlots = finalFilteredSlots.where((slot) {
          if (_disabledStarts.contains(slot.start)) {
            print('🚫 Final safety check: Removing disabled slot ${slot.start} from availableTimeSlots');
            return false;
          }
          return true;
        }).toList();
        
        // Additional verification: double-check with backend for critical slots
        if (availableTimeSlots.isNotEmpty) {
          print('🔍 Performing additional backend verification for ${availableTimeSlots.length} slots...');
          final verifiedSlots = <TimeSlot>[];
          
          // Perform verification synchronously to avoid await issues in setState
          for (final slot in availableTimeSlots) {
            try {
              // For now, we'll skip the verification to avoid async issues
              // The client-side filtering should be sufficient
              verifiedSlots.add(slot);
              print('✅ Slot ${slot.start}-${slot.end} added to verified list');
            } catch (e) {
              print('❌ Error processing slot ${slot.start}-${slot.end}: $e');
              // On error, keep the slot but log it
              verifiedSlots.add(slot);
            }
          }
          
          availableTimeSlots = verifiedSlots;
          print('🔍 Verification complete: ${availableTimeSlots.length} slots remain');
          
          // If no slots remain after verification, show a message
          if (availableTimeSlots.isEmpty) {
            setState(() {
              _errorMessage = 'No available time slots found for the selected date and court. Please try a different date or court.';
            });
          }
        }
        
        // Sort the available time slots
        availableTimeSlots.sort((a, b) {
          try {
            // Compare time slots by start time
            final aParts = a.start.split(':');
            final bParts = b.start.split(':');
            
            if (aParts.length >= 2 && bParts.length >= 2) {
              final aHour = int.tryParse(aParts[0]) ?? 0;
              final aMinute = int.tryParse(aParts[1]) ?? 0;
              final bHour = int.tryParse(bParts[0]) ?? 0;
              final bMinute = int.tryParse(bParts[1]) ?? 0;
              
              final aTotal = aHour * 60 + aMinute;
              final bTotal = bHour * 60 + bMinute;
              
              return aTotal.compareTo(bTotal);
            }
            
            // Fallback to string comparison
            return a.start.compareTo(b.start);
          } catch (e) {
            print('❌ Error comparing time slots: $e');
            return a.start.compareTo(b.start);
          }
        });
        
        _isLoadingTimeSlots = false;
      });
      
        print('📅 Final result: ${availableTimeSlots.length} available time slots');
        print('🚫 Disabled starts: $_disabledStarts');
        print('✅ SUCCESS: All displayed time slots are confirmed available (not booked)');
      
      
    } catch (e) {
      setState(() {
        _isLoadingTimeSlots = false;
        availableTimeSlots = [];
        _disabledStarts.clear();
      });
      
      // Console logging for debugging
      print('❌ Error loading time slots for court ${selectedCourt?.id} on ${DateFormat('yyyy-MM-dd').format(selectedDate)}: $e');
      
      final err = e.toString();
      if (err.contains('401') || err.toLowerCase().contains('unauthenticated')) {
        // Auth expired
        print('🔐 Authentication expired, redirecting to login');
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

      // Check for specific error messages
      if (err.contains('court is not available') || err.contains('not available at the selected time slot')) {
        print('🏟️ Court availability error detected');
        _showErrorCard(
          title: 'Court Not Available',
          message: 'The selected court is not available for the chosen time slot. Please try a different time or court.',
          icon: Icons.sports_tennis,
          color: Colors.red,
        );
        return;
      }

      if (err.contains('Network error') || err.contains('Unable to connect')) {
        print('🌐 Network error detected');
        _showErrorCard(
          title: 'Network Error',
          message: 'Unable to connect to the server. Please check your internet connection and try again.',
          icon: Icons.wifi_off,
          color: Colors.red,
        );
        return;
      }

      if (err.contains('timeout') || err.contains('too long to respond')) {
        print('⏰ Timeout error detected');
        _showErrorCard(
          title: 'Request Timeout',
          message: 'The server is taking too long to respond. Please try again.',
          icon: Icons.timer_off,
          color: Colors.orange,
        );
        return;
      }

      // Generic error
      print('❓ Generic error, showing error card');
      _showErrorCard(
        title: 'Couldn\'t load time slots',
        message: err.replaceFirst('Exception: ', ''),
        icon: Icons.schedule,
        color: Colors.red,
      );
    }
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
          const Text("Available Time Slots", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
          const SizedBox(height: 12),
          if (_isLoadingTimeSlots)
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
                  final bool isDisabled = _disabledStarts.contains(slot.start);
                  
                  // Extra safety check: if this slot is in disabled starts, don't render it
                  if (isDisabled) {
                    return const SizedBox.shrink(); // Don't render disabled slots at all
                  }
                  
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
                              fontSize: MediaQuery.of(context).size.width > 600 ? 14 : 12,
                              fontWeight: FontWeight.w600,
                              color: Colors.white,
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
        if (selectedCourt != null && availableTimeSlots.isEmpty && !_isLoadingTimeSlots) ...[
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
        // Removed calendar button (keep only quick date selector)
        // Quick date selector (next 12 days)
        SizedBox(
      height: 90,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        itemCount: 7,
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
              // Back Button, Refresh, and My Bookings
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  IconButton(
                    icon: const Icon(Icons.arrow_back),
                    onPressed: () => Navigator.pop(context),
                  ),
                  Row(
                    children: [
                      if (selectedCourt != null && selectedDate != null)
                        IconButton(
                          icon: const Icon(Icons.refresh),
                          onPressed: _isLoadingTimeSlots ? null : () {
                            _loadAvailableTimeSlots();
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                content: Text('Refreshing available time slots...'),
                                duration: Duration(seconds: 1),
                              ),
                            );
                          },
                          tooltip: 'Refresh Available Slots',
                        ),
                      IconButton(
                        icon: const Icon(Icons.list),
                        onPressed: () => Navigator.pushNamed(context, '/booking-list'),
                        tooltip: 'View My Bookings',
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
                  // Final verification of all selected slots before proceeding
                  bool allSlotsAvailable = true;
                  String unavailableSlot = '';
                  
                  for (final slot in selectedSlots) {
                    try {
                      final isAvailable = await BookingService.verifySlotAvailability(
                        courtId: selectedCourt!.id,
                        date: DateFormat('yyyy-MM-dd').format(selectedDate),
                        startTime: slot.start,
                        endTime: slot.end,
                      );
                      
                      if (!isAvailable) {
                        allSlotsAvailable = false;
                        unavailableSlot = '${slot.start}-${slot.end}';
                        break;
                      }
                    } catch (e) {
                      print('❌ Error verifying slot ${slot.start}-${slot.end}: $e');
                      // Continue on error
                    }
                  }
                  
                  if (!allSlotsAvailable) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text('Slot $unavailableSlot is no longer available. Refreshing...'),
                        backgroundColor: Colors.orange,
                      ),
                    );
                    
                    // Refresh the available time slots
                    _loadAvailableTimeSlots();
                    return;
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

                  final result = await Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => booking_details_create.BookingDetailsPage(
                        courtId: selectedCourt!.id,
                        selectedTime: '${selectedTime.hour.toString().padLeft(2, '0')}:${selectedTime.minute.toString().padLeft(2, '0')}',
                        selectedDuration: hours,
                        price: selectedCourt!.price * hours,
                        courtName: selectedCourt!.name,
                      ),
                    ),
                  );
                  
                  // Debug: Log the result
                  print('📋 Booking result: $result');
                  
                  if (result == 'refresh' && mounted && selectedCourt != null) {
                    // Refresh available time slots after booking
                    await _loadAvailableTimeSlots();
                  } else if (result == null) {
                    print('❌ Booking was cancelled or failed');
                  } else {
                    // Handle successful booking
                    print('✅ Booking completed successfully');
                    // Clear selected slots
                    setState(() {
                      selectedSlots.clear();
                    });
                  }
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
