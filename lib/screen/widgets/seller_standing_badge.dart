import 'package:flutter/material.dart';
import 'package:freelancer/core/utils/seller_standing.dart';
import 'package:freelancer/l10n/l10n.dart';

import 'constant.dart';

/// Circular standing badge + localized label (review-based ladder).
class SellerStandingBadge extends StatelessWidget {
  const SellerStandingBadge({
    super.key,
    required this.rating,
    required this.reviewCount,
    this.size = 44,
    this.compact = false,
  });

  final double rating;
  final int reviewCount;
  final double size;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final standing = SellerStandingResolver.resolve(
      rating: rating,
      reviewCount: reviewCount,
    );
    final label = standing.label(l10n);

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Image.asset(
          standing.assetPath,
          width: size,
          height: size,
          fit: BoxFit.contain,
          filterQuality: FilterQuality.high,
          errorBuilder: (_, __, ___) => Icon(
            Icons.military_tech_outlined,
            size: size * 0.7,
            color: kPrimaryColor,
          ),
        ),
        SizedBox(height: compact ? 4 : 6),
        Text(
          label,
          textAlign: TextAlign.center,
          style: kTextStyle.copyWith(
            color: kNeutralColor,
            fontWeight: FontWeight.w600,
            fontSize: compact ? 11 : 13,
          ),
        ),
      ],
    );
  }
}

/// Compact standing chip for talent cards (replaces the old Pro badge).
class TalentCardStandingChip extends StatelessWidget {
  const TalentCardStandingChip({
    super.key,
    required this.rating,
    required this.reviewCount,
    this.onPhoto = true,
  });

  final double rating;
  final int reviewCount;
  final bool onPhoto;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final standing = SellerStandingResolver.resolve(
      rating: rating,
      reviewCount: reviewCount,
    );
    final label = standing.label(l10n);

    return Tooltip(
      message: label,
      child: Container(
        padding: const EdgeInsets.fromLTRB(4, 3, 8, 3),
        decoration: BoxDecoration(
          color: onPhoto
              ? Colors.black.withValues(alpha: 0.5)
              : kDarkWhite,
          borderRadius: BorderRadius.circular(20),
          border: onPhoto
              ? null
              : Border.all(color: kBorderColorTextField),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Image.asset(
              standing.assetPath,
              width: 22,
              height: 22,
              fit: BoxFit.contain,
              filterQuality: FilterQuality.high,
              errorBuilder: (_, __, ___) => Icon(
                Icons.military_tech_rounded,
                size: 16,
                color: onPhoto ? Colors.white : kPrimaryColor,
              ),
            ),
            const SizedBox(width: 4),
            Text(
              label,
              style: kTextStyle.copyWith(
                color: onPhoto ? Colors.white : kNeutralColor,
                fontSize: 10,
                fontWeight: FontWeight.w700,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
