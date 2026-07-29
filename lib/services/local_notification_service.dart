import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:freelancer/core/notifications/notification_payload.dart';
import 'package:freelancer/core/utils/app_logger.dart';
import 'package:freelancer/data/models/notification_model.dart';

typedef NotificationTapHandler = void Function(NotificationPayload payload);

/// System tray notifications (no Firebase). Driven by Supabase realtime in-app.
///
/// Requires a **full restart** (not hot reload) after adding the plugin.
/// On web/desktop, initialization is skipped; in-app banners still work.
class LocalNotificationService {
  LocalNotificationService._();

  static final LocalNotificationService instance = LocalNotificationService._();

  final FlutterLocalNotificationsPlugin _plugin = FlutterLocalNotificationsPlugin();
  bool _initialized = false;
  bool _attempted = false;
  NotificationTapHandler? _onTap;

  bool get isAvailable => _initialized;

  static const _androidChannel = AndroidNotificationChannel(
    'hupworks_notifications',
    'HupWorks notifications',
    description: 'Orders, messages, and activity updates',
    importance: Importance.high,
  );

  static bool get _targetsMobile {
    if (kIsWeb) return false;
    return defaultTargetPlatform == TargetPlatform.android ||
        defaultTargetPlatform == TargetPlatform.iOS;
  }

  Future<void> initialize({NotificationTapHandler? onTap}) async {
    if (_initialized || _attempted) return;
    _attempted = true;
    _onTap = onTap;

    if (!_targetsMobile) {
      AppLogger.warn(
        'LocalNotificationService',
        'Skipped on this platform. Tray notifications need Android/iOS. '
            'In-app banners still work.',
      );
      return;
    }

    try {
      const androidSettings = AndroidInitializationSettings('@mipmap/ic_launcher');
      const darwinSettings = DarwinInitializationSettings(
        requestAlertPermission: false,
        requestBadgePermission: false,
        requestSoundPermission: false,
      );

      final ok = await _plugin.initialize(
        settings: const InitializationSettings(
          android: androidSettings,
          iOS: darwinSettings,
          macOS: darwinSettings,
        ),
        onDidReceiveNotificationResponse: _onNotificationResponse,
        onDidReceiveBackgroundNotificationResponse: _onBackgroundNotificationResponse,
      );

      if (ok != true) {
        AppLogger.error('LocalNotificationService.initialize', 'Plugin returned false', null);
        return;
      }

      final android =
          _plugin.resolvePlatformSpecificImplementation<AndroidFlutterLocalNotificationsPlugin>();
      await android?.createNotificationChannel(_androidChannel);
      if (defaultTargetPlatform == TargetPlatform.android) {
        await android?.requestNotificationsPermission();
      }

      final ios = _plugin.resolvePlatformSpecificImplementation<IOSFlutterLocalNotificationsPlugin>();
      await ios?.requestPermissions(alert: true, badge: true, sound: true);

      _initialized = true;
    } on MissingPluginException catch (e, st) {
      AppLogger.error(
        'LocalNotificationService.initialize',
        '$e — Stop the app completely, then run: flutter run -d <android|ios device>',
        st,
      );
    } catch (e, st) {
      AppLogger.error('LocalNotificationService.initialize', e, st);
    }
  }

  void _onNotificationResponse(NotificationResponse response) {
    final payload = NotificationPayload.decode(response.payload);
    if (payload != null) {
      _onTap?.call(payload);
    }
  }

  @pragma('vm:entry-point')
  static void _onBackgroundNotificationResponse(NotificationResponse response) {
    // Tap is handled when the app resumes via onDidReceiveNotificationResponse.
  }

  Future<void> show(AppNotification notification) async {
    if (!_initialized) return;

    final payload = NotificationPayload.fromNotification(notification);
    final id = notification.id.hashCode & 0x7fffffff;

    const androidDetails = AndroidNotificationDetails(
      'hupworks_notifications',
      'HupWorks notifications',
      channelDescription: 'Orders, messages, and activity updates',
      importance: Importance.high,
      priority: Priority.high,
    );
    const darwinDetails = DarwinNotificationDetails();
    const details = NotificationDetails(
      android: androidDetails,
      iOS: darwinDetails,
      macOS: darwinDetails,
    );

    try {
      await _plugin.show(
        id: id,
        title: notification.title,
        body: notification.body ?? '',
        notificationDetails: details,
        payload: payload.encode(),
      );
    } on MissingPluginException catch (e, st) {
      _initialized = false;
      AppLogger.error('LocalNotificationService.show', e, st);
    } catch (e, st) {
      AppLogger.error('LocalNotificationService.show', e, st);
    }
  }
}
