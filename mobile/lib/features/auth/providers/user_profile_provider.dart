import 'package:flutter_riverpod/legacy.dart';

import '../../../core/network/app_exception.dart';
import '../data/auth_repository.dart';
import '../models/current_user_profile.dart';

class UserProfileState {
  final CurrentUserProfile? profile;
  final bool isLoading;
  final bool isSaving;
  final String? errorMessage;

  const UserProfileState({
    this.profile,
    this.isLoading = false,
    this.isSaving = false,
    this.errorMessage,
  });

  UserProfileState copyWith({
    CurrentUserProfile? profile,
    bool? isLoading,
    bool? isSaving,
    String? errorMessage,
    bool clearError = false,
  }) {
    return UserProfileState(
      profile: profile ?? this.profile,
      isLoading: isLoading ?? this.isLoading,
      isSaving: isSaving ?? this.isSaving,
      errorMessage: clearError ? null : (errorMessage ?? this.errorMessage),
    );
  }
}

class UserProfileNotifier extends StateNotifier<UserProfileState> {
  UserProfileNotifier(this._repository)
    : super(const UserProfileState(isLoading: true)) {
    loadProfile();
  }

  final AuthRepository _repository;

  Future<void> loadProfile() async {
    state = state.copyWith(isLoading: true, clearError: true);
    try {
      final profile = await _repository.getCurrentUserProfile();
      state = state.copyWith(
        profile: profile,
        isLoading: false,
        isSaving: false,
        clearError: true,
      );
    } catch (error) {
      state = state.copyWith(
        isLoading: false,
        isSaving: false,
        errorMessage: AppExceptionMapper.message(error),
      );
    }
  }

  Future<void> refresh() async {
    await loadProfile();
  }

  Future<CurrentUserProfile> updateProfile(
    CurrentUserProfileUpdateInput input,
  ) async {
    state = state.copyWith(isSaving: true, clearError: true);
    try {
      final profile = await _repository.updateCurrentUserProfile(input);
      state = state.copyWith(
        profile: profile,
        isLoading: false,
        isSaving: false,
        clearError: true,
      );
      return profile;
    } catch (error) {
      state = state.copyWith(
        isSaving: false,
        errorMessage: AppExceptionMapper.message(error),
      );
      rethrow;
    }
  }

  void clear() {
    state = const UserProfileState();
  }
}

final userProfileProvider =
    StateNotifierProvider<UserProfileNotifier, UserProfileState>((ref) {
      return UserProfileNotifier(ref.watch(authRepositoryProvider));
    });
