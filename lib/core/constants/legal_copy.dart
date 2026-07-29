import 'package:freelancer/l10n/app_localizations.dart';
import 'package:freelancer/l10n/l10n_labels.dart';

/// Shared About / Privacy access via [AppLocalizations].
/// Prefer [L10nLabels.privacySections] and `l10n.aboutHupWorks*` in UI.
@Deprecated('Use AppLocalizations / L10nLabels instead')
class LegalCopy {
  LegalCopy._();

  static String aboutTitle(AppLocalizations l10n) => l10n.aboutHupWorksTitle;
  static String aboutBody(AppLocalizations l10n) => l10n.aboutHupWorksBody;

  static List<({String title, String body})> privacySections(
    AppLocalizations l10n,
  ) =>
      L10nLabels.privacySections(l10n);
}
