class CurrentUserProfile {
  final int id;
  final String email;
  final String fullName;
  final String role;
  final int dailyFocusGoal;
  final String preferredSchedule;
  final String? avatarDataUrl;
  final bool notifEnabled;
  final Map<String, dynamic> notifPreferences;

  const CurrentUserProfile({
    required this.id,
    required this.email,
    required this.fullName,
    required this.role,
    required this.dailyFocusGoal,
    required this.preferredSchedule,
    required this.avatarDataUrl,
    required this.notifEnabled,
    required this.notifPreferences,
  });

  factory CurrentUserProfile.fromJson(Map<String, dynamic> json) {
    final rawPreferences = json['notif_preferences'];
    final notifPreferences = rawPreferences is Map<String, dynamic>
        ? rawPreferences
        : rawPreferences is Map
        ? Map<String, dynamic>.from(rawPreferences)
        : <String, dynamic>{};

    return CurrentUserProfile(
      id: json['id'] as int,
      email: json['email']?.toString() ?? '',
      fullName: json['full_name']?.toString() ?? '',
      role: json['role']?.toString() ?? 'student',
      dailyFocusGoal: json['daily_focus_goal'] as int? ?? 120,
      preferredSchedule: json['preferred_schedule']?.toString() ?? 'morning',
      avatarDataUrl: json['avatar_data_url']?.toString(),
      notifEnabled: json['notif_enabled'] as bool? ?? true,
      notifPreferences: notifPreferences,
    );
  }

  bool get focusAlertsEnabled =>
      notifPreferences['focus_alerts'] as bool? ?? true;

  bool get sleepRemindersEnabled =>
      notifPreferences['sleep_reminders'] as bool? ?? true;
}

class CurrentUserProfileUpdateInput {
  final String fullName;
  final String role;
  final int dailyFocusGoal;
  final String preferredSchedule;
  final String? avatarDataUrl;
  final bool notifEnabled;
  final bool focusAlerts;
  final bool sleepReminders;

  const CurrentUserProfileUpdateInput({
    required this.fullName,
    required this.role,
    required this.dailyFocusGoal,
    required this.preferredSchedule,
    required this.avatarDataUrl,
    required this.notifEnabled,
    required this.focusAlerts,
    required this.sleepReminders,
  });

  Map<String, dynamic> toJson() {
    return {
      'full_name': fullName,
      'role': role,
      'daily_focus_goal': dailyFocusGoal,
      'preferred_schedule': preferredSchedule,
      'avatar_data_url': avatarDataUrl,
      'notif_enabled': notifEnabled,
      'notif_preferences': {
        'focus_alerts': focusAlerts,
        'sleep_reminders': sleepReminders,
      },
    };
  }
}
