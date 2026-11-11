import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

/// Copy caps (T-0033 section 5.2) for the wave 2 group 3 guides: client
/// attendance QR display, employer verification, hire onboarding editor.
void main() {
  const prefixes = ['guideQrDisp', 'guideEmpVerif', 'guideOnbEdit'];

  for (final lang in ['en', 'nl']) {
    test('wave 2 group 3 guide copy fits the caps ($lang)', () {
      final arb = jsonDecode(File('lib/l10n/app_$lang.arb').readAsStringSync())
          as Map<String, dynamic>;
      final titleCap = lang == 'en' ? 28 : 36;
      final descCap = lang == 'en' ? 140 : 180;
      var checked = 0;
      for (final e in arb.entries) {
        if (e.key.startsWith('@') || !prefixes.any(e.key.startsWith)) continue;
        final v = e.value as String;
        if (e.key.endsWith('Title')) {
          expect(v.length, lessThanOrEqualTo(titleCap), reason: e.key);
          checked++;
        } else if (e.key.endsWith('Desc')) {
          expect(v.length, lessThanOrEqualTo(descCap), reason: e.key);
          checked++;
        }
      }
      expect(checked, 24);
    });
  }

  test('titles have descriptions and nl twins; verification copy rules', () {
    final en = jsonDecode(File('lib/l10n/app_en.arb').readAsStringSync())
        as Map<String, dynamic>;
    final nl = jsonDecode(File('lib/l10n/app_nl.arb').readAsStringSync())
        as Map<String, dynamic>;
    for (final k in en.keys.where(
        (k) => prefixes.any(k.startsWith) && k.endsWith('Title'))) {
      final d = '${k.substring(0, k.length - 5)}Desc';
      expect(en.containsKey(d), true, reason: k);
      expect(nl.containsKey(k) && nl.containsKey(d), true, reason: k);
    }
    for (final k in en.keys.where((k) => k.startsWith('guideEmpVerif'))) {
      expect((en[k] as String).toLowerCase().contains('required'), false,
          reason: k);
    }
  });
}
