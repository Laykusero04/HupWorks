import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:freelancer/core/constants/colors.dart';
import 'package:freelancer/l10n/app_localizations.dart';
import 'package:freelancer/screen/client%20screen/client_authentication/client_log_in.dart';
import 'package:freelancer/screen/seller%20screen/seller%20authentication/seller_log_in.dart';
import 'package:freelancer/screen/widgets/auth/forgot_password_screen.dart';
import 'package:freelancer/screen/widgets/auth/unified_log_in.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    GoogleFonts.config.allowRuntimeFetching = false;
    SharedPreferences.setMockInitialValues({});
  });

  Future<void> pumpLogin(
    WidgetTester tester, {
    Locale locale = const Locale('en'),
    Size surface = const Size(390, 844),
  }) async {
    await tester.binding.setSurfaceSize(surface);
    addTearDown(() => tester.binding.setSurfaceSize(null));
    await tester.pumpWidget(
      MaterialApp(
        locale: locale,
        supportedLocales: AppLocalizations.supportedLocales,
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        home: const UnifiedLogIn(),
      ),
    );
    await tester.pump();
  }

  test('client and seller login are the shared screen', () {
    expect(const ClientLogIn(), isA<UnifiedLogIn>());
    expect(const SellerLogIn(), isA<UnifiedLogIn>());
    expect(const ClientLogIn().role, 'client');
    expect(const SellerLogIn().role, 'seller');
  });

  testWidgets('each role login shows its chip and action color', (tester) async {
    Future<void> pumpRole(Widget home) async {
      await tester.pumpWidget(
        MaterialApp(
          locale: const Locale('en'),
          supportedLocales: AppLocalizations.supportedLocales,
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          home: home,
        ),
      );
      await tester.pump();
    }

    Color? buttonColor() {
      final button = tester.widget<FilledButton>(
        find.widgetWithText(FilledButton, 'Log In'),
      );
      return button.style?.backgroundColor?.resolve(const <WidgetState>{});
    }

    await pumpRole(const ClientLogIn());
    expect(find.text('Employer'), findsOneWidget);
    expect(find.text('Freelancer'), findsNothing);
    expect(buttonColor(), kPrimaryColor);

    await pumpRole(const SellerLogIn());
    expect(find.text('Freelancer'), findsOneWidget);
    expect(find.text('Employer'), findsNothing);
    expect(buttonColor(), kSellerPrimary);
  });

  testWidgets('password Done submits and fields sit in an autofill group', (
    tester,
  ) async {
    await pumpLogin(tester);

    final fields = tester.widgetList<TextField>(find.byType(TextField)).toList();
    expect(fields, hasLength(2));
    expect(fields[0].autofillHints, contains(AutofillHints.email));
    expect(fields[0].textInputAction, TextInputAction.next);
    expect(fields[1].autofillHints, contains(AutofillHints.password));
    expect(fields[1].textInputAction, TextInputAction.done);
    expect(fields[1].onSubmitted, isNotNull);
    expect(
      find.ancestor(
        of: find.byType(TextFormField).first,
        matching: find.byType(AutofillGroup),
      ),
      findsOneWidget,
    );

    await tester.tap(find.byType(TextFormField).at(1));
    await tester.pump();
    await tester.testTextInput.receiveAction(TextInputAction.done);
    await tester.pump();

    expect(find.text('Please fill in all fields'), findsOneWidget);
  });

  testWidgets('save-password tap target is at least 44 px', (tester) async {
    await pumpLogin(tester);

    final target = find.ancestor(
      of: find.text('Save Password'),
      matching: find.byType(InkWell),
    );
    expect(target, findsOneWidget);
    expect(tester.getSize(target).height, greaterThanOrEqualTo(44));

    final forgot = find.widgetWithText(TextButton, 'Forgot password?');
    expect(tester.getSize(forgot).height, greaterThanOrEqualTo(44));
  });

  testWidgets('dutch login row does not overflow on a narrow phone', (
    tester,
  ) async {
    await pumpLogin(
      tester,
      locale: const Locale('nl'),
      surface: const Size(320, 640),
    );
    expect(tester.takeException(), isNull);
    expect(find.text('Wachtwoord opslaan'), findsOneWidget);
    expect(find.text('Wachtwoord vergeten?'), findsOneWidget);
  });

  testWidgets('empty reset stays on the screen', (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        locale: const Locale('en'),
        supportedLocales: AppLocalizations.supportedLocales,
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        home: const ForgotPasswordScreen(),
      ),
    );
    await tester.pump();

    await tester.tap(find.text('Reset Password'));
    await tester.pump();

    expect(find.text('Please enter your email'), findsOneWidget);
    expect(find.text('Reset Password'), findsOneWidget);
  });

  testWidgets('failed reset keeps the email and stays on the screen', (
    tester,
  ) async {
    await tester.pumpWidget(
      MaterialApp(
        locale: const Locale('en'),
        supportedLocales: AppLocalizations.supportedLocales,
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        home: const ForgotPasswordScreen(),
      ),
    );
    await tester.pump();

    await tester.enterText(find.byType(TextFormField), 'person@example.com');
    await tester.tap(find.text('Reset Password'));
    await tester.pump();
    await tester.pump(const Duration(seconds: 1));

    expect(find.text('Forgot Password?'), findsOneWidget);
    expect(find.text('person@example.com'), findsOneWidget);
    expect(find.text('Password reset link sent. Check your email.'), findsNothing);
  });

  testWidgets('successful reset pops and leaves the confirmation on login', (
    tester,
  ) async {
    await tester.pumpWidget(
      MaterialApp(
        locale: const Locale('en'),
        supportedLocales: AppLocalizations.supportedLocales,
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        home: Builder(
          builder: (context) {
            return Scaffold(
              body: TextButton(
                onPressed: () {
                  Navigator.of(context).push(
                    MaterialPageRoute<void>(
                      builder: (_) => ForgotPasswordScreen(
                        resetPassword: ({required String email}) async {},
                      ),
                    ),
                  );
                },
                child: const Text('Welcome back'),
              ),
            );
          },
        ),
      ),
    );

    await tester.tap(find.text('Welcome back'));
    await tester.pumpAndSettle();
    await tester.enterText(find.byType(TextFormField), 'person@example.com');
    await tester.tap(find.text('Reset Password'));
    await tester.pumpAndSettle();

    expect(find.text('Welcome back'), findsOneWidget);
    expect(find.text('Forgot Password?'), findsNothing);
    expect(
      find.text('Password reset link sent. Check your email.'),
      findsOneWidget,
    );
  });
}
