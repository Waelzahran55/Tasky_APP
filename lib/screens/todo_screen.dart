import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../models/sort_mode.dart';
import '../models/task.dart';
import '../services/notification_service.dart';
import '../theme/app_colors.dart';
import '../utils/date_helpers.dart';
import '../utils/task_sorter.dart';
import '../widgets/day_header.dart';
import '../widgets/day_strip.dart';
import '../widgets/empty_state.dart';
import '../widgets/task_list.dart';
import '../widgets/task_sheet.dart';

class TodoScreen extends StatefulWidget {
  const TodoScreen({super.key});

  @override
  State<TodoScreen> createState() => _TodoScreenState();
}

class _TodoScreenState extends State<TodoScreen> {
  /// All tasks of all days. Its order doubles as the user's custom order:
  /// in custom mode the tasks of a day appear in the order they have here.
  final List<Task> _tasks = [];
  SortMode _sortMode = SortMode.byTime;
  DateTime _selectedDate = dateOnly(DateTime.now());

  /// Tasks of the selected day, arranged by the current sort mode.
  List<Task> get _visibleTasks => sortTasks(
        _tasks.where((t) => isSameDay(t.date, _selectedDate)),
        _sortMode,
      );

  void _selectDate(DateTime date) {
    setState(() => _selectedDate = dateOnly(date));
  }

  Future<void> _pickDateFromCalendar() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate,
      firstDate: pickerFirstDate(_selectedDate),
      lastDate: DateTime(2100),
    );
    if (picked != null) _selectDate(picked);
  }

  Future<void> _openSheet({Task? task}) async {
    final result = await TaskSheet.show(
      context,
      initial: task,
      initialDate: _selectedDate,
    );
    if (result == null || !mounted) return;

    setState(() {
      if (task == null) {
        _tasks.add(result);
      } else {
        final index = _tasks.indexWhere((t) => t.id == task.id);
        if (index != -1) _tasks[index] = result;
      }
      // Jump to the day of the saved task so it never "disappears".
      _selectedDate = result.date;
    });
    NotificationService.instance.schedule(result);
  }

  void _toggleTask(Task task, bool? value) {
    setState(() => task.done = value ?? false);
    // Done tasks lose their reminder; un-done ones get it back (if still due).
    NotificationService.instance.schedule(task);
  }

  void _deleteTask(Task task) {
    final index = _tasks.indexWhere((t) => t.id == task.id);
    if (index == -1) return;

    setState(() => _tasks.removeAt(index));
    NotificationService.instance.cancel(task.id);
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(
          content: const Text('Task deleted'),
          action: SnackBarAction(
            label: 'Undo',
            onPressed: () {
              setState(() => _tasks.insert(index, task));
              NotificationService.instance.schedule(task);
            },
          ),
        ),
      );
  }

  /// Whatever order is on screen when the user drops a task becomes the
  /// custom order, and the sort mode switches to custom.
  void _reorder(int oldIndex, int newIndex) {
    if (newIndex > oldIndex) newIndex -= 1;
    if (oldIndex == newIndex) return;

    final reordered = _visibleTasks;
    final moved = reordered.removeAt(oldIndex);
    reordered.insert(newIndex, moved);

    setState(() {
      // Put the reordered tasks back into the slots this day's tasks occupy.
      final slots = <int>[
        for (var i = 0; i < _tasks.length; i++)
          if (isSameDay(_tasks[i].date, _selectedDate)) i,
      ];
      for (var i = 0; i < slots.length; i++) {
        _tasks[slots[i]] = reordered[i];
      }
      _sortMode = SortMode.custom;
    });
  }

  @override
  Widget build(BuildContext context) {
    final tasks = _visibleTasks;

    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'My Tasks',
          style: TextStyle(fontWeight: FontWeight.w800, letterSpacing: 0.3),
        ),
        centerTitle: true,
        foregroundColor: Colors.white,
        backgroundColor: Colors.transparent,
        systemOverlayStyle: SystemUiOverlayStyle.light,
        flexibleSpace: Container(
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.centerLeft,
              end: Alignment.centerRight,
              colors: [AppColors.violet, AppColors.indigo, AppColors.pink],
            ),
          ),
        ),
      ),
      body: SafeArea(
        bottom: false,
        child: Column(
          children: [
            DayStrip(
              selectedDate: _selectedDate,
              tasks: _tasks,
              onSelected: _selectDate,
            ),
            DayHeader(
              date: _selectedDate,
              tasks: tasks,
              sortMode: _sortMode,
              onPickDate: _pickDateFromCalendar,
              onSortChanged: (mode) => setState(() => _sortMode = mode),
            ),
            Expanded(
              child: tasks.isEmpty
                  ? const EmptyState()
                  : TaskList(
                      tasks: tasks,
                      onReorder: _reorder,
                      onToggle: _toggleTask,
                      onEdit: (task) => _openSheet(task: task),
                      onDelete: _deleteTask,
                    ),
            ),
          ],
        ),
      ),
      floatingActionButton: Container(
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          gradient: AppColors.warmGradient,
          boxShadow: [
            BoxShadow(
              color: AppColors.pink.withValues(alpha: 0.45),
              blurRadius: 16,
              offset: const Offset(0, 6),
            ),
          ],
        ),
        child: FloatingActionButton(
          onPressed: () => _openSheet(),
          tooltip: 'Add New Task',
          shape: const CircleBorder(),
          backgroundColor: Colors.transparent,
          foregroundColor: Colors.white,
          elevation: 0,
          focusElevation: 0,
          hoverElevation: 0,
          highlightElevation: 0,
          child: const Icon(Icons.add_rounded, size: 30),
        ),
      ),
    );
  }
}
