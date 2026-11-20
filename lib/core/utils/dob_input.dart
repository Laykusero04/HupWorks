import 'package:freelancer/core/utils/age_check.dart';

/// Why a typed date of birth was refused (T-0172). Never carries the value.
enum DobError { empty, invalid, future, under16 }

class DobResult {
  const DobResult.ok(DateTime this.date) : error = null;
  const DobResult.error(DobError this.error) : date = null;

  final DateTime? date;
  final DobError? error;

  bool get isValid => date != null;
}

/// Validates a date of birth typed as day / month / year.
///
/// - all three blank: [DobError.empty]
/// - missing part, non-digits, day or month out of range, a day that does not
///   exist in that month (29 Feb in a non-leap year), year not 4 digits or
///   before 1900: [DobError.invalid]
/// - after today: [DobError.future]
/// - younger than 16 (full-date comparison, turning 16 today is allowed):
///   [DobError.under16]
///
/// "Today" is the UTC date, the same basis as the database check. Pass [now]
/// (a UTC value) in tests.
DobResult validateDob(String day, String month, String year, {DateTime? now}) {
  final d = day.trim();
  final m = month.trim();
  final y = year.trim();
  if (d.isEmpty && m.isEmpty && y.isEmpty) {
    return const DobResult.error(DobError.empty);
  }
  final digits = RegExp(r'^[0-9]+$');
  if (!digits.hasMatch(d) ||
      !digits.hasMatch(m) ||
      !digits.hasMatch(y) ||
      d.length > 2 ||
      m.length > 2 ||
      y.length != 4) {
    return const DobResult.error(DobError.invalid);
  }
  final dd = int.parse(d);
  final mm = int.parse(m);
  final yy = int.parse(y);
  if (yy < 1900 || mm < 1 || mm > 12 || dd < 1 || dd > 31) {
    return const DobResult.error(DobError.invalid);
  }
  final date = DateTime(yy, mm, dd);
  // DateTime rolls 31 Apr over to 1 May; a real date round-trips.
  if (date.year != yy || date.month != mm || date.day != dd) {
    return const DobResult.error(DobError.invalid);
  }
  final n = now ?? DateTime.now().toUtc();
  if (date.isAfter(DateTime(n.year, n.month, n.day))) {
    return const DobResult.error(DobError.future);
  }
  if (!isAtLeast16(date, now: n)) {
    return const DobResult.error(DobError.under16);
  }
  return DobResult.ok(date);
}
