import 'package:flutter/material.dart';

import 'priority.dart';
import 'reminder.dart';

class Task {
  Task({
    required this.title,
    required this.date,
    this.details = '',
    this.time,
    this.priority = Priority.medium,
    this.reminder,
    this.done = false,
    int? id,
  }) : id = id ?? _nextId++;

  static int _nextId = 0;

  final int id;
  final String title;
  final String details;
  final DateTime date;
  final TimeOfDay? time;
  final Priority priority;

  /// Only meaningful when [time] is set.
  final Reminder? reminder;
  bool done;

  /// Minutes since midnight. Tasks without a time sort after all timed ones.
  int get minutes =>
      time == null ? 24 * 60 + 1 : time!.hour * 60 + time!.minute;

  /// The exact moment the reminder should fire, or null if there is none.
  DateTime? get reminderAt {
    if (reminder == null || time == null) return null;
    return DateTime(date.year, date.month, date.day, time!.hour, time!.minute)
        .subtract(Duration(minutes: reminder!.minutesBefore));
  }
}
