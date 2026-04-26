// lib/features/dashboard/providers/vision_provider.dart

import 'dart:async';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/legacy.dart';

import '../models/vision_models.dart';
import '../services/vision_service.dart';
import '../utils/session_utils.dart';

/// Holds the current active work-session ID (set when user starts a session).
final activeWorkSessionIdProvider = StateProvider<String?>((ref) => null);
final activePlanningSessionIdProvider = StateProvider<int?>((ref) => null);
final activePlanningSessionTitleProvider = StateProvider<String?>((ref) => null);
final isLivePollingPausedProvider = StateProvider<bool>((ref) => false);

class ActiveSessionRuntimeState {
  final String? sessionId;
  final int elapsedSeconds;
  final bool isPaused;
  final int pauseCount;
  final DateTime? lastTickAt;

  const ActiveSessionRuntimeState({
    this.sessionId,
    this.elapsedSeconds = 0,
    this.isPaused = false,
    this.pauseCount = 0,
    this.lastTickAt,
  });

  bool get hasSession => sessionId != null;

  ActiveSessionRuntimeState copyWith({
    String? sessionId,
    int? elapsedSeconds,
    bool? isPaused,
    int? pauseCount,
    DateTime? lastTickAt,
    bool clearLastTickAt = false,
  }) {
    return ActiveSessionRuntimeState(
      sessionId: sessionId ?? this.sessionId,
      elapsedSeconds: elapsedSeconds ?? this.elapsedSeconds,
      isPaused: isPaused ?? this.isPaused,
      pauseCount: pauseCount ?? this.pauseCount,
      lastTickAt: clearLastTickAt ? null : (lastTickAt ?? this.lastTickAt),
    );
  }
}

class ActiveSessionRuntimeNotifier
    extends StateNotifier<ActiveSessionRuntimeState> {
  ActiveSessionRuntimeNotifier() : super(const ActiveSessionRuntimeState());

  void attachSession(String? sessionId, {bool paused = false}) {
    if (sessionId == null || isSyntheticPlanningSessionId(sessionId)) {
      clear();
      return;
    }

    if (state.sessionId == sessionId) {
      if (!state.isPaused && state.lastTickAt == null) {
        state = state.copyWith(lastTickAt: DateTime.now());
      }
      return;
    }

    state = ActiveSessionRuntimeState(
      sessionId: sessionId,
      isPaused: paused,
      lastTickAt: paused ? null : DateTime.now(),
    );
  }

  void tick() {
    if (!state.hasSession || state.isPaused) return;

    final now = DateTime.now();
    final last = state.lastTickAt ?? now;
    final delta = now.difference(last).inSeconds;
    if (delta <= 0) {
      if (state.lastTickAt == null) {
        state = state.copyWith(lastTickAt: now);
      }
      return;
    }

    state = state.copyWith(
      elapsedSeconds: state.elapsedSeconds + delta,
      lastTickAt: now,
    );
  }

  void pause() {
    if (!state.hasSession || state.isPaused) return;
    tick();
    state = state.copyWith(
      isPaused: true,
      pauseCount: state.pauseCount + 1,
      clearLastTickAt: true,
    );
  }

  void resume() {
    if (!state.hasSession || !state.isPaused) return;
    state = state.copyWith(
      isPaused: false,
      lastTickAt: DateTime.now(),
    );
  }

  void clear() {
    state = const ActiveSessionRuntimeState();
  }
}

final activeSessionRuntimeProvider = StateNotifierProvider<
    ActiveSessionRuntimeNotifier, ActiveSessionRuntimeState>(
  (ref) => ActiveSessionRuntimeNotifier(),
);

/// Polls the backend every 2 seconds for the latest CV snapshot.
/// Automatically starts/stops when [activeWorkSessionIdProvider] changes.
final liveSnapshotProvider =
    StateNotifierProvider<LiveSnapshotNotifier, AsyncValue<VisionSnapshot?>>(
  (ref) {
    final service = ref.watch(visionServiceProvider);
    final notifier = LiveSnapshotNotifier(service);

    ref.listen<String?>(activeWorkSessionIdProvider, (_, next) {
      notifier.setSession(next);
    });
    ref.listen<bool>(isLivePollingPausedProvider, (_, next) {
      notifier.setPaused(next);
    });

    notifier.setSession(ref.read(activeWorkSessionIdProvider));
    notifier.setPaused(ref.read(isLivePollingPausedProvider));

    return notifier;
  },
);

class LiveSnapshotNotifier
    extends StateNotifier<AsyncValue<VisionSnapshot?>> {
  LiveSnapshotNotifier(this._service) : super(const AsyncData(null));

  final VisionService _service;
  Timer? _timer;
  String? _sessionId;
  bool _isPaused = false;

  void setSession(String? sessionId) {
    if (sessionId != null && isSyntheticPlanningSessionId(sessionId)) {
      sessionId = null;
    }
    if (_sessionId == sessionId) return;
    _sessionId = sessionId;
    _restartPolling();
  }

  void setPaused(bool paused) {
    if (_isPaused == paused) return;
    _isPaused = paused;
    _restartPolling();
  }

  void _restartPolling() {
    _timer?.cancel();
    _timer = null;

    if (_sessionId == null || _isPaused) {
      return;
    }

    // Fetch immediately, then every 2 seconds
    _fetchLatest();
    _timer = Timer.periodic(const Duration(seconds: 2), (_) {
      _fetchLatest();
    });
  }

  Future<void> _fetchLatest() async {
    final sessionId = _sessionId;
    if (sessionId == null) return;
    try {
      final snapshot = await _service.getLatestSnapshot(sessionId);
      if (mounted) {
        state = AsyncData(snapshot);
      }
    } catch (e, st) {
      if (mounted) {
        // Keep the last good value on transient errors
        if (state.hasValue && state.value != null) return;
        state = AsyncError(e, st);
      }
    }
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }
}

/// Lists all CV work sessions (for history / selection).
final workSessionsProvider =
    StateNotifierProvider<WorkSessionsNotifier, AsyncValue<List<WorkSessionInfo>>>(
  (ref) => WorkSessionsNotifier(ref.watch(visionServiceProvider)),
);

class WorkSessionsNotifier
    extends StateNotifier<AsyncValue<List<WorkSessionInfo>>> {
  final VisionService _service;

  WorkSessionsNotifier(this._service) : super(const AsyncLoading()) {
    fetch();
  }

  Future<void> fetch() async {
    state = const AsyncLoading();
    try {
      final sessions = await _service.listSessions(limit: 200);
      state = AsyncData(sessions);
    } catch (e, st) {
      state = AsyncError(e, st);
    }
  }
}

final todayVisionSummaryProvider =
    FutureProvider.autoDispose<DashboardVisionSummary>((ref) async {
  final service = ref.watch(visionServiceProvider);
  final now = DateTime.now();
  final todayStart = DateTime(now.year, now.month, now.day);
  final tomorrowStart = todayStart.add(const Duration(days: 1));

  final sessions = await service.listSessions(limit: 200);
  final todaySessions = sessions.where((session) {
    if (isSyntheticPlanningSessionId(session.id)) {
      return false;
    }
    final start = _toLocal(session.startTime);
    return !start.isBefore(todayStart) && start.isBefore(tomorrowStart);
  }).toList();

  if (todaySessions.isEmpty) {
    return const DashboardVisionSummary.empty();
  }

  final snapshots = <VisionSnapshot?>[];
  for (final session in todaySessions) {
    snapshots.add(await _safeLatestSnapshot(service, session.id));
  }

  final focusValues = <double>[];
  final scoreValues = <double>[];
  final postureValues = <double>[];
  final stressValues = <double>[];
  var pauseCount = 0;

  for (var index = 0; index < todaySessions.length; index++) {
    final session = todaySessions[index];
    final snapshot = snapshots[index];
    final summary = session.finalSummary;

    final snapshotFocus = _normalizePercent(snapshot?.globalFocusScore);
    final summaryFocus = _normalizePercent(summary?['focus_time_ratio']);
    final finalScore = _normalizePercent(summary?['final_score']);
    final snapshotPosture = _normalizePercent(snapshot?.postureScore);
    final summaryPosture = _normalizePercent(summary?['posture_quality_score']);
    final snapshotStress = _normalizePercent(snapshot?.stressRiskScore);

    if (snapshotFocus != null) {
      focusValues.add(snapshotFocus);
    } else if (summaryFocus != null) {
      focusValues.add(summaryFocus);
    }

    if (finalScore != null) {
      scoreValues.add(finalScore);
    } else if (snapshotFocus != null) {
      scoreValues.add(snapshotFocus);
    } else if (summaryFocus != null) {
      scoreValues.add(summaryFocus);
    }

    if (snapshotPosture != null) {
      postureValues.add(snapshotPosture);
    } else if (summaryPosture != null) {
      postureValues.add(summaryPosture);
    }

    if (snapshotStress != null) {
      stressValues.add(snapshotStress);
    }

    pauseCount += _extractPauseCount(summary);
  }

  return DashboardVisionSummary(
    todaySessionCount: todaySessions.length,
    completedSessionCount: todaySessions.where((session) => !session.isActive).length,
    activeSessionCount: todaySessions.where((session) => session.isActive).length,
    score: _average(scoreValues),
    focus: _average(focusValues),
    posture: _average(postureValues),
    stress: _average(stressValues),
    pauseCount: pauseCount,
  );
});

DateTime _toLocal(DateTime value) => value.isUtc ? value.toLocal() : value;

Future<VisionSnapshot?> _safeLatestSnapshot(
  VisionService service,
  String sessionId,
) async {
  try {
    return await service.getLatestSnapshot(sessionId);
  } catch (_) {
    return null;
  }
}

double? _normalizePercent(dynamic value) {
  final number = _asDouble(value);
  if (number == null) return null;

  var normalized = number;
  if (normalized <= 1.0) {
    normalized *= 100;
  }
  if (normalized < 0) return 0;
  if (normalized > 100) return 100;
  return normalized;
}

double? _asDouble(dynamic value) {
  if (value == null) return null;
  if (value is num) return value.toDouble();
  if (value is String) return double.tryParse(value);
  return null;
}

double? _average(List<double> values) {
  if (values.isEmpty) return null;
  final sum = values.fold<double>(0, (acc, current) => acc + current);
  return sum / values.length;
}

int _extractPauseCount(Map<String, dynamic>? summary) {
  if (summary == null) return 0;

  final breakdownRaw = summary['breakdown'];
  Map<String, dynamic>? breakdown;
  if (breakdownRaw is Map) {
    breakdown = Map<String, dynamic>.from(breakdownRaw as Map);
  }

  final direct = summary['pause_count'];
  final fromBreakdown = breakdown?['pause_count'] ?? breakdown?['pauses'];
  final value = fromBreakdown ?? direct;

  if (value is int) return value;
  if (value is num) return value.round();
  if (value is String) return int.tryParse(value) ?? 0;
  return 0;
}

