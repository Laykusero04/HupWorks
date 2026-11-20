import 'package:flutter_test/flutter_test.dart';
import 'package:freelancer/core/utils/dob_input.dart';

void main() {
  // "Today" in UTC.
  final now = DateTime.utc(2026, 11, 20, 12);

  DobError? err(String d, String m, String y, {DateTime? at}) =>
      validateDob(d, m, y, now: at ?? now).error;

  test('empty / partial / not a real date', () {
    expect(err('', '', ''), DobError.empty);
    expect(err(' ', ' ', ' '), DobError.empty);
    expect(err('1', '', '2000'), DobError.invalid);
    expect(err('aa', '01', '2000'), DobError.invalid);
    expect(err('32', '01', '2000'), DobError.invalid);
    expect(err('00', '01', '2000'), DobError.invalid);
    expect(err('10', '13', '2000'), DobError.invalid);
    expect(err('31', '04', '2000'), DobError.invalid);
    expect(err('10', '10', '99'), DobError.invalid);
    expect(err('10', '10', '20000'), DobError.invalid);
    expect(err('31', '12', '1899'), DobError.invalid);
  });

  test('leap day: 29 Feb real only in leap years', () {
    expect(err('29', '02', '2000'), isNull);
    expect(err('29', '02', '1900'), DobError.invalid); // 1900 not a leap year
    expect(err('29', '02', '2001'), DobError.invalid);
  });

  test('future date', () {
    expect(err('21', '11', '2026'), DobError.future);
    expect(err('01', '01', '2030'), DobError.future);
  });

  test('16th birthday boundary (turning 16 today is allowed)', () {
    expect(err('20', '11', '2010'), isNull); // exactly 16 today
    expect(err('21', '11', '2010'), DobError.under16); // 15y 364d
    expect(err('19', '11', '2010'), isNull);
    expect(err('20', '11', '2026'), DobError.under16); // born today
  });

  test('leap-day birthday: 16 on 29 Feb 2024', () {
    // Born 29 Feb 2008 -> 16 on 29 Feb 2024.
    expect(err('29', '02', '2008', at: DateTime.utc(2024, 2, 28)),
        DobError.under16);
    expect(err('29', '02', '2008', at: DateTime.utc(2024, 2, 29)), isNull);
  });

  test('result carries the date when valid', () {
    final r = validateDob('14', '03', '1998', now: now);
    expect(r.isValid, isTrue);
    expect(r.date, DateTime(1998, 3, 14));
  });

  test('UTC basis: 23:59:59 vs 00:00 UTC around the birthday', () {
    expect(err('20', '11', '2010', at: DateTime.utc(2026, 11, 19, 23, 59, 59)),
        DobError.under16);
    expect(
        err('20', '11', '2010', at: DateTime.utc(2026, 11, 20, 0, 0)), isNull);
  });
}
