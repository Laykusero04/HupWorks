import 'package:flutter/material.dart';

import '../../core/constants/colors.dart';
import 'constant.dart';
import 'shell_tab_header.dart';

/// Simple drawer header — green for client, blue for seller.
class ShellDrawerHeader extends StatelessWidget {
  const ShellDrawerHeader({
    super.key,
    required this.persona,
    required this.name,
    this.imageUrl,
    this.balanceLabel,
    this.rating,
    this.reviewCount,
    this.fallbackAsset = 'images/profile3.png',
  });

  final ShellPersona persona;
  final String name;
  final String? imageUrl;
  final String? balanceLabel;
  final double? rating;
  final int? reviewCount;
  final String fallbackAsset;

  Color get _backgroundColor =>
      persona == ShellPersona.client ? kPrimaryColor : kSellerPrimary;

  @override
  Widget build(BuildContext context) {
    final top = MediaQuery.paddingOf(context).top;

    return ColoredBox(
      color: _backgroundColor,
      child: Padding(
        padding: EdgeInsets.fromLTRB(16, top + 16, 16, 20),
        child: Row(
          children: [
            CircleAvatar(
              radius: 28,
              backgroundColor: kWhite.withValues(alpha: 0.2),
              backgroundImage: imageUrl != null
                  ? NetworkImage(imageUrl!) as ImageProvider
                  : AssetImage(fallbackAsset),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    name,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: kTextStyle.copyWith(
                      color: kWhite,
                      fontWeight: FontWeight.w600,
                      fontSize: 18,
                    ),
                  ),
                  if (balanceLabel != null) ...[
                    const SizedBox(height: 4),
                    Text(
                      balanceLabel!,
                      style: kTextStyle.copyWith(
                        color: kWhite.withValues(alpha: 0.9),
                        fontSize: 13,
                      ),
                    ),
                  ],
                  if (rating != null && (reviewCount ?? 0) > 0) ...[
                    const SizedBox(height: 4),
                    Text(
                      '${rating!.toStringAsFixed(1)} · $reviewCount reviews',
                      style: kTextStyle.copyWith(
                        color: kWhite.withValues(alpha: 0.85),
                        fontSize: 12,
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
