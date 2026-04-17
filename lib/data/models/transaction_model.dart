import 'package:equatable/equatable.dart';

class AppTransaction extends Equatable {
  final String id;
  final String userId;
  final String type;
  final double amount;
  final String status;
  final String? gateway;
  final String? reference;
  final DateTime createdAt;

  const AppTransaction({
    required this.id,
    required this.userId,
    required this.type,
    required this.amount,
    this.status = 'pending',
    this.gateway,
    this.reference,
    required this.createdAt,
  });

  factory AppTransaction.fromJson(Map<String, dynamic> json) {
    return AppTransaction(
      id: json['id'] as String,
      userId: json['user_id'] as String,
      type: json['type'] as String,
      amount: (json['amount'] as num).toDouble(),
      status: (json['status'] as String?) ?? 'pending',
      gateway: json['gateway'] as String?,
      reference: json['reference'] as String?,
      createdAt: DateTime.parse(json['created_at'] as String),
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'user_id': userId,
        'type': type,
        'amount': amount,
        'status': status,
        'gateway': gateway,
        'reference': reference,
        'created_at': createdAt.toIso8601String(),
      };

  @override
  List<Object?> get props => [id, userId, type, amount, status, gateway, reference, createdAt];
}
