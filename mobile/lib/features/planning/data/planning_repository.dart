import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../models/planning_models.dart';
import '../services/planning_service.dart';

abstract class PlanningRepository {
  Future<PlanningDayModel> getDay(DateTime day);
  Future<PlanningDayModel> getToday();
  Future<PlanningInsightsModel> getInsights({String period = 'week'});
  Future<PlanningDayModel> generatePlanning({
    required DateTime date,
    int? documentId,
    String? weekType,
    Map<String, dynamic>? preferences,
  });
  Future<void> generatePlanningWeek({
    required DateTime date,
    int? documentId,
    String? weekType,
    Map<String, dynamic>? preferences,
  });
  Future<PlanningSessionModel> createSession({
    required String subject,
    required DateTime start,
    required DateTime end,
    required String priority,
    int? documentId,
  });
  Future<PlanningSessionModel> updateSessionStatus(int sessionId, String status);
  Future<PlanningSessionModel> updateSessionDocument(int sessionId, int? documentId);
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
  Future<PlanningDayModel> generatePlanning({
    required DateTime date,
    int? documentId,
    String? weekType,
    Map<String, dynamic>? preferences,
  }) {
    return _service.generatePlanning(
      date: date,
      documentId: documentId,
      weekType: weekType,
      preferences: preferences,
    );
  }

  @override
  Future<void> generatePlanningWeek({
    required DateTime date,
    int? documentId,
    String? weekType,
    Map<String, dynamic>? preferences,
  }) {
    return _service.generatePlanningWeek(
      date: date,
      documentId: documentId,
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
  }) {
    return _service.createSession(
      subject: subject,
      start: start,
      end: end,
      priority: priority,
      documentId: documentId,
    );
  }

  @override
  Future<PlanningSessionModel> updateSessionStatus(int sessionId, String status) {
    return _service.updateSessionStatus(sessionId, status);
  }

  @override
  Future<PlanningSessionModel> updateSessionDocument(int sessionId, int? documentId) {
    return _service.updateSessionDocument(sessionId, documentId);
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
