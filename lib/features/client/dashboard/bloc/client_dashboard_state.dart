import 'package:equatable/equatable.dart';

abstract class ClientDashboardState extends Equatable {
  const ClientDashboardState();

  @override
  List<Object?> get props => [];
}

class ClientDashboardInitial extends ClientDashboardState {}

class ClientDashboardLoading extends ClientDashboardState {}

class ClientDashboardLoaded extends ClientDashboardState {
  final Map<String, dynamic> dashboardData;

  const ClientDashboardLoaded({required this.dashboardData});

  @override
  List<Object?> get props => [dashboardData];
}

class ClientDashboardError extends ClientDashboardState {
  final String message;

  const ClientDashboardError(this.message);

  @override
  List<Object?> get props => [message];
}
