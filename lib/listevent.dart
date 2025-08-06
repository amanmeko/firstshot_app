import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:curved_navigation_bar/curved_navigation_bar.dart';
import 'package:http/http.dart' as http;
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';
import 'services/api_service.dart';

class Event {
  final int id;
  final String title;
  final String? banner;
  final String? youtubeImage;
  final String eventDate;
  final String startTime;
  final String endTime;
  final String venue;
  final String location;
  final String description;
  final int organizerId;
  final String createdAt;
  final String updatedAt;
  final Organizer organizer;

  Event({
    required this.id,
    required this.title,
    this.banner,
    this.youtubeImage,
    required this.eventDate,
    required this.startTime,
    required this.endTime,
    required this.venue,
    required this.location,
    required this.description,
    required this.organizerId,
    required this.createdAt,
    required this.updatedAt,
    required this.organizer,
  });

  factory Event.fromJson(Map<String, dynamic> json) {
    return Event(
      id: json['id'],
      title: json['title'],
      banner: json['banner'],
      youtubeImage: json['youtube_image'],
      eventDate: json['event_date'],
      startTime: json['start_time'],
      endTime: json['end_time'],
      venue: json['venue'],
      location: json['location'],
      description: json['description'],
      organizerId: json['organizer_id'],
      createdAt: json['created_at'],
      updatedAt: json['updated_at'],
      organizer: Organizer.fromJson(json['organizer']),
    );
  }

  String? get bannerUrl {
    return banner != null ? 'https://firstshot.my/public/storage/$banner' : null;
  }
}

class Organizer {
  final int id;
  final String name;
  final String email;
  final String? phone;
  final String? address;
  final int isActive;
  final String? emailVerifiedAt;
  final String? mobileNo;
  final String? dateOfBirth;
  final String? avatar;
  final String createdAt;
  final String updatedAt;

  Organizer({
    required this.id,
    required this.name,
    required this.email,
    this.phone,
    this.address,
    required this.isActive,
    this.emailVerifiedAt,
    this.mobileNo,
    this.dateOfBirth,
    this.avatar,
    required this.createdAt,
    required this.updatedAt,
  });

  factory Organizer.fromJson(Map<String, dynamic> json) {
    return Organizer(
      id: json['id'],
      name: json['name'],
      email: json['email'],
      phone: json['phone'],
      address: json['address'],
      isActive: json['is_active'],
      emailVerifiedAt: json['email_verified_at'],
      mobileNo: json['mobile_no'],
      dateOfBirth: json['date_of_birth'],
      avatar: json['avatar'],
      createdAt: json['created_at'],
      updatedAt: json['updated_at'],
    );
  }
}

class ListEventsPage extends StatefulWidget {
  const ListEventsPage({super.key});

  @override
  State<ListEventsPage> createState() => _ListEventsPageState();
}

class _ListEventsPageState extends State<ListEventsPage> {
  int _selectedIndex = 0; // Adjust based on navigation bar index for events
  final List<String> _labels = ['Booking', 'Lessons', 'Home', 'Instructors', 'Settings'];
  final List<IconData> _icons = [
    Icons.calendar_today,
    Icons.assignment,
    Icons.home,
    Icons.sports_tennis,
    Icons.settings,
  ];

  List<Event> events = [];
  List<Event> filteredEvents = [];
  List<Organizer> organizers = [];
  String? selectedOrganizer;
  bool isLoading = true;
  String? errorMessage;
  int currentPage = 1;
  int lastPage = 1;
  final storage = FlutterSecureStorage();
  final TextEditingController _searchController = TextEditingController();
  final FocusNode _searchFocusNode = FocusNode();

  @override
  void initState() {
    super.initState();
    _fetchEvents();
    _searchController.addListener(_onSearchChanged);
  }

  @override
  void dispose() {
    _searchController.dispose();
    _searchFocusNode.dispose();
    super.dispose();
  }

  void _onSearchChanged() {
    final query = _searchController.text.trim().toLowerCase();
    setState(() {
      if (query.isEmpty) {
        filteredEvents = events;
      } else {
        filteredEvents = events
            .where((event) => event.title.toLowerCase().contains(query))
            .toList();
      }
    });
  }

  Future<void> _fetchEvents({String? organizer, String? searchQuery, int page = 1}) async {
    setState(() {
      isLoading = true;
      errorMessage = null;
    });

    try {
      String? token = await ApiService.getAuthToken();
      final queryParameters = {
        if (organizer != null) 'organizer': organizer,
        if (searchQuery != null && searchQuery.isNotEmpty) 'search': searchQuery,
        'page': page.toString(),
      };
      final uri = Uri.parse('https://firstshot.my/api/auth/events')
          .replace(queryParameters: queryParameters);

      final response = await http.get(
        uri,
        headers: {
          'Accept': 'application/json',
          'Authorization': 'Bearer $token',
        },
      );

      if (response.statusCode == 200) {
        final jsonData = json.decode(response.body);
        if (jsonData['status'] == 'success') {
          setState(() {
            events = (jsonData['events']['data'] as List)
                .map((json) => Event.fromJson(json))
                .toList();
            filteredEvents = events;
            if (_searchController.text.isNotEmpty) {
              _onSearchChanged();
            }
            organizers = (jsonData['users'] as List)
                .map((json) => Organizer.fromJson(json))
                .toList();
            currentPage = jsonData['events']['current_page'];
            lastPage = jsonData['events']['last_page'];
            isLoading = false;
          });
        } else {
          setState(() {
            isLoading = false;
            errorMessage = jsonData['message'] ?? 'Failed to load events';
          });
        }
      } else {
        setState(() {
          isLoading = false;
          errorMessage = 'Failed to load events: ${response.statusCode}';
        });
      }
    } catch (e) {
      setState(() {
        isLoading = false;
        errorMessage = 'Error: $e';
      });
    }
  }

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
      backgroundColor: Colors.white,
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
                Text(_labels[index], style: const TextStyle(color: Colors.white, fontSize: 10)),
            ],
          );
        }),
        onTap: _navigate,
      ),
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Top Bar with Back and Search
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              child: Row(
                children: [
                  IconButton(
                    icon: const Icon(Icons.arrow_back, color: Colors.black87),
                    onPressed: () => Navigator.pop(context),
                  ),
                  Expanded(
                    child: Container(
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(30),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.1),
                            blurRadius: 8,
                            offset: const Offset(0, 2),
                          ),
                        ],
                      ),
                      child: TextField(
                        controller: _searchController,
                        focusNode: _searchFocusNode,
                        decoration: InputDecoration(
                          hintText: 'Search events...',
                          hintStyle: TextStyle(color: Colors.grey.shade500),
                          prefixIcon: Icon(Icons.search, color: Colors.grey.shade500),
                          suffixIcon: _searchController.text.isNotEmpty
                              ? IconButton(
                                  icon: Icon(Icons.clear, color: Colors.grey.shade500),
                                  onPressed: () {
                                    _searchController.clear();
                                    _searchFocusNode.requestFocus();
                                  },
                                )
                              : null,
                          border: InputBorder.none,
                          contentPadding: const EdgeInsets.symmetric(vertical: 14, horizontal: 20),
                        ),
                        style: const TextStyle(fontSize: 16, color: Colors.black87),
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      border: Border.all(color: Colors.grey.shade300),
                      borderRadius: BorderRadius.circular(30),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.05),
                          blurRadius: 4,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                    child: const Icon(Icons.more_horiz, color: Colors.black87, size: 20),
                  ),
                ],
              ),
            ),

            // Organizer Dropdown
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              child: Container(
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(30),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.1),
                      blurRadius: 8,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: DropdownButtonFormField<String>(
                  value: selectedOrganizer,
                  decoration: InputDecoration(
                    prefixIcon: Icon(Icons.person, color: Colors.grey.shade500),
                    border: InputBorder.none,
                    contentPadding: const EdgeInsets.symmetric(vertical: 14, horizontal: 20),
                  ),
                  hint: const Text('Select Organizer', style: TextStyle(color: Colors.grey)),
                  items: [
                    const DropdownMenuItem<String>(
                      value: null,
                      child: Text('All', style: TextStyle(color: Colors.black87)),
                    ),
                    ...organizers.map((organizer) => DropdownMenuItem<String>(
                          value: organizer.name,
                          child: Text(organizer.name, style: const TextStyle(color: Colors.black87)),
                        )),
                  ],
                  onChanged: (value) {
                    setState(() {
                      selectedOrganizer = value;
                    });
                    _fetchEvents(organizer: value, searchQuery: _searchController.text.trim());
                  },
                  dropdownColor: Colors.white,
                  icon: Icon(Icons.arrow_drop_down, color: Colors.grey.shade500),
                ),
              ),
            ),
            const SizedBox(height: 10),

            // Grid of events
            Expanded(
              child: isLoading
                  ? const Center(child: CircularProgressIndicator(color: Color(0xFF4997D0)))
                  : errorMessage != null
                      ? Center(child: Text(errorMessage!, style: const TextStyle(color: Colors.red)))
                      : filteredEvents.isEmpty
                          ? const Center(child: Text('No events found', style: TextStyle(color: Colors.grey)))
                          : GridView.builder(
                              padding: const EdgeInsets.symmetric(horizontal: 16),
                              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                                crossAxisCount: 2,
                                childAspectRatio: 0.72,
                                crossAxisSpacing: 12,
                                mainAxisSpacing: 12,
                              ),
                              itemCount: filteredEvents.length,
                              itemBuilder: (context, index) => _buildEventCard(context, filteredEvents[index]),
                            ),
            ),

            // Pagination
            if (!isLoading && filteredEvents.isNotEmpty)
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 16),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    if (currentPage > 1)
                      IconButton(
                        icon: const Icon(Icons.arrow_back, color: Color(0xFF4997D0)),
                        onPressed: () => _fetchEvents(
                          organizer: selectedOrganizer,
                          searchQuery: _searchController.text.trim(),
                          page: currentPage - 1,
                        ),
                      ),
                    Text('Page $currentPage of $lastPage', style: const TextStyle(fontWeight: FontWeight.w500)),
                    if (currentPage < lastPage)
                      IconButton(
                        icon: const Icon(Icons.arrow_forward, color: Color(0xFF4997D0)),
                        onPressed: () => _fetchEvents(
                          organizer: selectedOrganizer,
                          searchQuery: _searchController.text.trim(),
                          page: currentPage + 1,
                        ),
                      ),
                  ],
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildEventCard(BuildContext context, Event event) {
    final date = DateTime.parse(event.eventDate).toLocal();
    final formattedDate = '${date.day}/${date.month}/${date.year}';

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 8,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Image
          Expanded(
            child: ClipRRect(
              borderRadius: const BorderRadius.vertical(top: Radius.circular(10)),
              child: event.bannerUrl != null
                  ? CachedNetworkImage(
                      imageUrl: event.bannerUrl!,
                      fit: BoxFit.cover,
                      width: double.infinity,
                      placeholder: (context, url) => const Center(child: CircularProgressIndicator()),
                      errorWidget: (context, url, error) => SvgPicture.asset(
                        'assets/images/paddle_m5.svg', // Reuse placeholder from products
                        fit: BoxFit.fitWidth,
                        width: double.infinity,
                      ),
                    )
                  : SvgPicture.asset(
                      'assets/images/paddle_m5.svg',
                      fit: BoxFit.fitWidth,
                      width: double.infinity,
                    ),
            ),
          ),
          // Details
          Padding(
            padding: const EdgeInsets.all(10),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  event.title,
                  style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 4),
                Text(
                  '$formattedDate, ${event.startTime} - ${event.endTime}',
                  style: const TextStyle(fontSize: 12, color: Color(0xFF4997D0)),
                ),
                const SizedBox(height: 4),
                Text(
                  event.venue,
                  style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
                ),
                const SizedBox(height: 4),
                Text(
                  'By ${event.organizer.name}',
                  style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
                ),
                const SizedBox(height: 6),
                Align(
                  alignment: Alignment.centerRight,
                  child: ElevatedButton(
                    onPressed: () {
                      // Placeholder for event details navigation
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(content: Text('View details for ${event.title}')),
                      );
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF4997D0),
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                      elevation: 2,
                    ),
                    child: const Text('View Details', style: TextStyle(fontSize: 12)),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}