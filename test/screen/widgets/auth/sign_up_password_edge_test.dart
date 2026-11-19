import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:freelancer/core/constants/colors.dart';
import 'package:freelancer/l10n/app_localizations.dart';
import 'package:freelancer/screen/app_config/app_config.dart';
import 'package:freelancer/screen/widgets/auth/sign_up_screen.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// T-0163 QA edge cases for the sign-up screen (confirm password, strength
/// hint, role colours, XL layout). Blocking paths only: every case here must
/// stop before Supabase is called, so no backend is initialised. Fake data.
void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  setUpAll(() {
    GoogleFonts.config.allowRuntimeFetching = false;
    SharedPreferences.setMockInitialValues({});
  });

  final en = lookupAppLocalizations(const Locale('en'));
  final nl = lookupAppLocalizations(const Locale('nl'));

  // Mirrors the real call sites: client_sign_up.dart and seller_sign_up.dart.
  Color accentFor(String role) =>
      role == 'seller' ? kSecondaryColor : kPrimaryColor;

  Future<void> pump(WidgetTester t, Locale locale, double scale,
      {String role = 'client', void Function()? onSignedUp}) async {
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
        accentColor: accentFor(role),
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

  Future<void> tickTerms(WidgetTester t) async {
    await t.ensureVisible(find.byType(Checkbox));
    await t.tap(find.byType(Checkbox));
    await t.pump();
  }

  Future<void> submit(WidgetTester t, String label) async {
    await t.ensureVisible(find.text(label));
    await t.tap(find.text(label));
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

  Color barColor(WidgetTester t, int i) =>
      (t.widget<Container>(find.byKey(ValueKey('strength-bar-$i')))
              .decoration as BoxDecoration)
          .color!;

  testWidgets('confirm empty: no inline error, submit blocked as mismatch',
      (t) async {
    ignoreFontErrors(t);
    var signedUp = false;
    await pump(t, const Locale('en'), 1.0,
        onSignedUp: () => signedUp = true);
    await fill(t, 'abcdef1!', '');
    expect(find.text(en.authPasswordsDoNotMatch), findsNothing);
    await submit(t, en.authSignUpButton);
    expect(find.text(en.authPasswordsDoNotMatch), findsOneWidget);
    expect(signedUp, isFalse);
    expect(t.takeException(), isNull);
  });

  testWidgets('both password and confirm empty: fill-all-fields message',
      (t) async {
    ignoreFontErrors(t);
    var signedUp = false;
    await pump(t, const Locale('en'), 1.0,
        onSignedUp: () => signedUp = true);
    await fill(t, '', '');
    await tickTerms(t);
    await submit(t, en.authSignUpButton);
    expect(find.text(en.pleaseFillAllFields), findsOneWidget);
    expect(signedUp, isFalse);
  });

  testWidgets('equal but 5 chars is blocked by the 6-char minimum',
      (t) async {
    ignoreFontErrors(t);
    var signedUp = false;
    await pump(t, const Locale('en'), 1.0,
        onSignedUp: () => signedUp = true);
    await fill(t, 'abc12', 'abc12');
    expect(find.text(en.authPasswordsDoNotMatch), findsNothing);
    await tickTerms(t);
    await submit(t, en.authSignUpButton);
    expect(find.text(en.authPasswordMinLength), findsOneWidget);
    expect(signedUp, isFalse);
    expect(t.takeException(), isNull);
  });

  testWidgets('equal valid password but terms unticked: blocked, no signup',
      (t) async {
    ignoreFontErrors(t);
    var signedUp = false;
    await pump(t, const Locale('en'), 1.0,
        onSignedUp: () => signedUp = true);
    await fill(t, 'abcdef1!', 'abcdef1!');
    await submit(t, en.authSignUpButton);
    expect(find.text(en.authMustAgreeTerms), findsOneWidget);
    expect(signedUp, isFalse);
  });

  testWidgets('trailing space makes passwords differ: blocked', (t) async {
    ignoreFontErrors(t);
    var signedUp = false;
    await pump(t, const Locale('en'), 1.0,
        onSignedUp: () => signedUp = true);
    await fill(t, 'abcdef1!', 'abcdef1! ');
    expect(find.text(en.authPasswordsDoNotMatch), findsOneWidget);
    await tickTerms(t);
    await submit(t, en.authSignUpButton);
    expect(find.text(en.authPasswordsDoNotMatch), findsNWidgets(2));
    expect(signedUp, isFalse);
  });

  testWidgets('leading space makes passwords differ: blocked', (t) async {
    ignoreFontErrors(t);
    var signedUp = false;
    await pump(t, const Locale('en'), 1.0,
        onSignedUp: () => signedUp = true);
    await fill(t, ' abcdef1!', 'abcdef1!');
    expect(find.text(en.authPasswordsDoNotMatch), findsOneWidget);
    await tickTerms(t);
    await submit(t, en.authSignUpButton);
    expect(signedUp, isFalse);
  });

  testWidgets(
      'observation: whitespace-only equal password passes client checks',
      (t) async {
    ignoreFontErrors(t);
    await pump(t, const Locale('en'), 1.0);
    await fill(t, '      ', '      ');
    expect(find.text(en.authPasswordsDoNotMatch), findsNothing);
    await submit(t, en.authSignUpButton);
    // Length and match checks pass for six spaces; only the terms gate stops
    // it here. Client-side code does not reject whitespace-only passwords.
    expect(find.text(en.authMustAgreeTerms), findsOneWidget);
    expect(t.takeException(), isNull);
  });

  testWidgets('very long equal password (200 chars): no error, strength shown',
      (t) async {
    ignoreFontErrors(t);
    final pw = '${'Abcdefgh1!' * 20}';
    expect(pw.length, 200);
    await pump(t, const Locale('en'), 1.0);
    await fill(t, pw, pw);
    expect(find.text(en.authPasswordsDoNotMatch), findsNothing);
    expect(find.text(en.authPasswordStrengthStrong), findsOneWidget);
    await submit(t, en.authSignUpButton);
    expect(find.text(en.authMustAgreeTerms), findsOneWidget);
    expect(t.takeException(), isNull);
  });

  testWidgets('inline mismatch clears once confirm is corrected',
      (t) async {
    ignoreFontErrors(t);
    await pump(t, const Locale('en'), 1.0);
    await fill(t, 'abcdef1!', 'abcdef1?');
    expect(find.text(en.authPasswordsDoNotMatch), findsOneWidget);
    await t.enterText(find.byType(TextField).at(4), 'abcdef1!');
    await t.pump();
    expect(find.text(en.authPasswordsDoNotMatch), findsNothing);
  });

  testWidgets('strength label follows 5 / 6 / 8 char boundaries (EN)',
      (t) async {
    ignoreFontErrors(t);
    await pump(t, const Locale('en'), 1.0);
    final pw = find.byType(TextField).at(3);
    await t.enterText(pw, 'Ab1!x');
    await t.pump();
    expect(find.text(en.authPasswordStrengthWeak), findsOneWidget);
    await t.enterText(pw, 'Ab1!xy');
    await t.pump();
    expect(find.text(en.authPasswordStrengthMedium), findsOneWidget);
    await t.enterText(pw, 'abcdef1!');
    await t.pump();
    expect(find.text(en.authPasswordStrengthStrong), findsOneWidget);
    expect(t.takeException(), isNull);
  });

  testWidgets('strength bar colours are semantic and identical per role',
      (t) async {
    ignoreFontErrors(t);
    final results = <String, List<Color>>{};
    for (final role in ['client', 'seller']) {
      await pump(t, const Locale('en'), 1.0, role: role);
      final pw = find.byType(TextField).at(3);
      final out = <Color>[];
      for (final v in ['abc', 'Abcdef12', 'abcdef1!']) {
        await t.enterText(pw, v);
        await t.pump();
        out.addAll([barColor(t, 0), barColor(t, 1), barColor(t, 2)]);
      }
      results[role] = out;
    }
    expect(results['client'], results['seller']);
    // weak: 1 red, 2 grey; medium: 2 amber; strong: 3 green.
    expect(results['client']!.sublist(0, 3),
        [const Color(0xFFD32F2F), kBorderColorTextField, kBorderColorTextField]);
    expect(results['client']!.sublist(3, 6),
        [const Color(0xFFF9A825), const Color(0xFFF9A825), kBorderColorTextField]);
    expect(results['client']!.sublist(6, 9),
        [const Color(0xFF2E7D32), const Color(0xFF2E7D32), const Color(0xFF2E7D32)]);
  });

  for (final role in ['client', 'seller']) {
    testWidgets('focus border uses the $role accent on password field',
        (t) async {
      ignoreFontErrors(t);
      await pump(t, const Locale('en'), 1.0, role: role);
      final tf = t.widget<TextField>(find.byType(TextField).at(3));
      final border = tf.decoration!.focusedBorder as OutlineInputBorder;
      expect(border.borderSide.color, accentFor(role));
    });
  }

  // ---- Visual checklist: EN/NL x 1.0/1.5/2.0 x client/seller ----
  for (final role in ['client', 'seller']) {
    for (final locale in [const Locale('en'), const Locale('nl')]) {
      for (final scale in [1.0, 1.5, 2.0]) {
        testWidgets(
            'visual: $role ${locale.languageCode} x$scale, form renders, no overflow',
            (t) async {
          ignoreFontErrors(t);
          final l10n = locale.languageCode == 'nl' ? nl : en;
          await pump(t, locale, scale, role: role);
          await fill(t, 'Abcdef12', 'Abcdef12');
          expect(find.text(l10n.authPasswordStrengthMedium), findsOneWidget);
          expect(find.text(l10n.authPasswordStrengthHint), findsOneWidget);
          expect(find.text(l10n.authSignUpButton), findsOneWidget);
          expect(t.takeException(), isNull);
        });
      }
    }
  }
}
