import 'package:intl/intl.dart';

import 'package:freelancer/l10n/app_localizations.dart';

/// Display-time helpers for contract rows (T-0159 B9). Nothing here changes
/// stored data: legacy English values written by older builds are mapped to
/// localized strings when shown.
class ContractText {
  ContractText._();

  /// Money for the current locale, e.g. "€ 100,00" (nl) / "€100.00" (en).
  /// Accepts num or numeric String; anything else counts as 0.
  static String money(Object? value, String localeName) {
    final n = value is num ? value : num.tryParse('${value ?? ''}') ?? 0;
    String name;
    try {
      name = Intl.canonicalizedLocale(localeName);
    } catch (_) {
      name = 'en';
    }
    return NumberFormat.currency(locale: name, symbol: '€', decimalDigits: 2)
        .format(n);
  }

  /// Known legacy English phrases that older builds stored/derived. Returns
  /// the localized text for those, [raw] unchanged for anything else.
  static String localizeLegacy(AppLocalizations l10n, String raw) {
    switch (raw.trim().toLowerCase()) {
      case 'agreed in chat':
        return l10n.contractAgreedInChat;
      case 'per job agreement':
        return l10n.contractPerJobAgreement;
      case 'unlimited revisions':
        return l10n.contractUnlimitedRevisions;
    }
    final m = RegExp(r'^(\d+) (day|days|hour|hours|revision|revisions)$',
            caseSensitive: false)
        .firstMatch(raw.trim());
    if (m != null) {
      final n = int.parse(m.group(1)!);
      final unit = m.group(2)!.toLowerCase();
      if (unit.startsWith('day')) return l10n.contractDurationDays(n);
      if (unit.startsWith('hour')) return l10n.contractDurationHours(n);
      return l10n.contractRevisionsCount(n);
    }
    return raw;
  }
}
