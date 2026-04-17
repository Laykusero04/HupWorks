import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/errors/failures.dart';
import '../../../../data/repositories/service_repository.dart';
import 'seller_services_event.dart';
import 'seller_services_state.dart';

class SellerServicesBloc extends Bloc<SellerServicesEvent, SellerServicesState> {
  final ServiceRepository _serviceRepository;

  SellerServicesBloc({required ServiceRepository serviceRepository})
      : _serviceRepository = serviceRepository,
        super(SellerServicesInitial()) {
    on<SellerServicesLoadRequested>(_onLoadRequested);
    on<SellerServiceToggleStatusRequested>(_onToggleStatusRequested);
    on<SellerServiceDeleteRequested>(_onDeleteRequested);
  }

  Future<void> _onLoadRequested(
    SellerServicesLoadRequested event,
    Emitter<SellerServicesState> emit,
  ) async {
    emit(SellerServicesLoading());
    try {
      final services = await _serviceRepository.getMyServices();
      emit(SellerServicesLoaded(services: services));
    } on Failure catch (e) {
      emit(SellerServicesError(e.message));
    } catch (e) {
      emit(SellerServicesError(e.toString()));
    }
  }

  Future<void> _onToggleStatusRequested(
    SellerServiceToggleStatusRequested event,
    Emitter<SellerServicesState> emit,
  ) async {
    try {
      await _serviceRepository.toggleServiceStatus(event.serviceId);
      final services = await _serviceRepository.getMyServices();
      emit(SellerServicesLoaded(services: services));
    } on Failure catch (e) {
      emit(SellerServicesError(e.message));
    } catch (e) {
      emit(SellerServicesError(e.toString()));
    }
  }

  Future<void> _onDeleteRequested(
    SellerServiceDeleteRequested event,
    Emitter<SellerServicesState> emit,
  ) async {
    try {
      await _serviceRepository.deleteService(event.serviceId);
      final services = await _serviceRepository.getMyServices();
      emit(SellerServicesLoaded(services: services));
    } on Failure catch (e) {
      emit(SellerServicesError(e.message));
    } catch (e) {
      emit(SellerServicesError(e.toString()));
    }
  }
}
