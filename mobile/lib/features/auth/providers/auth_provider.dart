import 'package:flutter_riverpod/legacy.dart';

import '../../../core/network/app_exception.dart';
import '../data/auth_repository.dart';

enum AuthStatus { idle, loading, success, error }

class AuthState {
  final AuthStatus status;
  final String? errorMessage;

  const AuthState({this.status = AuthStatus.idle, this.errorMessage});

  AuthState copyWith({AuthStatus? status, String? errorMessage}) {
    return AuthState(
      status: status ?? this.status,
      errorMessage: errorMessage,
    );
  }
}

class AuthNotifier extends StateNotifier<AuthState> {
  AuthNotifier(this._repository) : super(const AuthState());

  final AuthRepository _repository;

  Future<bool> login(String email, String password) async {
    state = state.copyWith(status: AuthStatus.loading);
    try {
      final tokens = await _repository.login(email, password);
      await _repository.saveTokens(tokens);
      state = state.copyWith(status: AuthStatus.success);
      return true;
    } catch (error) {
      state = state.copyWith(
        status: AuthStatus.error,
        errorMessage: AppExceptionMapper.message(error),
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
      state = state.copyWith(status: AuthStatus.success);
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
    await _repository.logout();
    state = const AuthState(status: AuthStatus.idle);
  }
}

final authProvider = StateNotifierProvider<AuthNotifier, AuthState>((ref) {
  return AuthNotifier(ref.watch(authRepositoryProvider));
});
