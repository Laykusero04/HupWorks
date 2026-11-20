/// Minimum age rules shared by signup, the personal-details step and the
/// private-details service (T-0172).
///
/// Calendar basis: the UTC date. The database check on
/// `user_private_details.date_of_birth` (migration 0060) uses
/// `(now() at time zone 'utc')::date`, so the app uses the same basis to avoid
/// accept/refuse drift around midnight.
const int kMinimumAgeYears = 16;

/// True when a person born on [dob] (a calendar date) is at least
/// [kMinimumAgeYears] old.
///
/// [now] defaults to the current instant converted to UTC. When you pass [now]
/// its calendar fields are used as given, so pass a UTC value (or a date you
/// already consider the "UTC today"); tests do this to stay timezone-proof.
bool isAtLeast16(DateTime dob, {DateTime? now}) {
  final n = now ?? DateTime.now().toUtc();
  final cutoff = DateTime(n.year - kMinimumAgeYears, n.month, n.day);
  final d = DateTime(dob.year, dob.month, dob.day);
  return !d.isAfter(cutoff);
}
