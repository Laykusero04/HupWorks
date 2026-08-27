import 'package:flutter/material.dart';
import 'package:freelancer/data/models/order_delivery_model.dart';
import 'package:freelancer/l10n/l10n.dart';

import 'constant.dart';

/// Message + file from [order_deliveries], shown on client and seller order details.
class OrderDeliveryPanel extends StatelessWidget {
  final List<OrderDelivery> deliveries;
  final String title;
  final String? instruction;

  const OrderDeliveryPanel({
    super.key,
    required this.deliveries,
    required this.title,
    this.instruction,
  });

  static String formatSubmittedAt(DateTime date) {
    const months = [
      'Jan',
      'Feb',
      'Mar',
      'Apr',
      'May',
      'Jun',
      'Jul',
      'Aug',
      'Sep',
      'Oct',
      'Nov',
      'Dec',
    ];
    return '${date.day} ${months[date.month - 1]} ${date.year}';
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: kSecondaryColor.withOpacity(0.08),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: kSecondaryColor.withOpacity(0.35)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Icon(Icons.inbox_rounded, color: kSecondaryColor, size: 26),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  title,
                  style: kTextStyle.copyWith(
                    color: kNeutralColor,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ],
          ),
          if (instruction != null && instruction!.trim().isNotEmpty) ...[
            const SizedBox(height: 6),
            Text(
              instruction!,
              style: kTextStyle.copyWith(
                color: kSubTitleColor,
                fontSize: 13,
                height: 1.35,
              ),
            ),
          ],
          for (var i = 0; i < deliveries.length; i++) ...[
            const SizedBox(height: 12),
            if (i > 0) ...[
              Divider(color: kBorderColorTextField, height: 1),
              const SizedBox(height: 12),
            ],
            _DeliveryBlock(delivery: deliveries[i], l10n: l10n),
          ],
        ],
      ),
    );
  }
}

class _DeliveryBlock extends StatelessWidget {
  final OrderDelivery delivery;
  final AppLocalizations l10n;

  const _DeliveryBlock({required this.delivery, required this.l10n});

  void _openImage(BuildContext context, String url) {
    Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => Scaffold(
          backgroundColor: Colors.black,
          appBar: AppBar(
            backgroundColor: Colors.black,
            foregroundColor: Colors.white,
            elevation: 0,
          ),
          body: Center(
            child: InteractiveViewer(
              child: Image.network(
                url,
                fit: BoxFit.contain,
                errorBuilder: (_, __, ___) => const Icon(
                  Icons.broken_image_outlined,
                  color: Colors.white54,
                  size: 48,
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final message = delivery.message?.trim() ?? '';
    final url = delivery.attachmentUrl?.trim();
    final hasFile = url != null && url.isNotEmpty;
    final isImage = delivery.attachmentType == 'image';

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          OrderDeliveryPanel.formatSubmittedAt(delivery.deliveredAt.toLocal()),
          style: kTextStyle.copyWith(color: kLightNeutralColor, fontSize: 12),
        ),
        if (message.isNotEmpty) ...[
          const SizedBox(height: 8),
          Text(
            message,
            style: kTextStyle.copyWith(
              color: kNeutralColor,
              fontSize: 14,
              height: 1.35,
            ),
          ),
        ],
        if (hasFile) ...[
          const SizedBox(height: 10),
          if (isImage)
            GestureDetector(
              onTap: () => _openImage(context, url),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(10),
                child: Image.network(
                  url,
                  width: double.infinity,
                  height: 180,
                  fit: BoxFit.cover,
                  loadingBuilder: (_, child, progress) {
                    if (progress == null) return child;
                    return Container(
                      height: 180,
                      color: kDarkWhite,
                      child: const Center(
                        child: CircularProgressIndicator(
                          color: kPrimaryColor,
                          strokeWidth: 2,
                        ),
                      ),
                    );
                  },
                  errorBuilder: (_, __, ___) => _FileChip(
                    label: delivery.attachmentFileName,
                    fallback: l10n.chatAttachment,
                  ),
                ),
              ),
            )
          else
            _FileChip(
              label: delivery.attachmentFileName,
              fallback: l10n.chatAttachment,
            ),
        ],
      ],
    );
  }
}

class _FileChip extends StatelessWidget {
  final String label;
  final String fallback;

  const _FileChip({required this.label, required this.fallback});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
      decoration: BoxDecoration(
        color: kPrimaryColor.withOpacity(0.12),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Row(
        children: [
          const Icon(Icons.insert_drive_file_rounded,
              color: kPrimaryColor, size: 18),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              label.isEmpty ? fallback : label,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: kTextStyle.copyWith(
                color: kPrimaryColor,
                fontWeight: FontWeight.w600,
                fontSize: 13,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
