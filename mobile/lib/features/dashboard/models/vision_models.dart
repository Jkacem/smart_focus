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
    return WorkSessionInfo(
      id: json['id'] as String,
      userId: json['user_id'] as int?,
      startTime: DateTime.parse(json['start_time'] as String),
      endTime: json['end_time'] != null
          ? DateTime.parse(json['end_time'] as String)
          : null,
      isActive: json['is_active'] as bool,
      metadataJson: json['metadata_json'] as Map<String, dynamic>?,
    );
  }
}
