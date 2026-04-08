import 'package:supabase_flutter/supabase_flutter.dart';

class NotificationService {
  static final _client = Supabase.instance.client;

  /// Fetch notifications for current user
  static Future<List<Map<String, dynamic>>> getNotifications() async {
    final user = _client.auth.currentUser;
    if (user == null) return [];

    final data = await _client
        .from('notifications')
        .select()
        .eq('user_id', user.id)
        .order('created_at', ascending: false);
    return List<Map<String, dynamic>>.from(data);
  }

  /// Mark a notification as read
  static Future<void> markAsRead(String notificationId) async {
    await _client
        .from('notifications')
        .update({'read': true})
        .eq('id', notificationId);
  }

  /// Mark all notifications as read
  static Future<void> markAllAsRead() async {
    final user = _client.auth.currentUser;
    if (user == null) return;

    await _client
        .from('notifications')
        .update({'read': true})
        .eq('user_id', user.id)
        .eq('read', false);
  }
}
