import 'package:flutter/material.dart';

import 'constant.dart';

/// Simple 1–5 star row with reliable hit targets (replaces flaky gesture stacks).
class InteractiveStarRating extends StatelessWidget {
  const InteractiveStarRating({
    super.key,
    required this.value,
    required this.onChanged,
    this.starSize = 44,
  });

  /// 0 = none selected, otherwise 1–5.
  final int value;
  final ValueChanged<int> onChanged;
  final double starSize;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      mainAxisSize: MainAxisSize.min,
      children: List.generate(5, (i) {
        final starIndex = i + 1;
        final filled = value >= starIndex;
        return Material(
          color: Colors.transparent,
          child: InkWell(
            onTap: () => onChanged(starIndex),
            borderRadius: BorderRadius.circular(28),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 2, vertical: 6),
              child: Icon(
                filled ? Icons.star_rounded : Icons.star_outline_rounded,
                size: starSize,
                color: filled ? ratingBarColor : kBorderColorTextField,
              ),
            ),
          ),
        );
      }),
    );
  }
}
