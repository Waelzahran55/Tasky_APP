import '../models/sort_mode.dart';
import '../models/task.dart';


List<Task> sortTasks(Iterable<Task> tasks, SortMode mode) {
  final list = tasks.toList();
  if (mode == SortMode.custom) return list;

  list.sort((a, b) {
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
