import 'dart:async';

import 'package:flutter/widgets.dart';
import 'package:freelancer/core/utils/app_logger.dart';
import 'package:freelancer/data/models/notification_model.dart';
import 'package:freelancer/data/repositories/notification_repository.dart';
import 'package:freelancer/services/local_notification_service.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

typedef PresentInAppBanner = void Function(AppNotification notification);

/// Unread count + Supabase realtime for new [AppNotification] rows.
class AppNotificationController extends ChangeNotifier {
  AppNotificationController({
    required NotificationRepository repository,
    required PresentInAppBanner presentInAppBanner,
    required AppLifecycleState Function() appLifecycleState,
  })  : _repository = repository,
        _presentInAppBanner = presentInAppBanner,
        _appLifecycleState = appLifecycleState;

  final NotificationRepository _repository;
  final PresentInAppBanner _presentInAppBanner;
  final AppLifecycleState Function() _appLifecycleState;

  RealtimeChannel? _channel;
  int _unreadCount = 0;
  final Set<String> _presentedIds = <String>{};
  DateTime? _listenStartedAt;
  Timer? _unreadRefreshDebounce;

  int get unreadCount => _unreadCount;

  bool get isListening => _channel != null;

  Future<void> start() async {
    if (_channel != null) return;
    if (Supabase.instance.client.auth.currentSession == null) return;

    try {
      _listenStartedAt = DateTime.now().toUtc();
      _channel = _repository.subscribeToNotifications(
        onChange: scheduleUnreadCountRefresh,
        onInsert: _onInsert,
      );
      await refreshUnreadCount();
    } catch (e, st) {
      AppLogger.error('AppNotificationController.start', e, st);
    }
  }

  void stop() {
    _repository.unsubscribe(_channel);
    _channel = null;
    _listenStartedAt = null;
    _unreadRefreshDebounce?.cancel();
    _presentedIds.clear();
    _unreadCount = 0;
    notifyListeners();
  }

  /// Coalesce rapid realtime events into a single count fetch.
  void scheduleUnreadCountRefresh() {
    _unreadRefreshDebounce?.cancel();
    _unreadRefreshDebounce = Timer(const Duration(milliseconds: 450), () {
      unawaited(refreshUnreadCount());
    });
  }

  Future<void> refreshUnreadCount() async {
    if (Supabase.instance.client.auth.currentSession == null) {
      _unreadCount = 0;
      notifyListeners();
      return;
    }
    try {
      final count = await _repository.getUnreadCount();
      if (_unreadCount != count) {
        _unreadCount = count;
        notifyListeners();
      }
    } catch (e, st) {
      AppLogger.error('AppNotificationController.refreshUnreadCount', e, st);
    }
  }

  void _onInsert(AppNotification notification) {
    if (_isHistoricalReplay(notification)) {
      scheduleUnreadCountRefresh();
      return;
    }

    if (_presentedIds.contains(notification.id)) return;
    _presentedIds.add(notification.id);
    if (_presentedIds.length > 200) {
      _presentedIds.remove(_presentedIds.first);
    }

    scheduleUnreadCountRefresh();

    final lifecycle = _appLifecycleState();
    if (lifecycle == AppLifecycleState.resumed) {
      _presentInAppBanner(notification);
    } else {
      LocalNotificationService.instance.show(notification);
    }
  }

  bool _isHistoricalReplay(AppNotification notification) {
    final since = _listenStartedAt;
    if (since == null) return false;
    final created = notification.createdAt.toUtc();
    return created.isBefore(since.subtract(const Duration(seconds: 15)));
  }

  @override
  void dispose() {
    _unreadRefreshDebounce?.cancel();
    stop();
    super.dispose();
  }
}
