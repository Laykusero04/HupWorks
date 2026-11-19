import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:freelancer/data/models/profile_model.dart';
import 'package:freelancer/services/profile_service.dart';

void main() {
  group('public profile helpers (FIX B)', () {
    test('public location is city/country, never a street address', () {
      expect(
        ProfileService.publicLocationFromProfile({
          'city': ' Leiden ',
          'country': 'NL',
          'address': '1 Secret Street',
        }),
        'Leiden, NL',
      );
      expect(ProfileService.publicLocationFromProfile({'city': 'Leiden'}),
          'Leiden');
      expect(
          ProfileService.publicLocationFromProfile(
              {'city': ' ', 'country': null}),
          isNull);
    });

    test('public age only comes from server-provided age_years', () {
      expect(ProfileService.publicAgeFromProfile({'age_years': 34}), 34);
      expect(ProfileService.publicAgeFromProfile({'age_years': null}), isNull);
      // A leaked birth date must never be turned into a public age.
      expect(
        ProfileService.publicAgeFromProfile({
          'seller_profiles': {
            'birth_year': 1990,
            'birth_month': 1,
            'birth_day': 1
          }
        }),
        isNull,
      );
    });

    test('show_age defaults to off', () {
      expect(ProfileService.sellerShowAgeFromProfile({}), isFalse);
      expect(
          ProfileService.sellerShowAgeFromProfile({
            'seller_profiles': {'show_age': true}
          }),
          isTrue);
      expect(
          ProfileService.sellerShowAgeFromProfile({
            'seller_profiles': [
              {'show_age': false}
            ]
          }),
          isFalse);
    });
  });

  test('Profile.fromJson accepts a public row without email', () {
    final p = Profile.fromJson({
      'id': 'u1',
      'role': 'seller',
      'name': 'Sam',
      'created_at': '2026-01-01T00:00:00Z',
    });
    expect(p.email, '');
    expect(p.name, 'Sam');
  });

  group(
      'source audit: no client writes of server-owned data, no select * on others',
      () {
    final files = Directory('lib')
        .listSync(recursive: true)
        .whereType<File>()
        .where((f) => f.path.endsWith('.dart') && !f.path.contains('/l10n/'))
        .toList();

    test('no client code updates profiles.rating or balance', () {
      final bad = <String>[];
      final re = RegExp(r"'(rating|balance)'\s*:");
      for (final f in files) {
        final src = f.readAsStringSync();
        for (final m
            in RegExp(r"from\('profiles'\)\s*\.(update|upsert|insert)\(")
                .allMatches(src)) {
          final window =
              src.substring(m.start, (m.start + 400).clamp(0, src.length));
          if (re.hasMatch(window)) bad.add(f.path);
        }
      }
      expect(bad, isEmpty);
    });

    test('no select-all on the profiles / seller_profiles tables or embeds',
        () {
      final bad = <String>[];
      final patterns = [
        RegExp(r"from\('(profiles|seller_profiles)'\)\s*\.select\(\s*\)"),
        RegExp(r"profiles[^'\n]*\(\*\)"),
      ];
      for (final f in files) {
        final src = f.readAsStringSync();
        for (final p in patterns) {
          if (p.hasMatch(src)) bad.add('${f.path} ~ ${p.pattern}');
        }
      }
      expect(bad, isEmpty);
    });

    test('public seller read does not request dob / address columns', () {
      final src = File('lib/services/profile_service.dart').readAsStringSync();
      final start =
          src.indexOf('const columns =', src.indexOf('getPublicSellerProfile'));
      final block = src.substring(start, src.indexOf(';', start));
      expect(block.contains('birth_'), isFalse);
      expect(block.contains('address'), isFalse);
      expect(block.contains('rejection_reason'), isFalse);
    });
  });
}
