class ApiResponse {
  final Map<String, dynamic>? data;
  final bool success;
  final String message;

  const ApiResponse({
    required this.data,
    required this.success,
    required this.message,
  });

  static ApiResponse? fromJson(Map<String, dynamic>? json) {
    if (json == null) return null;

    return ApiResponse(
      data: json["data"] is Map<String, dynamic> ? json["data"] : null,
      success: _readSuccess(json["status"]),
      message: json["message"] ?? "",
    );
  }

  static bool _readSuccess(dynamic status) {
    if (status is bool) return status;
    if (status is num) return status == 1;
    if (status is String) {
      return status == '1' || status.toLowerCase() == 'true';
    }

    return false;
  }
}
