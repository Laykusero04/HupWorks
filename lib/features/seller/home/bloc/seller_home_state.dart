import 'package:equatable/equatable.dart';

import '../../../../data/models/profile_model.dart';
import '../../../../data/models/service_model.dart';

abstract class SellerHomeState extends Equatable {
  const SellerHomeState();

  @override
  List<Object?> get props => [];
}

class SellerHomeInitial extends SellerHomeState {}

class SellerHomeLoading extends SellerHomeState {}

class SellerHomeLoaded extends SellerHomeState {
  final Profile? profile;
  final Map<String, dynamic> performance;
  final Map<String, double> statistics;
  final Map<String, dynamic> earnings;
  final List<ServiceModel> myServices;

  const SellerHomeLoaded({
    required this.profile,
    required this.performance,
    required this.statistics,
    required this.earnings,
    required this.myServices,
  });

  @override
  List<Object?> get props => [profile, performance, statistics, earnings, myServices];
}

class SellerHomeError extends SellerHomeState {
  final String message;

  const SellerHomeError(this.message);

  @override
  List<Object?> get props => [message];
}
