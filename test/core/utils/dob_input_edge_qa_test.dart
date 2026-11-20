import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:freelancer/core/utils/dob_input.dart';
import 'package:freelancer/services/user_private_details_service.dart';
import 'package:freelancer/screen/widgets/private_details/dob_field.dart';

import '../../support/pd_harness.dart';

/// T-0172 QA edge cases for date-of-birth input: parsing (leading zeros, impossible
/// dates, 2-digit years, letters), the UTC-midnight 16th-birthday boundary, and
/// what a paste does to the three fields. Fake data only, no network.
void main() {
  setUpAll(pdSetUp);

  final now = DateTime.utc(2026, 11, 20, 12);
  DobError? err(String d, String m, String y, {DateTime? at}) =>
      validateDob(d, m, y, now: at ?? now).error;

  group('parsing: leading zeros and separators', () {
    test('01/02/2008 with leading zeros is 1 Feb 2008', () {
      final r = validateDob('01', '02', '2008', now: now);
      expect(r.isValid, isTrue);
      expect(r.date, DateTime(2008, 2, 1));
    });

    test('three-digit day "001" is refused (length), not read as 1', () {
      expect(err('001', '02', '2008'), DobError.invalid);
    });

    test('day "0" and "00" are refused', () {
      expect(err('0', '02', '2008'), DobError.invalid);
      expect(err('00', '02', '2008'), DobError.invalid);
    });

    test('month "0" and "00" are refused; month "1" is not', () {
      expect(err('10', '0', '2008'), DobError.invalid);
      expect(err('10', '00', '2008'), DobError.invalid);
      expect(err('10', '1', '2008'), isNull);
    });

    test('surrounding spaces are trimmed', () {
      expect(validateDob(' 01 ', ' 02 ', ' 2008 ', now: now).isValid, isTrue);
    });

    test('a dash or slash inside one part is invalid (no splitting)', () {
      expect(err('01-02', '', '2008'), DobError.invalid);
      expect(err('01-02-2008', '', ''), DobError.invalid);
    });
  });

  group('parsing: impossible dates', () {
    test('31 February is refused', () {
      expect(err('31', '02', '2008'), DobError.invalid);
    });

    test('30 February is refused in a leap year too', () {
      expect(err('30', '02', '2008'), DobError.invalid);
    });

    test('29 February 2023 (non-leap) is refused; 2008 (leap) is accepted', () {
      expect(err('29', '02', '2023'), DobError.invalid);
      expect(err('29', '02', '2008'), isNull);
    });

    test('31 April, 31 June, 31 September, 31 November are refused', () {
      for (final m in ['04', '06', '09', '11']) {
        expect(err('31', m, '2008'), DobError.invalid, reason: 'month $m');
      }
    });

    test('31 December is accepted', () {
      expect(err('31', '12', '2008'), isNull);
    });

    test('day 32 and month 13 are refused', () {
      expect(err('32', '01', '2008'), DobError.invalid);
      expect(err('01', '13', '2008'), DobError.invalid);
    });
  });

  group('parsing: years', () {
    test('two-digit year "08" is refused (not read as 2008)', () {
      expect(err('01', '02', '08'), DobError.invalid);
    });

    test('three-digit year is refused', () {
      expect(err('01', '02', '999'), DobError.invalid);
    });

    test('year 0000 and 1899 are refused; 1900 is the lowest accepted', () {
      expect(err('01', '01', '0000'), DobError.invalid);
      expect(err('31', '12', '1899'), DobError.invalid);
      expect(err('01', '01', '1900'), isNull);
    });

    test('five-digit year is refused', () {
      expect(err('01', '01', '20080'), DobError.invalid);
    });
  });

  group('parsing: letters and signs', () {
    test('letters, signs and mixed input are refused', () {
      expect(err('1a', '02', '2008'), DobError.invalid);
      expect(err('01', 'Feb', '2008'), DobError.invalid);
      expect(err('01', '02', '20o8'), DobError.invalid);
      expect(err('+1', '02', '2008'), DobError.invalid);
      expect(err('-1', '02', '2008'), DobError.invalid);
    });

    test('partial input (one part blank) is invalid, not empty', () {
      expect(err('01', '', ''), DobError.invalid);
      expect(err('', '02', '2008'), DobError.invalid);
    });
  });

  group('DobField input formatters (what a paste or typing does)', () {
    testWidgets('typed letters never reach the controller', (t) async {
      final c = DobController();
      addTearDown(c.dispose);
      await pdPump(
        t,
        Scaffold(
          body: Padding(
            padding: const EdgeInsets.all(20),
            child: DobField(controller: c, accent: const Color(0xFFFF6A00)),
          ),
        ),
      );
      await t.enterText(find.byType(TextField).at(0), 'ab1c');
      await t.pump();
      expect(c.day.text, '1');
      await t.enterText(find.byType(TextField).at(2), '20x08y');
      await t.pump();
      expect(c.year.text, '2008');
    });

    testWidgets(
        'paste "01-02-2008" into the day field splits into day, month, year',
        (t) async {
      final c = DobController();
      addTearDown(c.dispose);
      await pdPump(
        t,
        Scaffold(
          body: Padding(
            padding: const EdgeInsets.all(20),
            child: DobField(controller: c, accent: const Color(0xFFFF6A00)),
          ),
        ),
      );
      await t.enterText(find.byType(TextField).at(0), '01-02-2008');
      await t.pump();
      // Changed on purpose in fix round 2: a pasted full date is distributed.
      expect(c.day.text, '01');
      expect(c.month.text, '02');
      expect(c.year.text, '2008');
      expect(c.validate(now: now).isValid, isTrue);
    });

    testWidgets('paste of a full date into the year field is capped at 4',
        (t) async {
      final c = DobController();
      addTearDown(c.dispose);
      await pdPump(
        t,
        Scaffold(
          body: Padding(
            padding: const EdgeInsets.all(20),
            child: DobField(controller: c, accent: const Color(0xFFFF6A00)),
          ),
        ),
      );
      await t.enterText(find.byType(TextField).at(2), '01022008');
      await t.pump();
      expect(c.year.text, '0102');
    });
  });

  group('under-16 boundary at UTC midnight', () {
    test('turning 16 at 00:00 UTC is allowed', () {
      expect(err('20', '11', '2010', at: DateTime.utc(2026, 11, 20)), isNull);
    });

    test('one millisecond before UTC midnight is still 15 (refused)', () {
      expect(
          err('20', '11', '2010',
              at: DateTime.utc(2026, 11, 19, 23, 59, 59, 999)),
          DobError.under16);
    });

    test('the service check agrees with the parser at the same instants', () {
      final dob = DateTime(2010, 11, 20);
      expect(
          UserPrivateDetailsService.isOldEnough(dob,
              now: DateTime.utc(2026, 11, 20)),
          isTrue);
      expect(
          UserPrivateDetailsService.isOldEnough(dob,
              now: DateTime.utc(2026, 11, 19, 23, 59, 59, 999)),
          isFalse);
    });

    test('the day after 16 today is also accepted (no lower bound drift)', () {
      expect(err('21', '11', '2010', at: DateTime.utc(2026, 11, 21)), isNull);
    });
  });
}
