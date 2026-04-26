import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:smart_focus/features/planning/data/planning_repository.dart';
import 'package:smart_focus/features/planning/models/planning_models.dart';
import 'package:smart_focus/features/sleep/models/sleep_models.dart';
import 'package:smart_focus/features/sleep/services/sleep_service.dart';

class StatsDashboardData {
  final String period;
  final int plannedMinutes;
  final int completedMinutes;
  final int focusCompletionPercent;
  final double avgSleepHours;
  final double? avgSleepScore;
  final int sleepRecordedDays;
  final List<String> labels;
  final List<double> focusCompletionSeries;
  final List<double> sleepHoursSeries;

  const StatsDashboardData({
    required this.period,
    required this.plannedMinutes,
    required this.completedMinutes,
    required this.focusCompletionPercent,
    required this.avgSleepHours,
    required this.avgSleepScore,
    required this.sleepRecordedDays,
    required this.labels,
    required this.focusCompletionSeries,
    required this.sleepHoursSeries,
  });

  String get periodLabel => period == 'month' ? 'Mois' : 'Semaine';
}

final statsDashboardProvider =
    FutureProvider.family.autoDispose<StatsDashboardData, String>((ref, period) async {
      final planningRepository = ref.watch(planningRepositoryProvider);
      final sleepService = ref.watch(sleepServiceProvider);
      final range = _rangeForPeriod(period);

      final sessionsFuture = _loadSessionsInRange(
        planningRepository: planningRepository,
        start: range.start,
        end: range.end,
        days: range.days,
      );
      final sleepStatsFuture = sleepService.getStats(period: period);
      final sleepHistoryFuture = sleepService.getHistory(
        limit: period == 'month' ? 90 : 30,
      );

      final sessions = await sessionsFuture;
      final sleepStats = await sleepStatsFuture;
      final sleepHistory = await sleepHistoryFuture;

      final plannedMinutes = sessions.fold<int>(0, (sum, session) {
        return sum + session.duration.inMinutes;
      });
      final completedMinutes = sessions.where((s) => s.isCompleted).fold<int>(0, (sum, session) {
        return sum + session.duration.inMinutes;
      });
      final focusCompletionPercent = plannedMinutes <= 0
          ? 0
          : ((completedMinutes / plannedMinutes) * 100).round();

      final sleepByDay = _buildSleepHoursByDay(
        records: sleepHistory,
        start: range.start,
        end: range.end,
      );

      final labels = <String>[];
      final focusSeries = <double>[];
      final sleepSeries = <double>[];

      for (var index = 0; index < range.days; index++) {
        final day = range.start.add(Duration(days: index));
        final daySessions = sessions.where((session) => _isSameDay(session.start, day)).toList();

        final dayPlanned = daySessions.fold<int>(0, (sum, session) {
          return sum + session.duration.inMinutes;
        });
        final dayCompleted = daySessions.where((s) => s.isCompleted).fold<int>(0, (sum, session) {
          return sum + session.duration.inMinutes;
        });
        final dayFocus = dayPlanned <= 0 ? 0 : ((dayCompleted / dayPlanned) * 100).round();

        labels.add(_dayLabel(day, period: period));
        focusSeries.add(dayFocus.toDouble());
        sleepSeries.add(sleepByDay[_dayKey(day)] ?? 0);
      }

      return StatsDashboardData(
        period: period,
        plannedMinutes: plannedMinutes,
        completedMinutes: completedMinutes,
        focusCompletionPercent: focusCompletionPercent,
        avgSleepHours: sleepStats.avgHours,
        avgSleepScore: sleepStats.scoreAvg,
        sleepRecordedDays: sleepStats.numRecords,
        labels: labels,
        focusCompletionSeries: focusSeries,
        sleepHoursSeries: sleepSeries,
      );
    });

Future<List<PlanningSessionModel>> _loadSessionsInRange({
  required PlanningRepository planningRepository,
  required DateTime start,
  required DateTime end,
  required int days,
}) async {
  final requests = <Future<PlanningDayModel?>>[];
  for (var i = 0; i < days; i++) {
    final day = start.add(Duration(days: i));
    requests.add(() async {
      try {
        return await planningRepository.getDay(day);
      } catch (_) {
        return null;
      }
    }());
  }

  final dayResults = await Future.wait(requests);
  final sessions = <PlanningSessionModel>[];
  for (final day in dayResults) {
    if (day == null) continue;
    sessions.addAll(day.sessions);
  }

  return sessions.where((session) {
    final startAt = session.start;
    return !startAt.isBefore(start) && !startAt.isAfter(end);
  }).toList();
}

Map<String, double> _buildSleepHoursByDay({
  required List<SleepRecord> records,
  required DateTime start,
  required DateTime end,
}) {
  final grouped = <String, List<double>>{};

  for (final record in records) {
    final totalHours = record.totalHours;
    if (totalHours == null) continue;

    final day = DateTime(
      record.sleepStart.year,
      record.sleepStart.month,
      record.sleepStart.day,
    );

    if (day.isBefore(start) || day.isAfter(end)) continue;

    final key = _dayKey(day);
    grouped.putIfAbsent(key, () => <double>[]).add(totalHours);
  }

  final averaged = <String, double>{};
  grouped.forEach((key, values) {
    if (values.isEmpty) return;
    final sum = values.reduce((a, b) => a + b);
    averaged[key] = sum / values.length;
  });
  return averaged;
}

_StatsRange _rangeForPeriod(String period) {
  final days = period == 'month' ? 30 : 7;
  final now = DateTime.now();
  final todayStart = DateTime(now.year, now.month, now.day);
  final start = todayStart.subtract(Duration(days: days - 1));
  return _StatsRange(start: start, end: now, days: days);
}

bool _isSameDay(DateTime first, DateTime second) {
  return first.year == second.year && first.month == second.month && first.day == second.day;
}

String _dayLabel(DateTime day, {required String period}) {
  if (period == 'month') {
    return day.day.toString();
  }
  const days = ['L', 'M', 'M', 'J', 'V', 'S', 'D'];
  return days[day.weekday - 1];
}

String _dayKey(DateTime day) {
  final month = day.month.toString().padLeft(2, '0');
  final date = day.day.toString().padLeft(2, '0');
  return '${day.year}-$month-$date';
}

class _StatsRange {
  final DateTime start;
  final DateTime end;
  final int days;

  const _StatsRange({
    required this.start,
    required this.end,
    required this.days,
  });
}
