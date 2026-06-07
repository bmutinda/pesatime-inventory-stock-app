import 'package:dio/dio.dart';
import 'package:inventory_app/data/models/api_response.dart';
import 'package:inventory_app/data/models/user.dart';
import 'package:inventory_app/helpers/api/index.dart';
import 'package:inventory_app/helpers/prefs/shared_preferences.dart';

abstract class AuthUtils {
  static const String LOGGED_IN_TAG = "pesatime_stock_app_is_logged_in";

  // -----------------------------
  // SAVE DATA TO LOCAL DEVICE
  // -----------------------------

  static Future saveToken(String token) async {
    await SharedPreferencesManager.setString(ApiClient.authTokenKey, token);
  }

  static Future saveSession(String token) async {
    await SharedPreferencesManager.setString(ApiClient.authTokenKey, token);
    await SharedPreferencesManager.setBool(LOGGED_IN_TAG, true);
  }

  static Future<String> getToken() async {
    return SharedPreferencesManager.getString(ApiClient.authTokenKey);
  }

  static Future<bool> isLoggedIn() async {
    return SharedPreferencesManager.getBool(LOGGED_IN_TAG, false);
  }

  static Future logout() async {
    await SharedPreferencesManager.setBool(LOGGED_IN_TAG, false);
    await SharedPreferencesManager.setString(ApiClient.authTokenKey, "");
  }

  static Future<void> login({
    required String staffCode,
    required String pin,
  }) async {
    try {
      final codeHash = await _validateStaffCode(staffCode);
      final token = await _loginWithPin(codeHash: codeHash, pin: pin);
      await saveSession(token);
    } on DioException catch (error) {
      throw AuthException(ApiUtils.readDioError(error));
    }
  }

  static Future<User> getMe() async {
    try {
      final response = await ApiClient.get<Map<String, dynamic>>('me');
      final apiResponse = ApiResponse.fromJson(response.data);

      if (apiResponse == null || !apiResponse.success) {
        throw Exception(
          apiResponse?.message.isEmpty ?? true
              ? 'Unable to load profile.'
              : apiResponse!.message,
        );
      }

      if (apiResponse.data is! Map<String, dynamic>) {
        throw Exception('Unable to load profile.');
      }

      return User.fromJson(apiResponse.data);
    } on DioException catch (error) {
      throw Exception(ApiUtils.readDioError(error));
    }
  }

  static Future<String> _validateStaffCode(String staffCode) async {
    final response = await ApiClient.post<Map<String, dynamic>>(
      'auth/validate-code',
      data: {'code': staffCode},
    );
    final apiResponse = ApiResponse.fromJson(response.data);

    if (apiResponse == null || !apiResponse.success) {
      throw AuthException(apiResponse?.message ?? 'Invalid staff code.');
    }

    final codeHash = ApiUtils.readString(apiResponse.data, [
      'code_hash',
      'codeHash',
      'hash',
      'code',
    ]);

    if (codeHash.isEmpty) {
      throw const AuthException('Staff code validation did not return a code.');
    }

    return codeHash;
  }

  static Future<String> _loginWithPin({
    required String codeHash,
    required String pin,
  }) async {
    final response = await ApiClient.post<Map<String, dynamic>>(
      'auth/login',
      data: {
        'code': codeHash,
        'pin': pin,
      },
    );
    final apiResponse = ApiResponse.fromJson(response.data);

    if (apiResponse == null || !apiResponse.success) {
      throw AuthException(apiResponse?.message ?? 'Unable to sign in.');
    }

    final token = ApiUtils.readString(apiResponse.data, [
      'token',
      'access_token',
      'accessToken',
    ]);

    if (token.isEmpty) {
      throw const AuthException('Login did not return an auth token.');
    }

    return token;
  }
}

class AuthException implements Exception {
  final String message;

  const AuthException(this.message);
}
