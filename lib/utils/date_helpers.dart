const _weekdays = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];
const _months = [
  'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
  'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec',
];

DateTime dateOnly(DateTime d) => DateTime(d.year, d.month, d.day);

DateTime addDays(DateTime d, int n) => DateTime(d.year, d.month, d.day + n);

bool isSameDay(DateTime a, DateTime b) =>
    a.year == b.year && a.month == b.month && a.day == b.day;

int dayDiff(DateTime a, DateTime b) => DateTime.utc(a.year, a.month, a.day)
    .difference(DateTime.utc(b.year, b.month, b.day))
    .inDays;

String weekdayShort(DateTime d) => _weekdays[d.weekday - 1];

String fullDate(DateTime d) {
  final base = '${weekdayShort(d)}, ${d.day} ${_months[d.month - 1]}';
  return d.year == DateTime.now().year ? base : '$base ${d.year}';
}

String? relativeLabel(DateTime d) {
  final diff = dayDiff(d, dateOnly(DateTime.now()));
  if (diff == 0) return 'Today';
  if (diff == 1) return 'Tomorrow';
  if (diff == -1) return 'Yesterday';
  return null;
}

DateTime pickerFirstDate(DateTime current) {
  final today = dateOnly(DateTime.now());
  return current.isBefore(today) ? current : today;
}

String formatTime(int hour, int minute) {
  final h = hour % 12 == 0 ? 12 : hour % 12;
  final m = minute.toString().padLeft(2, '0');
  return '$h:$m ${hour < 12 ? 'AM' : 'PM'}';
}

String formatLead(int minutes, {bool suffix = true}) {
  if (minutes <= 0) return 'At time';
  String base;
  if (minutes % 1440 == 0) {
    final d = minutes ~/ 1440;
    base = d == 1 ? '1 day' : '$d days';
  } else if (minutes % 60 == 0) {
    final h = minutes ~/ 60;
    base = h == 1 ? '1 hour' : '$h hours';
  } else if (minutes > 60) {
    base = '${minutes ~/ 60}h ${minutes % 60}m';
  } else {
    base = '$minutes min';
  }
  return suffix ? '$base before' : base;
}
