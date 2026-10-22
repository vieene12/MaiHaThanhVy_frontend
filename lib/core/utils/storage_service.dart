import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import '../../models/user_model.dart';

class StorageService {
  static const String _keyToken = 'auth_token';
  static const String _keyUser = 'auth_user';
  static const String _keyBaseUrl = 'api_base_url';
  static const String _keyIsDarkMode = 'is_dark_mode';

  static SharedPreferences? _prefs;

  static Future<void> init() async {
    _prefs = await SharedPreferences.getInstance();
  }

  static SharedPreferences get prefs {
    if (_prefs == null) {
      throw StateError('StorageService must be initialized before use.');
    }
    return _prefs!;
  }

  // Token
  static Future<void> saveToken(String token) async {
    await prefs.setString(_keyToken, token);
  }

  static String? getToken() {
    return prefs.getString(_keyToken);
  }

  static Future<void> removeToken() async {
    await prefs.remove(_keyToken);
  }

  // User info
  static Future<void> saveUser(UserInfoDto user) async {
    await prefs.setString(_keyUser, jsonEncode(user.toJson()));
  }

  static UserInfoDto? getUser() {
    final str = prefs.getString(_keyUser);
    if (str == null || str.isEmpty) return null;
    try {
      final map = jsonDecode(str) as Map<String, dynamic>;
      return UserInfoDto.fromJson(map);
    } catch (_) {
      return null;
    }
  }

  static Future<void> removeUser() async {
    await prefs.remove(_keyUser);
  }

  // Clear all auth
  static Future<void> clearAuth() async {
    await removeToken();
    await removeUser();
  }

  // Custom Base URL
  static Future<void> saveBaseUrl(String url) async {
    await prefs.setString(_keyBaseUrl, url);
  }

  static String? getBaseUrl() {
    return prefs.getString(_keyBaseUrl);
  }

  // Theme
  static Future<void> setDarkMode(bool isDark) async {
    await prefs.setBool(_keyIsDarkMode, isDark);
  }

  static bool isDarkMode() {
    return prefs.getBool(_keyIsDarkMode) ?? false;
  }
}
