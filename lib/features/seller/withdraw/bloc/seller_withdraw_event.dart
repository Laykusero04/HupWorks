import 'package:equatable/equatable.dart';

abstract class SellerWithdrawEvent extends Equatable {
  const SellerWithdrawEvent();

  @override
  List<Object?> get props => [];
}

class WithdrawHistoryLoadRequested extends SellerWithdrawEvent {}

class WithdrawRequested extends SellerWithdrawEvent {
  final double amount;
  final String gateway;

  const WithdrawRequested({required this.amount, required this.gateway});

  @override
  List<Object?> get props => [amount, gateway];
}
