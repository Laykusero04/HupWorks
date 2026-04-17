import 'package:equatable/equatable.dart';

abstract class ClientDashboardEvent extends Equatable {
  const ClientDashboardEvent();

  @override
  List<Object?> get props => [];
}

class ClientDashboardLoadRequested extends ClientDashboardEvent {}
