import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/legacy.dart';

import '../models/planning_models.dart';
import '../services/planning_service.dart';

class PlanningState {
  final DateTime selectedDate;
  final List<PlanningSessionModel> sessions;
  final bool isLoading;
  final bool isMutating;
  final String? errorMessage;

  const PlanningState({
    required this.selectedDate,
    this.sessions = const [],
    this.isLoading = false,
    this.isMutating = false,
    this.errorMessage,
  });

  factory PlanningState.initial() {
    final now = DateTime.now();
    return PlanningState(selectedDate: DateTime(now.year, now.month, now.day));
  }

  PlanningState copyWith({
    DateTime? selectedDate,
    List<PlanningSessionModel>? sessions,
    bool? isLoading,
    bool? isMutating,
    String? errorMessage,
    bool clearError = false,
  }) {
    return PlanningState(
      selectedDate: selectedDate ?? this.selectedDate,
      sessions: sessions ?? this.sessions,
      isLoading: isLoading ?? this.isLoading,
      isMutating: isMutating ?? this.isMutating,
      errorMessage: clearError ? null : (errorMessage ?? this.errorMessage),
    );
  }
}

class PlanningNotifier extends StateNotifier<PlanningState> {
  final PlanningService _service;

  PlanningNotifier(this._service) : super(PlanningState.initial()) {
    loadDay(state.selectedDate).catchError((_) {});
  }

  Future<void> loadDay(DateTime date, {bool showLoading = true}) async {
    final normalized = _normalizeDate(date);
    state = state.copyWith(
      selectedDate: normalized,
      isLoading: showLoading,
      clearError: true,
    );

    try {
      final result = await _service.getDay(normalized);
      state = state.copyWith(
        selectedDate: normalized,
        sessions: _sortSessions(result.sessions),
        isLoading: false,
        isMutating: false,
        clearError: true,
      );
    } catch (e) {
      state = state.copyWith(
        selectedDate: normalized,
        isLoading: false,
        isMutating: false,
        errorMessage: _extractError(e),
      );
      rethrow;
    }
  }

  Future<void> refresh() async {
    await loadDay(state.selectedDate, showLoading: false);
  }

  Future<void> createSession({
    required String subject,
    required DateTime start,
    required DateTime end,
    required String priority,
  }) async {
    state = state.copyWith(isMutating: true, clearError: true);

    try {
      final created = await _service.createSession(
        subject: subject,
        start: start,
        end: end,
        priority: priority,
      );

      state = state.copyWith(
        sessions: _sortSessions([...state.sessions, created]),
        isMutating: false,
        clearError: true,
      );
    } catch (e) {
      state = state.copyWith(
        isMutating: false,
        errorMessage: _extractError(e),
      );
      rethrow;
    }
  }

  Future<void> deleteSession(int sessionId) async {
    state = state.copyWith(isMutating: true, clearError: true);

    try {
      await _service.deleteSession(sessionId);
      state = state.copyWith(
        sessions: state.sessions.where((session) => session.id != sessionId).toList(),
        isMutating: false,
        clearError: true,
      );
    } catch (e) {
      state = state.copyWith(
        isMutating: false,
        errorMessage: _extractError(e),
      );
      rethrow;
    }
  }

  Future<void> completeSession(int sessionId) async {
    await updateSessionStatus(sessionId, 'completed');
  }

  Future<void> updateSessionStatus(int sessionId, String status) async {
    state = state.copyWith(isMutating: true, clearError: true);

    try {
      final updated = await _service.updateSessionStatus(sessionId, status);
      final sessions = state.sessions
          .map((session) => session.id == sessionId ? updated : session)
          .toList();

      state = state.copyWith(
        sessions: _sortSessions(sessions),
        isMutating: false,
        clearError: true,
      );
    } catch (e) {
      state = state.copyWith(
        isMutating: false,
        errorMessage: _extractError(e),
      );
      rethrow;
    }
  }

  Future<void> toggleSessionCompletion(int sessionId, bool isCompleted) async {
    await updateSessionStatus(sessionId, isCompleted ? 'pending' : 'completed');
  }

  Future<void> autoUnvalidateExpiredSessions() async {
    final now = DateTime.now();
    final expiredCompletedSessions = state.sessions
        .where((session) => session.isCompleted && !session.end.isAfter(now))
        .toList();

    if (expiredCompletedSessions.isEmpty || state.isMutating) {
      return;
    }

    for (final session in expiredCompletedSessions) {
      await updateSessionStatus(session.id, 'pending');
    }
  }

  Future<void> generatePlanning({
    int? documentId,
    String? weekType,
    Map<String, dynamic>? preferences,
  }) async {
    state = state.copyWith(isMutating: true, clearError: true);

    try {
      final result = await _service.generatePlanning(
        date: state.selectedDate,
        documentId: documentId,
        weekType: weekType,
        preferences: preferences,
      );

      state = state.copyWith(
        sessions: _sortSessions(result.sessions),
        isMutating: false,
        clearError: true,
      );
    } catch (e) {
      state = state.copyWith(
        isMutating: false,
        errorMessage: _extractError(e),
      );
      rethrow;
    }
  }

  Future<void> generatePlanningForWeek({
    int? documentId,
    String? weekType,
    Map<String, dynamic>? preferences,
  }) async {
    state = state.copyWith(isMutating: true, clearError: true);

    try {
      await _service.generatePlanningWeek(
        date: state.selectedDate,
        documentId: documentId,
        weekType: weekType,
        preferences: preferences,
      );

      final result = await _service.getDay(state.selectedDate);
      state = state.copyWith(
        sessions: _sortSessions(result.sessions),
        isMutating: false,
        clearError: true,
      );
    } catch (e) {
      state = state.copyWith(
        isMutating: false,
        errorMessage: _extractError(e),
      );
      rethrow;
    }
  }

  List<PlanningSessionModel> _sortSessions(List<PlanningSessionModel> sessions) {
    final sorted = [...sessions];
    sorted.sort((a, b) => a.start.compareTo(b.start));
    return sorted;
  }

  DateTime _normalizeDate(DateTime date) {
    return DateTime(date.year, date.month, date.day);
  }

  String _extractError(Object error) {
    if (error is DioException) {
      final data = error.response?.data;
      if (data is Map<String, dynamic>) {
        final detail = data['detail'];
        if (detail is String && detail.isNotEmpty) {
          return detail;
        }
      }
      if (data is String && data.isNotEmpty) {
        return data;
      }
    }
    return error.toString();
  }
}

final planningProvider = StateNotifierProvider<PlanningNotifier, PlanningState>((ref) {
  return PlanningNotifier(ref.watch(planningServiceProvider));
});
