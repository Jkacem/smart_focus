// lib/features/sleep/models/sleep_models.dart

class SleepRecord {
  final int id;
  final int userId;
  final DateTime sleepStart;
  final DateTime? sleepEnd;
  final double? totalHours;
  final double? deepSleepHours;
  final double? lightSleepHours;
  final int? sleepScore;
  final DateTime createdAt;

  SleepRecord({
    required this.id,
    required this.userId,
    required this.sleepStart,
    this.sleepEnd,
    this.totalHours,
    this.deepSleepHours,
    this.lightSleepHours,
    this.sleepScore,
    required this.createdAt,
  });

  factory SleepRecord.fromJson(Map<String, dynamic> json) {
    return SleepRecord(
      id: json['id'],
      userId: json['user_id'],
      sleepStart: DateTime.parse(json['sleep_start']),
      sleepEnd: json['sleep_end'] != null ? DateTime.parse(json['sleep_end']) : null,
      totalHours: (json['total_hours'] as num?)?.toDouble(),
      deepSleepHours: (json['deep_sleep_hours'] as num?)?.toDouble(),
      lightSleepHours: (json['light_sleep_hours'] as num?)?.toDouble(),
      sleepScore: json['sleep_score'],
      createdAt: DateTime.parse(json['created_at']),
    );
  }
}

class SleepStats {
  final String period;
  final double avgHours;
  final double? scoreAvg;
  final String trend; // "improving" | "stable" | "declining"
  final int numRecords;

  SleepStats({
    required this.period,
    required this.avgHours,
    this.scoreAvg,
    required this.trend,
    required this.numRecords,
  });

  factory SleepStats.fromJson(Map<String, dynamic> json) {
    return SleepStats(
      period: json['period'],
      avgHours: (json['avg_hours'] as num).toDouble(),
      scoreAvg: (json['score_avg'] as num?)?.toDouble(),
      trend: json['trend'],
      numRecords: json['num_records'],
    );
  }
}

class AlarmConfig {
  final int id;
  final int userId;
  final String alarmTime;   // "HH:MM"
  final bool isActive;
  final String wakeMode;    // "gradual" | "normal" | "silent"
  final int lightIntensity; // 0-100
  final bool soundEnabled;

  AlarmConfig({
    required this.id,
    required this.userId,
    required this.alarmTime,
    required this.isActive,
    required this.wakeMode,
    required this.lightIntensity,
    required this.soundEnabled,
  });

  factory AlarmConfig.fromJson(Map<String, dynamic> json) {
    return AlarmConfig(
      id: json['id'],
      userId: json['user_id'],
      alarmTime: json['alarm_time'],
      isActive: json['is_active'] ?? true,
      wakeMode: json['wake_mode'] ?? 'gradual',
      lightIntensity: json['light_intensity'] ?? 50,
      soundEnabled: json['sound_enabled'] ?? true,
    );
  }

  Map<String, dynamic> toJson() => {
    'alarm_time': alarmTime,
    'is_active': isActive,
    'wake_mode': wakeMode,
    'light_intensity': lightIntensity,
    'sound_enabled': soundEnabled,
  };
}

class ManualSleepSessionState {
  final DateTime? sleepStart;
  final bool isLoading;
  final bool isSubmitting;

  const ManualSleepSessionState({
    this.sleepStart,
    this.isLoading = false,
    this.isSubmitting = false,
  });

  bool get isSleeping => sleepStart != null;

  ManualSleepSessionState copyWith({
    DateTime? sleepStart,
    bool clearSleepStart = false,
    bool? isLoading,
    bool? isSubmitting,
  }) {
    return ManualSleepSessionState(
      sleepStart: clearSleepStart ? null : (sleepStart ?? this.sleepStart),
      isLoading: isLoading ?? this.isLoading,
      isSubmitting: isSubmitting ?? this.isSubmitting,
    );
  }
}
