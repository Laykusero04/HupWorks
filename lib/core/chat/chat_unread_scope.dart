import 'dart:async';

import 'package:flutter/material.dart';
import 'package:freelancer/core/chat/chat_unread_controller.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

/// App-wide unread chat badge state (Messages tab + conversation list).
class ChatUnreadScope extends StatefulWidget {
  const ChatUnreadScope({super.key, required this.child});

  final Widget child;

  static ChatUnreadController of(BuildContext context) {
    final scope =
        context.dependOnInheritedWidgetOfExactType<_InheritedChatUnreadScope>();
    assert(scope != null, 'ChatUnreadScope not found above context');
    return scope!.controller;
  }

  /// Refresh counts without requiring an InheritedWidget lookup.
  static void refreshGlobal() {
    _ChatUnreadScopeState._activeController?.scheduleRefresh();
  }

  @override
  State<ChatUnreadScope> createState() => _ChatUnreadScopeState();
}

class _ChatUnreadScopeState extends State<ChatUnreadScope>
    with WidgetsBindingObserver {
  ChatUnreadController? _controller;
  StreamSubscription<AuthState>? _authSub;
  bool _listeningStarted = false;

  static ChatUnreadController? _activeController;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _authSub =
        Supabase.instance.client.auth.onAuthStateChange.listen(_onAuthState);
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _controller ??= ChatUnreadController();
    _activeController = _controller;
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
    if (state == AppLifecycleState.resumed) {
      unawaited(_controller?.refresh());
    }
  }

  void _onAuthState(AuthState state) {
    if (state.session == null) {
      _listeningStarted = false;
      _controller?.stop();
    } else {
      _ensureListening();
      unawaited(_controller?.refresh());
    }
  }

  @override
  void dispose() {
    _authSub?.cancel();
    WidgetsBinding.instance.removeObserver(this);
    if (_activeController == _controller) {
      _activeController = null;
    }
    _controller?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final controller = _controller;
    if (controller == null) return widget.child;
    return _InheritedChatUnreadScope(
      controller: controller,
      child: widget.child,
    );
  }
}

class _InheritedChatUnreadScope
    extends InheritedNotifier<ChatUnreadController> {
  _InheritedChatUnreadScope({
    required ChatUnreadController controller,
    required super.child,
  }) : super(notifier: controller);

  ChatUnreadController get controller => notifier!;
}
