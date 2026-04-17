import 'package:equatable/equatable.dart';

abstract class SellerOrdersEvent extends Equatable {
  const SellerOrdersEvent();

  @override
  List<Object?> get props => [];
}

class SellerOrdersLoadRequested extends SellerOrdersEvent {
  final String? status;

  const SellerOrdersLoadRequested({this.status});

  @override
  List<Object?> get props => [status];
}

class SellerOrdersRefreshRequested extends SellerOrdersEvent {}

class SellerOrderStatusUpdateRequested extends SellerOrdersEvent {
  final String orderId;
  final String status;

  const SellerOrderStatusUpdateRequested({
    required this.orderId,
    required this.status,
  });

  @override
  List<Object?> get props => [orderId, status];
}
