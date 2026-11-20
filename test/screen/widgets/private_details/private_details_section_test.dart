import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:freelancer/core/constants/colors.dart';
import 'package:freelancer/data/models/user_private_details.dart';
import 'package:freelancer/l10n/app_localizations.dart';
import 'package:freelancer/screen/widgets/private_details/private_details_section.dart';
import 'package:freelancer/services/user_private_details_service.dart';

import '../../../support/pd_harness.dart';

/// T-0172: "Personal details (private)" section on both Edit profile screens.
void main() {
  setUpAll(pdSetUp);

  final en = lookupAppLocalizations(const Locale('en'));
  final nl = lookupAppLocalizations(const Locale('nl'));
  final today = DateTime.utc(2026, 11, 20, 12);

  late List<Map<String, Object?>> saves;
  Object? failWith;
  UserPrivateDetails? row;
  bool loadFails = false;
  final key = GlobalKey<PrivateDetailsSectionState>();

  setUp(() {
    saves = [];
    failWith = null;
    row = null;
    loadFails = false;
  });

  Widget host({Color accent = kPrimaryColor}) => Scaffold(
        body: SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: PrivateDetailsSection(
            key: key,
            accent: accent,
            now: today,
            loader: () async {
              if (loadFails) throw Exception('offline');
              return row;
            },
            launcher: (_) async => true,
            saver: ({
              legalName,
              dateOfBirth,
              streetAddress,
              postalCode,
              consentVersion,
              required clear,
            }) async {
              if (failWith != null) throw failWith!;
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

  UserPrivateDetails stored({String? name = 'Jan Jansen'}) =>
      UserPrivateDetails(
        userId: 'u',
        legalName: name,
        dateOfBirth: DateTime(1990, 5, 7),
        streetAddress: 'Dorpsstraat 1',
        postalCode: '1234 AB',
        consentVersion: 'privacy-2026-11',
        consentedAt: DateTime.utc(2026, 11, 20, 10),
      );

  testWidgets('title, private callout, empty state, consent checkbox',
      (t) async {
    await pdPump(t, host());
    expect(find.text(en.pdSectionTitle), findsOneWidget);
    expect(find.text(en.pdSectionCallout), findsOneWidget);
    expect(find.text(en.pdNotAddedYet), findsOneWidget);
    expect(find.byType(Checkbox), findsOneWidget);
  });

  testWidgets('nothing typed: save() succeeds without writing', (t) async {
    await pdPump(t, host());
    expect(await key.currentState!.save(), isTrue);
    expect(saves, isEmpty);
  });

  testWidgets('typing details without consent is refused', (t) async {
    await pdPump(t, host());
    await t.enterText(find.byType(TextField).at(3), 'Jan Jansen');
    await t.pump();
    expect(await key.currentState!.save(), isFalse);
    await t.pump();
    expect(find.text(en.pdConsentRequired), findsOneWidget);
    expect(saves, isEmpty);
  });

  testWidgets('saves all fields with consent; postal is normalised by service',
      (t) async {
    await pdPump(t, host());
    final f = find.byType(TextField);
    await t.enterText(f.at(0), '07');
    await t.enterText(f.at(1), '05');
    await t.enterText(f.at(2), '1990');
    await t.enterText(f.at(3), '  Jan Jansen ');
    await t.enterText(f.at(4), 'Dorpsstraat 1');
    await t.enterText(f.at(5), '1234ab');
    await t.ensureVisible(find.byType(Checkbox));
    await t.tap(find.byType(Checkbox));
    await t.pump();
    expect(await key.currentState!.save(), isTrue);
    expect(saves, hasLength(1));
    expect(saves.single['name'], 'Jan Jansen');
    expect(saves.single['dob'], DateTime(1990, 5, 7));
    expect(saves.single['street'], 'Dorpsstraat 1');
    expect(saves.single['postal'], '1234ab'); // service normalises
    expect(saves.single['consent'], 'privacy-2026-11');
  });

  testWidgets('invalid postal code and under-16 DOB show inline errors',
      (t) async {
    await pdPump(t, host());
    final f = find.byType(TextField);
    await t.enterText(f.at(0), '21');
    await t.enterText(f.at(1), '11');
    await t.enterText(f.at(2), '2010');
    await t.enterText(f.at(5), '12345');
    await t.pump();
    expect(await key.currentState!.save(), isFalse);
    await t.pump();
    expect(find.text(en.pdDobErrorUnder16), findsOneWidget);
    expect(find.text(en.pdErrPostal), findsOneWidget);
    expect(saves, isEmpty);
  });

  testWidgets('existing row: prefilled, consent summary, unchanged = no write',
      (t) async {
    row = stored();
    await pdPump(t, host());
    expect(find.text('Jan Jansen'), findsOneWidget);
    expect(find.text('1234 AB'), findsOneWidget);
    expect(find.byType(Checkbox), findsNothing);
    expect(find.text(en.pdConsentRowTitle), findsOneWidget);
    expect(find.textContaining('privacy-2026-11'), findsOneWidget);
    expect(await key.currentState!.save(), isTrue);
    expect(saves, isEmpty);
  });

  testWidgets('clearing an optional field sends it in clear, not as a value',
      (t) async {
    row = stored();
    await pdPump(t, host());
    await t.enterText(find.byType(TextField).at(3), '');
    await t.pump();
    expect(await key.currentState!.save(), isTrue);
    expect(saves.single['name'], isNull);
    expect(saves.single['clear'], {PrivateDetailsField.legalName});
  });

  testWidgets('clearing the stored DOB is refused (required once given)',
      (t) async {
    row = stored();
    await pdPump(t, host());
    final f = find.byType(TextField);
    await t.enterText(f.at(0), '');
    await t.enterText(f.at(1), '');
    await t.enterText(f.at(2), '');
    await t.pump();
    expect(await key.currentState!.save(), isFalse);
    await t.pump();
    expect(find.text(en.pdDobErrorEmpty), findsOneWidget);
  });

  testWidgets('server error: false + friendly inline message, no raw text',
      (t) async {
    row = stored();
    failWith = Exception('SECRET-RAW');
    await pdPump(t, host());
    await t.enterText(find.byType(TextField).at(3), 'Piet');
    await t.pump();
    expect(await key.currentState!.save(), isFalse);
    await t.pump();
    expect(find.text(en.pdSaveError), findsOneWidget);
    expect(find.textContaining('SECRET-RAW'), findsNothing);
  });

  testWidgets('read failure: section never writes over unread data', (t) async {
    loadFails = true;
    await pdPump(t, host());
    await t.enterText(find.byType(TextField).at(3), 'Piet');
    await t.pump();
    expect(await key.currentState!.save(), isTrue);
    expect(saves, isEmpty);
  });

  for (final role in ['client', 'seller']) {
    for (final withRow in [false, true]) {
      testWidgets(
          'NL x2.0 on 375pt ($role, ${withRow ? 'filled' : 'empty'}): no overflow',
          (t) async {
        row = withRow ? stored() : null;
        await pdPump(
          t,
          host(accent: role == 'seller' ? kSellerPrimary : kPrimaryColor),
          locale: const Locale('nl'),
          scale: 2.0,
        );
        expect(find.text(nl.pdSectionTitle), findsOneWidget);
        // trigger every error at once
        final f = find.byType(TextField);
        await t.enterText(f.at(0), '31');
        await t.enterText(f.at(1), '02');
        await t.enterText(f.at(2), '2000');
        await t.enterText(f.at(3), 'x' * 201);
        await t.enterText(f.at(4), 'y' * 301);
        await t.enterText(f.at(5), '0000');
        await t.pump();
        expect(await key.currentState!.save(), isFalse);
        await t.pump();
        expect(find.text(nl.pdDobErrorInvalid), findsOneWidget);
        expect(find.text(nl.pdErrLegalName), findsOneWidget);
        expect(find.text(nl.pdErrStreet), findsOneWidget);
        expect(find.text(nl.pdErrPostal), findsOneWidget);
        expect(t.takeException(), isNull);
      });
    }
  }
}
