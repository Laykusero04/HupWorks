import 'package:equatable/equatable.dart';

import 'profile_model.dart';

class Conversation extends Equatable {
  final String id;
  final String clientId;
  final String sellerId;
  final String? lastMessage;
  final DateTime lastMessageAt;

  // Joined data
  final Profile? client;
  final Profile? seller;

  const Conversation({
    required this.id,
    required this.clientId,
    required this.sellerId,
    this.lastMessage,
    required this.lastMessageAt,
    this.client,
    this.seller,
  });

  factory Conversation.fromJson(Map<String, dynamic> json) {
    final clientData = json['client'];
    final sellerData = json['seller'];

    return Conversation(
      id: json['id'] as String,
      clientId: json['client_id'] as String,
      sellerId: json['seller_id'] as String,
      lastMessage: json['last_message'] as String?,
      lastMessageAt: DateTime.parse(json['last_message_at'] as String),
      client: clientData is Map<String, dynamic> ? Profile.fromJson(clientData) : null,
      seller: sellerData is Map<String, dynamic> ? Profile.fromJson(sellerData) : null,
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'client_id': clientId,
        'seller_id': sellerId,
        'last_message': lastMessage,
        'last_message_at': lastMessageAt.toIso8601String(),
      };

  /// Get the other user's profile based on the current user's ID
  Profile? getOtherUser(String currentUserId) {
    return clientId == currentUserId ? seller : client;
  }

  /// Get the other user's ID
  String getOtherUserId(String currentUserId) {
    return clientId == currentUserId ? sellerId : clientId;
  }

  @override
  List<Object?> get props => [id, clientId, sellerId, lastMessage, lastMessageAt, client, seller];
}
