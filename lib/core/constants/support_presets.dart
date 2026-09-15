import 'package:freelancer/data/models/support_preset_model.dart';
import 'package:freelancer/l10n/app_localizations.dart';

/// FAQ presets for Help & Support, localized via [AppLocalizations].
abstract final class SupportPresets {
  static List<SupportPreset> all(AppLocalizations l10n) => [
        SupportPreset(
          question: l10n.faqDiffMessagesQ,
          answer: l10n.faqDiffMessagesA,
        ),
        SupportPreset(
          question: l10n.faqResetPasswordQ,
          answer: l10n.faqResetPasswordA,
        ),
        SupportPreset(
          question: l10n.faqUpdateProfileQ,
          answer: l10n.faqUpdateProfileA,
        ),
        SupportPreset(
          question: l10n.faqPostJobQ,
          audience: SupportPresetAudience.client,
          answer: l10n.faqPostJobA,
        ),
        SupportPreset(
          question: l10n.faqTrackOrderQ,
          audience: SupportPresetAudience.client,
          answer: l10n.faqTrackOrderA,
        ),
        SupportPreset(
          question: l10n.faqMessageSellerQ,
          audience: SupportPresetAudience.client,
          answer: l10n.faqMessageSellerA,
        ),
        SupportPreset(
          question: l10n.faqReportSellerQ,
          audience: SupportPresetAudience.client,
          answer: l10n.faqReportSellerA,
        ),
        SupportPreset(
          question: l10n.faqPaymentsClientQ,
          audience: SupportPresetAudience.client,
          answer: l10n.faqPaymentsClientA,
        ),
        SupportPreset(
          question: l10n.faqReportClientQ,
          audience: SupportPresetAudience.seller,
          answer: l10n.faqReportClientA,
        ),
        SupportPreset(
          question: l10n.faqApplyJobQ,
          audience: SupportPresetAudience.seller,
          answer: l10n.faqApplyJobA,
        ),
        SupportPreset(
          question: l10n.faqGetPaidQ,
          audience: SupportPresetAudience.seller,
          answer: l10n.faqGetPaidA,
        ),
        SupportPreset(
          question: l10n.faqAttendanceQ,
          audience: SupportPresetAudience.seller,
          answer: l10n.faqAttendanceA,
        ),
      ];

  static List<SupportPreset> forRole(AppLocalizations l10n, String? role) {
    final presets = all(l10n);
    if (role == 'client') {
      return presets
          .where((p) =>
              p.audience == SupportPresetAudience.all ||
              p.audience == SupportPresetAudience.client)
          .toList();
    }
    if (role == 'seller') {
      return presets
          .where((p) =>
              p.audience == SupportPresetAudience.all ||
              p.audience == SupportPresetAudience.seller)
          .toList();
    }
    return presets
        .where((p) => p.audience == SupportPresetAudience.all)
        .toList();
  }
}
