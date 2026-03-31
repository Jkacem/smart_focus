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
