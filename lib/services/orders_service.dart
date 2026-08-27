import 'package:freelancer/core/utils/app_logger.dart';
import 'package:freelancer/services/profile_service.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class OrdersService {
  static final _client = Supabase.instance.client;

  static String? _uuidString(dynamic value) {
    if (value == null) return null;
    final s = value.toString().trim();
    if (s.isEmpty || s == 'null') return null;
    return s;
  }

  /// `service_id` on the order (null for job-offer contracts).
  static String? serviceIdFromOrderMap(Map<String, dynamic> order) =>
      _uuidString(order['service_id']);

  /// `job_offer_id` on the order row, or embedded `job_offers.id` from the select.
  static String? jobOfferIdFromOrderMap(Map<String, dynamic> order) {
    final direct = _uuidString(order['job_offer_id']);
    if (direct != null) return direct;
    final nested = order['job_offers'];
    if (nested is Map<String, dynamic>) {
      return _uuidString(nested['id']);
    }
    return null;
  }

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

    final data = await _client
        .from('orders')
        .insert({
          'service_id': serviceId,
          'client_id': user.id,
          'seller_id': sellerId,
          'price': price,
          'status': 'active',
          'delivery_deadline': deadline.toIso8601String(),
        })
        .select()
        .single();

    return data;
  }

  /// Fetch client orders, optionally filtered by status
  static Future<List<Map<String, dynamic>>> getClientOrders(
      {String? status}) async {
    final user = _client.auth.currentUser;
    if (user == null) return [];

    var query = _client
        .from('orders')
        .select(
          '*, services!service_id(title, images), seller:profiles!seller_id(id, name), '
          'job_offers!job_offer_id(job_posts(title)), '
          'reviews(id, reviewer_id, rating, comment, created_at)',
        )
        .eq('client_id', user.id);

    if (status != null) {
      final s = status.toLowerCase();
      if (s == 'active') {
        query = query.inFilter('status', ['active', 'cancellation_requested']);
      } else {
        query = query.eq('status', s);
      }
    }

    final data = await query.order('created_at', ascending: false);
    return List<Map<String, dynamic>>.from(data);
  }

  /// Fetch single order details
  static Future<Map<String, dynamic>> getOrderDetails(String orderId) async {
    final data = await _client
        .from('orders')
        .select(
          '*, services!service_id(title, description, images, delivery_time, revision_count, price), '
          'seller:profiles!seller_id(id, name, profile_image_url), '
          'job_offers!job_offer_id('
          'id, cover_letter, delivery_time, delivery_time_unit, price_basis, '
          'job_posts(id, title, description, job_type, location, location_type, attendance_mode, workers_needed)'
          '), '
          'reviews(id, reviewer_id, rating, comment, created_at), '
          'order_deliveries(id, order_id, message, attachment_url, delivered_at)',
        )
        .eq('id', orderId)
        .single();
    return data;
  }

  /// True if the signed-in user already has a `reviews` row for this order.
  static bool currentUserHasReviewedOrder(Map<String, dynamic> orderDetails) {
    final uid = _client.auth.currentUser?.id;
    if (uid == null) return false;
    final raw = orderDetails['reviews'];
    if (raw == null) return false;
    if (raw is List) {
      for (final r in raw) {
        if (r is Map && r['reviewer_id'] == uid) return true;
      }
      return false;
    }
    if (raw is Map<String, dynamic>) {
      return raw['reviewer_id'] == uid;
    }
    return false;
  }

  /// Client leaves a review for the seller on this order.
  static Future<void> submitClientOrderReview({
    required String orderId,
    required String sellerId,
    required int rating,
    String? comment,
    String? serviceId,
    String? jobOfferId,
  }) async {
    final user = _client.auth.currentUser;
    if (user == null) throw Exception('Not logged in');
    if (rating < 1 || rating > 5) throw Exception('Invalid rating');

    final row = <String, dynamic>{
      'order_id': orderId,
      'reviewer_id': user.id,
      'reviewed_id': sellerId,
      'rating': rating,
    };
    final sid = serviceId?.trim();
    if (sid != null && sid.isNotEmpty) row['service_id'] = sid;
    final jid = jobOfferId?.trim();
    if (jid != null && jid.isNotEmpty) row['job_offer_id'] = jid;
    final c = comment?.trim();
    if (c != null && c.isNotEmpty) row['comment'] = c;

    try {
      await _client.from('reviews').insert(row).select('id').single();
      ProfileService.clearProfileCache();
      await ProfileService.syncReviewStatsToProfile(sellerId);
    } on PostgrestException catch (e) {
      final msg = e.message;
      final code = e.code;
      if (code == '23502' && msg.toLowerCase().contains('service_id')) {
        throw Exception(
          'This order has no marketplace service. In Supabase → SQL Editor, run '
          'migrations/0006_reviews_service_id_nullable.sql so reviews.service_id can be null.',
        );
      }
      if (code == '23503') {
        throw Exception(
          'Review could not be saved (linked order, profile, or job offer was not found). $msg',
        );
      }
      if (code == '42501' || msg.toLowerCase().contains('row-level security')) {
        throw Exception(
          'Review could not be saved (permission denied). You must be the client or seller on this order.',
        );
      }
      throw Exception(msg.isNotEmpty ? msg : e.toString());
    }
  }

  /// Client marks the order complete after the seller has delivered.
  static Future<void> completeOrder(String orderId) async {
    await _client.rpc(
      'complete_order',
      params: {'p_order_id': orderId},
    );
  }

  /// Seller leaves a review for the client on this order.
  static Future<void> submitSellerOrderReview({
    required String orderId,
    required String clientId,
    required int rating,
    String? comment,
    String? serviceId,
    String? jobOfferId,
  }) async {
    final user = _client.auth.currentUser;
    if (user == null) throw Exception('Not logged in');
    if (rating < 1 || rating > 5) throw Exception('Invalid rating');

    final row = <String, dynamic>{
      'order_id': orderId,
      'reviewer_id': user.id,
      'reviewed_id': clientId,
      'rating': rating,
    };
    final sid = serviceId?.trim();
    if (sid != null && sid.isNotEmpty) row['service_id'] = sid;
    final jid = jobOfferId?.trim();
    if (jid != null && jid.isNotEmpty) row['job_offer_id'] = jid;
    final c = comment?.trim();
    if (c != null && c.isNotEmpty) row['comment'] = c;

    try {
      await _client.from('reviews').insert(row).select('id').single();
      ProfileService.clearProfileCache();
      await ProfileService.syncReviewStatsToProfile(clientId);
    } on PostgrestException catch (e) {
      final msg = e.message;
      final code = e.code;
      if (code == '23502' && msg.toLowerCase().contains('service_id')) {
        throw Exception(
          'This order has no marketplace service. In Supabase → SQL Editor, run '
          'migrations/0006_reviews_service_id_nullable.sql so reviews.service_id can be null.',
        );
      }
      if (code == '23503') {
        throw Exception(
          'Review could not be saved (linked order, profile, or job offer was not found). $msg',
        );
      }
      if (code == '42501' || msg.toLowerCase().contains('row-level security')) {
        throw Exception(
          'Review could not be saved (permission denied). You must be the client or seller on this order.',
        );
      }
      throw Exception(msg.isNotEmpty ? msg : e.toString());
    }
  }

  /// Update order status (prefer [completeOrder] / deliver RPC for status changes).
  static Future<void> updateOrderStatus(String orderId, String status) async {
    await _client.from('orders').update({
      'status': status,
      if (status == 'completed')
        'completed_at': DateTime.now().toIso8601String(),
    }).eq('id', orderId);
  }

  /// Client approves or declines a freelancer cancellation request.
  static Future<void> respondToCancellation({
    required String orderId,
    required bool approve,
  }) async {
    await _client.rpc(
      'respond_order_cancellation',
      params: {
        'p_order_id': orderId,
        'p_approve': approve,
      },
    );
  }

  /// Expire cancellation requests older than 48h (call on order list/details load).
  static Future<void> expireStaleCancellationRequests() async {
    try {
      await _client.rpc('expire_stale_cancellation_requests');
    } catch (e, st) {
      AppLogger.error('OrdersService.expireStaleCancellationRequests', e, st);
    }
  }
}
