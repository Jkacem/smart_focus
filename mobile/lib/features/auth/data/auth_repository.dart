import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../models/current_user_profile.dart';
import '../services/auth_service.dart';

abstract class AuthRepository {
  Future<Map<String, dynamic>> login(String email, String password);
  Future<Map<String, dynamic>> register({
    required String fullName,
    required String email,
    required String password,
    required String role,
  });
  Future<Map<String, dynamic>> loginWithGoogle({
    required String idToken,
    String? role,
  });
  Future<CurrentUserProfile> getCurrentUserProfile();
  Future<CurrentUserProfile> updateCurrentUserProfile(
    CurrentUserProfileUpdateInput input,
  );
  Future<void> saveTokens(Map<String, dynamic> tokens);
  Future<void> logout();
}

class AuthRepositoryImpl implements AuthRepository {
  AuthRepositoryImpl(this._service);

  final AuthService _service;

  @override
  Future<Map<String, dynamic>> login(String email, String password) {
    return _service.login(email, password);
  }

  @override
  Future<Map<String, dynamic>> register({
    required String fullName,
    required String email,
    required String password,
    required String role,
  }) {
    return _service.register(
      fullName: fullName,
      email: email,
      password: password,
      role: role,
    );
  }

  @override
  Future<Map<String, dynamic>> loginWithGoogle({
    required String idToken,
    String? role,
  }) {
    return _service.loginWithGoogle(idToken: idToken, role: role);
  }

  @override
  Future<CurrentUserProfile> getCurrentUserProfile() {
    return _service.getCurrentUserProfile();
  }

  @override
  Future<CurrentUserProfile> updateCurrentUserProfile(
    CurrentUserProfileUpdateInput input,
  ) {
    return _service.updateCurrentUserProfile(input);
  }

  @override
  Future<void> saveTokens(Map<String, dynamic> tokens) {
    return _service.saveTokens(tokens);
  }

  @override
  Future<void> logout() {
    return _service.logout();
  }
}

final authRepositoryProvider = Provider<AuthRepository>((ref) {
  return AuthRepositoryImpl(ref.watch(authServiceProvider));
});
