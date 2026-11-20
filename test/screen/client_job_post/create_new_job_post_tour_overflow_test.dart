import 'dart:async';
import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:freelancer/l10n/app_localizations.dart';
import 'package:freelancer/screen/client screen/client job post/create_new_job_post.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../support/qa_supabase.dart';

/// T-0171 fix round 2: the REAL first-run guide tour on the create-job screens
/// (form and verification gate) must not overflow at NL, text scale 2.0, on
/// 330 and 375pt wide phones. The tour is NOT marked as seen. All requests stay
/// in-process, all data is fake.
///
/// Caveat: flutter test renders with the Ahem fallback font (about twice as
/// wide as the real font), so a pass here is conservative; a failure would
/// need a device check before it is called a bug.
typedef _Handler = FutureOr<http.Response> Function(http.Request request);

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

Map<String, dynamic>? _profileBody;
Object? _verificationRow;

/// Swallows google_fonts load errors (asset fonts are off in tests).
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

double _scale = 2.0;

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  final nl = lookupAppLocalizations(const Locale('nl'));

  setUpAll(() async {
    GoogleFonts.config.allowRuntimeFetching = false;
    SharedPreferences.setMockInitialValues({}); // tours NOT seen
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
    _verificationRow = null;
    _router.handlers = {
      'my_profile': (_) => _json(200, _profileBody),
      'employer_verifications': (_) => _json(
          200, _verificationRow == null ? <Object?>[] : [_verificationRow]),
      'categories': (_) => _json(200, [_category]),
    };
  });

  for (final width in [330.0, 375.0]) {
    for (final scenario in ['form', 'gate']) {
      guarded('real tour, $scenario, NL x2.0, ${width.toInt()}pt: no overflow',
          (t) async {
        final errors = <({String summary, String full})>[];
        final old = FlutterError.onError;
        FlutterError.onError = (d) {
          final s = d.exceptionAsString();
          if (s.contains('google_fonts') ||
              s.contains('allowRuntimeFetching')) {
            return;
          }
          errors.add((
            summary: s.split('\n').first,
            full: s.contains('overflowed') ? d.toString() : s,
          ));
        };

        _scale = const int.fromEnvironment('SCALE10', defaultValue: 20) / 10;
        _profileBody = _profile(
          status: 'verified',
          complete: scenario == 'form',
        );
        // Set the real view size (setSurfaceSize leaves MediaQuery at 800 wide,
        // which made the tour's action row 600dp wide: the QA harness overflow).
        t.view.devicePixelRatio = 1.0;
        t.view.physicalSize = Size(width, 667);
        addTearDown(t.view.reset);
        await t.pumpWidget(MaterialApp(
          locale: const Locale('nl'),
          supportedLocales: AppLocalizations.supportedLocales,
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          builder: (c, child) => MediaQuery(
            data: MediaQuery.of(c)
                .copyWith(textScaler: TextScaler.linear(_scale)),
            child: child!,
          ),
          home: const CreateNewJobPost(),
        ));
        // Let requests finish and the tour start (it is scheduled after the
        // gate check), then step through every tooltip.
        for (var i = 0; i < 40; i++) {
          await t.runAsync(
              () => Future<void>.delayed(const Duration(milliseconds: 10)));
          await t.pump(const Duration(milliseconds: 100));
        }
        final next = find.text(nl.guideNext);
        final done = find.text(nl.guideDone);
        final tourShowing = find.text(nl.guideSkip).evaluate().isNotEmpty ||
            next.evaluate().isNotEmpty ||
            done.evaluate().isNotEmpty;
        for (var step = 0; step < 12; step++) {
          if (next.evaluate().isNotEmpty) {
            await t.tap(next.first, warnIfMissed: false);
          } else if (done.evaluate().isNotEmpty) {
            await t.tap(done.first, warnIfMissed: false);
            break;
          } else {
            break;
          }
          for (var i = 0; i < 8; i++) {
            await t.runAsync(
                () => Future<void>.delayed(const Duration(milliseconds: 10)));
            await t.pump(const Duration(milliseconds: 100));
          }
        }
        // Tear the tour down so no timers outlive the test.
        await t.pumpWidget(const SizedBox());
        await t.pump(const Duration(seconds: 2));
        FlutterError.onError = old;
        if (scenario == 'form') {
          expect(tourShowing, isTrue, reason: 'the tour should be showing');
        }
        // Only overflows raised by the tour itself count (its widgets are
        // created in lib/core/guide or showcaseview). Page content overflowing
        // under the wide Ahem test font is a different, harness-only matter.
        final overflows =
            errors.where((e) => e.summary.contains('overflowed')).toList();
        final tour = overflows
            .where((e) {
              final text = e.full;
              return text.contains('core/guide') ||
                  text.contains('showcaseview');
            })
            .map((e) => e.summary)
            .toList();
        expect(tour, isEmpty,
            reason: 'tour overflow (${overflows.length} overflows in total)');
      });
    }
  }
}
