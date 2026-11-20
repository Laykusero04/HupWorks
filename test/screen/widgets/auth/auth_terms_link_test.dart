import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:freelancer/core/constants/colors.dart';
import 'package:freelancer/l10n/app_localizations.dart';
import 'package:freelancer/screen/app_config/app_config.dart';
import 'package:freelancer/screen/widgets/auth/auth_ui.dart';
import 'package:google_fonts/google_fonts.dart';

/// T-0162: the "Terms of Service" span on signup opens AppInfo.termsUrl.
void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  setUpAll(() => GoogleFonts.config.allowRuntimeFetching = false);

  test('terms URL constant', () {
    expect(AppInfo.termsUrl, 'https://hupworks-web.vercel.app/terms.html');
  });

  Future<void> pump(
    WidgetTester t, {
    required Future<bool> Function(Uri) launcher,
    Locale locale = const Locale('en'),
    ValueChanged<bool?>? onChanged,
  }) async {
    await t.pumpWidget(MaterialApp(
      locale: locale,
      supportedLocales: AppLocalizations.supportedLocales,
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      home: Scaffold(
        body: Padding(
          padding: const EdgeInsets.all(16),
          child: AuthTermsRow(
            checked: false,
            accentColor: kPrimaryFill,
            onChanged: onChanged ?? (_) {},
            launcher: launcher,
          ),
        ),
      ),
    ));
  }

  /// Taps the terms TextSpan (it is a recognizer, not a widget).
  void tapTerms(WidgetTester t) {
    TapGestureRecognizer? found;
    for (final rich in t.widgetList<RichText>(find.byType(RichText))) {
      rich.text.visitChildren((span) {
        if (span is TextSpan && span.recognizer is TapGestureRecognizer) {
          found = span.recognizer as TapGestureRecognizer;
        }
        return true;
      });
    }
    expect(found, isNotNull, reason: 'Terms span must have a tap recognizer');
    found!.onTap!();
  }

  testWidgets('tapping Terms calls the launcher with the terms URL', (t) async {
    final calls = <Uri>[];
    await pump(t, launcher: (u) async {
      calls.add(u);
      return true;
    });
    tapTerms(t);
    await t.pump();
    expect(calls, [Uri.parse('https://hupworks-web.vercel.app/terms.html')]);
    expect(find.byType(SnackBar), findsNothing);
  });

  testWidgets('shows a snackbar when the link cannot open (EN)', (t) async {
    await pump(t, launcher: (_) async => false);
    tapTerms(t);
    await t.pump();
    expect(
      find.text('Could not open the Terms of Service. Please try again later.'),
      findsOneWidget,
    );
  });

  testWidgets('shows a snackbar when the launcher throws (NL)', (t) async {
    await pump(
      t,
      launcher: (_) async => throw Exception('no browser'),
      locale: const Locale('nl'),
    );
    tapTerms(t);
    await t.pump();
    expect(find.textContaining('Kon de Servicevoorwaarden niet openen'),
        findsOneWidget);
  });

  testWidgets('checkbox still toggles and does not launch', (t) async {
    var launched = 0;
    bool? changed;
    await pump(t,
        launcher: (_) async {
          launched++;
          return true;
        },
        onChanged: (v) => changed = v);
    await t.tap(find.byType(Checkbox));
    expect(changed, isTrue);
    expect(launched, 0);
  });

  testWidgets('disposes the recognizer without error', (t) async {
    await pump(t, launcher: (_) async => true);
    await t.pumpWidget(const SizedBox());
    expect(t.takeException(), isNull);
  });
}
