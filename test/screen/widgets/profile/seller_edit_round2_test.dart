import 'dart:async';
import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:freelancer/core/constants/colors.dart';
import 'package:freelancer/l10n/app_localizations.dart';
import 'package:freelancer/screen/seller%20screen/profile/seller_edit_profile_details.dart';
import 'package:freelancer/screen/widgets/editable_profile_avatar.dart';

import '../../../support/qa_supabase.dart';

/// T-0172 fix round 2 (H1): the seller Edit profile screen has ONE date of
/// birth (the private section), prefilled from the old table when the new one
/// has none, drives the show-age switch, never writes the old table, and uses
/// the seller role colour. Mocked Supabase, fake data.
/// Runs [body] in a zone that drops only google_fonts load errors (Inter and
/// Jost cannot load in tests).
Future<void> runGuarded(Future<void> Function() body) {
  final done = Completer<void>();
  runZonedGuarded(() async {
    try {
      await body();
      if (!done.isCompleted) done.complete();
    } catch (e, s) {
      if (!done.isCompleted) done.completeError(e, s);
    }
  }, (error, stack) {
    if (error.toString().contains('google_fonts') ||
        error.toString().contains('allowRuntimeFetching')) {
      return;
    }
    if (!done.isCompleted) done.completeError(error, stack);
  });
  return done.future;
}

void gTest(String name, Future<void> Function(WidgetTester) body) =>
    testWidgets(name, (t) => runGuarded(() => body(t)));

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  final tables = <String, QaHandler>{};
  final calls = <String>[]; // "METHOD table"
  final bodies = <String, List<Object?>>{};

  QaHandler recording(String name, QaHandler inner) => (req) {
        calls.add('${req.method} $name');
        if (req.method != 'GET' && req.body.isNotEmpty) {
          (bodies[name] ??= []).add(jsonDecode(req.body));
        }
        return req.method == 'GET' ? inner(req) : null;
      };

  void setTables({
    String? oldDob = '1990-05-17',
    bool showAge = false,
    Map<String, Object?>? newRow,
    String? oldStreet,
  }) {
    final base = sellerEditTables(dateOfBirth: oldDob, showAge: showAge);
    tables
      ..clear()
      ..addAll({
        for (final e in base.entries) e.key: recording(e.key, e.value),
        'seller_private_details': recording(
            'seller_private_details',
            (_) => {
                  'user_id': qaSignedInUserId,
                  'date_of_birth': oldDob,
                  'street_address': oldStreet,
                  'state': null,
                  'postal_code': null,
                }),
        'profiles': recording('profiles', (_) => null),
        'seller_profiles': recording('seller_profiles', (_) => null),
        'user_private_details': recording(
            'user_private_details',
            (_) => newRow == null
                ? null
                : {...newRow, 'user_id': qaSignedInUserId}),
      });
    calls.clear();
    bodies.clear();
  }

  setUpAll(() async {
    setTables();
    await initQaSupabase(tables: tables, signedIn: true);
  });

  final en = lookupAppLocalizations(const Locale('en'));
  final nl = lookupAppLocalizations(const Locale('nl'));

  Future<void> pump(WidgetTester t,
      {Locale locale = const Locale('en'), double scale = 1.0}) async {
    t.view.physicalSize = const Size(375, 2400);
    t.view.devicePixelRatio = 1.0;
    addTearDown(t.view.resetPhysicalSize);
    addTearDown(t.view.resetDevicePixelRatio);
    void drain() {
      final e = t.takeException();
      if (e != null && !e.toString().contains('google_fonts')) throw e;
    }

    await t.pumpWidget(MaterialApp(
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      locale: locale,
      builder: (c, w) => MediaQuery(
        data: MediaQuery.of(c).copyWith(textScaler: TextScaler.linear(scale)),
        child: w!,
      ),
      home: const SellerEditProfile(),
    ));
    for (var i = 0;
        i < 200 && find.byType(SwitchListTile).evaluate().isEmpty;
        i++) {
      await t.runAsync(
          () => Future<void>.delayed(const Duration(milliseconds: 5)));
      await t.pump();
    }
    // let the section load too
    for (var i = 0; i < 20; i++) {
      await t.runAsync(
          () => Future<void>.delayed(const Duration(milliseconds: 5)));
      await t.pump();
    }
    await t.pump(const Duration(seconds: 1));
    drain();
  }

  Future<void> tearDown(WidgetTester t) async {
    await t.pumpWidget(const SizedBox.shrink());
    await t.pump(const Duration(seconds: 1));
  }

  SwitchListTile ageSwitch(WidgetTester t) =>
      t.widget<SwitchListTile>(find.byType(SwitchListTile));

  gTest('one date of birth only: no old picker, one Day/Month/Year group',
      (t) async {
    setTables();
    await pump(t);
    expect(find.text(en.pdDobLabel), findsOneWidget);
    expect(find.text(en.tapSetBirthDate), findsNothing);
    expect(find.text(en.ageHiddenOnProfile(35)), findsNothing);
    expect(find.text(en.address), findsNothing); // old address field retired
    expect(find.text(en.pdSectionTitle), findsOneWidget);
    await tearDown(t);
  });

  gTest('old DOB prefills the private section (read-only fallback)', (t) async {
    setTables(oldDob: '1990-05-17', oldStreet: 'Oude Straat 1');
    await pump(t);
    expect(find.text('17'), findsOneWidget);
    expect(find.text('05'), findsOneWidget);
    expect(find.text('1990'), findsOneWidget);
    expect(find.text('Oude Straat 1'), findsOneWidget);
    expect(ageSwitch(t).onChanged, isNotNull);
    await tearDown(t);
  });

  gTest('new DOB wins over the old value', (t) async {
    setTables(oldDob: '1990-05-17', newRow: {'date_of_birth': '1999-12-31'});
    await pump(t);
    expect(find.text('1999'), findsOneWidget);
    expect(find.text('1990'), findsNothing);
    await tearDown(t);
  });

  gTest('switch disabled when there is no DOB anywhere', (t) async {
    setTables(oldDob: null);
    await pump(t);
    expect(ageSwitch(t).value, isFalse);
    expect(ageSwitch(t).onChanged, isNull);
    await tearDown(t);
  });

  gTest('switch copy says only the age is shown', (t) async {
    setTables();
    await pump(t);
    expect(find.text(en.showAgeOnProfileHint), findsOneWidget);
    expect(en.showAgeOnProfileHint, contains('never your date of birth'));
    expect(nl.showAgeOnProfileHint, contains('nooit je geboortedatum'));
    await tearDown(t);
  });

  gTest('typing an under-16 date turns the switch off and disables it',
      (t) async {
    setTables(showAge: true);
    await pump(t);
    expect(ageSwitch(t).value, isTrue);
    final f = find.byType(TextField);
    // Day / Month / Year boxes are the last three plain fields before postal etc.
    final day = find
        .byWidgetPredicate((w) => w is TextField && w.controller?.text == '17');
    await t.enterText(day, '21');
    await t.enterText(
        find.byWidgetPredicate(
            (w) => w is TextField && w.controller?.text == '05'),
        '11');
    await t.enterText(
        find.byWidgetPredicate(
            (w) => w is TextField && w.controller?.text == '1990'),
        '2010');
    await t.pump();
    expect(f, findsWidgets);
    expect(ageSwitch(t).value, isFalse);
    expect(ageSwitch(t).onChanged, isNull);
    await tearDown(t);
  });

  gTest('seller role colour (teal), not orange', (t) async {
    setTables();
    await pump(t);
    final avatar =
        t.widget<EditableProfileAvatar>(find.byType(EditableProfileAvatar));
    expect(avatar.accent, kSellerPrimary);
    // Update button fill
    final button = find
        .ancestor(
            of: find.text(en.updateProfile), matching: find.byType(Container))
        .first;
    final deco = t.widget<Container>(button).decoration as BoxDecoration?;
    expect(deco?.color, isNot(kPrimaryFill));
    expect(deco?.color, kSecondaryFill);
    await tearDown(t);
  });

  gTest('app bar does not tint orange/pink when scrolled (M3 surface tint)',
      (t) async {
    setTables();
    await pump(t);
    final bar = t.widget<AppBar>(find.byType(AppBar));
    expect(bar.surfaceTintColor, Colors.transparent);
    expect(bar.scrolledUnderElevation, 0);
    await tearDown(t);
  });

  gTest('saving does not touch the old seller_private_details table',
      (t) async {
    setTables(showAge: true);
    await pump(t);
    await t.ensureVisible(find.text(en.updateProfile));
    await t.tap(find.text(en.updateProfile));
    await t.pump();
    for (var i = 0; i < 20; i++) {
      await t.runAsync(
          () => Future<void>.delayed(const Duration(milliseconds: 5)));
      await t.pump();
    }
    expect(
        calls.where((c) =>
            c.endsWith('seller_private_details') &&
            c != 'GET seller_private_details'),
        isEmpty,
        reason: 'old table must not be written (would wipe the old DOB)');
    expect(calls.any((c) => c.startsWith('PATCH seller_profiles')), isTrue);
    final sp = bodies['seller_profiles']!.last as Map;
    expect(sp['show_age'], isTrue);
    // unchanged prefilled values are not copied into the new table either
    expect(
        calls.where((c) => c.startsWith('POST user_private_details')), isEmpty);
    await tearDown(t);
  });

  gTest('NL x2.0 on 375pt: no overflow', (t) async {
    setTables(oldStreet: 'Oude Straat 1');
    await pump(t, locale: const Locale('nl'), scale: 2.0);
    expect(t.takeException(), isNull);
    await tearDown(t);
  });
}
