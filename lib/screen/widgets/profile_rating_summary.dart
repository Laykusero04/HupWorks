import 'package:flutter/material.dart';

import 'constant.dart';

/// Read-only average rating + review count (e.g. profile header).
class ProfileRatingSummary extends StatelessWidget {
  const ProfileRatingSummary({
    super.key,
    required this.rating,
    required this.reviewCount,
    this.compact = false,
  });

  final double rating;
  final int reviewCount;
  final bool compact;

  @override
  Widget build(BuildContext context) {
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

    if (reviewCount <= 0 && rating <= 0) {
      return Text(
        'No reviews yet',
        style: metaStyle.copyWith(color: kPrimaryColor.withValues(alpha: 0.65)),
      );
    }

    return Row(
      mainAxisSize: MainAxisSize.min,
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Icon(Icons.star_rounded, size: starSize, color: ratingBarColor),
        const SizedBox(width: 2),
        Text(rating.toStringAsFixed(1),
            style: valueStyle.copyWith(color: kPrimaryColor)),
        if (reviewCount > 0) ...[
          Text(' · ', style: metaStyle),
          Text(
            '$reviewCount ${reviewCount == 1 ? 'review' : 'reviews'}',
            style: metaStyle,
          ),
        ],
      ],
    );
  }
}
