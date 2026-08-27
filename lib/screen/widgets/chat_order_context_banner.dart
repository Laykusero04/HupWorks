import 'package:flutter/material.dart';
import 'package:freelancer/data/models/chat_order_context.dart';
import 'package:freelancer/l10n/l10n.dart';
import 'package:freelancer/screen/widgets/constant.dart';

/// Compact order summary pinned above chat messages.
class ChatOrderContextBanner extends StatelessWidget {
  const ChatOrderContextBanner({
    super.key,
    required this.orderContext,
    required this.onViewContract,
  });

  final ChatOrderContext orderContext;
  final VoidCallback onViewContract;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final deadline = orderContext.deadlineLabel;

    return Material(
      color: kWhite,
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.fromLTRB(16, 10, 16, 10),
        decoration: BoxDecoration(
          color: kPrimaryColor.withValues(alpha: 0.05),
          border: Border(
            bottom: BorderSide(color: kPrimaryColor.withValues(alpha: 0.18)),
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              orderContext.title,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: kTextStyle.copyWith(
                color: kNeutralColor,
                fontWeight: FontWeight.w700,
                fontSize: 14,
                height: 1.25,
              ),
            ),
            const SizedBox(height: 4),
            Wrap(
              spacing: 6,
              runSpacing: 2,
              crossAxisAlignment: WrapCrossAlignment.center,
              children: [
                Text(
                  '${l10n.labelStatus}${l10n.labelColon} ${orderContext.statusLabel}',
                  style: kTextStyle.copyWith(
                    color: kSubTitleColor,
                    fontSize: 12,
                  ),
                ),
                if (deadline != null && deadline.isNotEmpty) ...[
                  Text(
                    '·',
                    style: kTextStyle.copyWith(
                      color: kLightNeutralColor,
                      fontSize: 12,
                    ),
                  ),
                  Text(
                    '${l10n.deliveryDate}${l10n.labelColon} $deadline',
                    style: kTextStyle.copyWith(
                      color: kSubTitleColor,
                      fontSize: 12,
                    ),
                  ),
                ],
              ],
            ),
            const SizedBox(height: 2),
            InkWell(
              onTap: onViewContract,
              borderRadius: BorderRadius.circular(4),
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: 2),
                child: Text(
                  l10n.openContract,
                  style: kTextStyle.copyWith(
                    color: kPrimaryColor,
                    fontWeight: FontWeight.w600,
                    fontSize: 12,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
