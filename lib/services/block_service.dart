import 'package:supabase_flutter/supabase_flutter.dart';

class BlockResult {
  const BlockResult({
    required this.hasOpenObligation,
    required this.openOrderIds,
  });

  final bool hasOpenObligation;
  final List<String> openOrderIds;
}

/// Soft-block helpers. Blocks are directional; contact hide is mutual unless
/// the pair still has an open/unpaid obligation.
class BlockService {
  static final _client = Supabase.instance.client;

  static Future<List<String>> openOrderIdsWith(String otherUserId) async {
    final user = _client.auth.currentUser;
    if (user == null) throw Exception('Not logged in');
    final raw = await _client.rpc(
      'pair_open_order_ids',
      params: {
        'p_user_a': user.id,
        'p_user_b': otherUserId,
      },
    );
    if (raw is! List) return const [];
    return raw.map((e) => '$e').where((e) => e.isNotEmpty).toList();
  }

  static Future<bool> hasOpenObligation(String otherUserId) async {
    final user = _client.auth.currentUser;
    if (user == null) throw Exception('Not logged in');
    final raw = await _client.rpc(
      'pair_has_open_obligation',
      params: {
        'p_user_a': user.id,
        'p_user_b': otherUserId,
      },
    );
    return raw == true;
  }

  static Future<bool> isBlockedWith(String otherUserId) async {
    final user = _client.auth.currentUser;
    if (user == null) throw Exception('Not logged in');
    final raw = await _client.rpc(
      'pair_is_blocked',
      params: {
        'p_user_a': user.id,
        'p_user_b': otherUserId,
      },
    );
    return raw == true;
  }

  /// True when new messages / hire / contact should be refused.
  static Future<bool> isContactBlocked(String otherUserId) async {
    final user = _client.auth.currentUser;
    if (user == null) throw Exception('Not logged in');
    final raw = await _client.rpc(
      'pair_contact_blocked',
      params: {
        'p_user_a': user.id,
        'p_user_b': otherUserId,
      },
    );
    return raw == true;
  }

  static Future<bool> iBlocked(String otherUserId) async {
    final user = _client.auth.currentUser;
    if (user == null) throw Exception('Not logged in');
    final rows = await _client
        .from('user_blocks')
        .select('id')
        .eq('blocker_id', user.id)
        .eq('blocked_id', otherUserId)
        .limit(1);
    return (rows as List).isNotEmpty;
  }

  static Future<BlockResult> blockUser({
    required String blockedUserId,
    String? reason,
  }) async {
    final user = _client.auth.currentUser;
    if (user == null) throw Exception('Not logged in');
    final blocked = blockedUserId.trim();
    if (blocked.isEmpty) throw Exception('User required');
    if (blocked == user.id) throw Exception('You cannot block yourself');

    final raw = await _client.rpc(
      'block_user',
      params: {
        'p_blocked_id': blocked,
        'p_reason': reason?.trim().isEmpty == true ? null : reason?.trim(),
      },
    );

    final map = raw is Map ? Map<String, dynamic>.from(raw) : <String, dynamic>{};
    final idsRaw = map['open_order_ids'];
    final ids = <String>[];
    if (idsRaw is List) {
      for (final e in idsRaw) {
        final s = '$e'.trim();
        if (s.isNotEmpty) ids.add(s);
      }
    }
    return BlockResult(
      hasOpenObligation: map['has_open_obligation'] == true,
      openOrderIds: ids,
    );
  }

  static Future<void> unblockUser(String blockedUserId) async {
    final user = _client.auth.currentUser;
    if (user == null) throw Exception('Not logged in');
    await _client.rpc(
      'unblock_user',
      params: {'p_blocked_id': blockedUserId.trim()},
    );
  }
}
