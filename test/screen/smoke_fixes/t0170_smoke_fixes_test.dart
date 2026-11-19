// T-0170 regression tests for the 2026-11-19 overflow smoke-pass findings.
import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:freelancer/core/notifications/notification_text.dart';
import 'package:freelancer/core/utils/attendance_mode.dart';
import 'package:freelancer/core/utils/chat_thread_context.dart';
import 'package:freelancer/data/models/chat_order_context.dart';
import 'package:freelancer/data/models/chat_thread_context.dart';
import 'package:freelancer/l10n/l10n_labels.dart';
import 'package:freelancer/screen/widgets/chat_order_context_banner.dart';
import 'package:freelancer/data/models/notification_model.dart';
import 'package:freelancer/l10n/app_localizations.dart';
import 'package:freelancer/router/app_router.dart';
import 'package:freelancer/screen/seller%20screen/buyer%20request/buyer_request_details.dart';
import 'package:freelancer/screen/widgets/invite_friends_screen.dart';
import 'package:freelancer/screen/widgets/job_location_map_preview.dart';
import 'package:freelancer/screen/widgets/shell_drawer_header.dart';
import 'package:freelancer/screen/widgets/shell_tab_header.dart';
import 'package:freelancer/services/attendance_service.dart';

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

AppNotification _notif(String body, {String type = 'message'}) =>
    AppNotification(
      id: 'n1',
      userId: 'u1',
      title: 'Sender',
      body: body,
      type: type,
      createdAt: DateTime(2026, 11, 19),
    );

void main() {
  setUpAll(() async {
    await initQaSupabase(tables: const {}, signedIn: true);
  });

  group('1. invite illustration', () {
    for (final size in const [Size(402, 874), Size(440, 956)]) {
      testWidgets('is a full circle, no clipped asset: ${size.width}pt',
          (tester) async {
        _size(tester, size);
        await tester.pumpWidget(_app(
            const Locale('en'), const InviteFriendsScreen(isSeller: true)));
        await tester.pump();

        final art = find.byKey(const Key('inviteIllustration'));
        expect(art, findsOneWidget);
        final rect = tester.getRect(art);
        expect(rect.size, const Size(120, 120));
        expect(rect.center.dx, closeTo(size.width / 2, 0.5));
        // The old clipped bitmap is gone.
        expect(
          find.byWidgetPredicate((w) =>
              w is Image &&
              w.image is AssetImage &&
              (w.image as AssetImage).assetName == 'images/refer.png'),
          findsNothing,
        );
        expect(
          find.byWidgetPredicate((w) =>
              w is DecoratedBox &&
              w.decoration is BoxDecoration &&
              (w.decoration as BoxDecoration).image != null),
          findsNothing,
        );
        expect(tester.takeException(), isNull);
      });
    }
  });

  group('2. Dutch strings', () {
    late AppLocalizations nl;
    late AppLocalizations en;
    setUpAll(() async {
      nl = await AppLocalizations.delegate.load(const Locale('nl'));
      en = await AppLocalizations.delegate.load(const Locale('en'));
    });

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

    test('attendance status is localized (no English in NL)', () {
      final j = job(AttendanceMode.qrOnce);
      expect(j.statusText(en), 'Not checked in yet');
      expect(j.statusText(nl), 'Nog niet ingecheckt');
      expect(job(AttendanceMode.qrOnce, today: true).statusText(nl),
          'Ingecheckt voor deze dienst');
      for (final mode in const [
        AttendanceMode.qrInOut,
        AttendanceMode.selfReport
      ]) {
        expect(job(mode, clockedIn: true).statusText(nl), 'Ingeklokt');
        expect(job(mode, today: true).statusText(nl), 'Uitgeklokt');
        expect(job(mode).statusText(nl), 'Niet ingeklokt');
      }
    });

    test('drawer review count uses ICU plural', () {
      expect(en.drawerRatingReviews('5.0', 1), '5.0 · 1 review');
      expect(en.drawerRatingReviews('4.5', 3), '4.5 · 3 reviews');
      expect(nl.drawerRatingReviews('5.0', 1), '5.0 · 1 beoordeling');
      expect(nl.drawerRatingReviews('4.5', 3), '4.5 · 3 beoordelingen');
    });

    testWidgets('drawer header renders localized plural', (tester) async {
      await tester.pumpWidget(_app(
        const Locale('nl'),
        const Scaffold(
          body: ShellDrawerHeader(
            persona: ShellPersona.seller,
            name: 'Test',
            rating: 5.0,
            reviewCount: 1,
          ),
        ),
      ));
      await tester.pump();
      expect(find.text('5.0 · 1 beoordeling'), findsOneWidget);
      expect(find.textContaining('reviews'), findsNothing);
    });

    test('Settings subtitle and onboarding text have no English ownership', () {
      expect(nl.platformRulesSubtitle,
          'Van aanmelden tot eigenaarschap in 9 stappen');
      expect(nl.platformRulesSubtitle.contains('ownership'), isFalse);
      expect(nl.appOnboardPage9Body.contains('ownership'), isFalse);
    });

    test('message notification body is localized, other bodies unchanged', () {
      final b = 'You have a new message about "Keukenspetter". "Hallo daar"';
      expect(localizedNotificationBody(nl, _notif(b)),
          'Je hebt een nieuw bericht over "Keukenspetter". "Hallo daar"');
      expect(
          localizedNotificationBody(
              nl, _notif('You have a new message about "Job X".')),
          'Je hebt een nieuw bericht over "Job X".');
      expect(localizedNotificationBody(nl, _notif('You have a new message.')),
          'Je hebt een nieuw bericht.');
      expect(
          localizedNotificationBody(nl,
              _notif('You have a new message about "A". "Sent an attachment"')),
          'Je hebt een nieuw bericht over "A". "Bijlage verstuurd"');
      // EN stays identical to the stored text.
      expect(localizedNotificationBody(en, _notif(b)), b);
      // Unknown body / other type: fall back to the stored text.
      expect(localizedNotificationBody(nl, _notif('Something else')),
          'Something else');
      expect(localizedNotificationBody(nl, _notif(b, type: 'order')), b);
      expect(localizedNotificationBody(nl, _notif(b, type: 'order')), b);
    });

    testWidgets('chat banner status follows locale, not load-time locale',
        (tester) async {
      const item = ChatThreadContextItem(
        kind: ChatThreadContextKind.order,
        id: 'o',
        title: 'Keukenspetter',
        statusLabel: 'Active', // stale English label cached at load time
        statusKey: 'active',
      );
      late BuildContext ctx;
      await tester.pumpWidget(_app(const Locale('nl'), Builder(builder: (c) {
        ctx = c;
        return const SizedBox();
      })));
      expect(
        localizedThreadStatusLabel(AppLocalizations.of(ctx), item,
            isClientViewer: false),
        'Actief',
      );
    });
  });

  group('3. job detail map keeps its height when already applied', () {
    final job = <String, dynamic>{
      'id': 'job-1',
      'title': 'transport logistiek',
      'description': 'het vervoeren van pallets',
      'status': 'open',
      'client_id': '00000000-0000-4000-8000-0000000000aa',
      'location': 'Rijnsburg, Nederland',
      'location_type': 'On-site',
      'latitude': 52.18,
      'longitude': 4.45,
      'my_offer': {'status': 'pending'},
      'created_at': '2026-11-01T10:00:00Z',
    };

    testWidgets('402x874 applied state: map >= 180pt, page scrolls',
        (tester) async {
      _size(tester, const Size(402, 874));
      await tester.pumpWidget(_app(
        const Locale('en'),
        BuyerRequestDetails(jobPostId: 'job-1', debugJobPost: job),
      ));
      await tester.pump(const Duration(milliseconds: 200));

      expect(find.byKey(const Key('applyBlockedMessage')), findsOneWidget);
      expect(find.text('Cannot apply'), findsOneWidget);

      // The real bottom bar (the elevated Material of bottomNavigationBar,
      // lift included) is just the button: the message is not in it.
      final barFinder = find.byWidgetPredicate((w) =>
          w is Material &&
          w.elevation == 12 &&
          w.shadowColor == Colors.black26);
      expect(barFinder, findsOneWidget);
      final bar = tester.getRect(barFinder);
      expect(bar.bottom, closeTo(874, 0.5));
      expect(
          find.descendant(
              of: barFinder,
              matching: find.byKey(const Key('applyBlockedMessage'))),
          findsNothing);
      // Applied bar = button (about 65) + 72 lift + 8 top; the old stacked
      // message made it 145+. Allow wrapping slack but stay well below.
      expect(bar.height, lessThan(170));

      // The page scrolls instead of squeezing the map.
      await tester.dragUntilVisible(
        find.byType(FlutterMap),
        find.byType(SingleChildScrollView),
        const Offset(0, -150),
      );
      await tester.pump();
      expect(tester.getSize(find.byType(FlutterMap)).height,
          greaterThanOrEqualTo(180));
      expect(tester.getSize(find.byType(JobLocationMapPreview)).height,
          greaterThanOrEqualTo(180));
    });
  });

  group('4. NL bottom tab: full bold label fits inside the pill', () {
    for (final width in const [375.0, 402.0]) {
      for (final scale in const [1.0, 1.5, 2.0]) {
        for (final tabs in const [4, 5]) {
          testWidgets('Overeenkomsten ${width.toInt()}pt x$scale, $tabs tabs',
              (tester) async {
            _size(tester, Size(width, 812));
            final nl = await AppLocalizations.delegate.load(const Locale('nl'));
            expect(nl.contracts, 'Overeenkomsten');
            final labels = tabs == 4
                ? [nl.home, 'Bericht', nl.findJobs, nl.contracts]
                : [nl.home, 'Bericht', 'Talent', 'Mijn jobs', nl.contracts];
            await tester.pumpWidget(_app(
              const Locale('nl'),
              Scaffold(
                body: const SizedBox.shrink(),
                bottomNavigationBar:
                    debugShellBottomNav(currentIndex: tabs - 1, labels: labels),
              ),
              scale: scale,
            ));
            await tester.pump(const Duration(milliseconds: 300));
            expect(tester.takeException(), isNull);

            final text = find.text('Overeenkomsten');
            expect(text, findsOneWidget);
            final label = tester.getRect(text);
            // The selected pill is the AnimatedContainer around the icon.
            final pill = tester.getRect(find
                .ancestor(
                    of: find.byIcon(Icons.circle),
                    matching: find.byType(AnimatedContainer))
                .first);
            expect(label.left, greaterThanOrEqualTo(pill.left - 0.5),
                reason: 'label sticks out of the pill on the left');
            expect(label.right, lessThanOrEqualTo(pill.right + 0.5),
                reason: 'label sticks out of the pill on the right');
            expect(pill.left, greaterThanOrEqualTo(0));
            expect(pill.right, lessThanOrEqualTo(width));
            expect(pill.width, lessThanOrEqualTo(width / tabs + 0.5));
          });
        }
      }
    }
  });

  group('5. review plural, budget text, chat banner', () {
    test('reviewCount is an ICU plural in EN/NL/BN', () async {
      final en = await AppLocalizations.delegate.load(const Locale('en'));
      final nl = await AppLocalizations.delegate.load(const Locale('nl'));
      expect(en.reviewCount(1), '1 review');
      expect(en.reviewCount(2), '2 reviews');
      expect(nl.reviewCount(1), '1 beoordeling');
      expect(nl.reviewCount(5), '5 beoordelingen');
    });

    test('budget text is localized (no English "per hour" in NL)', () async {
      final en = await AppLocalizations.delegate.load(const Locale('en'));
      final nl = await AppLocalizations.delegate.load(const Locale('nl'));
      expect(
          L10nLabels.budgetRange(en, 10, 15, 'per_hour'), endsWith('per hour'));
      expect(
          L10nLabels.budgetRange(nl, 10, 15, 'per_hour'), endsWith('per uur'));
      expect(L10nLabels.budgetRange(nl, 500, 500, 'fixed'),
          endsWith('(vast project)'));
      expect(
          L10nLabels.offerAmountLine(nl, 40, 'per_day'), endsWith('per dag'));
    });

    testWidgets('chat order banner derives status from key at build time',
        (tester) async {
      const ctx = ChatOrderContext(
        orderId: 'o',
        title: 'Keukenspetter',
        statusLabel: 'Active', // stale snapshot
        statusKey: 'active',
        isClientViewer: false,
      );
      await tester.pumpWidget(_app(
          const Locale('nl'),
          Scaffold(
              body: ChatOrderContextBanner(
                  orderContext: ctx, onViewContract: () {}))));
      await tester.pump();
      expect(find.textContaining('Actief'), findsOneWidget);
      expect(find.textContaining('Active'), findsNothing);
    });
  });
}
