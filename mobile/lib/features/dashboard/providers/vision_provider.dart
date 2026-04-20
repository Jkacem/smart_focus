// lib/features/dashboard/providers/vision_provider.dart

import 'dart:async';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/legacy.dart';
import '../models/vision_models.dart';
import '../services/vision_service.dart';

/// Holds the current active work-session ID (set when user starts a session).
final activeWorkSessionIdProvider = StateProvider<String?>((ref) => null);

/// Polls the backend every 2 seconds for the latest CV snapshot.
/// Automatically starts/stops when [activeWorkSessionIdProvider] changes.
final liveSnapshotProvider =
    StateNotifierProvider<LiveSnapshotNotifier, AsyncValue<VisionSnapshot?>>(
  (ref) {
    final sessionId = ref.watch(activeWorkSessionIdProvider);
    final service = ref.watch(visionServiceProvider);
    return LiveSnapshotNotifier(service, sessionId);
  },
);

class LiveSnapshotNotifier
    extends StateNotifier<AsyncValue<VisionSnapshot?>> {
  LiveSnapshotNotifier(this._service, this._sessionId)
      : super(const AsyncData(null)) {
    if (_sessionId != null) {
      _startPolling();
    }
  }

  final VisionService _service;
  final String? _sessionId;
  Timer? _timer;

  void _startPolling() {
    // Fetch immediately, then every 2 seconds
    _fetchLatest();
    _timer = Timer.periodic(const Duration(seconds: 2), (_) {
      _fetchLatest();
    });
  }

  Future<void> _fetchLatest() async {
    if (_sessionId == null) return;
    try {
      final snapshot = await _service.getLatestSnapshot(_sessionId!);
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
      final sessions = await _service.listSessions();
      state = AsyncData(sessions);
    } catch (e, st) {
      state = AsyncError(e, st);
    }
  }
}
