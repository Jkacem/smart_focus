// lib/features/sleep/services/sleep_service.dart

import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/network/app_dio.dart';
import '../models/sleep_models.dart';

class SleepService {
  SleepService(this._dio);

  final Dio _dio;

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

  Future<List<SleepRecord>> getHistory({int limit = 30}) async {
    final response = await _dio.get(
      '/api/v1/sleep/history',
      queryParameters: {'limit': limit},
    );
    return (response.data as List).map((e) => SleepRecord.fromJson(e)).toList();
  }

  Future<SleepStats> getStats({String period = 'week'}) async {
    final response = await _dio.get(
      '/api/v1/sleep/stats',
      queryParameters: {'period': period},
    );
    return SleepStats.fromJson(response.data);
  }

  Future<AlarmConfig?> getAlarm() async {
    try {
      final response = await _dio.get('/api/v1/sleep/alarm');
      return AlarmConfig.fromJson(response.data);
    } on DioException catch (e) {
      if (e.response?.statusCode == 404) {
        return null;
      }
      rethrow;
    }
  }

  Future<AlarmConfig> updateAlarm(AlarmConfig config) async {
    final response = await _dio.put(
      '/api/v1/sleep/alarm',
      data: config.toJson(),
      options: Options(contentType: Headers.jsonContentType),
    );
    return AlarmConfig.fromJson(response.data);
  }
}

final sleepServiceProvider = Provider<SleepService>((ref) {
  return SleepService(ref.watch(dioProvider));
});
