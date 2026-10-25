
import 'dart:typed_data';

import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/data/latest_all.dart' as tzdata;
import 'package:timezone/timezone.dart' as tz;

import '../models/reminder.dart';
import '../models/task.dart';
import '../utils/date_helpers.dart';

class NotificationService {
  NotificationService._();

  static final NotificationService instance = NotificationService._();

  final FlutterLocalNotificationsPlugin _plugin =
      FlutterLocalNotificationsPlugin();

  bool _ready = false;
  bool _permissionsAsked = false;

  bool get isSupported =>
      !kIsWeb &&
      (defaultTargetPlatform == TargetPlatform.android ||
          defaultTargetPlatform == TargetPlatform.iOS);

  Future<void> init() async {
    if (!isSupported || _ready) return;

    try {
      tzdata.initializeTimeZones();

      await _plugin.initialize(
        settings: const InitializationSettings(
          android: AndroidInitializationSettings('@mipmap/ic_launcher'),
          iOS: DarwinInitializationSettings(
            requestAlertPermission: false,
            requestBadgePermission: false,
            requestSoundPermission: false,
          ),
        ),
      );

      // Tasks are currently stored in memory only.
      await _plugin.cancelAll();

      _ready = true;
      debugPrint('Notification service initialized.');
    } catch (e, stackTrace) {
      debugPrint('Notification init failed: $e');
      debugPrintStack(stackTrace: stackTrace);
    }
  }

  Future<void> _ensurePermissions() async {
    if (_permissionsAsked) return;

    try {
      if (defaultTargetPlatform == TargetPlatform.android) {
        final android = _plugin.resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin>();

        await android?.requestNotificationsPermission();
        await android?.requestExactAlarmsPermission();
      } else if (defaultTargetPlatform == TargetPlatform.iOS) {
        final ios = _plugin.resolvePlatformSpecificImplementation<
            IOSFlutterLocalNotificationsPlugin>();

        await ios?.requestPermissions(
          alert: true,
          badge: true,
          sound: true,
        );
      }

      _permissionsAsked = true;
    } catch (e, stackTrace) {
      debugPrint('Notification permission request failed: $e');
      debugPrintStack(stackTrace: stackTrace);
    }
  }

  Future<void> schedule(Task task) async {
    if (!isSupported) return;

    if (!_ready) {
      await init();
    }

    if (!_ready) {
      debugPrint('Cannot schedule: notification service is not initialized.');
      return;
    }

    await cancel(task.id);

    final reminder = task.reminder;
    final at = task.reminderAt;

    if (reminder == null || at == null || task.done) return;
    if (!at.isAfter(DateTime.now())) return;

    final taskTimeValue = task.time;
    if (taskTimeValue == null) return;

    await _ensurePermissions();

    // Convert the reminder to a timezone-aware date.
    final when = tz.TZDateTime.from(at, tz.local);
    final details = _detailsFor(reminder.type);

    final taskTime = formatTime(
      taskTimeValue.hour,
      taskTimeValue.minute,
    );

    final body = reminder.minutesBefore == 0
        ? "It's time! ($taskTime)"
        : '${formatLead(reminder.minutesBefore, suffix: false)} to go · at $taskTime';

    try {
      await _plugin.zonedSchedule(
        id: task.id,
        title: task.title,
        body: body,
        scheduledDate: when,
        notificationDetails: details,
        androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
      );

      debugPrint('Reminder scheduled for task ${task.id} at $when');
    } on PlatformException catch (e) {
      debugPrint('Exact scheduling failed: $e');

      try {
        await _plugin.zonedSchedule(
          id: task.id,
          title: task.title,
          body: body,
          scheduledDate: when,
          notificationDetails: details,
          androidScheduleMode: AndroidScheduleMode.inexactAllowWhileIdle,
        );

        debugPrint('Reminder scheduled inexactly for task ${task.id}.');
      } catch (fallbackError, stackTrace) {
        debugPrint('Could not schedule reminder: $fallbackError');
        debugPrintStack(stackTrace: stackTrace);
      }
    } catch (e, stackTrace) {
      debugPrint('Could not schedule reminder: $e');
      debugPrintStack(stackTrace: stackTrace);
    }
  }

  Future<void> cancel(int taskId) async {
    if (!_ready) return;

    try {
      await _plugin.cancel(id: taskId);
    } catch (e, stackTrace) {
      debugPrint('Could not cancel reminder: $e');
      debugPrintStack(stackTrace: stackTrace);
    }
  }

  NotificationDetails _detailsFor(ReminderType type) {
    switch (type) {
      case ReminderType.silent:
        return const NotificationDetails(
          android: AndroidNotificationDetails(
            'todo_reminders_silent',
            'Silent reminders',
            channelDescription: 'Quiet reminders: no sound, no vibration',
            importance: Importance.low,
            priority: Priority.low,
            playSound: false,
            enableVibration: false,
          ),
          iOS: DarwinNotificationDetails(
            presentAlert: true,
            presentSound: false,
          ),
        );

      case ReminderType.sound:
        return const NotificationDetails(
          android: AndroidNotificationDetails(
            'todo_reminders_sound',
            'Sound reminders',
            channelDescription: 'Reminders that play a notification sound',
            importance: Importance.high,
            priority: Priority.high,
            playSound: true,
            enableVibration: true,
          ),
          iOS: DarwinNotificationDetails(
            presentAlert: true,
            presentSound: true,
          ),
        );

      case ReminderType.alarm:
        return NotificationDetails(
          android: AndroidNotificationDetails(
            'todo_reminders_alarm',
            'Alarm reminders',
            channelDescription: 'Reminders that keep ringing until dismissed',
            importance: Importance.max,
            priority: Priority.max,
            playSound: true,
            enableVibration: true,
            vibrationPattern:
                Int64List.fromList([0, 800, 400, 800, 400, 800, 400, 800]),
            category: AndroidNotificationCategory.alarm,
            audioAttributesUsage: AudioAttributesUsage.alarm,
            additionalFlags: Int32List.fromList([4]),
          ),
          iOS: const DarwinNotificationDetails(
            presentAlert: true,
            presentSound: true,
            interruptionLevel: InterruptionLevel.timeSensitive,
          ),
        );
    }
  }
}
