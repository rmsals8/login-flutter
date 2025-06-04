// lib/data/models/api_response.dart
class ApiResponse<T> {
  final T? data;
  final String? message;
  final bool success;
  final int? statusCode;

  ApiResponse({
    this.data,
    this.message,
    this.success = false,
    this.statusCode,
  });

  factory ApiResponse.success(T data, {String? message, int? statusCode}) {
    return ApiResponse<T>(
      data: data,
      message: message,
      success: true,
      statusCode: statusCode,
    );
  }

  factory ApiResponse.error(String message, {int? statusCode}) {
    return ApiResponse<T>(
      message: message,
      success: false,
      statusCode: statusCode,
    );
  }

  @override
  String toString() {
    return 'ApiResponse{data: $data, message: $message, success: $success, statusCode: $statusCode}';
  }
}