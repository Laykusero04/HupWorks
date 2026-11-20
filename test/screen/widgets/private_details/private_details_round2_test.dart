import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:freelancer/core/constants/colors.dart';
import 'package:freelancer/data/models/user_private_details.dart';
import 'package:freelancer/l10n/app_localizations.dart';
import 'package:freelancer/screen/widgets/private_details/dob_field.dart';
import 'package:freelancer/screen/widgets/private_details/personal_details_screen.dart';
import 'package:freelancer/screen/widgets/private_details/personal_details_trust_item.dart';
import 'package:freelancer/screen/widgets/private_details/private_details_section.dart';

import '../../../support/pd_harness.dart';

/// T-0172 fix round 2: paste splitting, read-only fallback prefill, validate
/// without writing, first-sign-in screen read failure, trust item semantics.
void main() {
  setUpAll(pdSetUp);

  final en = lookupAppLocalizations(const Locale('en'));
  final nl = lookupAppLocalizations(const Locale('nl'));
  final today = DateTime.utc(2026, 11, 20, 12);

  group('paste a full date', () {
    Future<DobController> pumpField(WidgetTester t) async {
      final c = DobController();
      addTearDown(c.dispose);
      await pdPump(
        t,
        Scaffold(
          body: Padding(
            padding: const EdgeInsets.all(20),
            child: DobField(controller: c, accent: kPrimaryColor),
          ),
        ),
      );
      return c;
    }

    for (final (pasted, box) in [
      ('01-02-2008', 0),
      ('01/02/2008', 0),
      ('2008-02-01', 0),
      ('01.02.2008', 1),
      ('1 2 2008', 2),
      ('2008/2/1', 2),
    ]) {
      testWidgets('"$pasted" into box $box splits into 01 / 02 / 2008',
          (t) async {
        final c = await pumpField(t);
        await t.enterText(find.byType(TextField).at(box), pasted);
        await t.pump();
        expect(c.day.text, '01');
        expect(c.month.text, '02');
        expect(c.year.text, '2008');
      });
    }

    testWidgets('non-date text is still just filtered', (t) async {
      final c = await pumpField(t);
      await t.enterText(find.byType(TextField).at(0), 'ab1c');
      await t.pump();
      expect(c.day.text, '1');
      expect(c.month.text, '');
    });
  });

  group('section: read-only fallback and validate()', () {
    late List<Map<String, Object?>> saves;
    UserPrivateDetails? row;
    final key = GlobalKey<PrivateDetailsSectionState>();
    DateTime? reported;
    var reports = 0;

    setUp(() {
      saves = [];
      row = null;
      reported = null;
      reports = 0;
    });

    Widget host({
      DateTime? fallbackDob,
      String? fallbackStreet,
      String? fallbackPostal,
    }) =>
        Scaffold(
          body: SingleChildScrollView(
            padding: const EdgeInsets.all(20),
            child: PrivateDetailsSection(
              key: key,
              accent: kSellerPrimary,
              now: today,
              fallbackDob: fallbackDob,
              fallbackStreet: fallbackStreet,
              fallbackPostal: fallbackPostal,
              onDobChanged: (d) {
                reported = d;
                reports++;
              },
              loader: () async => row,
              launcher: (_) async => true,
              saver: ({
                legalName,
                dateOfBirth,
                streetAddress,
                postalCode,
                consentVersion,
                required clear,
              }) async {
                saves.add({
                  'name': legalName,
                  'dob': dateOfBirth,
                  'street': streetAddress,
                  'postal': postalCode,
                  'consent': consentVersion,
                  'clear': clear,
                });
              },
            ),
          ),
        );

    testWidgets(
        'no new row: old values prefill, unchanged = no write, no consent demanded',
        (t) async {
      await pdPump(
        t,
        host(
          fallbackDob: DateTime(1990, 5, 7),
          fallbackStreet: 'Oude Straat 1',
          fallbackPostal: '1234 AB',
        ),
      );
      expect(find.text('07'), findsOneWidget);
      expect(find.text('05'), findsOneWidget);
      expect(find.text('1990'), findsOneWidget);
      expect(find.text('Oude Straat 1'), findsOneWidget);
      expect(find.text(en.pdNotAddedYet), findsNothing);
      // the page's save must not be blocked or write anything
      expect(key.currentState!.validate(), isTrue);
      expect(await key.currentState!.save(), isTrue);
      expect(saves, isEmpty);
      expect(find.text(en.pdConsentRequired), findsNothing);
      expect(reported, DateTime(1990, 5, 7));
    });

    testWidgets('new DOB wins over the old one and is written (needs consent)',
        (t) async {
      await pdPump(t, host(fallbackDob: DateTime(1990, 5, 7)));
      final f = find.byType(TextField);
      await t.enterText(f.at(0), '15');
      await t.enterText(f.at(1), '06');
      await t.enterText(f.at(2), '1995');
      await t.pump();
      expect(reported, DateTime(1995, 6, 15));
      expect(await key.currentState!.save(), isFalse); // consent missing
      await t.pump();
      expect(find.text(en.pdConsentRequired), findsOneWidget);
      await t.ensureVisible(find.byType(Checkbox));
      await t.tap(find.byType(Checkbox));
      await t.pump();
      expect(await key.currentState!.save(), isTrue);
      expect(saves.single['dob'], DateTime(1995, 6, 15));
      expect(saves.single['street'], isNull); // unchanged prefill not copied
      expect(saves.single['consent'], 'privacy-2026-11');
    });

    testWidgets('stored row beats the fallback', (t) async {
      row = UserPrivateDetails(
        userId: 'u',
        dateOfBirth: DateTime(2000, 1, 2),
        consentVersion: 'privacy-2026-11',
        consentedAt: DateTime.utc(2026, 11, 20),
      );
      await pdPump(t, host(fallbackDob: DateTime(1990, 5, 7)));
      expect(find.text('2000'), findsOneWidget);
      expect(find.text('1990'), findsNothing);
      expect(reported, DateTime(2000, 1, 2));
    });

    testWidgets('old under-16 date: prefilled, does not block, age unknown',
        (t) async {
      await pdPump(t, host(fallbackDob: DateTime(2012, 1, 1)));
      expect(key.currentState!.validate(), isTrue);
      expect(await key.currentState!.save(), isTrue);
      expect(saves, isEmpty);
      expect(reported, isNull); // switch stays off
    });

    testWidgets('typing an under-16 date reports null and refuses on save',
        (t) async {
      await pdPump(t, host(fallbackDob: DateTime(1990, 5, 7)));
      final f = find.byType(TextField);
      await t.enterText(f.at(0), '21');
      await t.enterText(f.at(1), '11');
      await t.enterText(f.at(2), '2010');
      await t.pump();
      expect(reported, isNull);
      expect(key.currentState!.validate(), isFalse);
      await t.pump();
      expect(find.text(en.pdDobErrorUnder16), findsOneWidget);
      expect(saves, isEmpty);
      expect(reports, greaterThan(1));
    });

    testWidgets('validate() never writes', (t) async {
      await pdPump(t, host());
      await t.enterText(find.byType(TextField).at(3), 'Jan');
      await t.pump();
      expect(key.currentState!.validate(), isFalse); // consent missing
      expect(saves, isEmpty);
    });
  });

  group('first-sign-in screen: initial read failure', () {
    testWidgets('no form, no save; Try again reloads, then it works',
        (t) async {
      var loads = 0;
      var saves = 0;
      var done = 0;
      await pdPump(
        t,
        PersonalDetailsScreen(
          accent: kPrimaryColor,
          now: today,
          onDone: () => done++,
          onSkip: () async {},
          loader: () async {
            loads++;
            if (loads == 1) throw Exception('offline');
            return null;
          },
          saver: ({dateOfBirth, consentVersion}) async => saves++,
        ),
      );
      expect(find.text(en.pdLoadError), findsOneWidget);
      expect(find.byType(TextField), findsNothing);
      expect(find.text(en.pdTryAgain), findsOneWidget);
      expect(find.text(en.skipForNow), findsOneWidget); // skip stays possible
      expect(saves, 0);

      await t.tap(find.text(en.pdTryAgain));
      await t.pump();
      await t.pump();
      expect(loads, 2);
      expect(find.text(en.pdLoadError), findsNothing);
      expect(find.byType(TextField), findsNWidgets(3));

      final f = find.byType(TextField);
      await t.enterText(f.at(0), '14');
      await t.enterText(f.at(1), '03');
      await t.enterText(f.at(2), '1998');
      await t.ensureVisible(find.byType(Checkbox));
      await t.tap(find.byType(Checkbox));
      await t.pump();
      await t.ensureVisible(find.text(en.continueLabel));
      await t.tap(find.text(en.continueLabel));
      await t.pump();
      expect(saves, 1);
      expect(done, 1);
    });

    testWidgets('NL x2.0 on 375pt: failure state has no overflow', (t) async {
      await pdPump(
        t,
        PersonalDetailsScreen(
          accent: kSellerPrimary,
          onDone: () {},
          onSkip: () async {},
          loader: () async => throw Exception('offline'),
          saver: ({dateOfBirth, consentVersion}) async {},
        ),
        locale: const Locale('nl'),
        scale: 2.0,
      );
      expect(find.text(nl.pdLoadError), findsOneWidget);
      expect(t.takeException(), isNull);
    });
  });

  group('prefill from the old freelancer DOB (first sign-in and trust screen)',
      () {
    for (final fromTrust in [false, true]) {
      testWidgets('fromTrust=$fromTrust: old DOB prefilled when no new row',
          (t) async {
        DateTime? saved;
        var done = 0;
        await pdPump(
          t,
          PersonalDetailsScreen(
            accent: kSellerPrimary,
            fromTrust: fromTrust,
            now: today,
            onDone: () => done++,
            loader: () async => null,
            fallbackDobLoader: () async => DateTime(1990, 5, 7),
            saver: ({dateOfBirth, consentVersion}) async => saved = dateOfBirth,
          ),
        );
        expect(find.text('07'), findsOneWidget);
        expect(find.text('05'), findsOneWidget);
        expect(find.text('1990'), findsOneWidget);
        // Continue is the user's save of the shown date.
        await t.ensureVisible(find.byType(Checkbox));
        await t.tap(find.byType(Checkbox));
        await t.pump();
        await t.ensureVisible(find.text(en.continueLabel));
        await t.tap(find.text(en.continueLabel));
        await t.pump();
        expect(saved, DateTime(1990, 5, 7));
        expect(done, 1);
      });
    }

    testWidgets('new row beats the old value; a failing old read is harmless',
        (t) async {
      await pdPump(
        t,
        PersonalDetailsScreen(
          accent: kSellerPrimary,
          onDone: () {},
          loader: () async => UserPrivateDetails(
              userId: 'u', dateOfBirth: DateTime(2000, 1, 2)),
          fallbackDobLoader: () async => DateTime(1990, 5, 7),
          saver: ({dateOfBirth, consentVersion}) async {},
        ),
      );
      expect(find.text('2000'), findsOneWidget);
      expect(find.text('1990'), findsNothing);
      await pdPump(
        t,
        PersonalDetailsScreen(
          accent: kSellerPrimary,
          onDone: () {},
          loader: () async => null,
          fallbackDobLoader: () async => throw Exception('offline'),
          saver: ({dateOfBirth, consentVersion}) async {},
        ),
      );
      expect(find.byType(TextField), findsNWidgets(3));
      expect(find.text(en.pdLoadError), findsNothing);
    });
  });

  group('trust item', () {
    testWidgets('is a button with honest copy (no score promise)', (t) async {
      await pdPump(
        t,
        Scaffold(
          body: Padding(
            padding: const EdgeInsets.all(20),
            child: PersonalDetailsTrustItem(
              accent: kPrimaryColor,
              loader: () async => null,
              onOpen: (_) async {},
            ),
          ),
        ),
      );
      expect(find.text(en.pdTrustMissing), findsOneWidget);
      expect(en.pdTrustMissing.toLowerCase(), isNot(contains('raise')));
      expect(en.pdTrustMissing,
          'Complete your personal details. They stay private.');
      final handle = t.ensureSemantics();
      final node = t.getSemantics(
          find.byKey(const ValueKey('personal-details-trust-item')));
      expect(node.flagsCollection.isButton, isTrue);
      handle.dispose();
    });
  });
}
