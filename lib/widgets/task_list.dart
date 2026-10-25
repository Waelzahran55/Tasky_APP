import 'package:flutter/material.dart';

import '../models/task.dart';
import 'task_card.dart';

/// Reorderable list of tasks. Long-press a card, then drag it to move it.
class TaskList extends StatelessWidget {
  const TaskList({
    super.key,
    required this.tasks,
    required this.onReorder,
    required this.onToggle,
    required this.onEdit,
    required this.onDelete,
  });

  final List<Task> tasks;
  final ReorderCallback onReorder;
  final void Function(Task task, bool? value) onToggle;
  final ValueChanged<Task> onEdit;
  final ValueChanged<Task> onDelete;

  @override
  Widget build(BuildContext context) {
    return ReorderableListView.builder(
      // Extra bottom space so the floating button never covers the last card.
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 96),
      itemCount: tasks.length,
      buildDefaultDragHandles: false,
      onReorder: onReorder,
      proxyDecorator: _liftedCard,
      itemBuilder: (context, index) {
        final task = tasks[index];
        return ReorderableDelayedDragStartListener(
          key: ValueKey(task.id),
          index: index,
          child: TaskCard(
            task: task,
            onToggle: (value) => onToggle(task, value),
            onEdit: () => onEdit(task),
            onDelete: () => onDelete(task),
          ),
        );
      },
    );
  }

  /// How a card looks while it is being dragged: slightly enlarged.
  Widget _liftedCard(Widget child, int index, Animation<double> animation) {
    return AnimatedBuilder(
      animation: animation,
      builder: (context, child) {
        final t = Curves.easeInOut.transform(animation.value);
        return Transform.scale(
          scale: 1 + 0.03 * t,
          child: Material(color: Colors.transparent, child: child),
        );
      },
      child: child,
    );
  }
}
