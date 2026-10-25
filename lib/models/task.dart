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
  }) : id = id ?? _nextId++ {
    // Keep newly-created IDs unique after restoring saved tasks.
    if (id != null && id >= _nextId) {
      _nextId = id + 1;
    }
  }

  static int _nextId = 0;

  final int id;
  final String title;
  final String details;
  final DateTime date;
  final TimeOfDay? time;
  final Priority priority;
  final Reminder? reminder;
  bool done;

  int get minutes =>
      time == null ? 24 * 60 + 1 : time!.hour * 60 + time!.minute;

  DateTime? get reminderAt {
    if (reminder == null || time == null) return null;
    return DateTime(date.year, date.month, date.day, time!.hour, time!.minute)
        .subtract(Duration(minutes: reminder!.minutesBefore));
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'title': title,
        'details': details,
        'date': date.toIso8601String(),
        'timeHour': time?.hour,
        'timeMinute': time?.minute,
        'priority': priority.name,
        'done': done,
        'reminder': reminder == null
            ? null
            : {
                'minutesBefore': reminder!.minutesBefore,
                'type': reminder!.type.name,
              },
      };

  factory Task.fromJson(Map<String, dynamic> json) {
    final reminderJson = json['reminder'] as Map<String, dynamic>?;
    final timeHour = json['timeHour'] as int?;
    final timeMinute = json['timeMinute'] as int?;

    final priorityName = json['priority'] as String?;
    final priority = Priority.values.firstWhere(
      (value) => value.name == priorityName,
      orElse: () => Priority.medium,
    );

    Reminder? reminder;
    if (reminderJson != null) {
      final typeName = reminderJson['type'] as String?;
      final type = ReminderType.values.firstWhere(
        (value) => value.name == typeName,
        orElse: () => ReminderType.sound,
      );
      reminder = Reminder(
        minutesBefore: reminderJson['minutesBefore'] as int? ?? 10,
        type: type,
      );
    }

    return Task(
      id: json['id'] as int?,
      title: json['title'] as String? ?? '',
      details: json['details'] as String? ?? '',
      date: DateTime.parse(json['date'] as String),
      time: timeHour == null || timeMinute == null
          ? null
          : TimeOfDay(hour: timeHour, minute: timeMinute),
      priority: priority,
      reminder: reminder,
      done: json['done'] as bool? ?? false,
    );
  }
}
