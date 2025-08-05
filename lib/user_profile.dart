import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:intl/intl.dart';

class UserProfile with ChangeNotifier {
  String _name = '';
  String _email = '';
  String _mobileNo = '';
  String _duprId = '';
  String _level = 'N/A';
  String _location = 'N/A';
  String _avatarUrl = '';
  String _memberSince = '';

  String get name => _name;
  String get email => _email;
  String get mobileNo => _mobileNo;
  String get duprId => _duprId;
  String get level => _level;
  String get location => _location;
  String get avatarUrl => _avatarUrl;
  String get memberSince => _memberSince;

  Future<void> loadProfileData() async {
    final prefs = await SharedPreferences.getInstance();
    _name = prefs.getString('user_name') ?? '';
    _email = prefs.getString('email') ?? '';
    _mobileNo = prefs.getString('mobile_no') ?? '';
    _duprId = prefs.getString('dupr_id') ?? '';
    _level = prefs.getString('pickleball_level') ?? 'N/A';
    _location = prefs.getString('location') ?? 'N/A';
    _avatarUrl = prefs.getString('avatar_url') ?? '';
    _memberSince = prefs.getString('member_since') ?? '';
    print('UserProfile Loaded: name="$_name", email="$_email", mobile="$_mobileNo", duprId="$_duprId"');
    notifyListeners();
  }

  Future<void> updateProfileData({
    required String name,
    required String email,
    required String mobileNo,
    required String duprId,
    required String level,
    required String location,
    required String avatarUrl,
    required String memberSince,
  }) async {
    final prefs = await SharedPreferences.getInstance();
    _name = name;
    _email = email;
    _mobileNo = mobileNo;
    _duprId = duprId;
    _level = level;
    _location = location;
    _avatarUrl = avatarUrl;
    _memberSince = memberSince;

    await prefs.setString('user_name', name);
    await prefs.setString('email', email);
    await prefs.setString('mobile_no', mobileNo);
    await prefs.setString('dupr_id', duprId);
    await prefs.setString('pickleball_level', level);
    await prefs.setString('location', location);
    await prefs.setString('avatar_url', avatarUrl);
    await prefs.setString('member_since', memberSince);
    print('UserProfile Updated: name="$_name", email="$_email", mobile="$_mobileNo", duprId="$_duprId"');
    notifyListeners();
  }
}