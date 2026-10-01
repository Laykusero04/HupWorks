import 'package:freelancer/core/chat/chat_contact_policy.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

/// Reads and enforces [profiles.chat_contact_policy].
class ChatPrivacyService {
  static final _client = Supabase.instance.client;

  /// Refuses a brand-new conversation when the recipient's filter says no.
  /// Missing the database function (migration not applied yet) does not block chat.
  static Future<void> assertCanStartChat(String recipientId) async {
    final user = _client.auth.currentUser;
    if (user == null) throw Exception('Not authenticated');
    final recipient = recipientId.trim();
    if (recipient.isEmpty || recipient == user.id) {
      throw Exception('User required');
    }

    Object? raw;
    try {
      raw = await _client.rpc(
        'chat_contact_decision',
        params: {'p_recipient': recipient},
      );
    } catch (e) {
      final text = '$e';
      if (text.contains('chat_contact_decision') &&
          (text.contains('does not exist') ||
              text.contains('Could not find the function') ||
              text.contains('PGRST202'))) {
        return;
      }
      rethrow;
    }

    final map = raw is Map ? Map<String, dynamic>.from(raw) : <String, dynamic>{};
    if (map['allowed'] == true) return;

    final reason = (map['reason'] as String?)?.trim() ?? 'denied';
    if (reason == 'blocked') {
      throw Exception('Contact blocked');
    }
    throw ChatPrivacyException(reason);
  }
}
