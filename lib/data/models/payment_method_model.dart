import 'package:equatable/equatable.dart';

class PaymentMethod extends Equatable {
  final String id;
  final String userId;
  final String type;
  final Map<String, dynamic> details;
  final bool isDefault;
  final DateTime createdAt;

  const PaymentMethod({
    required this.id,
    required this.userId,
    required this.type,
    this.details = const {},
    this.isDefault = false,
    required this.createdAt,
  });

  factory PaymentMethod.fromJson(Map<String, dynamic> json) {
    return PaymentMethod(
      id: json['id'] as String,
      userId: json['user_id'] as String,
      type: json['type'] as String,
      details: (json['details'] as Map<String, dynamic>?) ?? {},
      isDefault: (json['is_default'] as bool?) ?? false,
      createdAt: DateTime.parse(json['created_at'] as String),
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'user_id': userId,
        'type': type,
        'details': details,
        'is_default': isDefault,
        'created_at': createdAt.toIso8601String(),
      };

  @override
  List<Object?> get props => [id, userId, type, details, isDefault, createdAt];
}
