import 'dart:async';
import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:freelancer/core/widgets/loading_widget.dart';
import 'package:freelancer/l10n/app_localizations.dart';
import 'package:freelancer/router/route_names.dart';
import 'package:freelancer/screen/widgets/button_global.dart';
import 'package:freelancer/screen/client screen/client job post/create_new_job_post.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../support/qa_supabase.dart';

/// T-0171 edge cases (QA), widget level: CreateNewJobPost's verification gate
/// for each status, loading and error states, re-check after returning from
/// the verify screen, and the submit refusal message.
///
/// Own HTTP router (one instance, handlers swapped per test) so the job_posts
/// insert can return a real 403 + SQLSTATE 42501 body. All requests stay
/// in-process. All data is fake.
typedef _Handler = FutureOr<http.Response> Function(http.Request request);

const _stubBackLabel = 'QA back from verify';
const _stubOpenLabel = 'QA open post';
const _rlsMessage =
    'new row violates row-level security policy for table "job_posts"';

class _Session extends LocalStorage {
  const _Session();
  @override
  Future<void> initialize() async {}
  @override
  Future<bool> hasAccessToken() async => true;
  @override
  Future<String?> accessToken() async => qaSessionJson();
  @override
  Future<void> removePersistedSession() async {}
  @override
  Future<void> persistSession(String persistSessionString) async {}
}

class _Router extends http.BaseClient {
  Map<String, _Handler> handlers = {};
  final requests = <http.Request>[];

  @override
  Future<http.StreamedResponse> send(http.BaseRequest request) async {
    final bytes = await request.finalize().toBytes();
    final req = http.Request(request.method, request.url)
      ..headers.addAll(request.headers)
      ..bodyBytes = bytes;
    requests.add(req);
    final name =
        request.url.pathSegments.isEmpty ? '' : request.url.pathSegments.last;
    final handler = handlers[name];
    final res = handler == null ? _json(200, <Object?>[]) : await handler(req);
    return http.StreamedResponse(
      Stream.value(res.bodyBytes),
      res.statusCode,
      headers: res.headers,
      request: request,
    );
  }

  int count(String method, String table) => requests
      .where((r) => r.method == method && r.url.pathSegments.last == table)
      .length;
}

http.Response _json(int status, Object? body) => http.Response(
      jsonEncode(body),
      status,
      headers: {'content-type': 'application/json'},
    );

Map<String, dynamic> _profile({String? status, bool complete = true}) => {
      'id': qaSignedInUserId,
      'role': 'client',
      'name': 'Sam Tester',
      'email': 'qa-user@example.invalid',
      'country': 'NL',
      'phone': complete ? '+31600000000' : '',
      'city': complete ? 'Leiden' : '',
      'bio': complete ? 'QA bio' : '',
      'profile_image_url':
          complete ? 'https://qa-test.invalid/avatar.png' : null,
      'verification_status': status,
    };

final _category = {
  'id': '00000000-0000-4000-8000-0000000000c1',
  'name': 'Warehouse',
  'name_i18n': null,
  'description': null,
  'description_i18n': null,
  'is_custom': false,
  'icon': 'box',
};

final _router = _Router();

// Per-test state, read by the handlers installed in setUp.
Map<String, dynamic>? _profileBody;
Completer<http.Response>? _profileGate;
int _profileHttpStatus = 200;
Object? _verificationRow;
_Handler _jobInsert = (_) => _json(201, {'id': 'job-1'});

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  final en = lookupAppLocalizations(const Locale('en'));
  final nl = lookupAppLocalizations(const Locale('nl'));

  setUpAll(() async {
    GoogleFonts.config.allowRuntimeFetching = false;
    // Mark the first-run guide tours as already seen (GuideService key:
    // guide_seen_<uid>_<role>_<screenId>_v<version>; version is 1 for both
    // create-job screens). Otherwise the tour overlay sits on top of the form.
    SharedPreferences.setMockInitialValues({
      for (final screen in ['create_job', 'create_job_gate'])
        'guide_seen_${qaSignedInUserId}_client_${screen}_v1': true,
    });
    await Supabase.initialize(
      url: 'https://qa-test.invalid',
      anonKey: 'qa-test-anon-key',
      httpClient: _router,
      debug: false,
      authOptions: const FlutterAuthClientOptions(
        localStorage: _Session(),
        detectSessionInUri: false,
        autoRefreshToken: false,
      ),
    );
  });

  setUp(() {
    _router.requests.clear();
    _profileBody = _profile(status: 'verified');
    _profileGate = null;
    _profileHttpStatus = 200;
    _verificationRow = null;
    _jobInsert = (_) => _json(201, {'id': 'job-1'});
    _router.handlers = {
      'my_profile': (_) {
        if (_profileHttpStatus != 200) {
          return _json(_profileHttpStatus, {'message': 'boom from profile'});
        }
        if (_profileGate != null) return _profileGate!.future;
        return _json(200, _profileBody);
      },
      'employer_verifications': (_) => _json(
          200, _verificationRow == null ? <Object?>[] : [_verificationRow]),
      'categories': (_) => _json(200, [_category]),
      'job_posts': (r) =>
          r.method == 'POST' ? _jobInsert(r) : _json(200, <Object?>[]),
    };
  });

  // ---------------------------------------------------------------- gate
  group('gate per status', () {
    final cases = <String?, bool>{
      'verified': false, // form shows, no verification gate
      'pending': true,
      'rejected': true,
      'unverified': true,
      'VERIFIED': true,
      'approved': true,
      '': true,
      null: true,
    };
    for (final entry in cases.entries) {
      final label = entry.key == null ? 'null' : "'${entry.key}'";
      guarded('status $label', (t) async {
        _profileBody = _profile(status: entry.key);
        await _pumpScreen(t);
        await _settle(t);
        if (entry.value) {
          expect(
              find.byKey(const Key('employerVerifyGateTitle')), findsOneWidget);
          expect(find.text(en.jobTitle), findsNothing);
        } else {
          expect(
              find.byKey(const Key('employerVerifyGateTitle')), findsNothing);
          expect(find.text(en.jobTitle), findsOneWidget);
        }
      });
    }

    guarded('pending shows the under-review title and status button',
        (t) async {
      _profileBody = _profile(status: 'pending');
      await _pumpScreen(t);
      await _settle(t);
      expect(find.text(en.employerVerifyPendingTitle), findsOneWidget);
      expect(find.text(en.employerVerifyViewStatusButton), findsOneWidget);
    });

    guarded('rejected shows resubmit copy', (t) async {
      _profileBody = _profile(status: 'rejected');
      await _pumpScreen(t);
      await _settle(t);
      expect(find.text(en.employerVerifyRejectedBody), findsOneWidget);
    });

    guarded('NL pending copy on the live screen', (t) async {
      _profileBody = _profile(status: 'pending');
      await _pumpScreen(t, locale: const Locale('nl'));
      await _settle(t);
      expect(find.text(nl.employerVerifyPendingTitle), findsOneWidget);
    });

    guarded(
        'verified but profile incomplete: profile gate, not the verification '
        'gate', (t) async {
      _profileBody = _profile(status: 'verified', complete: false);
      await _pumpScreen(t);
      await _settle(t);
      expect(find.byKey(const Key('employerVerifyGateTitle')), findsNothing);
      expect(find.text(en.jobTitle), findsNothing);
    });

    guarded('loading: spinner until profile resolves, never the form',
        (t) async {
      _profileGate = Completer<http.Response>();
      await _pumpScreen(t);
      await _settle(t, rounds: 3);
      expect(find.byType(LoadingWidget), findsOneWidget);
      expect(find.text(en.jobTitle), findsNothing);
      expect(find.byKey(const Key('employerVerifyGateTitle')), findsNothing);

      _profileGate!.complete(_json(200, _profile(status: 'verified')));
      await _settle(t);
      expect(find.byType(LoadingWidget), findsNothing);
      expect(find.text(en.jobTitle), findsOneWidget);
    });

    guarded('error loading the profile shows a retry state, not "required"',
        (t) async {
      _profileHttpStatus = 500;
      await _pumpScreen(t);
      await _settle(t);
      // Fail closed (no form) but do not claim verification is missing.
      expect(find.byKey(const Key('employerVerifyCheckFailedTitle')),
          findsOneWidget);
      expect(find.text(en.employerVerifyRequiredTitle), findsNothing);
      expect(find.text(en.jobTitle), findsNothing);

      // Retry once the server answers: a verified employer gets the form.
      _profileHttpStatus = 200;
      _profileBody = _profile(status: 'verified');
      await t.tap(find.text(en.retry));
      await _settle(t);
      expect(find.byKey(const Key('employerVerifyCheckFailedTitle')),
          findsNothing);
      expect(find.text(en.jobTitle), findsOneWidget);
    });
  });

  group('ever approved (T-0171 owner decision)', () {
    guarded('approved once, now pending (docs edited): form opens', (t) async {
      _profileBody = _profile(status: 'pending');
      _verificationRow = {
        'user_id': qaSignedInUserId,
        'status': 'pending',
        'first_verified_at': '2026-11-01T10:00:00Z',
      };
      await _pumpScreen(t);
      await _settle(t);
      expect(find.byKey(const Key('employerVerifyGateTitle')), findsNothing);
      expect(find.text(en.jobTitle), findsOneWidget);
    });

    guarded('never approved and pending: under review', (t) async {
      _profileBody = _profile(status: 'pending');
      _verificationRow = {
        'user_id': qaSignedInUserId,
        'status': 'pending',
        'first_verified_at': null,
      };
      await _pumpScreen(t);
      await _settle(t);
      expect(find.text(en.employerVerifyPendingTitle), findsOneWidget);
      expect(find.text(en.jobTitle), findsNothing);
    });
  });

  // ----------------------------------------------------- re-check on return
  group('re-check after returning from verification', () {
    guarded('approved while away: the form opens without a restart', (t) async {
      _profileBody = _profile(status: 'pending');
      await _pumpScreen(t);
      await _settle(t);
      expect(find.text(en.employerVerifyPendingTitle), findsOneWidget);
      final loadsBefore = _router.count('GET', 'my_profile');

      await t.tap(find.text(en.employerVerifyViewStatusButton));
      await _settle(t);
      expect(find.text(_stubBackLabel), findsOneWidget);

      _profileBody = _profile(status: 'verified');
      await t.tap(find.text(_stubBackLabel));
      await _settle(t);

      expect(_router.count('GET', 'my_profile'), greaterThan(loadsBefore));
      expect(find.byKey(const Key('employerVerifyGateTitle')), findsNothing);
      expect(find.text(en.jobTitle), findsOneWidget);
    });

    guarded('back without approval keeps the gate', (t) async {
      _profileBody = _profile(status: 'pending');
      await _pumpScreen(t);
      await _settle(t);
      await t.tap(find.text(en.employerVerifyViewStatusButton));
      await _settle(t);
      await t.tap(find.text(_stubBackLabel));
      await _settle(t);
      expect(find.text(en.employerVerifyPendingTitle), findsOneWidget);
      expect(find.text(en.jobTitle), findsNothing);
    });
  });

  // ------------------------------------------------------------- submit
  group('submit', () {
    guarded('control: a verified employer posts and sees the success text',
        (t) async {
      _profileBody = _profile(status: 'verified');
      await _pumpScreen(t);
      await _settle(t);
      await _fillWizardAndPost(t);
      expect(_router.count('POST', 'job_posts'), 1);
      expect(find.text(en.employerVerifyRequiredPostError), findsNothing);
      expect(find.text(en.jobPostedSuccess), findsOneWidget);
    });

    guarded('server refusal (RLS, 42501) shows the friendly verify message',
        (t) async {
      _profileBody = _profile(status: 'verified');
      _jobInsert = (_) => _json(403, {
            'code': '42501',
            'details': null,
            'hint': null,
            'message': _rlsMessage,
          });
      await _pumpScreen(t);
      await _settle(t);
      await _fillWizardAndPost(t);

      expect(_router.count('POST', 'job_posts'), 1,
          reason: 'the app did try to insert');
      expect(find.text(en.employerVerifyRequiredPostError), findsOneWidget);
      expect(find.textContaining('PostgrestException'), findsNothing);
      expect(find.textContaining('row-level'), findsNothing);
      expect(find.text(en.jobPostedSuccess), findsNothing);
      // The wizard stays on screen so nothing typed is lost.
      expect(find.text(en.postJob), findsWidgets);
    });

    guarded('server refusal message is localised (NL)', (t) async {
      _profileBody = _profile(status: 'verified');
      _jobInsert = (_) => _json(403, {
            'code': '42501',
            'details': null,
            'hint': null,
            'message': _rlsMessage,
          });
      await _pumpScreen(t, locale: const Locale('nl'));
      await _settle(t);
      await _fillWizardAndPost(t, locale: const Locale('nl'));
      expect(find.text(nl.employerVerifyRequiredPostError), findsOneWidget);
    });

    guarded('other server error is shown as-is, not as a verify message',
        (t) async {
      _profileBody = _profile(status: 'verified');
      _jobInsert = (_) => _json(500, {
            'code': 'XX000',
            'details': null,
            'hint': null,
            'message': 'boom from job_posts',
          });
      await _pumpScreen(t);
      await _settle(t);
      await _fillWizardAndPost(t);
      expect(find.text(en.employerVerifyRequiredPostError), findsNothing);
      expect(find.textContaining('boom from job_posts'), findsOneWidget);
    });
  });
}

// ---------------------------------------------------------------- helpers

/// Runs a widget test body in a zone that drops google_fonts load errors only
/// (no font assets in tests). Same approach as sign_up_auth_error_test.dart.
/// Keeps google_fonts load errors (no font assets in tests) out of the test.
void guarded(
  String description,
  Future<void> Function(WidgetTester t) body,
) {
  testWidgets(description, (t) {
    final done = Completer<void>();
    runZonedGuarded(() async {
      try {
        await body(t);
        if (!done.isCompleted) done.complete();
      } catch (e, s) {
        if (!done.isCompleted) done.completeError(e, s);
      }
    }, (error, stack) {
      final msg = error.toString();
      if (msg.contains('google_fonts') ||
          msg.contains('allowRuntimeFetching')) {
        return;
      }
      if (!done.isCompleted) done.completeError(error, stack);
    });
    return done.future;
  });
}

Future<void> _pumpScreen(
  WidgetTester t, {
  Locale locale = const Locale('en'),
}) async {
  await t.binding.setSurfaceSize(const Size(390, 844));
  addTearDown(() => t.binding.setSurfaceSize(null));
  // Home stub -> push the job form, so a successful post can pop back to a
  // real page (popping the only route would drop the success snackbar).
  final goRouter = GoRouter(routes: [
    GoRoute(
      path: '/',
      builder: (context, __) => Scaffold(
        body: Center(
          child: TextButton(
            onPressed: () => context.push('/post'),
            child: const Text(_stubOpenLabel),
          ),
        ),
      ),
    ),
    GoRoute(
      path: '/post',
      builder: (_, __) => const CreateNewJobPost(),
    ),
    GoRoute(
      path: AppRoutes.clientProfileVerify,
      builder: (context, __) => Scaffold(
        body: Center(
          child: TextButton(
            onPressed: () => context.pop(),
            child: const Text(_stubBackLabel),
          ),
        ),
      ),
    ),
  ]);
  await t.pumpWidget(MaterialApp.router(
    locale: locale,
    supportedLocales: AppLocalizations.supportedLocales,
    localizationsDelegates: AppLocalizations.localizationsDelegates,
    routerConfig: goRouter,
  ));
  await t.pump();
  await t.tap(find.text(_stubOpenLabel));
  await t.pump();
  await _settle(t);
}

/// Lets the in-process HTTP calls complete, then pumps frames. The first-run
/// guide tour on this screen would otherwise sit on top of the form and
/// swallow taps, so its Skip button is pressed whenever it is shown.
Future<void> _settle(WidgetTester t, {int rounds = 20}) async {
  for (var i = 0; i < rounds; i++) {
    await t
        .runAsync(() => Future<void>.delayed(const Duration(milliseconds: 10)));
    await t.pump(const Duration(milliseconds: 50));
  }
  for (final l10n in [
    lookupAppLocalizations(const Locale('en')),
    lookupAppLocalizations(const Locale('nl')),
  ]) {
    final skip = find.text(l10n.guideSkip);
    if (skip.evaluate().isNotEmpty) {
      await t.tap(skip.first, warnIfMissed: false);
      for (var i = 0; i < 5; i++) {
        await t.runAsync(
            () => Future<void>.delayed(const Duration(milliseconds: 10)));
        await t.pump(const Duration(milliseconds: 50));
      }
    }
  }
}

/// Fills the four wizard steps (Remote, so no QR pin is needed) and taps Post.
Future<void> _fillWizardAndPost(
  WidgetTester t, {
  Locale locale = const Locale('en'),
}) async {
  final l10n = lookupAppLocalizations(locale);
  Future<void> next() async {
    await t.ensureVisible(find.text(l10n.continueLabel));
    await t.tap(find.text(l10n.continueLabel));
    await _settle(t, rounds: 3);
  }

  await t.enterText(
      find.widgetWithText(TextFormField, l10n.jobTitle), 'QA warehouse shift');
  await _settle(t, rounds: 3);
  await t.tap(find.text(_category['name'] as String).first);
  await _settle(t, rounds: 3);
  await next(); // basics -> details

  await t.enterText(find.widgetWithText(TextFormField, l10n.describeJobLabel),
      'QA description');
  await _settle(t, rounds: 3);
  await next(); // details -> location

  await t.tap(find.text(l10n.locationRemote).first);
  await _settle(t, rounds: 3);
  await t.enterText(
      find.widgetWithText(TextFormField, 'Location'), 'QA remote');
  await _settle(t, rounds: 3);
  await next(); // location -> budget

  // The app bar title has the same text, so target the bottom button widget.
  final postButton = find.descendant(
    of: find.byType(ButtonGlobalWithoutIcon),
    matching: find.text(l10n.postJob),
  );
  await t.ensureVisible(postButton);
  await t.tap(postButton);
  await _settle(t, rounds: 60);
}
