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

  static String label(String? code) {
    switch ((code ?? '').toLowerCase()) {
      case scheduleConflict:
        return 'Schedule conflict';
      case scopeMismatch:
        return 'Scope does not match agreement';
      case siteOrSafety:
        return 'Site or safety concern';
      case personalEmergency:
        return 'Personal emergency';
      case clientIssue:
        return 'Issue with client / communication';
      case other:
        return 'Other';
      default:
        return 'Not specified';
    }
  }

  static String statusLabel(String? status) {
    switch ((status ?? '').toLowerCase()) {
      case 'cancellation_requested':
        return 'Cancellation pending';
      case 'cancelled':
        return 'Cancelled';
      case 'active':
        return 'Active';
      case 'pending':
        return 'Pending';
      case 'delivered':
        return 'Delivered';
      case 'completed':
        return 'Completed';
      default:
        if (status == null || status.isEmpty) return 'Unknown';
        return '${status[0].toUpperCase()}${status.length > 1 ? status.substring(1) : ''}';
    }
  }

  static const int minNoteLength = 20;
}
