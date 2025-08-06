import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:curved_navigation_bar/curved_navigation_bar.dart';
import 'package:shimmer/shimmer.dart';
import 'dart:convert';
import 'services/api_service.dart';

class GroupLessonScreen extends StatefulWidget {
  const GroupLessonScreen({super.key});

  @override
  State<GroupLessonScreen> createState() => _GroupLessonScreenState();
}

class _GroupLessonScreenState extends State<GroupLessonScreen> with SingleTickerProviderStateMixin {
  final storage = FlutterSecureStorage();
  List<dynamic> courses = [];
  List<dynamic> filteredCourses = [];
  bool isLoading = true;
  String? errorMessage;
  int currentPage = 1;
  int lastPage = 1;
  bool isFetchingMore = false;
  String? authToken;
  String? selectedDay;
  double scale = 1.0;
  late AnimationController _animationController;
  late Animation<double> _titleAnimation;
  final List<IconData> _icons = [
    Icons.calendar_today,
    Icons.group,
    Icons.home,
    Icons.sports_tennis,
    Icons.settings,
  ];
  final List<String> _labels = ['Booking', 'Group Lessons', 'Home', 'Instructors', 'Settings'];
  int _selectedIndex = 1;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 500),
      vsync: this,
    );
    _titleAnimation = Tween<double>(begin: 0.8, end: 1.0).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeOut),
    );
    _animationController.forward();
    _checkAuthAndFetchCourses();
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  Future<void> _checkAuthAndFetchCourses() async {
    print('Checking authentication...');
    final token = await ApiService.getAuthToken();
    if (token == null) {
      print('No token found, redirecting to login');
      _showSnackBar('Please log in to access group lessons.');
      WidgetsBinding.instance.addPostFrameCallback((_) {
        Navigator.pushReplacementNamed(context, '/login');
      });
      return;
    }
    print('Token found: $token');
    setState(() {
      authToken = token;
    });
    await _fetchCourses(page: currentPage, token: token);
  }

  Future<void> _fetchCourses({required int page, required String token}) async {
    print('Fetching courses for page $page');
    setState(() {
      isLoading = page == 1;
      isFetchingMore = page > 1;
    });

    try {
      final response = await http.get(
        Uri.parse('https://firstshot.my/api/auth/courses?page=$page'),
        headers: {
          'Authorization': 'Bearer $token',
          'Accept': 'application/json',
        },
      ).timeout(const Duration(seconds: 30));

      print('Courses API Response: ${response.statusCode} - ${response.body}');

      setState(() {
        isLoading = false;
        isFetchingMore = false;
      });

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        if (data['success'] == true && data['data'] != null && data['data']['courses'] != null) {
          final courseData = data['data']['courses'];
          setState(() {
            if (page == 1) {
              courses = (courseData['data'] as List?)?.where((course) => course['type'] == 'group').toList() ?? [];
              filteredCourses = courses;
            } else {
              courses.addAll((courseData['data'] as List?)?.where((course) => course['type'] == 'group') ?? []);
              filteredCourses = courses;
            }
            currentPage = courseData['current_page'] ?? 1;
            lastPage = courseData['last_page'] ?? 1;
            print('Parsed courses: ${courses.length}, currentPage: $currentPage, lastPage: $lastPage');
          });
        } else {
          setState(() {
            errorMessage = data['message'] ?? 'Failed to fetch courses.';
          });
          _showSnackBar(errorMessage!);
        }
      } else if (response.statusCode == 401) {
        print('Unauthorized, redirecting to login');
        _showSnackBar('Unauthorized. Please log in again.');
        await storage.delete(key: 'auth_token');
        WidgetsBinding.instance.addPostFrameCallback((_) {
          Navigator.pushReplacementNamed(context, '/login');
        });
      } else {
        setState(() {
          errorMessage = 'Failed to fetch courses: ${response.statusCode}';
        });
        _showSnackBar(errorMessage!);
      }
    } catch (e) {
      print('Fetch courses error: $e');
      setState(() {
        isLoading = false;
        isFetchingMore = false;
        errorMessage = 'Network error: $e';
      });
      _showSnackBar('Network error. Please check your connection and try again.');
    }
  }

  Future<void> _refreshCourses() async {
    if (authToken != null) {
      print('Refreshing courses');
      setState(() {
        courses.clear();
        filteredCourses.clear();
        currentPage = 1;
        errorMessage = null;
        selectedDay = null;
      });
      await _fetchCourses(page: 1, token: authToken!);
    }
  }

  void _showSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          message,
          style: GoogleFonts.montserrat(color: Colors.white, fontSize: 14),
        ),
        backgroundColor: message.contains('successfully') ? Colors.green : Colors.redAccent,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        margin: const EdgeInsets.all(16),
        duration: const Duration(seconds: 3),
      ),
    );
  }

  void _onItemTapped(int index) {
    setState(() => _selectedIndex = index);
    switch (index) {
      case 0:
        Navigator.pushNamed(context, '/booking');
        break;
      case 1:
        Navigator.pushNamed(context, '/groupclass');
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

  String _formatPrice(dynamic price) {
    if (price == null) return '0.00';
    if (price is num) return price.toStringAsFixed(2);
    if (price is String) {
      try {
        return double.parse(price).toStringAsFixed(2);
      } catch (e) {
        print('Price parsing error: $e');
        return '0.00';
      }
    }
    return '0.00';
  }

  void _filterByDay(String? day) {
    setState(() {
      selectedDay = day;
      if (day == null) {
        filteredCourses = courses;
      } else {
        filteredCourses = courses.where((course) => (course['days_of_week'] as List?)?.contains(day) ?? false).toList();
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: PreferredSize(
        preferredSize: const Size.fromHeight(70),
        child: AppBar(
          title: AnimatedBuilder(
            animation: _titleAnimation,
            builder: (context, child) {
              return Transform.scale(
                scale: _titleAnimation.value,
                child: Text(
                  'Group Lessons',
                  style: GoogleFonts.montserrat(
                    fontSize: 26,
                    fontWeight: FontWeight.w800,
                    color: Colors.white,
                  ),
                ),
              );
            },
          ),
          centerTitle: true,
          backgroundColor: Colors.transparent,
          foregroundColor: Colors.white,
          elevation: 6,
          flexibleSpace: Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  const Color(0xFF4997D0),
                  const Color(0xFF2A6D9A).withOpacity(0.95),
                ],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.2),
                  blurRadius: 10,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
          ),
          leading: IconButton(
            icon: const Icon(Icons.arrow_back, color: Colors.white, size: 28),
            onPressed: () => Navigator.pop(context),
          ),
          actions: [
            IconButton(
              icon: const Icon(Icons.search, color: Colors.white, size: 28),
              onPressed: () {
                _showSnackBar('Search functionality coming soon!');
              },
            ),
          ],
        ),
      ),
      body: SafeArea(
        child: Column(
          children: [
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
              child: Row(
                children: [
                  FilterChip(
                    label: Text(
                      'All',
                      style: GoogleFonts.montserrat(
                        fontSize: 13,
                        fontWeight: selectedDay == null ? FontWeight.w600 : FontWeight.w400,
                        color: selectedDay == null ? Colors.white : Colors.grey[600],
                      ),
                    ),
                    selected: selectedDay == null,
                    selectedColor: const Color(0xFF4997D0),
                    checkmarkColor: Colors.white,
                    onSelected: (_) => _filterByDay(null),
                    backgroundColor: Colors.grey[200],
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  ),
                  const SizedBox(width: 8),
                  ...['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'].map((day) => Padding(
                        padding: const EdgeInsets.only(right: 8),
                        child: FilterChip(
                          label: Text(
                            day,
                            style: GoogleFonts.montserrat(
                              fontSize: 13,
                              fontWeight: selectedDay == day ? FontWeight.w600 : FontWeight.w400,
                              color: selectedDay == day ? Colors.white : Colors.grey[600],
                            ),
                          ),
                          selected: selectedDay == day,
                          selectedColor: const Color(0xFF4997D0),
                          checkmarkColor: Colors.white,
                          onSelected: (_) => _filterByDay(day),
                          backgroundColor: Colors.grey[200],
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                        ),
                      )),
                ],
              ),
            ),
            Expanded(
              child: isLoading
                  ? Shimmer.fromColors(
                      baseColor: Colors.grey[200]!,
                      highlightColor: Colors.grey[100]!,
                      child: GridView.builder(
                        padding: const EdgeInsets.all(20),
                        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                          crossAxisCount: 2,
                          childAspectRatio: 0.65,
                          crossAxisSpacing: 20,
                          mainAxisSpacing: 20,
                        ),
                        itemCount: 4,
                        itemBuilder: (context, index) {
                          return Container(
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(16),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black.withOpacity(0.1),
                                  blurRadius: 10,
                                  offset: const Offset(0, 4),
                                ),
                              ],
                            ),
                          );
                        },
                      ),
                    )
                  : errorMessage != null
                      ? Center(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Text(
                                errorMessage!,
                                style: GoogleFonts.montserrat(
                                  fontSize: 16,
                                  color: Colors.redAccent,
                                  fontWeight: FontWeight.w500,
                                ),
                                textAlign: TextAlign.center,
                              ),
                              const SizedBox(height: 16),
                              ElevatedButton(
                                onPressed: _refreshCourses,
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: const Color(0xFF4997D0),
                                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                                  padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                                ),
                                child: Text(
                                  'Retry',
                                  style: GoogleFonts.montserrat(
                                    fontSize: 14,
                                    fontWeight: FontWeight.w600,
                                    color: Colors.white,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        )
                      : filteredCourses.isEmpty
                          ? Center(
                              child: Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Text(
                                    'No group lessons available.',
                                    style: GoogleFonts.montserrat(
                                      fontSize: 16,
                                      color: Colors.grey[600],
                                      fontWeight: FontWeight.w500,
                                    ),
                                  ),
                                  const SizedBox(height: 16),
                                  ElevatedButton(
                                    onPressed: _refreshCourses,
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor: const Color(0xFF4997D0),
                                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                                      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                                    ),
                                    child: Text(
                                      'Refresh',
                                      style: GoogleFonts.montserrat(
                                        fontSize: 14,
                                        fontWeight: FontWeight.w600,
                                        color: Colors.white,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            )
                          : RefreshIndicator(
                              onRefresh: _refreshCourses,
                              color: const Color(0xFF4997D0),
                              child: GridView.builder(
                                padding: const EdgeInsets.all(20),
                                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                                  crossAxisCount: 2,
                                  childAspectRatio: 0.65,
                                  crossAxisSpacing: 20,
                                  mainAxisSpacing: 20,
                                ),
                                itemCount: filteredCourses.length + (isFetchingMore ? 2 : 0),
                                itemBuilder: (context, index) {
                                  if (index >= filteredCourses.length) {
                                    return Shimmer.fromColors(
                                      baseColor: Colors.grey[200]!,
                                      highlightColor: Colors.grey[100]!,
                                      child: Container(
                                        decoration: BoxDecoration(
                                          color: Colors.white,
                                          borderRadius: BorderRadius.circular(16),
                                          boxShadow: [
                                            BoxShadow(
                                              color: Colors.black.withOpacity(0.1),
                                              blurRadius: 10,
                                              offset: const Offset(0, 4),
                                            ),
                                          ],
                                        ),
                                      ),
                                    );
                                  }
                                  final course = filteredCourses[index];
                                  final imageUrl = course['image'] != null
                                      ? 'https://firstshot.my/storage/${course['image']}'
                                      : null;
                                  return GestureDetector(
                                    onTapDown: (_) => setState(() => scale = 0.95),
                                    onTapUp: (_) => setState(() => scale = 1.0),
                                    onTapCancel: () => setState(() => scale = 1.0),
                                    onTap: () {
                                      final courseId = course['id'];
                                      if (courseId != null) {
                                        Navigator.pushNamed(context, '/classbookinginfo', arguments: courseId);
                                      } else {
                                        _showSnackBar('Invalid course ID');
                                      }
                                    },
                                    child: AnimatedContainer(
                                      duration: const Duration(milliseconds: 200),
                                      transform: Matrix4.identity()..scale(scale),
                                      child: Card(
                                        elevation: 6,
                                        shape: RoundedRectangleBorder(
                                          borderRadius: BorderRadius.circular(16),
                                          side: BorderSide(color: Colors.grey[200]!, width: 1),
                                        ),
                                        child: Container(
                                          decoration: BoxDecoration(
                                            color: Colors.white,
                                            borderRadius: BorderRadius.circular(16),
                                          ),
                                          child: Column(
                                            crossAxisAlignment: CrossAxisAlignment.start,
                                            children: [
                                              if (imageUrl != null)
                                                ClipRRect(
                                                  borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
                                                  child: SizedBox(
                                                    height: 150,
                                                    width: double.infinity,
                                                    child: CachedNetworkImage(
                                                      imageUrl: imageUrl,
                                                      fit: BoxFit.cover,
                                                      placeholder: (context, url) => Shimmer.fromColors(
                                                        baseColor: Colors.grey[200]!,
                                                        highlightColor: Colors.grey[100]!,
                                                        child: Container(color: Colors.white),
                                                      ),
                                                      errorWidget: (context, url, error) => Container(
                                                        color: Colors.grey[200],
                                                        child: const Icon(
                                                          Icons.broken_image,
                                                          size: 50,
                                                          color: Colors.grey,
                                                        ),
                                                      ),
                                                    ),
                                                  ),
                                                ),
                                              Expanded(
                                                child: Padding(
                                                  padding: const EdgeInsets.all(12),
                                                  child: Column(
                                                    crossAxisAlignment: CrossAxisAlignment.start,
                                                    children: [
                                                      Text(
                                                        course['name'] ?? 'Unnamed Course',
                                                        style: GoogleFonts.montserrat(
                                                          fontSize: 18,
                                                          fontWeight: FontWeight.w700,
                                                          color: Colors.black87,
                                                        ),
                                                        maxLines: 2,
                                                        overflow: TextOverflow.ellipsis,
                                                      ),
                                                      const SizedBox(height: 8),
                                                      Text(
                                                        'Coach: ${course['coach']?['name'] ?? 'Unknown'}',
                                                        style: GoogleFonts.montserrat(
                                                          fontSize: 13,
                                                          color: Colors.grey[600],
                                                        ),
                                                        maxLines: 1,
                                                        overflow: TextOverflow.ellipsis,
                                                      ),
                                                      const SizedBox(height: 6),
                                                      Text(
                                                        'Days: ${(course['days_of_week'] as List?)?.join(', ') ?? 'N/A'}',
                                                        style: GoogleFonts.montserrat(
                                                          fontSize: 13,
                                                          color: Colors.grey[600],
                                                        ),
                                                        maxLines: 1,
                                                        overflow: TextOverflow.ellipsis,
                                                      ),
                                                      const SizedBox(height: 6),
                                                      Text(
                                                        'Hours: ${course['hours'] ?? 0} hr${course['hours'] != 1 ? 's' : ''}',
                                                        style: GoogleFonts.montserrat(
                                                          fontSize: 13,
                                                          color: Colors.grey[600],
                                                        ),
                                                      ),
                                                      const SizedBox(height: 6),
                                                      Text(
                                                        'Price: RM ${_formatPrice(course['price'])}',
                                                        style: GoogleFonts.montserrat(
                                                          fontSize: 14,
                                                          color: Colors.deepOrange,
                                                          fontWeight: FontWeight.w700,
                                                        ),
                                                      ),
                                                      const SizedBox(height: 6),
                                                      Row(
                                                        children: [
                                                          Icon(
                                                            Icons.group,
                                                            size: 16,
                                                            color: Colors.grey[600],
                                                          ),
                                                          const SizedBox(width: 4),
                                                          Text(
                                                            '${course['registered_customers'] ?? 0} Registered',
                                                            style: GoogleFonts.montserrat(
                                                              fontSize: 13,
                                                              color: Colors.grey[600],
                                                              fontWeight: FontWeight.w500,
                                                            ),
                                                          ),
                                                        ],
                                                      ),
                                                      const Spacer(),
                                                      Align(
                                                        alignment: Alignment.centerRight,
                                                        child: ElevatedButton(
                                                          onPressed: () {
                                                            final courseId = course['id'];
                                                            if (courseId != null) {
                                                              Navigator.pushNamed(context, '/classbookinginfo',
                                                                  arguments: courseId);
                                                            } else {
                                                              _showSnackBar('Invalid course ID');
                                                            }
                                                          },
                                                          style: ElevatedButton.styleFrom(
                                                            backgroundColor: const Color(0xFF4997D0),
                                                            foregroundColor: Colors.white,
                                                            shape: RoundedRectangleBorder(
                                                              borderRadius: BorderRadius.circular(12),
                                                            ),
                                                            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                                                            elevation: 2,
                                                          ),
                                                          child: Text(
                                                            'Book Now',
                                                            style: GoogleFonts.montserrat(
                                                              fontSize: 13,
                                                              fontWeight: FontWeight.w600,
                                                              color: Colors.white,
                                                            ),
                                                          ),
                                                        ),
                                                      ),
                                                    ],
                                                  ),
                                                ),
                                              ),
                                            ],
                                          ),
                                        ),
                                      ),
                                    ),
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
        color: Colors.black, // Pure black as requested
        height: 50, // Smaller height to match main page
        animationDuration: const Duration(milliseconds: 300),
        items: List.generate(_icons.length, (index) {
          return Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              AnimatedScale(
                scale: _selectedIndex == index ? 1.2 : 1.0,
                duration: const Duration(milliseconds: 300),
                child: Icon(
                  _icons[index],
                  color: Colors.white,
                  size: 24, // Smaller size for compact bar
                ),
              ),
              Text(
                _labels[index],
                style: GoogleFonts.montserrat(
                  color: Colors.white,
                  fontSize: 10, // Smaller font for compact bar
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          );
        }),
        onTap: _onItemTapped,
      ),
    );
  }
}