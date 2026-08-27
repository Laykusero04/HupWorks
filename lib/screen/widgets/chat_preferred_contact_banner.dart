import 'package:flutter/material.dart';
import 'package:freelancer/core/utils/shift_schedule.dart';
import 'package:freelancer/data/models/chat_thread_context.dart';
import 'package:freelancer/screen/widgets/constant.dart';

/// Soft preferred-contact strip for hired chats with shift times.
/// Does not block messaging — guidance only.
class ChatPreferredContactBanner extends StatelessWidget {
  const ChatPreferredContactBanner({
    super.key,
    required this.items,
    this.highlightedOrderId,
  });

  final List<ChatThreadContextItem> items;
  final String? highlightedOrderId;

  static ChatThreadContextItem? resolveFocus({
    required List<ChatThreadContextItem> items,
    String? highlightedOrderId,
  }) {
    if (highlightedOrderId != null) {
      for (final item in items) {
        if (item.isOrder &&
            item.id == highlightedOrderId &&
            item.preferredContactLabel != null) {
          return item;
        }
      }
    }
    for (final item in items) {
      if (item.isOrder && item.preferredContactLabel != null) return item;
    }
    return null;
  }

  @override
  Widget build(BuildContext context) {
    final focus = resolveFocus(
      items: items,
      highlightedOrderId: highlightedOrderId,
    );
    final label = focus?.preferredContactLabel;
    if (label == null || label.isEmpty) return const SizedBox.shrink();

    final inWindow = focus?.isWithinPreferredWindow ?? false;

    return Material(
      color: kWhite,
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.fromLTRB(14, 8, 14, 10),
        decoration: BoxDecoration(
          color: inWindow
              ? Colors.green.withValues(alpha: 0.06)
              : kDarkWhite,
          border: Border(
            bottom: BorderSide(
              color: inWindow
                  ? Colors.green.withValues(alpha: 0.2)
                  : kBorderColorTextField.withValues(alpha: 0.9),
            ),
          ),
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(
              inWindow ? Icons.schedule : Icons.schedule_outlined,
              size: 18,
              color: inWindow ? Colors.green.shade700 : kSubTitleColor,
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Preferred contact: $label',
                    style: kTextStyle.copyWith(
                      color: kNeutralColor,
                      fontWeight: FontWeight.w600,
                      fontSize: 12,
                      height: 1.3,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    inWindow
                        ? 'You are in a preferred window.'
                        : 'Outside preferred hours — you can still message.',
                    style: kTextStyle.copyWith(
                      color: kSubTitleColor,
                      fontSize: 11,
                      height: 1.3,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Builds preferred-contact fields from an order map (shift snapshot).
({String? label, bool inWindow}) preferredContactFromOrder(
  Map<String, dynamic> order,
) {
  final status = ((order['status'] as String?) ?? '').toLowerCase();
  // Soft windows apply to hired / in-progress contracts, not closed ones.
  if (status == 'completed' || status == 'cancelled') {
    return (label: null, inWindow: false);
  }
  final schedule = ShiftSchedule.fromOrderMap(order);
  final label = schedule.preferredContactWindowsLabel;
  if (label == null) return (label: null, inWindow: false);
  return (label: label, inWindow: schedule.isWithinPreferredContactWindow());
}
