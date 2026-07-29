import 'package:supabase_flutter/supabase_flutter.dart';

class ReportService {
  static final _client = Supabase.instance.client;

  /// Creates a marketplace report. [reportedUserId] is optional when only a URL is known.
  static Future<void> createReport({
    String? reportedUserId,
    required String reason,
    String? details,
    String? profileUrl,
    String? contentUrl,
  }) async {
    final user = _client.auth.currentUser;
    if (user == null) throw Exception('Not logged in');

    final trimmedReason = reason.trim();
    if (trimmedReason.isEmpty) {
      throw Exception('Please select a reason');
    }

    final reported = reportedUserId?.trim();
    if (reported != null && reported.isNotEmpty && reported == user.id) {
      throw Exception('You cannot report yourself');
    }

    await _client.from('user_reports').insert({
      'reporter_id': user.id,
      'reported_user_id': (reported == null || reported.isEmpty) ? null : reported,
      'reason': trimmedReason,
      'details': _nullIfEmpty(details),
      'profile_url': _nullIfEmpty(profileUrl),
      'content_url': _nullIfEmpty(contentUrl),
      'status': 'open',
    });
  }

  static String? _nullIfEmpty(String? value) {
    final t = value?.trim();
    if (t == null || t.isEmpty) return null;
    return t;
  }
}
