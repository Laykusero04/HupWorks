import 'package:flutter/material.dart';
import 'package:freelancer/screen/widgets/constant.dart';
import 'package:freelancer/services/verification_service.dart';

/// Compact verification status chip for seller profile / drawer.
class VerificationStatusBadge extends StatelessWidget {
  const VerificationStatusBadge({
    super.key,
    required this.status,
    this.score,
    this.onTap,
    this.compact = false,
    this.showScore = true,
  });

  final String status;
  final VerificationScore? score;
  final VoidCallback? onTap;
  final bool compact;
  final bool showScore;

  @override
  Widget build(BuildContext context) {
    final info = _infoFor(status);
    final score = this.score ?? VerificationScore.fromStatus(status);
    final child = Container(
      padding: EdgeInsets.symmetric(
        horizontal: compact ? 8 : 10,
        vertical: compact ? 4 : 6,
      ),
      decoration: BoxDecoration(
        color: info.bg,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: info.fg.withValues(alpha: 0.35)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(info.icon, size: compact ? 14 : 16, color: info.fg),
          const SizedBox(width: 6),
          Text(
            showScore ? '${info.label} · ${score.total}/100' : info.label,
            style: kTextStyle.copyWith(
              color: info.fg,
              fontWeight: FontWeight.w600,
              fontSize: compact ? 11 : 12,
            ),
          ),
          if (onTap != null) ...[
            const SizedBox(width: 4),
            Icon(Icons.chevron_right, size: 16, color: info.fg),
          ],
        ],
      ),
    );

    if (onTap == null) return child;
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(20),
      child: child,
    );
  }

  static _BadgeInfo _infoFor(String status) {
    switch (status) {
      case 'verified':
        return const _BadgeInfo(
          label: 'Verified',
          icon: Icons.verified,
          fg: Color(0xFF0B7A3B),
          bg: Color(0xFFE7FFED),
        );
      case 'pending':
        return const _BadgeInfo(
          label: 'Pending',
          icon: Icons.hourglass_top_rounded,
          fg: Color(0xFFB86E00),
          bg: Color(0xFFFFF4E0),
        );
      case 'rejected':
        return const _BadgeInfo(
          label: 'Rejected',
          icon: Icons.cancel_outlined,
          fg: Color(0xFFC62828),
          bg: Color(0xFFFFEBEE),
        );
      default:
        return const _BadgeInfo(
          label: 'Not verified',
          icon: Icons.shield_outlined,
          fg: Color(0xFF546E7A),
          bg: Color(0xFFECEFF1),
        );
    }
  }
}

class _BadgeInfo {
  const _BadgeInfo({
    required this.label,
    required this.icon,
    required this.fg,
    required this.bg,
  });

  final String label;
  final IconData icon;
  final Color fg;
  final Color bg;
}
