import 'dart:io';
import 'package:supabase_flutter/supabase_flutter.dart';

class ChatService {
  static final _client = Supabase.instance.client;

  /// Get or create a conversation between the current user and another user.
  /// Determines client/seller roles from profiles.
  static Future<Map<String, dynamic>> getOrCreateConversation(String otherUserId) async {
    final user = _client.auth.currentUser;
    if (user == null) throw Exception('Not authenticated');

    // Check if conversation already exists between these two users
    final existing = await _client
        .from('conversations')
        .select()
        .or('and(client_id.eq.${user.id},seller_id.eq.$otherUserId),and(client_id.eq.$otherUserId,seller_id.eq.${user.id})')
        .maybeSingle();

    if (existing != null) return existing;

    // Determine who is client and who is seller
    final myProfile = await _client.from('profiles').select('role').eq('id', user.id).single();
    final myRole = myProfile['role'] as String;

    final clientId = myRole == 'client' ? user.id : otherUserId;
    final sellerId = myRole == 'seller' ? user.id : otherUserId;

    final newConversation = await _client.from('conversations').insert({
      'client_id': clientId,
      'seller_id': sellerId,
    }).select().single();

    return newConversation;
  }

  /// Fetch conversation list for the current user, joined with profile info
  static Future<List<Map<String, dynamic>>> getConversations() async {
    final user = _client.auth.currentUser;
    if (user == null) return [];

    final data = await _client
        .from('conversations')
        .select('*, client:profiles!conversations_client_id_fkey(*), seller:profiles!conversations_seller_id_fkey(*)')
        .or('client_id.eq.${user.id},seller_id.eq.${user.id}')
        .order('last_message_at', ascending: false);

    return List<Map<String, dynamic>>.from(data);
  }

  /// Fetch messages for a conversation
  static Future<List<Map<String, dynamic>>> getMessages(String conversationId) async {
    final data = await _client
        .from('messages')
        .select('*, sender:profiles!messages_sender_id_fkey(id, name, profile_image_url)')
        .eq('conversation_id', conversationId)
        .order('created_at', ascending: true);

    return List<Map<String, dynamic>>.from(data);
  }

  /// Send a text message
  static Future<Map<String, dynamic>> sendMessage({
    required String conversationId,
    required String content,
    String? attachmentUrl,
  }) async {
    final user = _client.auth.currentUser;
    if (user == null) throw Exception('Not authenticated');

    final message = await _client.from('messages').insert({
      'conversation_id': conversationId,
      'sender_id': user.id,
      'content': content,
      if (attachmentUrl != null) 'attachment_url': attachmentUrl,
    }).select('*, sender:profiles!messages_sender_id_fkey(id, name, profile_image_url)').single();

    // Update conversation's last_message and last_message_at
    await _client.from('conversations').update({
      'last_message': content.isNotEmpty ? content : 'Attachment',
      'last_message_at': DateTime.now().toIso8601String(),
    }).eq('id', conversationId);

    return message;
  }

  /// Subscribe to new messages in a conversation (Supabase Realtime)
  static RealtimeChannel subscribeToMessages({
    required String conversationId,
    required void Function(Map<String, dynamic> message) onNewMessage,
  }) {
    final channel = _client.channel('messages:$conversationId');
    channel
        .onPostgresChanges(
          event: PostgresChangeEvent.insert,
          schema: 'public',
          table: 'messages',
          filter: PostgresChangeFilter(
            type: PostgresChangeFilterType.eq,
            column: 'conversation_id',
            value: conversationId,
          ),
          callback: (payload) {
            onNewMessage(payload.newRecord);
          },
        )
        .subscribe();

    return channel;
  }

  /// Subscribe to conversation list updates
  static RealtimeChannel subscribeToConversations({
    required void Function() onUpdate,
  }) {
    final user = _client.auth.currentUser;
    if (user == null) throw Exception('Not authenticated');

    final channel = _client.channel('conversations:${user.id}');
    channel
        .onPostgresChanges(
          event: PostgresChangeEvent.update,
          schema: 'public',
          table: 'conversations',
          callback: (payload) {
            onUpdate();
          },
        )
        .subscribe();

    return channel;
  }

  /// Mark messages as read in a conversation
  static Future<void> markMessagesAsRead(String conversationId) async {
    final user = _client.auth.currentUser;
    if (user == null) return;

    await _client
        .from('messages')
        .update({'read': true})
        .eq('conversation_id', conversationId)
        .neq('sender_id', user.id)
        .eq('read', false);
  }

  /// Get unread message count for a conversation
  static Future<int> getUnreadCount(String conversationId) async {
    final user = _client.auth.currentUser;
    if (user == null) return 0;

    final data = await _client
        .from('messages')
        .select('id')
        .eq('conversation_id', conversationId)
        .neq('sender_id', user.id)
        .eq('read', false);

    return (data as List).length;
  }

  /// Upload a file attachment to Supabase Storage
  static Future<String> uploadAttachment(File file, String conversationId) async {
    final user = _client.auth.currentUser;
    if (user == null) throw Exception('Not authenticated');

    final fileName = '${user.id}/${DateTime.now().millisecondsSinceEpoch}_${file.path.split('/').last.split('\\').last}';

    await _client.storage
        .from('chat-attachments')
        .upload(fileName, file);

    final publicUrl = _client.storage
        .from('chat-attachments')
        .getPublicUrl(fileName);

    return publicUrl;
  }

  /// Get the file extension type (image, document, etc.)
  static String getAttachmentType(String filePath) {
    final ext = filePath.split('.').last.toLowerCase();
    if (['jpg', 'jpeg', 'png', 'gif', 'webp'].contains(ext)) return 'image';
    if (['pdf', 'doc', 'docx', 'txt'].contains(ext)) return 'document';
    return 'file';
  }

  /// Unsubscribe from a realtime channel
  static Future<void> unsubscribe(RealtimeChannel channel) async {
    await _client.removeChannel(channel);
  }
}
