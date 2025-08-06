import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'services/api_service.dart';

class AddFriendsPage extends StatefulWidget {
  const AddFriendsPage({super.key});

  @override
  State<AddFriendsPage> createState() => _AddFriendsPageState();
}

class _AddFriendsPageState extends State<AddFriendsPage> {
  List<Map<String, dynamic>> _users = [];
  bool _isLoading = false;
  bool _hasSearched = false;
  final TextEditingController _searchController = TextEditingController();
  final Map<int, bool> _sendingRequests = {};

  @override
  void initState() {
    super.initState();
    // Don't load all users by default, wait for search
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _searchUsers(String query) async {
    if (query.trim().isEmpty) {
      setState(() {
        _users = [];
        _hasSearched = false;
      });
      return;
    }

    setState(() {
      _isLoading = true;
      _hasSearched = true;
    });

    try {
      final users = await ApiService.searchUsers(query.trim());
      setState(() {
        _users = users;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
      _showErrorSnackBar('Failed to search users: $e');
    }
  }

  Future<void> _sendFriendRequest(int targetUserId) async {
    setState(() {
      _sendingRequests[targetUserId] = true;
    });

    try {
      final success = await ApiService.sendFriendRequest(targetUserId);
      
      if (success) {
        _showSuccessSnackBar('Friend request sent!');
        
        // Update the user's status in the list
        setState(() {
          final userIndex = _users.indexWhere((user) => user['id'] == targetUserId);
          if (userIndex != -1) {
            _users[userIndex]['friend_request_sent'] = true;
          }
        });
      } else {
        _showErrorSnackBar('Failed to send friend request');
      }
    } catch (e) {
      _showErrorSnackBar('Failed to send friend request: $e');
    } finally {
      setState(() {
        _sendingRequests.remove(targetUserId);
      });
    }
  }

  void _showErrorSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.red,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  void _showSuccessSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.green,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  Widget _buildActionButton(Map<String, dynamic> user) {
    final userId = user['id'] as int;
    final isSending = _sendingRequests[userId] == true;
    final hasSentRequest = user['friend_request_sent'] == true;
    final isFriend = user['is_friend'] == true;
    final hasPendingRequest = user['has_pending_request'] == true;

    if (isFriend) {
      return Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          color: Colors.green.withOpacity(0.1),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: Colors.green),
        ),
        child: const Text(
          'Friends',
          style: TextStyle(color: Colors.green, fontSize: 12, fontWeight: FontWeight.bold),
        ),
      );
    }

    if (hasSentRequest) {
      return Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          color: Colors.orange.withOpacity(0.1),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: Colors.orange),
        ),
        child: const Text(
          'Request Sent',
          style: TextStyle(color: Colors.orange, fontSize: 12, fontWeight: FontWeight.bold),
        ),
      );
    }

    if (hasPendingRequest) {
      return Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          color: Colors.blue.withOpacity(0.1),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: Colors.blue),
        ),
        child: const Text(
          'Respond',
          style: TextStyle(color: Colors.blue, fontSize: 12, fontWeight: FontWeight.bold),
        ),
      );
    }

    return ElevatedButton(
      onPressed: isSending ? null : () => _sendFriendRequest(userId),
      style: ElevatedButton.styleFrom(
        backgroundColor: const Color(0xFF4997D0),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
        ),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      ),
      child: isSending
          ? const SizedBox(
              width: 12,
              height: 12,
              child: CircularProgressIndicator(
                strokeWidth: 2,
                valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
              ),
            )
          : const Text(
              'Add Friend',
              style: TextStyle(color: Colors.white, fontSize: 12),
            ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF9FBFD),
      appBar: AppBar(
        title: const Text(
          'Add Friends',
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
        ),
        backgroundColor: const Color(0xFF4997D0),
        iconTheme: const IconThemeData(color: Colors.white),
        elevation: 0,
      ),
      body: Column(
        children: [
          // Search bar
          Container(
            padding: const EdgeInsets.all(16),
            child: TextField(
              controller: _searchController,
              decoration: InputDecoration(
                hintText: 'Search by name, email, or customer ID...',
                prefixIcon: const Icon(Icons.search),
                suffixIcon: _searchController.text.isNotEmpty
                    ? IconButton(
                        icon: const Icon(Icons.clear),
                        onPressed: () {
                          _searchController.clear();
                          _searchUsers('');
                        },
                      )
                    : null,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(30),
                  borderSide: const BorderSide(color: Color(0xFF4997D0)),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(30),
                  borderSide: const BorderSide(color: Color(0xFF4997D0), width: 2),
                ),
                contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
              ),
              onChanged: (value) {
                // Debounce search
                Future.delayed(const Duration(milliseconds: 500), () {
                  if (_searchController.text == value) {
                    _searchUsers(value);
                  }
                });
              },
              onSubmitted: _searchUsers,
            ),
          ),
          // Results
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator())
                : !_hasSearched
                    ? const Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.search, size: 64, color: Colors.grey),
                            SizedBox(height: 16),
                            Text(
                              'Search for friends',
                              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.grey),
                            ),
                            SizedBox(height: 8),
                            Text(
                              'Enter a name, email, or customer ID to find people',
                              textAlign: TextAlign.center,
                              style: TextStyle(fontSize: 14, color: Colors.grey),
                            ),
                          ],
                        ),
                      )
                    : _users.isEmpty
                        ? const Center(
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(Icons.people_outline, size: 64, color: Colors.grey),
                                SizedBox(height: 16),
                                Text(
                                  'No users found',
                                  style: TextStyle(fontSize: 16, color: Colors.grey),
                                ),
                                SizedBox(height: 8),
                                Text(
                                  'Try a different search term',
                                  style: TextStyle(fontSize: 12, color: Colors.grey),
                                ),
                              ],
                            ),
                          )
                        : ListView.builder(
                            padding: const EdgeInsets.symmetric(horizontal: 16),
                            itemCount: _users.length,
                            itemBuilder: (context, index) {
                              final user = _users[index];
                              return Card(
                                margin: const EdgeInsets.only(bottom: 12),
                                elevation: 2,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: ListTile(
                                  contentPadding: const EdgeInsets.all(16),
                                  leading: CircleAvatar(
                                    radius: 30,
                                    backgroundImage: user['avatar_url']?.isNotEmpty == true
                                        ? CachedNetworkImageProvider(user['avatar_url'])
                                        : const AssetImage('assets/icons/avatar.png') as ImageProvider,
                                  ),
                                  title: Text(
                                    user['name'] ?? 'Unknown',
                                    style: const TextStyle(
                                      fontWeight: FontWeight.bold,
                                      fontSize: 16,
                                    ),
                                  ),
                                  subtitle: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      const SizedBox(height: 4),
                                      if (user['customer_id'] != null)
                                        Text(
                                          'ID: ${user['customer_id']}',
                                          style: const TextStyle(color: Colors.grey, fontSize: 12),
                                        ),
                                      if (user['email'] != null)
                                        Text(
                                          user['email'],
                                          style: const TextStyle(color: Colors.grey, fontSize: 12),
                                        ),
                                      if (user['level'] != null)
                                        Text(
                                          'Level: ${user['level']}',
                                          style: const TextStyle(color: Colors.grey, fontSize: 12),
                                        ),
                                      if (user['location'] != null)
                                        Text(
                                          'Location: ${user['location']}',
                                          style: const TextStyle(color: Colors.grey, fontSize: 12),
                                        ),
                                    ],
                                  ),
                                  trailing: _buildActionButton(user),
                                ),
                              );
                            },
                          ),
          ),
        ],
      ),
    );
  }
} 