import 'package:supabase_flutter/supabase_flutter.dart';

class ReportService {
  static final _client = Supabase.instance.client;

  /// Creates a marketplace report.
  /// Prefer [reportedUserId] from chat, job, or contract when available.
  static Future<void> createReport({
    String? reportedUserId,
    required String reason,
    String? details,
    String? jobPostId,
    String? orderId,
  }) async {
    final user = _client.auth.currentUser;
    if (user == null) throw Exception('Not logged in');

    final trimmedReason = reason.trim();
    if (trimmedReason.isEmpty) {
      throw Exception('Please select a reason');
    }

    final trimmedDetails = details?.trim() ?? '';
    if (trimmedDetails.length < 10) {
      throw Exception('Please describe the issue (at least 10 characters)');
    }

    final reported = reportedUserId?.trim();
    if (reported != null && reported.isNotEmpty && reported == user.id) {
      throw Exception('You cannot report yourself');
    }

    await _client.from('user_reports').insert({
      'reporter_id': user.id,
      'reported_user_id': (reported == null || reported.isEmpty) ? null : reported,
      'reason': trimmedReason,
      'details': trimmedDetails,
      'job_post_id': _nullIfEmpty(jobPostId),
      'order_id': _nullIfEmpty(orderId),
      'status': 'open',
    });
  }

  static String? _nullIfEmpty(String? value) {
    final t = value?.trim();
    if (t == null || t.isEmpty) return null;
    return t;
  }
}
