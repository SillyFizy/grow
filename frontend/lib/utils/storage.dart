import 'package:shared_preferences/shared_preferences.dart';

class Storage {
  static const String _userKey = 'user_credentials';
  static const String _accessTokenKey = 'access_token';
  static const String _refreshTokenKey = 'refresh_token';
  static final Storage _instance = Storage._internal();
  static late final SharedPreferences _prefs;

  factory Storage() {
    return _instance;
  }

  Storage._internal();

  static Future<void> init() async {
    _prefs = await SharedPreferences.getInstance();
    // Add demo user if not exists
    if (!_prefs.containsKey(_userKey)) {
      await _prefs.setString(_userKey, 'demo:123');
    }
  }

  static Future<bool> validateUser(String username, String password) async {
    final storedCredentials = _prefs.getString(_userKey);
    if (storedCredentials == null) return false;

    final parts = storedCredentials.split(':');
    if (parts.length != 2) return false;

    final storedUsername = parts[0];
    final storedPassword = parts[1];

    return username == storedUsername && password == storedPassword;
  }

  static Future<void> saveUser(String username, String password) async {
    await _prefs.setString(_userKey, '$username:$password');
  }

  static Future<void> saveTokens(
      String accessToken, String refreshToken) async {
    await _prefs.setString(_accessTokenKey, accessToken);
    await _prefs.setString(_refreshTokenKey, refreshToken);
  }

  static Future<void> saveAccessToken(String accessToken) async {
    await _prefs.setString(_accessTokenKey, accessToken);
  }

  static String? getAccessToken() {
    return _prefs.getString(_accessTokenKey);
  }

  static String? getRefreshToken() {
    return _prefs.getString(_refreshTokenKey);
  }

  static Future<void> clearTokens() async {
    await _prefs.remove(_accessTokenKey);
    await _prefs.remove(_refreshTokenKey);
  }

  static bool isLoggedIn() {
    return _prefs.containsKey(_accessTokenKey);
  }

  static Future<void> logout() async {
    await clearTokens();
  }
}
