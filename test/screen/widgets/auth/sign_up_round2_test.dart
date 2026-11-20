import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:freelancer/core/constants/colors.dart';
import 'package:freelancer/l10n/app_localizations.dart';
import 'package:freelancer/screen/app_config/app_config.dart';
import 'package:freelancer/screen/widgets/auth/sign_up_screen.dart';

import '../../../support/pd_harness.dart';

/// T-0172 fix round 2 (signup): reason line under the DOB, DOB + Terms + field
/// errors shown together, Terms inline, no support promise in the under-16
/// message, birthday autofill hints, pasted dates. No network.
void main() {
  setUpAll(pdSetUp);

  final en = lookupAppLocalizations(const Locale('en'));
  final nl = lookupAppLocalizations(const Locale('nl'));
  final today = DateTime.utc(2026, 11, 20, 12);

  Widget screen(String role) => SignUpScreen(
        role: role,
        accentColor: role == 'seller' ? kSellerPrimary : kPrimaryColor,
        heroImage: AppInfo.onBoard2,
        subtitle: (l) => l.authCreateAccount,
        roleLabel: (l) => 'x',
        onSignedUp: (_, __) async {},
        now: today,
      );

  Future<void> tapSignUp(WidgetTester t, AppLocalizations l) async {
    await t.ensureVisible(find.text(l.authSignUpButton));
    await t.tap(find.text(l.authSignUpButton));
    await t.pump();
  }

  testWidgets('helper line explains why the date is asked (EN, NL)', (t) async {
    await pdPump(t, screen('client'));
    expect(find.text('You must be 16 or older. We keep this private.'),
        findsOneWidget);
    await pdPump(t, screen('client'), locale: const Locale('nl'));
    expect(find.text('Je moet 16 of ouder zijn. We houden dit privé.'),
        findsOneWidget);
  });

  testWidgets('helper line sits directly under the Day/Month/Year row',
      (t) async {
    await pdPump(t, screen('client'));
    final helper = t.getTopLeft(
        find.text('You must be 16 or older. We keep this private.'));
    final year = t.getBottomLeft(find.byType(TextField).at(7));
    final label = t.getTopLeft(find.text(en.pdDobLabel));
    final terms = t.getTopLeft(find.byType(Checkbox));
    expect(helper.dy, greaterThan(year.dy)); // below the boxes
    expect(helper.dy - year.dy, lessThan(24)); // directly under
    expect(helper.dy, greaterThan(label.dy)); // not above the label
    expect(helper.dy, lessThan(terms.dy)); // above the Terms row
  });

  testWidgets('empty form: snackbar plus inline DOB and Terms errors together',
      (t) async {
    await pdPump(t, screen('client'));
    await tapSignUp(t, en);
    expect(find.text(en.pleaseFillAllFields), findsOneWidget);
    expect(find.text(en.pdDobErrorEmpty), findsOneWidget);
    expect(find.text(en.authMustAgreeTerms), findsOneWidget);
  });

  testWidgets(
      'valid fields but bad DOB and unticked Terms: both inline at once',
      (t) async {
    await pdPump(t, screen('seller'));
    final f = find.byType(TextField);
    await t.enterText(f.at(0), 'QA');
    await t.enterText(f.at(1), 'Tester');
    await t.enterText(f.at(2), 'qa@example.invalid');
    await t.enterText(f.at(3), 'abcdef1!');
    await t.enterText(f.at(4), 'abcdef1!');
    await t.enterText(f.at(5), '21');
    await t.enterText(f.at(6), '11');
    await t.enterText(f.at(7), '2010');
    await t.pump();
    await tapSignUp(t, en);
    expect(find.text(en.pdDobErrorUnder16), findsOneWidget);
    expect(find.text(en.authMustAgreeTerms), findsOneWidget);
    // Ticking Terms clears only the Terms error.
    await t.ensureVisible(find.byType(Checkbox));
    await t.tap(find.byType(Checkbox));
    await t.pump();
    expect(find.text(en.authMustAgreeTerms), findsNothing);
    expect(find.text(en.pdDobErrorUnder16), findsOneWidget);
  });

  test('under-16 message does not point to unreachable support', () {
    for (final l in [en, nl]) {
      expect(l.pdDobErrorUnder16.toLowerCase(), isNot(contains('support')));
    }
    expect(en.pdDobErrorUnder16,
        'You must be 16 or older to sign up for HupWorks.');
  });

  testWidgets('birthday autofill hints on the three boxes', (t) async {
    await pdPump(t, screen('client'));
    final hints = [
      for (final i in [5, 6, 7])
        t.widget<TextField>(find.byType(TextField).at(i)).autofillHints
    ];
    expect(hints, [
      [AutofillHints.birthdayDay],
      [AutofillHints.birthdayMonth],
      [AutofillHints.birthdayYear],
    ]);
  });

  testWidgets('pasting a full date into any DOB box fills all three',
      (t) async {
    await pdPump(t, screen('client'));
    await t.enterText(find.byType(TextField).at(6), '01/02/2008');
    await t.pump();
    final f = find.byType(TextField);
    expect(t.widget<TextField>(f.at(5)).controller!.text, '01');
    expect(t.widget<TextField>(f.at(6)).controller!.text, '02');
    expect(t.widget<TextField>(f.at(7)).controller!.text, '2008');
  });

  for (final role in ['client', 'seller']) {
    testWidgets('NL x2.0 on 375pt ($role): all errors at once, no overflow',
        (t) async {
      await pdPump(t, screen(role), locale: const Locale('nl'), scale: 2.0);
      await tapSignUp(t, nl);
      expect(find.text(nl.authMustAgreeTerms), findsOneWidget);
      expect(find.text(nl.pdDobErrorEmpty), findsOneWidget);
      expect(t.takeException(), isNull);
    });
  }
}
