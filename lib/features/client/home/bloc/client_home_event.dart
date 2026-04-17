import 'package:equatable/equatable.dart';

abstract class ClientHomeEvent extends Equatable {
  const ClientHomeEvent();

  @override
  List<Object?> get props => [];
}

class ClientHomeLoadRequested extends ClientHomeEvent {}

class ClientHomeRefreshRequested extends ClientHomeEvent {}
