import 'dart:io';

import '../../core/errors/failures.dart';
import '../../services/orders_service.dart';
import '../../services/seller_orders_service.dart';
import '../models/order_model.dart';

class OrderRepository {
  // ── Client orders ──

  Future<Order> createOrder({
    required String serviceId,
    required String sellerId,
    required double price,
    required int deliveryDays,
  }) async {
    try {
      final data = await OrdersService.createOrder(
        serviceId: serviceId,
        sellerId: sellerId,
        price: price,
        deliveryDays: deliveryDays,
      );
      return Order.fromJson(data);
    } catch (e) {
      throw ServerFailure(e.toString());
    }
  }

  Future<List<Order>> getClientOrders({String? status}) async {
    try {
      final data = await OrdersService.getClientOrders(status: status);
      return data.map((m) => Order.fromJson(m)).toList();
    } catch (e) {
      throw ServerFailure(e.toString());
    }
  }

  Future<Order> getClientOrderDetails(String orderId) async {
    try {
      final data = await OrdersService.getOrderDetails(orderId);
      return Order.fromJson(data);
    } catch (e) {
      throw ServerFailure(e.toString());
    }
  }

  Future<void> updateOrderStatus(String orderId, String status) async {
    try {
      await OrdersService.updateOrderStatus(orderId, status);
    } catch (e) {
      throw ServerFailure(e.toString());
    }
  }

  // ── Seller orders ──

  Future<List<Order>> getSellerOrders({String? status}) async {
    try {
      final data = await SellerOrdersService.getSellerOrders(status: status);
      return data.map((m) => Order.fromJson(m)).toList();
    } catch (e) {
      throw ServerFailure(e.toString());
    }
  }

  Future<Order> getSellerOrderDetails(String orderId) async {
    try {
      final data = await SellerOrdersService.getOrderDetails(orderId);
      return Order.fromJson(data);
    } catch (e) {
      throw ServerFailure(e.toString());
    }
  }

  Future<void> sellerUpdateOrderStatus(String orderId, String status) async {
    try {
      await SellerOrdersService.updateOrderStatus(orderId, status);
    } catch (e) {
      throw ServerFailure(e.toString());
    }
  }

  Future<void> deliverOrder({
    required String orderId,
    required String message,
    File? attachment,
  }) async {
    try {
      await SellerOrdersService.deliverOrder(
        orderId: orderId,
        message: message,
        attachment: attachment,
      );
    } catch (e) {
      throw ServerFailure(e.toString());
    }
  }
}
