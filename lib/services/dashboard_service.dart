import 'package:supabase_flutter/supabase_flutter.dart';

class DashboardService {
  static final _client = Supabase.instance.client;

  /// Fetch client dashboard stats
  static Future<Map<String, dynamic>> getClientDashboard() async {
    final user = _client.auth.currentUser;
    if (user == null) return {};

    // Fetch order counts
    final allOrders = await _client
        .from('orders')
        .select('id, status, price')
        .eq('client_id', user.id);

    final orders = List<Map<String, dynamic>>.from(allOrders);
    final totalOrders = orders.length;
    final completedOrders = orders.where((o) => o['status'] == 'completed').length;
    final incompleteOrders = totalOrders - completedOrders;

    // Calculate total spent
    final totalSpent = orders.fold<double>(0, (sum, o) {
      final price = double.tryParse(o['price'].toString()) ?? 0;
      return sum + price;
    });

    return {
      'total_spent': totalSpent,
      'total_orders': totalOrders,
      'completed_orders': completedOrders,
      'incomplete_orders': incompleteOrders,
    };
  }
}
