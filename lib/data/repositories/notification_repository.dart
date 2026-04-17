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
