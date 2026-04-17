import 'package:equatable/equatable.dart';

import '../../../../data/models/transaction_model.dart';

abstract class SellerWithdrawState extends Equatable {
  const SellerWithdrawState();

  @override
  List<Object?> get props => [];
}

class WithdrawInitial extends SellerWithdrawState {}

class WithdrawLoading extends SellerWithdrawState {}

class WithdrawLoaded extends SellerWithdrawState {
  final List<AppTransaction> deposits;

  const WithdrawLoaded({required this.deposits});

  @override
  List<Object?> get props => [deposits];
}

class WithdrawSuccess extends SellerWithdrawState {}

class WithdrawError extends SellerWithdrawState {
  final String message;

  const WithdrawError(this.message);

  @override
  List<Object?> get props => [message];
}
