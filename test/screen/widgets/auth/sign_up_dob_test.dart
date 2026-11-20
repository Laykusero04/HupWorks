import 'dart:async';
import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:freelancer/core/constants/colors.dart';
import 'package:freelancer/l10n/app_localizations.dart';
import 'package:freelancer/screen/app_config/app_config.dart';
import 'package:freelancer/screen/widgets/auth/sign_up_screen.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

/// T-0172: sign-up refuses under-16 before any account is created.
/// Supabase is a MockClient on a non-resolvable host; fake data only.
void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  var signUpCalls = 0;
  // Fixed "today" (UTC) so the birthday boundary is timezone-proof.
  final today = DateTime.utc(2026, 11, 20, 12);

  setUpAll(() async {
    GoogleFonts.config.allowRuntimeFetching = false;
    SharedPreferences.setMockInitialValues({});
    final mock = MockClient((request) async {
      if (request.url.path.endsWith('/signup')) {
        signUpCalls++;
        return http.Response(
          jsonEncode({
            'code': 500,
            'error_code': 'unexpected_failure',
            'msg': 'x',
          }),
          500,
          headers: {'content-type': 'application/json'},
        );
      }
      return http.Response('{}', 404,
          headers: {'content-type': 'application/json'});
    });
    await Supabase.initialize(
      url: 'https://qa-test.invalid',
      anonKey: 'qa-test-anon-key',
      httpClient: mock,
      debug: false,
      authOptions: const FlutterAuthClientOptions(
        localStorage: EmptyLocalStorage(),
        detectSessionInUri: false,
      ),
    );
  });

  Future<void> runGuarded(Future<void> Function() body) {
    final done = Completer<void>();
    runZonedGuarded(() async {
      try {
        await body();
        if (!done.isCompleted) done.complete();
      } catch (e, s) {
        if (!done.isCompleted) done.completeError(e, s);
      }
    }, (error, stack) {
      if (error.toString().contains('google_fonts') ||
          error.toString().contains('allowRuntimeFetching')) {
        return;
      }
      if (!done.isCompleted) done.completeError(error, stack);
    });
    return done.future;
  }

  Future<void> pump(
    WidgetTester t, {
    Locale locale = const Locale('en'),
    double scale = 1.0,
    String role = 'client',
    Size size = const Size(375, 667),
  }) async {
    await t.binding.setSurfaceSize(size);
    addTearDown(() => t.binding.setSurfaceSize(null));
    await t.pumpWidget(MaterialApp(
      locale: locale,
      supportedLocales: AppLocalizations.supportedLocales,
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      builder: (c, w) => MediaQuery(
        data: MediaQuery.of(c).copyWith(textScaler: TextScaler.linear(scale)),
        child: w!,
      ),
      home: SignUpScreen(
        role: role,
        accentColor: role == 'seller' ? kSellerPrimary : kPrimaryColor,
        heroImage: AppInfo.onBoard2,
        subtitle: (l) => l.authCreateAccount,
        roleLabel: (l) => 'x',
        onSignedUp: (_, __) async {},
        now: today,
      ),
    ));
    await t.pump();
  }

  Future<void> fillAndSubmit(
    WidgetTester t,
    AppLocalizations l10n, {
    required String d,
    required String m,
    required String y,
    bool terms = true,
  }) async {
    final f = find.byType(TextField);
    await t.enterText(f.at(0), 'QA');
    await t.enterText(f.at(1), 'Tester');
    await t.enterText(f.at(2), 'qa@example.invalid');
    await t.enterText(f.at(3), 'abcdef1!');
    await t.enterText(f.at(4), 'abcdef1!');
    await t.enterText(f.at(5), d);
    await t.enterText(f.at(6), m);
    await t.enterText(f.at(7), y);
    if (terms) {
      await t.ensureVisible(find.byType(Checkbox));
      await t.tap(find.byType(Checkbox));
    }
    await t.pump();
    await t.ensureVisible(find.text(l10n.authSignUpButton));
    await t.tap(find.text(l10n.authSignUpButton));
    await t.pump();
    await t.runAsync(
        () => Future<void>.delayed(const Duration(milliseconds: 300)));
    for (var i = 0; i < 5; i++) {
      await t.pump(const Duration(milliseconds: 100));
    }
  }

  final en = lookupAppLocalizations(const Locale('en'));
  final nl = lookupAppLocalizations(const Locale('nl'));

  for (final role in ['client', 'seller']) {
    testWidgets(
        '$role: under 16 is refused, no signup request is sent',
        (t) => runGuarded(() async {
              signUpCalls = 0;
              await pump(t, role: role);
              // Born 21 Nov 2010: turns 16 tomorrow (15y 364d).
              await fillAndSubmit(t, en, d: '21', m: '11', y: '2010');
              expect(find.text(en.pdDobErrorUnder16), findsOneWidget);
              expect(signUpCalls, 0);
              expect(t.takeException(), isNull);
            }));

    testWidgets(
        '$role: turning 16 today is allowed and signup proceeds',
        (t) => runGuarded(() async {
              signUpCalls = 0;
              await pump(t, role: role);
              await fillAndSubmit(t, en, d: '20', m: '11', y: '2010');
              expect(find.text(en.pdDobErrorUnder16), findsNothing);
              expect(signUpCalls, 1);
              expect(t.takeException(), isNull);
            }));
  }

  testWidgets(
      'empty, impossible and future dates are refused with messages',
      (t) => runGuarded(() async {
            signUpCalls = 0;
            await pump(t);
            await fillAndSubmit(t, en, d: '', m: '', y: '');
            expect(find.text(en.pdDobErrorEmpty), findsOneWidget);

            final f = find.byType(TextField);
            await t.enterText(f.at(5), '31');
            await t.enterText(f.at(6), '02');
            await t.enterText(f.at(7), '2000');
            await t.pump();
            // typing clears the old error
            expect(find.text(en.pdDobErrorEmpty), findsNothing);
            await t.tap(find.text(en.authSignUpButton));
            await t.pump();
            expect(find.text(en.pdDobErrorInvalid), findsOneWidget);

            await t.enterText(f.at(5), '01');
            await t.enterText(f.at(6), '01');
            await t.enterText(f.at(7), '2030');
            await t.tap(find.text(en.authSignUpButton));
            await t.pump();
            expect(find.text(en.pdDobErrorFuture), findsOneWidget);
            expect(signUpCalls, 0);
          }));

  testWidgets(
      'confirm-password mismatch and terms still block (DOB valid)',
      (t) => runGuarded(() async {
            signUpCalls = 0;
            await pump(t);
            final f = find.byType(TextField);
            await t.enterText(f.at(0), 'QA');
            await t.enterText(f.at(1), 'Tester');
            await t.enterText(f.at(2), 'qa@example.invalid');
            await t.enterText(f.at(3), 'abcdef1!');
            await t.enterText(f.at(4), 'different1!');
            await t.enterText(f.at(5), '14');
            await t.enterText(f.at(6), '03');
            await t.enterText(f.at(7), '1998');
            await t.pump();
            await t.ensureVisible(find.text(en.authSignUpButton));
            await t.tap(find.text(en.authSignUpButton));
            await t.pump();
            expect(find.text(en.authPasswordsDoNotMatch), findsWidgets);
            expect(signUpCalls, 0);
          }));

  for (final role in ['client', 'seller']) {
    testWidgets(
        'NL x2.0 on 375pt: $role form scrolls, no overflow',
        (t) => runGuarded(() async {
              await pump(t, locale: const Locale('nl'), scale: 2.0, role: role);
              // Submit with nothing filled to show the DOB error too.
              await t.drag(
                  find.byType(SingleChildScrollView), const Offset(0, -2000));
              await t.pump();
              expect(find.text(nl.pdDobLabel), findsOneWidget);
              expect(find.text(nl.pdDobDay), findsOneWidget);
              expect(t.takeException(), isNull);
              // With the under-16 error text shown (longest NL message).
              final f = find.byType(TextField);
              await t.enterText(f.at(5), '21');
              await t.enterText(f.at(6), '11');
              await t.enterText(f.at(7), '2010');
              await t.enterText(f.at(0), 'QA');
              await t.enterText(f.at(1), 'Tester');
              await t.enterText(f.at(2), 'qa@example.invalid');
              await t.enterText(f.at(3), 'abcdef1!');
              await t.enterText(f.at(4), 'abcdef1!');
              await t.ensureVisible(find.byType(Checkbox));
              await t.tap(find.byType(Checkbox));
              await t.pump();
              await t.ensureVisible(find.text(nl.authSignUpButton));
              await t.tap(find.text(nl.authSignUpButton));
              await t.pump();
              expect(find.text(nl.pdDobErrorUnder16), findsOneWidget);
              expect(t.takeException(), isNull);
            }));
  }
}
