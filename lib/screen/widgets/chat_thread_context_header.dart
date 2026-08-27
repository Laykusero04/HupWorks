import 'package:flutter/material.dart';
import 'package:freelancer/core/utils/chat_thread_context.dart';
import 'package:freelancer/data/models/chat_thread_context.dart';
import 'package:freelancer/l10n/l10n.dart';
import 'package:freelancer/screen/widgets/constant.dart';

/// Compact strip under the chat app bar summarizing related work.
class ChatThreadContextHeader extends StatelessWidget {
  const ChatThreadContextHeader({
    super.key,
    required this.items,
    required this.isClientViewer,
    this.highlightedOrderId,
    this.isLoading = false,
  });

  final List<ChatThreadContextItem> items;
  final bool isClientViewer;
  final String? highlightedOrderId;
  final bool isLoading;

  @override
  Widget build(BuildContext context) {
    if (isLoading && items.isEmpty) {
      return Material(
        color: kWhite,
        child: Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
          decoration: BoxDecoration(
            border: Border(
              bottom: BorderSide(color: kBorderColorTextField.withValues(alpha: 0.8)),
            ),
          ),
          child: Row(
            children: [
              SizedBox(
                width: 14,
                height: 14,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  color: kPrimaryColor.withValues(alpha: 0.6),
                ),
              ),
              const SizedBox(width: 10),
              Text(
                context.l10n.threadContextLoading,
                style: kTextStyle.copyWith(
                  color: kLightNeutralColor,
                  fontSize: 12,
                ),
              ),
            ],
          ),
        ),
      );
    }

    if (items.isEmpty) return const SizedBox.shrink();

    final l10n = context.l10n;
    final focus = _focusItem();
    final count = items.length;
    final subtitle = count == 1
        ? focus.statusLabel
        : l10n.threadContextRelatedCount(count);

    return Material(
      color: kWhite,
      child: InkWell(
        onTap: () => showChatThreadContextSheet(
          context,
          items: items,
          isClientViewer: isClientViewer,
          highlightedOrderId: highlightedOrderId,
        ),
        child: Container(
          width: double.infinity,
          padding: const EdgeInsets.fromLTRB(14, 10, 10, 10),
          decoration: BoxDecoration(
            color: kPrimaryColor.withValues(alpha: 0.05),
            border: Border(
              bottom: BorderSide(color: kPrimaryColor.withValues(alpha: 0.16)),
            ),
          ),
          child: Row(
            children: [
              Container(
                width: 34,
                height: 34,
                decoration: BoxDecoration(
                  color: kPrimaryColor.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(
                  focus.isOrder
                      ? Icons.description_outlined
                      : Icons.assignment_outlined,
                  size: 18,
                  color: kPrimaryColor,
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      focus.title,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: kTextStyle.copyWith(
                        color: kNeutralColor,
                        fontWeight: FontWeight.w700,
                        fontSize: 13,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      subtitle,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: kTextStyle.copyWith(
                        color: kSubTitleColor,
                        fontSize: 11,
                      ),
                    ),
                  ],
                ),
              ),
              if (count > 1)
                Container(
                  margin: const EdgeInsets.only(right: 4),
                  padding:
                      const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
                  decoration: BoxDecoration(
                    color: kPrimaryColor,
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Text(
                    '$count',
                    style: kTextStyle.copyWith(
                      color: kWhite,
                      fontSize: 11,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
              Icon(
                Icons.keyboard_arrow_up_rounded,
                color: kPrimaryColor.withValues(alpha: 0.85),
              ),
            ],
          ),
        ),
      ),
    );
  }

  ChatThreadContextItem _focusItem() {
    if (highlightedOrderId != null) {
      for (final item in items) {
        if (item.isOrder && item.id == highlightedOrderId) return item;
      }
    }
    return items.first;
  }
}

Future<void> showChatThreadContextSheet(
  BuildContext context, {
  required List<ChatThreadContextItem> items,
  required bool isClientViewer,
  String? highlightedOrderId,
}) {
  final l10n = context.l10n;
  return showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    backgroundColor: kWhite,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
    ),
    builder: (ctx) {
      return SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 10, 16, 20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Center(
                child: Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: kBorderColorTextField,
                    borderRadius: BorderRadius.circular(4),
                  ),
                ),
              ),
              const SizedBox(height: 14),
              Text(
                l10n.threadContextTitle,
                style: kTextStyle.copyWith(
                  color: kNeutralColor,
                  fontWeight: FontWeight.w800,
                  fontSize: 17,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                l10n.threadContextSubtitle,
                style: kTextStyle.copyWith(
                  color: kSubTitleColor,
                  fontSize: 13,
                  height: 1.35,
                ),
              ),
              const SizedBox(height: 14),
              ConstrainedBox(
                constraints: BoxConstraints(
                  maxHeight: MediaQuery.sizeOf(ctx).height * 0.5,
                ),
                child: ListView.separated(
                  shrinkWrap: true,
                  itemCount: items.length,
                  separatorBuilder: (_, __) => const SizedBox(height: 8),
                  itemBuilder: (_, i) {
                    final item = items[i];
                    final highlighted = item.isOrder &&
                        highlightedOrderId != null &&
                        item.id == highlightedOrderId;
                    return _ThreadContextTile(
                      item: item,
                      highlighted: highlighted,
                      onTap: () {
                        Navigator.pop(ctx);
                        openThreadContextItem(
                          context,
                          item,
                          isClientViewer: isClientViewer,
                        );
                      },
                    );
                  },
                ),
              ),
            ],
          ),
        ),
      );
    },
  );
}

class _ThreadContextTile extends StatelessWidget {
  const _ThreadContextTile({
    required this.item,
    required this.onTap,
    this.highlighted = false,
  });

  final ChatThreadContextItem item;
  final VoidCallback onTap;
  final bool highlighted;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final kindLabel =
        item.isOrder ? l10n.contracts : l10n.bidOfferLabel;

    return Material(
      color: highlighted
          ? kPrimaryColor.withValues(alpha: 0.07)
          : kDarkWhite.withValues(alpha: 0.65),
      borderRadius: BorderRadius.circular(14),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(14),
        child: Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(14),
            border: Border.all(
              color: highlighted
                  ? kPrimaryColor.withValues(alpha: 0.35)
                  : kBorderColorTextField,
            ),
          ),
          child: Row(
            children: [
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: kWhite,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: kBorderColorTextField),
                ),
                child: Icon(
                  item.isOrder
                      ? Icons.description_outlined
                      : Icons.assignment_outlined,
                  color: kPrimaryColor,
                  size: 20,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      kindLabel,
                      style: kTextStyle.copyWith(
                        color: kLightNeutralColor,
                        fontSize: 10,
                        fontWeight: FontWeight.w700,
                        letterSpacing: 0.4,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      item.title,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: kTextStyle.copyWith(
                        color: kNeutralColor,
                        fontWeight: FontWeight.w700,
                        fontSize: 14,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Wrap(
                      spacing: 6,
                      crossAxisAlignment: WrapCrossAlignment.center,
                      children: [
                        Text(
                          item.statusLabel,
                          style: kTextStyle.copyWith(
                            color: kSubTitleColor,
                            fontSize: 12,
                          ),
                        ),
                        if (item.deadlineLabel != null &&
                            item.deadlineLabel!.isNotEmpty) ...[
                          Text(
                            '·',
                            style: kTextStyle.copyWith(
                              color: kLightNeutralColor,
                              fontSize: 12,
                            ),
                          ),
                          Text(
                            item.deadlineLabel!,
                            style: kTextStyle.copyWith(
                              color: kSubTitleColor,
                              fontSize: 12,
                            ),
                          ),
                        ],
                      ],
                    ),
                  ],
                ),
              ),
              const Icon(Icons.chevron_right_rounded, color: kLightNeutralColor),
            ],
          ),
        ),
      ),
    );
  }
}
