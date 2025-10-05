import 'package:dio/dio.dart';

class ApiException implements Exception {
  final String message;
  final int? statusCode;
  final String? code;

  ApiException({
    required this.message,
    this.statusCode,
    this.code,
  });

  factory ApiException.fromDioError(DioException error) {
    switch (error.type) {
      case DioExceptionType.connectionTimeout:
      case DioExceptionType.sendTimeout:
      case DioExceptionType.receiveTimeout:
        return ApiException(
          message: 'Connection timeout. Please check your internet connection.',
          statusCode: error.response?.statusCode,
        );

      case DioExceptionType.badResponse:
        final response = error.response;
        final data = response?.data;

        if (data != null && data is Map<String, dynamic>) {
          return ApiException(
            message: data['message'] ?? 'An error occurred',
            statusCode: response?.statusCode,
            code: data['errors'] != null ? 'validation_error' : null,
          );
        }

        return ApiException(
          message: 'Server error occurred',
          statusCode: response?.statusCode,
        );

      case DioExceptionType.cancel:
        return ApiException(
          message: 'Request cancelled',
          statusCode: error.response?.statusCode,
        );

      case DioExceptionType.unknown:
      default:
        return ApiException(
          message: 'Network error. Please check your connection.',
          statusCode: error.response?.statusCode,
        );
    }
  }

  @override
  String toString() => message;
}