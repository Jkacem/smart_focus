// lib/features/sleep/providers/sleep_provider.dart

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/legacy.dart';
import '../services/sleep_service.dart';
import '../models/sleep_models.dart';

// ─────────────────────────────────────────────
// SLEEP HISTORY
// ─────────────────────────────────────────────

final sleepHistoryProvider =
    StateNotifierProvider<SleepHistoryNotifier, AsyncValue<List<SleepRecord>>>(
      (ref) => SleepHistoryNotifier(ref.watch(sleepServiceProvider)),
    );

class SleepHistoryNotifier
    extends StateNotifier<AsyncValue<List<SleepRecord>>> {
  final SleepService _service;

  SleepHistoryNotifier(this._service) : super(const AsyncLoading()) {
    fetchHistory();
  }

  Future<void> fetchHistory({int limit = 30}) async {
    state = const AsyncLoading();
    try {
      final records = await _service.getHistory(limit: limit);
      state = AsyncData(records);
    } catch (e, st) {
      state = AsyncError(e, st);
    }
  }
}

// ─────────────────────────────────────────────
// SLEEP STATS
// ─────────────────────────────────────────────

final sleepPeriodProvider = StateProvider<String>((ref) => 'week');

final sleepStatsProvider =
    StateNotifierProvider<SleepStatsNotifier, AsyncValue<SleepStats?>>((ref) {
      final period = ref.watch(sleepPeriodProvider);
      return SleepStatsNotifier(ref.watch(sleepServiceProvider), period);
    });

class SleepStatsNotifier extends StateNotifier<AsyncValue<SleepStats?>> {
  final SleepService _service;
  final String _period;

  SleepStatsNotifier(this._service, this._period)
    : super(const AsyncLoading()) {
    fetchStats();
  }

  Future<void> fetchStats() async {
    state = const AsyncLoading();
    try {
      final stats = await _service.getStats(period: _period);
      state = AsyncData(stats);
    } catch (e, st) {
      state = AsyncError(e, st);
    }
  }
}

// ─────────────────────────────────────────────
// ALARM CONFIG
// ─────────────────────────────────────────────

final alarmProvider =
    StateNotifierProvider<AlarmNotifier, AsyncValue<AlarmConfig?>>(
      (ref) => AlarmNotifier(ref.watch(sleepServiceProvider)),
    );

class AlarmNotifier extends StateNotifier<AsyncValue<AlarmConfig?>> {
  final SleepService _service;

  AlarmNotifier(this._service) : super(const AsyncLoading()) {
    fetchAlarm();
  }

  Future<void> fetchAlarm() async {
    state = const AsyncLoading();
    try {
      final alarm = await _service.getAlarm();
      state = AsyncData(alarm); // null = not configured yet
    } catch (e, st) {
      state = AsyncError(e, st);
    }
  }

  Future<void> updateAlarm(AlarmConfig config) async {
    try {
      final updated = await _service.updateAlarm(config);
      state = AsyncData(updated);
    } catch (e, st) {
      state = AsyncError(e, st);
    }
  }
}
