import 'package:inventory_app/helpers/prefs/shared_preferences.dart';

abstract class AuthUtils {
  static const String LOGGED_IN_TAG = "pesatime_stock_app_is_logged_in";

  // -----------------------------
  // SAVE DATA TO LOCAL DEVICE
  // -----------------------------

  static Future saveToken(String token) async {
    await SharedPreferencesManager.setString("auth_token", token);
  }

  static Future<String> getToken() async {
    return SharedPreferencesManager.getString("auth_token");
  }

  static Future<bool> isLoggedIn() async {
    return SharedPreferencesManager.getBool(LOGGED_IN_TAG, false);
  }

  static Future logout() async {
    await SharedPreferencesManager.setBool(LOGGED_IN_TAG, false);
    await SharedPreferencesManager.setString("auth_token", "");
  }
}
