import 'package:equatable/equatable.dart';

/// Owner-only private details (table `user_private_details`, T-0172).
///
/// Never shown to other users and never merged into a public profile model.
/// [toString] is redacted on purpose so values cannot leak into logs.
class UserPrivateDetails extends Equatable {
  final String userId;
  final String? legalName;
  final DateTime? dateOfBirth;
  final String? streetAddress;
  final String? postalCode;
  final String? consentVersion;
  final DateTime? consentedAt;

  const UserPrivateDetails({
    required this.userId,
    this.legalName,
    this.dateOfBirth,
    this.streetAddress,
    this.postalCode,
    this.consentVersion,
    this.consentedAt,
  });

  /// Column list for own-row reads. Keep in sync with [fromJson].
  static const selectColumns =
      'user_id, legal_name, date_of_birth, street_address, postal_code, '
      'consent_version, consented_at';

  factory UserPrivateDetails.fromJson(Map<String, dynamic> json) {
    return UserPrivateDetails(
      userId: json['user_id'] as String? ?? '',
      legalName: _text(json['legal_name']),
      dateOfBirth: _date(json['date_of_birth']),
      streetAddress: _text(json['street_address']),
      postalCode: _text(json['postal_code']),
      consentVersion: _text(json['consent_version']),
      consentedAt: json['consented_at'] == null
          ? null
          : DateTime.tryParse(json['consented_at'] as String),
    );
  }

  bool get hasConsent => consentVersion != null && consentedAt != null;

  /// True when the postal code and street address needed for a contract exist.
  bool get hasAddress => streetAddress != null && postalCode != null;

  static String? _text(Object? v) {
    final s = (v as String?)?.trim();
    return (s == null || s.isEmpty) ? null : s;
  }

  /// `date_of_birth` is a SQL `date` ("1990-05-17"): parse as a calendar date.
  static DateTime? _date(Object? v) {
    if (v is! String || v.length < 10) return null;
    final y = int.tryParse(v.substring(0, 4));
    final m = int.tryParse(v.substring(5, 7));
    final d = int.tryParse(v.substring(8, 10));
    if (y == null || m == null || d == null) return null;
    return DateTime(y, m, d);
  }

  @override
  List<Object?> get props => [
        userId,
        legalName,
        dateOfBirth,
        streetAddress,
        postalCode,
        consentVersion,
        consentedAt,
      ];

  @override
  String toString() => 'UserPrivateDetails(<redacted>)';
}
