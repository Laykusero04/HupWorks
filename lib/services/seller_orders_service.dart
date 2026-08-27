import 'dart:io';
import 'package:freelancer/core/utils/app_logger.dart';
import 'package:freelancer/core/utils/job_offer_delivery.dart';
import 'package:freelancer/services/chat_service.dart';
import 'package:freelancer/services/job_posts_service.dart';
import 'package:freelancer/services/profile_service.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class SellerOrdersService {
  static final _client = Supabase.instance.client;

  /// Fetch seller orders filtered by status
  static Future<List<Map<String, dynamic>>> getSellerOrders({String? status}) async {
    final user = _client.auth.currentUser;
    if (user == null) return [];

    var query = _client
        .from('orders')
        .select(
          '*, services!service_id(title, images), client:profiles!client_id(name), '
          'job_offers!job_offer_id(job_posts(title))',
        )
        .eq('seller_id', user.id);

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
          'client:profiles!client_id(name, profile_image_url), '
          'job_offers!job_offer_id('
          'id, cover_letter, delivery_time, delivery_time_unit, price_basis, '
          'job_posts(id, title, description, job_type, location, location_type, attendance_mode, workers_needed)'
          ')',
        )
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

  /// Freelancer requests contract cancellation (client must approve within 48h).
  static Future<void> requestCancellation({
    required String orderId,
    required String reasonCode,
    required String reasonNote,
  }) async {
    await _client.rpc(
      'request_order_cancellation',
      params: {
        'p_order_id': orderId,
        'p_reason_code': reasonCode,
        'p_reason_note': reasonNote.trim(),
      },
    );
  }

  /// Freelancer withdraws a pending cancellation request.
  static Future<void> withdrawCancellation(String orderId) async {
    await _client.rpc(
      'withdraw_order_cancellation',
      params: {'p_order_id': orderId},
    );
  }

  /// Best-effort chat message to client when cancellation is requested.
  static Future<void> notifyClientCancellationRequest({
    required String orderId,
    required String clientId,
    required String reasonCode,
    required String reasonNote,
  }) async {
    try {
      final conversation = await ChatService.getOrCreateJobApplicationConversation(
        buyerUserId: clientId,
      );
      final label = _cancellationReasonLabel(reasonCode);
      await ChatService.sendMessage(
        conversationId: conversation['id'] as String,
        content:
            '📋 Cancellation requested for contract #${orderId.substring(0, 8).toUpperCase()}\n'
            'Reason: $label\n'
            '${reasonNote.trim()}\n\n'
            'Please open Contracts to approve or keep the contract active (48h to respond).',
      );
    } catch (e, st) {
      AppLogger.error('SellerOrdersService.notifyCancellationChat', e, st);
    }
  }

  static String _cancellationReasonLabel(String code) {
    switch (code) {
      case 'schedule_conflict':
        return 'Schedule conflict';
      case 'scope_mismatch':
        return 'Scope does not match agreement';
      case 'site_or_safety':
        return 'Site or safety concern';
      case 'personal_emergency':
        return 'Personal emergency';
      case 'client_issue':
        return 'Issue with client / communication';
      default:
        return 'Other';
    }
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

  /// Fetch open job posts for Find Jobs, filtered on the server.
  ///
  /// Uses [browse_open_job_posts] so clients do not download every open post.
  static Future<List<Map<String, dynamic>>> getBuyerRequests({
    String? titleQuery,
    List<String>? categoryIds,
    List<String>? skillNames,
    String? jobType,
    double? maxDistanceKm,
    bool includeRemote = true,
    double? sellerLat,
    double? sellerLng,
    int limit = 50,
    int offset = 0,
  }) async {
    final title = titleQuery?.trim();
    final cats = (categoryIds ?? const <String>[])
        .map((e) => e.trim())
        .where((e) => e.isNotEmpty)
        .toList();
    final skills = (skillNames ?? const <String>[])
        .map((e) => e.trim())
        .where((e) => e.isNotEmpty)
        .toList();

    final raw = await _client.rpc(
      'browse_open_job_posts',
      params: {
        'p_title_query': (title == null || title.isEmpty) ? null : title,
        'p_category_ids': cats.isEmpty ? null : cats,
        'p_skill_names': skills.isEmpty ? null : skills,
        'p_job_type': (jobType == null || jobType.isEmpty) ? null : jobType,
        'p_max_distance_km': maxDistanceKm,
        'p_include_remote': includeRemote,
        'p_seller_lat': sellerLat,
        'p_seller_lng': sellerLng,
        'p_limit': limit,
        'p_offset': offset,
      },
    );

    if (raw == null) return [];
    if (raw is List) return List<Map<String, dynamic>>.from(raw);
    if (raw is Map) {
      // Defensive: some clients wrap jsonb oddly.
      final values = raw.values.toList();
      if (values.length == 1 && values.first is List) {
        return List<Map<String, dynamic>>.from(values.first as List);
      }
    }
    return [];
  }

  /// Fetch single job post details with offer count + client public stats.
  static Future<Map<String, dynamic>> getBuyerRequestDetails(String jobPostId) async {
    final data = await _client
        .from('job_posts')
        .select(
          '*, categories(name), ${JobPostsService.jobPostSkillsSelect}, '
          'profiles:client_id(id, name, profile_image_url, rating, created_at, country, city, bio)',
        )
        .eq('id', jobPostId)
        .single();

    // Get offer count
    final offers = await _client
        .from('job_offers')
        .select('id')
        .eq('job_post_id', jobPostId);

    data['offer_count'] = (offers as List).length;

    final uid = _client.auth.currentUser?.id;
    if (uid != null) {
      final mine = await _client
          .from('job_offers')
          .select('id, status')
          .eq('job_post_id', jobPostId)
          .eq('seller_id', uid)
          .maybeSingle();
      data['my_offer'] = mine;
    }

    final clientId = data['client_id'] as String?;
    if (clientId != null) {
      final jobs = await _client
          .from('job_posts')
          .select('id')
          .eq('client_id', clientId);
      data['client_job_posts_count'] = (jobs as List).length;

      final reviewStats = await ProfileService.getReviewStats(clientId);
      data['client_review_count'] = reviewStats.reviewCount;
      data['client_rating'] = reviewStats.reviewCount > 0
          ? reviewStats.rating
          : ProfileService.parseRatingValue(
              (data['profiles'] as Map<String, dynamic>?)?['rating'],
            ) ??
              0.0;

      final embedded = data['profiles'];
      if (embedded is Map<String, dynamic>) {
        embedded['review_count'] = reviewStats.reviewCount;
        embedded['rating'] = data['client_rating'];
        embedded['job_posts_count'] = data['client_job_posts_count'];
      }
    }

    return data;
  }

  /// Create offer on a job post.
  /// Also seeds the (client, seller) chat with a formatted bid message so
  /// negotiation can continue in chat.
  static Future<void> createOffer({
    required String jobPostId,
    required double price,
    String priceBasis = JobPostsService.budgetBasisFixed,
    int? deliveryTime,
    String? deliveryTimeUnit,
    String? coverLetter,
    bool agreedToPostedRate = false,
  }) async {
    final user = _client.auth.currentUser;
    if (user == null) throw Exception('Not logged in');

    final job = await _client
        .from('job_posts')
        .select('id, title, status, client_id')
        .eq('id', jobPostId)
        .single();

    if ((job['status'] as String?)?.toLowerCase() != 'open') {
      throw Exception('This job is closed and is not accepting new applications.');
    }
    if (job['client_id'] == user.id) {
      throw Exception('You cannot apply to your own job post.');
    }

    final existingMine = await _client
        .from('job_offers')
        .select('id, status')
        .eq('job_post_id', jobPostId)
        .eq('seller_id', user.id)
        .maybeSingle();
    if (existingMine != null) {
      final st = (existingMine['status'] as String?)?.toLowerCase();
      if (st == 'pending' || st == 'accepted') {
        throw Exception('You have already applied to this job.');
      }
    }

    final insert = <String, dynamic>{
      'job_post_id': jobPostId,
      'seller_id': user.id,
      'price': price,
      'price_basis': JobPostsService.normalizeBudgetBasis(priceBasis),
      'cover_letter': coverLetter,
      'status': 'pending',
    };
    if (deliveryTime != null && deliveryTime > 0 && deliveryTimeUnit != null) {
      insert['delivery_time'] = deliveryTime;
      insert['delivery_time_unit'] = JobOfferDelivery.normalizeUnit(deliveryTimeUnit);
    } else {
      insert['delivery_time'] = null;
      insert['delivery_time_unit'] = null;
    }

    final inserted =
        await _client.from('job_offers').insert(insert).select('id').single();
    final offerId = inserted['id'] as String;

    // Seed the chat — best-effort, never blocks the apply flow.
    try {
      final conversation =
          await ChatService.getOrCreateJobApplicationConversation(
        buyerUserId: job['client_id'] as String,
      );

      final body = StringBuffer();
      if (agreedToPostedRate) {
        body
          ..writeln('📋 Application for "${job['title']}"')
          ..writeln(
            'Agreed to client\'s posted rate: ${JobPostsService.formatOfferAmountLine(price, insert['price_basis'])}',
          );
      } else {
        body
          ..writeln('📋 New bid for "${job['title']}"')
          ..writeln(
            'Amount: ${JobPostsService.formatOfferAmountLine(price, insert['price_basis'])}',
          );
        final deliveryTime = insert['delivery_time'] as int?;
        final deliveryUnit = insert['delivery_time_unit'] as String?;
        if (deliveryTime != null && deliveryUnit != null) {
          body.writeln(
            'Delivery: ${JobOfferDelivery.formatLabel(deliveryTime, deliveryUnit)}',
          );
        }
      }
      if (coverLetter != null && coverLetter.trim().isNotEmpty) {
        body
          ..writeln()
          ..writeln(coverLetter.trim());
      }

      await ChatService.sendMessage(
        conversationId: conversation['id'] as String,
        content: body.toString().trim(),
        messageType: 'job_offer',
        jobOfferId: offerId,
      );
    } catch (e, st) {
      AppLogger.error('SellerOrdersService.seedApplicationChat', e, st);
    }
  }

  /// Fetch the current freelancer's submitted applications (job_offers).
  /// Joined with the parent job post's title/status/job_type AND the client's
  /// profile, so a "Message" action can open chat without an extra lookup.
  static Future<List<Map<String, dynamic>>> getMyApplications() async {
    final user = _client.auth.currentUser;
    if (user == null) return [];

    final data = await _client
        .from('job_offers')
        .select(
          '*, job_posts!job_post_id(id, title, status, job_type, client_id, '
          'client:profiles!job_posts_client_id_fkey(id, name, profile_image_url))',
        )
        .eq('seller_id', user.id)
        .order('created_at', ascending: false);
    return List<Map<String, dynamic>>.from(data);
  }
}
