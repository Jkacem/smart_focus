/// Shared utilities for CV work-session identification.

/// Returns `true` for IDs that represent a synthetic planning-only session
/// (i.e. not a real CV work session from the pi_client).
bool isSyntheticPlanningSessionId(String id) {
  return id.startsWith('plan-') || id.startsWith('planning-');
}

/// Extracts the planning session ID from work-session metadata, if present.
int? planningSessionIdFromMetadata(Map<String, dynamic>? metadata) {
  final value = metadata?['planning_session_id'];
  if (value is int) return value;
  if (value is num) return value.toInt();
  if (value is String) return int.tryParse(value);
  return null;
}

/// Extracts a human-readable title from work-session metadata by checking
/// several candidate keys in order of preference.
String? planningSessionTitleFromMetadata(Map<String, dynamic>? metadata) {
  const candidates = <String>[
    'subject',
    'planning_session_subject',
    'session_subject',
    'title',
  ];
  for (final key in candidates) {
    final value = metadata?[key];
    if (value is String && value.trim().isNotEmpty) {
      return value.trim();
    }
  }
  return null;
}
