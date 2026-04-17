import 'package:equatable/equatable.dart';

abstract class ChatInboxEvent extends Equatable {
  const ChatInboxEvent();

  @override
  List<Object?> get props => [];
}

class ChatInboxLoadRequested extends ChatInboxEvent {
  final String conversationId;

  const ChatInboxLoadRequested({required this.conversationId});

  @override
  List<Object?> get props => [conversationId];
}

class ChatInboxSubscribeRequested extends ChatInboxEvent {
  final String conversationId;

  const ChatInboxSubscribeRequested({required this.conversationId});

  @override
  List<Object?> get props => [conversationId];
}

class ChatInboxSendMessage extends ChatInboxEvent {
  final String conversationId;
  final String content;
  final String? attachmentUrl;

  const ChatInboxSendMessage({
    required this.conversationId,
    required this.content,
    this.attachmentUrl,
  });

  @override
  List<Object?> get props => [conversationId, content, attachmentUrl];
}

class ChatInboxMarkReadRequested extends ChatInboxEvent {
  final String conversationId;

  const ChatInboxMarkReadRequested({required this.conversationId});

  @override
  List<Object?> get props => [conversationId];
}
