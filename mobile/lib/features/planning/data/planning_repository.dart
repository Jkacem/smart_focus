import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../models/planning_models.dart';
import '../services/planning_service.dart';

abstract class PlanningRepository {
  Future<PlanningDayModel> getDay(DateTime day);
  Future<PlanningDayModel> getToday();
  Future<PlanningInsightsModel> getInsights({String period = 'week'});
  Future<List<PlanningExamModel>> getExams();
  Future<PlanningExamModel> createExam({
    required String title,
    required DateTime examDate,
    int? documentId,
  });
  Future<void> deleteExam(int examId);
  Future<PlanningDayModel> generatePlanning({
    required DateTime date,
    int? documentId,
    List<int>? examIds,
    String? weekType,
    Map<String, dynamic>? preferences,
  });
  Future<void> generatePlanningWeek({
    required DateTime date,
    int? documentId,
    List<int>? examIds,
    String? weekType,
    Map<String, dynamic>? preferences,
  });
  Future<PlanningSessionModel> createSession({
    required String subject,
    required DateTime start,
    required DateTime end,
    required String priority,
    int? documentId,
    List<int>? documentIds,
  });
  Future<PlanningSessionModel> updateSessionStatus(int sessionId, String status);
  Future<PlanningSessionModel> updateSessionDocuments(int sessionId, List<int> documentIds);
  Future<PlanningSessionModel> rescheduleSession(int sessionId);
  Future<void> deleteSession(int sessionId);
}

class PlanningRepositoryImpl implements PlanningRepository {
  PlanningRepositoryImpl(this._service);

  final PlanningService _service;

  @override
  Future<PlanningDayModel> getDay(DateTime day) => _service.getDay(day);

  @override
  Future<PlanningDayModel> getToday() => _service.getToday();

  @override
  Future<PlanningInsightsModel> getInsights({String period = 'week'}) {
    return _service.getInsights(period: period);
  }

  @override
  Future<List<PlanningExamModel>> getExams() => _service.getExams();

  @override
  Future<PlanningExamModel> createExam({
    required String title,
    required DateTime examDate,
    int? documentId,
  }) {
    return _service.createExam(
      title: title,
      examDate: examDate,
      documentId: documentId,
    );
  }

  @override
  Future<void> deleteExam(int examId) => _service.deleteExam(examId);

  @override
  Future<PlanningDayModel> generatePlanning({
    required DateTime date,
    int? documentId,
    List<int>? examIds,
    String? weekType,
    Map<String, dynamic>? preferences,
  }) {
    return _service.generatePlanning(
      date: date,
      documentId: documentId,
      examIds: examIds,
      weekType: weekType,
      preferences: preferences,
    );
  }

  @override
  Future<void> generatePlanningWeek({
    required DateTime date,
    int? documentId,
    List<int>? examIds,
    String? weekType,
    Map<String, dynamic>? preferences,
  }) {
    return _service.generatePlanningWeek(
      date: date,
      documentId: documentId,
      examIds: examIds,
      weekType: weekType,
      preferences: preferences,
    );
  }

  @override
  Future<PlanningSessionModel> createSession({
    required String subject,
    required DateTime start,
    required DateTime end,
    required String priority,
    int? documentId,
    List<int>? documentIds,
  }) {
    return _service.createSession(
      subject: subject,
      start: start,
      end: end,
      priority: priority,
      documentId: documentId,
      documentIds: documentIds,
    );
  }

  @override
  Future<PlanningSessionModel> updateSessionStatus(int sessionId, String status) {
    return _service.updateSessionStatus(sessionId, status);
  }

  @override
  Future<PlanningSessionModel> updateSessionDocuments(int sessionId, List<int> documentIds) {
    return _service.updateSessionDocuments(sessionId, documentIds);
  }

  @override
  Future<PlanningSessionModel> rescheduleSession(int sessionId) {
    return _service.rescheduleSession(sessionId);
  }

  @override
  Future<void> deleteSession(int sessionId) => _service.deleteSession(sessionId);
}

final planningRepositoryProvider = Provider<PlanningRepository>((ref) {
  return PlanningRepositoryImpl(ref.watch(planningServiceProvider));
});
