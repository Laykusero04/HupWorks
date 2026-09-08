import 'package:flutter/material.dart';
import 'package:freelancer/core/notification_navigation.dart';
import 'package:freelancer/l10n/l10n.dart';
import 'package:freelancer/router/route_names.dart';
import 'package:freelancer/services/chat_service.dart';
import 'package:go_router/go_router.dart';

Future<void> openChatFromNotification(
  BuildContext context, {
  required String conversationId,
  required NotificationUserRole role,
}) async {
  try {
    // Prefetch so we can surface a clear error if the thread is gone.
    final row = await ChatService.getConversation(conversationId);
    if (!context.mounted) return;
    if (row == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(context.l10n.couldNotOpenChat)),
      );
      return;
    }

    switch (role) {
      case NotificationUserRole.client:
        context.push(AppRoutes.clientChatInboxOf(conversationId));
        return;
      case NotificationUserRole.seller:
        context.push(AppRoutes.sellerChatInboxOf(conversationId));
        return;
    }
  } catch (e) {
    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(context.l10n.couldNotOpenChatWithDetail('$e'))),
      );
    }
  }
}
