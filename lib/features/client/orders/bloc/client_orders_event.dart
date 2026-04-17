import 'package:equatable/equatable.dart';

abstract class ClientOrdersEvent extends Equatable {
  const ClientOrdersEvent();

  @override
  List<Object?> get props => [];
}

class ClientOrdersLoadRequested extends ClientOrdersEvent {
  final String? status;

  const ClientOrdersLoadRequested({this.status});

  @override
  List<Object?> get props => [status];
}

class ClientOrdersRefreshRequested extends ClientOrdersEvent {}
