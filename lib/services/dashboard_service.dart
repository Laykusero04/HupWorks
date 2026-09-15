import 'package:freelancer/core/utils/dashboard_period.dart';
import 'package:freelancer/services/seller_home_service.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class DashboardService {
  static final _client = Supabase.instance.client;

  /// Client dashboard KPIs for [period] (orders created in range).
  static Future<Map<String, dynamic>> getClientDashboard({
    DashboardPeriod period = DashboardPeriod.month,
  }) async {
    final user = _client.auth.currentUser;
    if (user == null) return {};

    final range = DashboardPeriodRange.forPeriod(period);

    final allOrders = await _client
        .from('orders')
        .select('id, status, price, created_at')
        .eq('client_id', user.id)
        .gte('created_at', range.startIso)
        .lt('created_at', range.endIso);

    final orders = List<Map<String, dynamic>>.from(allOrders);
    final totalOrders = orders.length;
    final completedOrders =
        orders.where((o) => o['status'] == 'completed').length;
    final incompleteOrders = totalOrders - completedOrders;

    final totalSpent = orders.fold<double>(0, (sum, o) {
      final price = double.tryParse(o['price'].toString()) ?? 0;
      return sum + price;
    });

    return {
      'total_spent': totalSpent,
      'total_orders': totalOrders,
      'completed_orders': completedOrders,
      'incomplete_orders': incompleteOrders,
      'period': period.name,
    };
  }

  /// Freelancer work-tracker overview for [period].
  static Future<Map<String, dynamic>> getSellerDashboard({
    DashboardPeriod period = DashboardPeriod.month,
  }) {
    return SellerHomeService.getWorkOverview(period: period);
  }
}
