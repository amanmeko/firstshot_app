import 'package:flutter/material.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'services/api_service.dart';

class UserProfile with ChangeNotifier {
  int? id;
  String customerId = '';
  String name = 'User';
  String email = '';
  String mobileNo = '';
  String duprId = '';
  String level = 'Beginner';
  String location = 'Not set';
  String avatarUrl = '';
  String about = '';
  String dateOfBirth = '';
  double creditBalance = 0.0;
  bool suspend = false;
  DateTime? createdAt;
  DateTime? updatedAt;

  final storage = const FlutterSecureStorage();

  // Load profile data from local storage
  Future<void> loadProfileData() async {
    try {
      id = int.tryParse(await storage.read(key: 'user_id') ?? '');
      customerId = await storage.read(key: 'customer_id') ?? '';
      name = await storage.read(key: 'user_name') ?? 'User';
      email = await storage.read(key: 'email') ?? '';
      mobileNo = await storage.read(key: 'mobile_no') ?? '';
      duprId = await storage.read(key: 'dupr_id') ?? '';
      level = await storage.read(key: 'level') ?? 'Beginner';
      location = await storage.read(key: 'location') ?? 'Not set';
      avatarUrl = await storage.read(key: 'avatar_url') ?? '';
      about = await storage.read(key: 'about') ?? '';
      dateOfBirth = await storage.read(key: 'date_of_birth') ?? '';
      creditBalance = double.tryParse(await storage.read(key: 'credit_balance') ?? '0') ?? 0.0;
      suspend = (await storage.read(key: 'suspend') ?? 'false') == 'true';
      
      final createdAtStr = await storage.read(key: 'created_at');
      if (createdAtStr != null) {
        createdAt = DateTime.tryParse(createdAtStr);
      }
      
      final updatedAtStr = await storage.read(key: 'updated_at');
      if (updatedAtStr != null) {
        updatedAt = DateTime.tryParse(updatedAtStr);
      }

      print('UserProfile Loaded: id=$id, customerId=$customerId, name=$name, email=$email');
      notifyListeners();
    } catch (e) {
      print('Error loading profile data: $e');
      _setDefaults();
      notifyListeners();
    }
  }

  // Sync profile data from API
  Future<bool> syncFromAPI() async {
    try {
      final profileResponse = await ApiService.getUserProfile();
      print('syncFromAPI received: $profileResponse');
      
      if (profileResponse != null) {
        // Extract customer data from API response
        final customerData = profileResponse['data']?['customer'] ?? profileResponse['data'] ?? profileResponse;
        print('Extracted customer data: $customerData');
        
        if (customerData != null) {
          updateFromMap(customerData);
          await saveToStorage();
          return true;
        }
      }
      return false;
    } catch (e) {
      print('Error syncing profile from API: $e');
      return false;
    }
  }

  // Update profile data locally and on server
  Future<bool> updateProfile(Map<String, dynamic> updates) async {
    try {
      // Update on server first
      final success = await ApiService.updateProfile(updates);
      if (success) {
        // Update locally if server update succeeded
        updateFromMap(updates);
        await saveToStorage();
        return true;
      }
      return false;
    } catch (e) {
      print('Error updating profile: $e');
      return false;
    }
  }

  // Update profile data from a map (from API response)
  void updateFromMap(Map<String, dynamic> data) {
    print('UserProfile.updateFromMap called with: $data');
    
    final oldName = name;
    final oldEmail = email;
    final oldLevel = level;
    
    id = data['id'] ?? id;
    customerId = data['customer_id'] ?? customerId;
    name = data['name'] ?? name;
    email = data['email'] ?? email;
    mobileNo = data['mobile_no'] ?? mobileNo;
    duprId = data['dupr_id'] ?? duprId;
    level = data['level'] ?? level;
    location = data['location'] ?? location;
    avatarUrl = data['avatar_url'] ?? avatarUrl;
    about = data['about'] ?? about;
    dateOfBirth = data['date_of_birth'] ?? dateOfBirth;
    creditBalance = double.tryParse(data['credit_balance']?.toString() ?? '0') ?? creditBalance;
    suspend = (data['suspend'] == 1 || data['suspend'] == true) ? true : false;
    
    if (data['created_at'] != null) {
      createdAt = DateTime.tryParse(data['created_at']);
    }
    
    if (data['updated_at'] != null) {
      updatedAt = DateTime.tryParse(data['updated_at']);
    }
    
    print('UserProfile updated: name "$oldName" -> "$name", email "$oldEmail" -> "$email", level "$oldLevel" -> "$level"');
    print('About to call notifyListeners()...');
    notifyListeners();
    print('notifyListeners() called successfully');
  }

  // Save current profile data to local storage
  Future<void> saveToStorage() async {
    try {
      await storage.write(key: 'user_id', value: id?.toString() ?? '');
      await storage.write(key: 'customer_id', value: customerId);
      await storage.write(key: 'user_name', value: name);
      await storage.write(key: 'email', value: email);
      await storage.write(key: 'mobile_no', value: mobileNo);
      await storage.write(key: 'dupr_id', value: duprId);
      await storage.write(key: 'level', value: level);
      await storage.write(key: 'location', value: location);
      await storage.write(key: 'avatar_url', value: avatarUrl);
      await storage.write(key: 'about', value: about);
      await storage.write(key: 'date_of_birth', value: dateOfBirth);
      await storage.write(key: 'credit_balance', value: creditBalance.toString());
      await storage.write(key: 'suspend', value: suspend.toString());
      
      if (createdAt != null) {
        await storage.write(key: 'created_at', value: createdAt!.toIso8601String());
      }
      
      if (updatedAt != null) {
        await storage.write(key: 'updated_at', value: updatedAt!.toIso8601String());
      }

      print('UserProfile saved to storage: name=$name, email=$email');
    } catch (e) {
      print('Error saving profile data: $e');
    }
  }

  // Legacy method for backward compatibility
  Future<void> updateProfileData({
    required String name,
    required String email,
    required String mobileNo,
    required String duprId,
    required String level,
    required String location,
    required String avatarUrl,
    String? memberSince,
    String? about,
  }) async {
    final updates = <String, dynamic>{
      'name': name,
      'email': email,
      'mobile_no': mobileNo,
      'dupr_id': duprId,
      'level': level,
      'location': location,
      'avatar_url': avatarUrl,
      if (about != null) 'about': about,
    };
    
    await updateProfile(updates);
  }

  // Convert to map for API requests
  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'customer_id': customerId,
      'name': name,
      'email': email,
      'mobile_no': mobileNo,
      'dupr_id': duprId,
      'level': level,
      'location': location,
      'avatar_url': avatarUrl,
      'about': about,
      'date_of_birth': dateOfBirth,
      'credit_balance': creditBalance,
      'suspend': suspend,
      'created_at': createdAt?.toIso8601String(),
      'updated_at': updatedAt?.toIso8601String(),
    };
  }

  // Clear all profile data (for logout)
  Future<void> clearProfile() async {
    try {
      await storage.deleteAll();
      _setDefaults();
      notifyListeners();
    } catch (e) {
      print('Error clearing profile: $e');
    }
  }

  // Set default values
  void _setDefaults() {
    id = null;
    customerId = '';
    name = 'User';
    email = '';
    mobileNo = '';
    duprId = '';
    level = 'Beginner';
    location = 'Not set';
    avatarUrl = '';
    about = '';
    dateOfBirth = '';
    creditBalance = 0.0;
    suspend = false;
    createdAt = null;
    updatedAt = null;
  }

  // Getters for formatted data
  String get displayName => name.isNotEmpty ? name : 'User';
  String get displayLevel => level.isNotEmpty ? level : 'Beginner';
  String get displayLocation => location.isNotEmpty ? location : 'Not set';
  String get displayDuprId => duprId.isNotEmpty ? duprId : 'Not set';
  String get displayAbout => about.isNotEmpty ? about : 'No bio available';
  String get formattedCreditBalance => '\$${creditBalance.toStringAsFixed(2)}';
  
  // Member since date
  String get memberSince {
    if (createdAt != null) {
      final now = DateTime.now();
      final difference = now.difference(createdAt!);
      if (difference.inDays < 30) {
        return '${difference.inDays} days ago';
      } else if (difference.inDays < 365) {
        return '${(difference.inDays / 30).floor()} months ago';
      } else {
        return '${(difference.inDays / 365).floor()} years ago';
      }
    }
    return 'Recently';
  }
}