import 'package:dio/dio.dart';
import 'package:inventory_app/data/models/api_response.dart';
import 'package:inventory_app/data/models/stock_session.dart';
import 'package:inventory_app/helpers/api/index.dart';

abstract class StockSessionService {
  static Future<List<StockSession>> getActiveSessions() async {
    try {
      final response = await ApiClient.get<Map<String, dynamic>>(
        'stock-sessions/active',
        queryParameters: {'limit': 5},
      );
      final apiResponse = ApiResponse.fromJson(response.data);

      if (apiResponse == null || !apiResponse.success) {
        throw Exception(
          apiResponse?.message.isEmpty ?? true
              ? 'Unable to load active sessions.'
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
