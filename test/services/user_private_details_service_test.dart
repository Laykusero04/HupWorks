import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:freelancer/core/utils/age_check.dart';
import 'package:freelancer/data/models/user_private_details.dart';
import 'package:freelancer/services/user_private_details_service.dart';
import 'package:http/http.dart' as http;

import '../support/qa_supabase.dart';

/// T-0172: own-row access + client-side validation mirroring migration 0060.
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

  final now = DateTime(2026, 11, 20);

  group('validation', () {
    test('age 16 boundary', () {
      expect(
          UserPrivateDetailsService.isOldEnough(DateTime(2010, 11, 20),
              now: now),
          isTrue);
      expect(
          UserPrivateDetailsService.isOldEnough(DateTime(2010, 11, 21),
              now: now),
          isFalse);
      expect(
          UserPrivateDetailsService.isOldEnough(DateTime(2026, 1, 1), now: now),
          isFalse);
      expect(
          UserPrivateDetailsService.isOldEnough(DateTime(1899, 12, 31),
              now: now),
          isFalse);
      expect(
          UserPrivateDetailsService.isOldEnough(DateTime(1990, 5, 17),
              now: now),
          isTrue);
    });

    test('NL postal code', () {
      for (final ok in ['1234 AB', '1234AB', '9999 zz', ' 2311 ab ']) {
        expect(UserPrivateDetailsService.isValidNlPostalCode(ok), isTrue,
            reason: ok);
      }
      for (final bad in [
        '0123 AB',
        '12345',
        '1234 A',
        '1234 ABC',
        'ABCD 12',
        '',
        '1234  AB'
      ]) {
        expect(UserPrivateDetailsService.isValidNlPostalCode(bad), isFalse,
            reason: bad);
      }
      expect(
          UserPrivateDetailsService.normalizeNlPostalCode('2311ab'), '2311 AB');
      expect(UserPrivateDetailsService.normalizeNlPostalCode(' 2311 ab '),
          '2311 AB');
    });

    test('invalid input throws before any request', () async {
      Future<PrivateDetailsField?> field(Future<void> Function() f) async {
        try {
          await f();
        } on PrivateDetailsValidationException catch (e) {
          return e.field;
        }
        return null;
      }

      expect(
          await field(() => UserPrivateDetailsService.upsertMine(
              dateOfBirth: DateTime(2020, 1, 1), now: now)),
          PrivateDetailsField.dateOfBirth);
      expect(
          await field(() =>
              UserPrivateDetailsService.upsertMine(postalCode: '0000 AA')),
          PrivateDetailsField.postalCode);
      expect(
          await field(
              () => UserPrivateDetailsService.upsertMine(legalName: '   ')),
          PrivateDetailsField.legalName);
      expect(
          await field(
              () => UserPrivateDetailsService.upsertMine(legalName: 'x' * 201)),
          PrivateDetailsField.legalName);
      expect(
          await field(
              () => UserPrivateDetailsService.upsertMine(streetAddress: '')),
          PrivateDetailsField.streetAddress);
      expect(requests, isEmpty);
    });

    test('exception text never contains the value', () {
      const e =
          PrivateDetailsValidationException(PrivateDetailsField.postalCode);
      expect(e.toString(), isNot(contains('0000')));
    });
  });

  group('requests', () {
    test('getMine selects explicit columns filtered by own user id', () async {
      row = {
        'user_id': qaSignedInUserId,
        'legal_name': ' Sam Tester ',
        'date_of_birth': '1990-05-17',
        'street_address': 'Laan 2',
        'postal_code': '1234 AB',
        'consent_version': 'privacy-2026-11',
        'consented_at': '2026-11-20T10:00:00+00:00',
      };
      final d = await UserPrivateDetailsService.getMine();

      expect(requests, hasLength(1));
      final r = requests.single;
      expect(r.method, 'GET');
      expect(r.url.path, endsWith('/rest/v1/user_private_details'));
      expect(r.url.queryParameters['user_id'], 'eq.$qaSignedInUserId');
      expect(r.url.queryParameters['select'], isNot('*'));
      expect(r.url.queryParameters['select']?.replaceAll(' ', ''),
          UserPrivateDetails.selectColumns.replaceAll(' ', ''));

      expect(d, isNotNull);
      expect(d!.legalName, 'Sam Tester');
      expect(d.dateOfBirth, DateTime(1990, 5, 17));
      expect(d.hasConsent, isTrue);
      expect(d.hasAddress, isTrue);
      expect(d.toString(), isNot(contains('Sam')));
    });

    test('getMine returns null when no row exists yet', () async {
      row = null;
      expect(await UserPrivateDetailsService.getMine(), isNull);
    });

    test('upsertMine sends explicit user_id, normalised values, on_conflict',
        () async {
      await UserPrivateDetailsService.upsertMine(
        legalName: ' Sam Tester ',
        dateOfBirth: DateTime(1990, 5, 7),
        streetAddress: ' Laan 2 ',
        postalCode: '1234ab',
        consentVersion: 'privacy-2026-11',
        now: now,
      );

      expect(requests, hasLength(1));
      final r = requests.single;
      expect(r.method, 'POST');
      expect(r.url.queryParameters['on_conflict'], 'user_id');
      expect(r.headers['Prefer'] ?? r.headers['prefer'],
          contains('resolution=merge-duplicates'));
      final body = jsonDecode(r.body) as Map<String, dynamic>;
      expect(body['user_id'], qaSignedInUserId);
      expect(body['legal_name'], 'Sam Tester');
      expect(body['date_of_birth'], '1990-05-07');
      expect(body['street_address'], 'Laan 2');
      expect(body['postal_code'], '1234 AB');
      expect(body['consent_version'], 'privacy-2026-11');
      // consented_at is set by the DB trigger, never sent by the client.
      expect(body.containsKey('consented_at'), isFalse);
    });

    test('upsertMine only sends fields that were passed', () async {
      await UserPrivateDetailsService.upsertMine(legalName: 'Sam');
      final body = jsonDecode(requests.single.body) as Map<String, dynamic>;
      expect(body.keys.toSet(), {'user_id', 'legal_name'});
    });
  });

  group('fix round 2', () {
    test('consent version blank / too long -> validation exception', () async {
      for (final v in ['', '   ', 'v' * 65]) {
        await expectLater(
          UserPrivateDetailsService.upsertMine(consentVersion: v),
          throwsA(isA<PrivateDetailsValidationException>().having(
              (e) => e.field, 'field', PrivateDetailsField.consentVersion)),
        );
      }
      expect(requests, isEmpty);
    });

    test('clear sends explicit nulls only for the cleared fields', () async {
      await UserPrivateDetailsService.upsertMine(
        legalName: 'Sam',
        clear: {
          PrivateDetailsField.streetAddress,
          PrivateDetailsField.postalCode,
          PrivateDetailsField.dateOfBirth,
        },
      );
      final body = jsonDecode(requests.single.body) as Map<String, dynamic>;
      expect(body['legal_name'], 'Sam');
      for (final k in ['street_address', 'postal_code', 'date_of_birth']) {
        expect(body.containsKey(k), isTrue, reason: k);
        expect(body[k], isNull, reason: k);
      }
      expect(body.containsKey('consent_version'), isFalse);
    });

    test('clearing consent nulls version and timestamp', () async {
      await UserPrivateDetailsService.upsertMine(
          clear: {PrivateDetailsField.consentVersion});
      final body = jsonDecode(requests.single.body) as Map<String, dynamic>;
      expect(body['consent_version'], isNull);
      expect(body['consented_at'], isNull);
      expect(body.containsKey('consented_at'), isTrue);
    });

    test('set and clear of the same field is an ArgumentError', () async {
      await expectLater(
        UserPrivateDetailsService.upsertMine(
            legalName: 'Sam', clear: {PrivateDetailsField.legalName}),
        throwsArgumentError,
      );
      expect(requests, isEmpty);
    });

    test('isAtLeast16: UTC calendar basis, boundary', () {
      // Instant just before / after UTC midnight of the 16th birthday.
      final dob = DateTime(2010, 11, 20);
      expect(isAtLeast16(dob, now: DateTime.utc(2026, 11, 19, 23, 59, 59)),
          isFalse);
      expect(isAtLeast16(dob, now: DateTime.utc(2026, 11, 20)), isTrue);
      // Default `now` is the UTC date: the 1-day-old-today dob is refused.
      final utcToday = DateTime.now().toUtc();
      expect(
          isAtLeast16(
              DateTime(utcToday.year - 16, utcToday.month, utcToday.day)),
          isTrue);
      expect(
          isAtLeast16(
              DateTime(utcToday.year - 16, utcToday.month, utcToday.day + 1)),
          isFalse);
      expect(isAtLeast16(DateTime(utcToday.year - 1, 1, 1)), isFalse);
    });
  });

  test('model parses an empty / partial row', () {
    final d = UserPrivateDetails.fromJson({'user_id': 'u', 'legal_name': '  '});
    expect(d.legalName, isNull);
    expect(d.dateOfBirth, isNull);
    expect(d.hasConsent, isFalse);
  });

  group('source audit (T-0172)', () {
    final files = Directory('lib')
        .listSync(recursive: true)
        .whereType<File>()
        .where((f) => f.path.endsWith('.dart') && !f.path.contains('/l10n/'))
        .toList();

    // Columns that exist only in user_private_details.
    final privateOnly =
        RegExp(r'\b(legal_name|consent_version|consented_at)\b');

    test(
        'no public profile select string requests user_private_details columns',
        () {
      final bad = <String>[];
      // Any .select('...') / .select("...") / const columns = '...' string.
      final selects = RegExp(r'''\.select\(\s*(?:'([^']*)'|"([^"]*)")''');
      final colsConst =
          RegExp(r'''(?:columns|Columns)\s*=\s*(?:'([^']*)'|"([^"]*)")''');
      for (final f in files) {
        if (f.path.endsWith('user_private_details_service.dart') ||
            f.path.endsWith('user_private_details.dart')) {
          continue;
        }
        final src = f.readAsStringSync();
        for (final re in [selects, colsConst]) {
          for (final m in re.allMatches(src)) {
            final s = m.group(1) ?? m.group(2) ?? '';
            if (privateOnly.hasMatch(s)) bad.add('${f.path}: $s');
          }
        }
      }
      expect(bad, isEmpty);
    });

    test('public profile services never reference the table or its columns',
        () {
      for (final path in [
        'lib/services/profile_service.dart',
        'lib/services/saved_talent_service.dart',
        'lib/services/chat_service.dart',
        'lib/services/job_posts_service.dart',
      ]) {
        final src = File(path).readAsStringSync();
        expect(src.contains('user_private_details'), isFalse, reason: path);
        expect(privateOnly.hasMatch(src), isFalse, reason: path);
      }
    });

    test('only the private-details service touches the table', () {
      final users = files
          .where((f) => f.readAsStringSync().contains("'user_private_details'"))
          .map((f) => f.path)
          .toList();
      expect(users, ['lib/services/user_private_details_service.dart']);
    });
  });
}
