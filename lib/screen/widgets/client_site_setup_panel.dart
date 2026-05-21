import 'package:flutter/material.dart';
import 'package:freelancer/core/utils/attendance_mode.dart';
import 'package:freelancer/screen/attendance/attendance_qr_display_screen.dart';
import 'package:freelancer/services/attendance_service.dart';
import 'package:nb_utils/nb_utils.dart';

import 'constant.dart';

/// Compact on-site tools for client order / job screens (instructions + QR).
class ClientSiteSetupPanel extends StatelessWidget {
  final String? onboardingStatus;
  final VoidCallback? onOnboarding;
  final Map<String, dynamic>? jobPost;

  const ClientSiteSetupPanel({
    super.key,
    this.onboardingStatus,
    this.onOnboarding,
    this.jobPost,
  });

  static bool showOnboarding(VoidCallback? onOnboarding) => onOnboarding != null;

  static bool showQr(Map<String, dynamic>? jobPost) {
    if (!AttendanceService.isOnsiteJob(jobPost)) return false;
    if (!AttendanceMode.canUseQr(AttendanceMode.effectiveForJobPost(jobPost))) {
      return false;
    }
    final id = jobPost?['id']?.toString();
    return id != null && id.isNotEmpty;
  }

  static bool shouldShow({
    VoidCallback? onOnboarding,
    Map<String, dynamic>? jobPost,
  }) =>
      showOnboarding(onOnboarding) || showQr(jobPost);

  void _openQr(BuildContext context) {
    final jobPostId = jobPost!['id'].toString();
    final title = (jobPost?['title'] as String?)?.trim().isNotEmpty == true
        ? (jobPost!['title'] as String).trim()
        : 'Job site';
    AttendanceQrDisplayScreen(
      jobPostId: jobPostId,
      jobTitle: title,
    ).launch(context);
  }

  @override
  Widget build(BuildContext context) {
    final showInstructions = showOnboarding(onOnboarding);
    final showQrRow = showQr(jobPost);
    if (!showInstructions && !showQrRow) {
      return const SizedBox.shrink();
    }

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: kPrimaryColor.withValues(alpha: 0.05),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: kBorderColorTextField),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Site setup',
            style: kTextStyle.copyWith(
              color: kNeutralColor,
              fontWeight: FontWeight.w700,
              fontSize: 13,
            ),
          ),
          if (showInstructions) ...[
            const SizedBox(height: 6),
            _SetupRow(
              icon: Icons.menu_book_outlined,
              label: 'First-day',
              status: onboardingStatus ?? '—',
              actionLabel: 'Edit',
              onTap: onOnboarding!,
            ),
          ],
          if (showInstructions && showQrRow)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 4),
              child: Divider(height: 1, color: kBorderColorTextField.withValues(alpha: 0.8)),
            ),
          if (showQrRow) ...[
            if (!showInstructions) const SizedBox(height: 6),
            _SetupRow(
              icon: Icons.qr_code_2_outlined,
              label: 'Attendance QR',
              status: 'Print at site',
              actionLabel: 'Open',
              onTap: () => _openQr(context),
            ),
          ],
        ],
      ),
    );
  }
}

class _SetupRow extends StatelessWidget {
  final IconData icon;
  final String label;
  final String status;
  final String actionLabel;
  final VoidCallback onTap;

  const _SetupRow({
    required this.icon,
    required this.label,
    required this.status,
    required this.actionLabel,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(8),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 4),
        child: Row(
          children: [
            Icon(icon, size: 20, color: kPrimaryColor),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    label,
                    style: kTextStyle.copyWith(
                      color: kNeutralColor,
                      fontWeight: FontWeight.w600,
                      fontSize: 13,
                    ),
                  ),
                  Text(
                    status,
                    style: kTextStyle.copyWith(
                      color: kSubTitleColor,
                      fontSize: 11,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
            Text(
              actionLabel,
              style: kTextStyle.copyWith(
                color: kPrimaryColor,
                fontWeight: FontWeight.w600,
                fontSize: 13,
              ),
            ),
            const SizedBox(width: 2),
            const Icon(Icons.chevron_right, size: 18, color: kPrimaryColor),
          ],
        ),
      ),
    );
  }
}
