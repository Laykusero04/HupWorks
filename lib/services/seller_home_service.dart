import 'package:supabase_flutter/supabase_flutter.dart';

class SellerHomeService {
  static final _client = Supabase.instance.client;

  /// Fetch seller profile + seller_profiles data
  static Future<Map<String, dynamic>?> getSellerProfile() async {
    final user = _client.auth.currentUser;
    if (user == null) return null;

    final data = await _client
        .from('profiles')
        .select('*, seller_profiles(*)')
        .eq('id', user.id)
        .single();
    return data;
  }

  /// Fetch performance metrics for a given period
  static Future<Map<String, dynamic>> getPerformance({required bool isLastMonth}) async {
    final user = _client.auth.currentUser;
    if (user == null) return {};

    final now = DateTime.now();
    final DateTime startDate;
    final DateTime endDate;

    if (isLastMonth) {
      startDate = DateTime(now.year, now.month - 1, 1);
      endDate = DateTime(now.year, now.month, 1);
    } else {
      startDate = DateTime(now.year, now.month, 1);
      endDate = now;
    }

    // Fetch orders in the period
    final orders = await _client
        .from('orders')
        .select('id, status')
        .eq('seller_id', user.id)
        .gte('created_at', startDate.toIso8601String())
        .lt('created_at', endDate.toIso8601String());

    final orderList = List<Map<String, dynamic>>.from(orders);
    final totalOrders = orderList.length;
    final completedOrders = orderList.where((o) => o['status'] == 'completed').length;

    // Fetch services count
    final services = await _client
        .from('services')
        .select('id')
        .eq('seller_id', user.id);

    final activeServices = List.from(services).length;

    // Fetch average rating
    final reviews = await _client
        .from('reviews')
        .select('rating')
        .eq('reviewed_id', user.id);

    final reviewList = List<Map<String, dynamic>>.from(reviews);
    double avgRating = 0;
    if (reviewList.isNotEmpty) {
      avgRating = reviewList.fold<double>(0, (sum, r) => sum + (r['rating'] as num).toDouble()) / reviewList.length;
    }

    return {
      'total_orders': totalOrders,
      'completed_orders': completedOrders,
      'avg_rating': avgRating,
      'total_services': activeServices,
    };
  }

  /// Fetch statistics (impressions, interactions, reach) from seller_profiles
  static Future<Map<String, double>> getStatistics() async {
    final user = _client.auth.currentUser;
    if (user == null) return {};

    final data = await _client
        .from('seller_profiles')
        .select('impressions_count, interactions_count, reach_count')
        .eq('user_id', user.id)
        .single();

    return {
      'Impressions': (data['impressions_count'] as num?)?.toDouble() ?? 0,
      'Interaction': (data['interactions_count'] as num?)?.toDouble() ?? 0,
      'Reached-Out': (data['reach_count'] as num?)?.toDouble() ?? 0,
    };
  }

  /// Fetch earnings data for a given period
  static Future<Map<String, dynamic>> getEarnings({required bool isLastMonth}) async {
    final user = _client.auth.currentUser;
    if (user == null) return {};

    final now = DateTime.now();
    final DateTime startDate;

    if (isLastMonth) {
      startDate = DateTime(now.year, now.month - 1, 1);
    } else {
      startDate = DateTime(now.year, now.month, 1);
    }

    // Fetch earning transactions
    final earnings = await _client
        .from('transactions')
        .select('amount')
        .eq('user_id', user.id)
        .eq('type', 'earning')
        .gte('created_at', startDate.toIso8601String());

    final earningList = List<Map<String, dynamic>>.from(earnings);
    final totalEarnings = earningList.fold<double>(0, (sum, e) => sum + (double.tryParse(e['amount'].toString()) ?? 0));

    // Fetch withdrawals
    final withdrawals = await _client
        .from('transactions')
        .select('amount')
        .eq('user_id', user.id)
        .eq('type', 'withdrawal')
        .gte('created_at', startDate.toIso8601String());

    final withdrawalList = List<Map<String, dynamic>>.from(withdrawals);
    final totalWithdrawals = withdrawalList.fold<double>(0, (sum, w) => sum + (double.tryParse(w['amount'].toString()) ?? 0));

    // Balance from profile
    final profile = await _client
        .from('profiles')
        .select('balance')
        .eq('id', user.id)
        .single();

    // Active orders value
    final activeOrders = await _client
        .from('orders')
        .select('price')
        .eq('seller_id', user.id)
        .eq('status', 'active');

    final activeOrdersValue = List<Map<String, dynamic>>.from(activeOrders)
        .fold<double>(0, (sum, o) => sum + (double.tryParse(o['price'].toString()) ?? 0));

    return {
      'total_earnings': totalEarnings,
      'total_withdrawals': totalWithdrawals,
      'current_balance': (profile['balance'] as num?)?.toDouble() ?? 0,
      'active_orders_value': activeOrdersValue,
    };
  }

  /// Fetch seller's services
  static Future<List<Map<String, dynamic>>> getMyServices({int limit = 10}) async {
    final user = _client.auth.currentUser;
    if (user == null) return [];

    final data = await _client
        .from('services')
        .select()
        .eq('seller_id', user.id)
        .order('created_at', ascending: false)
        .limit(limit);
    return List<Map<String, dynamic>>.from(data);
  }
}
