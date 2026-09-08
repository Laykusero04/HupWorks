import 'package:flutter/material.dart';
import 'package:freelancer/data/models/notification_model.dart';
import 'package:freelancer/router/route_names.dart';
import 'package:freelancer/core/utils/chat_navigation.dart';
import 'package:go_router/go_router.dart';
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
          if (!context.mounted) return;
          context.push(AppRoutes.sellerBuyerRequestDetailsOf(refId));
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
        context.push(AppRoutes.clientOrderDetailsOf(orderId));
        return;
      case NotificationUserRole.seller:
        context.push(AppRoutes.sellerOrderDetailsOf(orderId));
        return;
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
          context.push(AppRoutes.clientJobDetailsOf(jobPostId));
        } else {
          await _openOrder(context, role: role, orderId: orderId);
        }
        return;
      case NotificationUserRole.seller:
        context.push(AppRoutes.sellerOrderDetailsOf(orderId));
        return;
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
          context.push(AppRoutes.clientJobDetailsOf(jobPostId));
        } else {
          _showSnack(context, 'Job post not found.');
        }
        return;
      case NotificationUserRole.seller:
        context.push(AppRoutes.sellerApplications);
        return;
    }
  }

  static void _showSnack(BuildContext context, String message) {
    if (!context.mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(message)));
  }
}
