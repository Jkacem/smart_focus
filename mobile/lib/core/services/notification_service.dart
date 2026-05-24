import 'dart:io';

import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/data/latest_all.dart' as tz_data;
import 'package:timezone/timezone.dart' as tz;

class NotificationService {
  static final NotificationService instance = NotificationService._();
  NotificationService._();

  final _plugin = FlutterLocalNotificationsPlugin();

  static const _focusNotifId = 0;
  static const _sleepReminderId = 1;
  static const _focusChannelId = 'focus_alerts';
  static const _sleepChannelId = 'sleep_reminders';

  Future<void> initialize() async {
    tz_data.initializeTimeZones();

    const android = AndroidInitializationSettings('@mipmap/ic_launcher');
    const ios = DarwinInitializationSettings(
      requestAlertPermission: true,
      requestBadgePermission: true,
      requestSoundPermission: true,
    );
    const linux = LinuxInitializationSettings(defaultActionName: 'Open');

    await _plugin.initialize(
      settings: const InitializationSettings(android: android, iOS: ios, linux: linux),
    );

    if (Platform.isAndroid) {
      await _plugin
          .resolvePlatformSpecificImplementation<
              AndroidFlutterLocalNotificationsPlugin>()
          ?.requestNotificationsPermission();
    }
  }

  /// Shows an immediate notification summarising a completed focus session.
  Future<void> showFocusSessionEnd({
    required int focusScore,
    required int durationSeconds,
  }) async {
    final minutes = durationSeconds ~/ 60;
    final good = focusScore >= 70;
    final title = good ? 'Super session !' : 'Session terminee';
    final body = good
        ? 'Score focus : $focusScore/100 en $minutes min. Excellent travail !'
        : 'Score : $focusScore/100 en $minutes min. Continue comme ca !';

    await _plugin.show(
      id: _focusNotifId,
      title: title,
      body: body,
      notificationDetails: const NotificationDetails(
        android: AndroidNotificationDetails(
          _focusChannelId,
          'Alertes Focus',
          channelDescription: 'Notifications de fin de session de concentration',
          importance: Importance.high,
          priority: Priority.high,
        ),
        iOS: DarwinNotificationDetails(),
      ),
    );
  }

  /// Schedules a daily sleep reminder at [hour]:[minute] (local time).
  /// Cancels any existing reminder first.
  Future<void> scheduleSleepReminder({int hour = 21, int minute = 30}) async {
    await cancelSleepReminder();

    final now = tz.TZDateTime.now(tz.local);
    var scheduled = tz.TZDateTime(
      tz.local,
      now.year,
      now.month,
      now.day,
      hour,
      minute,
    );
    if (scheduled.isBefore(now)) {
      scheduled = scheduled.add(const Duration(days: 1));
    }

    await _plugin.zonedSchedule(
      id: _sleepReminderId,
      title: 'Il est temps de dormir',
      body: 'Respectez votre rythme de sommeil pour rester concentre demain.',
      scheduledDate: scheduled,
      notificationDetails: const NotificationDetails(
        android: AndroidNotificationDetails(
          _sleepChannelId,
          'Rappels Sommeil',
          channelDescription:
              'Rappels pour maintenir un rythme de sommeil regulier',
          importance: Importance.defaultImportance,
          priority: Priority.defaultPriority,
        ),
        iOS: DarwinNotificationDetails(),
      ),
      androidScheduleMode: AndroidScheduleMode.inexactAllowWhileIdle,
      matchDateTimeComponents: DateTimeComponents.time,
    );
  }

  Future<void> cancelSleepReminder() => _plugin.cancel(id: _sleepReminderId);
}
