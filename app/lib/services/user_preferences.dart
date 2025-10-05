import 'package:shared_preferences/shared_preferences.dart';

class UserPreferences {
  static const String _keyIsLoggedIn = 'isLoggedIn';
  static const String _keyMobileNumber = 'mobileNumber';
  static const String _keyUserId = 'userId';

  /// Save user login session
  static Future<void> saveUserSession({
    required String mobileNumber,
    required String userId,
  }) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_keyIsLoggedIn, true);
    await prefs.setString(_keyMobileNumber, mobileNumber);
    await prefs.setString(_keyUserId, userId);
  }

  /// Check if user is logged in
  static Future<bool> isLoggedIn() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(_keyIsLoggedIn) ?? false;
  }

  /// Get saved mobile number
  static Future<String?> getMobileNumber() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_keyMobileNumber);
  }

  /// Get saved user ID
  static Future<String?> getUserId() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_keyUserId);
  }

  /// Clear user session (logout)
  static Future<void> clearUserSession() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_keyIsLoggedIn);
    await prefs.remove(_keyMobileNumber);
    await prefs.remove(_keyUserId);
  }

  /// Get user data as a map
  static Future<Map<String, String?>> getUserData() async {
    final prefs = await SharedPreferences.getInstance();
    return {
      'mobileNumber': prefs.getString(_keyMobileNumber),
      'userId': prefs.getString(_keyUserId),
    };
  }

  // Language preference key
  static const String _keyLanguage = 'language';

  /// Save language preference
  static Future<void> saveLanguage(String languageCode) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_keyLanguage, languageCode);
  }

  /// Get saved language preference
  static Future<String?> getLanguage() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_keyLanguage);
  }

  // Profile related keys
  static const String _keyProfileName = 'profile_name';
  static const String _keyProfileLocation = 'profile_location';
  static const String _keyProfileLandSize = 'profile_land_size';
  static const String _keyProfileImagePath = 'profile_image_path';

  /// Save profile data locally
  static Future<void> saveProfileData({
    String? name,
    String? location,
    String? landSize,
    String? imagePath,
  }) async {
    final prefs = await SharedPreferences.getInstance();
    if (name != null) await prefs.setString(_keyProfileName, name);
    if (location != null) await prefs.setString(_keyProfileLocation, location);
    if (landSize != null) await prefs.setString(_keyProfileLandSize, landSize);
    if (imagePath != null) await prefs.setString(_keyProfileImagePath, imagePath);
  }

  /// Get profile data
  static Future<Map<String, String?>> getProfileData() async {
    final prefs = await SharedPreferences.getInstance();
    return {
      'name': prefs.getString(_keyProfileName),
      'location': prefs.getString(_keyProfileLocation),
      'landSize': prefs.getString(_keyProfileLandSize),
      'imagePath': prefs.getString(_keyProfileImagePath),
    };
  }
}
