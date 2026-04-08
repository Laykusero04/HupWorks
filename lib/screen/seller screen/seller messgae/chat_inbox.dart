import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_feather_icons/flutter_feather_icons.dart';
import 'package:freelancer/screen/widgets/constant.dart';
import 'package:image_picker/image_picker.dart';
import 'package:nb_utils/nb_utils.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../services/chat_service.dart';
import '../seller popUp/seller_popup.dart';
import 'model/chat_model.dart';

class ChatInbox extends StatefulWidget {
  final String conversationId;
  final String otherUserName;
  final String otherUserImage;

  const ChatInbox({
    super.key,
    required this.conversationId,
    required this.otherUserName,
    required this.otherUserImage,
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
  bool _isLoading = true;
  bool _isSending = false;
  RealtimeChannel? _messageChannel;

  String get _currentUserId => Supabase.instance.client.auth.currentUser?.id ?? '';

  @override
  void initState() {
    super.initState();
    _loadMessages();
    _subscribeToMessages();
    _markAsRead();
  }

  @override
  void dispose() {
    _messageController.dispose();
    _scrollController.dispose();
    _msgFocusNode.dispose();
    if (_messageChannel != null) {
      ChatService.unsubscribe(_messageChannel!);
    }
    super.dispose();
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
          SnackBar(content: Text('Failed to load messages: $e')),
        );
      }
    }
  }

  void _subscribeToMessages() {
    _messageChannel = ChatService.subscribeToMessages(
      conversationId: widget.conversationId,
      onNewMessage: (newRecord) async {
        // Fetch the full message with sender info
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

  Future<void> _sendMessage() async {
    final text = _messageController.text.trim();
    if (text.isEmpty || _isSending) return;

    _messageController.clear();
    setState(() => _isSending = true);

    try {
      await ChatService.sendMessage(
        conversationId: widget.conversationId,
        content: text,
      );
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to send message: $e')),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isSending = false);
        FocusScope.of(context).requestFocus(_msgFocusNode);
      }
    }
  }

  Future<void> _pickAndSendImage() async {
    try {
      final picked = await _imagePicker.pickImage(
        source: ImageSource.gallery,
        imageQuality: 70,
      );
      if (picked == null) return;

      setState(() => _isSending = true);

      final file = File(picked.path);
      final url = await ChatService.uploadAttachment(file, widget.conversationId);

      await ChatService.sendMessage(
        conversationId: widget.conversationId,
        content: '',
        attachmentUrl: url,
      );
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to send attachment: $e')),
        );
      }
    } finally {
      if (mounted) setState(() => _isSending = false);
    }
  }

  void _showBlockPopUp() {
    showDialog(
      barrierDismissible: false,
      context: context,
      builder: (BuildContext context) {
        return Dialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16.0)),
          child: const BlockingReasonPopUp(),
        );
      },
    );
  }

  String _formatMessageTime(DateTime dateTime) {
    final hour = dateTime.hour;
    final minute = dateTime.minute.toString().padLeft(2, '0');
    final period = hour >= 12 ? 'PM' : 'AM';
    final displayHour = hour == 0 ? 12 : (hour > 12 ? hour - 12 : hour);
    return '$displayHour:$minute $period';
  }

  String _formatDateHeader(DateTime dateTime) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final messageDate = DateTime(dateTime.year, dateTime.month, dateTime.day);

    if (messageDate == today) return 'Today';
    if (messageDate == today.subtract(const Duration(days: 1))) return 'Yesterday';
    return '${dateTime.day}/${dateTime.month}/${dateTime.year}';
  }

  bool _shouldShowDateHeader(int index) {
    if (index == 0) return true;
    final current = DateTime(_messages[index].createdAt.year, _messages[index].createdAt.month, _messages[index].createdAt.day);
    final previous = DateTime(_messages[index - 1].createdAt.year, _messages[index - 1].createdAt.month, _messages[index - 1].createdAt.day);
    return current != previous;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: kDarkWhite,
      appBar: AppBar(
        automaticallyImplyLeading: true,
        leadingWidth: 24,
        iconTheme: const IconThemeData(color: kNeutralColor),
        backgroundColor: kDarkWhite,
        title: Row(
          mainAxisAlignment: MainAxisAlignment.start,
          children: [
            CircleAvatar(
              radius: 20,
              backgroundImage: widget.otherUserImage.isNotEmpty ? NetworkImage(widget.otherUserImage) : null,
              backgroundColor: kWhite,
              child: widget.otherUserImage.isEmpty
                  ? Text(
                      widget.otherUserName.isNotEmpty ? widget.otherUserName[0].toUpperCase() : '?',
                      style: kTextStyle.copyWith(color: kPrimaryColor, fontWeight: FontWeight.bold),
                    )
                  : null,
            ),
            8.width,
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(widget.otherUserName, style: boldTextStyle(), overflow: TextOverflow.ellipsis),
                ],
              ),
            ),
          ],
        ),
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 10.0),
            child: Container(
              padding: const EdgeInsets.all(5.0),
              decoration: const BoxDecoration(shape: BoxShape.circle, color: kWhite),
              child: PopupMenuButton(
                itemBuilder: (BuildContext bc) => [
                  PopupMenuItem(
                    child: Text('Block', style: kTextStyle.copyWith(color: kNeutralColor)),
                    onTap: () => Future.delayed(Duration.zero, _showBlockPopUp),
                  ),
                  PopupMenuItem(
                    child: Text('Report', style: kTextStyle.copyWith(color: kNeutralColor)),
                  ),
                ],
                child: const Icon(FeatherIcons.moreVertical, color: kNeutralColor),
              ),
            ),
          )
        ],
        shadowColor: kNeutralColor.withOpacity(0.5),
        elevation: 0,
      ),
      body: Column(
        children: [
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator(color: kPrimaryColor))
                : _messages.isEmpty
                    ? Center(
                        child: Text(
                          'No messages yet. Say hello!',
                          style: kTextStyle.copyWith(color: kLightNeutralColor),
                        ),
                      )
                    : ListView.builder(
                        controller: _scrollController,
                        padding: const EdgeInsets.all(16.0),
                        physics: const BouncingScrollPhysics(),
                        itemCount: _messages.length,
                        itemBuilder: (context, index) {
                          final message = _messages[index];
                          final isMine = message.isMine(_currentUserId);

                          return Column(
                            children: [
                              // Date header
                              if (_shouldShowDateHeader(index))
                                Padding(
                                  padding: const EdgeInsets.symmetric(vertical: 12),
                                  child: Text(
                                    _formatDateHeader(message.createdAt),
                                    style: secondaryTextStyle(size: 13),
                                  ),
                                ),
                              // Message bubble
                              _buildMessageBubble(message, isMine),
                              const SizedBox(height: 8),
                            ],
                          );
                        },
                      ),
          ),
          // Message input
          _buildMessageInput(),
        ],
      ),
    );
  }

  Widget _buildMessageBubble(Message message, bool isMine) {
    return Row(
      mainAxisAlignment: isMine ? MainAxisAlignment.end : MainAxisAlignment.start,
      crossAxisAlignment: CrossAxisAlignment.end,
      children: [
        if (!isMine) ...[
          CircleAvatar(
            radius: 16,
            backgroundImage: widget.otherUserImage.isNotEmpty ? NetworkImage(widget.otherUserImage) : null,
            backgroundColor: kDarkWhite,
            child: widget.otherUserImage.isEmpty
                ? Text(widget.otherUserName.isNotEmpty ? widget.otherUserName[0].toUpperCase() : '?',
                    style: const TextStyle(fontSize: 12, color: kPrimaryColor))
                : null,
          ),
          6.width,
        ],
        Flexible(
          child: Column(
            crossAxisAlignment: isMine ? CrossAxisAlignment.end : CrossAxisAlignment.start,
            children: [
              Container(
                decoration: boxDecorationWithRoundedCorners(
                  backgroundColor: isMine ? kPrimaryColor : kDarkWhite,
                  borderRadius: BorderRadius.only(
                    topRight: const Radius.circular(20.0),
                    topLeft: const Radius.circular(20.0),
                    bottomLeft: isMine ? const Radius.circular(20.0) : Radius.zero,
                    bottomRight: isMine ? Radius.zero : const Radius.circular(20.0),
                  ),
                ),
                padding: const EdgeInsets.all(12.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Attachment
                    if (message.attachmentUrl != null) ...[
                      if (message.attachmentType == 'image')
                        ClipRRect(
                          borderRadius: BorderRadius.circular(12),
                          child: Image.network(
                            message.attachmentUrl!,
                            width: 200,
                            height: 200,
                            fit: BoxFit.cover,
                            loadingBuilder: (_, child, progress) {
                              if (progress == null) return child;
                              return const SizedBox(
                                width: 200,
                                height: 200,
                                child: Center(child: CircularProgressIndicator(color: kPrimaryColor)),
                              );
                            },
                          ),
                        )
                      else
                        Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(Icons.attach_file, color: isMine ? white : kNeutralColor, size: 18),
                            4.width,
                            Text(
                              'Attachment',
                              style: primaryTextStyle(color: isMine ? white : kNeutralColor),
                            ),
                          ],
                        ),
                      if (message.content.isNotEmpty) 6.height,
                    ],
                    // Text content
                    if (message.content.isNotEmpty)
                      Text(
                        message.content,
                        style: primaryTextStyle(color: isMine ? white : kNeutralColor),
                      ),
                  ],
                ),
              ),
              4.height,
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    _formatMessageTime(message.createdAt),
                    style: secondaryTextStyle(size: 11),
                  ),
                  if (isMine) ...[
                    4.width,
                    Icon(
                      message.isRead ? Icons.done_all : Icons.done,
                      size: 14,
                      color: message.isRead ? kPrimaryColor : kLightNeutralColor,
                    ),
                  ],
                ],
              ),
            ],
          ),
        ),
        if (isMine) 6.width,
      ],
    );
  }

  Widget _buildMessageInput() {
    return Container(
      padding: MediaQuery.of(context).viewInsets,
      decoration: boxDecorationWithRoundedCorners(
        backgroundColor: context.cardColor,
        borderRadius: radius(0.0),
        border: Border.all(color: Colors.grey.shade100),
      ),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 8),
        child: Row(
          children: [
            // Attachment button
            GestureDetector(
              onTap: _isSending ? null : _pickAndSendImage,
              child: Container(
                padding: const EdgeInsets.all(10.0),
                decoration: const BoxDecoration(shape: BoxShape.circle, color: kDarkWhite),
                child: Icon(
                  FeatherIcons.image,
                  color: _isSending ? kLightNeutralColor : kNeutralColor,
                ),
              ),
            ),
            8.width,
            // Text field
            Expanded(
              child: Container(
                padding: const EdgeInsets.only(left: 10.0, right: 10.0),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(30.0),
                  color: kDarkWhite,
                ),
                child: AppTextField(
                  controller: _messageController,
                  textFieldType: TextFieldType.OTHER,
                  focus: _msgFocusNode,
                  decoration: InputDecoration(
                    border: InputBorder.none,
                    hintText: 'Message...',
                    hintStyle: secondaryTextStyle(size: 16),
                    suffixIcon: _isSending
                        ? const Padding(
                            padding: EdgeInsets.all(12.0),
                            child: SizedBox(
                              width: 20,
                              height: 20,
                              child: CircularProgressIndicator(strokeWidth: 2, color: kPrimaryColor),
                            ),
                          )
                        : const Icon(Icons.send_outlined, size: 24, color: kPrimaryColor).paddingAll(4.0).onTap(_sendMessage),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
