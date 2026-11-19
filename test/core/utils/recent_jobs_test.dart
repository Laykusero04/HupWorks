import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:freelancer/core/utils/recent_jobs.dart';
import 'package:freelancer/l10n/app_localizations.dart';
import 'package:google_fonts/google_fonts.dart';

/// T-0166: recent jobs sorted newest first (max 3) and show a localized date.
void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  setUpAll(() => GoogleFonts.config.allowRuntimeFetching = false);

  Map<String, dynamic> job(String id, String? created) =>
      {'id': id, 'created_at': created};

  test('newestJobsFirst sorts desc by created_at, nulls last, caps at 3', () {
    final out = newestJobsFirst([
      job('old', '2026-01-02T10:00:00Z'),
      job('none', null),
      job('new', '2026-11-12T10:00:00Z'),
      job('mid', '2026-06-01T10:00:00Z'),
      job('mid2', '2026-05-01T10:00:00Z'),
    ]);
    expect(out.map((j) => j['id']), ['new', 'mid', 'mid2']);
  });

  Future<void> pump(WidgetTester t, Locale l, double scale) async {
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
          width: 160,
          child: Column(children: [
            for (final j in newestJobsFirst([
              job('a', '2026-03-05T12:00:00Z'),
              job('b', '2026-11-12T12:00:00Z'),
            ]))
              RecentJobPostedDate(
                  key: ValueKey<String>('${j['id']}'),
                  createdAt: j['created_at']),
          ]),
        ),
      ),
    ));
    await t.pump();
  }

  testWidgets('EN date, newest first', (t) async {
    final old = FlutterError.onError;
    FlutterError.onError = (d) {
      if (!d.toString().contains('google_fonts')) old?.call(d);
    };
    addTearDown(() => FlutterError.onError = old);
    await pump(t, const Locale('en'), 1.0);
    expect(find.text('Posted 12 Nov 2026'), findsOneWidget);
    expect(find.text('Posted 5 Mar 2026'), findsOneWidget);
    expect(t.getTopLeft(find.byKey(const ValueKey<String>('b'))).dy,
        lessThan(t.getTopLeft(find.byKey(const ValueKey<String>('a'))).dy));
  });

  testWidgets('NL date at XL text without overflow', (t) async {
    final old = FlutterError.onError;
    FlutterError.onError = (d) {
      if (!d.toString().contains('google_fonts')) old?.call(d);
    };
    addTearDown(() => FlutterError.onError = old);
    await pump(t, const Locale('nl'), 2.0);
    expect(find.textContaining('Geplaatst op 12 nov'), findsOneWidget);
    expect(t.takeException(), isNull);
  });
}
