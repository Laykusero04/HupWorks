import 'package:equatable/equatable.dart';

import '../../../../data/models/service_model.dart';
import '../../../../data/models/review_model.dart';
import '../../../../data/models/service_requirement_model.dart';

abstract class ServiceDetailsState extends Equatable {
  const ServiceDetailsState();

  @override
  List<Object?> get props => [];
}

class ServiceDetailsInitial extends ServiceDetailsState {}

class ServiceDetailsLoading extends ServiceDetailsState {}

class ServiceDetailsLoaded extends ServiceDetailsState {
  final ServiceModel service;
  final List<Review> reviews;
  final List<ServiceRequirement> requirements;
  final bool isFavourited;

  const ServiceDetailsLoaded({
    required this.service,
    required this.reviews,
    required this.requirements,
    required this.isFavourited,
  });

  @override
  List<Object?> get props => [service, reviews, requirements, isFavourited];
}

class ServiceDetailsError extends ServiceDetailsState {
  final String message;

  const ServiceDetailsError(this.message);

  @override
  List<Object?> get props => [message];
}
