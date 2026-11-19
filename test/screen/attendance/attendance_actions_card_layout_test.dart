// Regression: the attendance card header (title + mode chip + status) used a
// Row with a Spacer and overflowed by 8px on a 402pt iPhone at default text
// size (owner screenshot, 2026-11-19). It now wraps.
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:freelancer/core/utils/attendance_mode.dart';
import 'package:freelancer/l10n/app_localizations.dart';
import 'package:freelancer/screen/attendance/attendance_actions_card.dart';

import '../../support/qa_supabase.dart';

Widget _host(Locale locale, double scale) => MaterialApp(
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      locale: locale,
      home: Builder(
        builder: (context) => MediaQuery(
          data: MediaQuery.of(context)
              .copyWith(textScaler: TextScaler.linear(scale)),
          child: const Scaffold(
            body: SingleChildScrollView(
              padding: EdgeInsets.all(20),
              child: AttendanceActionsCard(
                orderId: 'order-1',
                jobPostId: 'job-1',
                attendanceMode: AttendanceMode.qrOnce,
                statusLabel: 'Not checked in yet',
              ),
            ),
          ),
        ),
      ),
    );

void main() {
  setUpAll(() async {
    await initQaSupabase(tables: const {}, signedIn: true);
  });

  for (final size in const [Size(375, 812), Size(402, 874)]) {
    for (final locale in const [Locale('en'), Locale('nl')]) {
      for (final scale in const [1.0, 1.5, 2.0]) {
        testWidgets(
            'header has no overflow: ${size.width.toInt()}pt '
            '${locale.languageCode} x$scale', (tester) async {
          tester.view.physicalSize = size;
          tester.view.devicePixelRatio = 1.0;
          addTearDown(tester.view.reset);

          await tester.pumpWidget(_host(locale, scale));
          await tester.pump(const Duration(milliseconds: 100));

          expect(tester.takeException(), isNull);
          expect(find.text('Not checked in yet'), findsOneWidget);
        });
      }
    }
  }
}
