import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:timezone/timezone.dart' as tz;
import 'package:timezone/data/latest_all.dart' as tz;

class NotificationService {
  NotificationService._();
  static final instance = NotificationService._();

  static const _enabledKey = 'notif_enabled';
  static const _hourKey    = 'notif_hour';
  static const _minuteKey  = 'notif_minute';
  static const _notifId    = 1;
  static const _testNotifId = 2;

  final _plugin = FlutterLocalNotificationsPlugin();

  Future<void> init() async {
    tz.initializeTimeZones();

    const android = AndroidInitializationSettings('@mipmap/ic_launcher');
    const ios = DarwinInitializationSettings(
      requestAlertPermission: false,
      requestBadgePermission: false,
      requestSoundPermission: false,
    );

    await _plugin.initialize(
      const InitializationSettings(android: android, iOS: ios),
    );
  }

  Future<bool> isEnabled() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(_enabledKey) ?? false;
  }

  Future<void> setEnabled(bool value) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_enabledKey, value);
    if (value) {
      await scheduleDailyReminder();
    } else {
      await cancelAll();
    }
  }

  Future<(int, int)> getReminderTime() async {
    final prefs = await SharedPreferences.getInstance();
    return (prefs.getInt(_hourKey) ?? 10, prefs.getInt(_minuteKey) ?? 0);
  }

  Future<void> setReminderTime(int hour, int minute) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt(_hourKey, hour);
    await prefs.setInt(_minuteKey, minute);
    if (await isEnabled()) await scheduleDailyReminder();
  }

  Future<bool> requestPermissions() async {
    final android = _plugin.resolvePlatformSpecificImplementation<
        AndroidFlutterLocalNotificationsPlugin>();
    final ios = _plugin.resolvePlatformSpecificImplementation<
        IOSFlutterLocalNotificationsPlugin>();

    bool granted = false;
    if (android != null) {
      // Returns null on Android < 13 where POST_NOTIFICATIONS isn't required —
      // treat null as granted since the permission is automatic on those versions.
      granted = (await android.requestNotificationsPermission()) ?? true;
    }
    if (ios != null) {
      granted = await ios.requestPermissions(alert: true, sound: true) ?? false;
    }
    return granted;
  }

  // One (title, body) pair per weekday — Monday=0 … Sunday=6
  static const _messages = [
    ('Start the week sharp 🧠', 'A quick review keeps your Monday ideas fresh.'),
    ('Tuesday check-in 📌', 'Two minutes on your saves beats forgetting them.'),
    ('Midweek momentum 🔥', 'Halfway through — revisit what matters most.'),
    ('Thursday deep-dive 🔍', 'The best time to re-read something is right now.'),
    ('Friday knowledge boost 📚', 'End the week knowing more than you started.'),
    ('Weekend reading time ☕', 'No rush — just you and your saved links.'),
    ('Sunday reset 🌿', 'Reflect on what you saved this week before the new one begins.'),
  ];

  Future<void> scheduleDailyReminder() async {
    await _plugin.cancel(_notifId);

    final (hour, minute) = await getReminderTime();

    final now = DateTime.now();
    var localTarget = DateTime(now.year, now.month, now.day, hour, minute);
    if (localTarget.isBefore(now)) {
      localTarget = localTarget.add(const Duration(days: 1));
    }
    final scheduledDate = tz.TZDateTime.from(localTarget.toUtc(), tz.UTC);

    // Pick message for the day the notification will actually fire
    final (title, body) = _messages[(localTarget.weekday - 1) % 7];

    const androidDetails = AndroidNotificationDetails(
      'recallr_reminders',
      'Daily Reminders',
      channelDescription: 'Revisit forgotten links',
      importance: Importance.defaultImportance,
      priority: Priority.defaultPriority,
    );

    const iosDetails = DarwinNotificationDetails();

    await _plugin.zonedSchedule(
      _notifId,
      title,
      body,
      scheduledDate,
      const NotificationDetails(android: androidDetails, iOS: iosDetails),
      androidScheduleMode: AndroidScheduleMode.inexact,
      matchDateTimeComponents: DateTimeComponents.time,
      uiLocalNotificationDateInterpretation:
          UILocalNotificationDateInterpretation.absoluteTime,
    );
  }

  Future<void> sendTestNotification() async {
    const androidDetails = AndroidNotificationDetails(
      'recallr_reminders',
      'Daily Reminders',
      channelDescription: 'Revisit forgotten links',
      importance: Importance.high,
      priority: Priority.high,
    );
    await _plugin.show(
      _testNotifId,
      'Test notification 🔔',
      'Recallr notifications are working!',
      const NotificationDetails(
        android: androidDetails,
        iOS: DarwinNotificationDetails(),
      ),
    );
  }

  Future<void> cancelAll() async {
    await _plugin.cancelAll();
  }
}
