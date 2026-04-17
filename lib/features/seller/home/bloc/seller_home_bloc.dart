import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/errors/failures.dart';
import '../../../../data/models/profile_model.dart';
import '../../../../data/models/service_model.dart';
import '../../../../data/repositories/dashboard_repository.dart';
import 'seller_home_event.dart';
import 'seller_home_state.dart';

class SellerHomeBloc extends Bloc<SellerHomeEvent, SellerHomeState> {
  final DashboardRepository _dashboardRepository;

  SellerHomeBloc({
    required DashboardRepository dashboardRepository,
  })  : _dashboardRepository = dashboardRepository,
        super(SellerHomeInitial()) {
    on<SellerHomeLoadRequested>(_onLoadRequested);
    on<SellerHomePerformancePeriodChanged>(_onPerformancePeriodChanged);
    on<SellerHomeEarningsPeriodChanged>(_onEarningsPeriodChanged);
  }

  Future<void> _onLoadRequested(
    SellerHomeLoadRequested event,
    Emitter<SellerHomeState> emit,
  ) async {
    emit(SellerHomeLoading());
    try {
      final results = await Future.wait([
        _dashboardRepository.getSellerProfile(),
        _dashboardRepository.getPerformance(isLastMonth: false),
        _dashboardRepository.getStatistics(),
        _dashboardRepository.getEarnings(isLastMonth: false),
        _dashboardRepository.getSellerMyServices(),
      ]);

      emit(SellerHomeLoaded(
        profile: results[0] as Profile?,
        performance: results[1] as Map<String, dynamic>,
        statistics: results[2] as Map<String, double>,
        earnings: results[3] as Map<String, dynamic>,
        myServices: results[4] as List<ServiceModel>,
      ));
    } on Failure catch (e) {
      emit(SellerHomeError(e.message));
    } catch (e) {
      emit(SellerHomeError(e.toString()));
    }
  }

  Future<void> _onPerformancePeriodChanged(
    SellerHomePerformancePeriodChanged event,
    Emitter<SellerHomeState> emit,
  ) async {
    final currentState = state;
    if (currentState is! SellerHomeLoaded) return;

    try {
      final performance = await _dashboardRepository.getPerformance(
        isLastMonth: event.isLastMonth,
      );

      emit(SellerHomeLoaded(
        profile: currentState.profile,
        performance: performance,
        statistics: currentState.statistics,
        earnings: currentState.earnings,
        myServices: currentState.myServices,
      ));
    } on Failure catch (e) {
      emit(SellerHomeError(e.message));
    } catch (e) {
      emit(SellerHomeError(e.toString()));
    }
  }

  Future<void> _onEarningsPeriodChanged(
    SellerHomeEarningsPeriodChanged event,
    Emitter<SellerHomeState> emit,
  ) async {
    final currentState = state;
    if (currentState is! SellerHomeLoaded) return;

    try {
      final earnings = await _dashboardRepository.getEarnings(
        isLastMonth: event.isLastMonth,
      );

      emit(SellerHomeLoaded(
        profile: currentState.profile,
        performance: currentState.performance,
        statistics: currentState.statistics,
        earnings: earnings,
        myServices: currentState.myServices,
      ));
    } on Failure catch (e) {
      emit(SellerHomeError(e.message));
    } catch (e) {
      emit(SellerHomeError(e.toString()));
    }
  }
}
