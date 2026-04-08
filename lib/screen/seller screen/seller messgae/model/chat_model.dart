class Conversation {
  final String id;
  final String clientId;
  final String sellerId;
  final String? lastMessage;
  final DateTime lastMessageAt;
  final Map<String, dynamic> client;
  final Map<String, dynamic> seller;

  Conversation({
    required this.id,
    required this.clientId,
    required this.sellerId,
    this.lastMessage,
    required this.lastMessageAt,
    required this.client,
    required this.seller,
  });

  factory Conversation.fromMap(Map<String, dynamic> map) {
    return Conversation(
      id: map['id'] as String,
      clientId: map['client_id'] as String,
      sellerId: map['seller_id'] as String,
      lastMessage: map['last_message'] as String?,
      lastMessageAt: DateTime.parse(map['last_message_at'] as String),
      client: Map<String, dynamic>.from(map['client'] ?? {}),
      seller: Map<String, dynamic>.from(map['seller'] ?? {}),
    );
  }

  /// Get the other user's profile based on the current user's ID
  Map<String, dynamic> getOtherUser(String currentUserId) {
    return clientId == currentUserId ? seller : client;
  }

  /// Get the other user's ID
  String getOtherUserId(String currentUserId) {
    return clientId == currentUserId ? sellerId : clientId;
  }
}

class Message {
  final String id;
  final String conversationId;
  final String senderId;
  final String content;
  final String? attachmentUrl;
  final bool isRead;
  final DateTime createdAt;
  final Map<String, dynamic>? sender;

  Message({
    required this.id,
    required this.conversationId,
    required this.senderId,
    required this.content,
    this.attachmentUrl,
    required this.isRead,
    required this.createdAt,
    this.sender,
  });

  factory Message.fromMap(Map<String, dynamic> map) {
    return Message(
      id: map['id'] as String,
      conversationId: map['conversation_id'] as String,
      senderId: map['sender_id'] as String,
      content: (map['content'] as String?) ?? '',
      attachmentUrl: map['attachment_url'] as String?,
      isRead: (map['read'] as bool?) ?? false,
      createdAt: DateTime.parse(map['created_at'] as String),
      sender: map['sender'] != null ? Map<String, dynamic>.from(map['sender']) : null,
    );
  }

  bool isMine(String currentUserId) => senderId == currentUserId;

  /// Determine attachment type from URL extension
  String? get attachmentType {
    if (attachmentUrl == null) return null;
    final ext = attachmentUrl!.split('.').last.toLowerCase().split('?').first;
    if (['jpg', 'jpeg', 'png', 'gif', 'webp'].contains(ext)) return 'image';
    if (['pdf', 'doc', 'docx', 'txt'].contains(ext)) return 'document';
    return 'file';
  }
}
