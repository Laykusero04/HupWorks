import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/errors/failures.dart';
import '../../../../data/repositories/category_repository.dart';
import '../../../../data/repositories/profile_repository.dart';
import '../../../../data/repositories/recently_viewed_repository.dart';
import '../../../../data/repositories/service_repository.dart';
import 'client_home_event.dart';
import 'client_home_state.dart';

class ClientHomeBloc extends Bloc<ClientHomeEvent, ClientHomeState> {
  final ServiceRepository _serviceRepository;
  final CategoryRepository _categoryRepository;
  final RecentlyViewedRepository _recentlyViewedRepository;
  final ProfileRepository _profileRepository;

  ClientHomeBloc({
    required ServiceRepository serviceRepository,
    required CategoryRepository categoryRepository,
    required RecentlyViewedRepository recentlyViewedRepository,
    required ProfileRepository profileRepository,
  })  : _serviceRepository = serviceRepository,
        _categoryRepository = categoryRepository,
        _recentlyViewedRepository = recentlyViewedRepository,
        _profileRepository = profileRepository,
        super(ClientHomeInitial()) {
    on<ClientHomeLoadRequested>(_onLoadRequested);
    on<ClientHomeRefreshRequested>(_onRefreshRequested);
  }

  Future<void> _onLoadRequested(ClientHomeLoadRequested event, Emitter<ClientHomeState> emit) async {
    emit(ClientHomeLoading());
    await _loadHome(emit);
  }

  Future<void> _onRefreshRequested(ClientHomeRefreshRequested event, Emitter<ClientHomeState> emit) async {
    await _loadHome(emit);
  }

  Future<void> _loadHome(Emitter<ClientHomeState> emit) async {
    try {
      final results = await Future.wait([
        _profileRepository.getProfile(),
        _categoryRepository.getCategories(),
        _serviceRepository.getPopularServices(),
        _serviceRepository.getTopSellers(),
        _recentlyViewedRepository.getRecentlyViewedServices(),
      ]);

      emit(ClientHomeLoaded(
        profile: results[0] as dynamic,
        categories: results[1] as dynamic,
        popularServices: results[2] as dynamic,
        topSellers: results[3] as dynamic,
        recentlyViewed: results[4] as dynamic,
      ));
    } on Failure catch (e) {
      emit(ClientHomeError(e.message));
    } catch (e) {
      emit(ClientHomeError(e.toString()));
    }
  }
}
