import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:freelancer/core/constants/colors.dart';
import 'package:freelancer/core/utils/password_strength.dart';
import 'package:freelancer/l10n/app_localizations.dart';
import 'package:freelancer/screen/app_config/app_config.dart';
import 'package:freelancer/screen/widgets/auth/sign_up_screen.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// T-0163: confirm-password mismatch blocks submit; strength label updates.
/// No Supabase init: mismatch must stop before any network call.
void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  setUpAll(() {
    GoogleFonts.config.allowRuntimeFetching = false;
    SharedPreferences.setMockInitialValues({});
  });

  test('passwordStrength classes', () {
    expect(passwordStrength(''), PasswordStrength.empty);
    expect(passwordStrength('abc'), PasswordStrength.weak);
    expect(passwordStrength('abcdefgh'), PasswordStrength.weak);
    expect(passwordStrength('abcdef1'), PasswordStrength.medium);
    expect(passwordStrength('abcdefg1!'), PasswordStrength.strong);
    expect(passwordStrength('Abcdefghij1k'), PasswordStrength.strong);
  });

  final en = lookupAppLocalizations(const Locale('en'));
  final nl = lookupAppLocalizations(const Locale('nl'));

  Future<void> pump(WidgetTester t, Locale locale, double scale,
      {Color accent = kPrimaryFill,
      String role = 'client',
      void Function()? onSignedUp}) async {
    await t.binding.setSurfaceSize(const Size(390, 844));
    addTearDown(() => t.binding.setSurfaceSize(null));
    await t.pumpWidget(MaterialApp(
      locale: locale,
      supportedLocales: AppLocalizations.supportedLocales,
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      builder: (c, child) => MediaQuery(
        data: MediaQuery.of(c).copyWith(textScaler: TextScaler.linear(scale)),
        child: child!,
      ),
      home: SignUpScreen(
        role: role,
        accentColor: accent,
        heroImage: AppInfo.onBoard2,
        subtitle: (l) => l.authCreateAccount,
        roleLabel: (l) => 'x',
        onSignedUp: (_, __) async => onSignedUp?.call(),
      ),
    ));
    await t.pump();
  }

  Future<void> fill(WidgetTester t, String pw, String confirm) async {
    final f = find.byType(TextField);
    await t.enterText(f.at(0), 'QA');
    await t.enterText(f.at(1), 'Tester');
    await t.enterText(f.at(2), 'qa@example.invalid');
    await t.enterText(f.at(3), pw);
    await t.enterText(f.at(4), confirm);
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

  for (final (locale, l10n, scale) in [
    (const Locale('en'), en, 1.0),
    (const Locale('nl'), nl, 1.5),
  ]) {
    testWidgets('mismatch blocks submit (${locale.languageCode}, x$scale)',
        (t) async {
      ignoreFontErrors(t);
      var signedUp = false;
      await pump(t, locale, scale, onSignedUp: () => signedUp = true);
      await fill(t, 'abcdef1!', 'abcdef2!');
      // inline error under confirm field
      expect(find.text(l10n.authPasswordsDoNotMatch), findsOneWidget);

      await t.ensureVisible(find.byType(Checkbox));
      await t.tap(find.byType(Checkbox));
      await t.pump();
      await t.ensureVisible(find.text(l10n.authSignUpButton));
      await t.tap(find.text(l10n.authSignUpButton));
      await t.pump();
      // snackbar + inline error both showing; never signed up
      expect(find.text(l10n.authPasswordsDoNotMatch), findsNWidgets(2));
      expect(signedUp, isFalse);
      expect(t.takeException(), isNull);
    });

    testWidgets('strength label updates (${locale.languageCode}, x$scale)',
        (t) async {
      ignoreFontErrors(t);
      await pump(t, locale, scale);
      final pw = find.byType(TextField).at(3);
      expect(find.text(l10n.authPasswordStrengthHint), findsOneWidget);
      expect(find.text(l10n.authPasswordStrengthWeak), findsNothing);

      await t.enterText(pw, 'abc');
      await t.pump();
      expect(find.text(l10n.authPasswordStrengthWeak), findsOneWidget);

      await t.enterText(pw, 'abcdef1');
      await t.pump();
      expect(find.text(l10n.authPasswordStrengthMedium), findsOneWidget);

      await t.enterText(pw, 'abcdefg1!');
      await t.pump();
      expect(find.text(l10n.authPasswordStrengthStrong), findsOneWidget);
      expect(find.text(l10n.authPasswordStrengthWeak), findsNothing);
      expect(t.takeException(), isNull);
    });
  }
}
