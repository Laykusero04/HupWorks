import 'package:flutter/material.dart';
import 'package:nb_utils/nb_utils.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../services/chat_service.dart';
import '../../widgets/constant.dart';
import 'chat_inbox.dart';
import 'model/chat_model.dart';

class ChatScreen extends StatefulWidget {
  const ChatScreen({Key? key}) : super(key: key);

  @override
  State<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen> {
  List<Conversation> _conversations = [];
  bool _isLoading = true;
  RealtimeChannel? _conversationChannel;

  String get _currentUserId => Supabase.instance.client.auth.currentUser?.id ?? '';

  @override
  void initState() {
    super.initState();
    _loadConversations();
    _subscribeToUpdates();
  }

  @override
  void dispose() {
    if (_conversationChannel != null) {
      ChatService.unsubscribe(_conversationChannel!);
    }
    super.dispose();
  }

  Future<void> _loadConversations() async {
    try {
      final data = await ChatService.getConversations();
      if (mounted) {
        setState(() {
          _conversations = data.map((e) => Conversation.fromMap(e)).toList();
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to load conversations: $e')),
        );
      }
    }
  }

  void _subscribeToUpdates() {
    _conversationChannel = ChatService.subscribeToConversations(
      onUpdate: () => _loadConversations(),
    );
  }

  String _formatTime(DateTime dateTime) {
    final now = DateTime.now();
    final diff = now.difference(dateTime);

    if (diff.inDays > 0) {
      if (diff.inDays == 1) return 'Yesterday';
      return '${dateTime.day}/${dateTime.month}/${dateTime.year}';
    }

    final hour = dateTime.hour;
    final minute = dateTime.minute.toString().padLeft(2, '0');
    final period = hour >= 12 ? 'PM' : 'AM';
    final displayHour = hour == 0 ? 12 : (hour > 12 ? hour - 12 : hour);
    return '$displayHour:$minute $period';
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Scaffold(
        backgroundColor: kDarkWhite,
        appBar: AppBar(
          iconTheme: const IconThemeData(color: kNeutralColor),
          backgroundColor: kDarkWhite,
          elevation: 0.0,
          centerTitle: true,
          title: Text(
            'Message',
            style: kTextStyle.copyWith(color: kNeutralColor, fontWeight: FontWeight.bold),
          ),
        ),
        body: _isLoading
            ? const Center(child: CircularProgressIndicator(color: kPrimaryColor))
            : _conversations.isEmpty
                ? Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(Icons.chat_bubble_outline, size: 64, color: kLightNeutralColor),
                        const SizedBox(height: 16),
                        Text(
                          'No conversations yet',
                          style: kTextStyle.copyWith(color: kLightNeutralColor, fontSize: 16),
                        ),
                      ],
                    ),
                  )
                : Padding(
                    padding: const EdgeInsets.only(top: 10.0),
                    child: Container(
                      padding: const EdgeInsets.only(left: 10.0, right: 10.0),
                      decoration: const BoxDecoration(
                        color: kWhite,
                        borderRadius: BorderRadius.only(
                          topLeft: Radius.circular(30.0),
                          topRight: Radius.circular(30.0),
                        ),
                      ),
                      child: RefreshIndicator(
                        color: kPrimaryColor,
                        onRefresh: _loadConversations,
                        child: ListView.separated(
                          physics: const AlwaysScrollableScrollPhysics(parent: BouncingScrollPhysics()),
                          itemCount: _conversations.length,
                          separatorBuilder: (_, __) => const Divider(
                            thickness: 1.0,
                            color: kBorderColorTextField,
                            height: 0,
                          ),
                          itemBuilder: (context, index) {
                            final conversation = _conversations[index];
                            final otherUser = conversation.getOtherUser(_currentUserId);
                            final name = otherUser['name'] ?? 'Unknown';
                            final imageUrl = otherUser['profile_image_url'] ?? '';

                            return ListTile(
                              contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                              leading: CircleAvatar(
                                radius: 25,
                                backgroundImage: imageUrl.isNotEmpty ? NetworkImage(imageUrl) : null,
                                backgroundColor: kDarkWhite,
                                child: imageUrl.isEmpty
                                    ? Text(
                                        name.isNotEmpty ? name[0].toUpperCase() : '?',
                                        style: kTextStyle.copyWith(
                                          color: kPrimaryColor,
                                          fontWeight: FontWeight.bold,
                                          fontSize: 18,
                                        ),
                                      )
                                    : null,
                              ),
                              title: Text(
                                name,
                                style: kTextStyle.copyWith(
                                  color: kNeutralColor,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                              subtitle: Text(
                                conversation.lastMessage ?? 'Start a conversation',
                                style: kTextStyle.copyWith(
                                  color: kLightNeutralColor,
                                  fontSize: 13,
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                              trailing: Text(
                                _formatTime(conversation.lastMessageAt),
                                style: kTextStyle.copyWith(
                                  color: kLightNeutralColor,
                                  fontSize: 12,
                                ),
                              ),
                              onTap: () {
                                ChatInbox(
                                  conversationId: conversation.id,
                                  otherUserName: name,
                                  otherUserImage: imageUrl,
                                ).launch(context);
                              },
                            );
                          },
                        ),
                      ),
                    ),
                  ),
      ),
    );
  }
}
