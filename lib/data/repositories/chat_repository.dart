import 'dart:io';

import 'package:supabase_flutter/supabase_flutter.dart';

import '../../core/errors/failures.dart';
import '../../services/chat_service.dart';
import '../models/conversation_model.dart';
import '../models/message_model.dart';

class ChatRepository {
  Future<Conversation> getOrCreateConversation(String otherUserId) async {
    try {
      final data = await ChatService.getOrCreateConversation(otherUserId);
      return Conversation.fromJson(data);
    } catch (e) {
      throw ServerFailure(e.toString());
    }
  }

  Future<List<Conversation>> getConversations() async {
    try {
      final data = await ChatService.getConversations();
      return data.map((m) => Conversation.fromJson(m)).toList();
    } catch (e) {
      throw ServerFailure(e.toString());
    }
  }

  Future<List<Message>> getMessages(String conversationId) async {
    try {
      final data = await ChatService.getMessages(conversationId);
      return data.map((m) => Message.fromJson(m)).toList();
    } catch (e) {
      throw ServerFailure(e.toString());
    }
  }

  Future<Message> sendMessage({
    required String conversationId,
    required String content,
    String? attachmentUrl,
  }) async {
    try {
      final data = await ChatService.sendMessage(
        conversationId: conversationId,
        content: content,
        attachmentUrl: attachmentUrl,
      );
      return Message.fromJson(data);
    } catch (e) {
      throw ServerFailure(e.toString());
    }
  }

  RealtimeChannel subscribeToMessages({
    required String conversationId,
    required void Function(Map<String, dynamic> message) onNewMessage,
  }) {
    return ChatService.subscribeToMessages(
      conversationId: conversationId,
      onNewMessage: onNewMessage,
    );
  }

  RealtimeChannel subscribeToConversations({required void Function() onUpdate}) {
    return ChatService.subscribeToConversations(onUpdate: onUpdate);
  }

  Future<void> markMessagesAsRead(String conversationId) async {
    try {
      await ChatService.markMessagesAsRead(conversationId);
    } catch (e) {
      throw ServerFailure(e.toString());
    }
  }

  Future<int> getUnreadCount(String conversationId) async {
    try {
      return await ChatService.getUnreadCount(conversationId);
    } catch (e) {
      throw ServerFailure(e.toString());
    }
  }

  Future<String> uploadAttachment(File file, String conversationId) async {
    try {
      return await ChatService.uploadAttachment(file, conversationId);
    } catch (e) {
      throw ServerFailure(e.toString());
    }
  }

  String getAttachmentType(String filePath) {
    return ChatService.getAttachmentType(filePath);
  }

  Future<void> unsubscribe(RealtimeChannel channel) async {
    await ChatService.unsubscribe(channel);
  }
}
