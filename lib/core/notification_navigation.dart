import 'package:flutter/material.dart';
import 'package:freelancer/core/utils/chat_navigation.dart';
import 'package:freelancer/data/models/notification_model.dart';
import 'package:freelancer/screen/client%20screen/client%20job%20post/job_details.dart';
import 'package:freelancer/screen/client%20screen/client%20orders/client_order_details.dart';
import 'package:freelancer/screen/seller%20screen/applications/seller_applications.dart';
import 'package:freelancer/screen/seller%20screen/buyer%20request/buyer_request_details.dart';
import 'package:go_router/go_router.dart';
import 'package:nb_utils/nb_utils.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

enum NotificationUserRole { client, seller }

class NotificationNavigation {
  static final _client = Supabase.instance.client;

  static Future<void> open(
    BuildContext context, {
    required NotificationUserRole role,
    required AppNotification notification,
  }) async {
    final refId = notification.referenceId;
    if (refId == null || refId.isEmpty) {
      _showSnack(context, 'This notification has no linked item.');
      return;
    }

    final type = (notification.type ?? '').toLowerCase();

    try {
      switch (type) {
        case 'order':
        case 'hire_onboarding':
          await _openOrder(context, role: role, orderId: refId);
          return;
        case 'attendance':
        case 'hour_report':
          await _openAttendance(context, role: role, orderId: refId);
          return;
        case 'job_offer':
          await _openJobOffer(context, role: role, offerId: refId);
          return;
        case 'job_match':
          if (role != NotificationUserRole.seller) {
            _showSnack(context, 'Unable to open this notification.');
            return;
          }
          await BuyerRequestDetails(jobPostId: refId).launch(context);
          return;
        case 'review':
          await _openOrder(context, role: role, orderId: refId);
          return;
        case 'message':
          await openChatFromNotification(
            context,
            conversationId: refId,
            role: role,
          );
          return;
        default:
          _showSnack(context, 'Unable to open this notification.');
      }
    } catch (e) {
      if (!context.mounted) return;
      _showSnack(context, 'Could not open: $e');
    }
  }

  static Future<void> _openOrder(
    BuildContext context, {
    required NotificationUserRole role,
    required String orderId,
  }) async {
    if (!context.mounted) return;
    switch (role) {
      case NotificationUserRole.client:
        await ClientOrderDetails(orderId: orderId).launch(context);
      case NotificationUserRole.seller:
        context.push('/seller/orders/$orderId');
    }
  }

  /// Attendance notifications store [orderId] as reference; client opens job post.
  static Future<void> _openAttendance(
    BuildContext context, {
    required NotificationUserRole role,
    required String orderId,
  }) async {
    final row = await _client
        .from('orders')
        .select('job_offers!job_offer_id(job_post_id)')
        .eq('id', orderId)
        .maybeSingle();

    if (!context.mounted) return;

    if (row == null) {
      _showSnack(context, 'Contract no longer available.');
      return;
    }

    final offerRaw = row['job_offers'];
    final Map<String, dynamic>? offer = offerRaw is Map<String, dynamic>
        ? offerRaw
        : (offerRaw is Map
            ? Map<String, dynamic>.from(offerRaw)
            : (offerRaw is List && offerRaw.isNotEmpty && offerRaw.first is Map
                ? Map<String, dynamic>.from(offerRaw.first as Map)
                : null));
    final jobPostId = offer?['job_post_id'] as String?;

    switch (role) {
      case NotificationUserRole.client:
        if (jobPostId != null) {
          await JobDetails(jobPostId: jobPostId).launch(context);
        } else {
          await _openOrder(context, role: role, orderId: orderId);
        }
      case NotificationUserRole.seller:
        context.push('/seller/orders/$orderId');
    }
  }

  static Future<void> _openJobOffer(
    BuildContext context, {
    required NotificationUserRole role,
    required String offerId,
  }) async {
    final row = await _client
        .from('job_offers')
        .select('job_post_id')
        .eq('id', offerId)
        .maybeSingle();

    if (!context.mounted) return;

    if (row == null) {
      _showSnack(context, 'Application no longer available.');
      return;
    }

    final jobPostId = row['job_post_id'] as String?;

    switch (role) {
      case NotificationUserRole.client:
        if (jobPostId != null) {
          await JobDetails(jobPostId: jobPostId).launch(context);
        } else {
          _showSnack(context, 'Job post not found.');
        }
      case NotificationUserRole.seller:
        await const SellerApplications().launch(context);
    }
  }

  static void _showSnack(BuildContext context, String message) {
    if (!context.mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(message)));
  }
}
