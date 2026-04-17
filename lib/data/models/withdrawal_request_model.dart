import 'package:equatable/equatable.dart';

class WithdrawalRequest extends Equatable {
  final String id;
  final String sellerId;
  final double amount;
  final String? paymentMethodId;
  final String status;
  final DateTime createdAt;

  const WithdrawalRequest({
    required this.id,
    required this.sellerId,
    required this.amount,
    this.paymentMethodId,
    this.status = 'pending',
    required this.createdAt,
  });

  factory WithdrawalRequest.fromJson(Map<String, dynamic> json) {
    return WithdrawalRequest(
      id: json['id'] as String,
      sellerId: json['seller_id'] as String,
      amount: (json['amount'] as num).toDouble(),
      paymentMethodId: json['payment_method_id'] as String?,
      status: (json['status'] as String?) ?? 'pending',
      createdAt: DateTime.parse(json['created_at'] as String),
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'seller_id': sellerId,
        'amount': amount,
        'payment_method_id': paymentMethodId,
        'status': status,
        'created_at': createdAt.toIso8601String(),
      };

  @override
  List<Object?> get props => [id, sellerId, amount, paymentMethodId, status, createdAt];
}
