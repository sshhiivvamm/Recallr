import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../services/notification_service.dart';

class NotifNotifier extends StateNotifier<bool> {
  NotifNotifier() : super(false) {
    _load();
  }

  Future<void> _load() async {
    state = await NotificationService.instance.isEnabled();
  }

  Future<void> toggle(bool val) async {
    if (val) {
      final granted =
          await NotificationService.instance.requestPermissions();
      if (!granted) return;
    }
    await NotificationService.instance.setEnabled(val);
    state = val;
  }
}

final notifEnabledProvider = StateNotifierProvider<NotifNotifier, bool>(
  (ref) => NotifNotifier(),
);

class ReminderTimeNotifier extends StateNotifier<TimeOfDay> {
  ReminderTimeNotifier() : super(const TimeOfDay(hour: 10, minute: 0)) {
    _load();
  }

  Future<void> _load() async {
    final (h, m) = await NotificationService.instance.getReminderTime();
    state = TimeOfDay(hour: h, minute: m);
  }

  Future<void> update(int hour, int minute) async {
    await NotificationService.instance.setReminderTime(hour, minute);
    state = TimeOfDay(hour: hour, minute: minute);
  }
}

final reminderTimeProvider =
    StateNotifierProvider<ReminderTimeNotifier, TimeOfDay>(
  (ref) => ReminderTimeNotifier(),
);
