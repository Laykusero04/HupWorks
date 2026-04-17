import 'package:equatable/equatable.dart';

import 'profile_model.dart';
import 'service_model.dart';

class Order extends Equatable {
  final String id;
  final String serviceId;
  final String clientId;
  final String sellerId;
  final String status;
  final double price;
  final Map<String, dynamic>? requirementsResponse;
  final DateTime? deliveryDeadline;
  final DateTime createdAt;
  final DateTime? completedAt;

  // Joined data
  final ServiceModel? service;
  final Profile? seller;
  final Profile? client;

  const Order({
    required this.id,
    required this.serviceId,
    required this.clientId,
    required this.sellerId,
    this.status = 'pending',
    required this.price,
    this.requirementsResponse,
    this.deliveryDeadline,
    required this.createdAt,
    this.completedAt,
    this.service,
    this.seller,
    this.client,
  });

  factory Order.fromJson(Map<String, dynamic> json) {
    // Handle joined service data (can come as 'services' from FK name)
    final serviceData = json['services'] ?? json['service'];
    // Handle joined seller/client profiles
    final sellerData = json['seller'];
    final clientData = json['client'];

    return Order(
      id: json['id'] as String,
      serviceId: json['service_id'] as String,
      clientId: json['client_id'] as String,
      sellerId: json['seller_id'] as String,
      status: (json['status'] as String?) ?? 'pending',
      price: (json['price'] as num).toDouble(),
      requirementsResponse: json['requirements_response'] as Map<String, dynamic>?,
      deliveryDeadline: json['delivery_deadline'] != null ? DateTime.parse(json['delivery_deadline'] as String) : null,
      createdAt: DateTime.parse(json['created_at'] as String),
      completedAt: json['completed_at'] != null ? DateTime.parse(json['completed_at'] as String) : null,
      service: serviceData is Map<String, dynamic> ? ServiceModel.fromJson(serviceData) : null,
      seller: sellerData is Map<String, dynamic> ? Profile.fromJson(sellerData) : null,
      client: clientData is Map<String, dynamic> ? Profile.fromJson(clientData) : null,
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'service_id': serviceId,
        'client_id': clientId,
        'seller_id': sellerId,
        'status': status,
        'price': price,
        'requirements_response': requirementsResponse,
        if (deliveryDeadline != null) 'delivery_deadline': deliveryDeadline!.toIso8601String(),
        'created_at': createdAt.toIso8601String(),
        if (completedAt != null) 'completed_at': completedAt!.toIso8601String(),
      };

  @override
  List<Object?> get props => [id, serviceId, clientId, sellerId, status, price, requirementsResponse, deliveryDeadline, createdAt, completedAt, service, seller, client];
}
