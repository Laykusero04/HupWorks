import 'package:freelancer/data/models/hire_onboarding_packet_model.dart';
import 'package:freelancer/l10n/app_localizations.dart';

/// Localised title for a packet section. Default sections are resolved by
/// key (stored titles are empty or the legacy English text); custom titles
/// fall back to what was stored.
extension HireOnboardingSectionTitle on HireOnboardingSection {
  String localizedTitle(AppLocalizations l10n) {
    switch (key) {
      case 'where':
        return l10n.onboardingSectionWhere;
      case 'when':
        return l10n.onboardingSectionWhen;
      case 'who':
        return l10n.onboardingSectionWho;
      case 'access':
        return l10n.onboardingSectionAccess;
      case 'rules':
        return l10n.onboardingSectionRules;
      case 'attendance':
        return l10n.attendance;
      case 'emergency':
        return l10n.onboardingSectionEmergency;
    }
    return title.trim().isEmpty ? l10n.onboardingSectionGeneric : title;
  }
}
