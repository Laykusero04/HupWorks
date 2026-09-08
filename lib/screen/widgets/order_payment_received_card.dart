import 'package:flutter/material.dart';
import 'package:freelancer/core/utils/app_date_format.dart';
import 'package:freelancer/l10n/l10n.dart';
import 'package:freelancer/screen/widgets/button_global.dart';
import 'package:freelancer/screen/widgets/constant.dart';
import 'package:freelancer/services/orders_service.dart';

/// Off-app payment mark for a completed order (work tracker proof, not a PSP).
class OrderPaymentReceivedCard extends StatefulWidget {
  final String orderId;
  final Map<String, dynamic>? order;
  final VoidCallback onChanged;

  /// Freelancer vs employer body copy; CTA is the same for both.
  final bool isSellerView;

  const OrderPaymentReceivedCard({
    Key? key,
    required this.orderId,
    required this.order,
    required this.onChanged,
    this.isSellerView = true,
  }) : super(key: key);

  @override
  State<OrderPaymentReceivedCard> createState() =>
      _OrderPaymentReceivedCardState();
}

class _OrderPaymentReceivedCardState extends State<OrderPaymentReceivedCard> {
  bool _busy = false;

  bool get _received => OrdersService.isPaymentReceived(widget.order);

  String? get _markedOnLabel {
    final raw = widget.order?['payment_received_at'] as String?;
    if (raw == null || raw.isEmpty) return null;
    final dt = DateTime.tryParse(raw);
    if (dt == null) return null;
    return AppDateFormat.mmmDY(dt, AppDateFormat.localeOf(context));
  }

  Future<void> _setReceived(bool received) async {
    if (_busy) return;
    setState(() => _busy = true);
    try {
      await OrdersService.setPaymentReceived(
        orderId: widget.orderId,
        received: received,
      );
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            received
                ? context.l10n.paymentReceivedMarked
                : context.l10n.paymentReceivedCleared,
          ),
        ),
      );
      widget.onChanged();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(context.l10n.errorWithDetail('$e'))),
        );
      }
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final received = _received;
    final markedOn = _markedOnLabel;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: received ? StatusColors.successBg : StatusColors.warningBg,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: (received ? StatusColors.success : StatusColors.warning)
              .withValues(alpha: 0.4),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                received
                    ? Icons.fact_check_outlined
                    : Icons.pending_actions_outlined,
                color: received ? StatusColors.success : StatusColors.warning,
                size: 22,
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  received
                      ? l10n.paymentReceivedTitle
                      : l10n.paymentOutstandingTitle,
                  style: kTextStyle.copyWith(
                    color: kNeutralColor,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          Text(
            received
                ? l10n.paymentReceivedBody
                : (widget.isSellerView
                    ? l10n.paymentOutstandingSellerBody
                    : l10n.paymentOutstandingClientBody),
            style: kTextStyle.copyWith(
              color: kSubTitleColor,
              fontSize: 13,
              height: 1.35,
            ),
          ),
          if (received && markedOn != null) ...[
            const SizedBox(height: 8),
            Text(
              l10n.paymentMarkedOn(markedOn),
              style: kTextStyle.copyWith(
                color: kNeutralColor,
                fontSize: 12.5,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
          const SizedBox(height: 12),
          if (!received)
            ButtonGlobalWithoutIcon(
              buttontext: _busy
                  ? l10n.pleaseWaitEllipsis
                  : l10n.markPaymentPaid,
              buttonDecoration: kButtonDecoration.copyWith(
                color: StatusColors.success,
              ),
              onPressed: _busy ? () {} : () => _setReceived(true),
              buttonTextColor: kWhite,
            )
          else
            TextButton(
              onPressed: _busy ? null : () => _setReceived(false),
              child: Text(
                l10n.undoPaymentReceived,
                style: kTextStyle.copyWith(
                  color: kSubTitleColor,
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
