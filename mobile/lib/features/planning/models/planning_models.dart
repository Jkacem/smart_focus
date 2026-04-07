import 'package:smart_focus/shared/utils/document_link_utils.dart';

class PlanningExamModel {
  final int id;
  final int userId;
  final String title;
  final DateTime examDate;
  final int? documentId;
  final String? documentName;
  final DateTime createdAt;
  final DateTime updatedAt;

  const PlanningExamModel({
    required this.id,
    required this.userId,
    required this.title,
    required this.examDate,
    required this.documentId,
    required this.documentName,
    required this.createdAt,
    required this.updatedAt,
  });

  factory PlanningExamModel.fromJson(Map<String, dynamic> json) {
    return PlanningExamModel(
      id: json['id'] as int,
      userId: json['user_id'] as int,
      title: json['title']?.toString() ?? '',
      examDate: _parseDate(json['exam_date']?.toString()),
      documentId: json['document_id'] as int?,
      documentName: json['document_name']?.toString(),
      createdAt: _parseDateTime(json['created_at']?.toString()),
      updatedAt: _parseDateTime(json['updated_at']?.toString()),
    );
  }

  int get daysUntilExam {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    return examDate.difference(today).inDays;
  }

  String get countdownLabel {
    if (daysUntilExam <= 0) {
      return 'Aujourd hui';
    }
    if (daysUntilExam == 1) {
      return 'Demain';
    }
    return 'Dans $daysUntilExam jours';
  }
}

class PlanningDayModel {
  final DateTime date;
  final List<PlanningSessionModel> sessions;

  const PlanningDayModel({
    required this.date,
    required this.sessions,
  });

  factory PlanningDayModel.fromJson(Map<String, dynamic> json) {
    final planning = json['planning'] as Map<String, dynamic>? ?? const {};
    final sessionsJson = json['sessions'] as List? ?? const [];

    return PlanningDayModel(
      date: _parseDate(planning['date']?.toString()),
      sessions: sessionsJson
          .map((item) => PlanningSessionModel.fromJson(item as Map<String, dynamic>))
          .toList(),
    );
  }
}

class PlanningInsightsModel {
  final String period;
  final int totalStudyMinutes;
  final int completedSessions;
  final int skippedSessions;
  final double completionRate;
  final double? avgSleepScore;
  final String sleepStudyCorrelation;
  final String? weakestSubject;
  final String? strongestSubject;
  final String recommendation;

  const PlanningInsightsModel({
    required this.period,
    required this.totalStudyMinutes,
    required this.completedSessions,
    required this.skippedSessions,
    required this.completionRate,
    required this.avgSleepScore,
    required this.sleepStudyCorrelation,
    required this.weakestSubject,
    required this.strongestSubject,
    required this.recommendation,
  });

  factory PlanningInsightsModel.fromJson(Map<String, dynamic> json) {
    return PlanningInsightsModel(
      period: json['period']?.toString() ?? 'week',
      totalStudyMinutes: json['total_study_minutes'] as int? ?? 0,
      completedSessions: json['completed_sessions'] as int? ?? 0,
      skippedSessions: json['skipped_sessions'] as int? ?? 0,
      completionRate: (json['completion_rate'] as num?)?.toDouble() ?? 0,
      avgSleepScore: (json['avg_sleep_score'] as num?)?.toDouble(),
      sleepStudyCorrelation:
          json['sleep_study_correlation']?.toString() ?? 'insufficient_data',
      weakestSubject: json['weakest_subject']?.toString(),
      strongestSubject: json['strongest_subject']?.toString(),
      recommendation: json['recommendation']?.toString() ?? '',
    );
  }

  String get studyHoursLabel {
    final hours = totalStudyMinutes ~/ 60;
    final minutes = totalStudyMinutes % 60;
    if (hours > 0 && minutes > 0) {
      return '${hours}h${minutes.toString().padLeft(2, '0')}';
    }
    if (hours > 0) {
      return '${hours}h';
    }
    return '${minutes}min';
  }

  int get completionRatePercent => (completionRate * 100).round();

  String get periodLabel => period == 'month' ? 'Mois' : 'Semaine';

  int get trackedSessions => completedSessions + skippedSessions;

  bool get hasAdaptiveSchedulingHistory => trackedSessions >= 3;

  String get adaptiveSchedulingLabel =>
      hasAdaptiveSchedulingHistory ? 'Horaires adaptes' : 'Apprentissage en cours';

  String get adaptiveSchedulingHint {
    if (hasAdaptiveSchedulingHistory) {
      return 'Les prochaines revisions privilegient vos heures de completion les plus fiables.';
    }
    return 'Validez encore quelques sessions pour que les prochaines revisions s adaptent automatiquement a vos meilleurs horaires.';
  }

  String get sleepCorrelationLabel {
    switch (sleepStudyCorrelation) {
      case 'positive':
        return 'Correlation positive';
      case 'negative':
        return 'Correlation negative';
      case 'neutral':
        return 'Correlation neutre';
      default:
        return 'Donnees insuffisantes';
    }
  }
}

class PlanningSessionModel {
  final int id;
  final int userId;
  final DateTime date;
  final String subject;
  final DateTime start;
  final DateTime end;
  final String priority;
  final String status;
  final String? notes;
  final int? documentId;
  final String? documentName;
  final List<int> documentIds;
  final List<String> documentNames;
  final int? sessionQuizId;
  final String sessionQuizStatus;
  final int sessionFlashcardsTotal;
  final int sessionFlashcardsDue;
  final int sessionFlashcardsReviewed;
  final String sessionFlashcardsStatus;
  final bool isAiGenerated;
  final DateTime? completedAt;
  final DateTime createdAt;
  final DateTime updatedAt;

  const PlanningSessionModel({
    required this.id,
    required this.userId,
    required this.date,
    required this.subject,
    required this.start,
    required this.end,
    required this.priority,
    required this.status,
    required this.notes,
    required this.documentId,
    required this.documentName,
    required this.documentIds,
    required this.documentNames,
    required this.sessionQuizId,
    required this.sessionQuizStatus,
    required this.sessionFlashcardsTotal,
    required this.sessionFlashcardsDue,
    required this.sessionFlashcardsReviewed,
    required this.sessionFlashcardsStatus,
    required this.isAiGenerated,
    required this.completedAt,
    required this.createdAt,
    required this.updatedAt,
  });

  factory PlanningSessionModel.fromJson(Map<String, dynamic> json) {
    return PlanningSessionModel(
      id: json['id'] as int,
      userId: json['user_id'] as int,
      date: _parseDate(json['date']?.toString()),
      subject: json['subject']?.toString() ?? '',
      start: _parseDateTime(json['start']?.toString()),
      end: _parseDateTime(json['end']?.toString()),
      priority: json['priority']?.toString() ?? 'medium',
      status: json['status']?.toString() ?? 'pending',
      notes: json['notes']?.toString(),
      documentId: json['document_id'] as int?,
      documentName: json['document_name']?.toString(),
      documentIds: List<int>.from(json['document_ids'] ?? const []),
      documentNames: List<String>.from(json['document_names'] ?? const []),
      sessionQuizId: json['session_quiz_id'] as int?,
      sessionQuizStatus: json['session_quiz_status']?.toString() ?? 'not_started',
      sessionFlashcardsTotal: json['session_flashcards_total'] as int? ?? 0,
      sessionFlashcardsDue: json['session_flashcards_due'] as int? ?? 0,
      sessionFlashcardsReviewed: json['session_flashcards_reviewed'] as int? ?? 0,
      sessionFlashcardsStatus:
          json['session_flashcards_status']?.toString() ?? 'not_started',
      isAiGenerated: json['is_ai_generated'] as bool? ?? false,
      completedAt: json['completed_at'] == null
          ? null
          : _parseDateTime(json['completed_at'].toString()),
      createdAt: _parseDateTime(json['created_at']?.toString()),
      updatedAt: _parseDateTime(json['updated_at']?.toString()),
    );
  }

  Duration get duration => end.difference(start);

  bool get isCompleted => status == 'completed';

  bool get isCancelled => status == 'cancelled';

  bool get isMissed =>
      !isCompleted &&
      !isCancelled &&
      end.isBefore(DateTime.now());

  bool get canBeRescheduled => isCancelled || isMissed;

  bool get hasLinkedDocument =>
      resolvedDocumentIds.isNotEmpty;

  List<int> get resolvedDocumentIds =>
      resolveDocumentIds(documentIds, primaryDocumentId: documentId);

  int get linkedDocumentCount {
    return resolvedDocumentIds.length;
  }

  String? get linkedDocumentSummary {
    if (!hasLinkedDocument && documentName == null) {
      return null;
    }
    return summarizeDocumentNames(
      documentNames,
      fallbackName: documentName,
    );
  }

  bool get hasSavedQuiz => sessionQuizId != null;

  bool get quizCompleted => sessionQuizStatus == 'completed';

  bool get quizStarted =>
      sessionQuizStatus == 'in_progress' || sessionQuizStatus == 'completed';

  bool get hasSavedFlashcards => sessionFlashcardsTotal > 0;

  bool get flashcardsCompleted => sessionFlashcardsStatus == 'completed';

  bool get flashcardsStarted =>
      sessionFlashcardsStatus == 'generated' ||
      sessionFlashcardsStatus == 'in_progress' ||
      sessionFlashcardsStatus == 'completed';

  String get _normalizedSubject => subject.trim().toLowerCase();

  bool get isFlashcardReviewSession =>
      _normalizedSubject.startsWith('revision flashcards:');

  bool get isQuizRevisionSession =>
      _normalizedSubject.startsWith('revision quiz:');

  bool get isExamCountdownSession =>
      _normalizedSubject.startsWith('revision examen:');

  bool get isSmartRevisionSession =>
      isFlashcardReviewSession || isQuizRevisionSession || isExamCountdownSession;

  String? get smartSessionLabel {
    if (isFlashcardReviewSession) {
      return 'Flashcards';
    }
    if (isQuizRevisionSession) {
      return 'Quiz cible';
    }
    if (isExamCountdownSession) {
      return 'Compte a rebours';
    }
    if (isAiGenerated && _normalizedSubject.startsWith('revision:')) {
      return 'Revision IA';
    }
    return null;
  }

  String? get smartSessionHint {
    if (isFlashcardReviewSession) {
      return hasLinkedDocument
          ? 'Des cartes sont dues pour ce document. Lance la revision directement depuis cette carte.'
          : 'Des cartes sont dues pour cette session de revision.';
    }
    if (isQuizRevisionSession) {
      return hasLinkedDocument
          ? 'Ce document a ete priorise a cause de recents scores plus faibles.'
          : 'Cette session a ete priorisee a partir des performances recentes.';
    }
    if (isExamCountdownSession) {
      return hasLinkedDocument
          ? 'Cette revision est renforcee automatiquement a mesure que l examen approche.'
          : 'Le planificateur intensifie cette revision a l approche de l examen.';
    }
    if (isAiGenerated && _normalizedSubject.startsWith('revision:')) {
      return 'Session de revision ajoutee automatiquement par le planificateur.';
    }
    return null;
  }

  String get priorityLabel {
    switch (priority) {
      case 'high':
        return 'Haute priorite';
      case 'low':
        return 'Faible priorite';
      default:
        return 'Priorite moyenne';
    }
  }

  String get priorityIcon {
    switch (priority) {
      case 'high':
        return '!!';
      case 'low':
        return '--';
      default:
        return '==';
    }
  }

  String get statusLabel {
    switch (status) {
      case 'completed':
        return 'Terminee';
      case 'in_progress':
        return 'En cours';
      case 'cancelled':
        return 'Annulee';
      default:
        return 'A faire';
    }
  }

  double get progress {
    switch (status) {
      case 'completed':
        return 1;
      case 'in_progress':
        return 0.55;
      case 'cancelled':
        return 0;
      default:
        return 0.15;
    }
  }
}

DateTime _parseDate(String? value) {
  if (value == null || value.isEmpty) {
    final now = DateTime.now();
    return DateTime(now.year, now.month, now.day);
  }

  final parsed = DateTime.parse(value);
  return DateTime(parsed.year, parsed.month, parsed.day);
}

DateTime _parseDateTime(String? value) {
  if (value == null || value.isEmpty) {
    return DateTime.now();
  }

  final parsed = DateTime.parse(value);
  return parsed.isUtc ? parsed.toLocal() : parsed;
}
