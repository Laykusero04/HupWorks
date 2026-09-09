import 'package:freelancer/l10n/app_localizations.dart';

/// Hire-history trust tiers for employers (Option D — no KYC).
enum EmployerStanding {
  newEmployer,
  activeHirer,
  trustedHirer,
  establishedHirer,
}

extension EmployerStandingX on EmployerStanding {
  String label(AppLocalizations l10n) => switch (this) {
        EmployerStanding.newEmployer => l10n.employerStandingNew,
        EmployerStanding.activeHirer => l10n.employerStandingActive,
        EmployerStanding.trustedHirer => l10n.employerStandingTrusted,
        EmployerStanding.establishedHirer => l10n.employerStandingEstablished,
      };
}

class EmployerStandingResolver {
  EmployerStandingResolver._();

  /// [completedPaidHires] = orders where client paid (payment_received_at set)
  /// or status completed — callers pass the count they already have.
  static EmployerStanding resolve({required int completedPaidHires}) {
    if (completedPaidHires >= 20) return EmployerStanding.establishedHirer;
    if (completedPaidHires >= 5) return EmployerStanding.trustedHirer;
    if (completedPaidHires >= 1) return EmployerStanding.activeHirer;
    return EmployerStanding.newEmployer;
  }
}
