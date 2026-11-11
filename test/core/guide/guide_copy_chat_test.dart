import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

/// Copy caps (T-0033 section 5.2) for the chat conversation guide (guideChat*).
void main() {
  for (final lang in ['en', 'nl']) {
    test('chat guide copy fits the caps ($lang)', () {
      final arb = jsonDecode(File('lib/l10n/app_$lang.arb').readAsStringSync())
          as Map<String, dynamic>;
      final titleCap = lang == 'en' ? 28 : 36;
      final descCap = lang == 'en' ? 140 : 180;
      var checked = 0;
      for (final e in arb.entries) {
        if (!e.key.startsWith('guideChat')) continue;
        final v = e.value as String;
        if (e.key.endsWith('Title') || e.key.contains('Section')) {
          expect(v.length, lessThanOrEqualTo(titleCap), reason: e.key);
          checked++;
        } else if (e.key.endsWith('Desc')) {
          expect(v.length, lessThanOrEqualTo(descCap), reason: e.key);
          checked++;
        }
      }
      expect(checked, 14);
    });
  }
}
