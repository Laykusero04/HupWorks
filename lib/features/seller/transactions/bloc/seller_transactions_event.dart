import 'package:equatable/equatable.dart';

abstract class SellerTransactionsEvent extends Equatable {
  const SellerTransactionsEvent();

  @override
  List<Object?> get props => [];
}

class SellerTransactionsLoadRequested extends SellerTransactionsEvent {}
