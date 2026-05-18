class AttendanceFormat {
  AttendanceFormat._();

  static String timeOfDay(DateTime dt) {
    final local = dt.toLocal();
    final hour = local.hour;
    final minute = local.minute.toString().padLeft(2, '0');
    final period = hour >= 12 ? 'PM' : 'AM';
    final displayHour = hour == 0 ? 12 : (hour > 12 ? hour - 12 : hour);
    return '$displayHour:$minute $period';
  }

  static String dateTime(DateTime dt) {
    const months = [
      'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
      'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec',
    ];
    final local = dt.toLocal();
    return '${months[local.month - 1]} ${local.day}, ${local.year} • ${timeOfDay(local)}';
  }

  static String punchLabel(String punchType) =>
      punchType == 'in' ? 'Clock in' : 'Clock out';

  static String minutesLabel(double minutes) {
    if (minutes < 1) return 'Less than 1 min';
    final h = minutes ~/ 60;
    final m = (minutes % 60).round();
    if (h == 0) return '$m min';
    if (m == 0) return '${h}h';
    return '${h}h ${m}m';
  }
}
