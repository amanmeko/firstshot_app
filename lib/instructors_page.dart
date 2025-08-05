import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:http/http.dart' as http;
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'dart:convert';
import 'dart:math';

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
      id: json['id'],
      coachId: json['coach_id'],
      name: json['name'],
      duration: json['duration'],
      price: double.parse(json['price'].toString()),
      type: json['type'],
      createdAt: json['created_at'],
      updatedAt: json['updated_at'],
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
      id: json['id'],
      name: json['name'],
      mobileNo: json['mobile_no'],
      dateOfBirth: json['date_of_birth'],
      level: json['level'],
      duprId: json['dupr_id'],
      avatar: json['avatar'],
      experiences: json['experiences'],
      createdAt: json['created_at'],
      updatedAt: json['updated_at'],
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
    return avatar != null ? 'https://firstshot.my/public/storage/$avatar' : null;
  }
}

class InstructorsPage extends StatefulWidget {
  const InstructorsPage({super.key});

  @override
  State<InstructorsPage> createState() => _InstructorsPageState();
}

class _InstructorsPageState extends State<InstructorsPage> with TickerProviderStateMixin {
  List<Coach> instructors = [];
  List<Coach> filteredInstructors = [];
  String? selectedCoachingType;
  bool isLoading = true;
  String? errorMessage;
  final storage = FlutterSecureStorage();
  final TextEditingController _searchController = TextEditingController();
  final FocusNode _searchFocusNode = FocusNode();
  late List<AnimationController> _controllers;

  @override
  void initState() {
    super.initState();
    _controllers = [];
    _fetchCoaches();
    _searchController.addListener(_onSearchChanged);
  }

  @override
  void dispose() {
    _searchController.dispose();
    _searchFocusNode.dispose();
    for (var controller in _controllers) {
      controller.dispose();
    }
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
    });
  }

  Future<void> _fetchCoaches({String? type, int page = 1}) async {
    setState(() {
      isLoading = true;
      errorMessage = null;
    });

    try {
      String? token = await storage.read(key: 'auth_token');
      print('Retrieved token: $token');
      if (token == null) {
        // setState(() {
        //   isLoading = false;
        //   errorMessage = 'No authentication token found. Please log in again.';
        // });
        // ScaffoldMessenger.of(context).showSnackBar(
        //   const SnackBar(content: Text('Session expired. Please log in again.')),
        // );
        // await Future.delayed(const Duration(seconds: 2));
        // if (mounted) {
        //   Navigator.pushReplacementNamed(context, '/login');
        // }
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
        },
      );

      // print('Response status (type=$type, page=$page): ${response.statusCode}');
      // print('Response body: ${response.body}');

      if (response.statusCode == 200) {
        final jsonData = json.decode(response.body);
        if (jsonData['success'] == true) {
          setState(() {
            instructors = (jsonData['data'] as List)
                .map((json) => Coach.fromJson(json))
                .toList();
            filteredInstructors = instructors;
            if (_searchController.text.isNotEmpty || selectedCoachingType != null) {
              _onSearchChanged();
            }
            isLoading = false;
            _controllers = List.generate(
              instructors.length,
              (index) => AnimationController(
                vsync: this,
                duration: const Duration(seconds: 1),
              ),
            );
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
        await Future.delayed(const Duration(seconds: 2));
        if (mounted) {
          Navigator.pushReplacementNamed(context, '/login');
        }
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
      print('Error: $e');
    }
  }

  void _startSpin(int index) {
    if (index < _controllers.length) {
      _controllers[index].forward(from: 0.0);
    }
  }

  void _navigateToCoachingInfo(BuildContext context) {
    Navigator.pushNamed(context, '/classbookinginfo');
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
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
                          hintText: 'Search instructors...',
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

            // Coaching Type Dropdown
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
                  value: selectedCoachingType,
                  decoration: InputDecoration(
                    prefixIcon: Icon(Icons.sports_tennis, color: Colors.grey.shade500),
                    border: InputBorder.none,
                    contentPadding: const EdgeInsets.symmetric(vertical: 14, horizontal: 20),
                  ),
                  hint: const Text('Select Coaching Type', style: TextStyle(color: Colors.grey)),
                  items: const [
                    DropdownMenuItem<String>(
                      value: null,
                      child: Text('All', style: TextStyle(color: Colors.black87)),
                    ),
                    DropdownMenuItem<String>(
                      value: 'private',
                      child: Text('Private', style: TextStyle(color: Colors.black87)),
                    ),
                    DropdownMenuItem<String>(
                      value: 'group',
                      child: Text('Group', style: TextStyle(color: Colors.black87)),
                    ),
                  ],
                  onChanged: (value) {
                    setState(() {
                      selectedCoachingType = value;
                      _onSearchChanged();
                    });
                    _fetchCoaches(type: value);
                  },
                  dropdownColor: Colors.white,
                  icon: Icon(Icons.arrow_drop_down, color: Colors.grey.shade500),
                ),
              ),
            ),
            const SizedBox(height: 10),

            // Coaches Horizontal List
            Expanded(
              child: isLoading
                  ? const Center(child: CircularProgressIndicator(color: Color(0xFF4997D0)))
                  : errorMessage != null
                      ? Center(child: Text(errorMessage!, style: const TextStyle(color: Colors.red)))
                      : filteredInstructors.isEmpty
                          ? const Center(child: Text('No instructors found', style: TextStyle(color: Colors.grey)))
                          : ListView.builder(
                              scrollDirection: Axis.horizontal,
                              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                              itemCount: filteredInstructors.length,
                              itemBuilder: (context, index) {
                                final coach = filteredInstructors[index];
                                return Container(
                                  width: 280, // Fixed width for each list item
                                  margin: const EdgeInsets.only(right: 12),
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
                                      // Avatar
                                      Expanded(
                                        flex: 3,
                                        child: ClipRRect(
                                          borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
                                          child: AnimatedBuilder(
                                            animation: _controllers[index],
                                            builder: (_, child) {
                                              return Transform.rotate(
                                                angle: _controllers[index].value * 2 * pi,
                                                child: child,
                                              );
                                            },
                                            child: coach.avatarUrl != null
                                                ? CachedNetworkImage(
                                                    imageUrl: coach.avatarUrl!,
                                                    fit: BoxFit.cover,
                                                    width: double.infinity,
                                                    placeholder: (context, url) => const Center(child: CircularProgressIndicator()),
                                                    errorWidget: (context, url, error) {
                                                      print('Image load error for ${coach.name}: ${coach.avatarUrl} - Error: $error');
                                                      return SvgPicture.asset(
                                                        'assets/images/default_coach.svg',
                                                        fit: BoxFit.cover,
                                                        width: double.infinity,
                                                      );
                                                    },
                                                  )
                                                : SvgPicture.asset(
                                                    'assets/images/default_coach.svg',
                                                    fit: BoxFit.cover,
                                                    width: double.infinity,
                                                  ),
                                          ),
                                        ),
                                      ),
                                      // Details
                                      Expanded(
                                        flex: 2,
                                        child: Padding(
                                          padding: const EdgeInsets.all(12),
                                          child: Column(
                                            crossAxisAlignment: CrossAxisAlignment.start,
                                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                            children: [
                                              Text(
                                                coach.name,
                                                style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                                                overflow: TextOverflow.ellipsis,
                                              ),
                                              Text(
                                                coach.coachingType,
                                                style: TextStyle(fontSize: 14, color: Colors.grey.shade600),
                                              ),
                                              const SizedBox(height: 8),
                                              Row(
                                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                                children: [
                                                  Expanded(
                                                    child: ElevatedButton(
                                                      onPressed: () => _startSpin(index),
                                                      style: ElevatedButton.styleFrom(
                                                        backgroundColor: const Color(0xFF4997D0),
                                                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                                                        padding: const EdgeInsets.symmetric(vertical: 10),
                                                      ),
                                                      child: const Text('View Profile', style: TextStyle(fontSize: 12, color: Colors.white)),
                                                    ),
                                                  ),
                                                  const SizedBox(width: 8),
                                                  Expanded(
                                                    child: ElevatedButton(
                                                      onPressed: () => _navigateToCoachingInfo(context),
                                                      style: ElevatedButton.styleFrom(
                                                        backgroundColor: Colors.black,
                                                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                                                        padding: const EdgeInsets.symmetric(vertical: 10),
                                                      ),
                                                      child: const Text('Coaching Info', style: TextStyle(fontSize: 12, color: Colors.white)),
                                                    ),
                                                  ),
                                                ],
                                              ),
                                            ],
                                          ),
                                        ),
                                      ),
                                    ],
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