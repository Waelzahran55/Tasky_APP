import 'package:flutter/material.dart';

import '../models/task.dart';
import '../theme/app_colors.dart';
import '../utils/date_helpers.dart';

/// Horizontal strip of days starting from today. A dot marks days that have
/// tasks (grey when all of them are done).
class DayStrip extends StatefulWidget {
  const DayStrip({
    super.key,
    required this.selectedDate,
    required this.tasks,
    required this.onSelected,
  });

  final DateTime selectedDate;

  /// All tasks (used only to draw the dots).
  final List<Task> tasks;
  final ValueChanged<DateTime> onSelected;

  @override
  State<DayStrip> createState() => _DayStripState();
}

class _DayStripState extends State<DayStrip> {
  static const int _length = 60;
  static const double _chipExtent = 68;

  final ScrollController _controller = ScrollController();
  late DateTime _start;
  bool _selectedByTap = false;

  @override
  void initState() {
    super.initState();
    _start = dateOnly(DateTime.now());
    _scheduleScrollToSelected();
  }

  @override
  void didUpdateWidget(DayStrip oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (isSameDay(oldWidget.selectedDate, widget.selectedDate)) return;

    // A far-away date (picked from the calendar) moves the strip window.
    final index = dayDiff(widget.selectedDate, _start);
    if (index < 0 || index >= _length) {
      final today = dateOnly(DateTime.now());
      final candidate = addDays(widget.selectedDate, -2);
      _start = candidate.isBefore(today) ? today : candidate;
    }

    // Tapping a visible chip shouldn't make the strip jump around.
    if (_selectedByTap) {
      _selectedByTap = false;
    } else {
      _scheduleScrollToSelected();
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _scheduleScrollToSelected() {
    WidgetsBinding.instance.addPostFrameCallback((_) => _scrollToSelected());
  }

  void _scrollToSelected() {
    if (!mounted || !_controller.hasClients) return;
    final index = dayDiff(widget.selectedDate, _start);
    final target = ((index - 1) * _chipExtent)
        .clamp(0.0, _controller.position.maxScrollExtent)
        .toDouble();
    _controller.animateTo(
      target,
      duration: const Duration(milliseconds: 250),
      curve: Curves.easeOut,
    );
  }

  void _handleTap(DateTime date) {
    if (!isSameDay(date, widget.selectedDate)) _selectedByTap = true;
    widget.onSelected(date);
  }

  @override
  Widget build(BuildContext context) {
    final today = dateOnly(DateTime.now());

    return SizedBox(
      height: 92,
      child: ListView.builder(
        controller: _controller,
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        itemExtent: _chipExtent,
        itemCount: _length,
        itemBuilder: (context, i) {
          final date = addDays(_start, i);
          final dayTasks =
              widget.tasks.where((t) => isSameDay(t.date, date)).toList();

          return _DayChip(
            date: date,
            isSelected: isSameDay(date, widget.selectedDate),
            isToday: isSameDay(date, today),
            hasTasks: dayTasks.isNotEmpty,
            allDone: dayTasks.isNotEmpty && dayTasks.every((t) => t.done),
            onTap: () => _handleTap(date),
          );
        },
      ),
    );
  }
}

class _DayChip extends StatelessWidget {
  const _DayChip({
    required this.date,
    required this.isSelected,
    required this.isToday,
    required this.hasTasks,
    required this.allDone,
    required this.onTap,
  });

  final DateTime date;
  final bool isSelected;
  final bool isToday;
  final bool hasTasks;
  final bool allDone;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;

    final textColor = isSelected ? Colors.white : const Color(0xFF2B2250);
    final subTextColor =
        isSelected ? Colors.white70 : const Color(0xFF8A82AD);
    final dotColor = isSelected
        ? Colors.white
        : (allDone ? AppColors.teal : AppColors.pink);

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 4),
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(18),
          boxShadow: [
            BoxShadow(
              color: AppColors.violet.withValues(alpha: isSelected ? 0.35 : 0.07),
              blurRadius: isSelected ? 12 : 8,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Material(
          color: Colors.transparent,
          child: Ink(
            decoration: BoxDecoration(
              gradient: isSelected ? AppColors.primaryGradient : null,
              color: isSelected ? null : Colors.white,
              borderRadius: BorderRadius.circular(18),
              border: isToday && !isSelected
                  ? Border.all(color: scheme.primary, width: 1.5)
                  : null,
            ),
            child: InkWell(
              borderRadius: BorderRadius.circular(18),
              onTap: onTap,
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    weekdayShort(date),
                    style: TextStyle(fontSize: 12, color: subTextColor),
                  ),
                  Text(
                    '${date.day}',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w800,
                      color: textColor,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Container(
                    width: 6,
                    height: 6,
                    decoration: BoxDecoration(
                      color: hasTasks ? dotColor : Colors.transparent,
                      shape: BoxShape.circle,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
