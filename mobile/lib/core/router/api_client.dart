import 'package:dio/dio.dart';
import 'package:hive_flutter/hive_flutter.dart';

class ApiClient {
  // adb reverse tcp:8000 tcp:8000 tunnels emulator localhost → host PC port 8000
  static const String _baseUrl = 'http://localhost:8000'; // works via: adb reverse tcp:8000 tcp:8000

  static Dio createDio() {
    final dio = Dio(
      BaseOptions(
        baseUrl: _baseUrl,
        connectTimeout: const Duration(seconds: 10),
        receiveTimeout: const Duration(seconds: 120), // RAG generation can take > 30s
        contentType: Headers.jsonContentType,
      ),
    );

    // Interceptor: auto-attach access token to every request
    dio.interceptors.add(
      InterceptorsWrapper(
        onRequest: (options, handler) {
          final box = Hive.box('auth');
          final token = box.get('access_token');
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
