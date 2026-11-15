import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:freelancer/l10n/app_localizations.dart';
import 'package:freelancer/screen/widgets/job_client_info_card.dart';
import 'package:freelancer/screen/widgets/label_value_row.dart';
import 'package:freelancer/screen/widgets/word_safe_text.dart';

Widget _app(double scale, Widget child, {Locale? locale}) => MediaQuery(
      data: MediaQueryData(
          size: const Size(375, 800), textScaler: TextScaler.linear(scale)),
      child: MaterialApp(
        locale: locale,
        localizationsDelegates: const [
          AppLocalizations.delegate,
          GlobalMaterialLocalizations.delegate,
          GlobalWidgetsLocalizations.delegate,
          GlobalCupertinoLocalizations.delegate,
        ],
        supportedLocales: AppLocalizations.supportedLocales,
        home: Scaffold(body: SingleChildScrollView(child: child)),
      ),
    );

void main() {
  for (final scale in [1.0, 2.0]) {
    testWidgets('JobClientInfoCard no exception at scale $scale', (t) async {
      await t.pumpWidget(_app(
        scale,
        const JobClientInfoCard(
          rating: 4.5,
          reviewCount: 3,
          jobPostsCount: 12,
          memberSince: 'Jan 2024',
        ),
        locale: const Locale('nl'),
      ));
      await t.pumpAndSettle();
      expect(t.takeException(), isNull);
    });

    testWidgets('WordSafeText inside IntrinsicHeight at scale $scale',
        (t) async {
      await t.pumpWidget(_app(
        scale,
        const IntrinsicHeight(
          child: Row(children: [
            Expanded(
              child: WordSafeText('Beoordeling', style: TextStyle(fontSize: 14)),
            ),
            Expanded(child: WordSafeText('Lid sinds')),
          ]),
        ),
      ));
      expect(t.takeException(), isNull);
      expect(find.text('Beoordeling'), findsOneWidget);
    });

    testWidgets('WordSafeText inside IntrinsicWidth at scale $scale',
        (t) async {
      await t.pumpWidget(_app(
        scale,
        const IntrinsicWidth(
          child: WordSafeText('Beoordeling', style: TextStyle(fontSize: 14)),
        ),
      ));
      expect(t.takeException(), isNull);
    });

    testWidgets('LabelValueRow normal layout at scale $scale', (t) async {
      await t.pumpWidget(_app(
        scale,
        const LabelValueRow(
          label: 'Revisions',
          labelStyle: TextStyle(fontSize: 14),
          colon: ':',
          value: Text('Per job agreement'),
        ),
      ));
      expect(t.takeException(), isNull);
    });
  }
}
