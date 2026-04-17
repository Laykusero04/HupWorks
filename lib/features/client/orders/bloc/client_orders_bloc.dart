import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/errors/failures.dart';
import '../../../../data/repositories/order_repository.dart';
import 'client_orders_event.dart';
import 'client_orders_state.dart';

class ClientOrdersBloc extends Bloc<ClientOrdersEvent, ClientOrdersState> {
  final OrderRepository _orderRepository;

  String? _lastStatus;

  ClientOrdersBloc({required OrderRepository orderRepository})
      : _orderRepository = orderRepository,
        super(ClientOrdersInitial()) {
    on<ClientOrdersLoadRequested>(_onLoadRequested);
    on<ClientOrdersRefreshRequested>(_onRefreshRequested);
  }

  Future<void> _onLoadRequested(ClientOrdersLoadRequested event, Emitter<ClientOrdersState> emit) async {
    emit(ClientOrdersLoading());
    _lastStatus = event.status;
    try {
      final orders = await _orderRepository.getClientOrders(status: event.status);
      emit(ClientOrdersLoaded(orders: orders, selectedStatus: event.status));
    } on Failure catch (e) {
      emit(ClientOrdersError(e.message));
    } catch (e) {
      emit(ClientOrdersError(e.toString()));
    }
  }

  Future<void> _onRefreshRequested(ClientOrdersRefreshRequested event, Emitter<ClientOrdersState> emit) async {
    try {
      final orders = await _orderRepository.getClientOrders(status: _lastStatus);
      emit(ClientOrdersLoaded(orders: orders, selectedStatus: _lastStatus));
    } on Failure catch (e) {
      emit(ClientOrdersError(e.message));
    } catch (e) {
      emit(ClientOrdersError(e.toString()));
    }
  }
}
