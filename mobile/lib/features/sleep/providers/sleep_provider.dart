// lib/features/sleep/providers/sleep_provider.dart

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/legacy.dart';
import 'package:shared_preferences/shared_preferences.dart';
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

final manualSleepSessionProvider = StateNotifierProvider<
  ManualSleepSessionNotifier,
  ManualSleepSessionState
>((ref) => ManualSleepSessionNotifier(ref, ref.watch(sleepServiceProvider)));

class ManualSleepSessionNotifier extends StateNotifier<ManualSleepSessionState> {
  ManualSleepSessionNotifier(this._ref, this._service)
    : super(const ManualSleepSessionState(isLoading: true)) {
    _restoreSleepStart();
  }

  static const _sleepStartKey = 'sleep_start';

  final Ref _ref;
  final SleepService _service;

  Future<void> _restoreSleepStart() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final savedSleepStart = prefs.getString(_sleepStartKey);
      final sleepStart = savedSleepStart == null
          ? null
          : DateTime.tryParse(savedSleepStart);

      state = state.copyWith(
        sleepStart: sleepStart,
        clearSleepStart: sleepStart == null,
        isLoading: false,
        isSubmitting: false,
      );
    } catch (_) {
      state = state.copyWith(
        clearSleepStart: true,
        isLoading: false,
        isSubmitting: false,
      );
    }
  }

  Future<void> refresh() async {
    state = state.copyWith(isLoading: true);
    await _restoreSleepStart();
  }

  Future<DateTime> startSleep() async {
    final sleepStart = DateTime.now();
    state = state.copyWith(isSubmitting: true);

    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_sleepStartKey, sleepStart.toIso8601String());
      state = state.copyWith(
        sleepStart: sleepStart,
        isLoading: false,
        isSubmitting: false,
      );
      return sleepStart;
    } catch (error) {
      state = state.copyWith(isSubmitting: false);
      throw Exception('Unable to save sleep start locally: $error');
    }
  }

  Future<SleepRecord> finishSleep() async {
    final sleepStart = state.sleepStart;
    if (sleepStart == null) {
      throw Exception('No saved sleep start found.');
    }

    state = state.copyWith(isSubmitting: true);

    try {
      final sleepEnd = DateTime.now();
      final record = await _service.logSleep(
        sleepStart: sleepStart,
        sleepEnd: sleepEnd,
      );

      final prefs = await SharedPreferences.getInstance();
      await prefs.remove(_sleepStartKey);

      state = state.copyWith(
        clearSleepStart: true,
        isLoading: false,
        isSubmitting: false,
      );

      try {
        await Future.wait([
          _ref.read(sleepHistoryProvider.notifier).fetchHistory(),
          _ref.read(sleepStatsProvider.notifier).fetchStats(),
        ]);
      } catch (_) {
        // The sleep record is already stored; a refresh failure should not
        // make the wake action look like it failed.
      }

      return record;
    } catch (error) {
      state = state.copyWith(isSubmitting: false);
      throw Exception('Unable to log sleep record: $error');
    }
  }
}
