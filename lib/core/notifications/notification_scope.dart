import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:freelancer/core/notification_navigation.dart';
import 'package:freelancer/core/notifications/app_notification_controller.dart';
import 'package:freelancer/core/notifications/notification_in_app_banner.dart';
import 'package:freelancer/core/notifications/notification_tap_handler.dart';
import 'package:freelancer/data/models/notification_model.dart';
import 'package:freelancer/data/repositories/notification_repository.dart';
import 'package:freelancer/router/app_router.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

/// App-wide notification realtime, badge state, and in-app banner host.
class NotificationScope extends StatefulWidget {
  const NotificationScope({super.key, required this.child});

  final Widget child;

  static AppNotificationController of(BuildContext context) {
    final scope = context.dependOnInheritedWidgetOfExactType<_InheritedNotificationScope>();
    assert(scope != null, 'NotificationScope not found above context');
    return scope!.controller;
  }

  @override
  State<NotificationScope> createState() => _NotificationScopeState();
}

class _NotificationScopeState extends State<NotificationScope> with WidgetsBindingObserver {
  AppNotificationController? _controller;
  StreamSubscription<AuthState>? _authSub;
  OverlayEntry? _bannerEntry;
  AppLifecycleState _lifecycle = AppLifecycleState.resumed;
  bool _listeningStarted = false;
  final List<AppNotification> _bannerQueue = <AppNotification>[];
  bool _bannerVisible = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _authSub = Supabase.instance.client.auth.onAuthStateChange.listen(_onAuthState);
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _controller ??= AppNotificationController(
      repository: context.read<NotificationRepository>(),
      presentInAppBanner: _showInAppBanner,
      appLifecycleState: () => _lifecycle,
    );
    _ensureListening();
  }

  void _ensureListening() {
    if (_listeningStarted || _controller == null) return;
    if (Supabase.instance.client.auth.currentSession == null) return;
    _listeningStarted = true;
    unawaited(_controller!.start());
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    _lifecycle = state;
    if (state == AppLifecycleState.resumed) {
      unawaited(_controller?.refreshUnreadCount());
    }
  }

  void _onAuthState(AuthState state) {
    if (state.session == null) {
      _listeningStarted = false;
      _bannerQueue.clear();
      _onBannerDismissed();
      _controller?.stop();
    } else {
      _ensureListening();
    }
  }

  void _enqueueInAppBanner(AppNotification notification) {
    if (_bannerVisible) {
      if (_bannerQueue.length >= 8) {
        _bannerQueue.removeAt(0);
      }
      _bannerQueue.add(notification);
      return;
    }
    _displayBanner(notification);
  }

  void _displayBanner(AppNotification notification) {
    final overlay = rootNavigatorKey.currentState?.overlay;
    if (overlay == null) return;

    _bannerVisible = true;
    _bannerEntry = OverlayEntry(
      builder: (context) => NotificationInAppBanner(
        notification: notification,
        onDismiss: _onBannerDismissed,
        onTap: () => _onBannerTap(notification),
      ),
    );
    overlay.insert(_bannerEntry!);
  }

  void _onBannerDismissed() {
    _bannerEntry?.remove();
    _bannerEntry = null;
    _bannerVisible = false;
    if (_bannerQueue.isNotEmpty) {
      final next = _bannerQueue.removeAt(0);
      _displayBanner(next);
    }
  }

  void _showInAppBanner(AppNotification notification) {
    _enqueueInAppBanner(notification);
  }

  Future<void> _onBannerTap(AppNotification notification) async {
    final navContext = rootNavigatorKey.currentContext;
    if (navContext == null) return;

    await markNotificationReadIfNeeded(
      context.read<NotificationRepository>(),
      notification.id,
    );
    await _controller?.refreshUnreadCount();

    if (!navContext.mounted) return;
    await NotificationNavigation.open(
      navContext,
      role: notificationRoleFromAuth(),
      notification: notification,
    );
  }

  @override
  void dispose() {
    _authSub?.cancel();
    WidgetsBinding.instance.removeObserver(this);
    _bannerQueue.clear();
    _bannerEntry?.remove();
    _bannerEntry = null;
    _controller?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final controller = _controller;
    if (controller == null) return widget.child;
    return _InheritedNotificationScope(
      controller: controller,
      child: widget.child,
    );
  }
}

class _InheritedNotificationScope extends InheritedNotifier<AppNotificationController> {
  _InheritedNotificationScope({
    required AppNotificationController controller,
    required super.child,
  }) : super(notifier: controller);

  AppNotificationController get controller => notifier!;
}
