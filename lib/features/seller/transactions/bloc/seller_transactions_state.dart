import 'package:equatable/equatable.dart';

import '../../../../data/models/transaction_model.dart';

abstract class SellerTransactionsState extends Equatable {
  const SellerTransactionsState();

  @override
  List<Object?> get props => [];
}

class SellerTransactionsInitial extends SellerTransactionsState {}

class SellerTransactionsLoading extends SellerTransactionsState {}

class SellerTransactionsLoaded extends SellerTransactionsState {
  final List<AppTransaction> transactions;

  const SellerTransactionsLoaded({required this.transactions});

  @override
  List<Object?> get props => [transactions];
}

class SellerTransactionsError extends SellerTransactionsState {
  final String message;

  const SellerTransactionsError(this.message);

  @override
  List<Object?> get props => [message];
}
