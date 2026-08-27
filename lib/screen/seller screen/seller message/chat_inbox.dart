import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_feather_icons/flutter_feather_icons.dart';
import 'package:freelancer/l10n/l10n.dart';
import 'package:freelancer/screen/widgets/constant.dart';
import 'package:image_picker/image_picker.dart';
import 'package:nb_utils/nb_utils.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../core/chat/chat_unread_scope.dart';
import '../../../core/utils/chat_thread_context.dart';
import '../../../data/models/chat_order_context.dart';
import '../../../data/models/chat_thread_context.dart';
import '../../../services/auth_service.dart';
import '../../../services/chat_service.dart';
import '../../client screen/client report/client_report.dart';
import '../../widgets/chat_job_offer_card.dart';
import '../../widgets/chat_thread_context_header.dart';
import '../report/seller_report.dart';
import '../seller popUp/seller_popup.dart';
import 'model/chat_model.dart';

class ChatInbox extends StatefulWidget {
  final String conversationId;
  final String otherUserName;
  final String otherUserImage;
  final String? otherUserId;
  final ChatOrderContext? orderContext;

  const ChatInbox({
    super.key,
    required this.conversationId,
    required this.otherUserName,
    required this.otherUserImage,
    this.otherUserId,
    this.orderContext,
  });

  @override
  State<ChatInbox> createState() => _ChatInboxState();
}

class _ChatInboxState extends State<ChatInbox> {
  final ScrollController _scrollController = ScrollController();
  final TextEditingController _messageController = TextEditingController();
  final FocusNode _msgFocusNode = FocusNode();
  final ImagePicker _imagePicker = ImagePicker();

  List<Message> _messages = [];
  final List<_PendingMessage> _pendingMessages = [];
  bool _isLoading = true;
  bool _isUploadingAttachment = false;
  bool _hasText = false;
  RealtimeChannel? _messageChannel;

  List<ChatThreadContextItem> _threadItems = const [];
  bool _threadLoading = false;
  bool _isClientViewer = true;

  String get _currentUserId =>
      Supabase.instance.client.auth.currentUser?.id ?? '';

  @override
  void initState() {
    super.initState();
    _isClientViewer = isClientViewerFromAuth();
    _messageController.addListener(_onTextChanged);
    // Defer Supabase calls until after the first frame so the skeleton
    // bubbles paint immediately.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      _loadMessages();
      _subscribeToMessages();
      _markAsRead();
      _loadThreadContext();
    });
  }

  @override
  void dispose() {
    _messageController.removeListener(_onTextChanged);
    _messageController.dispose();
    _scrollController.dispose();
    _msgFocusNode.dispose();
    if (_messageChannel != null) {
      ChatService.unsubscribe(_messageChannel!);
    }
    super.dispose();
  }

  void _onTextChanged() {
    final hasText = _messageController.text.trim().isNotEmpty;
    if (hasText != _hasText) {
      setState(() => _hasText = hasText);
    }
  }

  Future<void> _loadMessages() async {
    try {
      final data = await ChatService.getMessages(widget.conversationId);
      if (mounted) {
        setState(() {
          _messages = data.map((e) => Message.fromMap(e)).toList();
          _isLoading = false;
        });
        _scrollToBottom();
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(context.l10n.errorWithDetail('$e'))),
        );
      }
    }
  }

  void _subscribeToMessages() {
    _messageChannel = ChatService.subscribeToMessages(
      conversationId: widget.conversationId,
      onNewMessage: (newRecord) async {
        // If this incoming message was sent by us, drop the matching pending
        // bubble BEFORE the list rebuild so there is no flicker: the pending
        // entry vanishes at the same frame the real server copy appears.
        final senderId = newRecord['sender_id'] as String?;
        final content = newRecord['content'] as String? ?? '';
        if (senderId == _currentUserId && mounted) {
          setState(() {
            _pendingMessages.removeWhere(
              (m) =>
                  m.status == _PendingStatus.sending &&
                  m.content == content &&
                  m.attachmentUrl == (newRecord['attachment_url'] as String?),
            );
          });
        }

        final data = await ChatService.getMessages(widget.conversationId);
        if (mounted) {
          setState(() {
            _messages = data.map((e) => Message.fromMap(e)).toList();
          });
          _scrollToBottom();
          _markAsRead();
        }
      },
    );
  }

  Future<void> _markAsRead() async {
    await ChatService.markMessagesAsRead(widget.conversationId);
    ChatUnreadScope.refreshGlobal();
  }

  Future<void> _loadThreadContext() async {
    setState(() => _threadLoading = true);
    try {
      final row = await ChatService.getConversation(widget.conversationId);
      if (!mounted) return;
      if (row == null) {
        setState(() => _threadLoading = false);
        return;
      }

      final clientId = row['client_id'] as String?;
      final sellerId = row['seller_id'] as String?;
      if (clientId == null || sellerId == null) {
        setState(() => _threadLoading = false);
        return;
      }

      final items = await loadThreadContext(
        clientId: clientId,
        sellerId: sellerId,
        l10n: context.l10n,
        isClientViewer: _isClientViewer,
      );
      if (!mounted) return;
      setState(() {
        _threadItems = items;
        _threadLoading = false;
      });
    } catch (_) {
      if (mounted) setState(() => _threadLoading = false);
    }
  }

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    });
  }

  /// Optimistic text send: the message appears instantly in the UI and is
  /// reconciled with the server in the background. Failed sends are kept
  /// in the list with a retry affordance.
  Future<void> _sendMessage() async {
    final text = _messageController.text.trim();
    if (text.isEmpty) return;

    final pending = _PendingMessage(
      tempId: 't_${DateTime.now().microsecondsSinceEpoch}',
      content: text,
      createdAt: DateTime.now(),
    );

    _messageController.clear();
    setState(() {
      _pendingMessages.add(pending);
      _hasText = false;
    });
    _scrollToBottom();

    await _flushPending(pending);
  }

  Future<void> _flushPending(_PendingMessage pending) async {
    try {
      await ChatService.sendMessage(
        conversationId: widget.conversationId,
        content: pending.content,
        attachmentUrl: pending.attachmentUrl,
      );
      // Success: the realtime subscription's onNewMessage will drop the
      // pending bubble and insert the confirmed server copy in one setState,
      // eliminating the double-render flicker. We intentionally do NOT remove
      // the pending entry here.
    } catch (e) {
      if (!mounted) return;
      setState(() => pending.status = _PendingStatus.failed);
      // Show a clear toast so the failure is noticed even if the user has
      // scrolled away from the failed bubble.
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(context.l10n.chatSendFailed),
          action: SnackBarAction(
            label: context.l10n.retry,
            onPressed: () => _retryPending(pending),
          ),
          backgroundColor: const Color(0xFFDC2626),
          behavior: SnackBarBehavior.floating,
          duration: const Duration(seconds: 5),
        ),
      );
    }
  }

  Future<void> _retryPending(_PendingMessage pending) async {
    setState(() => pending.status = _PendingStatus.sending);
    await _flushPending(pending);
  }

  Future<void> _pickAndSendImage() async {
    if (_isUploadingAttachment) return;
    try {
      final picked = await _imagePicker.pickImage(
        source: ImageSource.gallery,
        imageQuality: 70,
      );
      if (picked == null) return;

      setState(() => _isUploadingAttachment = true);

      final file = File(picked.path);
      final url =
          await ChatService.uploadAttachment(file, widget.conversationId);

      // After upload, queue the message optimistically just like text.
      final pending = _PendingMessage(
        tempId: 't_${DateTime.now().microsecondsSinceEpoch}',
        content: '',
        attachmentUrl: url,
        createdAt: DateTime.now(),
      );
      setState(() {
        _pendingMessages.add(pending);
        _isUploadingAttachment = false;
      });
      _scrollToBottom();
      await _flushPending(pending);
    } catch (e) {
      if (mounted) {
        setState(() => _isUploadingAttachment = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(context.l10n.errorWithDetail('$e'))),
        );
      }
    }
  }

  void _showBlockPopUp() {
    showDialog(
      barrierDismissible: false,
      context: context,
      builder: (BuildContext context) {
        return Dialog(
          shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16.0)),
          child: const BlockingReasonPopUp(),
        );
      },
    );
  }

  String _formatMessageTime(BuildContext context, DateTime dateTime) {
    return MaterialLocalizations.of(context).formatTimeOfDay(
      TimeOfDay.fromDateTime(dateTime),
      alwaysUse24HourFormat: MediaQuery.alwaysUse24HourFormatOf(context),
    );
  }

  String _formatDateHeader(BuildContext context, DateTime dateTime) {
    final l10n = context.l10n;
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final messageDate = DateTime(dateTime.year, dateTime.month, dateTime.day);

    if (messageDate == today) return l10n.calendarToday;
    if (messageDate == today.subtract(const Duration(days: 1))) {
      return l10n.calendarYesterday;
    }
    return MaterialLocalizations.of(context).formatShortDate(dateTime);
  }

  bool _isSameDay(DateTime a, DateTime b) =>
      a.year == b.year && a.month == b.month && a.day == b.day;

  bool _shouldShowDateHeader(int index) {
    if (index == 0) return true;
    return !_isSameDay(_messages[index].createdAt,
        _messages[index - 1].createdAt);
  }

  /// True when the previous message in the list is from the same sender and same day.
  bool _isContinuationFromPrevious(int index) {
    if (index == 0) return false;
    if (!_isSameDay(
        _messages[index].createdAt, _messages[index - 1].createdAt)) {
      return false;
    }
    return _messages[index].senderId == _messages[index - 1].senderId;
  }

  /// True when the next message is from the same sender and same day.
  bool _isContinuedByNext(int index) {
    if (index == _messages.length - 1) return false;
    if (!_isSameDay(
        _messages[index].createdAt, _messages[index + 1].createdAt)) {
      return false;
    }
    return _messages[index].senderId == _messages[index + 1].senderId;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: kDarkWhite,
      appBar: _buildAppBar(),
      body: Column(
        children: [
          ChatThreadContextHeader(
            items: _threadItems,
            isClientViewer: _isClientViewer,
            highlightedOrderId: widget.orderContext?.orderId,
            isLoading: _threadLoading,
          ),
          Expanded(
            child: _isLoading
                ? _buildSkeleton()
                : (_messages.isEmpty && _pendingMessages.isEmpty)
                    ? _buildEmptyState()
                    : _buildMessageList(),
          ),
          _buildMessageInput(),
        ],
      ),
    );
  }

  // ---------------------------------------------------------------- App bar
  PreferredSizeWidget _buildAppBar() {
    final l10n = context.l10n;
    return AppBar(
      backgroundColor: kWhite,
      surfaceTintColor: kWhite,
      elevation: 0,
      scrolledUnderElevation: 0,
      iconTheme: const IconThemeData(color: kNeutralColor),
      leadingWidth: 44,
      leading: Padding(
        padding: const EdgeInsets.only(left: 8),
        child: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded, size: 18),
          onPressed: () => Navigator.of(context).maybePop(),
        ),
      ),
      titleSpacing: 0,
      title: InkWell(
        onTap: _threadItems.isEmpty
            ? null
            : () => showChatThreadContextSheet(
                  context,
                  items: _threadItems,
                  isClientViewer: _isClientViewer,
                  highlightedOrderId: widget.orderContext?.orderId,
                ),
        borderRadius: BorderRadius.circular(8),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            _appBarAvatar(),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    widget.otherUserName,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: kTextStyle.copyWith(
                      color: kNeutralColor,
                      fontWeight: FontWeight.w700,
                      fontSize: 15,
                    ),
                  ),
                  if (_threadItems.isNotEmpty)
                    Text(
                      _threadItems.length == 1
                          ? _threadItems.first.title
                          : context.l10n
                              .threadContextRelatedCount(_threadItems.length),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: kTextStyle.copyWith(
                        color: kPrimaryColor,
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                ],
              ),
            ),
          ],
        ),
      ),
      actions: [
        if (_threadItems.isNotEmpty)
          IconButton(
            tooltip: context.l10n.threadContextTitle,
            onPressed: () => showChatThreadContextSheet(
              context,
              items: _threadItems,
              isClientViewer: _isClientViewer,
              highlightedOrderId: widget.orderContext?.orderId,
            ),
            icon: Badge(
              isLabelVisible: _threadItems.length > 1,
              label: Text(
                '${_threadItems.length}',
                style: const TextStyle(fontSize: 10),
              ),
              child: const Icon(Icons.work_outline_rounded, color: kNeutralColor),
            ),
          ),
        Padding(
          padding: const EdgeInsets.only(right: 8),
          child: Container(
            decoration: BoxDecoration(
              color: kDarkWhite,
              shape: BoxShape.circle,
            ),
            child: PopupMenuButton<String>(
              icon: const Icon(FeatherIcons.moreVertical,
                  color: kNeutralColor, size: 18),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(14),
              ),
              itemBuilder: (BuildContext bc) => [
                PopupMenuItem(
                  value: 'block',
                  child: Row(
                    children: [
                      const Icon(Icons.block_rounded,
                          size: 18, color: kNeutralColor),
                      const SizedBox(width: 10),
                      Text(l10n.block,
                          style: kTextStyle.copyWith(color: kNeutralColor)),
                    ],
                  ),
                ),
                PopupMenuItem(
                  value: 'report',
                  child: Row(
                    children: [
                      const Icon(Icons.flag_outlined,
                          size: 18, color: kNeutralColor),
                      const SizedBox(width: 10),
                      Text(l10n.report,
                          style: kTextStyle.copyWith(color: kNeutralColor)),
                    ],
                  ),
                ),
              ],
              onSelected: (value) {
                if (value == 'block') {
                  Future.delayed(Duration.zero, _showBlockPopUp);
                } else if (value == 'report') {
                  Future.delayed(Duration.zero, _openReport);
                }
              },
            ),
          ),
        ),
      ],
      bottom: PreferredSize(
        preferredSize: const Size.fromHeight(1),
        child: Container(height: 1, color: kBorderColorTextField),
      ),
    );
  }

  Future<void> _openReport() async {
    final otherId = widget.otherUserId;
    try {
      final role = await AuthService.getUserRole();
      if (!mounted) return;
      if (role == 'seller') {
        SellerReport(
          reportedUserId: otherId,
          reportedUserName: widget.otherUserName,
        ).launch(context);
      } else {
        ClientReport(
          reportedUserId: otherId,
          reportedUserName: widget.otherUserName,
        ).launch(context);
      }
    } catch (_) {
      if (!mounted) return;
      ClientReport(
        reportedUserId: otherId,
        reportedUserName: widget.otherUserName,
      ).launch(context);
    }
  }

  Widget _appBarAvatar() {
    final hasImage = widget.otherUserImage.isNotEmpty;
    final initial = widget.otherUserName.isNotEmpty
        ? widget.otherUserName[0].toUpperCase()
        : '?';
    return Container(
      width: 38,
      height: 38,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: kPrimaryColor.withOpacity(0.10),
        image: hasImage
            ? DecorationImage(
                image: NetworkImage(widget.otherUserImage),
                fit: BoxFit.cover,
              )
            : null,
      ),
      alignment: Alignment.center,
      child: hasImage
          ? null
          : Text(
              initial,
              style: kTextStyle.copyWith(
                color: kPrimaryColor,
                fontWeight: FontWeight.w700,
                fontSize: 15,
              ),
            ),
    );
  }

  // ---------------------------------------------------------------- Empty
  Widget _buildEmptyState() {
    final l10n = context.l10n;
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 40),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(22),
              decoration: BoxDecoration(
                color: kPrimaryColor.withOpacity(0.10),
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.chat_bubble_outline_rounded,
                  color: kPrimaryColor, size: 48),
            ),
            const SizedBox(height: 16),
            Text(
              l10n.sayHelloTo(widget.otherUserName),
              textAlign: TextAlign.center,
              style: kTextStyle.copyWith(
                color: kNeutralColor,
                fontWeight: FontWeight.w700,
                fontSize: 16,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              l10n.startConversationFirstMessage,
              textAlign: TextAlign.center,
              style: kTextStyle.copyWith(
                color: kLightNeutralColor,
                fontSize: 13,
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ---------------------------------------------------------------- Messages
  Widget _buildMessageList() {
    final totalCount = _messages.length + _pendingMessages.length;
    return ListView.builder(
      controller: _scrollController,
      padding: const EdgeInsets.fromLTRB(14, 10, 14, 14),
      physics: const BouncingScrollPhysics(),
      itemCount: totalCount,
      itemBuilder: (context, index) {
        if (index < _messages.length) {
          return _buildRealMessageItem(index);
        }
        final pending = _pendingMessages[index - _messages.length];
        final isFirstPending = index == _messages.length;
        return _buildPendingBubble(pending, isFirstPending: isFirstPending);
      },
    );
  }

  Widget _buildRealMessageItem(int index) {
    final message = _messages[index];
    final isMine = message.isMine(_currentUserId);
    final showDateHeader = _shouldShowDateHeader(index);
    final isContinuation =
        !showDateHeader && _isContinuationFromPrevious(index);
    final isContinued = _isContinuedByNext(index);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        if (showDateHeader) _dateHeader(context, message.createdAt),
        _buildMessageBubble(
          message,
          isMine: isMine,
          isContinuation: isContinuation,
          isContinued: isContinued,
        ),
      ],
    );
  }

  Widget _dateHeader(BuildContext context, DateTime date) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 12),
      child: Center(
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
          decoration: BoxDecoration(
            color: kDarkWhite,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: kBorderColorTextField),
          ),
          child: Text(
            _formatDateHeader(context, date),
            style: kTextStyle.copyWith(
              color: kLightNeutralColor,
              fontWeight: FontWeight.w600,
              fontSize: 11,
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildMessageBubble(
    Message message, {
    required bool isMine,
    required bool isContinuation,
    required bool isContinued,
  }) {
    final bidInfo = _parseBidMessage(message.content);
    if (message.isJobOfferMessage ||
        message.jobOfferId != null ||
        bidInfo != null) {
      return ChatJobOfferCard(
        message: message,
        conversationId: widget.conversationId,
        isMine: isMine,
        formatTime: (dt) => _formatMessageTime(context, dt),
        smallAvatar: _smallAvatar(),
        legacyBid: bidInfo == null
            ? null
            : LegacyBidInfo(
                jobTitle: bidInfo.jobTitle,
                amount: bidInfo.amount,
                delivery: bidInfo.delivery,
                proposal: bidInfo.proposal,
              ),
      );
    }

    final radius = const Radius.circular(18);
    final smallRadius = const Radius.circular(6);

    final borderRadius = BorderRadius.only(
      topLeft: isMine ? radius : (isContinuation ? smallRadius : radius),
      topRight: !isMine ? radius : (isContinuation ? smallRadius : radius),
      bottomLeft: !isMine
          ? (isContinued ? radius : smallRadius)
          : radius,
      bottomRight: isMine
          ? (isContinued ? radius : smallRadius)
          : radius,
    );

    return Padding(
      padding: EdgeInsets.only(
        top: isContinuation ? 3 : 8,
        bottom: 0,
      ),
      child: Row(
        mainAxisAlignment:
            isMine ? MainAxisAlignment.end : MainAxisAlignment.start,
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          if (!isMine) ...[
            if (!isContinued)
              _smallAvatar()
            else
              const SizedBox(width: 28),
            const SizedBox(width: 6),
          ],
          Flexible(
            child: Column(
              crossAxisAlignment:
                  isMine ? CrossAxisAlignment.end : CrossAxisAlignment.start,
              children: [
                Container(
                  constraints: BoxConstraints(
                    maxWidth: MediaQuery.of(context).size.width * 0.72,
                  ),
                  padding: const EdgeInsets.symmetric(
                      horizontal: 14, vertical: 10),
                  decoration: BoxDecoration(
                    gradient: isMine
                        ? const LinearGradient(
                            colors: kChatBubbleGradient,
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                          )
                        : null,
                    color: isMine ? null : kWhite,
                    borderRadius: borderRadius,
                    boxShadow: [
                      BoxShadow(
                        color: isMine
                            ? kPrimaryColor.withOpacity(0.22)
                            : Colors.black.withOpacity(0.04),
                        blurRadius: 10,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: _bubbleContent(message, isMine),
                ),
                if (!isContinued) ...[
                  const SizedBox(height: 4),
                  Padding(
                    padding: EdgeInsets.only(
                      left: isMine ? 0 : 6,
                      right: isMine ? 6 : 0,
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          _formatMessageTime(context, message.createdAt),
                          style: kTextStyle.copyWith(
                            color: kLightNeutralColor,
                            fontSize: 10,
                          ),
                        ),
                        if (isMine) ...[
                          const SizedBox(width: 4),
                          Icon(
                            message.isRead
                                ? Icons.done_all_rounded
                                : Icons.done_rounded,
                            size: 14,
                            color: message.isRead
                                ? kPrimaryColor
                                : kLightNeutralColor,
                          ),
                        ],
                      ],
                    ),
                  ),
                ],
              ],
            ),
          ),
          if (isMine) const SizedBox(width: 4),
        ],
      ),
    );
  }

  Widget _bubbleContent(Message message, bool isMine) {
    final l10n = context.l10n;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (message.attachmentUrl != null) ...[
          if (message.attachmentType == 'image')
            ClipRRect(
              borderRadius: BorderRadius.circular(12),
              child: Image.network(
                message.attachmentUrl!,
                width: 220,
                height: 220,
                fit: BoxFit.cover,
                loadingBuilder: (_, child, progress) {
                  if (progress == null) return child;
                  return Container(
                    width: 220,
                    height: 220,
                    color: kDarkWhite,
                    child: const Center(
                      child: CircularProgressIndicator(
                          color: kPrimaryColor, strokeWidth: 2),
                    ),
                  );
                },
                errorBuilder: (_, __, ___) => Container(
                  width: 220,
                  height: 220,
                  color: kDarkWhite,
                  child: const Icon(Icons.broken_image_outlined,
                      color: kLightNeutralColor, size: 32),
                ),
              ),
            )
          else
            Container(
              padding: const EdgeInsets.symmetric(
                  horizontal: 10, vertical: 8),
              decoration: BoxDecoration(
                color: (isMine ? Colors.white : kPrimaryColor)
                    .withOpacity(0.15),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.insert_drive_file_rounded,
                      color: isMine ? Colors.white : kPrimaryColor,
                      size: 18),
                  const SizedBox(width: 6),
                  Text(
                    l10n.chatAttachment,
                    style: kTextStyle.copyWith(
                      color: isMine ? Colors.white : kPrimaryColor,
                      fontWeight: FontWeight.w600,
                      fontSize: 12,
                    ),
                  ),
                ],
              ),
            ),
          if (message.content.isNotEmpty) const SizedBox(height: 6),
        ],
        if (message.content.isNotEmpty)
          Text(
            message.content,
            style: kTextStyle.copyWith(
              color: isMine ? Colors.white : kNeutralColor,
              fontSize: 14,
              height: 1.35,
            ),
          ),
      ],
    );
  }

  Widget _smallAvatar() {
    final hasImage = widget.otherUserImage.isNotEmpty;
    final initial = widget.otherUserName.isNotEmpty
        ? widget.otherUserName[0].toUpperCase()
        : '?';
    return Container(
      width: 28,
      height: 28,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: kPrimaryColor.withOpacity(0.10),
        image: hasImage
            ? DecorationImage(
                image: NetworkImage(widget.otherUserImage),
                fit: BoxFit.cover)
            : null,
      ),
      alignment: Alignment.center,
      child: hasImage
          ? null
          : Text(
              initial,
              style: kTextStyle.copyWith(
                color: kPrimaryColor,
                fontWeight: FontWeight.w700,
                fontSize: 11,
              ),
            ),
    );
  }

  // ---------------------------------------------------------------- Input
  Widget _buildMessageInput() {
    final l10n = context.l10n;
    return SafeArea(
      top: false,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(12, 6, 12, 10),
        child: Container(
          padding: const EdgeInsets.fromLTRB(6, 6, 6, 6),
          decoration: BoxDecoration(
            color: kWhite,
            borderRadius: BorderRadius.circular(28),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.06),
                blurRadius: 18,
                offset: const Offset(0, 6),
              ),
            ],
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              GestureDetector(
                onTap: _isUploadingAttachment ? null : _pickAndSendImage,
                child: Container(
                  margin: const EdgeInsets.all(2),
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: kPrimaryColor.withOpacity(0.10),
                    shape: BoxShape.circle,
                  ),
                  child: _isUploadingAttachment
                      ? const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            valueColor: AlwaysStoppedAnimation<Color>(
                                kPrimaryColor),
                          ),
                        )
                      : const Icon(
                          Icons.attach_file_rounded,
                          color: kPrimaryColor,
                          size: 20,
                        ),
                ),
              ),
              const SizedBox(width: 4),
              Expanded(
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxHeight: 120),
                  child: TextField(
                    controller: _messageController,
                    focusNode: _msgFocusNode,
                    minLines: 1,
                    maxLines: 5,
                    textInputAction: TextInputAction.newline,
                    style: kTextStyle.copyWith(
                      color: kNeutralColor,
                      fontSize: 14,
                    ),
                    decoration: InputDecoration(
                      border: InputBorder.none,
                      isCollapsed: true,
                      contentPadding: const EdgeInsets.symmetric(
                          horizontal: 6, vertical: 12),
                      hintText: l10n.typeAMessage,
                      hintStyle: kTextStyle.copyWith(
                        color: kLightNeutralColor,
                        fontSize: 14,
                      ),
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 4),
              _buildSendButton(),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSendButton() {
    final active = _hasText;
    return AnimatedContainer(
      duration: const Duration(milliseconds: 220),
      curve: Curves.easeOut,
      width: 42,
      height: 42,
      margin: const EdgeInsets.all(2),
      decoration: BoxDecoration(
        gradient: active
            ? const LinearGradient(
                colors: kChatBubbleGradient,
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              )
            : null,
        color: active ? null : kDarkWhite,
        shape: BoxShape.circle,
        boxShadow: active
            ? [
                BoxShadow(
                  color: kPrimaryColor.withOpacity(0.30),
                  blurRadius: 10,
                  offset: const Offset(0, 4),
                ),
              ]
            : null,
      ),
      child: Material(
        color: Colors.transparent,
        shape: const CircleBorder(),
        child: InkWell(
          customBorder: const CircleBorder(),
          onTap: active ? _sendMessage : null,
          child: Center(
            child: Icon(
              Icons.send_rounded,
              size: 20,
              color: active ? Colors.white : kLightNeutralColor,
            ),
          ),
        ),
      ),
    );
  }

  // ---------------------------------------------------------------- Pending bubble
  Widget _buildPendingBubble(_PendingMessage pending,
      {required bool isFirstPending}) {
    final l10n = context.l10n;
    final maxWidth = MediaQuery.of(context).size.width * 0.72;
    final isFailed = pending.status == _PendingStatus.failed;
    final radius = const Radius.circular(18);
    final smallRadius = const Radius.circular(6);

    return Padding(
      padding: EdgeInsets.only(top: isFirstPending ? 8 : 3),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.end,
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          Flexible(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Opacity(
                  opacity: isFailed ? 1 : 0.75,
                  child: Container(
                    constraints: BoxConstraints(maxWidth: maxWidth),
                    padding: const EdgeInsets.symmetric(
                        horizontal: 14, vertical: 10),
                    decoration: BoxDecoration(
                      gradient: isFailed
                          ? null
                          : const LinearGradient(
                              colors: kChatBubbleGradient,
                              begin: Alignment.topLeft,
                              end: Alignment.bottomRight,
                            ),
                      color: isFailed
                          ? const Color(0xFFFEE2E2)
                          : null,
                      border: isFailed
                          ? Border.all(
                              color: const Color(0xFFEF4444), width: 1)
                          : null,
                      borderRadius: BorderRadius.only(
                        topLeft: radius,
                        topRight: radius,
                        bottomLeft: radius,
                        bottomRight: smallRadius,
                      ),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        if (pending.attachmentUrl != null) ...[
                          ClipRRect(
                            borderRadius: BorderRadius.circular(12),
                            child: Image.network(
                              pending.attachmentUrl!,
                              width: 220,
                              height: 220,
                              fit: BoxFit.cover,
                              errorBuilder: (_, __, ___) => Container(
                                width: 220,
                                height: 220,
                                color: kDarkWhite,
                                child: const Icon(
                                    Icons.broken_image_outlined,
                                    color: kLightNeutralColor,
                                    size: 32),
                              ),
                            ),
                          ),
                          if (pending.content.isNotEmpty)
                            const SizedBox(height: 6),
                        ],
                        if (pending.content.isNotEmpty)
                          Text(
                            pending.content,
                            style: kTextStyle.copyWith(
                              color: isFailed
                                  ? const Color(0xFF991B1B)
                                  : Colors.white,
                              fontSize: 14,
                              height: 1.35,
                            ),
                          ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 4),
                Padding(
                  padding: const EdgeInsets.only(right: 6),
                  child: isFailed
                      ? GestureDetector(
                          onTap: () => _retryPending(pending),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              const Icon(Icons.error_outline_rounded,
                                  size: 14, color: Color(0xFFEF4444)),
                              const SizedBox(width: 4),
                              Text(
                                l10n.failedTapToRetry,
                                style: kTextStyle.copyWith(
                                  color: const Color(0xFFEF4444),
                                  fontSize: 10,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ],
                          ),
                        )
                      : Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const SizedBox(
                              width: 10,
                              height: 10,
                              child: CircularProgressIndicator(
                                strokeWidth: 1.5,
                                valueColor: AlwaysStoppedAnimation<Color>(
                                    kLightNeutralColor),
                              ),
                            ),
                            const SizedBox(width: 4),
                            Text(
                              l10n.sending,
                              style: kTextStyle.copyWith(
                                color: kLightNeutralColor,
                                fontSize: 10,
                              ),
                            ),
                          ],
                        ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 4),
        ],
      ),
    );
  }

  // ---------------------------------------------------------------- Skeleton
  Widget _buildSkeleton() {
    // A plausible mix of incoming/outgoing bubbles of varying widths.
    final stub = const <_SkeletonStub>[
      _SkeletonStub(mine: false, widthFactor: 0.55),
      _SkeletonStub(mine: true, widthFactor: 0.40),
      _SkeletonStub(mine: false, widthFactor: 0.70),
      _SkeletonStub(mine: true, widthFactor: 0.50),
      _SkeletonStub(mine: false, widthFactor: 0.35),
      _SkeletonStub(mine: true, widthFactor: 0.60),
    ];

    return _Shimmer(
      child: ListView.builder(
        physics: const NeverScrollableScrollPhysics(),
        padding: const EdgeInsets.fromLTRB(14, 12, 14, 14),
        itemCount: stub.length,
        itemBuilder: (context, i) {
          final s = stub[i];
          final width = MediaQuery.of(context).size.width * s.widthFactor;
          return Padding(
            padding: const EdgeInsets.symmetric(vertical: 6),
            child: Row(
              mainAxisAlignment:
                  s.mine ? MainAxisAlignment.end : MainAxisAlignment.start,
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                if (!s.mine) ...[
                  const _SkeletonBox(width: 28, height: 28, radius: 14),
                  const SizedBox(width: 6),
                ],
                _SkeletonBox(width: width, height: 36, radius: 18),
              ],
            ),
          );
        },
      ),
    );
  }

  // ---------------------------------------------------------------- Bid card
  _BidMessageInfo? _parseBidMessage(String content) {
    final lines = content.split('\n').map((l) => l.trim()).toList();
    if (lines.isEmpty ||
        (!lines[0].contains('New bid for') &&
            !lines[0].contains('Application for'))) {
      return null;
    }

    final titleMatch = RegExp(r'"([^"]+)"').firstMatch(lines[0]);
    final jobTitle = titleMatch?.group(1) ?? '';
    if (jobTitle.isEmpty || lines.length < 2) return null;

    final amountMatch = RegExp(
      r'(?:Amount:|posted rate:)\s*([^·\n]+?)(?:\s*·|$)',
    ).firstMatch(lines[1]);
    final deliveryMatch = RegExp(r'·\s*Delivery:\s*(.+)$').firstMatch(lines[1]);
    final amount = amountMatch?.group(1)?.trim() ?? '';
    final delivery = deliveryMatch?.group(1)?.trim() ?? 'Agreed in chat';
    if (amount.isEmpty) return null;

    String? proposal;
    if (lines.length > 2) {
      proposal = lines.sublist(2).join('\n').trim();
      if (proposal.isEmpty) proposal = null;
    }

    return _BidMessageInfo(jobTitle: jobTitle, amount: amount, delivery: delivery, proposal: proposal);
  }
}

class _BidMessageInfo {
  final String jobTitle;
  final String amount;
  final String delivery;
  final String? proposal;
  _BidMessageInfo({required this.jobTitle, required this.amount, required this.delivery, this.proposal});
}

// =============================================================
// Pending message model
// =============================================================
enum _PendingStatus { sending, failed }

class _PendingMessage {
  final String tempId;
  final String content;
  final String? attachmentUrl;
  final DateTime createdAt;
  _PendingStatus status = _PendingStatus.sending;

  _PendingMessage({
    required this.tempId,
    required this.content,
    this.attachmentUrl,
    required this.createdAt,
  });
}

// =============================================================
// Shimmer primitives
// =============================================================
class _SkeletonStub {
  final bool mine;
  final double widthFactor;
  const _SkeletonStub({required this.mine, required this.widthFactor});
}

class _SkeletonBox extends StatelessWidget {
  final double? width;
  final double height;
  final double radius;

  const _SkeletonBox({
    this.width,
    required this.height,
    this.radius = 8,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: width,
      height: height,
      decoration: BoxDecoration(
        color: const Color(0xFFE6E6E6),
        borderRadius: BorderRadius.circular(radius),
      ),
    );
  }
}

class _Shimmer extends StatefulWidget {
  final Widget child;
  const _Shimmer({required this.child});

  @override
  State<_Shimmer> createState() => _ShimmerState();
}

class _ShimmerState extends State<_Shimmer>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 1400),
  )..repeat();

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) => ShaderMask(
        blendMode: BlendMode.srcATop,
        shaderCallback: (bounds) => LinearGradient(
          begin: Alignment.centerLeft,
          end: Alignment.centerRight,
          colors: const [
            Color(0xFFE6E6E6),
            Color(0xFFF6F6F6),
            Color(0xFFE6E6E6),
          ],
          stops: const [0.1, 0.5, 0.9],
          transform: _SlidingGradientTransform(_controller.value),
        ).createShader(bounds),
        child: child,
      ),
      child: widget.child,
    );
  }
}

class _SlidingGradientTransform extends GradientTransform {
  final double slidePercent;
  const _SlidingGradientTransform(this.slidePercent);

  @override
  Matrix4? transform(Rect bounds, {TextDirection? textDirection}) {
    return Matrix4.translationValues(
      bounds.width * (slidePercent * 2 - 1),
      0,
      0,
    );
  }
}
