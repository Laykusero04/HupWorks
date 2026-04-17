import 'package:equatable/equatable.dart';

abstract class BuyerRequestsEvent extends Equatable {
  const BuyerRequestsEvent();

  @override
  List<Object?> get props => [];
}

class BuyerRequestsLoadRequested extends BuyerRequestsEvent {}

class BuyerRequestOfferCreated extends BuyerRequestsEvent {
  final String jobPostId;
  final double price;
  final int deliveryTime;
  final String? coverLetter;

  const BuyerRequestOfferCreated({
    required this.jobPostId,
    required this.price,
    required this.deliveryTime,
    this.coverLetter,
  });

  @override
  List<Object?> get props => [jobPostId, price, deliveryTime, coverLetter];
}
