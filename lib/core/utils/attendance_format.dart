import 'package:freelancer/l10n/app_localizations.dart';
import 'package:intl/intl.dart';

class AttendanceFormat {
  AttendanceFormat._();

  static String timeOfDay(DateTime dt, [String? localeName]) {
    final local = dt.toLocal();
    return DateFormat.jm(localeName).format(local);
  }

  static String dateTime(DateTime dt, [String? localeName]) {
    final local = dt.toLocal();
    return '${DateFormat.yMMMd(localeName).format(local)} • ${timeOfDay(local, localeName)}';
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
