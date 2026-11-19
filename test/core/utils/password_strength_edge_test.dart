import 'package:flutter_test/flutter_test.dart';
import 'package:freelancer/core/utils/password_strength.dart';

/// T-0163 QA edge cases for the password strength hint.
/// Expectations come from the rule in password_strength.dart:
///   strong = 8+ with letter+digit+symbol, or 12+ with 3 classes
///   medium = 6+ with 2 classes
///   weak   = everything else (hint only, never blocks submit)
/// Test data is fake.
void main() {
  group('length boundaries', () {
    test('5 chars, all four classes is still weak (below 6)', () {
      expect(passwordStrength('Ab1!x'), PasswordStrength.weak);
    });

    test('6 chars, two classes is medium', () {
      expect(passwordStrength('Ab1!xy'), PasswordStrength.medium);
    });

    test('6 chars, one class is weak', () {
      expect(passwordStrength('abcdef'), PasswordStrength.weak);
    });

    test('7 chars, letter+digit+symbol is medium (below 8)', () {
      expect(passwordStrength('abc1!xy'), PasswordStrength.medium);
    });

    test('8 chars, letter+digit+symbol is strong', () {
      expect(passwordStrength('abcdef1!'), PasswordStrength.strong);
    });

    test('8 chars, letters only is weak', () {
      expect(passwordStrength('abcdefgh'), PasswordStrength.weak);
    });

    test('11 chars, three classes without symbol is medium (below 12)', () {
      expect(passwordStrength('Abcdefghi1k'), PasswordStrength.medium);
    });

    test('12 chars, three classes without symbol is strong', () {
      expect(passwordStrength('Abcdefghij1k'), PasswordStrength.strong);
    });

    test('12 chars, two classes is medium', () {
      expect(passwordStrength('abcdefghijk1'), PasswordStrength.medium);
    });
  });

  group('each class combination at 8 chars', () {
    final cases = <String, PasswordStrength>{
      'abcdefgh': PasswordStrength.weak, // lower only
      'ABCDEFGH': PasswordStrength.weak, // upper only
      '12345678': PasswordStrength.weak, // digit only
      '!@#\$%^&*': PasswordStrength.weak, // symbol only
      'AbcdefGh': PasswordStrength.medium, // lower+upper
      '12345!@#': PasswordStrength.medium, // digit+symbol, no letter
      'Abcdef12': PasswordStrength.medium, // lower+upper+digit, no symbol
      'abcdef1!': PasswordStrength.strong, // lower+digit+symbol
      'ABCDEF1!': PasswordStrength.strong, // upper+digit+symbol
      'Abcdef1!': PasswordStrength.strong, // all four
    };
    cases.forEach((pw, expected) {
      test('"$pw" -> ${expected.name}', () {
        expect(passwordStrength(pw), expected);
      });
    });
  });

  test('empty string is the empty state, not weak', () {
    expect(passwordStrength(''), PasswordStrength.empty);
  });

  test('whitespace-only 6 spaces counts as one class (weak)', () {
    expect(passwordStrength('      '), PasswordStrength.weak);
  });

  test('a space counts as a symbol (current behaviour)', () {
    // Documents what the code does; a space is [^A-Za-z0-9].
    expect(passwordStrength('abcdef1 '), PasswordStrength.strong);
  });

  test('very long password (500 chars) is strong without error', () {
    final pw = '${'a' * 498}1!';
    expect(pw.length, 500);
    expect(passwordStrength(pw), PasswordStrength.strong);
  });

  test('very long single-class password (500 chars) is weak', () {
    expect(passwordStrength('a' * 500), PasswordStrength.weak);
  });
}
