import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

/// Copy caps (T-0033 section 5.2) for the group C guides: Find Jobs, seller
/// job details, apply form and the setup wizard.
void main() {
  const prefixes = ['guideFindJobs', 'guideSellerJob', 'guideApply', 'guideSetup'];

  for (final lang in ['en', 'nl']) {
    test('group C guide copy fits the caps ($lang)', () {
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
      expect(checked, greaterThan(60));
    });
  }

  test('every group C title has a description and an nl twin', () {
    final en = jsonDecode(File('lib/l10n/app_en.arb').readAsStringSync())
        as Map<String, dynamic>;
    final nl = jsonDecode(File('lib/l10n/app_nl.arb').readAsStringSync())
        as Map<String, dynamic>;
    for (final k in en.keys.where((k) =>
        prefixes.any(k.startsWith) && k.endsWith('Title'))) {
      expect(en.containsKey('${k.substring(0, k.length - 5)}Desc'), true,
          reason: k);
      expect(nl.containsKey(k), true, reason: k);
    }
  });
}
