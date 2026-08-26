import 'package:supabase_flutter/supabase_flutter.dart';

class DashboardService {
  static final _client = Supabase.instance.client;

  /// Fetch client dashboard stats
  static Future<Map<String, dynamic>> getClientDashboard() async {
    final user = _client.auth.currentUser;
    if (user == null) return {};

    // Fetch profile balance
    final profile = await _client
        .from('profiles')
        .select('balance')
        .eq('id', user.id)
        .single();

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

    // Fetch latest transactions
    final transactions = await _client
        .from('transactions')
        .select()
        .eq('user_id', user.id)
        .order('created_at', ascending: false)
        .limit(5);

    return {
      'balance': profile['balance'] ?? 0,
      'total_spent': totalSpent,
      'total_orders': totalOrders,
      'completed_orders': completedOrders,
      'incomplete_orders': incompleteOrders,
      'transactions': List<Map<String, dynamic>>.from(transactions),
    };
  }

}
