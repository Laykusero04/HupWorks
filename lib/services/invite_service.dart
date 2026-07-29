import 'package:supabase_flutter/supabase_flutter.dart';

/// Share-only invite helpers (no referral rewards backend yet).
class InviteService {
  static final _client = Supabase.instance.client;

  /// Stable invite code derived from the signed-in user's id.
  /// Example: `HW-A1B2C3D4`
  static String? inviteCodeForCurrentUser() {
    final id = _client.auth.currentUser?.id;
    if (id == null || id.isEmpty) return null;
    return inviteCodeFromUserId(id);
  }

  static String inviteCodeFromUserId(String userId) {
    final compact = userId.replaceAll('-', '').toUpperCase();
    final short = compact.length >= 8 ? compact.substring(0, 8) : compact.padRight(8, '0');
    return 'HW-$short';
  }

  static String shareMessage(String code) {
    return 'Join me on HupWorks! Use my invite code: $code';
  }
}
