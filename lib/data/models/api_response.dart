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
      data: json["data"],
      success: json["status"] == 1,
      message: json["message"] ?? "",
    );
  }
}
