import 'package:supabase_flutter/supabase_flutter.dart';

class OrdersService {
  static final _client = Supabase.instance.client;

  /// Create a new order
  static Future<Map<String, dynamic>> createOrder({
    required String serviceId,
    required String sellerId,
    required double price,
    required int deliveryDays,
  }) async {
    final user = _client.auth.currentUser;
    if (user == null) throw Exception('Not logged in');

    final deadline = DateTime.now().add(Duration(days: deliveryDays));

    final data = await _client.from('orders').insert({
      'service_id': serviceId,
      'client_id': user.id,
      'seller_id': sellerId,
      'price': price,
      'status': 'pending',
      'delivery_deadline': deadline.toIso8601String(),
    }).select().single();

    return data;
  }

  /// Fetch client orders, optionally filtered by status
  static Future<List<Map<String, dynamic>>> getClientOrders({String? status}) async {
    final user = _client.auth.currentUser;
    if (user == null) return [];

    var query = _client
        .from('orders')
        .select('*, services!service_id(title, images), seller:profiles!seller_id(name)')
        .eq('client_id', user.id);

    if (status != null) {
      query = query.eq('status', status.toLowerCase());
    }

    final data = await query.order('created_at', ascending: false);
    return List<Map<String, dynamic>>.from(data);
  }

  /// Fetch single order details
  static Future<Map<String, dynamic>> getOrderDetails(String orderId) async {
    final data = await _client
        .from('orders')
        .select('*, services!service_id(title, description, images, delivery_time, revision_count, price), seller:profiles!seller_id(name, profile_image_url)')
        .eq('id', orderId)
        .single();
    return data;
  }

  /// Update order status
  static Future<void> updateOrderStatus(String orderId, String status) async {
    await _client.from('orders').update({
      'status': status,
      if (status == 'completed') 'completed_at': DateTime.now().toIso8601String(),
    }).eq('id', orderId);
  }
}
