import 'package:flutter/material.dart';
import 'package:freelancer/core/notification_navigation.dart';
import 'package:freelancer/core/utils/order_contract_display.dart';
import 'package:freelancer/data/models/chat_order_context.dart';
import 'package:freelancer/l10n/app_localizations.dart';
import 'package:freelancer/l10n/l10n.dart';
import 'package:freelancer/l10n/l10n_labels.dart';
import 'package:freelancer/screen/seller%20screen/seller%20message/chat_inbox.dart';
import 'package:freelancer/screen/seller%20screen/seller%20message/model/chat_model.dart';
import 'package:freelancer/screen/widgets/chat_preferred_contact_banner.dart';
import 'package:freelancer/services/chat_service.dart';
import 'package:nb_utils/nb_utils.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

Future<void> openChatFromNotification(
  BuildContext context, {
  required String conversationId,
  required NotificationUserRole role,
}) async {
  try {
    final row = await ChatService.getConversation(conversationId);
    if (!context.mounted) return;
    if (row == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(context.l10n.couldNotOpenChat)),
      );
      return;
    }

    final conversation = Conversation.fromMap(row);
    final userId = Supabase.instance.client.auth.currentUser?.id ?? '';
    final otherUser = conversation.getOtherUser(userId);
    final isClientViewer = role == NotificationUserRole.client;
    final l10n = context.l10n;
    final orderContext = await _resolveOrderContext(
      l10n,
      clientId: conversation.clientId,
      sellerId: conversation.sellerId,
      isClientViewer: isClientViewer,
    );

    if (!context.mounted) return;
    await ChatInbox(
      conversationId: conversationId,
      otherUserName: otherUser['name'] as String? ??
          (isClientViewer ? l10n.roleSeller : l10n.roleClient),
      otherUserImage: otherUser['profile_image_url'] as String? ?? '',
      otherUserId: conversation.getOtherUserId(userId),
      orderContext: orderContext,
    ).launch(context);
  } catch (e) {
    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(context.l10n.couldNotOpenChatWithDetail('$e'))),
      );
    }
  }
}

Future<ChatOrderContext?> _resolveOrderContext(
  AppLocalizations l10n, {
  required String clientId,
  required String sellerId,
  required bool isClientViewer,
}) async {
  final order = await ChatService.getActiveOrderForConversation(
    clientId: clientId,
    sellerId: sellerId,
  );
  if (order == null) return null;

  final status = ((order['status'] as String?) ?? 'pending').toLowerCase();
  final service = order['services'] as Map<String, dynamic>?;
  final title = OrderContractDisplay.title(order, service);
  final deadlineRaw = order['delivery_deadline'] as String?;
  final deadlineLabel = _formatDeadline(deadlineRaw);
  final preferred = preferredContactFromOrder(order);

  return ChatOrderContext(
    orderId: order['id'] as String,
    title: title,
    statusLabel: isClientViewer
        ? L10nLabels.clientOrderStatusForUi(l10n, status)
        : L10nLabels.orderFilterTabLabel(l10n, status),
    deadlineLabel: deadlineLabel,
    preferredContactLabel: preferred.label,
    isWithinPreferredWindow: preferred.inWindow,
    isClientViewer: isClientViewer,
  );
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
