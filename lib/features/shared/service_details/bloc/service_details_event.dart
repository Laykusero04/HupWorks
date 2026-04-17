import 'package:equatable/equatable.dart';

abstract class ServiceDetailsEvent extends Equatable {
  const ServiceDetailsEvent();

  @override
  List<Object?> get props => [];
}

class ServiceDetailsLoadRequested extends ServiceDetailsEvent {
  final String serviceId;

  const ServiceDetailsLoadRequested({required this.serviceId});

  @override
  List<Object?> get props => [serviceId];
}

class ServiceDetailsFavouriteToggled extends ServiceDetailsEvent {
  final String serviceId;

  const ServiceDetailsFavouriteToggled({required this.serviceId});

  @override
  List<Object?> get props => [serviceId];
}
