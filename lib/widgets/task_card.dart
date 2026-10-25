import 'package:flutter/material.dart';

import '../models/task.dart';
import '../utils/date_helpers.dart';
import 'info_pill.dart';

class TaskCard extends StatelessWidget {
  const TaskCard({
    super.key,
    required this.task,
    required this.onToggle,
    required this.onEdit,
    required this.onDelete,
  });

  final Task task;
  final ValueChanged<bool?> onToggle;
  final VoidCallback onEdit;
  final VoidCallback onDelete;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final done = task.done;
    final decoration = done ? TextDecoration.lineThrough : TextDecoration.none;
    final accent = done ? scheme.outline : task.priority.color;
    final reminder = task.reminder;

    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(18),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF7C4DFF).withValues(alpha: done ? 0.03 : 0.10),
            blurRadius: 14,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(18),
        child: Material(
          color: done ? const Color(0xFFF0EDF8) : Colors.white,
          child: IntrinsicHeight(
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // Priority strip.
                Container(width: 6, color: accent),
                Expanded(
                  child: ListTile(
                    contentPadding: const EdgeInsets.only(
                      left: 8,
                      right: 4,
                      top: 4,
                      bottom: 4,
                    ),
                    onTap: () => onToggle(!done),
                    leading: Checkbox(
                      value: done,
                      onChanged: onToggle,
                      activeColor: accent,
                      shape: const CircleBorder(),
                      side: BorderSide(color: accent, width: 2),
                    ),
                    title: Text(
                      task.title,
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w700,
                        color: done ? scheme.outline : const Color(0xFF2B2250),
                        decoration: decoration,
                      ),
                    ),
                    subtitle: Padding(
                      padding: const EdgeInsets.only(top: 4),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          if (task.details.isNotEmpty) ...[
                            Text(
                              task.details,
                              style: TextStyle(
                                color: done
                                    ? scheme.outline
                                    : scheme.onSurfaceVariant,
                                decoration: decoration,
                              ),
                            ),
                            const SizedBox(height: 8),
                          ],
                          Wrap(
                            spacing: 8,
                            runSpacing: 6,
                            children: [
                              if (task.time != null)
                                InfoPill(
                                  icon: Icons.access_time_rounded,
                                  label: task.time!.format(context),
                                  color: done ? scheme.outline : scheme.primary,
                                ),
                              InfoPill(
                                icon: Icons.flag_rounded,
                                label: task.priority.label,
                                color: accent,
                              ),
                              if (reminder != null)
                                InfoPill(
                                  icon: reminder.type.icon,
                                  label: reminder.minutesBefore == 0
                                      ? 'At time · ${reminder.type.label}'
                                      : '${formatLead(reminder.minutesBefore, suffix: false)} · ${reminder.type.label}',
                                  color:
                                      done ? scheme.outline : reminder.type.color,
                                ),
                            ],
                          ),
                        ],
                      ),
                    ),
                    trailing: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        IconButton(
                          icon: const Icon(Icons.edit_outlined),
                          tooltip: 'Edit task',
                          onPressed: onEdit,
                        ),
                        IconButton(
                          icon: Icon(Icons.delete_outline, color: scheme.error),
                          tooltip: 'Delete task',
                          onPressed: onDelete,
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
