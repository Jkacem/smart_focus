import 'package:dio/dio.dart';
import 'package:hive_flutter/hive_flutter.dart';
import '../../../core/router/api_client.dart';

class AuthService {
  final Dio _dio = ApiClient.createDio();

  /// Login — FastAPI expects form-data (OAuth2PasswordRequestForm)
  Future<Map<String, dynamic>> login(String email, String password) async {
    final response = await _dio.post(
      '/auth/login',
      data: {'username': email, 'password': password},
      options: Options(contentType: Headers.formUrlEncodedContentType),
    );
    return response.data;
  }

  /// Register — FastAPI expects JSON body
  Future<Map<String, dynamic>> register({
    required String fullName,
    required String email,
    required String password,
    required String role,
  }) async {
    final response = await _dio.post(
      '/auth/register',
      data: {
        'full_name': fullName,
        'email': email,
        'password': password,
        'role': role,
      },
      options: Options(contentType: Headers.jsonContentType),
    );
    return response.data;
  }

  /// Save tokens to Hive local storage
  Future<void> saveTokens(Map<String, dynamic> tokens) async {
    final box = Hive.box('auth');
    await box.put('access_token', tokens['access_token']);
    await box.put('refresh_token', tokens['refresh_token']);
  }

  /// Clear tokens on logout
  Future<void> logout() async {
    final box = Hive.box('auth');
    await box.deleteAll(['access_token', 'refresh_token']);
  }
}
