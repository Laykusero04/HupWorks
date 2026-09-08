import 'package:flutter/widgets.dart';
import 'package:intl/intl.dart';

/// Locale-aware date labels (EN / NL / BN via [DateFormat]).
class AppDateFormat {
  AppDateFormat._();

  static String localeOf(BuildContext context) =>
      Localizations.localeOf(context).toString();

  /// e.g. `8 Sep 2026`
  static String dMmmY(DateTime date, [String? locale]) =>
      DateFormat('d MMM yyyy', locale).format(date.toLocal());

  /// e.g. `Sep 8, 2026`
  static String mmmDY(DateTime date, [String? locale]) =>
      DateFormat.yMMMd(locale).format(date.toLocal());

  /// e.g. `Monday, 8 Sep 2026`
  static String eeeeDMmmY(DateTime date, [String? locale]) =>
      DateFormat('EEEE, d MMM yyyy', locale).format(date.toLocal());

  /// e.g. `Sep 2026`
  static String mmmY(DateTime date, [String? locale]) =>
      DateFormat('MMM yyyy', locale).format(date.toLocal());

  /// Month abbreviation only, e.g. `Sep`
  static String mmm(DateTime date, [String? locale]) =>
      DateFormat('MMM', locale).format(date.toLocal());

  static String? tryDMmmY(String? iso, [String? locale]) {
    if (iso == null || iso.isEmpty) return null;
    final d = DateTime.tryParse(iso);
    if (d == null) return null;
    return dMmmY(d, locale);
  }

  static String? tryMmmDY(String? iso, [String? locale]) {
    if (iso == null || iso.isEmpty) return null;
    final d = DateTime.tryParse(iso);
    if (d == null) return null;
    return mmmDY(d, locale);
  }
}
