import 'package:freelancer/core/notification_navigation.dart';
import 'package:freelancer/core/notifications/notification_payload.dart';
import 'package:freelancer/data/repositories/notification_repository.dart';
import 'package:freelancer/router/app_router.dart';
import 'package:freelancer/services/auth_service.dart';
import 'package:freelancer/services/local_notification_service.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

/// Opens a notification from banner or system tray using the root navigator.
Future<void> openNotificationFromPayload(NotificationPayload payload) async {
  final userId = Supabase.instance.client.auth.currentUser?.id;
  if (userId == null) return;

  final navContext = rootNavigatorKey.currentContext;
  if (navContext == null) return;

  final role = AuthService.cachedRole;
  final userRole = role == 'seller'
      ? NotificationUserRole.seller
      : NotificationUserRole.client;

  final notification = payload.toAppNotification(userId: userId);

  try {
    await NotificationNavigation.open(
      navContext,
      role: userRole,
      notification: notification,
    );
  } catch (_) {
    // Navigation helper already surfaces errors via snackbar when mounted.
  }
}

Future<void> markNotificationReadIfNeeded(
  NotificationRepository repository,
  String notificationId,
) async {
  try {
    await repository.markAsRead(notificationId);
  } catch (_) {}
}

NotificationUserRole notificationRoleFromAuth() {
  return AuthService.cachedRole == 'seller'
      ? NotificationUserRole.seller
      : NotificationUserRole.client;
}

void wireLocalNotificationTapHandler() {
  LocalNotificationService.instance.initialize(
    onTap: openNotificationFromPayload,
  );
}

Future<void> initLocalNotifications() async {
  await LocalNotificationService.instance.initialize(
    onTap: openNotificationFromPayload,
  );
}
