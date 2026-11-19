import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:freelancer/l10n/app_localizations.dart';
import 'package:freelancer/screen/client%20screen/client%20talent/freelancer_public_profile.dart';

import '../../../support/qa_supabase.dart';

/// T-0121/T-0128 QA: another user's public profile must show "Location" with
/// city and country only, never a street address, and show age only when the
/// server returns age_years (the freelancer opted in).
///
/// The mocked seller row deliberately includes a street address in both the
/// top-level and seller_profiles fields. The screen must still not render it.
const _street = '1 Secret Street';

Map<String, Object?> _sellerRow() => {
      'id': qaSellerId,
      'role': 'seller',
      'name': 'Alex Tester',
      'profile_image_url': null,
      'bio': null,
      'rating': 0,
      'created_at': '2026-01-01T00:00:00Z',
      'country': 'NL',
      'city': 'Leiden',
      'address': _street,
      'verification_status': null,
      'profile_photo_status': null,
      'seller_profiles': {
        'job_title': 'Courier',
        'about': 'QA test seller',
        'skills': <Object?>[],
        'languages': <Object?>[],
        'education': null,
        'experience': null,
        'show_age': false,
        'address': _street,
      },
    };

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  final tables = <String, QaHandler>{};
  Object? ageRow;

  setUpAll(() async {
    tables['profiles'] = (_) => _sellerRow();
    tables['seller_public_age'] = (_) => ageRow;
    tables['reviews'] = (_) => <Object?>[];
    await initQaSupabase(tables: tables);
  });

  Future<List<Object>> pumpProfile(WidgetTester tester,
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
      home: const FreelancerPublicProfile(sellerId: qaSellerId),
    ));
    drain();
    for (var i = 0; i < 200 && find.text('Alex Tester').evaluate().isEmpty; i++) {
      await tester.runAsync(
          () => Future<void>.delayed(const Duration(milliseconds: 5)));
      await tester.pump();
      drain();
    }
    await tester.pump(const Duration(seconds: 1));
    drain();
    return errors;
  }

  Future<void> tearDownProfile(WidgetTester tester) async {
    await tester.pumpWidget(const SizedBox.shrink());
    await tester.pump(const Duration(seconds: 1));
  }

  testWidgets('shows Location as city, country (EN) and never a street address',
      (tester) async {
    ageRow = null;
    final errors = await pumpProfile(tester);
    expect(errors, isEmpty);
    expect(find.text('Alex Tester'), findsWidgets);
    expect(find.text('Leiden, NL'), findsWidgets);
    expect(find.text('Location'), findsOneWidget,
        reason: 'the detail row label is Location, not Address');
    expect(find.text('Address'), findsNothing);
    expect(find.textContaining('Secret'), findsNothing);
    expect(find.textContaining(_street), findsNothing);
    await tearDownProfile(tester);
  });

  testWidgets('age is hidden when the freelancer has not opted in',
      (tester) async {
    ageRow = null;
    await pumpProfile(tester);
    expect(find.textContaining('years old'), findsNothing);
    await tearDownProfile(tester);
  });

  testWidgets('age shows only when the server returns age_years',
      (tester) async {
    ageRow = {'age_years': 34};
    final errors = await pumpProfile(tester);
    expect(errors, isEmpty);
    expect(find.text('34 years old'), findsOneWidget);
    expect(find.textContaining(_street), findsNothing);
    await tearDownProfile(tester);
  });

  testWidgets('NL at XL text scale (1.5): Locatie row, no street, no overflow',
      (tester) async {
    ageRow = null;
    final errors = await pumpProfile(tester,
        locale: const Locale('nl'), textScale: 1.5);
    expect(errors, isEmpty, reason: 'overflow or build errors at NL XL');
    expect(find.text('Leiden, NL'), findsWidgets);
    expect(find.text('Locatie'), findsOneWidget);
    expect(find.text('Adres'), findsNothing);
    expect(find.textContaining(_street), findsNothing);
    await tearDownProfile(tester);
  });

  testWidgets('EN at XL text scale (1.5): Location row, no street, no overflow',
      (tester) async {
    ageRow = null;
    final errors = await pumpProfile(tester, textScale: 1.5);
    expect(errors, isEmpty, reason: 'overflow or build errors at EN XL');
    expect(find.text('Location'), findsOneWidget);
    expect(find.text('Leiden, NL'), findsWidgets);
    expect(find.textContaining(_street), findsNothing);
    await tearDownProfile(tester);
  });
}
