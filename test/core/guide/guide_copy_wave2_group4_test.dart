import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

/// Copy caps (T-0033 section 5.2) for the wave 2 group 4 guides: seller
/// Contracts tab, Applications, Deliver work, Job alerts, hire reader and
/// identity verification.
void main() {
  const prefixes = [
    'guideSellerContracts',
    'guideSellerApps',
    'guideDeliver',
    'guideJobAlerts',
    'guideHireReader',
    'guideIdentity',
  ];

  bool isTitle(String k) => k.endsWith('Title') || k.contains('SectionHired');

  for (final lang in ['en', 'nl']) {
    test('wave 2 group 4 guide copy fits the caps ($lang)', () {
      final arb = jsonDecode(File('lib/l10n/app_$lang.arb').readAsStringSync())
          as Map<String, dynamic>;
      final titleCap = lang == 'en' ? 28 : 36;
      final descCap = lang == 'en' ? 140 : 180;
      var checked = 0;
      for (final e in arb.entries) {
        if (e.key.startsWith('@') || !prefixes.any(e.key.startsWith)) continue;
        final v = e.value as String;
        if (isTitle(e.key)) {
          expect(v.length, lessThanOrEqualTo(titleCap), reason: e.key);
          checked++;
        } else if (e.key.endsWith('Desc')) {
          expect(v.length, lessThanOrEqualTo(descCap), reason: e.key);
          checked++;
        }
      }
      expect(checked, 49);
    });
  }

  test('every group 4 title has a description and an nl twin', () {
    final en = jsonDecode(File('lib/l10n/app_en.arb').readAsStringSync())
        as Map<String, dynamic>;
    final nl = jsonDecode(File('lib/l10n/app_nl.arb').readAsStringSync())
        as Map<String, dynamic>;
    for (final k in en.keys
        .where((k) => prefixes.any(k.startsWith) && k.endsWith('Title'))) {
      expect(en.containsKey('${k.substring(0, k.length - 5)}Desc'), true,
          reason: k);
      expect(nl.containsKey(k), true, reason: k);
    }
  });
}
