import 'package:flutter/material.dart';

import '../constants/colors.dart';
import '../constants/text_styles.dart';

class EmptyStateWidget extends StatelessWidget {
  final String message;
  final String? hint;
  final IconData icon;
  final String? imageAsset;
  final double imageHeight;
  final double imageWidth;
  final String? actionLabel;
  final VoidCallback? onAction;

  const EmptyStateWidget({
    super.key,
    required this.message,
    this.hint,
    this.icon = Icons.inbox_outlined,
    this.imageAsset,
    this.imageHeight = 180,
    this.imageWidth = 240,
    this.actionLabel,
    this.onAction,
  });

  @override
  Widget build(BuildContext context) {
    final showAction =
        actionLabel != null && actionLabel!.isNotEmpty && onAction != null;

    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 28),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            if (imageAsset != null)
              Container(
                height: imageHeight,
                width: imageWidth,
                decoration: BoxDecoration(
                  image: DecorationImage(
                    image: AssetImage(imageAsset!),
                    fit: BoxFit.contain,
                  ),
                ),
              )
            else
              Icon(icon, size: 56, color: kLightNeutralColor.withValues(alpha: 0.9)),
            const SizedBox(height: 16),
            Text(
              message,
              style: kTextStyle.copyWith(
                color: kNeutralColor,
                fontWeight: FontWeight.w700,
                fontSize: 18,
              ),
              textAlign: TextAlign.center,
            ),
            if (hint != null && hint!.isNotEmpty) ...[
              const SizedBox(height: 8),
              Text(
                hint!,
                style: kTextStyle.copyWith(
                  color: kLightNeutralColor,
                  fontSize: 13.5,
                  height: 1.35,
                ),
                textAlign: TextAlign.center,
              ),
            ],
            if (showAction) ...[
              const SizedBox(height: 20),
              FilledButton(
                style: FilledButton.styleFrom(
                  backgroundColor: kPrimaryColor,
                  foregroundColor: Colors.white,
                  padding:
                      const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(24),
                  ),
                ),
                onPressed: onAction,
                child: Text(
                  actionLabel!,
                  style: kTextStyle.copyWith(
                    color: Colors.white,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
