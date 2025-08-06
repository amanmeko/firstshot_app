import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'services/api_service.dart';

class FriendRequestsPage extends StatefulWidget {
  const FriendRequestsPage({super.key});

  @override
  State<FriendRequestsPage> createState() => _FriendRequestsPageState();
}

class _FriendRequestsPageState extends State<FriendRequestsPage> {
  List<Map<String, dynamic>> _friendRequests = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadFriendRequests();
  }

  Future<void> _loadFriendRequests() async {
    setState(() {
      _isLoading = true;
    });

    try {
      final requests = await ApiService.getPendingRequests();
      setState(() {
        _friendRequests = requests;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
      _showErrorSnackBar('Failed to load friend requests: $e');
    }
  }

  Future<void> _acceptRequest(int senderId) async {
    try {
      // Show loading state for this specific request
      setState(() {
        final requestIndex = _friendRequests.indexWhere((request) => request['sender']['id'] == senderId);
        if (requestIndex != -1) {
          _friendRequests[requestIndex]['isProcessing'] = true;
        }
      });

      final success = await ApiService.acceptFriendRequest(senderId);
      
      if (success) {
        _showSuccessSnackBar('Friend request accepted!');
        
        // Remove the request from the list
        setState(() {
          _friendRequests.removeWhere((request) => request['sender']['id'] == senderId);
        });
      } else {
        _showErrorSnackBar('Failed to accept request');
        // Remove loading state
        setState(() {
          final requestIndex = _friendRequests.indexWhere((request) => request['sender']['id'] == senderId);
          if (requestIndex != -1) {
            _friendRequests[requestIndex]['isProcessing'] = false;
          }
        });
      }
    } catch (e) {
      _showErrorSnackBar('Failed to accept request: $e');
      // Remove loading state
      setState(() {
        final requestIndex = _friendRequests.indexWhere((request) => request['sender']['id'] == senderId);
        if (requestIndex != -1) {
          _friendRequests[requestIndex]['isProcessing'] = false;
        }
      });
    }
  }

  Future<void> _rejectRequest(int senderId) async {
    try {
      // Show loading state for this specific request
      setState(() {
        final requestIndex = _friendRequests.indexWhere((request) => request['sender']['id'] == senderId);
        if (requestIndex != -1) {
          _friendRequests[requestIndex]['isProcessing'] = true;
        }
      });

      final success = await ApiService.rejectFriendRequest(senderId);
      
      if (success) {
        _showSuccessSnackBar('Friend request rejected');
        
        // Remove the request from the list
        setState(() {
          _friendRequests.removeWhere((request) => request['sender']['id'] == senderId);
        });
      } else {
        _showErrorSnackBar('Failed to reject request');
        // Remove loading state
        setState(() {
          final requestIndex = _friendRequests.indexWhere((request) => request['sender']['id'] == senderId);
          if (requestIndex != -1) {
            _friendRequests[requestIndex]['isProcessing'] = false;
          }
        });
      }
    } catch (e) {
      _showErrorSnackBar('Failed to reject request: $e');
      // Remove loading state
      setState(() {
        final requestIndex = _friendRequests.indexWhere((request) => request['sender']['id'] == senderId);
        if (requestIndex != -1) {
          _friendRequests[requestIndex]['isProcessing'] = false;
        }
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF9FBFD),
      appBar: AppBar(
        title: const Text(
          'Friend Requests',
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
        ),
        backgroundColor: const Color(0xFF4997D0),
        iconTheme: const IconThemeData(color: Colors.white),
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loadFriendRequests,
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: _loadFriendRequests,
        child: _isLoading
            ? const Center(child: CircularProgressIndicator())
            : _friendRequests.isEmpty
                ? const Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.person_add_outlined, size: 64, color: Colors.grey),
                        SizedBox(height: 16),
                        Text(
                          'No friend requests',
                          style: TextStyle(fontSize: 16, color: Colors.grey),
                        ),
                        SizedBox(height: 8),
                        Text(
                          'When someone sends you a friend request,\nit will appear here.',
                          textAlign: TextAlign.center,
                          style: TextStyle(fontSize: 12, color: Colors.grey),
                        ),
                      ],
                    ),
                  )
                : ListView.builder(
                    padding: const EdgeInsets.all(16),
                    itemCount: _friendRequests.length,
                    itemBuilder: (context, index) {
                      final request = _friendRequests[index];
                      final sender = request['sender'] ?? {};
                      final isProcessing = request['isProcessing'] == true;
                      
                      return Card(
                        margin: const EdgeInsets.only(bottom: 12),
                        elevation: 2,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Padding(
                          padding: const EdgeInsets.all(16),
                          child: Row(
                            children: [
                              CircleAvatar(
                                radius: 30,
                                backgroundImage: sender['avatar_url']?.isNotEmpty == true
                                    ? CachedNetworkImageProvider(sender['avatar_url'])
                                    : const AssetImage('assets/icons/avatar.png') as ImageProvider,
                              ),
                              const SizedBox(width: 16),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      sender['name'] ?? 'Unknown',
                                      style: const TextStyle(
                                        fontWeight: FontWeight.bold,
                                        fontSize: 16,
                                      ),
                                    ),
                                    const SizedBox(height: 4),
                                    if (sender['email'] != null)
                                      Text(
                                        sender['email'],
                                        style: const TextStyle(color: Colors.grey, fontSize: 12),
                                      ),
                                    if (sender['level'] != null)
                                      Text(
                                        'Level: ${sender['level']}',
                                        style: const TextStyle(color: Colors.grey, fontSize: 12),
                                      ),
                                    if (sender['location'] != null)
                                      Text(
                                        'Location: ${sender['location']}',
                                        style: const TextStyle(color: Colors.grey, fontSize: 12),
                                      ),
                                  ],
                                ),
                              ),
                              Column(
                                children: [
                                  ElevatedButton(
                                    onPressed: isProcessing ? null : () => _acceptRequest(sender['id']),
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor: const Color(0xFF4997D0),
                                      shape: RoundedRectangleBorder(
                                        borderRadius: BorderRadius.circular(20),
                                      ),
                                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                                    ),
                                    child: isProcessing
                                        ? const SizedBox(
                                            width: 12,
                                            height: 12,
                                            child: CircularProgressIndicator(
                                              strokeWidth: 2,
                                              valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                                            ),
                                          )
                                        : const Text(
                                            'Accept',
                                            style: TextStyle(color: Colors.white, fontSize: 12),
                                          ),
                                  ),
                                  const SizedBox(height: 8),
                                  OutlinedButton(
                                    onPressed: isProcessing ? null : () => _rejectRequest(sender['id']),
                                    style: OutlinedButton.styleFrom(
                                      side: const BorderSide(color: Colors.red),
                                      shape: RoundedRectangleBorder(
                                        borderRadius: BorderRadius.circular(20),
                                      ),
                                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                                    ),
                                    child: const Text(
                                      'Reject',
                                      style: TextStyle(color: Colors.red, fontSize: 12),
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                      );
                    },
                  ),
      ),
    );
  }
} 