import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/errors/failures.dart';
import '../../../../data/repositories/dashboard_repository.dart';
import 'client_favourites_event.dart';
import 'client_favourites_state.dart';

class ClientFavouritesBloc extends Bloc<ClientFavouritesEvent, ClientFavouritesState> {
  final DashboardRepository _dashboardRepository;

  ClientFavouritesBloc({required DashboardRepository dashboardRepository})
      : _dashboardRepository = dashboardRepository,
        super(FavouritesInitial()) {
    on<FavouritesLoadRequested>(_onLoadRequested);
    on<FavouriteRemoveRequested>(_onRemoveRequested);
  }

  Future<void> _onLoadRequested(FavouritesLoadRequested event, Emitter<ClientFavouritesState> emit) async {
    emit(FavouritesLoading());
    try {
      final favourites = await _dashboardRepository.getFavourites();
      emit(FavouritesLoaded(favourites: favourites));
    } on Failure catch (e) {
      emit(FavouritesError(e.message));
    } catch (e) {
      emit(FavouritesError(e.toString()));
    }
  }

  Future<void> _onRemoveRequested(FavouriteRemoveRequested event, Emitter<ClientFavouritesState> emit) async {
    try {
      await _dashboardRepository.removeFavourite(event.favouriteId);
      final favourites = await _dashboardRepository.getFavourites();
      emit(FavouritesLoaded(favourites: favourites));
    } on Failure catch (e) {
      emit(FavouritesError(e.message));
    } catch (e) {
      emit(FavouritesError(e.toString()));
    }
  }
}
