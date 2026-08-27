import 'package:flutter/material.dart';
import 'package:freelancer/data/models/chat_order_context.dart';
import 'package:freelancer/l10n/l10n.dart';
import 'package:freelancer/screen/client%20screen/client%20orders/client_order_details.dart';
import 'package:freelancer/screen/seller%20screen/orders/seller_order_details.dart';
import 'package:freelancer/screen/seller%20screen/seller%20message/chat_inbox.dart';
import 'package:freelancer/services/chat_service.dart';
import 'package:nb_utils/nb_utils.dart';

Future<void> openOrderChat(
  BuildContext context, {
  required String otherUserId,
  required String otherUserName,
  required String otherUserImage,
  required ChatOrderContext orderContext,
}) async {
  try {
    final conversation = await ChatService.getOrCreateConversation(otherUserId);
    if (!context.mounted) return;
    await ChatInbox(
      conversationId: conversation['id'] as String,
      otherUserName: otherUserName,
      otherUserImage: otherUserImage,
      otherUserId: otherUserId,
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

void openOrderDetailsFromChat(BuildContext context, ChatOrderContext ctx) {
  if (ctx.isClientViewer) {
    ClientOrderDetails(orderId: ctx.orderId).launch(context);
  } else {
    SellerOrderDetails(orderId: ctx.orderId).launch(context);
  }
}
