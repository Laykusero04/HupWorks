import 'package:flutter/material.dart';
import 'package:freelancer/core/utils/job_offer_chat_actions.dart';
import 'package:freelancer/core/utils/job_offer_delivery.dart';
import 'package:freelancer/l10n/l10n.dart';
import 'package:freelancer/screen/seller%20screen/seller%20message/model/chat_model.dart';
import 'package:freelancer/services/chat_service.dart';
import 'package:freelancer/services/job_posts_service.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'constant.dart';

/// Bid / application card in chat with optional inline hire actions for clients.
class ChatJobOfferCard extends StatefulWidget {
  const ChatJobOfferCard({
    super.key,
    required this.message,
    required this.conversationId,
    required this.isMine,
    required this.formatTime,
    required this.smallAvatar,
    this.legacyBid,
  });

  final Message message;
  final String conversationId;
  final bool isMine;
  final String Function(DateTime) formatTime;
  final Widget smallAvatar;
  final LegacyBidInfo? legacyBid;

  @override
  State<ChatJobOfferCard> createState() => _ChatJobOfferCardState();
}

class LegacyBidInfo {
  const LegacyBidInfo({
    required this.jobTitle,
    required this.amount,
    required this.delivery,
    this.proposal,
  });

  final String jobTitle;
  final String amount;
  final String delivery;
  final String? proposal;
}

class _ChatJobOfferCardState extends State<ChatJobOfferCard> {
  Map<String, dynamic>? _offer;
  bool _loadingOffer = false;
  bool _actionBusy = false;

  String get _currentUserId =>
      Supabase.instance.client.auth.currentUser?.id ?? '';

  @override
  void initState() {
    super.initState();
    if (widget.message.jobOfferId != null) {
      _loadOffer();
    }
  }

  Future<void> _loadOffer() async {
    final offerId = widget.message.jobOfferId;
    if (offerId == null) return;
    setState(() => _loadingOffer = true);
    try {
      final data = await ChatService.getJobOffer(offerId);
      if (mounted) {
        setState(() {
          _offer = data;
          _loadingOffer = false;
        });
      }
    } catch (_) {
      if (mounted) setState(() => _loadingOffer = false);
    }
  }

  LegacyBidInfo? get _displayBid {
    if (_offer != null) {
      final jobPost = _offer!['job_posts'] as Map<String, dynamic>? ?? {};
      return LegacyBidInfo(
        jobTitle: jobPost['title'] as String? ?? 'Job',
        amount: JobPostsService.formatOfferAmountShort(
          _offer!['price'],
          _offer!['price_basis'],
        ),
        delivery: JobOfferDelivery.formatLabel(
          _offer!['delivery_time'],
          _offer!['delivery_time_unit'],
        ),
        proposal: (_offer!['cover_letter'] as String?)?.trim().isNotEmpty == true
            ? (_offer!['cover_letter'] as String).trim()
            : _legacyFromContent()?.proposal,
      );
    }
    return widget.legacyBid ?? _legacyFromContent();
  }

  LegacyBidInfo? _legacyFromContent() {
    final lines =
        widget.message.content.split('\n').map((l) => l.trim()).toList();
    if (lines.isEmpty || !lines[0].contains('bid for')) return null;
    final titleMatch = RegExp(r'"([^"]+)"').firstMatch(lines[0]);
    final jobTitle = titleMatch?.group(1) ?? '';
    if (jobTitle.isEmpty || lines.length < 2) return null;
    final amountMatch =
        RegExp(r'Amount:\s*([^·]+?)(?:\s*·|$)').firstMatch(lines[1]);
    final deliveryMatch =
        RegExp(r'(?:Delivery:|·)\s*(.+)$').firstMatch(lines[1]);
    final amount = amountMatch?.group(1)?.trim() ?? '';
    final delivery = deliveryMatch?.group(1)?.trim() ?? 'Agreed in chat';
    if (amount.isEmpty) return null;
    String? proposal;
    if (lines.length > 2) {
      proposal = lines.sublist(2).join('\n').trim();
      if (proposal.isEmpty) proposal = null;
    }
    return LegacyBidInfo(
      jobTitle: jobTitle,
      amount: amount,
      delivery: delivery,
      proposal: proposal,
    );
  }

  bool get _isClientViewer {
    final offer = _offer;
    if (offer == null) return false;
    final jobPost = offer['job_posts'] as Map<String, dynamic>?;
    return jobPost?['client_id'] == _currentUserId;
  }

  bool get _canActOnOffer {
    if (_offer == null || _actionBusy || widget.isMine) return false;
    if (!_isClientViewer) return false;
    final status = ((_offer!['status'] as String?) ?? '').toLowerCase();
    if (status != 'pending') return false;
    final jobPost = _offer!['job_posts'] as Map<String, dynamic>?;
    return (jobPost?['status'] as String?)?.toLowerCase() == 'open';
  }

  String? get _statusLabel {
    final status = ((_offer?['status'] as String?) ?? '').toLowerCase();
    if (status.isEmpty) return null;
    final l10n = context.l10n;
    switch (status) {
      case 'accepted':
        return l10n.statusAccepted;
      case 'rejected':
        return l10n.statusRejected;
      case 'pending':
        return l10n.statusPending;
      default:
        return status.substring(0, 1).toUpperCase() + status.substring(1);
    }
  }

  (Color, Color)? get _statusColors {
    final status = (_offer?['status'] as String?)?.toLowerCase();
    if (status == null) return null;
    final (fg, bg) = StatusColors.application(status);
    return (fg, bg);
  }

  Future<void> _handleReject() async {
    final offerId = widget.message.jobOfferId ?? _offer?['id'] as String?;
    if (offerId == null) return;
    setState(() => _actionBusy = true);
    await JobOfferChatActions.rejectOffer(
      context,
      offerId: offerId,
      onComplete: () async {
        await _loadOffer();
        if (mounted) setState(() => _actionBusy = false);
      },
    );
    if (mounted) setState(() => _actionBusy = false);
  }

  Future<void> _handleAccept() async {
    final offer = _offer;
    if (offer == null) return;
    setState(() => _actionBusy = true);
    final jobPost = offer['job_posts'] as Map<String, dynamic>? ?? {};
    final jobPostId = jobPost['id'] as String?;
    List<Map<String, dynamic>> siblings = [];
    if (jobPostId != null) {
      siblings = await ChatService.getOffersForJobPost(jobPostId);
    }
    if (!mounted) return;
    await JobOfferChatActions.acceptOffer(
      context,
      offer: offer,
      siblingOffers: siblings,
      onComplete: () async {
        await _loadOffer();
        if (mounted) setState(() => _actionBusy = false);
      },
    );
    if (mounted) setState(() => _actionBusy = false);
  }

  Future<void> _handleCounter() async {
    final offer = _offer;
    final offerId = widget.message.jobOfferId ?? offer?['id'] as String?;
    if (offer == null || offerId == null) return;
    await JobOfferChatActions.showCounterOfferDialog(
      context,
      conversationId: widget.conversationId,
      offerId: offerId,
      offer: offer,
    );
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final bid = _displayBid;
    if (_loadingOffer && bid == null) {
      return const Padding(
        padding: EdgeInsets.symmetric(vertical: 12),
        child: Center(
          child: SizedBox(
            width: 24,
            height: 24,
            child: CircularProgressIndicator(strokeWidth: 2, color: kPrimaryColor),
          ),
        ),
      );
    }
    if (bid == null) return const SizedBox.shrink();

    final isCounter = widget.message.messageType == 'counter_offer';
    final headerLabel =
        isCounter ? l10n.counterOfferLabel : l10n.bidOfferLabel;
    final statusLabel = _statusLabel;
    final statusColors = _statusColors;

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        mainAxisAlignment:
            widget.isMine ? MainAxisAlignment.end : MainAxisAlignment.start,
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          if (!widget.isMine) ...[
            widget.smallAvatar,
            const SizedBox(width: 6),
          ],
          Flexible(
            child: Column(
              crossAxisAlignment: widget.isMine
                  ? CrossAxisAlignment.end
                  : CrossAxisAlignment.start,
              children: [
                Container(
                  constraints: BoxConstraints(
                    maxWidth: MediaQuery.of(context).size.width * 0.78,
                  ),
                  decoration: BoxDecoration(
                    color: kWhite,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(
                      color: kPrimaryColor.withValues(alpha: 0.25),
                      width: 1.2,
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: kPrimaryColor.withValues(alpha: 0.08),
                        blurRadius: 12,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  clipBehavior: Clip.antiAlias,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.symmetric(
                          horizontal: 14,
                          vertical: 10,
                        ),
                        color: kPrimaryColor.withValues(alpha: 0.10),
                        child: Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.all(6),
                              decoration: const BoxDecoration(
                                shape: BoxShape.circle,
                                color: kPrimaryColor,
                              ),
                              child: Icon(
                                isCounter
                                    ? Icons.swap_horiz_rounded
                                    : Icons.assignment_outlined,
                                color: kWhite,
                                size: 14,
                              ),
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                headerLabel,
                                style: kTextStyle.copyWith(
                                  color: kPrimaryColor,
                                  fontWeight: FontWeight.bold,
                                  fontSize: 13,
                                  letterSpacing: 0.3,
                                ),
                              ),
                            ),
                            if (statusLabel != null && statusColors != null)
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 8,
                                  vertical: 3,
                                ),
                                decoration: BoxDecoration(
                                  color: statusColors.$2,
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: Text(
                                  statusLabel,
                                  style: kTextStyle.copyWith(
                                    color: statusColors.$1,
                                    fontSize: 11,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ),
                          ],
                        ),
                      ),
                      Padding(
                        padding: const EdgeInsets.all(14),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              bid.jobTitle,
                              style: kTextStyle.copyWith(
                                color: kNeutralColor,
                                fontWeight: FontWeight.bold,
                                fontSize: 15,
                                height: 1.25,
                              ),
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                            ),
                            const SizedBox(height: 10),
                            Row(
                              children: [
                                Expanded(
                                  child: _bidPill(
                                    icon: Icons.payments_outlined,
                                    label: l10n.amount.toUpperCase(),
                                    value: bid.amount,
                                  ),
                                ),
                                const SizedBox(width: 8),
                                Expanded(
                                  child: _bidPill(
                                    icon: Icons.schedule,
                                    label: l10n.labelDuration.toUpperCase(),
                                    value: bid.delivery,
                                  ),
                                ),
                              ],
                            ),
                            if (bid.proposal != null) ...[
                              const SizedBox(height: 12),
                              Container(
                                width: double.infinity,
                                padding: const EdgeInsets.all(10),
                                decoration: BoxDecoration(
                                  color: kDarkWhite,
                                  borderRadius: BorderRadius.circular(8),
                                  border:
                                      Border.all(color: kBorderColorTextField),
                                ),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      l10n.proposalCaps,
                                      style: kTextStyle.copyWith(
                                        color: kLightNeutralColor,
                                        fontSize: 10,
                                        fontWeight: FontWeight.w700,
                                        letterSpacing: 0.5,
                                      ),
                                    ),
                                    const SizedBox(height: 4),
                                    Text(
                                      bid.proposal!,
                                      style: kTextStyle.copyWith(
                                        color: kNeutralColor,
                                        fontSize: 13,
                                        height: 1.35,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                            if (_canActOnOffer) ...[
                              const SizedBox(height: 14),
                              Row(
                                children: [
                                  Expanded(
                                    child: OutlinedButton(
                                      onPressed:
                                          _actionBusy ? null : _handleReject,
                                      style: OutlinedButton.styleFrom(
                                        foregroundColor: StatusColors.danger,
                                        side: const BorderSide(
                                          color: StatusColors.danger,
                                        ),
                                        padding: const EdgeInsets.symmetric(
                                          vertical: 10,
                                        ),
                                      ),
                                      child: Text(l10n.rejectApplication),
                                    ),
                                  ),
                                  const SizedBox(width: 8),
                                  Expanded(
                                    child: OutlinedButton(
                                      onPressed:
                                          _actionBusy ? null : _handleCounter,
                                      style: OutlinedButton.styleFrom(
                                        foregroundColor: kPrimaryColor,
                                        side: const BorderSide(
                                          color: kPrimaryColor,
                                        ),
                                        padding: const EdgeInsets.symmetric(
                                          vertical: 10,
                                        ),
                                      ),
                                      child: Text(l10n.counterOfferAction),
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 8),
                              SizedBox(
                                width: double.infinity,
                                child: FilledButton(
                                  onPressed:
                                      _actionBusy ? null : _handleAccept,
                                  style: FilledButton.styleFrom(
                                    backgroundColor: kPrimaryColor,
                                    padding: const EdgeInsets.symmetric(
                                      vertical: 12,
                                    ),
                                  ),
                                  child: _actionBusy
                                      ? const SizedBox(
                                          width: 18,
                                          height: 18,
                                          child: CircularProgressIndicator(
                                            strokeWidth: 2,
                                            color: kWhite,
                                          ),
                                        )
                                      : Text(l10n.hireAction),
                                ),
                              ),
                            ],
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 4),
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      widget.formatTime(widget.message.createdAt),
                      style: kTextStyle.copyWith(
                        color: kLightNeutralColor,
                        fontSize: 11,
                      ),
                    ),
                    if (widget.isMine) ...[
                      const SizedBox(width: 4),
                      Icon(
                        widget.message.isRead ? Icons.done_all : Icons.done,
                        size: 14,
                        color: widget.message.isRead
                            ? kPrimaryColor
                            : kLightNeutralColor,
                      ),
                    ],
                  ],
                ),
              ],
            ),
          ),
          if (widget.isMine) const SizedBox(width: 6),
        ],
      ),
    );
  }

  Widget _bidPill({
    required IconData icon,
    required String label,
    required String value,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
      decoration: BoxDecoration(
        color: kDarkWhite,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: kBorderColorTextField),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, size: 13, color: kPrimaryColor),
              const SizedBox(width: 4),
              Flexible(
                child: Text(
                  label,
                  style: kTextStyle.copyWith(
                    color: kLightNeutralColor,
                    fontSize: 10,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 0.5,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
          const SizedBox(height: 4),
          Text(
            value,
            style: kTextStyle.copyWith(
              color: kNeutralColor,
              fontWeight: FontWeight.bold,
              fontSize: 14,
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }
}
