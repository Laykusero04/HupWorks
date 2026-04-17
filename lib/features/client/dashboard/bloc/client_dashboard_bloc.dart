import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/errors/failures.dart';
import '../../../../data/repositories/dashboard_repository.dart';
import 'client_dashboard_event.dart';
import 'client_dashboard_state.dart';

class ClientDashboardBloc extends Bloc<ClientDashboardEvent, ClientDashboardState> {
  final DashboardRepository _dashboardRepository;

  ClientDashboardBloc({required DashboardRepository dashboardRepository})
      : _dashboardRepository = dashboardRepository,
        super(ClientDashboardInitial()) {
    on<ClientDashboardLoadRequested>(_onLoadRequested);
  }

  Future<void> _onLoadRequested(ClientDashboardLoadRequested event, Emitter<ClientDashboardState> emit) async {
    emit(ClientDashboardLoading());
    try {
      final dashboardData = await _dashboardRepository.getClientDashboard();
      emit(ClientDashboardLoaded(dashboardData: dashboardData));
    } on Failure catch (e) {
      emit(ClientDashboardError(e.message));
    } catch (e) {
      emit(ClientDashboardError(e.toString()));
    }
  }
}
