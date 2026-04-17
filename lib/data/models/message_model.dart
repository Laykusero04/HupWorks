import 'package:equatable/equatable.dart';

import 'profile_model.dart';

class Message extends Equatable {
  final String id;
  final String conversationId;
  final String senderId;
  final String content;
  final String? attachmentUrl;
  final bool isRead;
  final DateTime createdAt;

  // Joined data
  final Profile? sender;

  const Message({
    required this.id,
    required this.conversationId,
    required this.senderId,
    required this.content,
    this.attachmentUrl,
    this.isRead = false,
    required this.createdAt,
    this.sender,
  });

  factory Message.fromJson(Map<String, dynamic> json) {
    final senderData = json['sender'];

    return Message(
      id: json['id'] as String,
      conversationId: json['conversation_id'] as String,
      senderId: json['sender_id'] as String,
      content: (json['content'] as String?) ?? '',
      attachmentUrl: json['attachment_url'] as String?,
      isRead: (json['read'] as bool?) ?? false,
      createdAt: DateTime.parse(json['created_at'] as String),
      sender: senderData is Map<String, dynamic> ? Profile.fromJson(senderData) : null,
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'conversation_id': conversationId,
        'sender_id': senderId,
        'content': content,
        'attachment_url': attachmentUrl,
        'read': isRead,
        'created_at': createdAt.toIso8601String(),
      };

  bool isMine(String currentUserId) => senderId == currentUserId;

  /// Determine attachment type from URL extension
  String? get attachmentType {
    if (attachmentUrl == null) return null;
    final ext = attachmentUrl!.split('.').last.toLowerCase().split('?').first;
    if (['jpg', 'jpeg', 'png', 'gif', 'webp'].contains(ext)) return 'image';
    if (['pdf', 'doc', 'docx', 'txt'].contains(ext)) return 'document';
    return 'file';
  }

  @override
  List<Object?> get props => [id, conversationId, senderId, content, attachmentUrl, isRead, createdAt, sender];
}
