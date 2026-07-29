import 'package:freelancer/l10n/app_localizations.dart';

/// Per-job attendance policy (see `job_posts.attendance_mode`).
class AttendanceMode {
  AttendanceMode._();

  static const qrInOut = 'qr_in_out';
  static const qrOnce = 'qr_once';
  static const selfReport = 'self_report';
  static const disabled = 'disabled';

  static String normalize(Object? raw) {
    final v = (raw as String?)?.trim().toLowerCase() ?? '';
    switch (v) {
      case qrOnce:
      case selfReport:
      case disabled:
        return v;
      case qrInOut:
      default:
        return qrInOut;
    }
  }

  static String effectiveForJobPost(Map<String, dynamic>? jobPost) {
    if (jobPost == null) return disabled;
    final locationType = (jobPost['location_type'] as String?)?.trim();
    if (locationType != 'On-site') return disabled;
    return normalize(jobPost['attendance_mode']);
  }

  static bool canUseQr(String mode) => mode == qrInOut || mode == qrOnce;

  static bool canSelfReport(String mode) => mode == selfReport;

  static bool isEnabled(String mode) => mode != disabled;

  static String label(String mode, [AppLocalizations? l10n]) {
    switch (normalize(mode)) {
      case qrOnce:
        return l10n?.attendanceModeQrOnce ?? 'QR check-in (once per day)';
      case selfReport:
        return l10n?.attendanceModeSelfReport ?? 'Self-report in app';
      case disabled:
        return l10n?.attendanceModeDisabled ?? 'Attendance off';
      case qrInOut:
      default:
        return l10n?.attendanceModeQrInOut ?? 'QR clock in & out';
    }
  }

  static String clientHint(String mode, [AppLocalizations? l10n]) {
    switch (normalize(mode)) {
      case qrOnce:
        return l10n?.attendanceClientHintQrOnce ??
            'Post a QR at the site. Workers scan once per day to check in.';
      case selfReport:
        return l10n?.attendanceClientHintSelfReport ??
            'Workers clock in and out in the app — no QR needed.';
      case disabled:
        return l10n?.attendanceClientHintDisabled ??
            'Attendance tracking is turned off for this job.';
      case qrInOut:
      default:
        return l10n?.attendanceClientHintQrInOut ??
            'Post a QR at the site. Workers scan to clock in and clock out.';
    }
  }

  static String freelancerHint(String mode, [AppLocalizations? l10n]) {
    switch (normalize(mode)) {
      case qrOnce:
        return l10n?.attendanceFreelancerHintQrOnce ??
            'Scan the site QR once when you arrive.';
      case selfReport:
        return l10n?.attendanceFreelancerHintSelfReport ??
            'Tap clock in when you start and clock out when you leave.';
      case disabled:
        return l10n?.attendanceFreelancerHintDisabled ??
            'Your client has not enabled attendance for this job.';
      case qrInOut:
      default:
        return l10n?.attendanceFreelancerHintQrInOut ??
            'Scan the site QR to clock in and clock out.';
    }
  }

  static String onboardingSectionBody(String mode, [AppLocalizations? l10n]) {
    switch (normalize(mode)) {
      case qrOnce:
        return l10n?.attendanceOnboardingQrOnce ??
            'When you arrive, open Attendance in HupWorks and scan the QR code posted on site. You only need to check in once per day.';
      case selfReport:
        return l10n?.attendanceOnboardingSelfReport ??
            'Open Attendance in HupWorks on this contract and tap Clock in when you start and Clock out when you leave. No QR scan is required.';
      case disabled:
        return l10n?.attendanceOnboardingDisabled ??
            'Attendance is not tracked in the app for this job. Follow your supervisor\'s instructions on site.';
      case qrInOut:
      default:
        return l10n?.attendanceOnboardingQrInOut ??
            'Open Attendance in HupWorks and scan the QR code at the job site to clock in when you arrive and clock out when you leave.';
    }
  }

  /// Default mode when creating an on-site vs remote job.
  static String defaultForLocationType(String? locationType) {
    if (locationType == 'On-site') return qrInOut;
    return disabled;
  }
}
