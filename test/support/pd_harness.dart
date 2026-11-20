import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:freelancer/l10n/app_localizations.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Shared setup for the T-0172 private-details widget tests (no network).
void pdSetUp() {
  TestWidgetsFlutterBinding.ensureInitialized();
  GoogleFonts.config.allowRuntimeFetching = false;
  SharedPreferences.setMockInitialValues({});
}

/// google_fonts cannot load Inter in tests; drop only those errors.
void pdIgnoreFontErrors() {
  final old = FlutterError.onError;
  FlutterError.onError = (d) {
    if (d.toString().contains('google_fonts')) return;
    old?.call(d);
  };
  addTearDown(() => FlutterError.onError = old);
}

/// Pumps [child] at 375x667 (iPhone SE class) with locale and text scale.
Future<void> pdPump(
  WidgetTester t,
  Widget child, {
  Locale locale = const Locale('en'),
  double scale = 1.0,
}) async {
  pdIgnoreFontErrors();
  await t.binding.setSurfaceSize(const Size(375, 667));
  addTearDown(() => t.binding.setSurfaceSize(null));
  await t.pumpWidget(MaterialApp(
    locale: locale,
    supportedLocales: AppLocalizations.supportedLocales,
    localizationsDelegates: AppLocalizations.localizationsDelegates,
    builder: (c, w) => MediaQuery(
      data: MediaQuery.of(c).copyWith(textScaler: TextScaler.linear(scale)),
      child: w!,
    ),
    home: child,
  ));
  await t.pump();
  await t.pump();
}
