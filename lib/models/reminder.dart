import 'package:flutter/material.dart';

import '../utils/date_helpers.dart';

/// How loudly a reminder announces itself.
enum ReminderType {
  silent(
    'Silent',
    'Quiet notification',
    Icons.volume_off_rounded,
    Color(0xFF5C7C99),
  ),
  sound(
    'Sound',
    'Notification + sound',
    Icons.notifications_active_rounded,
    Color(0xFF7C4DFF),
  ),
  alarm(
    'Alarm',
    'Rings until you stop it',
    Icons.alarm_rounded,
    Color(0xFFE5365F),
  );

  const ReminderType(this.label, this.caption, this.icon, this.color);

  final String label;
  final String caption;
  final IconData icon;
  final Color color;
}

/// A reminder attached to a task: how long before the task time, and what kind.
class Reminder {
  const Reminder({required this.minutesBefore, required this.type});

  /// Quick choices offered in the sheet (minutes before the task).
  static const presets = [0, 5, 10, 15, 30, 60, 120, 1440];

  final int minutesBefore;
  final ReminderType type;

  String get summary => '${formatLead(minutesBefore)} · ${type.label}';
}
