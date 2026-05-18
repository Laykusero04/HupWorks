import 'package:supabase_flutter/supabase_flutter.dart';

import '../../core/errors/failures.dart';
import '../../services/notification_service.dart';
import '../models/notification_model.dart';

class NotificationRepository {
  Future<List<AppNotification>> getNotifications() async {
    try {
      final data = await NotificationService.getNotifications();
      return data.map((m) => AppNotification.fromJson(m)).toList();
    } catch (e) {
      throw ServerFailure(e.toString());
    }
  }

  Future<int> getUnreadCount() async {
    try {
      return await NotificationService.getUnreadCount();
    } catch (e) {
      throw ServerFailure(e.toString());
    }
  }

  RealtimeChannel subscribeToNotifications({required void Function() onChange}) {
    return NotificationService.subscribeToNotifications(onChange: onChange);
  }

  void unsubscribe(RealtimeChannel? channel) {
    NotificationService.unsubscribe(channel);
  }

  Future<void> markAsRead(String notificationId) async {
    try {
      await NotificationService.markAsRead(notificationId);
    } catch (e) {
      throw ServerFailure(e.toString());
    }
  }

  Future<void> markAllAsRead() async {
    try {
      await NotificationService.markAllAsRead();
    } catch (e) {
      throw ServerFailure(e.toString());
    }
  }
}
