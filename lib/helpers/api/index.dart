import 'package:dio/dio.dart';
import 'package:inventory_app/data/models/api_response.dart';
import 'package:inventory_app/helpers/config/index.dart';
import 'package:inventory_app/helpers/prefs/shared_preferences.dart';
import 'package:inventory_app/services/device/index.dart';

abstract class ApiClient {
  static const String authTokenKey = "auth_token";

  static final Dio _dio = Dio(
    BaseOptions(
      baseUrl: AppConfig.baseUrl,
      connectTimeout: const Duration(seconds: 30),
      receiveTimeout: const Duration(seconds: 30),
      headers: const {
        'Accept': 'application/json',
        'Content-Type': 'application/json',
      },
    ),
  )..interceptors.add(
      InterceptorsWrapper(
        onRequest: (options, handler) async {
          final token = await SharedPreferencesManager.getString(
            authTokenKey,
          );
          final deviceId = await DeviceUtils.getDeviceId();

          if (token.isNotEmpty) {
            options.headers['Authorization'] = 'Bearer $token';
          } else {
            options.headers.remove('Authorization');
          }

          options.queryParameters['device_id'] = deviceId;

          final data = options.data;
          if (data is Map<String, dynamic>) {
            data.putIfAbsent('device_id', () => deviceId);
          }

          return handler.next(options);
        },
      ),
    );

  static Dio get instance => _dio;

  static Future<Response<T>> get<T>(
    String path, {
    Map<String, dynamic>? queryParameters,
    Options? options,
  }) {
    return _dio.get<T>(
      path,
      queryParameters: queryParameters,
      options: options,
    );
  }

  static Future<Response<T>> post<T>(
    String path, {
    Object? data,
    Map<String, dynamic>? queryParameters,
    Options? options,
  }) {
    return _dio.post<T>(
      path,
      data: data,
      queryParameters: queryParameters,
      options: options,
    );
  }

  static Future<Response<T>> put<T>(
    String path, {
    Object? data,
    Map<String, dynamic>? queryParameters,
    Options? options,
  }) {
    return _dio.put<T>(
      path,
      data: data,
      queryParameters: queryParameters,
      options: options,
    );
  }

  static Future<Response<T>> patch<T>(
    String path, {
    Object? data,
    Map<String, dynamic>? queryParameters,
    Options? options,
  }) {
    return _dio.patch<T>(
      path,
      data: data,
      queryParameters: queryParameters,
      options: options,
    );
  }

  static Future<Response<T>> delete<T>(
    String path, {
    Object? data,
    Map<String, dynamic>? queryParameters,
    Options? options,
  }) {
    return _dio.delete<T>(
      path,
      data: data,
      queryParameters: queryParameters,
      options: options,
    );
  }
}

abstract class ApiUtils {
  static String readDioError(DioException error) {
    final data = error.response?.data;
    if (data is Map<String, dynamic>) {
      final apiResponse = ApiResponse.fromJson(data);
      if (apiResponse != null && apiResponse.message.isNotEmpty) {
        return apiResponse.message;
      }
    }

    return 'Unable to process request. Please try again.';
  }

  static String readString(
    dynamic data,
    List<String> keys, {
    String defaultValue = '',
  }) {
    if (data is! Map<String, dynamic>) return defaultValue;

    for (final key in keys) {
      final value = data[key];
      if (value is String && value.isNotEmpty) {
        return value;
      }
      if (value is num || value is bool) {
        return value.toString();
      }
    }

    return defaultValue;
  }

  static int readInt(dynamic data, List<String> keys, {int defaultValue = 0}) {
    if (data is! Map<String, dynamic>) return defaultValue;

    for (final key in keys) {
      final value = data[key];
      if (value is int) return value;
      if (value is num) return value.toInt();
      if (value is String) {
        return int.tryParse(value) ?? defaultValue;
      }
    }

    return defaultValue;
  }

  static double readDouble(
    dynamic data,
    List<String> keys, {
    double defaultValue = 0,
  }) {
    if (data is! Map<String, dynamic>) return defaultValue;

    for (final key in keys) {
      final value = data[key];
      if (value is num) return value.toDouble();
      if (value is String) {
        return double.tryParse(value) ?? defaultValue;
      }
    }

    return defaultValue;
  }

  static bool readBool(
    dynamic data,
    String key, {
    bool defaultValue = false,
  }) {
    if (data is! Map<String, dynamic>) return defaultValue;

    final value = data[key];
    if (value is bool) return value;
    if (value is num) return value == 1;
    if (value is String) return value == '1' || value.toLowerCase() == 'true';

    return defaultValue;
  }
}
