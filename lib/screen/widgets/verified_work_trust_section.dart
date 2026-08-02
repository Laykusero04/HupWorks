import 'package:flutter/material.dart';
import 'package:freelancer/data/models/seller_work_trust_model.dart';
import 'package:freelancer/l10n/l10n.dart';

import 'constant.dart';
import 'profile_detail_theme.dart';

/// Attendance-backed trust stats for client-facing seller profiles.
class VerifiedWorkTrustSection extends StatelessWidget {
  const VerifiedWorkTrustSection({
    super.key,
    required this.trust,
    this.accentColor = kPrimaryColor,
  });

  final SellerWorkTrust trust;
  final Color accentColor;

  static String formatCompletedMonth(AppLocalizations l10n, String yearMonth) {
    final parts = yearMonth.split('-');
    if (parts.length != 2) return yearMonth;
    final year = int.tryParse(parts[0]);
    final month = int.tryParse(parts[1]);
    if (year == null || month == null || month < 1 || month > 12) {
      return yearMonth;
    }
    const months = [
      'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
      'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec',
    ];
    return l10n.workTrustCompletedMonthLabel(months[month - 1], year);
  }

  @override
  Widget build(BuildContext context) {
    if (!trust.shouldShowSection) return const SizedBox.shrink();

    final l10n = context.l10n;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            l10n.workTrustSectionTitle,
            style: kTextStyle.copyWith(
              color: accentColor,
              fontWeight: FontWeight.bold,
              fontSize: 16,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            l10n.workTrustSectionSubtitle,
            style: kTextStyle.copyWith(color: kSubTitleColor, fontSize: 12, height: 1.35),
          ),
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 8),
            decoration: ProfileDetailTheme.statsPanel(accent: accentColor),
            child: Row(
              children: [
                Expanded(
                  child: _stat(
                    '${trust.completedOnsiteJobs}',
                    l10n.workTrustStatCompletedOnsite,
                  ),
                ),
                _divider(),
                Expanded(
                  child: _stat(
                    '${trust.verifiedCheckins}',
                    l10n.workTrustStatVerifiedCheckins,
                  ),
                ),
                _divider(),
                Expanded(
                  child: _stat(
                    '${trust.verifiedShiftDays}',
                    l10n.workTrustStatVerifiedDays,
                  ),
                ),
              ],
            ),
          ),
          if (trust.highlights.isNotEmpty) ...[
            const SizedBox(height: 16),
            Text(
              l10n.workTrustHighlightsTitle,
              style: kTextStyle.copyWith(
                color: kNeutralColor,
                fontWeight: FontWeight.w600,
                fontSize: 14,
              ),
            ),
            const SizedBox(height: 8),
            ...trust.highlights.map((h) => _highlightRow(context, h)),
          ],
        ],
      ),
    );
  }

  Widget _stat(String value, String label) {
    return Column(
      children: [
        Text(
          value,
          textAlign: TextAlign.center,
          style: kTextStyle.copyWith(
            color: accentColor,
            fontWeight: FontWeight.bold,
            fontSize: 18,
          ),
        ),
        const SizedBox(height: 2),
        Text(
          label,
          textAlign: TextAlign.center,
          style: kTextStyle.copyWith(color: kSubTitleColor, fontSize: 11),
        ),
      ],
    );
  }

  Widget _divider() => Container(
        width: 1,
        height: 36,
        color: accentColor.withValues(alpha: 0.22),
        margin: const EdgeInsets.symmetric(horizontal: 4),
      );

  Widget _highlightRow(BuildContext context, WorkTrustHighlight h) {
    final l10n = context.l10n;
    final monthLabel = h.completedMonth.isNotEmpty
        ? formatCompletedMonth(l10n, h.completedMonth)
        : '';

    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        decoration: ProfileDetailTheme.cardOnPage(accent: accentColor),
        child: Row(
          children: [
            Icon(
              h.hadAttendance ? Icons.verified_outlined : Icons.work_outline,
              size: 20,
              color: h.hadAttendance ? accentColor : kLightNeutralColor,
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    h.jobTitle,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: kTextStyle.copyWith(
                      fontWeight: FontWeight.w600,
                      fontSize: 13,
                    ),
                  ),
                  if (monthLabel.isNotEmpty)
                    Text(
                      monthLabel,
                      style: kTextStyle.copyWith(
                        color: kLightNeutralColor,
                        fontSize: 11,
                      ),
                    ),
                ],
              ),
            ),
            if (h.hadAttendance)
              Tooltip(
                message: l10n.workTrustAttendanceVerifiedTooltip,
                child: Icon(Icons.check_circle_outline, size: 18, color: accentColor),
              ),
          ],
        ),
      ),
    );
  }
}
