// lib/features/sleep/services/sleep_service.dart

import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/router/api_client.dart';
import '../models/sleep_models.dart';

class SleepService {
  final Dio _dio = ApiClient.createDio();

  /// Log a night's sleep
  Future<SleepRecord> logSleep({
    required DateTime sleepStart,
    required DateTime sleepEnd,
    double? deepSleepHours,
    double? lightSleepHours,
  }) async {
    final response = await _dio.post(
      '/api/v1/sleep/log',
      data: {
        'sleep_start': sleepStart.toIso8601String(),
        'sleep_end': sleepEnd.toIso8601String(),
        if (deepSleepHours != null) 'deep_sleep_hours': deepSleepHours,
        if (lightSleepHours != null) 'light_sleep_hours': lightSleepHours,
      },
      options: Options(contentType: Headers.jsonContentType),
    );
    return SleepRecord.fromJson(response.data);
  }

  /// Get sleep history (most recent first)
  Future<List<SleepRecord>> getHistory({int limit = 30}) async {
    final response = await _dio.get(
      '/api/v1/sleep/history',
      queryParameters: {'limit': limit},
    );
    return (response.data as List).map((e) => SleepRecord.fromJson(e)).toList();
  }

  /// Get aggregated stats for a period ("week" or "month")
  Future<SleepStats> getStats({String period = 'week'}) async {
    final response = await _dio.get(
      '/api/v1/sleep/stats',
      queryParameters: {'period': period},
    );
    return SleepStats.fromJson(response.data);
  }

  /// Get the current alarm configuration
  Future<AlarmConfig?> getAlarm() async {
    try {
      final response = await _dio.get('/api/v1/sleep/alarm');
      return AlarmConfig.fromJson(response.data);
    } on DioException catch (e) {
      if (e.response?.statusCode == 404) return null; // no alarm configured yet
      rethrow;
    }
  }

  /// Create or update the alarm configuration
  Future<AlarmConfig> updateAlarm(AlarmConfig config) async {
    final response = await _dio.put(
      '/api/v1/sleep/alarm',
      data: config.toJson(),
      options: Options(contentType: Headers.jsonContentType),
    );
    return AlarmConfig.fromJson(response.data);
  }
}

/// Riverpod provider — singleton service instance
final sleepServiceProvider = Provider<SleepService>((ref) => SleepService());
