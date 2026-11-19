import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:freelancer/core/notification_navigation.dart';
import 'package:freelancer/core/notifications/notification_scope.dart';
import 'package:freelancer/data/models/notification_model.dart';
import 'package:freelancer/data/repositories/notification_repository.dart';
import 'package:freelancer/l10n/app_localizations.dart';
import 'package:freelancer/screen/widgets/notification_list_screen.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../support/qa_supabase.dart';

/// QA for T-0168 visual checklist, widget level only (no device rendering).
/// Screen is 375x800 logical px. Overflow shows up as a test exception.

class _Repo extends NotificationRepository {
  _Repo(this.items);
  final List<AppNotification> items;

  @override
  Future<List<AppNotification>> getNotifications(
          {int limit = 20, int offset = 0}) async =>
      offset == 0 ? List.of(items) : [];

  @override
  Future<int> getUnreadCount() async => items.where((n) => !n.read).length;

  @override
  RealtimeChannel subscribeToNotifications({
    void Function()? onChange,
    void Function(AppNotification notification)? onInsert,
  }) =>
      throw StateError('no realtime in tests');
}

class _Strings {
  const _Strings({
    required this.readAll,
    required this.deleteAll,
    required this.notifications,
    required this.swipeTitle,
    required this.swipeConfirm,
    required this.swipeBody,
    required this.bulkTitle,
    required this.bulkBody,
    required this.bulkConfirm,
    required this.cancel,
    required this.unreadTitle,
    required this.readTitle,
  });
  final String readAll;
  final String deleteAll;
  final String notifications;
  final String swipeTitle;
  final String swipeConfirm;
  final String swipeBody;
  final String bulkTitle;
  final String bulkBody;
  final String bulkConfirm;
  final String cancel;
  final String unreadTitle;
  final String readTitle;
}

// Strings copied from app_en.arb / app_nl.arb (T-0168 keys).
const _en = _Strings(
  readAll: 'Read All',
  deleteAll: 'Delete all',
  notifications: 'Notifications',
  swipeTitle: 'Delete this notification?',
  swipeConfirm: 'Delete',
  swipeBody: 'This cannot be undone.',
  bulkTitle: 'Delete all notifications?',
  bulkBody:
      'Are you sure you want to delete all notifications? This cannot be undone.',
  bulkConfirm: 'Delete all',
  cancel: 'Cancel',
  unreadTitle: 'New application received for your job posting',
  readTitle: 'Your contract was updated by the employer',
);

const _nl = _Strings(
  readAll: 'Alles gelezen',
  deleteAll: 'Alles verwijderen',
  notifications: 'Meldingen',
  swipeTitle: 'Deze melding verwijderen?',
  swipeConfirm: 'Verwijderen',
  swipeBody: 'Dit kan niet ongedaan worden gemaakt.',
  bulkTitle: 'Alle meldingen verwijderen?',
  bulkBody:
      'Weet je zeker dat je alle meldingen wilt verwijderen? Dit kan niet ongedaan worden gemaakt.',
  bulkConfirm: 'Alles verwijderen',
  cancel: 'Annuleren',
  unreadTitle: 'Nieuwe sollicitatie ontvangen voor je opdrachtaanbod',
  readTitle: 'Je overeenkomst is bijgewerkt door de opdrachtgever',
);

final _strings = {'en': _en, 'nl': _nl};

List<AppNotification> _seed(_Strings s) => [
      AppNotification(
        id: 'u',
        userId: qaSignedInUserId,
        title: s.unreadTitle,
        body: 'Body',
        read: false,
        createdAt: DateTime.now(),
      ),
      AppNotification(
        id: 'r',
        userId: qaSignedInUserId,
        title: s.readTitle,
        read: true,
        createdAt: DateTime.now(),
      ),
    ];

/// "Delete all" now lives in the app bar's overflow menu.
Future<void> openDeleteAll(WidgetTester tester, String label) async {
  await tester.tap(find.byIcon(Icons.more_vert));
  await tester.pumpAndSettle();
  await tester.tap(find.text(label).last);
  await tester.pumpAndSettle();
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUpAll(() async {
    await initQaSupabase(tables: const {}, signedIn: true);
  });

  Future<void> pump(
    WidgetTester tester,
    List<AppNotification> items, {
    required String lang,
    double textScale = 1.0,
  }) async {
    await tester.binding.setSurfaceSize(const Size(375, 800));
    addTearDown(() => tester.binding.setSurfaceSize(null));
    await tester.pumpWidget(
      RepositoryProvider<NotificationRepository>.value(
        value: _Repo(items),
        child: MaterialApp(
          locale: Locale(lang),
          supportedLocales: AppLocalizations.supportedLocales,
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          builder: (context, child) => MediaQuery(
            data: MediaQuery.of(context)
                .copyWith(textScaler: TextScaler.linear(textScale)),
            child: child!,
          ),
          home: const NotificationScope(
            child: NotificationListScreen(role: NotificationUserRole.client),
          ),
        ),
      ),
    );
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 100));
  }

  Rect rectOf(WidgetTester tester, Finder f) => tester.getRect(f);

  void expectOnScreen(String what, Rect r) {
    expect(r.left, greaterThanOrEqualTo(0), reason: '$what left edge');
    expect(r.top, greaterThanOrEqualTo(0), reason: '$what top edge');
    expect(r.right, lessThanOrEqualTo(375), reason: '$what right edge');
    expect(r.bottom, lessThanOrEqualTo(800), reason: '$what bottom edge');
  }

  for (final lang in ['en', 'nl']) {
    for (final scale in [1.0, 1.5, 2.0]) {
      testWidgets('list $lang x$scale: app bar menu fits and keeps the title',
          (tester) async {
        final s = _strings[lang]!;
        await pump(tester, _seed(s), lang: lang, textScale: scale);

        expect(tester.takeException(), isNull);
        final menuIcon = find.descendant(
            of: find.byType(AppBar), matching: find.byIcon(Icons.more_vert));
        final title = find.text(s.notifications);
        expect(menuIcon, findsOneWidget);
        // Old layout (Read all text + delete icon side by side) was replaced
        // by one overflow menu; Read all must no longer sit in the bar.
        expect(find.text(s.readAll), findsNothing);
        expect(find.byIcon(Icons.delete_outline), findsNothing);

        final rMenu = rectOf(tester, menuIcon);
        final rTitle = rectOf(tester, title);
        // ignore: avoid_print
        print('[$lang x$scale] title=$rTitle menu=$rMenu');
        expect(rTitle.overlaps(rMenu), isFalse,
            reason: 'title overlaps menu button');
        expect(rTitle.width, greaterThan(30),
            reason: 'title is squeezed by the app bar actions');
        expectOnScreen('menu button', rMenu);

        // Both actions are reachable from the menu, Delete all in red.
        await tester.tap(menuIcon);
        await tester.pumpAndSettle();
        expect(find.text(s.readAll), findsOneWidget);
        expect(find.text(s.deleteAll), findsOneWidget);
        expect(tester.widget<Text>(find.text(s.deleteAll)).style?.color,
            Colors.red);
        expectOnScreen('read all item', rectOf(tester, find.text(s.readAll)));
        expectOnScreen(
            'delete all item', rectOf(tester, find.text(s.deleteAll)));
        expect(tester.takeException(), isNull);
      });
    }
  }

  for (final lang in ['en', 'nl']) {
    // Read-only list: no "Read all" text, so the delete-all icon is reachable.
    // With unread items at NL x2.0 the icon is pushed off-screen (see the
    // app-bar test above), so the bulk dialog cannot be opened there.
    testWidgets('$lang x2.0: Delete all dialog fits the screen',
        (tester) async {
      final s = _strings[lang]!;
      await pump(tester, [_seed(s)[1]], lang: lang, textScale: 2.0);

      await openDeleteAll(tester, s.deleteAll);
      expect(find.text(s.bulkTitle), findsOneWidget);
      final dialog = rectOf(tester, find.byType(AlertDialog));
      final body = rectOf(tester, find.text(s.bulkBody));
      final confirm =
          rectOf(tester, find.widgetWithText(TextButton, s.bulkConfirm));
      final cancel = rectOf(tester, find.widgetWithText(TextButton, s.cancel));
      // ignore: avoid_print
      print('[$lang x2.0 bulk] dialog=$dialog body=$body '
          'confirm=$confirm cancel=$cancel');
      expectOnScreen('bulk dialog', dialog);
      expectOnScreen('bulk body', body);
      expectOnScreen('bulk confirm', confirm);
      expectOnScreen('bulk cancel', cancel);
      expect(body.bottom, lessThanOrEqualTo(confirm.top + 0.5));
      expect(tester.takeException(), isNull);
    });

    testWidgets('$lang x2.0: swipe confirm dialog fits the screen',
        (tester) async {
      final s = _strings[lang]!;
      await pump(tester, _seed(s), lang: lang, textScale: 2.0);

      // Swipe confirm dialog.
      await tester.drag(find.text(_seed(s)[0].title), const Offset(-500, 0));
      await tester.pumpAndSettle();
      expect(find.text(s.swipeTitle), findsOneWidget);
      final sDialog = rectOf(tester, find.byType(AlertDialog));
      final sBody = rectOf(tester, find.text(s.swipeBody));
      final sConfirm =
          rectOf(tester, find.widgetWithText(TextButton, s.swipeConfirm));
      // ignore: avoid_print
      print('[$lang x2.0 swipe] dialog=$sDialog body=$sBody confirm=$sConfirm');
      expectOnScreen('swipe dialog', sDialog);
      expectOnScreen('swipe body', sBody);
      expectOnScreen('swipe confirm', sConfirm);
      expect(tester.takeException(), isNull);
    });
  }

  for (final lang in ['en', 'nl']) {
    for (final scale in [1.0, 2.0]) {
      testWidgets(
          '$lang x$scale: swipe reveals red background with white icon and label',
          (tester) async {
        final handle = tester.ensureSemantics();
        final s = _strings[lang]!;
        await pump(tester, _seed(s), lang: lang, textScale: scale);

        final gesture = await tester
            .startGesture(tester.getCenter(find.text(s.unreadTitle)));
        // Two move steps: a single 120 px move did not start the drag in tests.
        await gesture.moveBy(const Offset(-40, 0));
        await tester.pump();
        await gesture.moveBy(const Offset(-80, 0));
        await tester.pump();

        final bg = find
            .byWidgetPredicate((w) => w is Container && w.color == Colors.red);
        expect(bg, findsOneWidget);
        final icon = find.descendant(
            of: bg, matching: find.byIcon(Icons.delete_outline));
        expect(icon, findsOneWidget);
        expect(tester.widget<Icon>(icon).color, Colors.white);
        expect(
          find.descendant(
            of: bg,
            matching: find.byWidgetPredicate(
                (w) => w is Semantics && w.properties.label == s.swipeConfirm),
          ),
          findsOneWidget,
        );
        // ignore: avoid_print
        print('[$lang x$scale swipe-bg] bg=${rectOf(tester, bg)} '
            'icon=${rectOf(tester, icon)}');
        expect(tester.takeException(), isNull);

        // Release short of the threshold: snaps back, no dialog.
        await gesture.up();
        await tester.pumpAndSettle();
        expect(find.text(s.swipeTitle), findsNothing);
        expect(find.text(s.unreadTitle), findsOneWidget);
        handle.dispose();
      });
    }
  }
}
