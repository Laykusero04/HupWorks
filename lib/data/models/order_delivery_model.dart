import 'package:equatable/equatable.dart';

class OrderDelivery extends Equatable {
  final String id;
  final String orderId;
  final String? message;
  final String? attachmentUrl;
  final DateTime deliveredAt;

  const OrderDelivery({
    required this.id,
    required this.orderId,
    this.message,
    this.attachmentUrl,
    required this.deliveredAt,
  });

  factory OrderDelivery.fromJson(Map<String, dynamic> json) {
    return OrderDelivery(
      id: json['id'] as String,
      orderId: json['order_id'] as String,
      message: json['message'] as String?,
      attachmentUrl: json['attachment_url'] as String?,
      deliveredAt: DateTime.parse(json['delivered_at'] as String),
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'order_id': orderId,
        'message': message,
        'attachment_url': attachmentUrl,
        'delivered_at': deliveredAt.toIso8601String(),
      };

  @override
  List<Object?> get props => [id, orderId, message, attachmentUrl, deliveredAt];
}
