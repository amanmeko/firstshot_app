import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:curved_navigation_bar/curved_navigation_bar.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:provider/provider.dart';
import 'services/api_service.dart';
import 'user_profile.dart';

class ProfilePage extends StatefulWidget {
  const ProfilePage({super.key});

  @override
  State<ProfilePage> createState() => _ProfilePageState();
}

class _ProfilePageState extends State<ProfilePage> {
  int _selectedIndex = 4;
  List<Map<String, dynamic>> _friends = [];
  bool _isLoading = true;
  Map<String, dynamic>? _userProfile;
  List<Map<String, dynamic>> _friendRequests = [];
  int _totalFriends = 0;

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
    _loadUserData();
  }

  Future<void> _loadUserData() async {
    setState(() {
      _isLoading = true;
    });

    try {
      // Load user profile from Laravel API
      final profile = await ApiService.getUserProfile();
      if (profile != null) {
        setState(() {
          _userProfile = profile;
        });
      }
      
      // Load friends and friend requests
      final friends = await ApiService.getFriends();
      final friendRequests = await ApiService.getPendingRequests();
      
      setState(() {
        _friends = friends;
        _friendRequests = friendRequests;
        _totalFriends = friends.length;
        _isLoading = false;
      });
    } catch (e) {
      print('Error loading user data: $e');
      setState(() {
        _isLoading = false;
      });
      
      // Show error message
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to load profile data: ${e.toString()}'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  void _onItemTapped(int index) {
    setState(() => _selectedIndex = index);
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

  void _showFriendRequests() {
    Navigator.pushNamed(context, '/friend_requests').then((_) {
      // Refresh data when returning from friend requests page
      _loadUserData();
    });
  }

  void _showAddFriends() {
    Navigator.pushNamed(context, '/add_friends').then((_) {
      // Refresh data when returning from add friends page
      _loadUserData();
    });
  }

  @override
  Widget build(BuildContext context) {
    final userProfile = Provider.of<UserProfile>(context);
    
    // Use provider data first (most up-to-date), then fall back to API data
    final userName = userProfile.name.isNotEmpty ? userProfile.name : (_userProfile?['name'] ?? 'User');
    final userLevel = userProfile.level.isNotEmpty ? userProfile.level : (_userProfile?['level'] ?? 'Beginner');
    final userLocation = userProfile.location.isNotEmpty ? userProfile.location : (_userProfile?['location'] ?? 'Not set');
    final userAvatarUrl = userProfile.avatarUrl.isNotEmpty ? userProfile.avatarUrl : (_userProfile?['avatar_url'] ?? '');
    final userDuprId = userProfile.duprId.isNotEmpty ? userProfile.duprId : (_userProfile?['dupr_id'] ?? '');
    final userAbout = userProfile.about.isNotEmpty ? userProfile.about : (_userProfile?['about'] ?? 'No bio available');

    return Scaffold(
      backgroundColor: const Color(0xFFF9FBFD),
      body: SafeArea(
        child: RefreshIndicator(
          onRefresh: _loadUserData,
          child: SingleChildScrollView(
            physics: const AlwaysScrollableScrollPhysics(),
            child: Column(
              children: [
                Stack(
                  alignment: Alignment.center,
                  children: [
                    Image.asset(
                      'assets/images/splash_bgnew.png',
                      height: 230,
                      width: double.infinity,
                      fit: BoxFit.cover,
                    ),
                    // Back button
                    Positioned(
                      top: 16,
                      left: 12,
                      child: IconButton(
                        icon: const Icon(Icons.arrow_back, color: Colors.white, size: 28),
                        onPressed: () => Navigator.pop(context),
                      ),
                    ),
                    // Friend requests badge
                    Positioned(
                      top: 16,
                      right: 12,
                      child: Stack(
                        children: [
                          IconButton(
                            icon: const Icon(Icons.person_add, color: Colors.white, size: 28),
                            onPressed: _showFriendRequests,
                          ),
                          if (_friendRequests.isNotEmpty)
                            Positioned(
                              right: 8,
                              top: 8,
                              child: Container(
                                padding: const EdgeInsets.all(2),
                                decoration: BoxDecoration(
                                  color: Colors.red,
                                  borderRadius: BorderRadius.circular(10),
                                ),
                                constraints: const BoxConstraints(
                                  minWidth: 16,
                                  minHeight: 16,
                                ),
                                child: Text(
                                  '${_friendRequests.length}',
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontSize: 10,
                                  ),
                                  textAlign: TextAlign.center,
                                ),
                              ),
                            ),
                        ],
                      ),
                    ),
                    Positioned(
                      bottom: 0,
                      child: Stack(
                        alignment: Alignment.bottomRight,
                        children: [
                          CircleAvatar(
                            radius: 60,
                            backgroundImage: userAvatarUrl?.isNotEmpty == true
                                ? CachedNetworkImageProvider(userAvatarUrl)
                                : const AssetImage('assets/icons/avatar.png') as ImageProvider,
                          ),
                          GestureDetector(
                            onTap: () => Navigator.pushNamed(context, '/editprofile'),
                            child: Container(
                              decoration: const BoxDecoration(
                                color: Colors.white,
                                shape: BoxShape.circle,
                              ),
                              child: const Icon(Icons.edit, size: 24, color: Color(0xFF4997D0)),
                            ),
                          )
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Text(userName, style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold)),
                const SizedBox(height: 12),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    _outlinedBtn("Add Friends", _showAddFriends),
                    const SizedBox(width: 12),
                    _outlinedBtn("Edit Profile", () => Navigator.pushNamed(context, '/editprofile')),
                  ],
                ),
                const SizedBox(height: 24),
                _buildAboutSection(userAbout),
                const SizedBox(height: 16),
                _buildStatsAndFriends(),
                const SizedBox(height: 30),
              ],
            ),
          ),
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
                Text(_labels[index], style: const TextStyle(color: Colors.white, fontSize: 10)),
            ],
          );
        }),
        onTap: _onItemTapped,
      ),
    );
  }

  Widget _outlinedBtn(String label, VoidCallback onPressed) {
    return OutlinedButton(
      onPressed: onPressed,
      style: OutlinedButton.styleFrom(
        side: const BorderSide(color: Color(0xFF4997D0)),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(30)),
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
      ),
      child: Text(label, style: const TextStyle(fontWeight: FontWeight.bold, color: Color(0xFF4997D0))),
    );
  }

  Widget _buildAboutSection(String about) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text("About", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
          const SizedBox(height: 6),
          Text(
            about,
            style: const TextStyle(fontSize: 13, height: 1.4),
          ),
        ],
      ),
    );
  }

  Widget _buildStatsAndFriends() {
    final userProfile = Provider.of<UserProfile>(context);
    final userLevel = userProfile.level.isNotEmpty ? userProfile.level : (_userProfile?['level'] ?? 'Beginner');
    final userLocation = userProfile.location.isNotEmpty ? userProfile.location : (_userProfile?['location'] ?? 'Not set');
    final userDuprId = userProfile.duprId.isNotEmpty ? userProfile.duprId : (_userProfile?['dupr_id'] ?? '');

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _duprBox(userLevel, userLocation, userDuprId),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text("FirstShot Buddies", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                    Text('$_totalFriends friends', style: const TextStyle(color: Colors.grey, fontSize: 12)),
                  ],
                ),
                const SizedBox(height: 8),
                _isLoading
                    ? const Center(child: CircularProgressIndicator())
                    : _friends.isEmpty
                        ? Column(
                            children: [
                              const Text(
                                'No friends yet. Add some friends to get started!',
                                style: TextStyle(color: Colors.grey, fontSize: 12),
                              ),
                              const SizedBox(height: 8),
                              ElevatedButton(
                                onPressed: _showAddFriends,
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: const Color(0xFF4997D0),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(20),
                                  ),
                                ),
                                child: const Text('Find Friends', style: TextStyle(color: Colors.white)),
                              ),
                            ],
                          )
                        : Column(
                            children: [
                              Wrap(
                                spacing: 10,
                                runSpacing: 10,
                                children: _friends.take(6).map((friend) {
                                  return Column(
                                    children: [
                                      CircleAvatar(
                                        radius: 25,
                                        backgroundImage: friend['avatar_url']?.isNotEmpty == true
                                            ? CachedNetworkImageProvider(friend['avatar_url'])
                                            : const AssetImage('assets/icons/avatar.png') as ImageProvider,
                                      ),
                                      const SizedBox(height: 4),
                                      SizedBox(
                                        width: 50,
                                        child: Text(
                                          friend['name'] ?? 'Unknown',
                                          style: const TextStyle(fontSize: 10),
                                          textAlign: TextAlign.center,
                                          maxLines: 1,
                                          overflow: TextOverflow.ellipsis,
                                        ),
                                      ),
                                    ],
                                  );
                                }).toList(),
                              ),
                              if (_friends.length > 6)
                                Padding(
                                  padding: const EdgeInsets.only(top: 8),
                                  child: TextButton(
                                    onPressed: () {
                                      // Navigate to all friends page
                                      Navigator.pushNamed(context, '/all_friends');
                                    },
                                    child: Text('View all ${_friends.length} friends'),
                                  ),
                                ),
                            ],
                          ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _duprBox(String level, String location, String duprId) {
    return Container(
      width: 120,
      padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 12),
      decoration: BoxDecoration(
        color: const Color(0xFFE1F0FF),
        borderRadius: BorderRadius.circular(30),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text("Level", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
          const SizedBox(height: 4),
          Text(level.isNotEmpty ? level : 'Beginner'),
          const SizedBox(height: 14),
          const Text("Location", style: TextStyle(fontWeight: FontWeight.bold)),
          Text(location.isNotEmpty ? location : 'Not set'),
          const SizedBox(height: 14),
          const Text("DUPR", style: TextStyle(fontWeight: FontWeight.bold)),
          Text(duprId.isNotEmpty ? duprId : "Not set"),
        ],
      ),
    );
  }
}
