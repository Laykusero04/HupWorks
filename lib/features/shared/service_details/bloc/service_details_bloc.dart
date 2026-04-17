import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/errors/failures.dart';
import '../../../../data/repositories/service_repository.dart';
import '../../../../data/repositories/recently_viewed_repository.dart';
import 'service_details_event.dart';
import 'service_details_state.dart';

class ServiceDetailsBloc extends Bloc<ServiceDetailsEvent, ServiceDetailsState> {
  final ServiceRepository _serviceRepository;
  final RecentlyViewedRepository _recentlyViewedRepository;

  ServiceDetailsBloc({
    required ServiceRepository serviceRepository,
    required RecentlyViewedRepository recentlyViewedRepository,
  })  : _serviceRepository = serviceRepository,
        _recentlyViewedRepository = recentlyViewedRepository,
        super(ServiceDetailsInitial()) {
    on<ServiceDetailsLoadRequested>(_onLoadRequested);
    on<ServiceDetailsFavouriteToggled>(_onFavouriteToggled);
  }

  Future<void> _onLoadRequested(ServiceDetailsLoadRequested event, Emitter<ServiceDetailsState> emit) async {
    emit(ServiceDetailsLoading());
    try {
      final results = await Future.wait([
        _serviceRepository.getServiceDetails(event.serviceId),
        _serviceRepository.getServiceReviews(event.serviceId),
        _serviceRepository.getServiceRequirements(event.serviceId),
        _serviceRepository.isFavourited(event.serviceId),
      ]);

      await _recentlyViewedRepository.addServiceId(event.serviceId);

      emit(ServiceDetailsLoaded(
        service: results[0] as dynamic,
        reviews: results[1] as dynamic,
        requirements: results[2] as dynamic,
        isFavourited: results[3] as bool,
      ));
    } on Failure catch (e) {
      emit(ServiceDetailsError(e.message));
    } catch (e) {
      emit(ServiceDetailsError(e.toString()));
    }
  }

  Future<void> _onFavouriteToggled(ServiceDetailsFavouriteToggled event, Emitter<ServiceDetailsState> emit) async {
    final currentState = state;
    if (currentState is! ServiceDetailsLoaded) return;

    try {
      await _serviceRepository.toggleFavourite(event.serviceId);

      emit(ServiceDetailsLoaded(
        service: currentState.service,
        reviews: currentState.reviews,
        requirements: currentState.requirements,
        isFavourited: !currentState.isFavourited,
      ));
    } on Failure catch (e) {
      emit(ServiceDetailsError(e.message));
    } catch (e) {
      emit(ServiceDetailsError(e.toString()));
    }
  }
}
