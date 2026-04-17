import 'package:equatable/equatable.dart';

import '../../../../data/models/order_model.dart';

abstract class ClientOrdersState extends Equatable {
  const ClientOrdersState();

  @override
  List<Object?> get props => [];
}

class ClientOrdersInitial extends ClientOrdersState {}

class ClientOrdersLoading extends ClientOrdersState {}

class ClientOrdersLoaded extends ClientOrdersState {
  final List<Order> orders;
  final String? selectedStatus;

  const ClientOrdersLoaded({
    required this.orders,
    this.selectedStatus,
  });

  @override
  List<Object?> get props => [orders, selectedStatus];
}

class ClientOrdersError extends ClientOrdersState {
  final String message;

  const ClientOrdersError(this.message);

  @override
  List<Object?> get props => [message];
}
