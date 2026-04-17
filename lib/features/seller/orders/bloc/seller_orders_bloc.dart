import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/errors/failures.dart';
import '../../../../data/repositories/order_repository.dart';
import 'seller_orders_event.dart';
import 'seller_orders_state.dart';

class SellerOrdersBloc extends Bloc<SellerOrdersEvent, SellerOrdersState> {
  final OrderRepository _orderRepository;

  SellerOrdersBloc({required OrderRepository orderRepository})
      : _orderRepository = orderRepository,
        super(SellerOrdersInitial()) {
    on<SellerOrdersLoadRequested>(_onLoadRequested);
    on<SellerOrdersRefreshRequested>(_onRefreshRequested);
    on<SellerOrderStatusUpdateRequested>(_onStatusUpdateRequested);
  }

  Future<void> _onLoadRequested(
    SellerOrdersLoadRequested event,
    Emitter<SellerOrdersState> emit,
  ) async {
    emit(SellerOrdersLoading());
    try {
      final orders = await _orderRepository.getSellerOrders(status: event.status);
      emit(SellerOrdersLoaded(orders: orders, selectedStatus: event.status));
    } on Failure catch (e) {
      emit(SellerOrdersError(e.message));
    } catch (e) {
      emit(SellerOrdersError(e.toString()));
    }
  }

  Future<void> _onRefreshRequested(
    SellerOrdersRefreshRequested event,
    Emitter<SellerOrdersState> emit,
  ) async {
    final currentStatus = state is SellerOrdersLoaded
        ? (state as SellerOrdersLoaded).selectedStatus
        : null;

    try {
      final orders = await _orderRepository.getSellerOrders(status: currentStatus);
      emit(SellerOrdersLoaded(orders: orders, selectedStatus: currentStatus));
    } on Failure catch (e) {
      emit(SellerOrdersError(e.message));
    } catch (e) {
      emit(SellerOrdersError(e.toString()));
    }
  }

  Future<void> _onStatusUpdateRequested(
    SellerOrderStatusUpdateRequested event,
    Emitter<SellerOrdersState> emit,
  ) async {
    try {
      await _orderRepository.sellerUpdateOrderStatus(event.orderId, event.status);

      final currentStatus = state is SellerOrdersLoaded
          ? (state as SellerOrdersLoaded).selectedStatus
          : null;

      final orders = await _orderRepository.getSellerOrders(status: currentStatus);
      emit(SellerOrdersLoaded(orders: orders, selectedStatus: currentStatus));
    } on Failure catch (e) {
      emit(SellerOrdersError(e.message));
    } catch (e) {
      emit(SellerOrdersError(e.toString()));
    }
  }
}
