import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hive_flutter/hive_flutter.dart';

final authBoxProvider = Provider<Box<dynamic>>((ref) {
  return Hive.box('auth');
});

final apiBaseUrlProvider = Provider<String>((ref) {
  return const String.fromEnvironment(
    'API_BASE_URL',
    defaultValue: 'http://localhost:8000',
  );
});

class ApiClient {
  ApiClient({
    required String baseUrl,
    required Box<dynamic> authBox,
  }) : _baseUrl = baseUrl,
       _authBox = authBox;

  final String _baseUrl;
  final Box<dynamic> _authBox;

  Dio createDio() {
    final dio = Dio(
      BaseOptions(
        baseUrl: _baseUrl,
        connectTimeout: const Duration(seconds: 10),
        receiveTimeout: const Duration(seconds: 120),
        contentType: Headers.jsonContentType,
      ),
    );

    dio.interceptors.add(
      InterceptorsWrapper(
        onRequest: (options, handler) {
          final token = _authBox.get('access_token');
          if (token != null) {
            options.headers['Authorization'] = 'Bearer $token';
          }
          handler.next(options);
        },
      ),
    );

    return dio;
  }
}

final apiClientProvider = Provider<ApiClient>((ref) {
  return ApiClient(
    baseUrl: ref.watch(apiBaseUrlProvider),
    authBox: ref.watch(authBoxProvider),
  );
});

final dioProvider = Provider<Dio>((ref) {
  return ref.watch(apiClientProvider).createDio();
});
