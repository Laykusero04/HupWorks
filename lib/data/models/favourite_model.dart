import 'package:equatable/equatable.dart';

import 'service_model.dart';

class Favourite extends Equatable {
  final String id;
  final String userId;
  final String serviceId;
  final DateTime createdAt;

  // Joined data
  final ServiceModel? service;

  const Favourite({
    required this.id,
    required this.userId,
    required this.serviceId,
    required this.createdAt,
    this.service,
  });

  factory Favourite.fromJson(Map<String, dynamic> json) {
    final serviceData = json['services'] ?? json['service'];

    return Favourite(
      id: json['id'] as String,
      userId: json['user_id'] as String,
      serviceId: json['service_id'] as String,
      createdAt: DateTime.parse(json['created_at'] as String),
      service: serviceData is Map<String, dynamic> ? ServiceModel.fromJson(serviceData) : null,
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'user_id': userId,
        'service_id': serviceId,
        'created_at': createdAt.toIso8601String(),
      };

  @override
  List<Object?> get props => [id, userId, serviceId, createdAt, service];
}
