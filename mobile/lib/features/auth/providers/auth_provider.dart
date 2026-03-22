import 'package:dio/dio.dart';
import 'package:flutter_riverpod/legacy.dart';
import '../services/auth_service.dart';

// State
enum AuthStatus { idle, loading, success, error }

class AuthState {
  final AuthStatus status;
  final String? errorMessage;
  const AuthState({this.status = AuthStatus.idle, this.errorMessage});

  AuthState copyWith({AuthStatus? status, String? errorMessage}) =>
      AuthState(status: status ?? this.status, errorMessage: errorMessage);
}

// Notifier
class AuthNotifier extends StateNotifier<AuthState> {
  final AuthService _service = AuthService();
  AuthNotifier() : super(const AuthState());

  Future<void> login(String email, String password) async {
    state = state.copyWith(status: AuthStatus.loading);
    try {
      final tokens = await _service.login(email, password);
      await _service.saveTokens(tokens);
      state = state.copyWith(status: AuthStatus.success);
    } catch (e) {
      final msg = _extractError(e);
      state = state.copyWith(status: AuthStatus.error, errorMessage: msg);
    }
  }

  Future<void> register(
    String fullName,
    String email,
    String password,
    String role,
  ) async {
    state = state.copyWith(status: AuthStatus.loading);
    try {
      final tokens = await _service.register(
        fullName: fullName,
        email: email,
        password: password,
        role: role,
      );
      await _service.saveTokens(tokens);
      state = state.copyWith(status: AuthStatus.success);
    } catch (e) {
      final msg = _extractError(e);
      state = state.copyWith(status: AuthStatus.error, errorMessage: msg);
    }
  }

  Future<void> logout() async {
    await _service.logout();
    state = const AuthState(status: AuthStatus.idle);
  }

  String _extractError(dynamic e) {
    if (e is DioException && e.response?.data != null) {
      return e.response!.data['detail'] ?? 'Unknown error';
    }
    return e.toString();
  }
}

final authProvider = StateNotifierProvider<AuthNotifier, AuthState>(
  (_) => AuthNotifier(),
);
