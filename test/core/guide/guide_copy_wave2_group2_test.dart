import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

/// Copy caps (T-0033 section 5.2) for wave 2 group 2 guides: client Contracts
/// tab, My Jobs tab, client Applications and client contract details.
void main() {
  const prefixes = [
    'guideContracts',
    'guideMyJobs',
    'guideApplications',
    'guideContractDetails',
  ];

  for (final lang in ['en', 'nl']) {
    test('wave 2 group 2 guide copy fits the caps ($lang)', () {
      final arb = jsonDecode(File('lib/l10n/app_$lang.arb').readAsStringSync())
          as Map<String, dynamic>;
      final titleCap = lang == 'en' ? 28 : 36;
      final descCap = lang == 'en' ? 140 : 180;
      var checked = 0;
      for (final e in arb.entries) {
        if (e.key.startsWith('@') || !prefixes.any(e.key.startsWith)) continue;
        final v = e.value as String;
        if (e.key.endsWith('Title') || e.key.contains('Section')) {
          expect(v.length, lessThanOrEqualTo(titleCap), reason: e.key);
          checked++;
        } else if (e.key.endsWith('Desc')) {
          expect(v.length, lessThanOrEqualTo(descCap), reason: e.key);
          checked++;
        }
      }
      expect(checked, greaterThanOrEqualTo(38));
    });
  }

  test('every wave 2 group 2 title has a description and an nl twin', () {
    final en = jsonDecode(File('lib/l10n/app_en.arb').readAsStringSync())
        as Map<String, dynamic>;
    final nl = jsonDecode(File('lib/l10n/app_nl.arb').readAsStringSync())
        as Map<String, dynamic>;
    final titles = en.keys
        .where((k) => prefixes.any(k.startsWith) && k.endsWith('Title'));
    expect(titles.length, greaterThanOrEqualTo(17));
    for (final k in titles) {
      expect(en.containsKey('${k.substring(0, k.length - 5)}Desc'), true,
          reason: k);
      expect(nl.containsKey(k), true, reason: k);
    }
  });
}
