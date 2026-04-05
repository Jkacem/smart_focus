import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/legacy.dart';

import '../../../core/network/app_exception.dart';
import '../data/planning_repository.dart';
import '../models/planning_models.dart';

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
  PlanningNotifier(this._repository) : super(PlanningState.initial()) {
    loadDay(state.selectedDate).catchError((_) {});
  }

  final PlanningRepository _repository;

  Future<void> loadDay(DateTime date, {bool showLoading = true}) async {
    final normalized = _normalizeDate(date);
    state = state.copyWith(
      selectedDate: normalized,
      isLoading: showLoading,
      clearError: true,
    );

    try {
      final result = await _repository.getDay(normalized);
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
    int? documentId,
    List<int>? documentIds,
  }) async {
    state = state.copyWith(isMutating: true, clearError: true);

    try {
      final created = await _repository.createSession(
        subject: subject,
        start: start,
        end: end,
        priority: priority,
        documentId: documentId,
        documentIds: documentIds,
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
      await _repository.deleteSession(sessionId);
      state = state.copyWith(
        sessions: state.sessions
            .where((session) => session.id != sessionId)
            .toList(),
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
      final updated = await _repository.updateSessionStatus(sessionId, status);
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

  Future<void> updateSessionDocuments(int sessionId, List<int> documentIds) async {
    state = state.copyWith(isMutating: true, clearError: true);

    try {
      final updated = await _repository.updateSessionDocuments(sessionId, documentIds);
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

  Future<PlanningSessionModel> rescheduleSession(int sessionId) async {
    state = state.copyWith(isMutating: true, clearError: true);

    try {
      final rescheduled = await _repository.rescheduleSession(sessionId);
      await loadDay(state.selectedDate, showLoading: false);
      return rescheduled;
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
    return;
  }

  Future<void> generatePlanning({
    int? documentId,
    List<int>? examIds,
    String? weekType,
    Map<String, dynamic>? preferences,
  }) async {
    state = state.copyWith(isMutating: true, clearError: true);

    try {
      final result = await _repository.generatePlanning(
        date: state.selectedDate,
        documentId: documentId,
        examIds: examIds,
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
    List<int>? examIds,
    String? weekType,
    Map<String, dynamic>? preferences,
  }) async {
    state = state.copyWith(isMutating: true, clearError: true);

    try {
      await _repository.generatePlanningWeek(
        date: state.selectedDate,
        documentId: documentId,
        examIds: examIds,
        weekType: weekType,
        preferences: preferences,
      );

      final result = await _repository.getDay(state.selectedDate);
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
    return AppExceptionMapper.message(error);
  }
}

final planningProvider = StateNotifierProvider<PlanningNotifier, PlanningState>((ref) {
  return PlanningNotifier(ref.watch(planningRepositoryProvider));
});

final planningInsightsProvider = FutureProvider.family
    .autoDispose<PlanningInsightsModel, String>((ref, period) async {
      final repository = ref.watch(planningRepositoryProvider);
      return repository.getInsights(period: period);
    });

final planningExamsProvider = FutureProvider.autoDispose<List<PlanningExamModel>>((
  ref,
) async {
  final repository = ref.watch(planningRepositoryProvider);
  return repository.getExams();
});

final todayPlanningProvider = FutureProvider.autoDispose<PlanningDayModel>((ref) async {
  final repository = ref.watch(planningRepositoryProvider);
  return repository.getToday();
});
