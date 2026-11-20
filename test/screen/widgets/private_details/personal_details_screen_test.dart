import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:freelancer/core/constants/colors.dart';
import 'package:freelancer/data/models/user_private_details.dart';
import 'package:freelancer/l10n/app_localizations.dart';
import 'package:freelancer/screen/widgets/private_details/personal_details_screen.dart';
import 'package:freelancer/services/personal_details_gate.dart';
import 'package:freelancer/services/user_private_details_service.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../support/pd_harness.dart';

/// T-0172: first-sign-in date of birth + consent screen. No network.
void main() {
  setUpAll(pdSetUp);

  final en = lookupAppLocalizations(const Locale('en'));
  final nl = lookupAppLocalizations(const Locale('nl'));
  final today = DateTime.utc(2026, 11, 20, 12);

  late List<Map<String, Object?>> saved;
  late int done;
  late int skipped;
  late int signedOut;
  Object? failWith;
  UserPrivateDetails? existing;

  Widget screen({
    Color accent = kPrimaryColor,
    bool fromTrust = false,
    List<Uri>? opened,
  }) =>
      PersonalDetailsScreen(
        accent: accent,
        fromTrust: fromTrust,
        now: today,
        onDone: () => done++,
        onSkip: () async => skipped++,
        onSignOut: () async => signedOut++,
        loader: () async => existing,
        launcher: (uri) async {
          opened?.add(uri);
          return true;
        },
        saver: ({dateOfBirth, consentVersion}) async {
          if (failWith != null) throw failWith!;
          saved.add({'dob': dateOfBirth, 'consent': consentVersion});
        },
      );

  setUp(() {
    saved = [];
    done = 0;
    skipped = 0;
    signedOut = 0;
    failWith = null;
    existing = null;
    PersonalDetailsGate.reset();
  });

  Future<void> fill(WidgetTester t, String d, String m, String y) async {
    final f = find.byType(TextField);
    await t.enterText(f.at(0), d);
    await t.enterText(f.at(1), m);
    await t.enterText(f.at(2), y);
    await t.pump();
  }

  Future<void> tapText(WidgetTester t, String s) async {
    await t.ensureVisible(find.text(s));
    await t.tap(find.text(s));
    await t.pump();
  }

  testWidgets('empty form: DOB and consent errors, nothing saved', (t) async {
    await pdPump(t, screen());
    await tapText(t, en.continueLabel);
    expect(find.text(en.pdDobErrorEmpty), findsOneWidget);
    expect(find.text(en.pdConsentRequired), findsOneWidget);
    expect(saved, isEmpty);
    expect(done, 0);
  });

  testWidgets('under 16: refused, nothing saved, sign-out link offered',
      (t) async {
    await pdPump(t, screen());
    await fill(t, '21', '11', '2010'); // 15y 364d
    await t.tap(find.byType(Checkbox));
    await t.pump();
    await tapText(t, en.continueLabel);
    expect(find.text(en.pdDobErrorUnder16), findsOneWidget);
    expect(saved, isEmpty);
    expect(done, 0);
    await t.ensureVisible(find.text(en.logOut));
    await t.tap(find.text(en.logOut));
    expect(signedOut, 1);
  });

  testWidgets('exactly 16 today + consent saves DOB and consent version',
      (t) async {
    await pdPump(t, screen());
    await fill(t, '20', '11', '2010');
    await t.tap(find.byType(Checkbox));
    await t.pump();
    await tapText(t, en.continueLabel);
    expect(saved, hasLength(1));
    expect(saved.single['dob'], DateTime(2010, 11, 20));
    expect(saved.single['consent'], 'privacy-2026-11');
    expect(done, 1);
    expect(PersonalDetailsGate.needsPrompt, isFalse);
  });

  testWidgets('consent unticked blocks even with a valid date', (t) async {
    await pdPump(t, screen());
    await fill(t, '14', '03', '1998');
    await tapText(t, en.continueLabel);
    expect(find.text(en.pdConsentRequired), findsOneWidget);
    expect(find.text(en.pdDobErrorEmpty), findsNothing);
    expect(saved, isEmpty);
  });

  testWidgets('skip is allowed, remembered via onSkip, saves nothing',
      (t) async {
    await pdPump(t, screen());
    await tapText(t, en.skipForNow);
    expect(skipped, 1);
    expect(done, 1);
    expect(saved, isEmpty);
  });

  testWidgets('opened from the trust item: no skip button, shows back',
      (t) async {
    await pdPump(t, screen(fromTrust: true));
    expect(find.text(en.skipForNow), findsNothing);
    expect(find.text(en.pdSkipHint), findsNothing);
  });

  testWidgets('server error: friendly banner, input kept, Try again works',
      (t) async {
    failWith = Exception('boom: SECRET-RAW-DETAIL');
    await pdPump(t, screen());
    await fill(t, '14', '03', '1998');
    await t.tap(find.byType(Checkbox));
    await t.pump();
    await tapText(t, en.continueLabel);
    await t.pump();
    expect(find.text(en.pdSaveError), findsOneWidget);
    expect(find.textContaining('SECRET-RAW-DETAIL'), findsNothing);
    expect(find.text(en.pdTryAgain), findsOneWidget);
    expect(done, 0);
    // values kept
    expect(find.text('1998'), findsOneWidget);

    failWith = null;
    await tapText(t, en.pdTryAgain);
    expect(saved, hasLength(1));
    expect(done, 1);
  });

  testWidgets('validation exception from the service maps to under-16 text',
      (t) async {
    failWith = const PrivateDetailsValidationException(
        PrivateDetailsField.dateOfBirth);
    await pdPump(t, screen());
    await fill(t, '14', '03', '1998');
    await t.tap(find.byType(Checkbox));
    await t.pump();
    await tapText(t, en.continueLabel);
    expect(find.text(en.pdDobErrorUnder16), findsOneWidget);
    expect(done, 0);
  });

  testWidgets('DB check violation (23514) shows a friendly message', (t) async {
    failWith = const PostgrestException(
        message: 'new row violates check constraint "user_private_details_dob"',
        code: '23514');
    await pdPump(t, screen());
    await fill(t, '14', '03', '1998');
    await t.tap(find.byType(Checkbox));
    await t.pump();
    await tapText(t, en.continueLabel);
    expect(find.text(en.pdInvalidValue), findsOneWidget);
    expect(find.textContaining('check constraint'), findsNothing);
  });

  testWidgets('stored DOB is prefilled', (t) async {
    existing =
        UserPrivateDetails(userId: 'u', dateOfBirth: DateTime(1990, 5, 7));
    await pdPump(t, screen());
    expect(find.text('07'), findsOneWidget);
    expect(find.text('05'), findsOneWidget);
    expect(find.text('1990'), findsOneWidget);
  });

  testWidgets('links open the privacy and terms pages without toggling',
      (t) async {
    final opened = <Uri>[];
    await pdPump(t, screen(opened: opened));
    Future<void> tapLink(String s) async {
      final rich = find.byWidgetPredicate((w) =>
          w is RichText && w.text.toPlainText().contains(en.pdConsentIntro));
      await t.ensureVisible(rich);
      await t.tapOnText(find.textRange.ofSubstring(s));
      await t.pump();
    }

    await tapLink(en.pdConsentPrivacy);
    await tapLink(en.pdConsentTerms);
    expect(opened.map((u) => u.toString()), [
      'https://hupworks-web.vercel.app/privacy.html',
      'https://hupworks-web.vercel.app/terms.html',
    ]);
    expect(t.widget<Checkbox>(find.byType(Checkbox)).value, isFalse);
    // version caption is shown
    expect(find.text(en.pdConsentVersionCaption('privacy-2026-11')),
        findsOneWidget);
  });

  testWidgets('tapping the consent text toggles the box', (t) async {
    await pdPump(t, screen());
    await t.tapAt(t.getCenter(find.byType(Checkbox)) + const Offset(60, 0));
    await t.pump();
    expect(t.widget<Checkbox>(find.byType(Checkbox)).value, isTrue);
  });

  for (final role in ['client', 'seller']) {
    final accent = role == 'seller' ? kSellerPrimary : kPrimaryColor;
    for (final scale in [1.0, 2.0]) {
      testWidgets('NL x$scale on 375pt ($role): no overflow, with errors',
          (t) async {
        await pdPump(t, screen(accent: accent),
            locale: const Locale('nl'), scale: scale);
        expect(find.text(nl.pdTitle), findsOneWidget);
        // all errors at once: empty DOB + consent
        await t.ensureVisible(find.text(nl.continueLabel));
        await t.tap(find.text(nl.continueLabel));
        await t.pump();
        expect(find.text(nl.pdDobErrorEmpty), findsOneWidget);
        expect(find.text(nl.pdConsentRequired), findsOneWidget);
        // longest error (under 16) + server error banner
        failWith = Exception('x');
        await fill(t, '21', '11', '2010');
        await t.ensureVisible(find.byType(Checkbox));
        await t.tap(find.byType(Checkbox));
        await t.pump();
        await t.ensureVisible(find.text(nl.continueLabel));
        await t.tap(find.text(nl.continueLabel));
        await t.pump();
        expect(find.text(nl.pdDobErrorUnder16), findsOneWidget);
        // Continue + Skip stay reachable (docked action bar).
        expect(find.text(nl.continueLabel), findsOneWidget);
        expect(find.text(nl.skipForNow), findsOneWidget);
        expect(t.takeException(), isNull);
      });
    }
  }
}
