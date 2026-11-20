import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:freelancer/core/constants/colors.dart';
import 'package:freelancer/data/models/user_private_details.dart';
import 'package:freelancer/l10n/app_localizations.dart';
import 'package:freelancer/screen/app_config/app_config.dart';
import 'package:freelancer/screen/widgets/auth/sign_up_screen.dart';
import 'package:freelancer/screen/widgets/private_details/dob_field.dart';
import 'package:freelancer/screen/widgets/private_details/personal_details_screen.dart';
import 'package:freelancer/screen/widgets/private_details/personal_details_trust_item.dart';
import 'package:freelancer/screen/widgets/private_details/private_details_section.dart';

import '../../../support/pd_harness.dart';

/// T-0172 visual checklist (large UI), as far as widget tests can check it:
/// signup form, first-sign-in screen, profile section and trust item, in EN and
/// NL at text scale 1.0 / 1.5 / 2.0 on 375x667, for client (orange) and seller
/// (teal). Checks: no render or overflow exception, and the primary control
/// is on screen. It does NOT check colour contrast, pixel layout or device
/// behaviour; those stay UNVERIFIED (see the QA report).
void main() {
  setUpAll(pdSetUp);

  // Completed row, so the trust item shows its "done" variant.
  final stored = UserPrivateDetails(
    userId: 'u',
    legalName: 'Jan Jansen',
    dateOfBirth: DateTime(1990, 5, 7),
    streetAddress: 'Dorpsstraat 1',
    postalCode: '1234 AB',
    consentVersion: 'privacy-2026-11',
    consentedAt: DateTime.utc(2026, 11, 20, 10),
  );

  Future<void> guarded(WidgetTester t, Future<void> Function() body) {
    final done = Completer<void>();
    runZonedGuarded(() async {
      try {
        await body();
        if (!done.isCompleted) done.complete();
      } catch (e, s) {
        if (!done.isCompleted) done.completeError(e, s);
      }
    }, (error, stack) {
      // google_fonts cannot load Inter/Jost in tests; drop only those errors.
      if (error.toString().contains('google_fonts') ||
          error.toString().contains('allowRuntimeFetching')) {
        return;
      }
      if (!done.isCompleted) done.completeError(error, stack);
    });
    return done.future;
  }

  for (final lang in ['en', 'nl']) {
    final l10n = lookupAppLocalizations(Locale(lang));
    for (final scale in [1.0, 1.5, 2.0]) {
      for (final role in ['client', 'seller']) {
        final accent = role == 'seller' ? kSellerPrimary : kPrimaryColor;
        final tag = '$lang x$scale $role';

        testWidgets('signup form $tag: renders, no overflow', (t) => guarded(t, () async {
              await pdPump(
                t,
                SignUpScreen(
                  role: role,
                  accentColor: accent,
                  heroImage: AppInfo.onBoard2,
                  subtitle: (_) => 'x',
                  roleLabel: (_) => 'x',
                  onSignedUp: (_, __) async {},
                ),
                locale: Locale(lang),
                scale: scale,
              );
              expect(find.byType(DobField), findsOneWidget);
              expect(find.text(l10n.authSignUpButton), findsOneWidget);
              expect(t.takeException(), isNull);
            }));

        testWidgets('first sign-in screen $tag: renders, no overflow', (t) => guarded(t, () async {
              await pdPump(
                t,
                PersonalDetailsScreen(
                  accent: accent,
                  onDone: () {},
                  loader: () async => null,
                  onSkip: () async {},
                ),
                locale: Locale(lang),
                scale: scale,
              );
              expect(find.text(l10n.pdTitle), findsOneWidget);
              expect(find.text(l10n.skipForNow), findsOneWidget);
              expect(t.takeException(), isNull);
            }));

        for (final filled in [false, true]) {
          testWidgets('profile section $tag (stored=$filled): renders, no overflow',
              (t) => guarded(t, () async {
                await pdPump(
                  t,
                  Scaffold(
                    body: SingleChildScrollView(
                      padding: const EdgeInsets.all(20),
                      child: PrivateDetailsSection(
                        accent: accent,
                        now: DateTime.utc(2026, 11, 20, 12),
                        loader: () async => filled ? stored : null,
                        launcher: (_) async => true,
                        saver: ({legalName, dateOfBirth, streetAddress,
                            postalCode, consentVersion, required clear}) async {},
                      ),
                    ),
                  ),
                  locale: Locale(lang),
                  scale: scale,
                );
                expect(find.text(l10n.pdTrustTitle), findsNothing);
                expect(t.takeException(), isNull);
              }));

          testWidgets('trust item $tag (done=$filled): renders, no overflow',
              (t) => guarded(t, () async {
                await pdPump(
                  t,
                  Scaffold(
                    body: Padding(
                      padding: const EdgeInsets.all(20),
                      child: PersonalDetailsTrustItem(
                        accent: accent,
                        loader: () async => filled ? stored : null,
                        onOpen: (_) async {},
                      ),
                    ),
                  ),
                  locale: Locale(lang),
                  scale: scale,
                );
                expect(find.text(l10n.pdTrustTitle), findsOneWidget);
                expect(find.text(filled ? l10n.pdTrustDone : l10n.pdTrustMissing),
                    findsOneWidget);
                expect(t.takeException(), isNull);
              }));
        }
      }
    }
  }
}
