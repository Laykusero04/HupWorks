import 'package:supabase_flutter/supabase_flutter.dart';

import '../../core/errors/failures.dart';
import '../../services/notification_service.dart';
import '../models/notification_model.dart';

class NotificationRepository {
  Future<List<AppNotification>> getNotifications({
    int limit = NotificationService.pageSize,
    int offset = 0,
  }) async {
    try {
      final data = await NotificationService.getNotificationsPage(
        limit: limit,
        offset: offset,
      );
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

  RealtimeChannel subscribeToNotifications({
    void Function()? onChange,
    void Function(AppNotification notification)? onInsert,
  }) {
    return NotificationService.subscribeToNotifications(
      onChange: onChange,
      onInsert: onInsert,
    );
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
