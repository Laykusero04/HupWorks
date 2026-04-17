import 'package:equatable/equatable.dart';

import '../../../../data/models/service_model.dart';

abstract class SellerServicesState extends Equatable {
  const SellerServicesState();

  @override
  List<Object?> get props => [];
}

class SellerServicesInitial extends SellerServicesState {}

class SellerServicesLoading extends SellerServicesState {}

class SellerServicesLoaded extends SellerServicesState {
  final List<ServiceModel> services;

  const SellerServicesLoaded({required this.services});

  @override
  List<Object?> get props => [services];
}

class SellerServicesError extends SellerServicesState {
  final String message;

  const SellerServicesError(this.message);

  @override
  List<Object?> get props => [message];
}
