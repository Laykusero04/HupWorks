import 'package:equatable/equatable.dart';

abstract class SellerServicesEvent extends Equatable {
  const SellerServicesEvent();

  @override
  List<Object?> get props => [];
}

class SellerServicesLoadRequested extends SellerServicesEvent {}

class SellerServiceToggleStatusRequested extends SellerServicesEvent {
  final String serviceId;

  const SellerServiceToggleStatusRequested({required this.serviceId});

  @override
  List<Object?> get props => [serviceId];
}

class SellerServiceDeleteRequested extends SellerServicesEvent {
  final String serviceId;

  const SellerServiceDeleteRequested({required this.serviceId});

  @override
  List<Object?> get props => [serviceId];
}
