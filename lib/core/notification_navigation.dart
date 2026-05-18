import 'package:flutter/material.dart';
import 'package:freelancer/data/models/notification_model.dart';
import 'package:freelancer/screen/client%20screen/client%20job%20post/job_details.dart';
import 'package:freelancer/screen/client%20screen/client%20orders/client_order_details.dart';
import 'package:freelancer/screen/seller%20screen/applications/seller_applications.dart';
import 'package:freelancer/screen/seller%20screen/orders/seller_order_details.dart';
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
          await _openOrder(context, role: role, orderId: refId);
          return;
        case 'job_offer':
          await _openJobOffer(context, role: role, offerId: refId);
          return;
        case 'review':
          await _openOrder(context, role: role, orderId: refId);
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
        await SellerOrderDetails(orderId: orderId).launch(context);
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
