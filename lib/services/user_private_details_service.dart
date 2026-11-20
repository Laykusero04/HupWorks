import 'package:freelancer/core/utils/age_check.dart';
import 'package:freelancer/data/models/user_private_details.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

/// Which field failed client-side validation. Never carries the value.
enum PrivateDetailsField {
  legalName,
  dateOfBirth,
  streetAddress,
  postalCode,
  consentVersion,
}

class PrivateDetailsValidationException implements Exception {
  final PrivateDetailsField field;
  const PrivateDetailsValidationException(this.field);

  @override
  String toString() => 'PrivateDetailsValidationException(${field.name})';
}

/// Owner-only private personal details (T-0172). Reads and writes only the
/// signed-in user's own row in `user_private_details`. Values are never logged.
///
/// Validation mirrors the DB checks in migration 0060 so bad input is rejected
/// before a request is sent (the DB remains the authority).
class UserPrivateDetailsService {
  static SupabaseClient get _client => Supabase.instance.client;
  static const table = 'user_private_details';

  static const minAgeYears = kMinimumAgeYears;
  static const maxLegalNameLength = 200;
  static const maxStreetLength = 300;
  static const maxConsentVersionLength = 64;

  // NL: 4 digits (first not 0), optional space, 2 letters. Same as the DB check.
  static final _nlPostal = RegExp(r'^[1-9][0-9]{3} ?[A-Za-z]{2}$');

  /// True when [dob] is at least [minAgeYears] on [now] and not before 1900.
  /// Same UTC-date basis as the DB check, see `lib/core/utils/age_check.dart`.
  static bool isOldEnough(DateTime dob, {DateTime? now}) =>
      isAtLeast16(dob, now: now) && dob.year >= 1900;

  static bool isValidNlPostalCode(String value) =>
      _nlPostal.hasMatch(value.trim());

  /// "1234ab" -> "1234 AB".
  static String normalizeNlPostalCode(String value) {
    final t = value.trim().replaceAll(RegExp(r'\s+'), '').toUpperCase();
    return t.length == 6
        ? '${t.substring(0, 4)} ${t.substring(4)}'
        : value.trim();
  }

  static String _dateOnly(DateTime d) => '${d.year.toString().padLeft(4, '0')}-'
      '${d.month.toString().padLeft(2, '0')}-'
      '${d.day.toString().padLeft(2, '0')}';

  /// Own row, or null when none exists yet (rows are created lazily).
  static Future<UserPrivateDetails?> getMine() async {
    final user = _client.auth.currentUser;
    if (user == null) throw Exception('Not logged in');

    final row = await _client
        .from(table)
        .select(UserPrivateDetails.selectColumns)
        .eq('user_id', user.id)
        .maybeSingle();
    if (row == null) return null;
    return UserPrivateDetails.fromJson(Map<String, dynamic>.from(row));
  }

  /// Creates or updates the signed-in user's row. Only the fields you pass are
  /// written (null = leave unchanged). To clear optional fields put them in
  /// [clear]; [PrivateDetailsField.consentVersion] clears consent (the server
  /// then also clears `consented_at`). Passing a value and clearing the same
  /// field is an [ArgumentError] (programmer error).
  ///
  /// Passing [consentVersion] records consent; `consented_at` is set by the
  /// database trigger, never by the client. Throws
  /// [PrivateDetailsValidationException] before any request when a value fails
  /// the DB rules.
  static Future<void> upsertMine({
    String? legalName,
    DateTime? dateOfBirth,
    String? streetAddress,
    String? postalCode,
    String? consentVersion,
    Set<PrivateDetailsField> clear = const {},
    DateTime? now,
  }) async {
    final user = _client.auth.currentUser;
    if (user == null) throw Exception('Not logged in');

    final given = <PrivateDetailsField, Object?>{
      PrivateDetailsField.legalName: legalName,
      PrivateDetailsField.dateOfBirth: dateOfBirth,
      PrivateDetailsField.streetAddress: streetAddress,
      PrivateDetailsField.postalCode: postalCode,
      PrivateDetailsField.consentVersion: consentVersion,
    };
    for (final f in clear) {
      if (given[f] != null) {
        throw ArgumentError('Cannot both set and clear ${f.name}');
      }
    }

    final payload = <String, dynamic>{'user_id': user.id};

    if (clear.contains(PrivateDetailsField.legalName)) {
      payload['legal_name'] = null;
    }
    if (clear.contains(PrivateDetailsField.dateOfBirth)) {
      payload['date_of_birth'] = null;
    }
    if (clear.contains(PrivateDetailsField.streetAddress)) {
      payload['street_address'] = null;
    }
    if (clear.contains(PrivateDetailsField.postalCode)) {
      payload['postal_code'] = null;
    }
    if (clear.contains(PrivateDetailsField.consentVersion)) {
      payload['consent_version'] = null;
      payload['consented_at'] = null;
    }

    if (legalName != null) {
      final v = legalName.trim();
      if (v.isEmpty || v.length > maxLegalNameLength) {
        throw const PrivateDetailsValidationException(
            PrivateDetailsField.legalName);
      }
      payload['legal_name'] = v;
    }
    if (dateOfBirth != null) {
      if (!isOldEnough(dateOfBirth, now: now)) {
        throw const PrivateDetailsValidationException(
            PrivateDetailsField.dateOfBirth);
      }
      payload['date_of_birth'] = _dateOnly(dateOfBirth);
    }
    if (streetAddress != null) {
      final v = streetAddress.trim();
      if (v.isEmpty || v.length > maxStreetLength) {
        throw const PrivateDetailsValidationException(
            PrivateDetailsField.streetAddress);
      }
      payload['street_address'] = v;
    }
    if (postalCode != null) {
      if (!isValidNlPostalCode(postalCode)) {
        throw const PrivateDetailsValidationException(
            PrivateDetailsField.postalCode);
      }
      payload['postal_code'] = normalizeNlPostalCode(postalCode);
    }
    if (consentVersion != null) {
      final v = consentVersion.trim();
      if (v.isEmpty || v.length > maxConsentVersionLength) {
        throw const PrivateDetailsValidationException(
            PrivateDetailsField.consentVersion);
      }
      // consented_at is set server-side by the trigger; never sent.
      payload['consent_version'] = v;
    }

    await _client.from(table).upsert(payload, onConflict: 'user_id');
  }
}
