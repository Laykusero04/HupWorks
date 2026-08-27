import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

/// Job/order shift window: optional [workDate] + [shiftStart]/[shiftEnd] clock times.
class ShiftSchedule {
  const ShiftSchedule({
    this.workDate,
    this.shiftStart,
    this.shiftEnd,
  });

  final DateTime? workDate;
  final TimeOfDay? shiftStart;
  final TimeOfDay? shiftEnd;

  bool get hasTimes => shiftStart != null && shiftEnd != null;

  bool get hasAny => workDate != null || shiftStart != null || shiftEnd != null;

  /// Postgres `time` / `date` values from maps (job_posts or orders).
  factory ShiftSchedule.fromMap(Map<String, dynamic>? map) {
    if (map == null) return const ShiftSchedule();
    return ShiftSchedule(
      workDate: parseDate(map['work_date']),
      shiftStart: parseTime(map['shift_start']),
      shiftEnd: parseTime(map['shift_end']),
    );
  }

  /// Prefer order snapshot; fall back to nested job_posts under job_offers.
  factory ShiftSchedule.fromOrderMap(Map<String, dynamic>? order) {
    if (order == null) return const ShiftSchedule();
    final fromOrder = ShiftSchedule.fromMap(order);
    if (fromOrder.hasAny) return fromOrder;

    final offer = order['job_offers'];
    if (offer is Map<String, dynamic>) {
      final post = offer['job_posts'];
      if (post is Map<String, dynamic>) {
        return ShiftSchedule.fromMap(post);
      }
    }
    return const ShiftSchedule();
  }

  static DateTime? parseDate(dynamic raw) {
    if (raw == null) return null;
    if (raw is DateTime) {
      return DateTime(raw.year, raw.month, raw.day);
    }
    final s = raw.toString().trim();
    if (s.isEmpty) return null;
    final d = DateTime.tryParse(s);
    if (d == null) return null;
    return DateTime(d.year, d.month, d.day);
  }

  static TimeOfDay? parseTime(dynamic raw) {
    if (raw == null) return null;
    if (raw is TimeOfDay) return raw;
    final s = raw.toString().trim();
    if (s.isEmpty) return null;
    final parts = s.split(':');
    if (parts.length < 2) return null;
    final h = int.tryParse(parts[0]);
    final m = int.tryParse(parts[1]);
    if (h == null || m == null) return null;
    if (h < 0 || h > 23 || m < 0 || m > 59) return null;
    return TimeOfDay(hour: h, minute: m);
  }

  static String? timeToDb(TimeOfDay? t) {
    if (t == null) return null;
    final hh = t.hour.toString().padLeft(2, '0');
    final mm = t.minute.toString().padLeft(2, '0');
    return '$hh:$mm:00';
  }

  static String? dateToDb(DateTime? d) {
    if (d == null) return null;
    final y = d.year.toString().padLeft(4, '0');
    final m = d.month.toString().padLeft(2, '0');
    final day = d.day.toString().padLeft(2, '0');
    return '$y-$m-$day';
  }

  static String formatTimeOfDay(TimeOfDay t) {
    final hh = t.hour.toString().padLeft(2, '0');
    final mm = t.minute.toString().padLeft(2, '0');
    return '$hh:$mm';
  }

  static String? formatTimeRaw(dynamic raw) {
    final t = parseTime(raw);
    return t == null ? null : formatTimeOfDay(t);
  }

  static String? formatDateRaw(dynamic raw) {
    final d = parseDate(raw);
    if (d == null) return null;
    return DateFormat('d MMM yyyy').format(d);
  }

  /// e.g. `06:00–15:00` or null if incomplete.
  String? get timeWindowLabel {
    if (!hasTimes) return null;
    return '${formatTimeOfDay(shiftStart!)}–${formatTimeOfDay(shiftEnd!)}';
  }

  /// e.g. `28 Aug 2026 · 06:00–15:00` or just the time window / date.
  String? get displayLabel {
    final datePart =
        workDate == null ? null : DateFormat('d MMM yyyy').format(workDate!);
    final timePart = timeWindowLabel;
    if (datePart != null && timePart != null) return '$datePart · $timePart';
    return datePart ?? timePart;
  }

  /// ±1 hour windows around start and end (preferred contact / soft work windows).
  ({TimeOfDay open, TimeOfDay close})? get startChatWindow {
    if (shiftStart == null) return null;
    return (
      open: _addMinutes(shiftStart!, -60),
      close: _addMinutes(shiftStart!, 60),
    );
  }

  ({TimeOfDay open, TimeOfDay close})? get endChatWindow {
    if (shiftEnd == null) return null;
    return (
      open: _addMinutes(shiftEnd!, -60),
      close: _addMinutes(shiftEnd!, 60),
    );
  }

  /// e.g. `05:00–07:00 and 14:00–16:00`
  String? get preferredContactWindowsLabel {
    final start = startChatWindow;
    final end = endChatWindow;
    if (start == null || end == null) return null;
    final a = '${formatTimeOfDay(start.open)}–${formatTimeOfDay(start.close)}';
    final b = '${formatTimeOfDay(end.open)}–${formatTimeOfDay(end.close)}';
    return '$a and $b';
  }

  /// Local device clock vs preferred ±1h windows. Messaging is never blocked.
  bool isWithinPreferredContactWindow([DateTime? now]) {
    final start = startChatWindow;
    final end = endChatWindow;
    if (start == null || end == null) return false;
    final n = now ?? DateTime.now();
    final minutes = n.hour * 60 + n.minute;
    return _minutesInWindow(minutes, start.open, start.close) ||
        _minutesInWindow(minutes, end.open, end.close);
  }

  static bool _minutesInWindow(int minutes, TimeOfDay open, TimeOfDay close) {
    final o = open.hour * 60 + open.minute;
    final c = close.hour * 60 + close.minute;
    if (o <= c) return minutes >= o && minutes <= c;
    // Overnight wrap (e.g. 23:00–01:00)
    return minutes >= o || minutes <= c;
  }

  static TimeOfDay _addMinutes(TimeOfDay t, int delta) {
    final total = (t.hour * 60 + t.minute + delta) % (24 * 60);
    final normalized = total < 0 ? total + (24 * 60) : total;
    return TimeOfDay(hour: normalized ~/ 60, minute: normalized % 60);
  }
}
