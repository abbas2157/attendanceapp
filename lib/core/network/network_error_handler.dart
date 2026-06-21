// lib/core/network/network_error_handler.dart
import 'package:dio/dio.dart';
import 'api_result.dart';

class NetworkErrorHandler {
  static ApiError<T> handle<T>(dynamic error) {
    if (error is DioException) {
      return switch (error.type) {
        DioExceptionType.connectionTimeout ||
        DioExceptionType.sendTimeout ||
        DioExceptionType.receiveTimeout =>
          ApiError('Connection timed out. Check your internet.'),
        DioExceptionType.connectionError =>
          ApiError('Unable to connect to server. Check your network.'),
        DioExceptionType.badResponse => _handleStatusCode(error),
        DioExceptionType.cancel => ApiError('Request cancelled.'),
        _ => ApiError('An unexpected error occurred.'),
      };
    }
    return ApiError(error.toString());
  }

  static ApiError<T> _handleStatusCode<T>(DioException error) {
    final statusCode = error.response?.statusCode;
    final data = error.response?.data;

    String message = 'Something went wrong.';
    if (data is Map) {
      message = data['message'] as String? ?? message;
    }

    return ApiError(
      message,
      statusCode: statusCode,
    );
  }
}
