import 'package:flutter/material.dart';
import 'package:freelancer/core/utils/order_chat_navigation.dart';
import 'package:freelancer/core/utils/order_contract_display.dart';
import 'package:freelancer/data/models/chat_order_context.dart';
import 'package:freelancer/data/models/chat_thread_context.dart';
import 'package:freelancer/l10n/l10n.dart';
import 'package:freelancer/l10n/l10n_labels.dart';
import 'package:freelancer/screen/client%20screen/client%20job%20post/job_details.dart';
import 'package:freelancer/screen/seller%20screen/buyer%20request/buyer_request_details.dart';
import 'package:freelancer/services/auth_service.dart';
import 'package:freelancer/services/chat_service.dart';
import 'package:nb_utils/nb_utils.dart';

Future<List<ChatThreadContextItem>> loadThreadContext({
  required String clientId,
  required String sellerId,
  required AppLocalizations l10n,
  required bool isClientViewer,
}) async {
  final rows = await ChatService.getThreadContextRows(
    clientId: clientId,
    sellerId: sellerId,
  );

  final items = <ChatThreadContextItem>[];

  for (final order in rows.orders) {
    final status = ((order['status'] as String?) ?? 'pending').toLowerCase();
    final service = order['services'] as Map<String, dynamic>?;
    items.add(
      ChatThreadContextItem(
        kind: ChatThreadContextKind.order,
        id: order['id'] as String,
        title: OrderContractDisplay.title(order, service),
        statusKey: status,
        statusLabel: isClientViewer
            ? L10nLabels.clientOrderStatusForUi(l10n, status)
            : L10nLabels.orderFilterTabLabel(l10n, status),
        deadlineLabel: _formatDeadline(order['delivery_deadline'] as String?),
        jobPostId: OrderContractDisplay.jobPostIdFromOrder(order),
      ),
    );
  }

  for (final offer in rows.jobOffers) {
    final status = ((offer['status'] as String?) ?? 'pending').toLowerCase();
    final jobPost = offer['job_posts'] as Map<String, dynamic>? ?? {};
    final title = (jobPost['title'] as String?)?.trim();
    items.add(
      ChatThreadContextItem(
        kind: ChatThreadContextKind.jobOffer,
        id: offer['id'] as String,
        title: (title != null && title.isNotEmpty) ? title : l10n.bidOfferLabel,
        statusKey: status,
        statusLabel: _offerStatusLabel(l10n, status),
        jobPostId: jobPost['id']?.toString(),
      ),
    );
  }

  return items;
}

String _offerStatusLabel(AppLocalizations l10n, String status) {
  switch (status) {
    case 'accepted':
      return l10n.statusAccepted;
    case 'rejected':
      return l10n.statusRejected;
    case 'pending':
      return l10n.statusPending;
    default:
      return status;
  }
}

String? _formatDeadline(String? iso) {
  if (iso == null || iso.isEmpty) return null;
  final date = DateTime.tryParse(iso);
  if (date == null) return null;
  const months = [
    'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
    'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec',
  ];
  return '${months[date.month - 1]} ${date.day}, ${date.year}';
}

Future<void> openThreadContextItem(
  BuildContext context,
  ChatThreadContextItem item, {
  required bool isClientViewer,
}) async {
  if (item.isOrder) {
    openOrderDetailsFromChat(
      context,
      ChatOrderContext(
        orderId: item.id,
        title: item.title,
        statusLabel: item.statusLabel,
        deadlineLabel: item.deadlineLabel,
        isClientViewer: isClientViewer,
      ),
    );
    return;
  }

  final jobPostId = item.jobPostId;
  if (jobPostId == null || jobPostId.isEmpty) {
    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(context.l10n.couldNotOpenChat)),
      );
    }
    return;
  }

  if (isClientViewer) {
    await JobDetails(jobPostId: jobPostId).launch(context);
  } else {
    await BuyerRequestDetails(jobPostId: jobPostId).launch(context);
  }
}

bool isClientViewerFromAuth() => AuthService.cachedRole != 'seller';
