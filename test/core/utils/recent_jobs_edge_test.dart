import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:freelancer/core/utils/recent_jobs.dart';
import 'package:freelancer/l10n/app_localizations.dart';
import 'package:google_fonts/google_fonts.dart';

/// T-0166 QA edge cases: recent jobs ordering, cap, empty input, and the
/// posted-date line with missing / invalid / same-day dates. Fake data only.
void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  setUpAll(() => GoogleFonts.config.allowRuntimeFetching = false);

  Map<String, dynamic> job(String id, Object? created) =>
      {'id': id, 'created_at': created};

  List<String> ids(List<Map<String, dynamic>> l) =>
      l.map((j) => j['id'] as String).toList();

  group('newestJobsFirst', () {
    test('0 jobs returns an empty list (drives the empty state)', () {
      expect(newestJobsFirst([]), isEmpty);
    });

    test('1 job is returned as is', () {
      expect(ids(newestJobsFirst([job('only', '2026-11-12T10:00:00Z')])),
          ['only']);
    });

    test('more than 3 jobs is capped at 3, newest kept', () {
      final out = newestJobsFirst([
        job('d1', '2026-01-01T10:00:00Z'),
        job('d5', '2026-05-01T10:00:00Z'),
        job('d3', '2026-03-01T10:00:00Z'),
        job('d7', '2026-07-01T10:00:00Z'),
        job('d2', '2026-02-01T10:00:00Z'),
      ]);
      expect(ids(out), ['d7', 'd5', 'd3']);
    });

    test('exactly 3 jobs are all kept', () {
      final out = newestJobsFirst([
        job('a', '2026-01-01T10:00:00Z'),
        job('b', '2026-02-01T10:00:00Z'),
        job('c', '2026-03-01T10:00:00Z'),
      ]);
      expect(ids(out), ['c', 'b', 'a']);
    });

    test('null created_at goes last, does not crash', () {
      final out = newestJobsFirst([
        job('null', null),
        job('old', '2026-01-02T10:00:00Z'),
        job('new', '2026-11-12T10:00:00Z'),
      ]);
      expect(ids(out), ['new', 'old', 'null']);
    });

    test('missing created_at key goes last', () {
      final out = newestJobsFirst([
        {'id': 'nokey'},
        job('dated', '2026-11-12T10:00:00Z'),
      ]);
      expect(ids(out), ['dated', 'nokey']);
    });

    test('empty string and invalid date go last', () {
      final out = newestJobsFirst([
        job('empty', ''),
        job('bad', 'not-a-date'),
        job('dated', '2026-11-12T10:00:00Z'),
      ]);
      expect(out.first['id'], 'dated');
      expect(ids(out).toSet(), {'empty', 'bad', 'dated'});
    });

    test('all dates null: every job is still returned (capped)', () {
      final out = newestJobsFirst([
        job('a', null),
        job('b', null),
        job('c', null),
        job('d', null),
      ]);
      expect(out.length, 3);
      expect(ids(out).toSet().length, 3);
    });

    test('same date, different times: ordered by time', () {
      final out = newestJobsFirst([
        job('early', '2026-11-12T08:00:00Z'),
        job('late', '2026-11-12T18:00:00Z'),
      ]);
      expect(ids(out), ['late', 'early']);
    });

    test('same exact timestamp: both kept (order not asserted)', () {
      final out = newestJobsFirst([
        job('x', '2026-11-12T10:00:00Z'),
        job('y', '2026-11-12T10:00:00Z'),
      ]);
      expect(out.length, 2);
      expect(ids(out).toSet(), {'x', 'y'});
    });

    test('does not mutate the input list', () {
      final input = [
        job('old', '2026-01-01T10:00:00Z'),
        job('new', '2026-11-12T10:00:00Z'),
      ];
      newestJobsFirst(input);
      expect(ids(input), ['old', 'new']);
    });

    test('custom limit is honoured', () {
      final out = newestJobsFirst([
        job('a', '2026-01-01T10:00:00Z'),
        job('b', '2026-02-01T10:00:00Z'),
      ], limit: 1);
      expect(ids(out), ['b']);
    });
  });

  Future<void> pumpDates(WidgetTester t, Locale l, double scale,
      List<Object?> dates, {double width = 160}) async {
    await t.pumpWidget(MaterialApp(
      locale: l,
      supportedLocales: AppLocalizations.supportedLocales,
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      builder: (c, child) => MediaQuery(
        data: MediaQuery.of(c).copyWith(textScaler: TextScaler.linear(scale)),
        child: child!,
      ),
      home: Scaffold(
        body: SizedBox(
          width: width,
          child: Column(children: [
            for (var i = 0; i < dates.length; i++)
              RecentJobPostedDate(
                  key: ValueKey<int>(i), createdAt: dates[i]),
          ]),
        ),
      ),
    ));
    await t.pump();
  }

  void ignoreFontErrors(WidgetTester t) {
    final old = FlutterError.onError;
    FlutterError.onError = (d) {
      if (d.toString().contains('google_fonts')) return;
      old?.call(d);
    };
    addTearDown(() => FlutterError.onError = old);
  }

  testWidgets('null / empty / invalid date renders no date line',
      (t) async {
    ignoreFontErrors(t);
    await pumpDates(t, const Locale('en'), 1.0,
        [null, '', 'not-a-date']);
    expect(find.textContaining('Posted'), findsNothing);
    expect(t.takeException(), isNull);
  });

  testWidgets('same date on two cards shows two date lines (EN)', (t) async {
    ignoreFontErrors(t);
    // Local-date construction so the same calendar day holds in any TZ.
    await pumpDates(t, const Locale('en'), 1.0, [
      DateTime(2026, 11, 12, 8).toUtc().toIso8601String(),
      DateTime(2026, 11, 12, 18).toUtc().toIso8601String(),
    ]);
    expect(find.text('Posted 12 Nov 2026'), findsNWidgets(2));
    expect(t.takeException(), isNull);
  });

  testWidgets('BN locale shows the Bangla posted line without error',
      (t) async {
    ignoreFontErrors(t);
    final bn = lookupAppLocalizations(const Locale('bn'));
    await pumpDates(t, const Locale('bn'), 1.0, [DateTime(2026, 11, 12, 10).toUtc().toIso8601String()]);
    expect(find.textContaining(bn.recentJobPostedOn('X').split('X').first),
        findsOneWidget);
    expect(t.takeException(), isNull);
  });

  for (final scale in [1.0, 1.5, 2.0]) {
    testWidgets('NL date line at x$scale in a 160dp column (no overflow)',
        (t) async {
      ignoreFontErrors(t);
      await pumpDates(t, const Locale('nl'), scale,
          [DateTime(2026, 11, 12, 10).toUtc().toIso8601String()], width: 160);
      expect(find.textContaining('Geplaatst op 12 nov'), findsOneWidget);
      expect(t.takeException(), isNull);
    });
  }

  testWidgets('NL date line at x2.0 in a narrow 110dp column (no overflow)',
      (t) async {
    ignoreFontErrors(t);
    await pumpDates(t, const Locale('nl'), 2.0,
        [DateTime(2026, 11, 12, 10).toUtc().toIso8601String()], width: 110);
    expect(find.textContaining('Geplaatst op'), findsOneWidget);
    expect(t.takeException(), isNull);
  });
}
