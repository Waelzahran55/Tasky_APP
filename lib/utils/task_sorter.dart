import '../models/sort_mode.dart';
import '../models/task.dart';

/// Returns a new list with [tasks] arranged according to [mode].
///
/// In [SortMode.custom] the incoming order is kept exactly as is, because it
/// is the order the user arranged by hand.
List<Task> sortTasks(Iterable<Task> tasks, SortMode mode) {
  final list = tasks.toList();
  if (mode == SortMode.custom) return list;

  list.sort((a, b) {
    // Completed tasks always sink to the bottom.
    if (a.done != b.done) return a.done ? 1 : -1;

    final byTime = a.minutes.compareTo(b.minutes);
    final byPriority = b.priority.index.compareTo(a.priority.index);

    final result = mode == SortMode.byTime
        ? (byTime != 0 ? byTime : byPriority)
        : (byPriority != 0 ? byPriority : byTime);

    return result != 0 ? result : a.id.compareTo(b.id);
  });
  return list;
}
