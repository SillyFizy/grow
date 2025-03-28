import 'package:shared_preferences/shared_preferences.dart';

class Storage {
  static const String _userKey = 'user_credentials';
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
    
    final [storedUsername, storedPassword] = storedCredentials.split(':');
    return username == storedUsername && password == storedPassword;
  }
}