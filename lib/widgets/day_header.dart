import 'package:flutter/material.dart';

import '../models/sort_mode.dart';
import '../models/task.dart';
import '../theme/app_colors.dart';
import '../utils/date_helpers.dart';

/// Title of the selected day, its progress, and the calendar / sort buttons.
class DayHeader extends StatelessWidget {
  const DayHeader({
    super.key,
    required this.date,
    required this.tasks,
    required this.sortMode,
    required this.onPickDate,
    required this.onSortChanged,
  });

  final DateTime date;

  /// Tasks of the selected day (used for the counter).
  final List<Task> tasks;
  final SortMode sortMode;
  final VoidCallback onPickDate;
  final ValueChanged<SortMode> onSortChanged;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    final total = tasks.length;
    final remaining = tasks.where((t) => !t.done).length;
    final allDone = total > 0 && remaining == 0;
    final counts = total == 0
        ? 'No tasks'
        : allDone
            ? 'All done 🎉'
            : '$remaining of $total remaining';
    final relative = relativeLabel(date);
    final title = relative ?? fullDate(date);
    final subtitle = relative != null ? '${fullDate(date)}  •  $counts' : counts;

    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 4, 12, 4),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: theme.textTheme.headlineSmall?.copyWith(
                    fontWeight: FontWeight.w800,
                    color: const Color(0xFF2B2250),
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  subtitle,
                  style: theme.textTheme.labelLarge?.copyWith(
                    color: const Color(0xFF8A82AD),
                  ),
                ),
                if (total > 0) ...[
                  const SizedBox(height: 8),
                  ClipRRect(
                    borderRadius: BorderRadius.circular(6),
                    child: LinearProgressIndicator(
                      value: (total - remaining) / total,
                      minHeight: 6,
                      backgroundColor: AppColors.violet.withValues(alpha: 0.12),
                      color: allDone ? AppColors.teal : AppColors.violet,
                    ),
                  ),
                ],
              ],
            ),
          ),
          const SizedBox(width: 8),
          _RoundButton(
            color: AppColors.violet,
            child: IconButton(
              icon: const Icon(Icons.calendar_month_rounded),
              color: AppColors.violet,
              tooltip: 'Pick a date',
              onPressed: onPickDate,
            ),
          ),
          const SizedBox(width: 6),
          _RoundButton(
            color: AppColors.pink,
            child: PopupMenuButton<SortMode>(
              icon: const Icon(Icons.sort_rounded, color: AppColors.pink),
              tooltip: 'Sort tasks',
              initialValue: sortMode,
              onSelected: onSortChanged,
              itemBuilder: (_) => [
                for (final mode in SortMode.values)
                  CheckedPopupMenuItem(
                    value: mode,
                    checked: mode == sortMode,
                    child: Text(mode.label),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _RoundButton extends StatelessWidget {
  const _RoundButton({required this.color, required this.child});

  final Color color;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: color.withValues(alpha: 0.12),
      ),
      child: child,
    );
  }
}
