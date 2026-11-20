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

/// T-0161 QA: the sign-up screen must show the friendly, localized auth error
/// (never the raw AuthApiException text) when Supabase signUp fails.
///
/// Supabase is initialised against a non-resolvable host with a MockClient, so
/// no request leaves the test process. Test data is fake.
///
/// Known harness limits (not app bugs):
/// - google_fonts cannot load Inter in tests (no bundled font asset). Its
///   async load error is ignored by [runGuarded]; text falls back to the test
///   font. Font-size/overflow results at XL are therefore approximate.
/// - Supabase's HTTP call only completes on the real event loop, so the
///   submit step uses tester.runAsync.
void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late http.Response Function() nextSignUpResponse;
  late bool Function() networkDown;

  setUpAll(() async {
    GoogleFonts.config.allowRuntimeFetching = false;
    SharedPreferences.setMockInitialValues({});
    nextSignUpResponse = () => http.Response('{}', 500);
    networkDown = () => false;

    final mock = MockClient((request) async {
      if (networkDown()) {
        throw http.ClientException('Connection refused', request.url);
      }
      if (request.url.path.endsWith('/signup')) {
        return nextSignUpResponse();
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

  http.Response apiError(int status, String errorCode, String msg) =>
      http.Response(
        jsonEncode({'code': status, 'error_code': errorCode, 'msg': msg}),
        status,
        headers: {'content-type': 'application/json'},
      );

  /// Runs [body] in a child zone that drops google_fonts load errors only.
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

  Future<void> pumpSignUp(
    WidgetTester tester, {
    required Locale locale,
    double textScale = 1.0,
  }) async {
    await tester.binding.setSurfaceSize(const Size(390, 844));
    addTearDown(() => tester.binding.setSurfaceSize(null));
    await tester.pumpWidget(
      MaterialApp(
        locale: locale,
        supportedLocales: AppLocalizations.supportedLocales,
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        builder: (context, child) => MediaQuery(
          data: MediaQuery.of(context).copyWith(
            textScaler: TextScaler.linear(textScale),
          ),
          child: child!,
        ),
        home: SignUpScreen(
          role: 'client',
          accentColor: kPrimaryFill,
          heroImage: AppInfo.onBoard2,
          subtitle: (l) => l.authCreateAccount,
          roleLabel: (l) => 'Employer',
          onSignedUp: (_, __) async {},
        ),
      ),
    );
    await tester.pump();
  }

  /// Fills the form with fake data, ticks terms and taps Sign up, then lets
  /// the real async Supabase call finish and the snackbar appear.
  Future<void> submitSignUp(WidgetTester tester, AppLocalizations l10n) async {
    final fields = find.byType(TextField);
    // 5 text fields + 3 date-of-birth fields (T-0172).
    expect(fields, findsNWidgets(8));
    await tester.enterText(fields.at(0), 'QA');
    await tester.enterText(fields.at(1), 'Tester');
    await tester.enterText(fields.at(2), 'qa.tester@example.invalid');
    await tester.enterText(fields.at(3), 'not-a-real-pass');
    await tester.enterText(fields.at(4), 'not-a-real-pass');
    await tester.enterText(fields.at(5), '14');
    await tester.enterText(fields.at(6), '03');
    await tester.enterText(fields.at(7), '1998');
    await tester.ensureVisible(find.byType(Checkbox));
    await tester.tap(find.byType(Checkbox));
    await tester.pump();

    await tester.ensureVisible(find.text(l10n.authSignUpButton));
    await tester.tap(find.text(l10n.authSignUpButton));
    await tester.pump();
    await tester.runAsync(
        () => Future<void>.delayed(const Duration(milliseconds: 300)));
    for (var i = 0; i < 5; i++) {
      await tester.pump(const Duration(milliseconds: 100));
    }
  }

  final en = lookupAppLocalizations(const Locale('en'));
  final nl = lookupAppLocalizations(const Locale('nl'));

  testWidgets(
      'database error (500) shows friendly EN text, not raw exception',
      (tester) => runGuarded(() async {
            networkDown = () => false;
            nextSignUpResponse = () => apiError(
                500, 'unexpected_failure', 'Database error saving new user');
            await pumpSignUp(tester, locale: const Locale('en'));
            await submitSignUp(tester, en);

            expect(find.text(en.authErrorServer), findsOneWidget);
            expect(find.textContaining('AuthApiException'), findsNothing);
            expect(find.textContaining('Database error saving new user'),
                findsNothing);
            expect(find.textContaining('statusCode'), findsNothing);
            expect(find.textContaining('Error:'), findsNothing);
            expect(tester.takeException(), isNull);
          }));

  testWidgets(
      'rate limit (429) shows friendly NL text at XL text scale',
      (tester) => runGuarded(() async {
            networkDown = () => false;
            nextSignUpResponse = () => apiError(
                429, 'over_email_send_rate_limit', 'email rate limit exceeded');
            await pumpSignUp(tester,
                locale: const Locale('nl'), textScale: 1.5);
            await submitSignUp(tester, nl);

            expect(find.text(nl.authErrorRateLimit), findsOneWidget);
            expect(find.textContaining('AuthApiException'), findsNothing);
            expect(find.textContaining('rate limit'), findsNothing);
            expect(tester.takeException(), isNull);
          }));

  testWidgets(
      'network failure shows the network message, not generic',
      (tester) => runGuarded(() async {
            networkDown = () => true;
            await pumpSignUp(tester, locale: const Locale('en'));
            await submitSignUp(tester, en);

            expect(find.text(en.authErrorNetwork), findsOneWidget);
            expect(find.text(en.authErrorGeneric), findsNothing);
            expect(tester.takeException(), isNull);
            networkDown = () => false;
          }));
}
