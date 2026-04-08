import 'dart:io';
import 'package:supabase_flutter/supabase_flutter.dart';

class SellerOrdersService {
  static final _client = Supabase.instance.client;

  /// Fetch seller orders filtered by status
  static Future<List<Map<String, dynamic>>> getSellerOrders({String? status}) async {
    final user = _client.auth.currentUser;
    if (user == null) return [];

    var query = _client
        .from('orders')
        .select('*, services!service_id(title, images), client:profiles!client_id(name)')
        .eq('seller_id', user.id);

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
        .select('*, services!service_id(title, description, images, delivery_time, revision_count, price), client:profiles!client_id(name, profile_image_url)')
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

  /// Deliver order with message and optional attachment
  static Future<void> deliverOrder({
    required String orderId,
    required String message,
    File? attachment,
  }) async {
    String? attachmentUrl;

    if (attachment != null) {
      final user = _client.auth.currentUser;
      if (user == null) throw Exception('Not logged in');
      final ext = attachment.path.split('.').last;
      final path = '${user.id}/${orderId}_delivery.$ext';

      await _client.storage.from('chat-attachments').upload(
        path,
        attachment,
        fileOptions: const FileOptions(upsert: true),
      );
      attachmentUrl = _client.storage.from('chat-attachments').getPublicUrl(path);
    }

    await _client.from('order_deliveries').insert({
      'order_id': orderId,
      'message': message,
      'attachment_url': attachmentUrl,
    });

    await updateOrderStatus(orderId, 'delivered');
  }

  /// Fetch open job posts (buyer requests)
  static Future<List<Map<String, dynamic>>> getBuyerRequests() async {
    final data = await _client
        .from('job_posts')
        .select('*, categories(name), profiles:client_id(name, profile_image_url)')
        .eq('status', 'open')
        .order('created_at', ascending: false);
    return List<Map<String, dynamic>>.from(data);
  }

  /// Fetch single job post details with offer count
  static Future<Map<String, dynamic>> getBuyerRequestDetails(String jobPostId) async {
    final data = await _client
        .from('job_posts')
        .select('*, categories(name), profiles:client_id(name, profile_image_url)')
        .eq('id', jobPostId)
        .single();

    // Get offer count
    final offers = await _client
        .from('job_offers')
        .select('id')
        .eq('job_post_id', jobPostId);

    data['offer_count'] = (offers as List).length;
    return data;
  }

  /// Create offer on a job post
  static Future<void> createOffer({
    required String jobPostId,
    required double price,
    required int deliveryTime,
    String? coverLetter,
  }) async {
    final user = _client.auth.currentUser;
    if (user == null) throw Exception('Not logged in');

    await _client.from('job_offers').insert({
      'job_post_id': jobPostId,
      'seller_id': user.id,
      'price': price,
      'delivery_time': deliveryTime,
      'cover_letter': coverLetter,
      'status': 'pending',
    });
  }
}
