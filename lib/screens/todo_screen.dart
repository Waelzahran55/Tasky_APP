import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:shared_preferences/shared_preferences.dart';

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
  static const String _tasksKey = 'todo_tasks_v1';
  static const String _sortModeKey = 'todo_sort_mode_v1';
  static const String _selectedDateKey = 'todo_selected_date_v1';

  final List<Task> _tasks = [];
  SortMode _sortMode = SortMode.byTime;
  DateTime _selectedDate = dateOnly(DateTime.now());
  bool _isLoading = true;

  List<Task> get _visibleTasks => sortTasks(
        _tasks.where((t) => isSameDay(t.date, _selectedDate)),
        _sortMode,
      );

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final rawTasks = prefs.getString(_tasksKey);

      final loadedTasks = <Task>[];
      if (rawTasks != null && rawTasks.isNotEmpty) {
        final decoded = jsonDecode(rawTasks) as List<dynamic>;
        for (final item in decoded) {
          try {
            loadedTasks.add(
              Task.fromJson(Map<String, dynamic>.from(item as Map)),
            );
          } catch (e) {
            debugPrint('Skipping invalid saved task: $e');
          }
        }
      }

      final savedSortMode = prefs.getString(_sortModeKey);
      final loadedSortMode = SortMode.values.firstWhere(
        (mode) => mode.name == savedSortMode,
        orElse: () => SortMode.byTime,
      );

      final savedDate = prefs.getString(_selectedDateKey);
      final loadedDate = savedDate == null
          ? dateOnly(DateTime.now())
          : dateOnly(DateTime.tryParse(savedDate) ?? DateTime.now());

      if (!mounted) return;
      setState(() {
        _tasks
          ..clear()
          ..addAll(loadedTasks);
        _sortMode = loadedSortMode;
        _selectedDate = loadedDate;
        _isLoading = false;
      });

      
      for (final task in loadedTasks) {
        await NotificationService.instance.schedule(task);
      }
    } catch (e, stackTrace) {
      debugPrint('Could not load saved tasks: $e');
      debugPrintStack(stackTrace: stackTrace);
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _saveData() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(
        _tasksKey,
        jsonEncode(_tasks.map((task) => task.toJson()).toList()),
      );
      await prefs.setString(_sortModeKey, _sortMode.name);
      await prefs.setString(
        _selectedDateKey,
        _selectedDate.toIso8601String(),
      );
    } catch (e, stackTrace) {
      debugPrint('Could not save tasks: $e');
      debugPrintStack(stackTrace: stackTrace);
    }
  }

  void _selectDate(DateTime date) {
    setState(() => _selectedDate = dateOnly(date));
    _saveData();
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
      _selectedDate = result.date;
    });

    await _saveData();
    await NotificationService.instance.schedule(result);
  }

  Future<void> _toggleTask(Task task, bool? value) async {
    setState(() => task.done = value ?? false);
    await _saveData();
    await NotificationService.instance.schedule(task);
  }

  Future<void> _deleteTask(Task task) async {
    final index = _tasks.indexWhere((t) => t.id == task.id);
    if (index == -1) return;

    setState(() => _tasks.removeAt(index));
    await _saveData();
    await NotificationService.instance.cancel(task.id);

    if (!mounted) return;
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(
          content: const Text('Task deleted'),
          action: SnackBarAction(
            label: 'Undo',
            onPressed: () async {
              setState(() => _tasks.insert(index, task));
              await _saveData();
              await NotificationService.instance.schedule(task);
            },
          ),
        ),
      );
  }

  void _reorder(int oldIndex, int newIndex) {
    if (newIndex > oldIndex) newIndex -= 1;
    if (oldIndex == newIndex) return;

    final reordered = _visibleTasks;
    final moved = reordered.removeAt(oldIndex);
    reordered.insert(newIndex, moved);

    setState(() {
      final slots = <int>[
        for (var i = 0; i < _tasks.length; i++)
          if (isSameDay(_tasks[i].date, _selectedDate)) i,
      ];
      for (var i = 0; i < slots.length; i++) {
        _tasks[slots[i]] = reordered[i];
      }
      _sortMode = SortMode.custom;
    });
    _saveData();
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
        child: _isLoading
            ? const Center(child: CircularProgressIndicator())
            : Column(
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
                    onSortChanged: (mode) {
                      setState(() => _sortMode = mode);
                      _saveData();
                    },
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
      floatingActionButton: _isLoading
          ? null
          : Container(
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
