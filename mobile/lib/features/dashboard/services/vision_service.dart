// lib/features/dashboard/services/vision_service.dart

import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/network/app_dio.dart';
import '../models/vision_models.dart';

class VisionService {
  VisionService(this._dio);

  final Dio _dio;

  /// Fetch the list of CV work sessions.
  Future<List<WorkSessionInfo>> listSessions({int limit = 20}) async {
    final response = await _dio.get(
      '/api/v1/sessions',
      queryParameters: {'limit': limit},
    );
    return (response.data as List)
        .map((json) => WorkSessionInfo.fromJson(json))
        .toList();
  }

  /// Fetch the latest snapshot for a given session.
  Future<VisionSnapshot?> getLatestSnapshot(String sessionId) async {
    try {
      final response = await _dio.get(
        '/api/v1/sessions/$sessionId/latest',
      );
      return VisionSnapshot.fromJson(response.data);
    } on DioException catch (e) {
      if (e.response?.statusCode == 404) {
        return null; // No snapshots yet
      }
      rethrow;
    }
  }

  /// Create or ensure a work session exists.
  Future<WorkSessionInfo> createSession(String sessionId) async {
    final response = await _dio.post(
      '/api/v1/sessions',
      data: {'id': sessionId},
    );
    return WorkSessionInfo.fromJson(response.data);
  }

  /// Finalize (stop) a session.
  Future<WorkSessionInfo> finalizeSession(String sessionId) async {
    final response = await _dio.post(
      '/api/v1/sessions/$sessionId/finalize',
      data: {},
    );
    return WorkSessionInfo.fromJson(response.data);
  }
}

final visionServiceProvider = Provider<VisionService>((ref) {
  return VisionService(ref.watch(dioProvider));
});
