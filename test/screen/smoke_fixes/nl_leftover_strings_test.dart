// Regression: English left in the Dutch app (T-0170 device re-check):
// "Reviews", "Top skills", "Live".
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:freelancer/data/models/seller_skill_model.dart';
import 'package:freelancer/l10n/app_localizations.dart';
import 'package:freelancer/screen/widgets/seller_skills_display.dart';

Future<AppLocalizations> _l10n(String code) =>
    AppLocalizations.delegate.load(Locale(code));

void main() {
  test('NL labels are Dutch', () async {
    final nl = await _l10n('nl');
    expect(nl.reviews, 'Beoordelingen');
    expect(nl.periodLive, 'Actueel');
    expect(nl.skillsTierTop, 'Topvaardigheden (5★)');
  });

  test('EN labels unchanged', () async {
    final en = await _l10n('en');
    expect(en.reviews, 'Reviews');
    expect(en.periodLive, 'Live');
    expect(en.skillsTierTop, 'Top skills (5★)');
  });

  for (final code in const ['en', 'nl']) {
    testWidgets('skill tiers render localized ($code)', (tester) async {
      await tester.pumpWidget(MaterialApp(
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        locale: Locale(code),
        home: Scaffold(
          body: SellerSkillsDisplay(skills: [
            SellerSkill.fromJson(const {'name': 'Van Driver', 'stars': 5}),
            SellerSkill.fromJson(const {'name': 'Forklift', 'stars': 4}),
            SellerSkill.fromJson(const {'name': 'Cooking', 'stars': 2}),
          ]),
        ),
      ));
      final l10n = await _l10n(code);
      expect(find.text(l10n.skillsTierTop), findsOneWidget);
      expect(find.text(l10n.skillsTierFour), findsOneWidget);
      expect(find.text(l10n.skillsTierLow), findsOneWidget);
      if (code == 'nl') expect(find.textContaining('skills'), findsNothing);
    });
  }
}
