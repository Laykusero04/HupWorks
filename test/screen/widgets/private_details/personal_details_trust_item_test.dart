import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:freelancer/core/constants/colors.dart';
import 'package:freelancer/data/models/user_private_details.dart';
import 'package:freelancer/l10n/app_localizations.dart';
import 'package:freelancer/screen/widgets/private_details/personal_details_trust_item.dart';
import 'package:freelancer/services/personal_details_gate.dart';

import '../../../support/pd_harness.dart';

/// T-0172: "Personal details" shown as an unfinished trust item when missing.
void main() {
  setUpAll(pdSetUp);

  final en = lookupAppLocalizations(const Locale('en'));
  final nl = lookupAppLocalizations(const Locale('nl'));

  UserPrivateDetails complete() => UserPrivateDetails(
        userId: 'u',
        dateOfBirth: DateTime(1990, 5, 7),
        consentVersion: 'privacy-2026-11',
        consentedAt: DateTime.utc(2026, 11, 20),
      );

  Widget item(Future<UserPrivateDetails?> Function() loader,
          {Future<void> Function(BuildContext)? onOpen,
          Color accent = kPrimaryColor}) =>
      Scaffold(
        body: Padding(
          padding: const EdgeInsets.all(20),
          child: PersonalDetailsTrustItem(
              accent: accent, loader: loader, onOpen: onOpen),
        ),
      );

  testWidgets('no row yet: unfinished item with a link', (t) async {
    await pdPump(t, item(() async => null));
    expect(find.text(en.pdTrustTitle), findsOneWidget);
    expect(find.text(en.pdTrustMissing), findsOneWidget);
    expect(find.text(en.pdTrustAdd), findsOneWidget);
    expect(find.byIcon(Icons.radio_button_unchecked), findsOneWidget);
  });

  testWidgets('DOB without consent is still unfinished', (t) async {
    await pdPump(
        t,
        item(() async => UserPrivateDetails(
            userId: 'u', dateOfBirth: DateTime(1990, 5, 7))));
    expect(find.text(en.pdTrustMissing), findsOneWidget);
  });

  testWidgets('older consent version is unfinished', (t) async {
    await pdPump(
        t,
        item(() async => UserPrivateDetails(
              userId: 'u',
              dateOfBirth: DateTime(1990, 5, 7),
              consentVersion: 'privacy-2025-01',
              consentedAt: DateTime.utc(2025, 1, 1),
            )));
    expect(find.text(en.pdTrustMissing), findsOneWidget);
  });

  testWidgets('complete: shown as done, no add link', (t) async {
    await pdPump(t, item(() async => complete()));
    expect(find.text(en.pdTrustDone), findsOneWidget);
    expect(find.text(en.pdTrustAdd), findsNothing);
    expect(find.byIcon(Icons.check_circle_rounded), findsOneWidget);
  });

  testWidgets('read failure shows nothing (does not claim "missing")',
      (t) async {
    await pdPump(t, item(() async => throw Exception('offline')));
    expect(find.text(en.pdTrustTitle), findsNothing);
  });

  testWidgets('tap opens the screen and reloads afterwards', (t) async {
    var loads = 0;
    var opens = 0;
    UserPrivateDetails? current;
    await pdPump(
      t,
      item(() async {
        loads++;
        return current;
      }, onOpen: (_) async {
        opens++;
        current = complete(); // user filled it in on the other screen
      }),
    );
    expect(find.text(en.pdTrustMissing), findsOneWidget);
    await t.tap(find.byKey(const ValueKey('personal-details-trust-item')));
    await t.pump();
    await t.pump();
    expect(opens, 1);
    expect(loads, 2);
    expect(find.text(en.pdTrustDone), findsOneWidget);
  });

  for (final role in ['client', 'seller']) {
    for (final done in [false, true]) {
      testWidgets('NL x2.0 on 375pt ($role, done=$done): no overflow',
          (t) async {
        await pdPump(
          t,
          item(() async => done ? complete() : null,
              accent: role == 'seller' ? kSellerPrimary : kPrimaryColor),
          locale: const Locale('nl'),
          scale: 2.0,
        );
        expect(find.text(nl.pdTrustTitle), findsOneWidget);
        expect(t.takeException(), isNull);
      });
    }
  }

  test('pending signup DOB is never flushed for a different email', () async {
    PendingSignupDob.hold('a@example.invalid', DateTime(1990, 1, 1));
    expect(PendingSignupDob.hasPending, isTrue);
    expect(await PendingSignupDob.flushFor(null), isFalse);
    expect(await PendingSignupDob.flushFor('b@example.invalid'), isFalse);
    expect(PendingSignupDob.hasPending, isTrue);
    PendingSignupDob.clear();
    expect(PendingSignupDob.hasPending, isFalse);
  });
}
