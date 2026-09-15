/// Calendar periods for client/seller dashboard KPIs.
enum DashboardPeriod { day, week, month }

/// Inclusive [start] / exclusive [end] range in local time.
class DashboardPeriodRange {
  const DashboardPeriodRange(this.start, this.end);

  final DateTime start;
  final DateTime end;

  bool contains(DateTime value) {
    return !value.isBefore(start) && value.isBefore(end);
  }

  /// ISO timestamp for timestamptz columns.
  String get startIso => start.toUtc().toIso8601String();
  String get endIso => end.toUtc().toIso8601String();

  /// `YYYY-MM-DD` for `date` columns such as `hour_reports.work_date`.
  String get startDate => _ymd(start);
  String get endDate => _ymd(end);

  static String _ymd(DateTime d) =>
      '${d.year.toString().padLeft(4, '0')}-'
      '${d.month.toString().padLeft(2, '0')}-'
      '${d.day.toString().padLeft(2, '0')}';

  /// Day = today; week = Monday → today; month = 1st → today.
  static DashboardPeriodRange forPeriod(
    DashboardPeriod period, [
    DateTime? now,
  ]) {
    final n = now ?? DateTime.now();
    final today = DateTime(n.year, n.month, n.day);
    final tomorrow = today.add(const Duration(days: 1));
    switch (period) {
      case DashboardPeriod.day:
        return DashboardPeriodRange(today, tomorrow);
      case DashboardPeriod.week:
        final monday = today.subtract(Duration(days: today.weekday - 1));
        return DashboardPeriodRange(monday, tomorrow);
      case DashboardPeriod.month:
        return DashboardPeriodRange(
          DateTime(n.year, n.month, 1),
          tomorrow,
        );
    }
  }
}
