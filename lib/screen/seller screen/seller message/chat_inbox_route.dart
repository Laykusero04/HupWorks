import 'package:flutter/material.dart';
import 'package:freelancer/core/utils/app_date_format.dart';
import 'package:freelancer/core/utils/chat_thread_context.dart';
import 'package:freelancer/core/utils/order_contract_display.dart';
import 'package:freelancer/data/models/chat_order_context.dart';
import 'package:freelancer/l10n/l10n.dart';
import 'package:freelancer/l10n/l10n_labels.dart';
import 'package:freelancer/screen/seller%20screen/seller%20message/chat_inbox.dart';
import 'package:freelancer/screen/seller%20screen/seller%20message/model/chat_model.dart';
import 'package:freelancer/screen/widgets/chat_preferred_contact_banner.dart';
import 'package:freelancer/screen/widgets/constant.dart';
import 'package:freelancer/services/chat_service.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

/// Resolves conversation metadata then shows [ChatInbox] (for GoRouter deep links).
class ChatInboxRoute extends StatefulWidget {
  const ChatInboxRoute({super.key, required this.conversationId});

  final String conversationId;

  @override
  State<ChatInboxRoute> createState() => _ChatInboxRouteState();
}

class _ChatInboxRouteState extends State<ChatInboxRoute> {
  bool _loading = true;
  String? _error;
  Widget? _inbox;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    try {
      final row = await ChatService.getConversation(widget.conversationId);
      if (!mounted) return;
      if (row == null) {
        setState(() {
          _loading = false;
          _error = context.l10n.couldNotOpenChat;
        });
        return;
      }

      final conversation = Conversation.fromMap(row);
      final userId = Supabase.instance.client.auth.currentUser?.id ?? '';
      final otherUser = conversation.getOtherUser(userId);
      final isClientViewer = isClientViewerFromAuth();
      final l10n = context.l10n;

      ChatOrderContext? orderContext;
      try {
        final order = await ChatService.getActiveOrderForConversation(
          clientId: conversation.clientId,
          sellerId: conversation.sellerId,
        );
        if (order != null) {
          final status =
              ((order['status'] as String?) ?? 'pending').toLowerCase();
          final service = order['services'] as Map<String, dynamic>?;
          final preferred = preferredContactFromOrder(order);
          orderContext = ChatOrderContext(
            orderId: order['id'] as String,
            title: OrderContractDisplay.title(order, service),
            statusLabel: isClientViewer
                ? L10nLabels.clientOrderStatusForUi(l10n, status)
                : L10nLabels.orderFilterTabLabel(l10n, status),
            deadlineLabel:
                AppDateFormat.tryMmmDY(order['delivery_deadline'] as String?),
            preferredContactLabel: preferred.label,
            isWithinPreferredWindow: preferred.inWindow,
            isClientViewer: isClientViewer,
          );
        }
      } catch (_) {
        // Optional enrichment — inbox still works without order context.
      }

      if (!mounted) return;
      setState(() {
        _inbox = ChatInbox(
          conversationId: widget.conversationId,
          otherUserName: otherUser['name'] as String? ??
              (isClientViewer ? l10n.roleSeller : l10n.roleClient),
          otherUserImage: otherUser['profile_image_url'] as String? ?? '',
          otherUserId: conversation.getOtherUserId(userId),
          orderContext: orderContext,
        );
        _loading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _loading = false;
        _error = context.l10n.couldNotOpenChatWithDetail('$e');
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_inbox != null) return _inbox!;
    if (_loading) {
      return const Scaffold(
        backgroundColor: kDarkWhite,
        body: Center(child: CircularProgressIndicator(color: kPrimaryColor)),
      );
    }
    return Scaffold(
      backgroundColor: kDarkWhite,
      appBar: AppBar(
        backgroundColor: kDarkWhite,
        elevation: 0,
        iconTheme: const IconThemeData(color: kNeutralColor),
      ),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Text(
            _error ?? context.l10n.couldNotOpenChat,
            textAlign: TextAlign.center,
            style: kTextStyle.copyWith(color: kSubTitleColor),
          ),
        ),
      ),
    );
  }
}
