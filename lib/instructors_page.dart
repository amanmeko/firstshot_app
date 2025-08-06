import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:http/http.dart' as http;
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';
import 'package:provider/provider.dart';
import 'user_profile.dart';
import 'services/api_service.dart';

class Course {
  final int id;
  final int coachId;
  final String name;
  final String duration;
  final double price;
  final String type;
  final String createdAt;
  final String updatedAt;

  Course({
    required this.id,
    required this.coachId,
    required this.name,
    required this.duration,
    required this.price,
    required this.type,
    required this.createdAt,
    required this.updatedAt,
  });

  factory Course.fromJson(Map<String, dynamic> json) {
    return Course(
      id: json['id'] ?? 0,
      coachId: json['coach_id'] ?? 0,
      name: json['name']?.toString() ?? 'Unknown Course',
      duration: json['duration']?.toString() ?? '',
      price: double.tryParse(json['price']?.toString() ?? '0.0') ?? 0.0,
      type: json['type']?.toString() ?? 'unknown',
      createdAt: json['created_at']?.toString() ?? '',
      updatedAt: json['updated_at']?.toString() ?? '',
    );
  }
}

class Coach {
  final int id;
  final String name;
  final String? mobileNo;
  final String? dateOfBirth;
  final String? level;
  final String? duprId;
  final String? avatar;
  final String? experiences;
  final String? createdAt;
  final String? updatedAt;
  final List<Course> courses;

  Coach({
    required this.id,
    required this.name,
    this.mobileNo,
    this.dateOfBirth,
    this.level,
    this.duprId,
    this.avatar,
    this.experiences,
    this.createdAt,
    this.updatedAt,
    this.courses = const [],
  });

  factory Coach.fromJson(Map<String, dynamic> json) {
    return Coach(
      id: json['id'] ?? 0,
      name: json['name']?.toString() ?? 'Unknown Coach',
      mobileNo: json['mobile_no']?.toString(),
      dateOfBirth: json['date_of_birth']?.toString(),
      level: json['level']?.toString(),
      duprId: json['dupr_id']?.toString(),
      avatar: json['avatar']?.toString(),
      experiences: json['experiences']?.toString(),
      createdAt: json['created_at']?.toString(),
      updatedAt: json['updated_at']?.toString(),
      courses: (json['courses'] as List<dynamic>?)
              ?.map((courseJson) => Course.fromJson(courseJson))
              .toList() ??
          [],
    );
  }

  String get coachingType {
    if (courses.isEmpty) return 'Coaching: Unknown';
    final hasPrivate = courses.any((course) => course.type == 'private');
    final hasGroup = courses.any((course) => course.type == 'group');
    if (hasPrivate && hasGroup) return 'Coaching: Private | Group';
    if (hasPrivate) return 'Coaching: Private';
    if (hasGroup) return 'Coaching: Group';
    return 'Coaching: Unknown';
  }

  String? get avatarUrl {
    return avatar != null && avatar!.isNotEmpty
        ? (avatar!.startsWith('http')
            ? avatar
            : 'https://firstshot.my/public/storage/$avatar')
        : null;
  }
}

class InstructorsPage extends StatefulWidget {
  const InstructorsPage({super.key});

  @override
  State<InstructorsPage> createState() => _InstructorsPageState();
}

class _InstructorsPageState extends State<InstructorsPage>
    with TickerProviderStateMixin {
  List<Coach> instructors = [];
  List<Coach> filteredInstructors = [];
  String? selectedCoachingType;
  bool isLoading = true;
  String? errorMessage;
  final storage = FlutterSecureStorage();
  final TextEditingController _searchController = TextEditingController();
  final FocusNode _searchFocusNode = FocusNode();
  late List<AnimationController> _animationControllers;
  late List<Animation<double>> _fadeAnimations;

  @override
  void initState() {
    super.initState();
    _animationControllers = [];
    _fadeAnimations = [];
    _fetchCoaches();
    _searchController.addListener(_onSearchChanged);
    print('InstructorsPage: Initialized');
  }

  @override
  void dispose() {
    _searchController.dispose();
    _searchFocusNode.dispose();
    for (var controller in _animationControllers) {
      controller.dispose();
    }
    print('InstructorsPage: Disposed');
    super.dispose();
  }

  void _onSearchChanged() {
    final query = _searchController.text.trim().toLowerCase();
    setState(() {
      filteredInstructors = instructors.where((coach) {
        if (query.isEmpty && selectedCoachingType == null) return true;
        final matchesName = coach.name.toLowerCase().contains(query);
        final matchesType = selectedCoachingType == null ||
            coach.courses.any((course) => course.type == selectedCoachingType);
        return matchesName && matchesType;
      }).toList();
      _setupAnimations();
    });
  }

  void _setupAnimations() {
    for (var controller in _animationControllers) {
      controller.dispose();
    }
    _animationControllers = List.generate(
      filteredInstructors.length,
      (index) => AnimationController(
        vsync: this,
        duration: const Duration(milliseconds: 500),
      )..forward(),
    );
    _fadeAnimations = _animationControllers
        .map((controller) => Tween<double>(begin: 0.0, end: 1.0).animate(
            CurvedAnimation(parent: controller, curve: Curves.easeInOut)))
        .toList();
  }

  Future<void> _fetchCoaches({String? type, int page = 1}) async {
    setState(() {
      isLoading = true;
      errorMessage = null;
    });

    try {
      String? token = await ApiService.getAuthToken();
      print('InstructorsPage: Retrieved token: $token');
      if (token == null) {
        setState(() {
          isLoading = false;
          errorMessage = 'No authentication token found. Please log in again.';
        });
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Session expired. Please log in again.')),
        );
        return;
      }

      final queryParameters = {
        if (type != null) 'type': type,
        'page': page.toString(),
      };
      final uri = Uri.parse('https://firstshot.my/api/auth/coaches')
          .replace(queryParameters: queryParameters);

      final response = await http.get(
        uri,
        headers: {
          'Accept': 'application/json',
          'Authorization': 'Bearer $token',
        },
      );

      print('InstructorsPage: Response status (type=$type, page=$page): ${response.statusCode}');
      print('InstructorsPage: Response body: ${response.body}');

      if (response.statusCode == 200) {
        final jsonData = jsonDecode(response.body);
        final coachData = jsonData['data'] ?? jsonData['coaches'] ?? jsonData;
        if (jsonData['success'] == true || coachData is List) {
          setState(() {
            instructors = (coachData as List)
                .map((json) => Coach.fromJson(json))
                .toList();
            filteredInstructors = instructors;
            if (_searchController.text.isNotEmpty || selectedCoachingType != null) {
              _onSearchChanged();
            } else {
              _setupAnimations();
            }
            isLoading = false;
          });
        } else {
          setState(() {
            isLoading = false;
            errorMessage = jsonData['message'] ?? 'Failed to load coaches';
          });
        }
      } else if (response.statusCode == 401) {
        setState(() {
          isLoading = false;
          errorMessage = 'Unauthorized: Invalid or expired token. Please log in again.';
        });
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Invalid session. Please log in again.')),
        );
        await storage.delete(key: 'auth_token');
        return;
      } else {
        setState(() {
          isLoading = false;
          errorMessage = 'Failed to load coaches: ${response.statusCode} - ${response.body}';
        });
      }
    } catch (e) {
      setState(() {
        isLoading = false;
        errorMessage = 'Error fetching coaches: $e';
      });
      print('InstructorsPage: Error: $e');
    }
  }

  void _navigateToCoachingInfo(BuildContext context, Coach coach) {
    print('InstructorsPage: Navigating to /classbookinginfo for coach: ${coach.name}');
    Navigator.pushNamed(
      context,
      '/classbookinginfo',
      arguments: coach,
    );
  }

  void _navigateToCoachProfile(BuildContext context, Coach coach) {
    print('InstructorsPage: Navigating to /coach_profile for coach: ${coach.name}');
    Navigator.pushNamed(
      context,
      '/coach_profile',
      arguments: coach,
    );
  }

  void _showFilterModal(BuildContext context) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              title: const Text('All', style: TextStyle(fontWeight: FontWeight.w600)),
              onTap: () {
                setState(() {
                  selectedCoachingType = null;
                  _onSearchChanged();
                  _fetchCoaches();
                });
                Navigator.pop(context);
              },
            ),
            ListTile(
              title: const Text('Private', style: TextStyle(fontWeight: FontWeight.w600)),
              onTap: () {
                setState(() {
                  selectedCoachingType = 'private';
                  _onSearchChanged();
                  _fetchCoaches(type: 'private');
                });
                Navigator.pop(context);
              },
            ),
            ListTile(
              title: const Text('Group', style: TextStyle(fontWeight: FontWeight.w600)),
              onTap: () {
                setState(() {
                  selectedCoachingType = 'group';
                  _onSearchChanged();
                  _fetchCoaches(type: 'group');
                });
                Navigator.pop(context);
              },
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF9FBFD),
      appBar: AppBar(
        title: const Text(
          'Instructors',
          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 20),
        ),
        backgroundColor: Colors.white,
        elevation: 0,
        flexibleSpace: Container(
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              colors: [Color(0xFF4997D0), Color(0xFF6AB4E8)],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
          ),
        ),
        foregroundColor: Colors.white,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () async {
            print('InstructorsPage: Back button pressed, navigating to /main');
            String? token = await ApiService.getAuthToken();
            if (token != null) {
              Navigator.pushReplacementNamed(context, '/main');
            } else {
              print('InstructorsPage: No token found, redirecting to /login');
              Navigator.pushReplacementNamed(context, '/login');
            }
          },
          tooltip: 'Back to Home',
        ),
      ),
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Search Bar and Filter
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              child: Row(
                children: [
                  Expanded(
                    child: Container(
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.9),
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
                          hintText: 'Search instructors...',
                          hintStyle: TextStyle(color: Colors.grey.shade500, fontSize: 16),
                          prefixIcon: Icon(Icons.search, color: Colors.grey.shade500, size: 20),
                          suffixIcon: _searchController.text.isNotEmpty
                              ? IconButton(
                                  icon: Icon(Icons.clear, color: Colors.grey.shade500, size: 20),
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
                  GestureDetector(
                    onTap: () => _showFilterModal(context),
                    child: Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.9),
                        borderRadius: BorderRadius.circular(15),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.1),
                            blurRadius: 8,
                            offset: const Offset(0, 2),
                          ),
                        ],
                      ),
                      child: SvgPicture.asset(
                        'assets/icons/filter.svg',
                        width: 24,
                        height: 24,
                        color: const Color(0xFF4997D0),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            // Coaches List
            Expanded(
              child: isLoading
                  ? const Center(child: CircularProgressIndicator(color: Color(0xFF4997D0)))
                  : errorMessage != null
                      ? Center(child: Text(errorMessage!, style: const TextStyle(color: Colors.red, fontSize: 16)))
                      : filteredInstructors.isEmpty
                          ? const Center(child: Text('No instructors found', style: TextStyle(color: Colors.grey, fontSize: 16)))
                          : ListView.builder(
                              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                              itemCount: filteredInstructors.length,
                              itemBuilder: (context, index) {
                                final coach = filteredInstructors[index];
                                return FadeTransition(
                                  opacity: _fadeAnimations[index],
                                  child: Container(
                                    margin: const EdgeInsets.only(bottom: 12),
                                    decoration: BoxDecoration(
                                      color: Colors.white,
                                      borderRadius: BorderRadius.circular(15),
                                      boxShadow: [
                                        BoxShadow(
                                          color: Colors.black.withOpacity(0.05),
                                          blurRadius: 10,
                                          offset: const Offset(0, 2),
                                        ),
                                      ],
                                    ),
                                    child: Padding(
                                      padding: const EdgeInsets.all(12),
                                      child: Row(
                                        children: [
                                          // Avatar with Gradient Ring
                                          Container(
                                            decoration: BoxDecoration(
                                              shape: BoxShape.circle,
                                              gradient: const LinearGradient(
                                                colors: [Color(0xFF4997D0), Color(0xFF6AB4E8)],
                                              ),
                                            ),
                                            padding: const EdgeInsets.all(2),
                                            child: CircleAvatar(
                                              radius: 24,
                                              backgroundColor: Colors.grey[200],
                                              backgroundImage: coach.avatarUrl != null
                                                  ? CachedNetworkImageProvider(coach.avatarUrl!)
                                                  : null,
                                              onBackgroundImageError: coach.avatarUrl != null
                                                  ? (error, stackTrace) {
                                                      print('Image load error for ${coach.name}: ${coach.avatarUrl} - Error: $error');
                                                    }
                                                  : null,
                                              child: coach.avatarUrl == null || coach.avatarUrl!.isEmpty
                                                  ? Text(
                                                      coach.name.isNotEmpty ? coach.name[0].toUpperCase() : 'C',
                                                      style: const TextStyle(fontSize: 18, color: Colors.black54),
                                                    )
                                                  : null,
                                            ),
                                          ),
                                          const SizedBox(width: 12),
                                          // Coach Info
                                          Expanded(
                                            child: Column(
                                              crossAxisAlignment: CrossAxisAlignment.start,
                                              children: [
                                                Text(
                                                  coach.name,
                                                  style: const TextStyle(
                                                    fontWeight: FontWeight.bold,
                                                    fontSize: 16,
                                                    color: Colors.black87,
                                                  ),
                                                  overflow: TextOverflow.ellipsis,
                                                ),
                                                const SizedBox(height: 4),
                                                Text(
                                                  coach.coachingType,
                                                  style: TextStyle(
                                                    fontSize: 14,
                                                    color: Colors.grey.shade600,
                                                  ),
                                                ),
                                              ],
                                            ),
                                          ),
                                          // Action Buttons
                                          Row(
                                            mainAxisSize: MainAxisSize.min,
                                            children: [
                                              IconButton(
                                                onPressed: () => _navigateToCoachProfile(context, coach),
                                                icon: const Icon(Icons.person, color: Color(0xFF4997D0), size: 20),
                                                tooltip: 'View Profile',
                                              ),
                                              IconButton(
                                                onPressed: () => _navigateToCoachingInfo(context, coach),
                                                icon: const Icon(Icons.info, color: Colors.black87, size: 20),
                                                tooltip: 'Coaching Info',
                                              ),
                                            ],
                                          ),
                                        ],
                                      ),
                                    ),
                                  ),
                                );
                              },
                            ),
                            
            ),
          ],
        ),
      ),
    );
  }
}