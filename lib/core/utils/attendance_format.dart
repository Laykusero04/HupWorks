import 'package:freelancer/l10n/app_localizations.dart';
import 'package:intl/intl.dart';

class AttendanceFormat {
  AttendanceFormat._();

  static String timeOfDay(DateTime dt, [String? localeName]) {
    final local = dt.toLocal();
    if (localeName != null && localeName.isNotEmpty) {
      return DateFormat.jm(localeName).format(local);
    }
    final hour = local.hour;
    final minute = local.minute.toString().padLeft(2, '0');
    final period = hour >= 12 ? 'PM' : 'AM';
    final displayHour = hour == 0 ? 12 : (hour > 12 ? hour - 12 : hour);
    return '$displayHour:$minute $period';
  }

  static String dateTime(DateTime dt, [String? localeName]) {
    final local = dt.toLocal();
    if (localeName != null && localeName.isNotEmpty) {
      return '${DateFormat.yMMMd(localeName).format(local)} • ${timeOfDay(local, localeName)}';
    }
    const months = [
      'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
      'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec',
    ];
    return '${months[local.month - 1]} ${local.day}, ${local.year} • ${timeOfDay(local)}';
  }

  static String punchLabel(String punchType, [AppLocalizations? l10n]) =>
      punchType == 'in'
          ? (l10n?.clockIn ?? 'Clock in')
          : (l10n?.clockOut ?? 'Clock out');

  static String minutesLabel(double minutes, [AppLocalizations? l10n]) {
    if (minutes < 1) {
      return l10n?.attendanceLessThanOneMin ?? 'Less than 1 min';
    }
    final h = minutes ~/ 60;
    final m = (minutes % 60).round();
    if (h == 0) {
      return l10n?.attendanceMinutesOnly(m) ?? '$m min';
    }
    if (m == 0) {
      return l10n?.attendanceHoursOnly(h) ?? '${h}h';
    }
    return l10n?.attendanceHoursMinutes(h, m) ?? '${h}h ${m}m';
  }
}
