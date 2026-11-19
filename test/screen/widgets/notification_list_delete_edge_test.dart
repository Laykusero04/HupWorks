import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/semantics.dart';
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

/// QA for T-0168: edge cases for delete on the Notifications screen.
/// The fake repo behaves like a server: it holds the rows, paginates by
/// offset, and lets a test hold any call open with a Completer.

class _ServerRepo extends NotificationRepository {
  _ServerRepo(List<AppNotification> seed) : rows = List.of(seed);

  /// Server truth.
  final List<AppNotification> rows;
  final deletedIds = <String>[];
  final pageOffsets = <int>[];
  int refreshCalls = 0;
  int deleteAllCalls = 0;

  /// true = RLS filters the delete: 0 rows removed, no error returned.
  bool deleteIsNoop = false;
  bool failDelete = false;
  bool failDeleteAll = false;

  /// Next call of each kind waits on its completer before returning.
  Completer<void>? deleteGate;
  Completer<void>? refreshGate;
  Completer<void>? pageGate;

  @override
  Future<List<AppNotification>> getNotifications(
      {int limit = 20, int offset = 0}) async {
    // Snapshot at call time: the response can arrive after a later write.
    final snapshot = rows.skip(offset).take(limit).toList();
    if (offset == 0) {
      refreshCalls++;
      final gate = refreshGate;
      refreshGate = null;
      if (gate != null) await gate.future;
    } else {
      pageOffsets.add(offset);
      final gate = pageGate;
      pageGate = null;
      if (gate != null) await gate.future;
    }
    return snapshot;
  }

  @override
  Future<int> getUnreadCount() async => rows.where((n) => !n.read).length;

  @override
  RealtimeChannel subscribeToNotifications({
    void Function()? onChange,
    void Function(AppNotification notification)? onInsert,
  }) =>
      throw StateError('no realtime in tests');

  @override
  Future<void> deleteNotification(String id) async {
    if (failDelete) throw Exception('boom');
    final gate = deleteGate;
    deleteGate = null;
    if (gate != null) await gate.future;
    deletedIds.add(id);
    // The real service throws when the delete removed 0 rows.
    if (deleteIsNoop) throw Exception('Notification was not deleted');
    rows.removeWhere((n) => n.id == id);
  }

  @override
  Future<int> deleteAllNotifications() async {
    deleteAllCalls++;
    if (failDeleteAll) throw Exception('network down');
    final n = deleteIsNoop ? 0 : rows.length;
    if (!deleteIsNoop) rows.clear();
    return n;
  }
}

AppNotification _n(String id, String title, {bool read = false}) =>
    AppNotification(
      id: id,
      userId: qaSignedInUserId,
      title: title,
      read: read,
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

  Future<_ServerRepo> pump(
    WidgetTester tester,
    List<AppNotification> seed, {
    Locale locale = const Locale('en'),
    double textScale = 1.0,
  }) async {
    final repo = _ServerRepo(seed);
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

  Future<void> swipeLeft(WidgetTester tester, String title) async {
    await tester.drag(find.text(title), const Offset(-500, 0));
    await tester.pumpAndSettle();
  }

  Future<void> tapDialogButton(WidgetTester tester, String label) async {
    await tester.tap(find.widgetWithText(TextButton, label));
    await tester.pumpAndSettle();
  }

  /// Pull the list down far enough to fire RefreshIndicator.
  Future<void> pullToRefresh(WidgetTester tester) async {
    await tester.drag(find.byType(ListView).first, const Offset(0, 300));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 300));
  }

  final titlePattern = RegExp(r'^N\d\d$');

  /// Scroll from top to bottom and collect every visible "Nxx" title.
  Future<Set<String>> collectAllTitles(WidgetTester tester) async {
    final seen = <String>{};
    final titles = find.byWidgetPredicate(
        (w) => w is Text && titlePattern.hasMatch(w.data ?? ''));
    for (var i = 0; i < 40; i++) {
      for (final element in titles.evaluate()) {
        seen.add((element.widget as Text).data!);
      }
      await tester.drag(find.byType(ListView).first, const Offset(0, -300));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));
    }
    for (final element in titles.evaluate()) {
      seen.add((element.widget as Text).data!);
    }
    return seen;
  }

  testWidgets(
      'deleting the last item shows the empty state and hides Delete all',
      (tester) async {
    final repo = await pump(tester, [_n('a', 'First', read: true)]);

    await swipeLeft(tester, 'First');
    await tapDialogButton(tester, 'Delete');

    expect(repo.deletedIds, ['a']);
    expect(repo.rows, isEmpty);
    expect(find.text('First'), findsNothing);
    expect(find.text('No notifications'), findsOneWidget);
    expect(find.byIcon(Icons.more_vert), findsNothing);
    expect(find.text('Read All'), findsNothing);
    expect(tester.takeException(), isNull);
  });

  testWidgets('Delete all fails: every row and the Delete all button stay',
      (tester) async {
    final repo = await pump(tester, [_n('a', 'First'), _n('b', 'Second')]);
    repo.failDeleteAll = true;

    await openDeleteAll(tester, 'Delete all');
    await tapDialogButton(tester, 'Delete all');

    expect(repo.deleteAllCalls, 1);
    expect(repo.rows, hasLength(2));
    expect(find.text('First'), findsOneWidget);
    expect(find.text('Second'), findsOneWidget);
    expect(find.byIcon(Icons.more_vert), findsOneWidget);
    expect(find.byType(SnackBar), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets(
      'delete that removes 0 rows (RLS blocks): row snaps back with an error, no success message',
      (tester) async {
    final repo = await pump(tester, [_n('a', 'First'), _n('b', 'Second')]);
    repo.deleteIsNoop = true;

    await swipeLeft(tester, 'First');
    await tapDialogButton(tester, 'Delete');

    expect(find.text('First'), findsOneWidget);
    expect(find.text('Notification deleted'), findsNothing);
    expect(find.byType(SnackBar), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('Delete all that removes 0 rows from a non-empty list fails',
      (tester) async {
    final repo = await pump(tester, [_n('a', 'First'), _n('b', 'Second')]);
    repo.deleteIsNoop = true;

    await openDeleteAll(tester, 'Delete all');
    await tapDialogButton(tester, 'Delete all');

    expect(find.text('First'), findsOneWidget);
    expect(find.text('All notifications deleted'), findsNothing);
    expect(find.byType(SnackBar), findsOneWidget);
  });

  testWidgets('screen-reader Delete action and long press delete a row',
      (tester) async {
    final handle = tester.ensureSemantics();
    final repo = await pump(tester, [_n('a', 'First'), _n('b', 'Second')]);

    final node = tester.getSemantics(find.widgetWithText(ListTile, 'First'));
    expect(node.getSemanticsData().customSemanticsActionIds, isNotEmpty);
    final id = node.getSemanticsData().customSemanticsActionIds!.first;
    final action = CustomSemanticsAction.getAction(id)!;
    expect(action.label, 'Delete');
    tester.semantics.performAction(
        find.semantics.byLabel(RegExp('First')), SemanticsAction.customAction,
        args: id);
    await tester.pumpAndSettle();
    expect(find.text('Delete this notification?'), findsOneWidget);
    await tapDialogButton(tester, 'Delete');
    expect(repo.deletedIds, ['a']);
    expect(find.text('First'), findsNothing);

    await tester.longPress(find.text('Second'));
    await tester.pumpAndSettle();
    await tapDialogButton(tester, 'Delete');
    expect(repo.deletedIds, ['a', 'b']);
    expect(find.text('Second'), findsNothing);
    handle.dispose();
  });

  testWidgets('rapid double tap on Delete sends one delete', (tester) async {
    final repo = await pump(tester, [_n('a', 'First'), _n('b', 'Second')]);

    await tester.drag(find.text('First'), const Offset(-500, 0));
    await tester.pumpAndSettle();
    final deleteBtn = find.widgetWithText(TextButton, 'Delete');
    await tester.tap(deleteBtn);
    await tester.tap(deleteBtn);
    await tester.pumpAndSettle();

    expect(repo.deletedIds, ['a']);
    expect(find.text('Second'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets(
      'swiping the same row again while its dialog is open opens no second dialog',
      (tester) async {
    final repo = await pump(tester, [_n('a', 'First'), _n('b', 'Second')]);

    await swipeLeft(tester, 'First');
    expect(find.text('Delete this notification?'), findsOneWidget);
    await swipeLeft(tester, 'First');
    expect(find.text('Delete this notification?'), findsOneWidget);

    await tapDialogButton(tester, 'Delete');
    expect(repo.deletedIds, ['a']);
    expect(tester.takeException(), isNull);
  });

  testWidgets('swiping a second row while the first dialog is open is blocked',
      (tester) async {
    final repo = await pump(tester, [_n('a', 'First'), _n('b', 'Second')]);

    await swipeLeft(tester, 'First');
    await swipeLeft(tester, 'Second');
    expect(find.text('Delete this notification?'), findsOneWidget);

    await tapDialogButton(tester, 'Cancel');
    expect(repo.deletedIds, isEmpty);
    expect(find.text('First'), findsOneWidget);
    expect(find.text('Second'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets(
      'row deleted while a pull-to-refresh is in flight does not come back',
      (tester) async {
    final repo = await pump(
        tester, [_n('a', 'First'), _n('b', 'Second'), _n('c', 'Third')]);

    // 1. Delete of First is in flight on the server.
    final deleteGate = Completer<void>();
    repo.deleteGate = deleteGate;
    await swipeLeft(tester, 'First');
    await tapDialogButton(tester, 'Delete');
    await tester.pump(const Duration(milliseconds: 300));
    expect(repo.deletedIds, isEmpty);

    // 2. Refresh starts; its response is read before the delete commits,
    //    so it still contains First.
    final refreshGate = Completer<void>();
    repo.refreshGate = refreshGate;
    final before = repo.refreshCalls;
    await pullToRefresh(tester);
    expect(repo.refreshCalls, greaterThan(before));

    // 3. Delete commits and returns while the refresh is still pending.
    deleteGate.complete();
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 300));
    expect(repo.deletedIds, ['a']);

    // 4. Stale refresh response arrives last.
    refreshGate.complete();
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 300));

    // Expected: the deleted row is gone. The server does not have it.
    expect(find.text('First'), findsNothing);
    expect(find.text('Second'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets(
      'Delete all while the next page is loading does not bring rows back',
      (tester) async {
    final seed = List.generate(
        25, (i) => _n('id$i', 'N${i.toString().padLeft(2, '0')}'));
    final repo = await pump(tester, seed);

    // Hold page 2 (offset 20) open, then scroll to the end to request it.
    final pageGate = Completer<void>();
    repo.pageGate = pageGate;
    for (var i = 0; i < 12; i++) {
      await tester.drag(find.byType(ListView).first, const Offset(0, -400));
      await tester.pump();
    }
    await tester.pump(const Duration(milliseconds: 300));
    expect(repo.pageOffsets, [20]);
    // Known pre-existing issue (not T-0168): the load-more skeleton is an
    // unbounded ListView inside the list and throws a layout error while
    // page 2 is pending. Capture it here so the check below stays clean.
    final skeletonErrs = <String>[];
    for (Object? e = tester.takeException();
        e != null;
        e = tester.takeException()) {
      skeletonErrs.add(e.toString().split('\n').first);
    }
    // ignore: avoid_print
    print('LOAD-MORE SKELETON EXCEPTIONS: $skeletonErrs');
    // B3 fixed (shrinkWrap): the load-more skeleton no longer throws.
    expect(skeletonErrs, isEmpty);

    // Delete all completes while page 2 is still in flight.
    // The shimmering skeleton never settles, so pump by hand here.
    await tester.tap(find.byIcon(Icons.more_vert));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 600));
    await tester.tap(find.text('Delete all').last);
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 600));
    await tapDialogButton(tester, 'Delete all');
    expect(repo.rows, isEmpty);

    // Page 2 returns with its pre-delete snapshot (5 rows).
    pageGate.complete();
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 300));

    // Expected: nothing comes back and the empty state is shown.
    expect(find.text('N20'), findsNothing);
    expect(find.text('No notifications'), findsOneWidget);
    expect(find.byIcon(Icons.more_vert), findsNothing);
    expect(tester.takeException(), isNull);
  });

  testWidgets(
      'long list: delete a loaded row, then scroll to the end: no skipped or duplicated rows',
      (tester) async {
    final seed = List.generate(
        45, (i) => _n('id$i', 'N${i.toString().padLeft(2, '0')}'));
    final repo = await pump(tester, seed);

    // Only page 1 (rows 0-19) is loaded. Delete N05, which is in that page.
    await swipeLeft(tester, 'N05');
    await tapDialogButton(tester, 'Delete');
    expect(repo.deletedIds, ['id5']);

    final shown = await collectAllTitles(tester);

    final expected = {
      for (var i = 0; i < 45; i++)
        if (i != 5) 'N${i.toString().padLeft(2, '0')}',
    };
    expect(shown, expected, reason: 'every remaining row exactly once');
    // Offset after delete must be 19 (20 loaded - 1 deleted), not 20.
    expect(repo.pageOffsets, [19, 39]);
    expect(tester.takeException(), isNull);
  });
}
