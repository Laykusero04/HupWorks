import 'package:equatable/equatable.dart';

import '../../../../data/models/order_model.dart';

abstract class SellerOrdersState extends Equatable {
  const SellerOrdersState();

  @override
  List<Object?> get props => [];
}

class SellerOrdersInitial extends SellerOrdersState {}

class SellerOrdersLoading extends SellerOrdersState {}

class SellerOrdersLoaded extends SellerOrdersState {
  final List<Order> orders;
  final String? selectedStatus;

  const SellerOrdersLoaded({
    required this.orders,
    this.selectedStatus,
  });

  @override
  List<Object?> get props => [orders, selectedStatus];
}

class SellerOrdersError extends SellerOrdersState {
  final String message;

  const SellerOrdersError(this.message);

  @override
  List<Object?> get props => [message];
}
