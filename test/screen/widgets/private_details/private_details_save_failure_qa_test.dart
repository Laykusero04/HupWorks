import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:freelancer/core/constants/colors.dart';
import 'package:freelancer/data/models/user_private_details.dart';
import 'package:freelancer/l10n/app_localizations.dart';
import 'package:freelancer/screen/widgets/private_details/personal_details_trust_item.dart';
import 'package:freelancer/screen/widgets/private_details/private_details_section.dart';

import '../../../support/pd_harness.dart';

/// T-0172 QA: a failed profile-edit save keeps everything the user typed, a
/// retry works, and the trust item shows "done" after the details are saved.
/// Fake data only, no network.
void main() {
  setUpAll(pdSetUp);

  final en = lookupAppLocalizations(const Locale('en'));
  final today = DateTime.utc(2026, 11, 20, 12);

  Future<void> guarded(Future<void> Function() body) {
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

  testWidgets('failed save keeps typed values; retry saves them', (t) => guarded(() async {
        final key = GlobalKey<PrivateDetailsSectionState>();
        var failNext = true;
        final saved = <Object?>[];
        await pdPump(
          t,
          Scaffold(
            body: SingleChildScrollView(
              padding: const EdgeInsets.all(20),
              child: PrivateDetailsSection(
                key: key,
                accent: kPrimaryColor,
                now: today,
                loader: () async => null,
                launcher: (_) async => true,
                saver: ({legalName, dateOfBirth, streetAddress, postalCode,
                    consentVersion, required clear}) async {
                  if (failNext) {
                    failNext = false;
                    throw Exception('SECRET-RAW-VALUE');
                  }
                  saved.add(legalName);
                },
              ),
            ),
          ),
        );

        await t.enterText(find.byType(TextField).at(0), '07');
        await t.enterText(find.byType(TextField).at(1), '05');
        await t.enterText(find.byType(TextField).at(2), '1990');
        await t.enterText(find.byType(TextField).at(3), 'Piet Jansen');
        await t.enterText(find.byType(TextField).at(4), 'Dorpsstraat 1');
        await t.enterText(find.byType(TextField).at(5), '1234ab');
        await t.ensureVisible(find.byType(Checkbox));
        await t.tap(find.byType(Checkbox));
        await t.pump();

        expect(await key.currentState!.save(), isFalse);
        await t.pump();

        // Error is shown, raw exception text is not.
        expect(find.text(en.pdSaveError), findsOneWidget);
        expect(find.textContaining(en.pdSaveError.split('.').first),
            findsWidgets);
        expect(find.textContaining('SECRET-RAW-VALUE'), findsNothing);

        // Everything typed is still there.
        expect(t.widget<TextField>(find.byType(TextField).at(0)).controller!.text,
            '07');
        expect(t.widget<TextField>(find.byType(TextField).at(2)).controller!.text,
            '1990');
        expect(t.widget<TextField>(find.byType(TextField).at(3)).controller!.text,
            'Piet Jansen');
        expect(t.widget<TextField>(find.byType(TextField).at(4)).controller!.text,
            'Dorpsstraat 1');
        expect(t.widget<TextField>(find.byType(TextField).at(5)).controller!.text,
            '1234ab');
        expect(t.takeException(), isNull);

        // Retry with the same input succeeds and the name is written once.
        expect(await key.currentState!.save(), isTrue);
        expect(saved, ['Piet Jansen']);
      }));

  testWidgets('trust item shows done (not missing) after the details are saved',
      (t) => guarded(() async {
        UserPrivateDetails? current;
        await pdPump(
          t,
          Scaffold(
            body: Padding(
              padding: const EdgeInsets.all(20),
              child: PersonalDetailsTrustItem(
                accent: kPrimaryColor,
                loader: () async => current,
                onOpen: (_) async {
                  current = UserPrivateDetails(
                    userId: 'u',
                    dateOfBirth: DateTime(1990, 5, 7),
                    consentVersion: 'privacy-2026-11',
                    consentedAt: DateTime.utc(2026, 11, 20),
                  );
                },
              ),
            ),
          ),
        );
        expect(find.text(en.pdTrustMissing), findsOneWidget);
        await t.tap(find.byKey(const ValueKey('personal-details-trust-item')));
        await t.pump();
        await t.pump();
        // The unfinished text and "add" link are gone; the item stays as "done".
        expect(find.text(en.pdTrustMissing), findsNothing);
        expect(find.text(en.pdTrustAdd), findsNothing);
        expect(find.text(en.pdTrustDone), findsOneWidget);
        expect(t.takeException(), isNull);
      }));
}
