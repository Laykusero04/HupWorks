/// What an employer may do about posting jobs, from their verification state
/// (T-0171). Admin approval of the employer verification is required.
///
/// Owner decision 2026-11-20 ("ever approved"): once an admin approved the
/// employer, posting stays allowed even if they later edit their documents
/// (the record goes back to pending for re-review, which does not block).
/// Marker: `employer_verifications.first_verified_at` (set by the database,
/// never writable by the app). Otherwise the state comes from
/// `profiles.verification_status`, which the database keeps in sync with
/// `employer_verifications.status` (migration 0043 trigger). The server
/// enforces the real rule on `job_posts` INSERT (migration 0061).
enum EmployerPostAccess {
  /// Approved by an admin: may post.
  approved,

  /// Submitted, waiting for an admin.
  pending,

  /// Admin rejected the last submission.
  rejected,

  /// Nothing submitted yet.
  required,
}

class EmployerVerificationGate {
  EmployerVerificationGate._();

  /// The database value that means "admin approved".
  static const approvedStatus = 'verified';

  /// [verification] is the employer's own `employer_verifications` row, if any.
  static EmployerPostAccess accessFor(
    Map<String, dynamic>? profile, {
    Map<String, dynamic>? verification,
  }) {
    if (verification?['first_verified_at'] != null) {
      return EmployerPostAccess.approved;
    }
    final raw = (profile?['verification_status'] as String?)?.trim();
    switch (raw) {
      case approvedStatus:
        return EmployerPostAccess.approved;
      case 'pending':
        return EmployerPostAccess.pending;
      case 'rejected':
        return EmployerPostAccess.rejected;
      default:
        return EmployerPostAccess.required;
    }
  }

  static bool canPost(
    Map<String, dynamic>? profile, {
    Map<String, dynamic>? verification,
  }) =>
      accessFor(profile, verification: verification) ==
      EmployerPostAccess.approved;

  /// True when the server refused the insert because the `job_posts` INSERT
  /// policy (migration 0061) failed, i.e. the employer is not verified.
  ///
  /// Matches the row-level-security policy violation text
  /// ("new row violates row-level security policy for table job_posts",
  /// SQLSTATE 42501). A bare 42501 is NOT enough: a missing GRANT also uses
  /// 42501 but says "permission denied for table ...", and must show the raw
  /// error instead of a misleading "verify" message.
  static bool isBlockedByServer(Object error) {
    return error.toString().toLowerCase().contains('row-level security');
  }
}
