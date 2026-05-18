import 'package:freelancer/data/models/attendance_punch_model.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class AttendanceService {
  static final _client = Supabase.instance.client;

  static const String qrSchemePrefix = 'hupworks://attendance/';

  /// Extract token from scanned QR payload.
  static String? parseTokenFromPayload(String raw) {
    final trimmed = raw.trim();
    if (trimmed.startsWith(qrSchemePrefix)) {
      return trimmed.substring(qrSchemePrefix.length);
    }
    final uri = Uri.tryParse(trimmed);
    if (uri != null &&
        uri.scheme == 'hupworks' &&
        uri.host == 'attendance' &&
        uri.pathSegments.isNotEmpty) {
      return uri.pathSegments.first;
    }
    if (trimmed.length >= 16 && !trimmed.contains(' ')) {
      return trimmed;
    }
    return null;
  }

  static Future<AttendanceTokenResult> generateJobAttendanceToken(
    String jobPostId,
  ) async {
    final data = await _client.rpc(
      'generate_job_attendance_token',
      params: {'p_job_post_id': jobPostId},
    );
    return AttendanceTokenResult.fromJson(
      Map<String, dynamic>.from(data as Map),
    );
  }

  static Future<AttendanceTokenResult> getJobAttendanceToken(
    String jobPostId,
  ) async {
    final data = await _client.rpc(
      'get_job_attendance_token',
      params: {'p_job_post_id': jobPostId},
    );
    return AttendanceTokenResult.fromJson(
      Map<String, dynamic>.from(data as Map),
    );
  }

  static Future<AttendanceResolveResult> resolveAttendanceToken(
    String token,
  ) async {
    final data = await _client.rpc(
      'resolve_attendance_token',
      params: {'p_token': token},
    );
    return AttendanceResolveResult.fromJson(
      Map<String, dynamic>.from(data as Map),
    );
  }

  static Future<AttendancePunchRecordResult> recordAttendancePunch({
    required String token,
    required String punchType,
    double? latitude,
    double? longitude,
  }) async {
    final data = await _client.rpc(
      'record_attendance_punch',
      params: {
        'p_token': token,
        'p_punch_type': punchType,
        'p_latitude': latitude,
        'p_longitude': longitude,
      },
    );
    return AttendancePunchRecordResult.fromJson(
      Map<String, dynamic>.from(data as Map),
    );
  }

  /// Punches for a job post (client view), newest first.
  static Future<List<Map<String, dynamic>>> getPunchesForJobPost(
    String jobPostId, {
    DateTime? day,
  }) async {
    var query = _client
        .from('attendance_punches')
        .select(
          'id, punch_type, punched_at, seller_id, '
          'profiles:seller_id(name)',
        )
        .eq('job_post_id', jobPostId);

    if (day != null) {
      final start = DateTime(day.year, day.month, day.day);
      final end = start.add(const Duration(days: 1));
      query = query
          .gte('punched_at', start.toUtc().toIso8601String())
          .lt('punched_at', end.toUtc().toIso8601String());
    }

    final rows = await query.order('punched_at', ascending: false);
    return List<Map<String, dynamic>>.from(rows as List);
  }

  /// Punches for seller on a job (history).
  static Future<List<AttendancePunchSummary>> getMyPunchesForJob(
    String jobPostId,
  ) async {
    final uid = _client.auth.currentUser?.id;
    if (uid == null) return [];

    final rows = await _client
        .from('attendance_punches')
        .select('id, punch_type, punched_at')
        .eq('job_post_id', jobPostId)
        .eq('seller_id', uid)
        .order('punched_at', ascending: false)
        .limit(50);

    return (rows as List)
        .map((e) => AttendancePunchSummary.fromJson(
              Map<String, dynamic>.from(e as Map),
            ))
        .toList();
  }

  static bool isOnsiteJob(Map<String, dynamic>? jobPost) {
    final type = (jobPost?['location_type'] as String?)?.trim();
    return type == 'On-site';
  }

  static bool jobHasAcceptedHire(List<Map<String, dynamic>> offers) {
    return offers.any(
      (o) => (o['status'] as String?)?.toLowerCase() == 'accepted',
    );
  }
}
