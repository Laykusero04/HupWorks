import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:freelancer/core/constants/colors.dart';
import 'package:freelancer/core/utils/employer_verification_gate.dart';
import 'package:freelancer/l10n/app_localizations.dart';
import 'package:freelancer/screen/client screen/client job post/employer_verification_required_gate.dart';
import 'package:freelancer/screen/widgets/auth/auth_ui.dart';
import 'package:google_fonts/google_fonts.dart';

/// Visual checklist (QA, widget level) for T-0171 gate screen and T-0162
/// signup terms row. EN + NL at text scale 1.0 / 1.5 / 2.0 on a 375pt-wide
/// viewport (iPhone SE-class width, 375x667).
///
/// This is NOT a device check. Fonts are the test fallback (google_fonts cannot
/// load Inter/Jost here), so widths differ from the real app. Device rows stay
/// UNVERIFIED until mobile-qa-tester runs on a simulator.
void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUpAll(() => GoogleFonts.config.allowRuntimeFetching = false);

  const viewport = Size(375, 667);
  const scales = [1.0, 1.5, 2.0];
  const locales = ['en', 'nl'];

  for (final code in locales) {
    for (final scale in scales) {
      final name = '$code x$scale';

      guarded('gate screen $name: no overflow, actions on screen', (t) async {
        final l10n = lookupAppLocalizations(Locale(code));
        await _pump(
          t,
          viewport: viewport,
          scale: scale,
          locale: Locale(code),
          child: EmployerVerificationRequiredGate(
            access: EmployerPostAccess.required,
            onVerify: () async {},
          ),
        );
        expect(t.takeException(), isNull);
        expect(find.text(l10n.employerVerifyRequiredTitle), findsOneWidget);
        _expectInside(t, find.text(l10n.employerVerifyStartButton), viewport,
            'required button');
        _expectInside(t, find.text(l10n.employerVerifyRequiredTitle), viewport,
            'required title');
      });

      guarded('gate screen pending $name: no overflow, actions on screen',
          (t) async {
        final l10n = lookupAppLocalizations(Locale(code));
        await _pump(
          t,
          viewport: viewport,
          scale: scale,
          locale: Locale(code),
          child: EmployerVerificationRequiredGate(
            access: EmployerPostAccess.pending,
            onVerify: () async {},
          ),
        );
        expect(t.takeException(), isNull);
        expect(find.text(l10n.employerVerifyPendingTitle), findsOneWidget);
        _expectInside(t, find.text(l10n.employerVerifyViewStatusButton),
            viewport, 'pending button');
      });

      guarded('signup terms row $name: no overflow, text inside width',
          (t) async {
        final l10n = lookupAppLocalizations(Locale(code));
        await _pump(
          t,
          viewport: viewport,
          scale: scale,
          locale: Locale(code),
          child: Scaffold(
            body: Padding(
              padding: const EdgeInsets.all(16),
              child: AuthTermsRow(
                checked: false,
                accentColor: kPrimaryFill,
                onChanged: (_) {},
                launcher: (_) async => true,
              ),
            ),
          ),
        );
        expect(t.takeException(), isNull);
        final checkbox = find.byType(Checkbox);
        expect(checkbox, findsOneWidget);
        _expectInside(t, checkbox, viewport, 'checkbox');
        // The terms span is part of a RichText; check the whole row box.
        final row = find.byType(AuthTermsRow);
        _expectInside(t, row, viewport, 'terms row');
        // The "Terms of Service" link is a TextSpan inside RichText.
        final richTexts = find.byType(RichText);
        expect(richTexts, findsWidgets);
        var checked = 0;
        for (final e in richTexts.evaluate()) {
          final rt = e.widget as RichText;
          if (rt.text.toPlainText().contains(l10n.authTermsOfService)) {
            checked++;
            _expectInside(t, find.byWidget(rt), viewport, 'terms text');
          }
        }
        expect(checked, greaterThan(0), reason: 'terms link text not found');
      });
    }
  }
}

/// Runs a widget test body in a zone that drops google_fonts load errors
/// (no font assets in tests). Same approach as sign_up_auth_error_test.dart.
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

Future<void> _pump(
  WidgetTester t, {
  required Size viewport,
  required double scale,
  required Locale locale,
  required Widget child,
}) async {
  await t.binding.setSurfaceSize(viewport);
  addTearDown(() => t.binding.setSurfaceSize(null));
  await t.pumpWidget(MaterialApp(
    locale: locale,
    supportedLocales: AppLocalizations.supportedLocales,
    localizationsDelegates: AppLocalizations.localizationsDelegates,
    builder: (context, w) => MediaQuery(
      data: MediaQuery.of(context)
          .copyWith(textScaler: TextScaler.linear(scale)),
      child: w!,
    ),
    home: child,
  ));
  for (var i = 0; i < 5; i++) {
    await t.runAsync(
        () => Future<void>.delayed(const Duration(milliseconds: 5)));
    await t.pump(const Duration(milliseconds: 50));
  }
}

/// The widget must be laid out and fully inside the viewport.
void _expectInside(WidgetTester t, Finder f, Size viewport, String what) {
  final rect = t.getRect(f.first);
  expect(rect.left >= 0 && rect.top >= 0, isTrue,
      reason: '$what starts off-screen: $rect');
  expect(rect.right <= viewport.width + 0.5, isTrue,
      reason: '$what runs past ${viewport.width}pt: $rect');
  expect(rect.bottom <= viewport.height + 0.5, isTrue,
      reason: '$what runs below ${viewport.height}pt: $rect');
}
