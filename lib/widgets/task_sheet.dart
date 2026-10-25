import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../models/priority.dart';
import '../models/reminder.dart';
import '../models/task.dart';
import '../services/notification_service.dart';
import '../theme/app_colors.dart';
import '../utils/date_helpers.dart';

/// Bottom sheet used both to add a new task and to edit an existing one.
/// Pops with the resulting [Task], or null if dismissed.
class TaskSheet extends StatefulWidget {
  const TaskSheet({super.key, this.initial, required this.initialDate});

  /// The task being edited, or null when adding a new one.
  final Task? initial;

  /// Date preselected for a new task.
  final DateTime initialDate;

  static Future<Task?> show(
    BuildContext context, {
    Task? initial,
    required DateTime initialDate,
  }) {
    return showModalBottomSheet<Task>(
      context: context,
      isScrollControlled: true,
      showDragHandle: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
      ),
      builder: (_) => TaskSheet(initial: initial, initialDate: initialDate),
    );
  }

  @override
  State<TaskSheet> createState() => _TaskSheetState();
}

class _TaskSheetState extends State<TaskSheet> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _titleController;
  late final TextEditingController _detailsController;
  late DateTime _date;
  TimeOfDay? _time;
  late Priority _priority;

  bool _remind = false;
  int _leadMinutes = 10;
  ReminderType _reminderType = ReminderType.sound;

  bool get _isEditing => widget.initial != null;

  @override
  void initState() {
    super.initState();
    final task = widget.initial;
    _titleController = TextEditingController(text: task?.title ?? '');
    _detailsController = TextEditingController(text: task?.details ?? '');
    _date = task?.date ?? widget.initialDate;
    _time = task?.time;
    _priority = task?.priority ?? Priority.medium;

    final reminder = task?.reminder;
    if (reminder != null && _time != null) {
      _remind = true;
      _leadMinutes = reminder.minutesBefore;
      _reminderType = reminder.type;
    }
  }

  @override
  void dispose() {
    _titleController.dispose();
    _detailsController.dispose();
    super.dispose();
  }

  Future<void> _pickDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _date,
      firstDate: pickerFirstDate(_date),
      lastDate: DateTime(2100),
    );
    if (picked != null) setState(() => _date = dateOnly(picked));
  }

  /// Returns true when a time ended up selected.
  Future<bool> _pickTime() async {
    final picked = await showTimePicker(
      context: context,
      initialTime: _time ?? TimeOfDay.now(),
    );
    if (picked != null) setState(() => _time = picked);
    return _time != null;
  }

  Future<void> _toggleReminder(bool value) async {
    if (!value) {
      setState(() => _remind = false);
      return;
    }
    // A reminder needs a time: ask for one first.
    if (_time == null && !await _pickTime()) return;
    setState(() => _remind = true);
  }

  Future<void> _askCustomLead() async {
    final controller = TextEditingController();
    var unit = 1;

    final minutes = await showDialog<int>(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setLocal) => AlertDialog(
          title: const Text('Custom reminder'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: controller,
                autofocus: true,
                keyboardType: TextInputType.number,
                inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                decoration: const InputDecoration(labelText: 'How long before?'),
              ),
              const SizedBox(height: 14),
              SegmentedButton<int>(
                showSelectedIcon: false,
                segments: const [
                  ButtonSegment(value: 1, label: Text('Min')),
                  ButtonSegment(value: 60, label: Text('Hours')),
                  ButtonSegment(value: 1440, label: Text('Days')),
                ],
                selected: {unit},
                onSelectionChanged: (s) => setLocal(() => unit = s.first),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text('Cancel'),
            ),
            FilledButton(
              onPressed: () {
                final n = int.tryParse(controller.text);
                if (n == null || n <= 0) return;
                Navigator.pop(ctx, n * unit);
              },
              child: const Text('Set'),
            ),
          ],
        ),
      ),
    );

    if (minutes != null) setState(() => _leadMinutes = minutes);
  }

  DateTime? get _reminderMoment {
    if (!_remind || _time == null) return null;
    return DateTime(_date.year, _date.month, _date.day, _time!.hour, _time!.minute)
        .subtract(Duration(minutes: _leadMinutes));
  }

  void _submit() {
    if (!_formKey.currentState!.validate()) return;
    final initial = widget.initial;
    Navigator.of(context).pop(
      Task(
        id: initial?.id,
        title: _titleController.text.trim(),
        details: _detailsController.text.trim(),
        date: _date,
        time: _time,
        priority: _priority,
        reminder: (_remind && _time != null)
            ? Reminder(minutesBefore: _leadMinutes, type: _reminderType)
            : null,
        done: initial?.done ?? false,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final bottomInset = MediaQuery.of(context).viewInsets.bottom;

    return SingleChildScrollView(
      padding: EdgeInsets.fromLTRB(20, 0, 20, bottomInset + 20),
      child: Form(
        key: _formKey,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              _isEditing ? 'Edit Task' : 'New Task',
              style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                    fontWeight: FontWeight.w800,
                    color: const Color(0xFF2B2250),
                  ),
            ),
            const SizedBox(height: 16),
            _buildTitleField(),
            const SizedBox(height: 12),
            _buildDetailsField(),
            const SizedBox(height: 16),
            _buildDateTimeRow(),
            const SizedBox(height: 16),
            _buildPrioritySelector(),
            const SizedBox(height: 16),
            _buildReminderSection(),
            const SizedBox(height: 20),
            _buildSubmitButton(),
          ],
        ),
      ),
    );
  }

  Widget _buildSubmitButton() {
    return Container(
      height: 52,
      decoration: BoxDecoration(
        gradient: AppColors.primaryGradient,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: AppColors.violet.withValues(alpha: 0.35),
            blurRadius: 12,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: FilledButton(
        style: FilledButton.styleFrom(
          backgroundColor: Colors.transparent,
          shadowColor: Colors.transparent,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        ),
        onPressed: _submit,
        child: Text(
          _isEditing ? 'Save Changes' : 'Add Task',
          style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700),
        ),
      ),
    );
  }

  Widget _buildTitleField() {
    return TextFormField(
      controller: _titleController,
      autofocus: !_isEditing,
      textInputAction: TextInputAction.next,
      decoration: const InputDecoration(labelText: 'Title'),
      validator: (value) => (value == null || value.trim().isEmpty)
          ? 'Please enter a title'
          : null,
    );
  }

  Widget _buildDetailsField() {
    return TextFormField(
      controller: _detailsController,
      minLines: 3,
      maxLines: 5,
      textInputAction: TextInputAction.newline,
      decoration: const InputDecoration(
        labelText: 'Details',
        alignLabelWithHint: true,
      ),
    );
  }

  Widget _buildDateTimeRow() {
    const buttonPadding = EdgeInsets.symmetric(horizontal: 12, vertical: 12);
    final style = OutlinedButton.styleFrom(
      padding: buttonPadding,
      foregroundColor: AppColors.violet,
      side: BorderSide(color: AppColors.violet.withValues(alpha: 0.4)),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
    );

    return Row(
      children: [
        Expanded(
          child: OutlinedButton.icon(
            style: style,
            onPressed: _pickDate,
            icon: const Icon(Icons.calendar_today_rounded, size: 18),
            label: Text(
              fullDate(_date),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: OutlinedButton.icon(
            style: style,
            onPressed: _pickTime,
            icon: const Icon(Icons.access_time_rounded, size: 18),
            label: Text(
              _time == null ? 'Set time' : _time!.format(context),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ),
        if (_time != null)
          IconButton(
            onPressed: () => setState(() {
              _time = null;
              _remind = false; // no time, no reminder
            }),
            icon: const Icon(Icons.close),
            tooltip: 'Clear time',
          ),
      ],
    );
  }

  Widget _buildPrioritySelector() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text('Priority', style: Theme.of(context).textTheme.labelLarge),
        const SizedBox(height: 8),
        SegmentedButton<Priority>(
          showSelectedIcon: false,
          style: ButtonStyle(
            backgroundColor: WidgetStateProperty.resolveWith((states) {
              if (!states.contains(WidgetState.selected)) return null;
              return _priority.color.withValues(alpha: 0.18);
            }),
            foregroundColor: WidgetStateProperty.resolveWith((states) {
              return states.contains(WidgetState.selected)
                  ? _priority.color
                  : null;
            }),
          ),
          segments: [
            for (final p in Priority.values)
              ButtonSegment(
                value: p,
                label: Text(p.label),
                icon: Icon(Icons.flag_rounded, size: 18, color: p.color),
              ),
          ],
          selected: {_priority},
          onSelectionChanged: (s) => setState(() => _priority = s.first),
        ),
      ],
    );
  }

  // ---------------------------------------------------------------- reminder

  Widget _buildReminderSection() {
    final moment = _reminderMoment;
    final passed = moment != null && !moment.isAfter(DateTime.now());

    return AnimatedSize(
      duration: const Duration(milliseconds: 220),
      curve: Curves.easeOut,
      alignment: Alignment.topCenter,
      child: Container(
        padding: const EdgeInsets.fromLTRB(14, 8, 14, 14),
        decoration: BoxDecoration(
          color: _remind
              ? AppColors.violet.withValues(alpha: 0.07)
              : const Color(0xFFF5F2FF),
          borderRadius: BorderRadius.circular(18),
          border: Border.all(
            color: _remind
                ? AppColors.violet.withValues(alpha: 0.35)
                : Colors.transparent,
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    gradient: _remind ? AppColors.warmGradient : null,
                    color: _remind ? null : Colors.black12,
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    Icons.notifications_active_rounded,
                    size: 20,
                    color: _remind ? Colors.white : Colors.black45,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Remind me',
                        style: Theme.of(context).textTheme.titleMedium?.copyWith(
                              fontWeight: FontWeight.w700,
                              color: const Color(0xFF2B2250),
                            ),
                      ),
                      if (!_remind)
                        Text(
                          _time == null
                              ? 'Turn on to pick a time & alert type'
                              : 'Off',
                          style: Theme.of(context).textTheme.bodySmall,
                        ),
                    ],
                  ),
                ),
                Switch(value: _remind, onChanged: _toggleReminder),
              ],
            ),
            if (_remind) ...[
              const SizedBox(height: 12),
              Text('How long before?',
                  style: Theme.of(context).textTheme.labelLarge),
              const SizedBox(height: 8),
              _buildLeadChips(),
              const SizedBox(height: 14),
              Text('Alert type', style: Theme.of(context).textTheme.labelLarge),
              const SizedBox(height: 8),
              Row(
                children: [
                  for (final type in ReminderType.values) ...[
                    Expanded(child: _buildTypeTile(type)),
                    if (type != ReminderType.values.last)
                      const SizedBox(width: 8),
                  ],
                ],
              ),
              const SizedBox(height: 12),
              _buildReminderSummary(moment, passed),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildLeadChips() {
    final isCustom = !Reminder.presets.contains(_leadMinutes);

    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: [
        for (final m in Reminder.presets)
          ChoiceChip(
            label: Text(formatLead(m, suffix: false)),
            selected: _leadMinutes == m,
            showCheckmark: false,
            onSelected: (_) => setState(() => _leadMinutes = m),
          ),
        if (isCustom)
          ChoiceChip(
            label: Text(formatLead(_leadMinutes, suffix: false)),
            selected: true,
            showCheckmark: false,
            onSelected: (_) {},
          ),
        ActionChip(
          avatar: const Icon(Icons.tune_rounded, size: 16),
          label: const Text('Custom'),
          onPressed: _askCustomLead,
        ),
      ],
    );
  }

  Widget _buildTypeTile(ReminderType type) {
    final selected = _reminderType == type;

    return InkWell(
      borderRadius: BorderRadius.circular(14),
      onTap: () => setState(() => _reminderType = type),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 160),
        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 12),
        decoration: BoxDecoration(
          color: selected
              ? type.color.withValues(alpha: 0.14)
              : Colors.white,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: selected ? type.color : Colors.black12,
            width: selected ? 2 : 1,
          ),
        ),
        child: Column(
          children: [
            Icon(type.icon, color: type.color, size: 26),
            const SizedBox(height: 6),
            Text(
              type.label,
              style: TextStyle(
                fontWeight: FontWeight.w700,
                color: selected ? type.color : const Color(0xFF2B2250),
              ),
            ),
            const SizedBox(height: 2),
            Text(
              type.caption,
              textAlign: TextAlign.center,
              style: const TextStyle(fontSize: 11, color: Colors.black54),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildReminderSummary(DateTime? moment, bool passed) {
    final warn = Theme.of(context).colorScheme.error;
    final lines = <Widget>[];

    if (moment != null) {
      lines.add(
        Row(
          children: [
            Icon(
              passed ? Icons.warning_amber_rounded : Icons.check_circle_rounded,
              size: 18,
              color: passed ? warn : AppColors.teal,
            ),
            const SizedBox(width: 6),
            Expanded(
              child: Text(
                passed
                    ? 'That moment has already passed, so no reminder will fire.'
                    : "You'll be reminded ${fullDate(moment)} at ${formatTime(moment.hour, moment.minute)}",
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: passed ? warn : const Color(0xFF2B2250),
                ),
              ),
            ),
          ],
        ),
      );
    }

    if (!NotificationService.instance.isSupported) {
      lines.add(const SizedBox(height: 6));
      lines.add(
        const Text(
          'Reminders only fire on Android / iOS, not in this preview.',
          style: TextStyle(fontSize: 12, color: Colors.black54),
        ),
      );
    }

    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: lines);
  }
}
