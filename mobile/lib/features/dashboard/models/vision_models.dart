// lib/features/dashboard/models/vision_models.dart

/// Data classes for CV monitoring snapshots from the backend.

class VisionSnapshot {
  final int id;
  final String sessionId;
  final DateTime timestamp;
  final String? workMode;
  final double? attentionScore;
  final double? postureScore;
  final double? vigilanceScore;
  final double? stressRiskScore;
  final double? globalFocusScore;

  const VisionSnapshot({
    required this.id,
    required this.sessionId,
    required this.timestamp,
    this.workMode,
    this.attentionScore,
    this.postureScore,
    this.vigilanceScore,
    this.stressRiskScore,
    this.globalFocusScore,
  });

  factory VisionSnapshot.fromJson(Map<String, dynamic> json) {
    return VisionSnapshot(
      id: json['id'] as int,
      sessionId: json['session_id'] as String,
      timestamp: DateTime.parse(json['timestamp'] as String),
      workMode: json['work_mode'] as String?,
      attentionScore: (json['attention_score'] as num?)?.toDouble(),
      postureScore: (json['posture_score'] as num?)?.toDouble(),
      vigilanceScore: (json['vigilance_score'] as num?)?.toDouble(),
      stressRiskScore: (json['stress_risk_score'] as num?)?.toDouble(),
      globalFocusScore: (json['global_focus_score'] as num?)?.toDouble(),
    );
  }
}


class WorkSessionInfo {
  final String id;
  final int? userId;
  final DateTime startTime;
  final DateTime? endTime;
  final bool isActive;
  final Map<String, dynamic>? metadataJson;

  const WorkSessionInfo({
    required this.id,
    this.userId,
    required this.startTime,
    this.endTime,
    required this.isActive,
    this.metadataJson,
  });

  factory WorkSessionInfo.fromJson(Map<String, dynamic> json) {
    final rawMetadata = json['metadata_json'];
    return WorkSessionInfo(
      id: json['id'] as String,
      userId: json['user_id'] as int?,
      startTime: DateTime.parse(json['start_time'] as String),
      endTime: json['end_time'] != null
          ? DateTime.parse(json['end_time'] as String)
          : null,
      isActive: json['is_active'] as bool,
      metadataJson: rawMetadata is Map
          ? Map<String, dynamic>.from(rawMetadata as Map)
          : null,
    );
  }

  Map<String, dynamic>? get finalSummary {
    final metadata = metadataJson;
    if (metadata == null) return null;
    final raw = metadata['final_summary'];
    if (raw is! Map) return null;
    return Map<String, dynamic>.from(raw as Map);
  }
}

class DashboardVisionSummary {
  final int todaySessionCount;
  final int completedSessionCount;
  final int activeSessionCount;
  final double? score;
  final double? focus;
  final double? posture;
  final double? stress;
  final int pauseCount;

  const DashboardVisionSummary({
    required this.todaySessionCount,
    required this.completedSessionCount,
    required this.activeSessionCount,
    required this.score,
    required this.focus,
    required this.posture,
    required this.stress,
    required this.pauseCount,
  });

  const DashboardVisionSummary.empty()
      : todaySessionCount = 0,
        completedSessionCount = 0,
        activeSessionCount = 0,
        score = null,
        focus = null,
        posture = null,
        stress = null,
        pauseCount = 0;

  bool get hasData =>
      score != null ||
      focus != null ||
      posture != null ||
      stress != null ||
      todaySessionCount > 0;

  int get scorePercent => _clampPercent(score);
  int get focusPercent => _clampPercent(focus);
  int get posturePercent => _clampPercent(posture);
  int get stressPercent => _clampPercent(stress);

  double get scoreProgress {
    final normalized = scorePercent / 100;
    if (normalized <= 0) {
      return 0.05;
    }
    return normalized.clamp(0.0, 1.0);
  }

  static int _clampPercent(double? value) {
    if (value == null) return 0;
    final rounded = value.round();
    if (rounded < 0) return 0;
    if (rounded > 100) return 100;
    return rounded;
  }
}
