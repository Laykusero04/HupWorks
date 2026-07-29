import 'package:freelancer/l10n/app_localizations.dart';

/// Cancellation reason codes stored on `orders.cancellation_reason_code`.
class OrderCancellationReason {
  OrderCancellationReason._();

  static const scheduleConflict = 'schedule_conflict';
  static const scopeMismatch = 'scope_mismatch';
  static const siteOrSafety = 'site_or_safety';
  static const personalEmergency = 'personal_emergency';
  static const clientIssue = 'client_issue';
  static const other = 'other';

  static const List<String> codes = [
    scheduleConflict,
    scopeMismatch,
    siteOrSafety,
    personalEmergency,
    clientIssue,
    other,
  ];

  static String label(String? code, [AppLocalizations? l10n]) {
    switch ((code ?? '').toLowerCase()) {
      case scheduleConflict:
        return l10n?.cancelReasonScheduleConflict ?? 'Schedule conflict';
      case scopeMismatch:
        return l10n?.cancelReasonScopeMismatch ??
            'Scope does not match agreement';
      case siteOrSafety:
        return l10n?.cancelReasonSiteOrSafety ?? 'Site or safety concern';
      case personalEmergency:
        return l10n?.cancelReasonPersonalEmergency ?? 'Personal emergency';
      case clientIssue:
        return l10n?.cancelReasonClientIssue ??
            'Issue with client / communication';
      case other:
        return l10n?.cancelReasonOther ?? 'Other';
      default:
        return l10n?.notSpecified ?? 'Not specified';
    }
  }

  static String statusLabel(String? status, [AppLocalizations? l10n]) {
    switch ((status ?? '').toLowerCase()) {
      case 'cancellation_requested':
        return l10n?.orderStatusCancellationPending ?? 'Cancellation pending';
      case 'cancelled':
        return l10n?.orderStatusCancelled ?? 'Cancelled';
      case 'active':
        return l10n?.orderStatusActive ?? 'Active';
      case 'pending':
        return l10n?.orderStatusPending ?? 'Pending';
      case 'delivered':
        return l10n?.orderStatusDelivered ?? 'Delivered';
      case 'completed':
        return l10n?.orderStatusCompleted ?? 'Completed';
      default:
        if (status == null || status.isEmpty) {
          return l10n?.unknown ?? 'Unknown';
        }
        return '${status[0].toUpperCase()}${status.length > 1 ? status.substring(1) : ''}';
    }
  }

  static const int minNoteLength = 20;
}
