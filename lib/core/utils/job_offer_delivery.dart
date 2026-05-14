/// Job offer `delivery_time` is stored with [deliveryTimeUnit]: `hours` or `days`.
class JobOfferDelivery {
  JobOfferDelivery._();

  static const String hours = 'hours';
  static const String days = 'days';

  static String normalizeUnit(Object? raw) {
    final s = raw?.toString().toLowerCase().trim() ?? '';
    if (s == hours) return hours;
    return days;
  }

  /// Human-readable label for lists and detail rows.
  static String formatLabel(Object? value, [Object? unit]) {
    if (value == null) return 'Agreed in chat';
    final n = _parseInt(value);
    if (n <= 0) return '—';
    final u = normalizeUnit(unit);
    if (u == hours) {
      return n == 1 ? '1 hour' : '$n hours';
    }
    return n == 1 ? '1 day' : '$n days';
  }

  /// Compact chip text (e.g. job cards).
  static String formatShort(Object? value, [Object? unit]) {
    if (value == null) return '—';
    final n = _parseInt(value);
    if (n <= 0) return '—';
    return normalizeUnit(unit) == hours ? '${n}h' : '${n}d';
  }

  static int _parseInt(Object? value) {
    if (value is int) return value;
    if (value is num) return value.round();
    return int.tryParse(value?.toString() ?? '') ?? 0;
  }
}
