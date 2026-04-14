import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hive_flutter/hive_flutter.dart';

import '../../../core/network/app_dio.dart';
import '../models/current_user_profile.dart';

class AuthService {
  AuthService(this._dio);

  final Dio _dio;

  /// Login: FastAPI expects form-data (OAuth2PasswordRequestForm)
  Future<Map<String, dynamic>> login(String email, String password) async {
    final response = await _dio.post(
      '/auth/login',
      data: {'username': email, 'password': password},
      options: Options(contentType: Headers.formUrlEncodedContentType),
    );
    final data = response.data;
    if (data is! Map) {
      throw const FormatException('Unexpected login response format');
    }
    return Map<String, dynamic>.from(data as Map);
  }

  /// Register: FastAPI expects JSON body
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
    final data = response.data;
    if (data is! Map) {
      throw const FormatException('Unexpected register response format');
    }
    return Map<String, dynamic>.from(data as Map);
  }

  Future<void> saveTokens(Map<String, dynamic> tokens) async {
    final accessToken = tokens['access_token'];
    final refreshToken = tokens['refresh_token'];
    final tokenType = tokens['token_type'];

    if (accessToken is! String || accessToken.isEmpty) {
      throw const FormatException('Missing access token in response');
    }
    if (refreshToken is! String || refreshToken.isEmpty) {
      throw const FormatException('Missing refresh token in response');
    }

    final box = Hive.box('auth');
    await box.put('access_token', accessToken);
    await box.put('refresh_token', refreshToken);
    if (tokenType is String && tokenType.isNotEmpty) {
      await box.put('token_type', tokenType);
    }
  }

  Future<void> logout() async {
    final box = Hive.box('auth');
    await box.deleteAll(['access_token', 'refresh_token', 'token_type']);
  }

  Future<CurrentUserProfile> getCurrentUserProfile() async {
    final response = await _dio.get('/auth/me/profile');
    final data = response.data;
    if (data is! Map) {
      throw const FormatException('Unexpected profile response format');
    }
    return CurrentUserProfile.fromJson(Map<String, dynamic>.from(data as Map));
  }

  Future<CurrentUserProfile> updateCurrentUserProfile(
    CurrentUserProfileUpdateInput input,
  ) async {
    final response = await _dio.put(
      '/auth/me/profile',
      data: input.toJson(),
      options: Options(contentType: Headers.jsonContentType),
    );
    final data = response.data;
    if (data is! Map) {
      throw const FormatException('Unexpected profile update response format');
    }
    return CurrentUserProfile.fromJson(Map<String, dynamic>.from(data as Map));
  }
}

final authServiceProvider = Provider<AuthService>((ref) {
  return AuthService(ref.watch(dioProvider));
});
