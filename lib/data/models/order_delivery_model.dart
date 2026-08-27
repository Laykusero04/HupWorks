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
      id: json['id'].toString(),
      orderId: json['order_id'].toString(),
      message: json['message'] as String?,
      attachmentUrl: json['attachment_url'] as String?,
      deliveredAt: DateTime.tryParse(json['delivered_at']?.toString() ?? '') ??
          DateTime.now(),
    );
  }

  static List<OrderDelivery> listFromOrderMap(Map<String, dynamic>? order) {
    if (order == null) return const [];
    final raw = order['order_deliveries'];
    final maps = <Map<String, dynamic>>[];
    if (raw is List) {
      for (final item in raw) {
        if (item is Map<String, dynamic>) {
          maps.add(item);
        } else if (item is Map) {
          maps.add(Map<String, dynamic>.from(item));
        }
      }
    } else if (raw is Map<String, dynamic>) {
      maps.add(raw);
    }
    final list = <OrderDelivery>[];
    for (final json in maps) {
      try {
        list.add(OrderDelivery.fromJson(json));
      } catch (_) {}
    }
    list.sort((a, b) => b.deliveredAt.compareTo(a.deliveredAt));
    return list;
  }

  String? get attachmentType {
    if (attachmentUrl == null || attachmentUrl!.isEmpty) return null;
    final ext = attachmentUrl!.split('.').last.toLowerCase().split('?').first;
    if (['jpg', 'jpeg', 'png', 'gif', 'webp'].contains(ext)) return 'image';
    return 'file';
  }

  String get attachmentFileName {
    final url = attachmentUrl;
    if (url == null || url.isEmpty) return '';
    final path = Uri.tryParse(url)?.path ?? url;
    final name = path.split('/').last;
    return name.contains('.') ? name : 'attachment';
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
