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

/// T-0168: swipe-to-delete and "Delete all" on the Notifications screen.
class _FakeRepo extends NotificationRepository {
  _FakeRepo(this.items);
  List<AppNotification> items;
  final deletedIds = <String>[];
  int deleteAllCalls = 0;
  int unreadCountCalls = 0;
  bool failDelete = false;

  @override
  Future<List<AppNotification>> getNotifications(
          {int limit = 20, int offset = 0}) async =>
      offset == 0 ? List.of(items) : [];

  @override
  Future<int> getUnreadCount() async {
    unreadCountCalls++;
    return items.where((n) => !n.read).length;
  }

  @override
  RealtimeChannel subscribeToNotifications({
    void Function()? onChange,
    void Function(AppNotification notification)? onInsert,
  }) =>
      throw StateError('no realtime in tests');

  @override
  Future<void> deleteNotification(String id) async {
    if (failDelete) throw Exception('boom');
    deletedIds.add(id);
    items = items.where((n) => n.id != id).toList();
  }

  @override
  Future<int> deleteAllNotifications() async {
    deleteAllCalls++;
    final n = items.length;
    items = [];
    return n;
  }
}

AppNotification _n(String id, String title) => AppNotification(
      id: id,
      userId: qaSignedInUserId,
      title: title,
      createdAt: DateTime.now(),
    );

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

  Future<_FakeRepo> pump(
    WidgetTester tester,
    List<AppNotification> items, {
    Locale locale = const Locale('en'),
    double textScale = 1.0,
  }) async {
    final repo = _FakeRepo(items);
    await tester.binding.setSurfaceSize(const Size(375, 800));
    addTearDown(() => tester.binding.setSurfaceSize(null));
    await tester.pumpWidget(
      RepositoryProvider<NotificationRepository>.value(
        value: repo,
        child: MaterialApp(
          locale: locale,
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
    return repo;
  }

  testWidgets('swipe + confirm removes the row and refreshes the badge',
      (tester) async {
    final repo = await pump(tester, [_n('a', 'First'), _n('b', 'Second')]);
    expect(find.text('First'), findsOneWidget);
    final before = repo.unreadCountCalls;

    await tester.drag(find.text('First'), const Offset(-500, 0));
    await tester.pumpAndSettle();
    expect(find.text('Delete this notification?'), findsOneWidget);
    await tester.tap(find.widgetWithText(TextButton, 'Delete'));
    await tester.pumpAndSettle();

    expect(repo.deletedIds, ['a']);
    expect(find.text('First'), findsNothing);
    expect(find.text('Second'), findsOneWidget);
    expect(repo.unreadCountCalls, greaterThan(before));
  });

  testWidgets('swipe + cancel keeps the row and deletes nothing',
      (tester) async {
    final repo = await pump(tester, [_n('a', 'First')]);

    await tester.drag(find.text('First'), const Offset(-500, 0));
    await tester.pumpAndSettle();
    await tester.tap(find.widgetWithText(TextButton, 'Cancel'));
    await tester.pumpAndSettle();

    expect(repo.deletedIds, isEmpty);
    expect(find.text('First'), findsOneWidget);
  });

  testWidgets('failed delete keeps the row', (tester) async {
    final repo = await pump(tester, [_n('a', 'First')]);
    repo.failDelete = true;

    await tester.drag(find.text('First'), const Offset(-500, 0));
    await tester.pumpAndSettle();
    await tester.tap(find.widgetWithText(TextButton, 'Delete'));
    await tester.pumpAndSettle();

    expect(find.text('First'), findsOneWidget);
  });

  testWidgets('Delete all asks for confirmation, then empties the list',
      (tester) async {
    final repo = await pump(tester, [_n('a', 'First'), _n('b', 'Second')]);
    final before = repo.unreadCountCalls;

    await openDeleteAll(tester, 'Delete all');
    expect(find.text('Delete all notifications?'), findsOneWidget);

    // Cancel first: nothing happens.
    await tester.tap(find.text('Cancel'));
    await tester.pumpAndSettle();
    expect(repo.deleteAllCalls, 0);
    expect(find.text('First'), findsOneWidget);

    await openDeleteAll(tester, 'Delete all');
    await tester.tap(find.widgetWithText(TextButton, 'Delete all'));
    await tester.pumpAndSettle();

    expect(repo.deleteAllCalls, 1);
    expect(find.text('First'), findsNothing);
    expect(find.text('Second'), findsNothing);
    expect(repo.unreadCountCalls, greaterThan(before));
    // Empty list: the action is hidden.
    expect(find.byIcon(Icons.more_vert), findsNothing);
  });

  testWidgets('Delete all is hidden when the list is empty', (tester) async {
    await pump(tester, []);
    expect(find.byIcon(Icons.more_vert), findsNothing);
  });

  testWidgets('NL at XL text: dialog and app bar do not overflow',
      (tester) async {
    await pump(tester, [_n('a', 'Eerste')],
        locale: const Locale('nl'), textScale: 1.6);
    expect(find.byIcon(Icons.more_vert), findsOneWidget);

    await openDeleteAll(tester, 'Alles verwijderen');
    expect(
      find.text(
          'Weet je zeker dat je alle meldingen wilt verwijderen? Dit kan niet ongedaan worden gemaakt.'),
      findsOneWidget,
    );
    expect(tester.takeException(), isNull);
  });
}
