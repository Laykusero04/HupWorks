import 'package:freelancer/core/utils/order_cancellation.dart';
import 'package:freelancer/l10n/app_localizations.dart';

/// Localized labels for stored English codes / enums.
class L10nLabels {
  L10nLabels._();

  static const genderMale = 'Male';
  static const genderFemale = 'Female';
  static const genderValues = [genderMale, genderFemale];

  static String gender(AppLocalizations l10n, String value) {
    switch (value) {
      case genderFemale:
        return l10n.genderFemale;
      case genderMale:
      default:
        return l10n.genderMale;
    }
  }

  static const reportCodes = [
    'Harassment or inappropriate behavior',
    'Fake or misleading job',
    'No-show or incomplete work',
    'Payment or contract dispute',
    'Spam or scam',
    'Other reasons',
  ];

  static String reportReason(AppLocalizations l10n, String code) {
    switch (code) {
      case 'Harassment or inappropriate behavior':
        return l10n.reportReasonHarassment;
      case 'Fake or misleading job':
        return l10n.reportReasonFakeJob;
      case 'No-show or incomplete work':
        return l10n.reportReasonNoShow;
      case 'Payment or contract dispute':
        return l10n.reportReasonPaymentDispute;
      case 'Spam or scam':
        return l10n.reportReasonSpam;
      case 'Other reasons':
        return l10n.reportReasonOther;
      // Legacy stored codes (older reports)
      case 'Trademark Violations':
        return l10n.reportReasonTrademark;
      case 'Copyright Violations':
        return l10n.reportReasonCopyright;
      case 'Non original content':
        return l10n.reportReasonNonOriginal;
      default:
        return code;
    }
  }

  static List<String> reportReasonLabels(AppLocalizations l10n) =>
      reportCodes.map((c) => reportReason(l10n, c)).toList();

  static List<String> orderStatusChipLabels(AppLocalizations l10n) => [
        l10n.orderStatusActive,
        l10n.orderStatusPending,
        l10n.orderStatusCompleted,
        l10n.orderStatusCancelled,
      ];

  static String jobType(AppLocalizations l10n, String? type) {
    switch (type) {
      case 'full_time':
        return l10n.fullTime;
      case 'part_time':
        return l10n.partTime;
      case 'gig':
      default:
        return l10n.jobTypeGig;
    }
  }

  static String orderFilterTabLabel(AppLocalizations l10n, String code) {
    if (code == 'all') return l10n.filterAll;
    return OrderCancellationReason.statusLabel(code, l10n);
  }

  static String clientOrderStatusForUi(AppLocalizations l10n, String status) {
    switch (status.toLowerCase()) {
      case 'delivered':
        return l10n.awaitingYourApproval;
      case 'active':
        return l10n.inProgress;
      default:
        return OrderCancellationReason.statusLabel(status, l10n);
    }
  }

  static String formatContractDeadlineRemaining(
    AppLocalizations l10n,
    Duration d,
  ) {
    if (d.inSeconds <= 0) return l10n.contractOverdue;
    if (d.inDays > 0) {
      return l10n.deadlineDaysHoursLeft(
        d.inDays,
        d.inHours.remainder(24),
      );
    }
    if (d.inHours > 0) {
      return l10n.deadlineHoursMinutesLeft(
        d.inHours,
        d.inMinutes.remainder(60),
      );
    }
    return l10n.deadlineMinutesLeft(d.inMinutes);
  }

  static List<({String title, String body})> privacySections(
    AppLocalizations l10n,
  ) =>
      [
        (title: l10n.privacySectionCollectTitle, body: l10n.privacySectionCollectBody),
        (title: l10n.privacySectionUseTitle, body: l10n.privacySectionUseBody),
        (title: l10n.privacySectionShareTitle, body: l10n.privacySectionShareBody),
        (title: l10n.privacySectionChoicesTitle, body: l10n.privacySectionChoicesBody),
        (title: l10n.privacySectionContactTitle, body: l10n.privacySectionContactBody),
      ];

  static String transactionType(AppLocalizations l10n, String? type) {
    switch (type) {
      case 'deposit':
        return l10n.txnTypeDeposit;
      case 'withdrawal':
        return l10n.txnTypeWithdrawal;
      case 'earning':
        return l10n.txnTypeEarning;
      case 'payment':
        return l10n.txnTypePayment;
      default:
        return type ?? '';
    }
  }

  static String jobTypeLabel(AppLocalizations l10n, String? t) {
    switch (t) {
      case 'full_time':
        return l10n.fullTime;
      case 'part_time':
        return l10n.partTime;
      case 'gig':
      default:
        return l10n.jobTypeGig;
    }
  }
}
