import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/network/app_dio.dart';
import '../../../shared/utils/document_link_utils.dart';
import '../models/planning_models.dart';

class PlanningService {
  PlanningService(this._dio);

  final Dio _dio;

  Future<PlanningDayModel> getDay(DateTime day) async {
    final response = await _dio.get('/api/v1/planning/${_formatDay(day)}');
    return PlanningDayModel.fromJson(response.data as Map<String, dynamic>);
  }

  Future<PlanningDayModel> getToday() async {
    final response = await _dio.get('/api/v1/planning/today');
    return PlanningDayModel.fromJson(response.data as Map<String, dynamic>);
  }

  Future<PlanningInsightsModel> getInsights({String period = 'week'}) async {
    final response = await _dio.get(
      '/api/v1/planning/insights',
      queryParameters: {'period': period},
    );
    return PlanningInsightsModel.fromJson(response.data as Map<String, dynamic>);
  }

  Future<List<PlanningExamModel>> getExams() async {
    final response = await _dio.get('/api/v1/planning/exams');
    final items = response.data as List? ?? const [];
    return items
        .map((item) => PlanningExamModel.fromJson(item as Map<String, dynamic>))
        .toList();
  }

  Future<PlanningExamModel> createExam({
    required String title,
    required DateTime examDate,
    int? documentId,
  }) async {
    final response = await _dio.post(
      '/api/v1/planning/exams',
      data: {
        'title': title,
        'exam_date': _formatDay(examDate),
        if (documentId != null) 'document_id': documentId,
      },
      options: Options(contentType: Headers.jsonContentType),
    );
    return PlanningExamModel.fromJson(response.data as Map<String, dynamic>);
  }

  Future<void> deleteExam(int examId) async {
    await _dio.delete('/api/v1/planning/exams/$examId');
  }

  Future<PlanningDayModel> generatePlanning({
    required DateTime date,
    int? documentId,
    List<int>? examIds,
    String? weekType,
    Map<String, dynamic>? preferences,
  }) async {
    final response = await _dio.post(
      '/api/v1/planning/generate',
      data: _buildGeneratePayload(
        date: date,
        documentId: documentId,
        examIds: examIds,
        weekType: weekType,
        preferences: preferences,
      ),
      options: Options(contentType: Headers.jsonContentType),
    );

    return PlanningDayModel.fromJson(response.data as Map<String, dynamic>);
  }

  Future<void> generatePlanningWeek({
    required DateTime date,
    int? documentId,
    List<int>? examIds,
    String? weekType,
    Map<String, dynamic>? preferences,
  }) async {
    await _dio.post(
      '/api/v1/planning/generate/week',
      data: _buildGeneratePayload(
        date: date,
        documentId: documentId,
        examIds: examIds,
        weekType: weekType,
        preferences: preferences,
      ),
      options: Options(contentType: Headers.jsonContentType),
    );
  }

  Future<PlanningSessionModel> createSession({
    required String subject,
    required DateTime start,
    required DateTime end,
    required String priority,
    int? documentId,
    List<int>? documentIds,
  }) async {
    final response = await _dio.post(
      '/api/v1/planning/sessions',
      data: {
        'subject': subject,
        'start': start.toIso8601String(),
        'end': end.toIso8601String(),
        'priority': priority,
        if (documentId != null || documentIds != null)
          ...buildLinkedDocumentPayload(
            resolveDocumentIds(
              documentIds ?? const [],
              primaryDocumentId: documentId,
            ),
          ),
      },
      options: Options(contentType: Headers.jsonContentType),
    );

    return PlanningSessionModel.fromJson(response.data as Map<String, dynamic>);
  }

  Future<PlanningSessionModel> completeSession(int sessionId) async {
    final response = await _dio.patch('/api/v1/planning/sessions/$sessionId/complete');
    return PlanningSessionModel.fromJson(response.data as Map<String, dynamic>);
  }

  Future<PlanningSessionModel> updateSessionStatus(
    int sessionId,
    String status,
  ) async {
    final response = await _dio.patch(
      '/api/v1/planning/sessions/$sessionId',
      data: {
        'status': status,
      },
      options: Options(contentType: Headers.jsonContentType),
    );
    return PlanningSessionModel.fromJson(response.data as Map<String, dynamic>);
  }

  Future<PlanningSessionModel> updateSessionDocuments(
    int sessionId,
    List<int> documentIds,
  ) async {
    final response = await _dio.patch(
      '/api/v1/planning/sessions/$sessionId',
      data: buildLinkedDocumentPayload(documentIds),
      options: Options(contentType: Headers.jsonContentType),
    );
    return PlanningSessionModel.fromJson(response.data as Map<String, dynamic>);
  }

  Future<PlanningSessionModel> rescheduleSession(int sessionId) async {
    final response = await _dio.post('/api/v1/planning/reschedule/$sessionId');
    return PlanningSessionModel.fromJson(response.data as Map<String, dynamic>);
  }

  Future<void> deleteSession(int sessionId) async {
    await _dio.delete('/api/v1/planning/sessions/$sessionId');
  }

  String _formatDay(DateTime day) {
    final normalized = DateTime(day.year, day.month, day.day);
    final month = normalized.month.toString().padLeft(2, '0');
    final date = normalized.day.toString().padLeft(2, '0');
    return '${normalized.year}-$month-$date';
  }

  Map<String, dynamic> _buildGeneratePayload({
    required DateTime date,
    int? documentId,
    List<int>? examIds,
    String? weekType,
    Map<String, dynamic>? preferences,
  }) {
    return {
      'date': _formatDay(date),
      if (preferences != null && preferences.isNotEmpty) 'preferences': preferences,
      if (documentId != null) 'document_id': documentId,
      if (examIds != null) 'exam_ids': examIds,
      if (weekType != null) 'week_type': weekType,
    };
  }
}

final planningServiceProvider = Provider<PlanningService>((ref) {
  return PlanningService(ref.watch(dioProvider));
});
