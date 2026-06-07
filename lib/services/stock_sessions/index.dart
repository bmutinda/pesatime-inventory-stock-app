import 'package:dio/dio.dart';
import 'package:inventory_app/data/models/api_response.dart';
import 'package:inventory_app/data/models/stock_session.dart';
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
