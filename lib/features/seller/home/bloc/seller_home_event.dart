import 'package:equatable/equatable.dart';

abstract class SellerHomeEvent extends Equatable {
  const SellerHomeEvent();

  @override
  List<Object?> get props => [];
}

class SellerHomeLoadRequested extends SellerHomeEvent {}

class SellerHomePerformancePeriodChanged extends SellerHomeEvent {
  final bool isLastMonth;

  const SellerHomePerformancePeriodChanged({required this.isLastMonth});

  @override
  List<Object?> get props => [isLastMonth];
}

class SellerHomeEarningsPeriodChanged extends SellerHomeEvent {
  final bool isLastMonth;

  const SellerHomeEarningsPeriodChanged({required this.isLastMonth});

  @override
  List<Object?> get props => [isLastMonth];
}
