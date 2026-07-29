import 'package:dio/dio.dart';
import 'package:inventory_app/data/models/api_response.dart';
import 'package:inventory_app/data/models/user.dart';
import 'package:inventory_app/helpers/api/index.dart';
import 'package:inventory_app/helpers/config/index.dart';
import 'package:inventory_app/helpers/prefs/shared_preferences.dart';

abstract class AuthUtils {
  static const String loggedInTag = "pesatime_stock_app_is_logged_in";
  static const String _userAccessTokenKey = ApiClient.authTokenKey;
  static const String _userRefreshTokenKey = "user_refresh_token";
  static const String _bizAccessTokenKey = ApiClient.bizAccessTokenKey;
  static const String _bizRefreshTokenKey = "biz_refresh_token";
  static const String _validatedDeviceCodeKey = "validated_device_code";
  static const String _businessIdKey = ApiClient.businessIdKey;
  static const String _unitIdKey = ApiClient.unitIdKey;
  static const String _businessNameKey = "business_name";
  static const String _unitNameKey = "unit_name";

  static Future<void> saveSession({
    required String userAccessToken,
    required String userRefreshToken,
    required String bizRefreshToken,
  }) async {
    await SharedPreferencesManager.setString(
      _userAccessTokenKey,
      userAccessToken,
    );
    await SharedPreferencesManager.setString(
      _userRefreshTokenKey,
      userRefreshToken,
    );
    await SharedPreferencesManager.setString(
      _bizRefreshTokenKey,
      bizRefreshToken,
    );
    await SharedPreferencesManager.setBool(loggedInTag, true);
  }

  static Future<void> _saveBizSession({
    required String accessToken,
    required String refreshToken,
  }) async {
    await SharedPreferencesManager.setString(_bizAccessTokenKey, accessToken);
    await SharedPreferencesManager.setString(
      _bizRefreshTokenKey,
      refreshToken,
    );
  }

  static Future<String> getToken() {
    return SharedPreferencesManager.getString(_userAccessTokenKey);
  }

  static Future<bool> isLoggedIn() {
    return SharedPreferencesManager.getBool(loggedInTag, false);
  }

  static Future<String> getValidatedDeviceCode() {
    return SharedPreferencesManager.getString(_validatedDeviceCodeKey);
  }

  static Future<String> getBusinessName() {
    return SharedPreferencesManager.getString(_businessNameKey);
  }

  static Future<String> getUnitName() {
    return SharedPreferencesManager.getString(_unitNameKey);
  }

  static Future<void> logout() async {
    await SharedPreferencesManager.setBool(loggedInTag, false);
    await SharedPreferencesManager.setString(_userAccessTokenKey, "");
    await SharedPreferencesManager.setString(_userRefreshTokenKey, "");
  }

  static Future<void> resetDeviceOnboarding() async {
    await SharedPreferencesManager.setBool(loggedInTag, false);
    await SharedPreferencesManager.setString(_userAccessTokenKey, "");
    await SharedPreferencesManager.setString(_userRefreshTokenKey, "");
    await SharedPreferencesManager.setString(_bizAccessTokenKey, "");
    await SharedPreferencesManager.setString(_bizRefreshTokenKey, "");
    await SharedPreferencesManager.setString(_validatedDeviceCodeKey, "");
    await SharedPreferencesManager.setString(_businessIdKey, "");
    await SharedPreferencesManager.setString(_unitIdKey, "");
    await SharedPreferencesManager.setString(_businessNameKey, "");
    await SharedPreferencesManager.setString(_unitNameKey, "");
  }

  static Future<void> login({
    required String code,
    required String pin,
  }) async {
    try {
      final session = await _loginWithPin(codeHash: code, pin: pin);
      await saveSession(
        userAccessToken: session.userAccessToken,
        userRefreshToken: session.userRefreshToken,
        bizRefreshToken: session.bizRefreshToken,
      );
    } on DioException catch (error) {
      throw AuthException(ApiUtils.readDioError(error));
    }
  }

  static Future<bool> refreshSession() async {
    final loggedIn = await isLoggedIn();
    final userRefreshToken = await SharedPreferencesManager.getString(
      _userRefreshTokenKey,
    );
    final bizRefreshToken = await SharedPreferencesManager.getString(
      _bizRefreshTokenKey,
    );

    if (!loggedIn || userRefreshToken.isEmpty || bizRefreshToken.isEmpty) {
      return false;
    }

    try {
      final response = await ApiClient.post<Map<String, dynamic>>(
        AppConfig.authRefresh,
        data: {
          'biz_refresh_token': bizRefreshToken,
          'user_refresh_token': userRefreshToken,
        },
      );
      final apiResponse = ApiResponse.fromJson(response.data);

      if (apiResponse == null || !apiResponse.success) {
        throw AuthException(apiResponse?.message ?? 'Unable to refresh login.');
      }
      if (apiResponse.data is! Map<String, dynamic>) {
        throw const AuthException('Refresh did not return token data.');
      }

      final data = apiResponse.data as Map<String, dynamic>;
      final biz = data['biz'];
      final user = data['user'];
      final nextBizAccess = ApiUtils.readString(biz, ['access']);
      final nextBizRefresh = ApiUtils.readString(biz, ['refresh']);
      final nextUserAccess = ApiUtils.readString(user, ['access']);
      final nextUserRefresh = ApiUtils.readString(user, ['refresh']);

      if (nextBizAccess.isEmpty || nextBizRefresh.isEmpty) {
        throw const AuthException('Refresh did not return business tokens.');
      }
      if (nextUserAccess.isEmpty || nextUserRefresh.isEmpty) {
        throw const AuthException('Refresh did not return user tokens.');
      }

      await _saveBizSession(
        accessToken: nextBizAccess,
        refreshToken: nextBizRefresh,
      );
      await saveSession(
        userAccessToken: nextUserAccess,
        userRefreshToken: nextUserRefresh,
        bizRefreshToken: nextBizRefresh,
      );
      return true;
    } on DioException catch (error) {
      throw AuthException(ApiUtils.readDioError(error));
    }
  }

  static Future<User> getMe() async {
    try {
      final response = await ApiClient.get<Map<String, dynamic>>(
        AppConfig.profile,
      );
      final apiResponse = ApiResponse.fromJson(response.data);

      if (apiResponse == null || !apiResponse.success) {
        throw AuthException(
          apiResponse?.message.isEmpty ?? true
              ? 'Unable to load profile.'
              : apiResponse!.message,
        );
      }
      if (apiResponse.data is! Map<String, dynamic>) {
        throw const AuthException('Unable to load profile.');
      }

      return User.fromJson(apiResponse.data);
    } on DioException catch (error) {
      throw AuthException(ApiUtils.readDioError(error));
    }
  }

  static Future<String> validateDeviceCode(String deviceCode) async {
    try {
      final response = await ApiClient.post<Map<String, dynamic>>(
        AppConfig.authValidateCode,
        data: {'code': deviceCode},
      );
      final apiResponse = ApiResponse.fromJson(response.data);

      if (apiResponse == null || !apiResponse.success) {
        throw AuthException(apiResponse?.message ?? 'Invalid device code.');
      }
      if (apiResponse.data is! Map<String, dynamic>) {
        throw const AuthException(
          'Device code did not return business and unit details.',
        );
      }

      final data = apiResponse.data as Map<String, dynamic>;
      final validatedCode = ApiUtils.readString(data, ['code']);
      final business = data['business'];
      final unit = data['unit'];
      final businessId = ApiUtils.readString(business, ['_id', 'id']);
      final businessName = ApiUtils.readString(business, ['name']);
      final unitId = ApiUtils.readString(unit, ['_id', 'id']);
      final unitName = ApiUtils.readString(unit, ['name']);

      if (validatedCode.isEmpty) {
        throw const AuthException(
          'Device code validation did not return a code.',
        );
      }
      if (businessId.isEmpty || unitId.isEmpty) {
        throw const AuthException(
          'Device code did not return business and unit details.',
        );
      }

      await SharedPreferencesManager.setString(
        _validatedDeviceCodeKey,
        validatedCode,
      );
      await SharedPreferencesManager.setString(
        _bizAccessTokenKey,
        validatedCode,
      );
      await SharedPreferencesManager.setString(_businessIdKey, businessId);
      await SharedPreferencesManager.setString(_unitIdKey, unitId);
      await SharedPreferencesManager.setString(
        _businessNameKey,
        businessName,
      );
      await SharedPreferencesManager.setString(_unitNameKey, unitName);
      return validatedCode;
    } on DioException catch (error) {
      throw AuthException(ApiUtils.readDioError(error));
    }
  }

  static Future<_LoginSession> _loginWithPin({
    required String codeHash,
    required String pin,
  }) async {
    final response = await ApiClient.post<Map<String, dynamic>>(
      AppConfig.authLogin,
      data: {
        'code': codeHash,
        'pin': pin,
      },
    );
    final apiResponse = ApiResponse.fromJson(response.data);

    if (apiResponse == null || !apiResponse.success) {
      throw AuthException(apiResponse?.message ?? 'Unable to sign in.');
    }

    final token = ApiUtils.readString(apiResponse.data, ['token']);
    final userRefreshToken =
        ApiUtils.readString(apiResponse.data, ['user_refresh_token']);
    final bizRefreshToken =
        ApiUtils.readString(apiResponse.data, ['biz_refresh_token']);

    if (token.isEmpty) {
      throw const AuthException('Login did not return an auth token.');
    }
    if (userRefreshToken.isEmpty || bizRefreshToken.isEmpty) {
      throw const AuthException('Login did not return refresh tokens.');
    }

    return _LoginSession(
      userAccessToken: token,
      userRefreshToken: userRefreshToken,
      bizRefreshToken: bizRefreshToken,
    );
  }
}

class _LoginSession {
  final String userAccessToken;
  final String userRefreshToken;
  final String bizRefreshToken;

  const _LoginSession({
    required this.userAccessToken,
    required this.userRefreshToken,
    required this.bizRefreshToken,
  });
}

class AuthException implements Exception {
  final String message;

  const AuthException(this.message);
}
