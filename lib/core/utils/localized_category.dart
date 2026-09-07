import 'package:flutter/widgets.dart';

/// Resolves localized category display strings from DB rows.
///
/// Prefers `name_i18n` / `description_i18n` maps (`en` / `nl` / `bn`),
/// then falls back to canonical English `name` / `description`.
abstract final class LocalizedCategory {
  static const supportedCodes = <String>['en', 'nl', 'bn'];

  static String languageCodeOf(BuildContext context) {
    return Localizations.localeOf(context).languageCode;
  }

  static String name(
    Map<String, dynamic>? category,
    String languageCode, {
    String fallback = '',
  }) {
    if (category == null) return fallback;
    final fromI18n = _pick(category['name_i18n'], languageCode);
    if (fromI18n != null) return fromI18n;
    final canonical = (category['name'] as String?)?.trim();
    if (canonical != null && canonical.isNotEmpty) return canonical;
    return fallback;
  }

  static String description(
    Map<String, dynamic>? category,
    String languageCode, {
    String fallback = '',
  }) {
    if (category == null) return fallback;
    final fromI18n = _pick(category['description_i18n'], languageCode);
    if (fromI18n != null) return fromI18n;
    final canonical = (category['description'] as String?)?.trim();
    if (canonical != null && canonical.isNotEmpty) return canonical;
    return fallback;
  }

  /// True if [query] matches the localized name, English name, or any i18n value.
  static bool matchesSearch(
    Map<String, dynamic> category,
    String query,
    String languageCode,
  ) {
    final q = query.trim().toLowerCase();
    if (q.isEmpty) return true;

    final candidates = <String>{
      name(category, languageCode).toLowerCase(),
      (category['name'] as String? ?? '').toLowerCase(),
    };

    final i18n = category['name_i18n'];
    if (i18n is Map) {
      for (final value in i18n.values) {
        final s = value?.toString().trim().toLowerCase();
        if (s != null && s.isNotEmpty) candidates.add(s);
      }
    }

    return candidates.any((c) => c.contains(q));
  }

  static String? _pick(dynamic i18n, String languageCode) {
    if (i18n is! Map) return null;
    final primary = i18n[languageCode]?.toString().trim();
    if (primary != null && primary.isNotEmpty) return primary;
    final en = i18n['en']?.toString().trim();
    if (en != null && en.isNotEmpty) return en;
    return null;
  }
}
