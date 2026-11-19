// T-0170 QA edge tests (2026-11-19). Fake data only; no network (qa_supabase).
// Covers: notification_text odd inputs, drawer plural 0/1/2/many in EN/NL/BN,
// attendance statusText for every status, job detail bottom bar in
// not-applied / applied / closed states, and widget-level visual checks.
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:freelancer/core/notifications/notification_text.dart';
import 'package:freelancer/core/utils/attendance_mode.dart';
import 'package:freelancer/data/models/notification_model.dart';
import 'package:freelancer/l10n/app_localizations.dart';
import 'package:freelancer/router/app_router.dart';
import 'package:freelancer/screen/attendance/attendance_actions_card.dart';
import 'package:freelancer/screen/seller%20screen/buyer%20request/buyer_request_details.dart';
import 'package:freelancer/screen/widgets/invite_friends_screen.dart';
import 'package:freelancer/screen/widgets/job_client_info_card.dart';
import 'package:freelancer/screen/widgets/shell_drawer_header.dart';
import 'package:freelancer/screen/widgets/shell_tab_header.dart';
import 'package:freelancer/services/attendance_service.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../support/qa_supabase.dart';

Widget _app(Locale locale, Widget home, {double scale = 1.0}) => MaterialApp(
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      locale: locale,
      builder: (context, child) => MediaQuery(
        data: MediaQuery.of(context)
            .copyWith(textScaler: TextScaler.linear(scale)),
        child: child!,
      ),
      home: home,
    );

void _size(WidgetTester tester, Size size) {
  tester.view.physicalSize = size;
  tester.view.devicePixelRatio = 1.0;
  addTearDown(tester.view.reset);
}

AppNotification _n(String? body, {String type = 'message'}) => AppNotification(
      id: 'n1',
      userId: 'u1',
      title: 'Sender',
      body: body,
      type: type,
      createdAt: DateTime(2026, 11, 19),
    );

Map<String, dynamic> _job({
  String? status = 'open',
  String? clientId = '00000000-0000-4000-8000-0000000000aa',
  Map<String, dynamic>? myOffer,
}) =>
    {
      'id': 'job-1',
      'title': 'transport logistiek',
      'description': 'het vervoeren van pallets',
      'status': status,
      'client_id': clientId,
      'location': 'Rijnsburg, Nederland',
      'location_type': 'On-site',
      'latitude': 52.18,
      'longitude': 4.45,
      'my_offer': myOffer,
      'created_at': '2026-11-01T10:00:00Z',
    };

Future<void> _pumpJob(WidgetTester tester, Map<String, dynamic> job,
    {Locale locale = const Locale('en'),
    double scale = 1.0,
    Size size = const Size(402, 874)}) async {
  _size(tester, size);
  await tester.pumpWidget(_app(
    locale,
    BuyerRequestDetails(jobPostId: 'job-1', debugJobPost: job),
    scale: scale,
  ));
  await tester.pump(const Duration(milliseconds: 200));
}

/// Runs [body] and returns every FlutterError it reports, with the
/// error-causing widget text (takeException() drops that detail).
Future<List<String>> _captureErrors(Future<void> Function() body) async {
  final out = <String>[];
  final prev = FlutterError.onError;
  FlutterError.onError = (details) {
    final info = details.informationCollector?.call() ?? const [];
    out.add('${details.exceptionAsString()} | '
        '${info.map((d) => d.toString()).join(' / ')}');
  };
  try {
    await body();
  } finally {
    FlutterError.onError = prev;
  }
  return out;
}

/// The bottom bar Material (elevation 12 in BuyerRequestDetails).
Finder _bottomBar() =>
    find.byWidgetPredicate((w) => w is Material && w.elevation == 12);

void main() {
  late AppLocalizations en;
  late AppLocalizations nl;
  late AppLocalizations bn;

  setUpAll(() async {
    await initQaSupabase(tables: const {}, signedIn: true);
    en = await AppLocalizations.delegate.load(const Locale('en'));
    nl = await AppLocalizations.delegate.load(const Locale('nl'));
    bn = await AppLocalizations.delegate.load(const Locale('bn'));
  });

  group('A. notification body edge inputs', () {
    test('null body stays null (no crash)', () {
      expect(localizedNotificationBody(nl, _n(null)), isNull);
    });

    test('empty and whitespace-only bodies are returned unchanged', () {
      expect(localizedNotificationBody(nl, _n('')), '');
      expect(localizedNotificationBody(nl, _n('   ')), '   ');
    });

    test('different type with a trigger template is not translated', () {
      const b = 'You have a new message about "Job".';
      expect(localizedNotificationBody(nl, _n(b, type: 'order')), b);
      expect(localizedNotificationBody(nl, _n(b, type: '')), b);
      // Type match is case-sensitive: "Message" is not the trigger type.
      expect(localizedNotificationBody(nl, _n(b, type: 'Message')), b);
    });

    test('partial templates fall back to the stored English text', () {
      for (final b in const [
        'You have a new message about "Job X"', // no closing period
        'You have a new message about "".', // empty context
        'You have a new message about', // bare prefix
        'You have a new message. ', // trailing space, not trigger output
        'you have a new message.', // wrong case
      ]) {
        expect(localizedNotificationBody(nl, _n(b)), b, reason: b);
      }
    });

    test('title with inner quotes is kept intact', () {
      expect(
        localizedNotificationBody(
            nl, _n('You have a new message about "Say "hi" now".')),
        'Je hebt een nieuw bericht over "Say "hi" now".',
      );
    });

    test('title ending in a quote is kept intact', () {
      expect(
        localizedNotificationBody(
            nl, _n('You have a new message about "Big "deal"".')),
        'Je hebt een nieuw bericht over "Big "deal"".',
      );
    });

    test('title with a quote-period sequence and a preview', () {
      expect(
        localizedNotificationBody(
            nl, _n('You have a new message about "Foo". Bar".')),
        'Je hebt een nieuw bericht over "Foo". Bar".',
      );
      expect(
        localizedNotificationBody(
            nl, _n('You have a new message about "Job". "say "hi""')),
        'Je hebt een nieuw bericht over "Job". "say "hi""',
      );
    });

    test('preview that is an empty quoted string drops the preview', () {
      expect(
        localizedNotificationBody(
            nl, _n('You have a new message about "Job". ""')),
        'Je hebt een nieuw bericht over "Job".',
      );
    });

    test('title with emoji is kept intact', () {
      const title = '🍕 Pizza 🔥 (Ç/é) — 日本';
      expect(
        localizedNotificationBody(
            nl, _n('You have a new message about "$title". "👍 ok"')),
        'Je hebt een nieuw bericht over "$title". "👍 ok"',
      );
    });

    test('very long title (2000 chars) re-renders without truncation', () {
      final title = List.filled(200, 'Lange titel').join(' '); // ~2400 chars
      expect(title.length, greaterThan(2000));
      final out = localizedNotificationBody(
          nl, _n('You have a new message about "$title". "kort"'));
      expect(out, 'Je hebt een nieuw bericht over "$title". "kort"');
    });

    test('braces and dollar signs in a title are literal', () {
      expect(
        localizedNotificationBody(
            nl, _n('You have a new message about "{count} \$5 {x}".')),
        'Je hebt een nieuw bericht over "{count} \$5 {x}".',
      );
    });

    test('order-number context from the trigger is kept', () {
      expect(
        localizedNotificationBody(
            nl, _n('You have a new message about "Order #AB12CD34".')),
        'Je hebt een nieuw bericht over "Order #AB12CD34".',
      );
    });

    test('preview-only bodies: attachment translated, other text unchanged',
        () {
      expect(localizedNotificationBody(nl, _n('Sent an attachment')),
          'Bijlage verstuurd');
      expect(localizedNotificationBody(nl, _n('Hallo daar')), 'Hallo daar');
    });

    test('English locale returns the stored body for trigger templates', () {
      const b = 'You have a new message about "Job". "Hi"';
      expect(localizedNotificationBody(en, _n(b)), b);
    });
  });

  group('B. drawer review plural 0 / 1 / 2 / many', () {
    test('EN', () {
      expect(en.drawerRatingReviews('5.0', 0), '5.0 · 0 reviews');
      expect(en.drawerRatingReviews('5.0', 1), '5.0 · 1 review');
      expect(en.drawerRatingReviews('5.0', 2), '5.0 · 2 reviews');
      expect(en.drawerRatingReviews('5.0', 21), '5.0 · 21 reviews');
    });

    test('NL', () {
      expect(nl.drawerRatingReviews('5.0', 0), '5.0 · 0 beoordelingen');
      expect(nl.drawerRatingReviews('5.0', 1), '5.0 · 1 beoordeling');
      expect(nl.drawerRatingReviews('5.0', 2), '5.0 · 2 beoordelingen');
      expect(nl.drawerRatingReviews('5.0', 21), '5.0 · 21 beoordelingen');
    });

    test('BN has only "1" and "other" forms, no English leak', () {
      final one = bn.drawerRatingReviews('5.0', 1);
      final two = bn.drawerRatingReviews('5.0', 2);
      final many = bn.drawerRatingReviews('5.0', 21);
      expect(one, '5.0 · ১টি রিভিউ');
      expect(two, '5.0 · 2টি রিভিউ');
      expect(many, '5.0 · 21টি রিভিউ');
      // Known issue (latent): Bengali CLDR maps 0 to "one", so count 0 would
      // read "1 review". The drawer hides 0 reviews, so no user impact today.
      // Not asserted here; see the QA report. Skipped test below records it.

      for (final s in [one, two, many]) {
        expect(s.contains('review'), isFalse, reason: s);
      }
    });

    test('KNOWN ISSUE (latent): BN count 0 should use the other form',
        () {
      expect(bn.drawerRatingReviews('5.0', 0), '5.0 · 0টি রিভিউ');
    }, skip: 'Bengali CLDR maps 0 to "one": renders "১টি রিভিউ". '
        'Drawer hides 0 reviews, so no user impact yet. See T-0170-qa.md.');

    for (final c in const [
      (Locale('en'), 1, 'review'),
      (Locale('nl'), 2, 'beoordelingen'),
    ]) {
      testWidgets('drawer header shows plural for ${c.$1.languageCode} x${c.$2}',
          (tester) async {
        await tester.pumpWidget(_app(
          c.$1,
          Scaffold(
            body: ShellDrawerHeader(
              persona: ShellPersona.client,
              name: 'Test',
              rating: 4.5,
              reviewCount: c.$2,
            ),
          ),
        ));
        await tester.pump();
        expect(tester.takeException(), isNull);
        expect(find.textContaining(c.$3), findsOneWidget);
      });
    }

    testWidgets('drawer hides the rating line when there are 0 reviews',
        (tester) async {
      await tester.pumpWidget(_app(
        const Locale('nl'),
        const Scaffold(
          body: ShellDrawerHeader(
            persona: ShellPersona.seller,
            name: 'Test',
            rating: 5.0,
            reviewCount: 0,
          ),
        ),
      ));
      await tester.pump();
      expect(find.textContaining('·'), findsNothing);
      expect(find.textContaining('beoordeling'), findsNothing);
    });
  });

  group('C. attendance statusText for every status', () {
    OnsiteAttendanceJob job(String mode,
            {bool clockedIn = false, bool today = false}) =>
        OnsiteAttendanceJob(
          orderId: 'o',
          jobPostId: 'j',
          title: 't',
          clientName: 'c',
          orderStatus: 'active',
          attendanceMode: mode,
          isClockedIn: clockedIn,
          checkedInToday: today,
        );

    test('disabled mode shows "off" for every flag combination', () {
      for (final clockedIn in [false, true]) {
        for (final today in [false, true]) {
          final j = job(AttendanceMode.disabled,
              clockedIn: clockedIn, today: today);
          expect(j.statusText(en), 'Attendance off');
          expect(j.statusText(nl), 'Aanwezigheid uit');
          expect(j.statusText(bn), bn.attendanceModeDisabled);
        }
      }
    });

    test('qr_once: checked-in-today drives the label; isClockedIn is ignored',
        () {
      for (final clockedIn in [false, true]) {
        expect(
            job(AttendanceMode.qrOnce, clockedIn: clockedIn).statusText(en),
            'Not checked in yet');
        expect(
            job(AttendanceMode.qrOnce, clockedIn: clockedIn, today: true)
                .statusText(en),
            'Checked in this shift');
        expect(
            job(AttendanceMode.qrOnce, clockedIn: clockedIn).statusText(nl),
            'Nog niet ingecheckt');
        expect(
            job(AttendanceMode.qrOnce, clockedIn: clockedIn, today: true)
                .statusText(nl),
            'Ingecheckt voor deze dienst');
        expect(
            job(AttendanceMode.qrOnce, clockedIn: clockedIn, today: true)
                .statusText(bn),
            bn.attendanceStatusCheckedInShift);
        expect(
            job(AttendanceMode.qrOnce, clockedIn: clockedIn).statusText(bn),
            bn.attendanceStatusNotCheckedIn);
      }
    });

    test('qr_in_out and self_report: all four in/today combinations', () {
      for (final mode in const [
        AttendanceMode.qrInOut,
        AttendanceMode.selfReport
      ]) {
        // clocked in (today or not) -> Clocked in
        expect(job(mode, clockedIn: true, today: true).statusText(en),
            'Clocked in');
        expect(job(mode, clockedIn: true).statusText(en), 'Clocked in');
        // out but punched in today -> Clocked out
        expect(job(mode, today: true).statusText(en), 'Clocked out');
        // never punched today -> Not clocked in
        expect(job(mode).statusText(en), 'Not clocked in');

        expect(job(mode, clockedIn: true).statusText(nl), 'Ingeklokt');
        expect(job(mode, today: true).statusText(nl), 'Uitgeklokt');
        expect(job(mode).statusText(nl), 'Niet ingeklokt');

        expect(job(mode, clockedIn: true).statusText(bn),
            bn.attendanceStatusClockedIn);
        expect(job(mode, today: true).statusText(bn),
            bn.attendanceStatusClockedOut);
        expect(job(mode).statusText(bn), bn.attendanceStatusNotClockedIn);
      }
    });

    test('every non-disabled status differs between EN and NL/BN', () {
      final samples = [
        job(AttendanceMode.qrOnce),
        job(AttendanceMode.qrOnce, today: true),
        job(AttendanceMode.qrInOut, clockedIn: true),
        job(AttendanceMode.qrInOut, today: true),
        job(AttendanceMode.selfReport),
      ];
      for (final s in samples) {
        final e = s.statusText(en);
        expect(e.isNotEmpty, isTrue);
        expect(s.statusText(nl), isNot(e));
        expect(s.statusText(bn), isNot(e));
      }
    });

    test('service-normalized modes map as expected (raw values are normalized)',
        () {
      expect(AttendanceMode.normalize('QR_ONCE'), AttendanceMode.qrOnce);
      expect(AttendanceMode.normalize(' self_report '),
          AttendanceMode.selfReport);
      expect(AttendanceMode.normalize('bogus'), AttendanceMode.qrInOut);
      expect(AttendanceMode.normalize(null), AttendanceMode.qrInOut);
    });
  });

  group('D. job detail bottom bar by state', () {
    const applyEn = 'Submit application';
    const blockedEn = 'Cannot apply';

    testWidgets('not applied, open: submit button, no reason message',
        (tester) async {
      await _pumpJob(tester, _job());
      expect(find.text(applyEn), findsOneWidget);
      expect(find.text(blockedEn), findsNothing);
      expect(find.byKey(const Key('applyBlockedMessage')), findsNothing);
      expect(find.descendant(of: _bottomBar(), matching: find.text(applyEn)),
          findsOneWidget);
      expect(tester.takeException(), isNull);
    });

    for (final s in const ['pending', 'accepted']) {
      testWidgets('applied ($s): bar shows "Cannot apply", message is in body',
          (tester) async {
        await _pumpJob(tester, _job(myOffer: {'status': s}));
        expect(find.text(blockedEn), findsOneWidget);
        expect(find.text(applyEn), findsNothing);
        expect(find.byKey(const Key('applyBlockedMessage')), findsOneWidget);
        expect(
            find.descendant(
                of: _bottomBar(), matching: find.text(blockedEn)),
            findsOneWidget);
        expect(
            find.descendant(
                of: _bottomBar(),
                matching:
                    find.byKey(const Key('applyBlockedMessage'))),
            findsNothing);
        expect(tester.takeException(), isNull);
      });
    }

    testWidgets('applied with rejected offer: still submittable (behaviour check)',
        (tester) async {
      await _pumpJob(tester, _job(myOffer: {'status': 'rejected'}));
      expect(find.text(applyEn), findsOneWidget);
      expect(find.byKey(const Key('applyBlockedMessage')), findsNothing);
    });

    for (final status in const ['closed', 'CLOSED']) {
      testWidgets('closed ($status): bar blocked, closed reason in body',
          (tester) async {
        await _pumpJob(tester, _job(status: status));
        expect(find.text(blockedEn), findsOneWidget);
        expect(find.text(en.jobClosedNoApplications), findsOneWidget);
        expect(find.byKey(const Key('applyBlockedMessage')), findsOneWidget);
        expect(
            find.descendant(
                of: _bottomBar(), matching: find.text(blockedEn)),
            findsOneWidget);
        expect(tester.takeException(), isNull);
      });
    }

    testWidgets('null status is treated as open (submit button)',
        (tester) async {
      await _pumpJob(tester, _job(status: null));
      expect(find.text(applyEn), findsOneWidget);
      expect(find.text(en.jobClosedNoApplications), findsNothing);
    });

    testWidgets('closed and already applied: closed reason wins',
        (tester) async {
      await _pumpJob(tester,
          _job(status: 'closed', myOffer: {'status': 'pending'}));
      expect(find.text(en.jobClosedNoApplications), findsOneWidget);
      expect(find.text(en.alreadySubmittedApplication), findsNothing);
    });

    testWidgets('own job: blocked with own-job reason', (tester) async {
      await _pumpJob(tester, _job(clientId: qaSignedInUserId));
      expect(find.text(blockedEn), findsOneWidget);
      expect(find.text(en.cannotApplyToOwnJob), findsOneWidget);
    });

    testWidgets('NL closed: NL button and NL reason, no English',
        (tester) async {
      await _pumpJob(tester, _job(status: 'closed'),
          locale: const Locale('nl'));
      expect(find.text(nl.cannotSubmitApplication), findsOneWidget);
      expect(find.text(nl.jobClosedNoApplications), findsOneWidget);
      expect(find.text(blockedEn), findsNothing);
    });

    testWidgets('tapping a blocked button shows the reason in a snackbar',
        (tester) async {
      await _pumpJob(tester, _job(status: 'closed'));
      await tester.tap(find.text(blockedEn));
      await tester.pump(const Duration(milliseconds: 300));
      expect(find.byType(SnackBar), findsOneWidget);
      expect(
          find.descendant(
              of: find.byType(SnackBar),
              matching: find.text(en.jobClosedNoApplications)),
          findsOneWidget);
    });

    for (final state in const [
      ('not applied', <String, dynamic>{}),
      ('applied', <String, dynamic>{'myOffer': {'status': 'pending'}}),
    ]) {
      testWidgets('bar is a single button, sits at screen bottom: ${state.$1}',
          (tester) async {
        await _pumpJob(
          tester,
          _job(
            myOffer: state.$2['myOffer'] as Map<String, dynamic>?,
          ),
        );
        expect(_bottomBar(), findsOneWidget);
        final bar = tester.getRect(_bottomBar());
        final btn = tester.getRect(find.descendant(
            of: _bottomBar(), matching: find.byType(TextButton)));
        // Measured, not asserted against a guessed limit. The bar includes
        // the 72pt floating-nav lift from BuyerRequestDetails.
        debugPrint('T-0170 QA measure 402x874 ${state.$1}: '
            'bar=${bar.height.toStringAsFixed(1)} '
            'button=${btn.height.toStringAsFixed(1)} '
            'bottom=${bar.bottom.toStringAsFixed(1)}');
        expect(bar.height, lessThan(874 / 2));
        expect(bar.bottom, closeTo(874, 1));
        expect(tester.takeException(), isNull);
      });
    }
  });

  group('E. visual checklist (widget level, device rows unverified)', () {
    for (final size in const [Size(402, 874), Size(375, 812)]) {
      for (final scale in const [1.0, 1.5, 2.0]) {
        for (final seller in const [true, false]) {
          testWidgets(
              'invite ${seller ? 'seller' : 'client'} ${size.width.toInt()}pt x$scale',
              (tester) async {
            _size(tester, size);
            await tester.pumpWidget(_app(
              const Locale('nl'),
              InviteFriendsScreen(isSeller: seller),
              scale: scale,
            ));
            await tester.pump();
            expect(tester.takeException(), isNull);
            final art = find.byKey(const Key('inviteIllustration'));
            expect(art, findsOneWidget);
            final rect = tester.getRect(art);
            expect(rect.size, const Size(120, 120));
            expect(rect.center.dx, closeTo(size.width / 2, 0.5));
          });
        }
      }
    }

    for (final persona in ShellPersona.values) {
      for (final scale in const [1.0, 1.5, 2.0]) {
        testWidgets(
            'drawer header ${persona.name} NL long name x$scale',
            (tester) async {
          _size(tester, const Size(402, 874));
          await tester.pumpWidget(_app(
            const Locale('nl'),
            Scaffold(
              body: ShellDrawerHeader(
                persona: persona,
                name: 'Maximiliaan-Alexander van der Berg-Scholten-Jansen',
                rating: 4.8,
                reviewCount: 12,
                balanceLabel: '€ 1.234,56',
              ),
            ),
            scale: scale,
          ));
          await tester.pump();
          expect(tester.takeException(), isNull);
          expect(find.textContaining('beoordelingen'), findsOneWidget);
        });
      }
    }

    for (final scale in const [1.0, 1.5, 2.0]) {
      for (final state in const [
        ('qr_once not in', AttendanceMode.qrOnce, false, false),
        ('qr_once in', AttendanceMode.qrOnce, false, true),
        ('qr_in_out clocked in', AttendanceMode.qrInOut, true, true),
        ('self_report clocked out', AttendanceMode.selfReport, false, true),
      ]) {
        testWidgets('attendance card NL 402pt x$scale: ${state.$1}',
            (tester) async {
          _size(tester, const Size(402, 874));
          final job = OnsiteAttendanceJob(
            orderId: 'o',
            jobPostId: 'j',
            title: 'Transport logistiek voor de zomerdienst',
            clientName: 'Client',
            orderStatus: 'active',
            attendanceMode: state.$2,
            isClockedIn: state.$3,
            checkedInToday: state.$4,
          );
          await tester.pumpWidget(_app(
            const Locale('nl'),
            Scaffold(
              body: SingleChildScrollView(
                padding: const EdgeInsets.all(16),
                child: AttendanceActionsCard(
                  orderId: 'o',
                  jobPostId: 'j',
                  attendanceMode: state.$2,
                  isClockedIn: state.$3,
                  checkedInToday: state.$4,
                  statusLabel: job.statusText(nl),
                  compact: true,
                ),
              ),
            ),
            scale: scale,
          ));
          await tester.pump(const Duration(milliseconds: 100));
          expect(tester.takeException(), isNull);
          expect(find.text(job.statusText(nl)), findsOneWidget);
        });
      }
    }

    // Reproduces a PRE-EXISTING overflow (not from T-0170): the location Row
    // in BuyerRequestDetails._buildLocationSection (no Expanded, badge text)
    // overflows at 1.5x (3px) and 2.0x (108px), EN, 402pt. Expected to FAIL
    // until fixed. The guide state does not change it (checked both states).
    // Guide seen key: guide_seen_<uid>_seller_seller_job_details_v1.
    for (final guideSeen in const [true, false]) {
      for (final scale in const [1.0, 1.5, 2.0]) {
        for (final applied in const [false, true]) {
          testWidgets(
              'job detail 402pt x$scale ${applied ? 'applied' : 'not applied'} '
              'guide ${guideSeen ? 'seen' : 'first visit'}', (tester) async {
            SharedPreferences.setMockInitialValues(guideSeen
                ? {'guide_seen_${qaSignedInUserId}_seller_seller_job_details_v1': true}
                : <String, Object>{});
            final errors = await _captureErrors(() => _pumpJob(
                  tester,
                  _job(myOffer: applied ? {'status': 'pending'} : null),
                  scale: scale,
                ));
            expect(errors, isEmpty, reason: errors.join('\n'));
            expect(_bottomBar(), findsOneWidget);
            expect(tester.getRect(_bottomBar()).bottom, closeTo(874, 1));
          });
        }
      }
    }

    for (final locale in const ['client', 'seller']) {
      for (final width in const [375.0, 402.0]) {
        for (final scale in const [1.0, 1.5, 2.0]) {
          testWidgets(
              'NL bottom tabs $locale ${width.toInt()}pt x$scale: labels fit',
              (tester) async {
            _size(tester, Size(width, 812));
            final labels = locale == 'client'
                ? [nl.home, nl.message, nl.talent, nl.myJobs, nl.contracts]
                : [nl.home, nl.message, nl.findJobs, nl.contracts];
            await tester.pumpWidget(_app(
              const Locale('nl'),
              Scaffold(
                body: const SizedBox.shrink(),
                bottomNavigationBar: debugShellBottomNav(
                  currentIndex: 0,
                  labels: labels,
                ),
              ),
              scale: scale,
            ));
            await tester.pump();
            expect(tester.takeException(), isNull);

            final rects = <Rect>[];
            for (final label in labels) {
              final f = find.text(label);
              expect(f, findsOneWidget, reason: label);
              final r = tester.getRect(f);
              expect(r.left, greaterThanOrEqualTo(0), reason: label);
              expect(r.right, lessThanOrEqualTo(width), reason: label);
              rects.add(r);
            }
            rects.sort((a, b) => a.left.compareTo(b.left));
            for (var i = 1; i < rects.length; i++) {
              expect(rects[i - 1].right, lessThanOrEqualTo(rects[i].left + 1),
                  reason: 'labels overlap at index $i');
            }
          });
        }
      }
    }
  });

  group('F. owner decision: NL tab label "Overeenkomsten" (measured)', () {
    // Owner decision (task notes 2026-11-19): keep "Overeenkomsten". The
    // label is in a FittedBox, so it always fits the slot by shrinking. The
    // numbers below show how much it shrinks; they are not a device check.
    for (final width in const [375.0, 402.0]) {
      for (final scale in const [1.0, 1.5, 2.0]) {
        testWidgets(
            'client 5 tabs "Overeenkomsten" ${width.toInt()}pt x$scale',
            (tester) async {
          _size(tester, Size(width, 812));
          final labels = [nl.home, nl.message, nl.talent, nl.myJobs, 'Overeenkomsten'];
          await tester.pumpWidget(_app(
            const Locale('nl'),
            Scaffold(
              body: const SizedBox.shrink(),
              bottomNavigationBar:
                  debugShellBottomNav(currentIndex: 4, labels: labels),
            ),
            scale: scale,
          ));
          await tester.pump();
          expect(tester.takeException(), isNull);
          final f = find.text('Overeenkomsten');
          expect(f, findsOneWidget);
          final natural = tester.getSize(f).width;
          final rendered = tester.getRect(f).width;
          final slot = width / labels.length;
          debugPrint('T-0170 QA measure tab Overeenkomsten client '
              '${width.toInt()}pt x$scale: natural=${natural.toStringAsFixed(1)} '
              'rendered=${rendered.toStringAsFixed(1)} '
              'slot=${slot.toStringAsFixed(1)} '
              'scale=${(rendered / natural).toStringAsFixed(2)}');
          expect(rendered, lessThanOrEqualTo(slot + 1));
        });
      }
    }
  });

  group('G. job client card review plural (owner-requested, not done yet)', () {
    // Task notes 2026-11-19: add ICU plural to the job detail client card.
    // Today en "{count} reviews" and nl "{count} beoordelingen" give "1 reviews".
    // These FAIL until that change lands.
    for (final c in const [
      (Locale('en'), '1 review'),
      (Locale('nl'), '1 beoordeling'),
    ]) {
      testWidgets('job client card reads "${c.$2}" for one review (${c.$1.languageCode})',
          (tester) async {
        _size(tester, const Size(402, 874));
        await tester.pumpWidget(_app(
          c.$1,
          Scaffold(
            body: SingleChildScrollView(
              child: JobClientInfoCard(
                clientProfile: const {'name': 'Client'},
                clientId: 'client-1',
                rating: 4.0,
                reviewCount: 1,
                jobPostsCount: 2,
                memberSince: '2025',
              ),
            ),
          ),
        ));
        await tester.pump();
        expect(tester.takeException(), isNull);
        final plural = find.byWidgetPredicate((w) =>
            w is Text &&
            RegExp(r'(^|\s)1 (reviews|beoordelingen)(\s|$)')
                .hasMatch(w.data ?? ''));
        expect(plural, findsNothing,
            reason: 'found plural form for a single review');
        expect(
            find.byWidgetPredicate((w) =>
                w is Text && (w.data ?? '').contains(c.$2)),
            findsOneWidget);
      });
    }
  });
}
