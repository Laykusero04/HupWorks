import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:freelancer/services/user_private_details_service.dart';
import 'package:http/http.dart' as http;
import 'package:supabase_flutter/supabase_flutter.dart';

import '../support/qa_supabase.dart';

/// T-0172 edge cases (QA): validation boundaries, leap days, year 1899,
/// NL postal variants, partial upserts, getMine with no row, sign-out.
/// Fake data only; every request stays in the in-process mock.
void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  final requests = <http.Request>[];
  Object? row;

  setUpAll(() async {
    await initQaSupabase(
      signedIn: true,
      tables: {
        UserPrivateDetailsService.table: (request) {
          requests.add(request);
          return row;
        },
      },
    );
  });

  setUp(() {
    requests.clear();
    row = null;
  });

  Map<String, dynamic> bodyOf(http.Request r) =>
      jsonDecode(r.body) as Map<String, dynamic>;

  group('date of birth (16+ and not before 1900)', () {
    final now = DateTime(2026, 11, 20);

    test('exactly 16 today is accepted; 16 tomorrow is refused', () {
      expect(
          UserPrivateDetailsService.isOldEnough(DateTime(2010, 11, 20),
              now: now),
          isTrue);
      expect(
          UserPrivateDetailsService.isOldEnough(DateTime(2010, 11, 21),
              now: now),
          isFalse);
      expect(
          UserPrivateDetailsService.isOldEnough(DateTime(2010, 11, 19),
              now: now),
          isTrue);
    });

    test('leap-day birthday (2008-02-29) turns 16 on 2024-02-29', () {
      final dob = DateTime(2008, 2, 29);
      // Day before the leap day, not yet 16 in calendar terms.
      expect(
          UserPrivateDetailsService.isOldEnough(dob,
              now: DateTime(2024, 2, 28)),
          isFalse);
      // On the leap day itself: exactly 16.
      expect(
          UserPrivateDetailsService.isOldEnough(dob,
              now: DateTime(2024, 2, 29)),
          isTrue);
      // Non-leap year: 28 Feb is the day after 16 is reached.
      expect(
          UserPrivateDetailsService.isOldEnough(dob,
              now: DateTime(2025, 2, 28)),
          isTrue);
      expect(
          UserPrivateDetailsService.isOldEnough(dob, now: DateTime(2025, 3, 1)),
          isTrue);
    });

    test('leap-day check on the day after a non-leap birthday', () {
      // DOB 2008-03-01 is 16 on 2024-03-01, not on 2024-02-29.
      expect(
          UserPrivateDetailsService.isOldEnough(DateTime(2008, 3, 1),
              now: DateTime(2024, 2, 29)),
          isFalse);
      expect(
          UserPrivateDetailsService.isOldEnough(DateTime(2008, 3, 1),
              now: DateTime(2024, 3, 1)),
          isTrue);
    });

    test('year 1899 is refused; 1900-01-01 is the lowest accepted date', () {
      expect(
          UserPrivateDetailsService.isOldEnough(DateTime(1899, 12, 31),
              now: now),
          isFalse);
      expect(
          UserPrivateDetailsService.isOldEnough(DateTime(1899, 1, 1), now: now),
          isFalse);
      expect(
          UserPrivateDetailsService.isOldEnough(DateTime(1900, 1, 1), now: now),
          isTrue);
    });

    test('future date and same-day birth are refused', () {
      expect(
          UserPrivateDetailsService.isOldEnough(DateTime(2026, 11, 21),
              now: now),
          isFalse);
      expect(
          UserPrivateDetailsService.isOldEnough(DateTime(2026, 11, 20),
              now: now),
          isFalse);
    });

    test('upsertMine with 1899 throws before any request', () async {
      await expectLater(
        UserPrivateDetailsService.upsertMine(
            dateOfBirth: DateTime(1899, 6, 1), now: now),
        throwsA(isA<PrivateDetailsValidationException>()
            .having((e) => e.field, 'field', PrivateDetailsField.dateOfBirth)),
      );
      expect(requests, isEmpty);
    });
  });

  group('NL postal code', () {
    test('accepted forms all validate and normalise to "1234 AB"', () {
      const inputs = [
        '1234 AB',
        '1234AB',
        '1234 ab',
        '1234ab',
        '  1234 AB  ',
        '1234AB ',
        '9999ZZ',
        '1000 aa',
      ];
      for (final s in inputs) {
        expect(UserPrivateDetailsService.isValidNlPostalCode(s), isTrue,
            reason: 'input "$s"');
        final n = UserPrivateDetailsService.normalizeNlPostalCode(s);
        expect(RegExp(r'^[1-9][0-9]{3} [A-Z]{2}$').hasMatch(n), isTrue,
            reason: 'normalised "$n" from "$s"');
      }
    });

    test('refused forms', () {
      const inputs = [
        '0123 AB', // leading zero
        '0000 AA',
        '1234  AB', // two spaces
        '1234\tAB', // tab
        '1234 AB', // non-breaking space inside
        '12 34 AB',
        '1234-AB',
        '1234 A',
        'AB1234',
        '1234 A1',
        '1234 ÁB', // non-ASCII letter
        '123 AB',
        '',
        '   ',
      ];
      for (final s in inputs) {
        expect(UserPrivateDetailsService.isValidNlPostalCode(s), isFalse,
            reason: 'input "${s.replaceAll(' ', '<NBSP>')}"');
      }
    });

    test('normalise leaves a non-matching value trimmed, not rewritten', () {
      expect(UserPrivateDetailsService.normalizeNlPostalCode('  12  '), '12');
    });

    test('upsertMine with "1234 ab" sends "1234 AB"', () async {
      await UserPrivateDetailsService.upsertMine(postalCode: '1234 ab');
      expect(bodyOf(requests.single)['postal_code'], '1234 AB');
    });
  });

  group('legal name, street and consent limits', () {
    test('legal name: 200 chars accepted, 201 refused, trimmed on send',
        () async {
      await UserPrivateDetailsService.upsertMine(legalName: 'x' * 200);
      expect(bodyOf(requests.single)['legal_name'], 'x' * 200);
      requests.clear();

      await expectLater(
        UserPrivateDetailsService.upsertMine(legalName: 'x' * 201),
        throwsA(isA<PrivateDetailsValidationException>()
            .having((e) => e.field, 'field', PrivateDetailsField.legalName)),
      );
      expect(requests, isEmpty);

      await UserPrivateDetailsService.upsertMine(legalName: '  Ann  ');
      expect(bodyOf(requests.single)['legal_name'], 'Ann');
    });

    test('street: 300 accepted, 301 refused, blank refused', () async {
      await UserPrivateDetailsService.upsertMine(streetAddress: 'y' * 300);
      expect(requests, hasLength(1));
      requests.clear();

      await expectLater(
        UserPrivateDetailsService.upsertMine(streetAddress: 'y' * 301),
        throwsA(isA<PrivateDetailsValidationException>().having(
            (e) => e.field, 'field', PrivateDetailsField.streetAddress)),
      );
      await expectLater(
        UserPrivateDetailsService.upsertMine(streetAddress: ' \t '),
        throwsA(isA<PrivateDetailsValidationException>().having(
            (e) => e.field, 'field', PrivateDetailsField.streetAddress)),
      );
      expect(requests, isEmpty);
    });

    test('consent version: empty, blank or too long is a validation exception',
        () async {
      // Fix round 2: was throwsArgumentError (inconsistent with other fields).
      for (final v in ['', '   ', 'v' * 65]) {
        await expectLater(
          UserPrivateDetailsService.upsertMine(consentVersion: v),
          throwsA(isA<PrivateDetailsValidationException>().having(
              (e) => e.field, 'field', PrivateDetailsField.consentVersion)),
        );
      }
      expect(requests, isEmpty);

      await UserPrivateDetailsService.upsertMine(consentVersion: 'v' * 64);
      expect(bodyOf(requests.single)['consent_version'], 'v' * 64);
    });
  });

  group('partial upserts send only the fields passed', () {
    final now = DateTime(2026, 11, 20, 9, 30);

    test('no fields: request carries only user_id', () async {
      await UserPrivateDetailsService.upsertMine();
      expect(requests, hasLength(1));
      expect(bodyOf(requests.single).keys.toSet(), {'user_id'});
      expect(bodyOf(requests.single)['user_id'], qaSignedInUserId);
    });

    test(
        'consent only: sends consent_version only (consented_at is server-side)',
        () async {
      await UserPrivateDetailsService.upsertMine(
          consentVersion: 'privacy-2026-11', now: now);
      final body = bodyOf(requests.single);
      // Fix round 2: consented_at is set by the DB trigger, never sent.
      expect(body.keys.toSet(), {'user_id', 'consent_version'});
    });

    test('date of birth only sends a plain date', () async {
      await UserPrivateDetailsService.upsertMine(
          dateOfBirth: DateTime(2010, 11, 20), now: now);
      final body = bodyOf(requests.single);
      expect(body.keys.toSet(), {'user_id', 'date_of_birth'});
      expect(body['date_of_birth'], '2010-11-20');
    });

    test('postal code only, and it does not touch other columns', () async {
      await UserPrivateDetailsService.upsertMine(postalCode: '1234ab');
      final body = bodyOf(requests.single);
      expect(body.keys.toSet(), {'user_id', 'postal_code'});
      expect(body['postal_code'], '1234 AB');
    });

    test('an invalid field in a multi-field call sends nothing', () async {
      await expectLater(
        UserPrivateDetailsService.upsertMine(
          legalName: 'Ann',
          postalCode: '0123 AB', // invalid
          consentVersion: 'privacy-2026-11',
        ),
        throwsA(isA<PrivateDetailsValidationException>()
            .having((e) => e.field, 'field', PrivateDetailsField.postalCode)),
      );
      expect(requests, isEmpty,
          reason: 'valid fields must not be written when one field is bad');
    });
  });

  group('getMine', () {
    test('no row: returns null with a single own-row GET', () async {
      row = null;
      expect(await UserPrivateDetailsService.getMine(), isNull);
      expect(requests, hasLength(1));
      expect(requests.single.method, 'GET');
      expect(requests.single.url.queryParameters['user_id'],
          'eq.$qaSignedInUserId');
    });

    test('blank name is read as null; consent needs both halves', () async {
      row = {
        'user_id': qaSignedInUserId,
        'legal_name': '   ',
        'consent_version': 'privacy-2026-11',
        'consented_at': null,
      };
      final d = await UserPrivateDetailsService.getMine();
      expect(d, isNotNull);
      expect(d!.legalName, isNull);
      expect(d.hasConsent, isFalse);
      expect(d.hasAddress, isFalse);
    });

    test('toString never reveals the user id or any value', () async {
      row = {
        'user_id': qaSignedInUserId,
        'legal_name': 'Sam Tester',
        'postal_code': '1234 AB',
      };
      final d = await UserPrivateDetailsService.getMine();
      final s = d.toString();
      expect(s, isNot(contains('Sam')));
      expect(s, isNot(contains('1234')));
      expect(s, isNot(contains(qaSignedInUserId)));
    });
  });

  test('signed out: every call refuses without a request', () async {
    // Last in the file: this changes the shared session.
    await Supabase.instance.client.auth.signOut(scope: SignOutScope.local);
    requests.clear();

    await expectLater(
        UserPrivateDetailsService.getMine(), throwsA(isA<Exception>()));
    await expectLater(UserPrivateDetailsService.upsertMine(legalName: 'Ann'),
        throwsA(isA<Exception>()));
    expect(requests, isEmpty);
  });
}
