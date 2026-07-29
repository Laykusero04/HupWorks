import 'package:flutter/material.dart';
import 'package:freelancer/l10n/l10n.dart';

import 'constant.dart';

/// Read-only average rating + review count (e.g. profile header).
class ProfileRatingSummary extends StatelessWidget {
  const ProfileRatingSummary({
    super.key,
    required this.rating,
    required this.reviewCount,
    this.compact = false,
    /// When true, text is tuned for green/blue [ShellTabHeader] gradients (drawer profile).
    this.onBrandGradient = false,
    /// When set (e.g. seller shell blue), used instead of [kPrimaryColor] for rating value / empty state.
    this.accentColor,
  });

  final double rating;
  final int reviewCount;
  final bool compact;
  final bool onBrandGradient;
  final Color? accentColor;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final starSize = compact ? 15.0 : 18.0;
    final valueStyle = kTextStyle.copyWith(
      color: kNeutralColor,
      fontWeight: FontWeight.w600,
      fontSize: compact ? 12 : 14,
    );
    final metaStyle = kTextStyle.copyWith(
      color: kLightNeutralColor,
      fontSize: compact ? 11 : 12,
    );

    if (onBrandGradient) {
      final onSoft = Colors.white.withValues(alpha: 0.9);
      final onMuted = Colors.white.withValues(alpha: 0.78);
      if (reviewCount <= 0 && rating <= 0) {
        return Text(
          l10n.noReviewsYet,
          style: metaStyle.copyWith(color: onMuted),
        );
      }
      return Row(
        mainAxisSize: MainAxisSize.min,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.star_rounded, size: starSize, color: ratingBarColor),
          const SizedBox(width: 2),
          Text(
            rating.toStringAsFixed(1),
            style: valueStyle.copyWith(color: onSoft, fontSize: compact ? 12 : 14),
          ),
          if (reviewCount > 0) ...[
            Text(' · ', style: metaStyle.copyWith(color: onMuted)),
            Text(
              l10n.reviewCount(reviewCount),
              style: metaStyle.copyWith(color: onMuted),
            ),
          ],
        ],
      );
    }

    final accent = accentColor ?? kPrimaryColor;

    if (reviewCount <= 0 && rating <= 0) {
      return Text(
        l10n.noReviewsYet,
        style: metaStyle.copyWith(color: accent.withValues(alpha: 0.65)),
      );
    }

    return Row(
      mainAxisSize: MainAxisSize.min,
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Icon(Icons.star_rounded, size: starSize, color: ratingBarColor),
        const SizedBox(width: 2),
        Text(rating.toStringAsFixed(1),
            style: valueStyle.copyWith(color: accent)),
        if (reviewCount > 0) ...[
          Text(' · ', style: metaStyle),
          Text(
            l10n.reviewCount(reviewCount),
            style: metaStyle,
          ),
        ],
      ],
    );
  }
}
