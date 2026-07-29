import 'dart:convert';

import 'package:freelancer/data/models/notification_model.dart';

/// JSON payload stored on system notifications for tap handling.
class NotificationPayload {
  const NotificationPayload({
    required this.id,
    required this.title,
    this.body,
    this.type,
    this.referenceId,
  });

  final String id;
  final String title;
  final String? body;
  final String? type;
  final String? referenceId;

  factory NotificationPayload.fromNotification(AppNotification n) {
    return NotificationPayload(
      id: n.id,
      title: n.title,
      body: n.body,
      type: n.type,
      referenceId: n.referenceId,
    );
  }

  AppNotification toAppNotification({required String userId}) {
    return AppNotification(
      id: id,
      userId: userId,
      title: title,
      body: body,
      type: type,
      referenceId: referenceId,
      read: false,
      createdAt: DateTime.now(),
    );
  }

  String encode() => jsonEncode({
        'id': id,
        'title': title,
        'body': body,
        'type': type,
        'reference_id': referenceId,
      });

  static NotificationPayload? decode(String? raw) {
    if (raw == null || raw.isEmpty) return null;
    try {
      final map = jsonDecode(raw) as Map<String, dynamic>;
      return NotificationPayload(
        id: map['id'] as String,
        title: map['title'] as String? ?? '',
        body: map['body'] as String?,
        type: map['type'] as String?,
        referenceId: map['reference_id'] as String?,
      );
    } catch (_) {
      return null;
    }
  }
}
