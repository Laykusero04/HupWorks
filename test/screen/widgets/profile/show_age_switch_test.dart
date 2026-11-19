import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:freelancer/l10n/app_localizations.dart';
import 'package:freelancer/screen/seller%20screen/profile/seller_edit_profile_details.dart';
import 'package:freelancer/services/profile_service.dart';

import '../../../support/qa_supabase.dart';

/// T-0121/T-0128 QA: the "Show my age on my profile" switch on the seller edit
/// screen must default to OFF, follow the saved value, and stay disabled until
/// a birth date exists. Runs the real screen against a mocked Supabase.
///
/// Known defect found by this QA (see the last group): the SwitchListTile sits
/// inside the screen's white DecoratedBox body, and Flutter's debug assertion
/// "ListTile background color or ink splashes may be invisible" fires on every
/// build. The value tests drain that assertion so they check the switch state
/// itself; the defect has its own test that fails until it is fixed.
void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  // Mutable so each test can change what the backend returns.
  final tables = <String, QaHandler>{};

  setUpAll(() async {
    tables.addAll(sellerEditTables(dateOfBirth: '1990-05-17'));
    await initQaSupabase(tables: tables, signedIn: true);
  });

  bool isListTileMaterialAssertion(Object e) =>
      e.toString().contains('ListTile background color or ink splashes');

  /// Pumps the edit screen and returns every framework exception it raised.
  Future<List<Object>> pumpEditScreen(WidgetTester tester,
      {Locale locale = const Locale('en'), double textScale = 1.0}) async {
    tester.view.physicalSize = const Size(1000, 2400);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    final errors = <Object>[];
    void drain() {
      final e = tester.takeException();
      if (e != null) errors.add(e);
    }

    await tester.pumpWidget(MaterialApp(
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      locale: locale,
      builder: (context, child) => MediaQuery(
        data: MediaQuery.of(context)
            .copyWith(textScaler: TextScaler.linear(textScale)),
        child: child!,
      ),
      home: const SellerEditProfile(),
    ));
    drain();
    // Supabase answers on the real event loop, so wait with runAsync.
    for (var i = 0;
        i < 200 && find.byType(SwitchListTile).evaluate().isEmpty;
        i++) {
      await tester.runAsync(
          () => Future<void>.delayed(const Duration(milliseconds: 5)));
      await tester.pump();
      drain();
    }
    // Let the loader's fake-async timers finish so none are left pending.
    await tester.pump(const Duration(seconds: 1));
    drain();
    return errors;
  }

  SwitchListTile ageSwitch(WidgetTester tester) =>
      tester.widget<SwitchListTile>(find.byType(SwitchListTile));

  Future<void> tearDownScreen(WidgetTester tester) async {
    await tester.pumpWidget(const SizedBox.shrink());
    await tester.pump(const Duration(seconds: 1));
  }

  group('show-age switch state', () {
    testWidgets('default is OFF when show_age is not set in the database',
        (tester) async {
      tables
        ..clear()
        ..addAll(sellerEditTables(dateOfBirth: '1990-05-17', showAge: null));
      final errors = await pumpEditScreen(tester);
      expect(errors.where((e) => !isListTileMaterialAssertion(e)), isEmpty);
      expect(find.byType(SwitchListTile), findsOneWidget);
      expect(find.text('Show my age on my profile'), findsOneWidget);
      expect(ageSwitch(tester).value, isFalse);
      expect(ageSwitch(tester).onChanged, isNotNull,
          reason: 'enabled once a birth date is set');
      await tearDownScreen(tester);
    });

    testWidgets('reflects show_age = false from the database as OFF',
        (tester) async {
      tables
        ..clear()
        ..addAll(sellerEditTables(dateOfBirth: '1990-05-17', showAge: false));
      await pumpEditScreen(tester);
      expect(ageSwitch(tester).value, isFalse);
      await tearDownScreen(tester);
    });

    testWidgets('reflects show_age = true from the database as ON',
        (tester) async {
      tables
        ..clear()
        ..addAll(sellerEditTables(dateOfBirth: '1990-05-17', showAge: true));
      await pumpEditScreen(tester);
      expect(ageSwitch(tester).value, isTrue);
      await tearDownScreen(tester);
    });

    testWidgets('switch is disabled while no birth date is set',
        (tester) async {
      tables
        ..clear()
        ..addAll(sellerEditTables(dateOfBirth: null, showAge: null));
      await pumpEditScreen(tester);
      expect(ageSwitch(tester).value, isFalse);
      expect(ageSwitch(tester).onChanged, isNull);
      await tearDownScreen(tester);
    });

    testWidgets('XL text scale (1.5) with NL: switch row renders without overflow',
        (tester) async {
      tables
        ..clear()
        ..addAll(sellerEditTables(dateOfBirth: '1990-05-17', showAge: null));
      final errors = await pumpEditScreen(tester,
          locale: const Locale('nl'), textScale: 1.5);
      expect(errors.where((e) => !isListTileMaterialAssertion(e)), isEmpty);
      expect(find.text('Toon mijn leeftijd op mijn profiel'), findsOneWidget);
      expect(ageSwitch(tester).value, isFalse);
      await tearDownScreen(tester);
    });
  });

  group('XL text scale (1.5) checklist', () {
    testWidgets('EN: switch row renders without overflow', (tester) async {
      tables
        ..clear()
        ..addAll(sellerEditTables(dateOfBirth: '1990-05-17', showAge: null));
      final errors = await pumpEditScreen(tester, textScale: 1.5);
      expect(errors.where((e) => !isListTileMaterialAssertion(e)), isEmpty);
      expect(find.text('Show my age on my profile'), findsOneWidget);
      expect(ageSwitch(tester).value, isFalse);
      await tearDownScreen(tester);
    });
  });

  group('known defect: switch inside decorated body', () {
    testWidgets(
        'SwitchListTile has a Material ancestor (no ListTile debug assertion)',
        (tester) async {
      tables
        ..clear()
        ..addAll(sellerEditTables(dateOfBirth: '1990-05-17', showAge: null));
      final errors = await pumpEditScreen(tester);
      expect(errors.where(isListTileMaterialAssertion), isEmpty,
          reason: 'SwitchListTile is inside a DecoratedBox with a background '
              'colour (SellerEditProfile body). Wrap it in a Material or use a '
              'Row with Switch.adaptive.');
      await tearDownScreen(tester);
    });
  });

  test('service default (no profile value) is off', () {
    expect(ProfileService.sellerShowAgeFromProfile({}), isFalse);
    expect(
        ProfileService.sellerShowAgeFromProfile({
          'seller_profiles': {'job_title': 'x'}
        }),
        isFalse);
  });
}
