import 'dart:async';

import 'package:flutter/widgets.dart';
import 'package:freelancer/core/utils/app_logger.dart';
import 'package:freelancer/services/chat_service.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

/// Tracks unread chat message counts and refreshes on realtime inserts.
class ChatUnreadController extends ChangeNotifier {
  RealtimeChannel? _channel;
  int _totalUnread = 0;
  Map<String, int> _byConversation = const {};
  Timer? _refreshDebounce;

  int get totalUnread => _totalUnread;

  int unreadForConversation(String conversationId) =>
      _byConversation[conversationId] ?? 0;

  Map<String, int> get unreadByConversation => _byConversation;

  bool get isListening => _channel != null;

  Future<void> start() async {
    if (_channel != null) return;
    if (Supabase.instance.client.auth.currentSession == null) return;

    try {
      _channel = ChatService.subscribeToIncomingMessages(
        onNewMessage: scheduleRefresh,
      );
      await refresh();
    } catch (e, st) {
      AppLogger.error('ChatUnreadController.start', e, st);
    }
  }

  void stop() {
    final channel = _channel;
    _channel = null;
    if (channel != null) {
      unawaited(ChatService.unsubscribe(channel));
    }
    _refreshDebounce?.cancel();
    _totalUnread = 0;
    _byConversation = const {};
    notifyListeners();
  }

  void scheduleRefresh() {
    _refreshDebounce?.cancel();
    _refreshDebounce = Timer(const Duration(milliseconds: 350), () {
      unawaited(refresh());
    });
  }

  Future<void> refresh() async {
    if (Supabase.instance.client.auth.currentSession == null) {
      _totalUnread = 0;
      _byConversation = const {};
      notifyListeners();
      return;
    }
    try {
      final counts = await ChatService.getUnreadCountsByConversation();
      final total = counts.values.fold<int>(0, (sum, n) => sum + n);
      if (_totalUnread != total || !_mapsEqual(_byConversation, counts)) {
        _totalUnread = total;
        _byConversation = counts;
        notifyListeners();
      }
    } catch (e, st) {
      AppLogger.error('ChatUnreadController.refresh', e, st);
    }
  }

  bool _mapsEqual(Map<String, int> a, Map<String, int> b) {
    if (a.length != b.length) return false;
    for (final entry in a.entries) {
      if (b[entry.key] != entry.value) return false;
    }
    return true;
  }

  @override
  void dispose() {
    _refreshDebounce?.cancel();
    stop();
    super.dispose();
  }
}
