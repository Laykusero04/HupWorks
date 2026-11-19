import 'package:supabase_flutter/supabase_flutter.dart';

import '../data/models/notification_model.dart';

class NotificationService {
  static final _client = Supabase.instance.client;

  static const int pageSize = 20;

  /// First page of notifications (newest first).
  static Future<List<Map<String, dynamic>>> getNotifications({
    int limit = pageSize,
    int offset = 0,
  }) async {
    return getNotificationsPage(limit: limit, offset: offset);
  }

  static Future<List<Map<String, dynamic>>> getNotificationsPage({
    int limit = pageSize,
    int offset = 0,
  }) async {
    final user = _client.auth.currentUser;
    if (user == null) return [];

    final from = offset;
    final to = offset + limit - 1;

    final data = await _client
        .from('notifications')
        .select()
        .eq('user_id', user.id)
        .order('created_at', ascending: false)
        .range(from, to);
    return List<Map<String, dynamic>>.from(data);
  }

  /// Count unread notifications for the current user
  static Future<int> getUnreadCount() async {
    final user = _client.auth.currentUser;
    if (user == null) return 0;

    final count = await _client
        .from('notifications')
        .count(CountOption.exact)
        .eq('user_id', user.id)
        .eq('read', false);
    return count;
  }

  /// Mark a notification as read
  static Future<void> markAsRead(String notificationId) async {
    await _client
        .from('notifications')
        .update({'read': true}).eq('id', notificationId);
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

  /// Delete one notification of the current user. Filters by user_id as well
  /// as id (RLS policy from migration 0059 also enforces ownership).
  static Future<void> deleteNotification(String notificationId) async {
    final user = _client.auth.currentUser;
    if (user == null) return;

    // select() makes PostgREST return the deleted rows. RLS filtering a row
    // out returns 204 with no error, so an empty result means nothing was
    // deleted (policy missing or row already gone) and must not look like success.
    final deleted = await _client
        .from('notifications')
        .delete()
        .eq('id', notificationId)
        .eq('user_id', user.id)
        .select('id');
    if (deleted.isEmpty) {
      throw Exception('Notification was not deleted');
    }
  }

  /// Delete every notification of the current user (never other users' rows).
  /// Returns how many rows were actually deleted (0 may mean RLS blocked it).
  static Future<int> deleteAllNotifications() async {
    final user = _client.auth.currentUser;
    if (user == null) return 0;

    final deleted = await _client
        .from('notifications')
        .delete()
        .eq('user_id', user.id)
        .select('id');
    return deleted.length;
  }

  /// Subscribe to notification inserts/updates for badge refresh and live alerts.
  static RealtimeChannel subscribeToNotifications({
    void Function()? onChange,
    void Function(AppNotification notification)? onInsert,
  }) {
    final user = _client.auth.currentUser;
    if (user == null) throw Exception('Not authenticated');

    final channel = _client.channel('notifications:${user.id}');
    channel
        .onPostgresChanges(
          event: PostgresChangeEvent.insert,
          schema: 'public',
          table: 'notifications',
          filter: PostgresChangeFilter(
            type: PostgresChangeFilterType.eq,
            column: 'user_id',
            value: user.id,
          ),
          callback: (payload) {
            final notification = _parseNotificationRow(payload.newRecord);
            if (notification != null) {
              onInsert?.call(notification);
            }
            onChange?.call();
          },
        )
        .onPostgresChanges(
          event: PostgresChangeEvent.update,
          schema: 'public',
          table: 'notifications',
          filter: PostgresChangeFilter(
            type: PostgresChangeFilterType.eq,
            column: 'user_id',
            value: user.id,
          ),
          callback: (_) => onChange?.call(),
        )
        .subscribe();

    return channel;
  }

  static AppNotification? _parseNotificationRow(Map<String, dynamic> record) {
    if (record.isEmpty) return null;
    try {
      return AppNotification.fromJson(Map<String, dynamic>.from(record));
    } catch (_) {
      return null;
    }
  }

  static void unsubscribe(RealtimeChannel? channel) {
    if (channel != null) {
      _client.removeChannel(channel);
    }
  }
}
