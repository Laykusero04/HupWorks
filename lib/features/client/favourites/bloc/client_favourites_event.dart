import 'package:equatable/equatable.dart';

abstract class ClientFavouritesEvent extends Equatable {
  const ClientFavouritesEvent();

  @override
  List<Object?> get props => [];
}

class FavouritesLoadRequested extends ClientFavouritesEvent {}

class FavouriteRemoveRequested extends ClientFavouritesEvent {
  final String favouriteId;

  const FavouriteRemoveRequested({required this.favouriteId});

  @override
  List<Object?> get props => [favouriteId];
}
