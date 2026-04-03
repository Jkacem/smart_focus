import 'package:dio/dio.dart';

class AppException implements Exception {
  const AppException(
    this.message, {
    this.statusCode,
    this.cause,
  });

  final String message;
  final int? statusCode;
  final Object? cause;

  @override
  String toString() => message;
}

class AppExceptionMapper {
  const AppExceptionMapper._();

  static AppException from(Object error) {
    if (error is AppException) {
      return error;
    }

    if (error is DioException) {
      final response = error.response;
      final data = response?.data;

      if (data is Map<String, dynamic>) {
        final detail = data['detail'];
        if (detail is String && detail.isNotEmpty) {
          return AppException(
            detail,
            statusCode: response?.statusCode,
            cause: error,
          );
        }
      }

      if (data is String && data.isNotEmpty) {
        return AppException(
          data,
          statusCode: response?.statusCode,
          cause: error,
        );
      }

      return AppException(
        error.message ?? 'Unexpected network error',
        statusCode: response?.statusCode,
        cause: error,
      );
    }

    return AppException(error.toString(), cause: error);
  }

  static String message(Object error) => from(error).message;
}
