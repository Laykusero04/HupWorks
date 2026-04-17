import 'package:equatable/equatable.dart';

import '../../../../data/models/job_post_model.dart';

abstract class BuyerRequestsState extends Equatable {
  const BuyerRequestsState();

  @override
  List<Object?> get props => [];
}

class BuyerRequestsInitial extends BuyerRequestsState {}

class BuyerRequestsLoading extends BuyerRequestsState {}

class BuyerRequestsLoaded extends BuyerRequestsState {
  final List<JobPost> requests;

  const BuyerRequestsLoaded({required this.requests});

  @override
  List<Object?> get props => [requests];
}

class BuyerRequestOfferSuccess extends BuyerRequestsState {}

class BuyerRequestsError extends BuyerRequestsState {
  final String message;

  const BuyerRequestsError(this.message);

  @override
  List<Object?> get props => [message];
}
