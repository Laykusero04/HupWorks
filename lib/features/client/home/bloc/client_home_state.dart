import 'package:equatable/equatable.dart';

import '../../../../data/models/category_model.dart';
import '../../../../data/models/profile_model.dart';
import '../../../../data/models/service_model.dart';

abstract class ClientHomeState extends Equatable {
  const ClientHomeState();

  @override
  List<Object?> get props => [];
}

class ClientHomeInitial extends ClientHomeState {}

class ClientHomeLoading extends ClientHomeState {}

class ClientHomeLoaded extends ClientHomeState {
  final Profile? profile;
  final List<Category> categories;
  final List<ServiceModel> popularServices;
  final List<Profile> topSellers;
  final List<ServiceModel> recentlyViewed;

  const ClientHomeLoaded({
    required this.profile,
    required this.categories,
    required this.popularServices,
    required this.topSellers,
    required this.recentlyViewed,
  });

  @override
  List<Object?> get props => [profile, categories, popularServices, topSellers, recentlyViewed];
}

class ClientHomeError extends ClientHomeState {
  final String message;

  const ClientHomeError(this.message);

  @override
  List<Object?> get props => [message];
}
