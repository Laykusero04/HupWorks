import 'package:freelancer/core/charity/charity_cause.dart';
import 'package:freelancer/services/profile_service.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class CharityCauseService {
  static final _client = Supabase.instance.client;

  /// Saved cause for the signed-in profile, or null when none is chosen.
  /// Returns null if the column is not migrated yet.
  static Future<String?> getMine() async {
    final user = _client.auth.currentUser;
    if (user == null) return null;

    try {
      final row = await _client
          .from('profiles')
          .select('charity_cause')
          .eq('id', user.id)
          .maybeSingle();
      return CharityCause.normalize(row?['charity_cause'] as String?);
    } catch (_) {
      return null;
    }
  }

  static Future<void> save(String? cause) async {
    final user = _client.auth.currentUser;
    if (user == null) throw Exception('Not logged in');

    final value = CharityCause.normalize(cause);
    try {
      await ProfileService.updateProfile({'charity_cause': value});
    } catch (e) {
      final msg = e.toString();
      if (msg.contains('charity_cause') &&
          (msg.contains('schema cache') ||
              msg.contains('column') ||
              msg.contains('PGRST'))) {
        throw Exception(
          'Cause choice is not available yet. Open the SQL Editor and run '
          'migrations/0050_charity_cause.sql, then try again.',
        );
      }
      rethrow;
    }
  }
}
