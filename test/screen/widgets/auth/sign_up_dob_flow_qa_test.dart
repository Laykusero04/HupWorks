import 'dart:async';
import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:freelancer/core/constants/colors.dart';
import 'package:freelancer/l10n/app_localizations.dart';
import 'package:freelancer/screen/app_config/app_config.dart';
import 'package:freelancer/screen/widgets/auth/sign_up_screen.dart';
import 'package:freelancer/services/personal_details_gate.dart';
import 'package:freelancer/services/user_private_details_service.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../support/pd_harness.dart';
import '../../../support/qa_supabase.dart';

/// T-0172 QA: a real sign-up submit with a date of birth, on both auth paths.
///   - session returned (confirm email off): DOB is written during sign-up
///   - no session (confirm email on): nothing written, DOB held in memory, and
///     written on the first sign-in with the same email (any case)
///   - write fails during sign-up: sign-up still completes, DOB kept for retry
/// Auth is a MockClient on a non-resolvable host. Fake data only.
/// postgrest reads `response.request`, which MockClient leaves null (see
/// test/support/qa_supabase.dart), so answer through a BaseClient instead.
class _AuthRouter extends http.BaseClient {
  _AuthRouter(this.handle);
  final Future<http.Response> Function(http.Request request) handle;

  @override
  Future<http.StreamedResponse> send(http.BaseRequest request) async {
    final bytes = await request.finalize().toBytes();
    final req = http.Request(request.method, request.url)
      ..headers.addAll(request.headers)
      ..bodyBytes = bytes;
    final res = await handle(req);
    return http.StreamedResponse(
      Stream.value(res.bodyBytes),
      res.statusCode,
      headers: res.headers,
      request: request,
    );
  }
}

/// What PostgREST answers for a maybeSingle() with no row.
http.Response _noRow() => http.Response(
      jsonEncode({
        'code': 'PGRST116',
        'message': 'JSON object requested, multiple (or no) rows returned',
        'details': 'The result contains 0 rows',
        'hint': null,
      }),
      406,
      headers: {'content-type': 'application/json'},
    );

void main() {
  setUpAll(pdSetUp);

  // Mutable fake backend state.
  var returnSession = true;
  var writeFails = false;
  var signupCalls = 0;
  late List<Map<String, dynamic>> writes;
  String? signupEmail;

  setUpAll(() async {
    final mock = _AuthRouter((request) async {
      final path = request.url.path;
      if (path.endsWith('/signup')) {
        signupCalls++;
        final body = jsonDecode(request.body) as Map<String, dynamic>;
        signupEmail = body['email'] as String?;
        final user = {
          'id': qaSignedInUserId,
          'aud': 'authenticated',
          'role': 'authenticated',
          'email': signupEmail,
          'app_metadata': <String, dynamic>{},
          'user_metadata': <String, dynamic>{},
          'created_at': '2026-01-01T00:00:00Z',
        };
        final payload = returnSession
            ? {
                ...(jsonDecode(qaSessionJson()) as Map<String, dynamic>),
                'user': user,
              }
            : user;
        return http.Response(jsonEncode(payload), 200,
            headers: {'content-type': 'application/json'});
      }
      final segs = request.url.pathSegments;
      final table = segs.isEmpty ? '' : segs.last;
      if (table == UserPrivateDetailsService.table) {
        if (request.method == 'POST') {
          if (writeFails) {
            return http.Response('{"message":"x"}', 500,
                headers: {'content-type': 'application/json'});
          }
          writes.add(jsonDecode(request.body) as Map<String, dynamic>);
          return http.Response('', 201);
        }
        // GET maybeSingle() asks for application/json: no row is an empty list.
        return http.Response('[]', 200,
            headers: {'content-type': 'application/json'});
      }
      // Profile bootstrap and role reads: no rows.
      final wantsObject = (request.headers['accept'] ?? '')
          .contains('vnd.pgrst.object');
      if (wantsObject) return _noRow();
      return http.Response('[]', 200,
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
        autoRefreshToken: false,
      ),
    );
  });

  setUp(() async {
    returnSession = true;
    writeFails = false;
    signupCalls = 0;
    signupEmail = null;
    writes = [];
    PendingSignupDob.clear();
    await (await SharedPreferences.getInstance()).clear();
    await Supabase.instance.client.auth.signOut(scope: SignOutScope.local);
    PersonalDetailsGate.reset();
  });

  Future<void> guarded(Future<void> Function() body) {
    final done = Completer<void>();
    runZonedGuarded(() async {
      try {
        await body();
        if (!done.isCompleted) done.complete();
      } catch (e, s) {
        if (!done.isCompleted) done.completeError(e, s);
      }
    }, (error, stack) {
      // google_fonts cannot load Inter in tests; drop only those errors.
      if (error.toString().contains('google_fonts') ||
          error.toString().contains('allowRuntimeFetching')) {
        return;
      }
      if (!done.isCompleted) done.completeError(error, stack);
    });
    return done.future;
  }

  Future<void> pumpSignUp(
    WidgetTester t, {
    required List<String> signedUpEmails,
  }) async {
    await pdPump(
      t,
      SignUpScreen(
        role: 'client',
        accentColor: kPrimaryColor,
        heroImage: AppInfo.onBoard2,
        subtitle: (l) => l.authCreateAccount,
        roleLabel: (l) => 'x',
        onSignedUp: (_, email) async => signedUpEmails.add(email),
      ),
    );
  }

  Future<void> submit(
    WidgetTester t,
    AppLocalizations l10n, {
    required String email,
    String d = '07',
    String m = '05',
    String y = '1990',
  }) async {
    final f = find.byType(TextField);
    await t.enterText(f.at(0), 'QA');
    await t.enterText(f.at(1), 'Tester');
    await t.enterText(f.at(2), email);
    await t.enterText(f.at(3), 'abcdef1!');
    await t.enterText(f.at(4), 'abcdef1!');
    await t.enterText(f.at(5), d);
    await t.enterText(f.at(6), m);
    await t.enterText(f.at(7), y);
    await t.ensureVisible(find.byType(Checkbox));
    await t.tap(find.byType(Checkbox));
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

  testWidgets('session returned: DOB is written during sign-up, consent is not',
      (t) => guarded(() async {
    final signedUp = <String>[];
    await pumpSignUp(t, signedUpEmails: signedUp);
    await submit(t, en, email: 'qa-new@example.invalid');

    expect(signupCalls, 1);
    expect(signedUp, ['qa-new@example.invalid']);
    expect(writes, hasLength(1));
    expect(writes.single['date_of_birth'], '1990-05-07');
    expect(writes.single.containsKey('consent_version'), isFalse);
    expect(PendingSignupDob.hasPending, isFalse);
    expect(t.takeException(), isNull);
  }));

  testWidgets(
      'confirm email: no session, nothing written at sign-up, DOB held, '
      'then written on first sign-in with the same email in another case',
      (t) => guarded(() async {
    returnSession = false;
    final signedUp = <String>[];
    await pumpSignUp(t, signedUpEmails: signedUp);
    await submit(t, en, email: 'Qa-New@Example.invalid');

    expect(signupCalls, 1);
    expect(signedUp, hasLength(1), reason: 'sign-up still completes');
    expect(Supabase.instance.client.auth.currentSession, isNull);
    expect(writes, isEmpty);
    expect(PendingSignupDob.hasPending, isTrue);

    // Later: the user confirms the email and signs in (session appears).
    final user = {
      'id': qaSignedInUserId,
      'email': 'qa-new@example.invalid',
    };
    final session = {
      ...(jsonDecode(qaSessionJson()) as Map<String, dynamic>),
      'user': {
        ...(jsonDecode(qaSessionJson()) as Map)['user'] as Map,
        ...user,
      },
    };
    await Supabase.instance.client.auth
        .recoverSession(jsonEncode(session));
    await PersonalDetailsGate.refresh();

    expect(writes, hasLength(1));
    expect(writes.single['date_of_birth'], '1990-05-07');
    expect(PendingSignupDob.hasPending, isFalse);
    expect(PersonalDetailsGate.needsPrompt, isTrue,
        reason: 'consent still missing, so the first-sign-in step shows');
    expect(t.takeException(), isNull);
  }));

  testWidgets('DOB write fails during sign-up: sign-up completes, DOB kept',
      (t) => guarded(() async {
    writeFails = true;
    final signedUp = <String>[];
    await pumpSignUp(t, signedUpEmails: signedUp);
    await submit(t, en, email: 'qa-new@example.invalid');

    expect(signedUp, hasLength(1), reason: 'a failed DOB write never blocks');
    expect(writes, isEmpty);
    expect(PendingSignupDob.hasPending, isTrue);
    expect(t.takeException(), isNull);
  }));

  testWidgets('under 16 typed at sign-up: no sign-up request at all',
      (t) => guarded(() async {
    final signedUp = <String>[];
    await pumpSignUp(t, signedUpEmails: signedUp);
    await submit(t, en,
        email: 'qa-kid@example.invalid', d: '01', m: '01', y: '2020');
    expect(signupCalls, 0);
    expect(signedUp, isEmpty);
    expect(writes, isEmpty);
    expect(PendingSignupDob.hasPending, isFalse);
    expect(find.text(en.pdDobErrorUnder16), findsOneWidget);
  }));
}
