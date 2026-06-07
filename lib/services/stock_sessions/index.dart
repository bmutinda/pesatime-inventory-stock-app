import 'package:dio/dio.dart';
import 'package:inventory_app/data/models/api_response.dart';
import 'package:inventory_app/data/models/stock_session.dart';
import 'package:inventory_app/data/models/stock_session_item.dart';
import 'package:inventory_app/helpers/api/index.dart';

abstract class StockSessionService {
  static Future<List<StockSession>> getActiveSessions() async {
    return _getSessions(
      path: 'stock-sessions/active',
      limit: 5,
      fallbackMessage: 'Unable to load active sessions.',
    );
  }

  static Future<List<StockSession>> getHistorySessions() async {
    return _getSessions(
      path: 'stock-sessions',
      limit: 50,
      fallbackMessage: 'Unable to load stock session history.',
    );
  }

  static Future<StockSession> getSession(String sessionId) async {
    try {
      final response = await ApiClient.get<Map<String, dynamic>>(
        'stock-sessions/$sessionId',
      );
      final apiResponse = ApiResponse.fromJson(response.data);

      if (apiResponse == null || !apiResponse.success) {
        throw Exception(
          apiResponse?.message.isEmpty ?? true
              ? 'Unable to load stock session.'
              : apiResponse!.message,
        );
      }

      return StockSession.fromJson(apiResponse.data);
    } on DioException catch (error) {
      throw Exception(ApiUtils.readDioError(error));
    }
  }

  static Future<List<StockSessionItem>> getSessionItems(
    String sessionId,
  ) async {
    try {
      final response = await ApiClient.get<Map<String, dynamic>>(
        'stock-sessions/$sessionId/items',
      );
      final apiResponse = ApiResponse.fromJson(response.data);

      if (apiResponse == null || !apiResponse.success) {
        throw Exception(
          apiResponse?.message.isEmpty ?? true
              ? 'Unable to load stock session items.'
              : apiResponse!.message,
        );
      }

      return (apiResponse.data as List<dynamic>)
          .whereType<Map<String, dynamic>>()
          .map(StockSessionItem.fromJson)
          .toList();
    } on DioException catch (error) {
      throw Exception(ApiUtils.readDioError(error));
    }
  }

  static Future<void> submitOpeningQty({
    required String sessionId,
    required String lineId,
    required double openingQty,
  }) async {
    try {
      final response = await ApiClient.put<Map<String, dynamic>>(
        'stock-sessions/$sessionId/items/$lineId/opening',
        data: {'opening_qty': openingQty},
      );
      final apiResponse = ApiResponse.fromJson(response.data);

      if (apiResponse == null || !apiResponse.success) {
        throw Exception(
          apiResponse?.message.isEmpty ?? true
              ? 'Unable to save opening quantity.'
              : apiResponse!.message,
        );
      }
    } on DioException catch (error) {
      throw Exception(ApiUtils.readDioError(error));
    }
  }

  static Future<void> submitClosingQty({
    required String sessionId,
    required String lineId,
    required double closingQty,
    String? varianceReason,
  }) async {
    try {
      final response = await ApiClient.put<Map<String, dynamic>>(
        'stock-sessions/$sessionId/items/$lineId/closing',
        data: {
          'closing_qty': closingQty,
          if (varianceReason != null && varianceReason.isNotEmpty)
            'variance_reason': varianceReason,
        },
      );
      final apiResponse = ApiResponse.fromJson(response.data);

      if (apiResponse == null || !apiResponse.success) {
        throw Exception(
          apiResponse?.message.isEmpty ?? true
              ? 'Unable to save closing quantity.'
              : apiResponse!.message,
        );
      }
    } on DioException catch (error) {
      throw Exception(ApiUtils.readDioError(error));
    }
  }

  static Future<List<StockSession>> _getSessions({
    required String path,
    required int limit,
    required String fallbackMessage,
  }) async {
    try {
      final response = await ApiClient.get<Map<String, dynamic>>(
        path,
        queryParameters: {'limit': limit},
      );
      final apiResponse = ApiResponse.fromJson(response.data);

      if (apiResponse == null || !apiResponse.success) {
        throw Exception(
          apiResponse?.message.isEmpty ?? true
              ? fallbackMessage
              : apiResponse!.message,
        );
      }

      return (apiResponse.data as List<dynamic>)
          .whereType<Map<String, dynamic>>()
          .map(StockSession.fromJson)
          .toList();
    } on DioException catch (error) {
      throw Exception(ApiUtils.readDioError(error));
    }
  }
}
