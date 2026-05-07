import 'dart:convert';

import 'package:flutter_riverpod/legacy.dart';
import 'package:google_sign_in/google_sign_in.dart';

import '../../../core/network/app_exception.dart';
import '../../../core/storage/token_storage.dart';
import '../data/auth_repository.dart';

enum AuthStatus { idle, loading, success, error }

class AuthState {
  final AuthStatus status;
  final String? errorMessage;
  final bool isAuthenticated;
  final bool isInitializing;

  const AuthState({
    this.status = AuthStatus.idle,
    this.errorMessage,
    this.isAuthenticated = false,
    this.isInitializing = false,
  });

  AuthState copyWith({
    AuthStatus? status,
    String? errorMessage,
    bool? isAuthenticated,
    bool? isInitializing,
  }) {
    return AuthState(
      status: status ?? this.status,
      errorMessage: errorMessage,
      isAuthenticated: isAuthenticated ?? this.isAuthenticated,
      isInitializing: isInitializing ?? this.isInitializing,
    );
  }
}

class AuthNotifier extends StateNotifier<AuthState> {
  AuthNotifier(this._repository, this._tokenStorage)
      : super(const AuthState(isInitializing: true)) {
    _checkInitialAuth();
  }

  final AuthRepository _repository;
  final TokenStorage _tokenStorage;
  static const _googleWebClientId = String.fromEnvironment('GOOGLE_WEB_CLIENT_ID');
  final GoogleSignIn _googleSignIn = GoogleSignIn(
    scopes: const ['email', 'profile'],
    serverClientId: _googleWebClientId.isEmpty ? null : _googleWebClientId,
  );

  Future<void> _checkInitialAuth() async {
    final token = await _tokenStorage.getAccessToken();
    final valid = token != null && token.isNotEmpty && !_isTokenExpired(token);
    if (!valid) await _tokenStorage.clearTokens();
    state = AuthState(isAuthenticated: valid);
  }

  bool _isTokenExpired(String token) {
    try {
      final parts = token.split('.');
      if (parts.length != 3) return true;
      final payload = base64Url.normalize(parts[1]);
      final decoded = utf8.decode(base64Url.decode(payload));
      final data = json.decode(decoded) as Map<String, dynamic>;
      final exp = data['exp'];
      if (exp == null) return false;
      final expiry = DateTime.fromMillisecondsSinceEpoch((exp as int) * 1000);
      return DateTime.now().isAfter(expiry);
    } catch (_) {
      return true;
    }
  }

  Future<bool> login(String email, String password) async {
    state = state.copyWith(status: AuthStatus.loading);
    try {
      final tokens = await _repository.login(email, password);
      await _repository.saveTokens(tokens);
      state = state.copyWith(status: AuthStatus.success, isAuthenticated: true);
      return true;
    } catch (error) {
      state = state.copyWith(
        status: AuthStatus.error,
        errorMessage: AppExceptionMapper.message(error),
        isAuthenticated: false,
      );
      return false;
    }
  }

  Future<bool> register(
    String fullName,
    String email,
    String password,
    String role,
  ) async {
    state = state.copyWith(status: AuthStatus.loading);
    try {
      final tokens = await _repository.register(
        fullName: fullName,
        email: email,
        password: password,
        role: role,
      );
      await _repository.saveTokens(tokens);
      state = state.copyWith(status: AuthStatus.success, isAuthenticated: true);
      return true;
    } catch (error) {
      state = state.copyWith(
        status: AuthStatus.error,
        errorMessage: AppExceptionMapper.message(error),
        isAuthenticated: false,
      );
      return false;
    }
  }

  Future<bool> loginWithGoogle({String role = 'student'}) async {
    state = state.copyWith(status: AuthStatus.loading, errorMessage: null);
    try {
      final account = await _googleSignIn.signIn();
      if (account == null) {
        state = state.copyWith(status: AuthStatus.idle);
        return false;
      }

      final authentication = await account.authentication;
      final idToken = authentication.idToken;
      if (idToken == null || idToken.isEmpty) {
        state = state.copyWith(
          status: AuthStatus.error,
          errorMessage:
              'Google id token introuvable. Configure GOOGLE_WEB_CLIENT_ID si necessaire.',
        );
        return false;
      }

      final tokens = await _repository.loginWithGoogle(idToken: idToken, role: role);
      await _repository.saveTokens(tokens);
      state = state.copyWith(status: AuthStatus.success, isAuthenticated: true);
      return true;
    } catch (error) {
      state = state.copyWith(
        status: AuthStatus.error,
        errorMessage: AppExceptionMapper.message(error),
      );
      return false;
    }
  }

  Future<void> logout() async {
    try {
      await _googleSignIn.signOut();
    } catch (_) {}
    await _repository.logout();
    state = const AuthState(status: AuthStatus.idle, isAuthenticated: false);
  }
}

final authProvider = StateNotifierProvider<AuthNotifier, AuthState>((ref) {
  return AuthNotifier(
    ref.watch(authRepositoryProvider),
    ref.watch(tokenStorageProvider),
  );
});
