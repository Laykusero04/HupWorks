import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:freelancer/core/utils/terms_link.dart';
import 'package:freelancer/l10n/app_localizations.dart';
import 'package:freelancer/screen/app_config/app_config.dart';
import 'package:url_launcher_platform_interface/link.dart';
import 'package:url_launcher_platform_interface/url_launcher_platform_interface.dart';

/// T-0162 edge cases (QA): launch mode and failure paths of the Terms opener.
/// Uses a fake UrlLauncherPlatform, so no browser is started.
class _FakeUrlLauncher extends UrlLauncherPlatform {
  final calls = <({String url, LaunchOptions options})>[];
  bool result = true;
  Object? throwError;

  @override
  LinkDelegate? get linkDelegate => null;

  @override
  Future<bool> launchUrl(String url, LaunchOptions options) async {
    calls.add((url: url, options: options));
    if (throwError != null) throw throwError!;
    return result;
  }
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late _FakeUrlLauncher fake;
  late UrlLauncherPlatform previous;

  setUp(() {
    previous = UrlLauncherPlatform.instance;
    fake = _FakeUrlLauncher();
    UrlLauncherPlatform.instance = fake;
  });

  tearDown(() {
    UrlLauncherPlatform.instance = previous;
  });

  test('URL constant is https and has no query or fragment', () {
    final u = Uri.parse(AppInfo.termsUrl);
    expect(u.scheme, 'https');
    expect(u.host, 'hupworks-web.vercel.app');
    expect(u.path, '/terms.html');
    expect(u.hasQuery, isFalse);
    expect(u.hasFragment, isFalse);
  });

  test('default launcher opens the terms URL in an external application',
      () async {
    final ok = await defaultTermsLauncher(Uri.parse(AppInfo.termsUrl));
    expect(ok, isTrue);
    expect(fake.calls, hasLength(1));
    expect(fake.calls.single.url, AppInfo.termsUrl);
    expect(fake.calls.single.options.mode,
        PreferredLaunchMode.externalApplication);
  });

  test('default launcher reports false when the platform cannot open it',
      () async {
    fake.result = false;
    final ok = await defaultTermsLauncher(Uri.parse(AppInfo.termsUrl));
    expect(ok, isFalse);
    expect(fake.calls.single.options.mode,
        PreferredLaunchMode.externalApplication);
  });

  Future<void> tapOpen(
    WidgetTester t, {
    TermsLauncher? launcher,
    Locale locale = const Locale('en'),
  }) async {
    await t.pumpWidget(MaterialApp(
      locale: locale,
      supportedLocales: AppLocalizations.supportedLocales,
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      home: Scaffold(
        body: Builder(
          builder: (context) => TextButton(
            onPressed: () => openTermsOfService(context,
                launcher: launcher ?? defaultTermsLauncher),
            child: const Text('open'),
          ),
        ),
      ),
    ));
    await t.tap(find.text('open'));
    await t.pump();
    await t.pump(const Duration(milliseconds: 300));
  }

  testWidgets('no snackbar when the platform opens the page (default launcher)',
      (t) async {
    await tapOpen(t);
    expect(fake.calls, hasLength(1));
    expect(fake.calls.single.url, AppInfo.termsUrl);
    expect(find.byType(SnackBar), findsNothing);
  });

  testWidgets('default launcher false -> snackbar (EN)', (t) async {
    fake.result = false;
    await tapOpen(t);
    expect(
        find.text(
            lookupAppLocalizations(const Locale('en')).authTermsOpenFailed),
        findsOneWidget);
  });

  testWidgets('PlatformException from the platform -> snackbar, no crash',
      (t) async {
    fake.throwError = PlatformException(code: 'ACTIVITY_NOT_FOUND');
    await tapOpen(t, locale: const Locale('nl'));
    expect(t.takeException(), isNull);
    expect(
        find.text(
            lookupAppLocalizations(const Locale('nl')).authTermsOpenFailed),
        findsOneWidget);
  });

  testWidgets('custom launcher returning true -> no snackbar, exact URI',
      (t) async {
    final seen = <Uri>[];
    await tapOpen(t, launcher: (u) async {
      seen.add(u);
      return true;
    });
    expect(seen, [Uri.parse(AppInfo.termsUrl)]);
    expect(fake.calls, isEmpty, reason: 'custom launcher replaces platform');
    expect(find.byType(SnackBar), findsNothing);
  });

  testWidgets('custom launcher that throws -> snackbar', (t) async {
    await tapOpen(t, launcher: (_) async => throw StateError('boom'));
    expect(t.takeException(), isNull);
    expect(
        find.text(
            lookupAppLocalizations(const Locale('en')).authTermsOpenFailed),
        findsOneWidget);
  });
}
