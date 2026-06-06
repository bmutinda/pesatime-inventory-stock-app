import 'package:shared_preferences/shared_preferences.dart';

abstract class SharedPreferencesManager {
  static Future<bool> getBool(String key, [bool? defaultValue]) async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(key) ?? (defaultValue ?? false);
  }

  static Future<int> getInt(String key) async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getInt(key) ?? 0;
  }

  static Future<String> getString(String key) async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(key) ?? '';
  }

  static Future<bool> setString(String key, String value) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(key, value);
    return true;
  }

  static Future<bool> setBool(String key, bool value) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(key, value);
    return true;
  }

  static Future<bool> setInt(String key, int value) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt(key, value);
    return true;
  }
}
