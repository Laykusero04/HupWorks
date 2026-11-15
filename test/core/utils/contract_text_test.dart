import 'package:flutter_test/flutter_test.dart';
import 'package:freelancer/core/utils/contract_text.dart';
import 'package:freelancer/l10n/app_localizations.dart';
import 'package:freelancer/l10n/app_localizations_bn.dart';
import 'package:freelancer/l10n/app_localizations_en.dart';
import 'package:freelancer/l10n/app_localizations_nl.dart';

void main() {
  test('money: locale-aware currency format', () {
    String nbspFree(String s) => s.replaceAll(' ', ' ');
    expect(nbspFree(ContractText.money(100.0, 'nl')), '€ 100,00');
    expect(nbspFree(ContractText.money('100.0', 'nl')), '€ 100,00');
    expect(ContractText.money(100, 'en'), '€100.00');
    expect(ContractText.money(null, 'en'), '€0.00');
    expect(ContractText.money(1234.5, 'en'), '€1,234.50');
  });

  test('legacy English contract strings map to every locale', () {
    final nl = AppLocalizationsNl();
    final en = AppLocalizationsEn();
    final bn = AppLocalizationsBn();
    for (final AppLocalizations l in [nl, en, bn]) {
      expect(ContractText.localizeLegacy(l, 'Agreed in chat'),
          l.contractAgreedInChat);
      expect(ContractText.localizeLegacy(l, 'Per job agreement'),
          l.contractPerJobAgreement);
      expect(ContractText.localizeLegacy(l, 'Unlimited Revisions'),
          l.contractUnlimitedRevisions);
    }
    expect(ContractText.localizeLegacy(nl, 'Agreed in chat'),
        'Afgesproken in de chat');
    expect(ContractText.localizeLegacy(nl, '3 days'), '3 dagen');
    expect(ContractText.localizeLegacy(nl, '1 hour'), '1 uur');
    expect(ContractText.localizeLegacy(nl, '2 Revisions'), '2 revisies');
    expect(ContractText.localizeLegacy(en, '1 day'), '1 day');
    // Unknown text and em dash are untouched (stored data is never changed).
    expect(ContractText.localizeLegacy(nl, 'Two weeks'), 'Two weeks');
    expect(ContractText.localizeLegacy(nl, '—'), '—');
  });
}
