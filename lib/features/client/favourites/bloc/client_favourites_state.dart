import 'package:equatable/equatable.dart';

import '../../../../data/models/favourite_model.dart';

abstract class ClientFavouritesState extends Equatable {
  const ClientFavouritesState();

  @override
  List<Object?> get props => [];
}

class FavouritesInitial extends ClientFavouritesState {}

class FavouritesLoading extends ClientFavouritesState {}

class FavouritesLoaded extends ClientFavouritesState {
  final List<Favourite> favourites;

  const FavouritesLoaded({required this.favourites});

  @override
  List<Object?> get props => [favourites];
}

class FavouritesError extends ClientFavouritesState {
  final String message;

  const FavouritesError(this.message);

  @override
  List<Object?> get props => [message];
}
