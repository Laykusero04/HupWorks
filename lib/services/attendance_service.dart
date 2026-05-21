import 'package:freelancer/core/utils/attendance_mode.dart';
import 'package:freelancer/data/models/attendance_punch_model.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

/// Active on-site contract row for the attendance hub.
class OnsiteAttendanceJob {
  final String orderId;
  final String jobPostId;
  final String title;
  final String clientName;
  final String orderStatus;
  final String attendanceMode;
  final bool isClockedIn;
  final bool checkedInToday;
  final String? lastPunchType;
  final DateTime? lastPunchedAt;

  const OnsiteAttendanceJob({
    required this.orderId,
    required this.jobPostId,
    required this.title,
    required this.clientName,
    required this.orderStatus,
    required this.attendanceMode,
    required this.isClockedIn,
    required this.checkedInToday,
    this.lastPunchType,
    this.lastPunchedAt,
  });

  bool get attendanceEnabled => AttendanceMode.isEnabled(attendanceMode);

  String get statusLabel {
    if (!attendanceEnabled) return 'Attendance off';
    if (attendanceMode == AttendanceMode.qrOnce) {
      return checkedInToday ? 'Checked in today' : 'Not checked in yet';
    }
    if (isClockedIn) return 'Clocked in';
    if (checkedInToday) return 'Clocked out';
    return 'Not clocked in';
  }
}

class AttendanceService {
  static final _client = Supabase.instance.client;

  static const String qrSchemePrefix = 'hupworks://attendance/';

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

  static Future<AttendancePunchRecordResult> recordSelfReportPunch({
    required String orderId,
    required String punchType,
    double? latitude,
    double? longitude,
  }) async {
    final data = await _client.rpc(
      'record_self_report_punch',
      params: {
        'p_order_id': orderId,
        'p_punch_type': punchType,
        'p_latitude': latitude,
        'p_longitude': longitude,
      },
    );
    return AttendancePunchRecordResult.fromJson(
      Map<String, dynamic>.from(data as Map),
    );
  }

  static Future<List<OnsiteAttendanceJob>> getMyOnsiteAttendanceJobs() async {
    final uid = _client.auth.currentUser?.id;
    if (uid == null) return [];

    final rows = await _client
        .from('orders')
        .select(
          'id, status, '
          'job_offers!job_offer_id('
          'job_posts(id, title, location_type, attendance_mode, '
          'client:profiles!client_id(name))'
          ')',
        )
        .eq('seller_id', uid)
        .order('created_at', ascending: false);

    final List<OnsiteAttendanceJob> jobs = [];
    for (final row in rows as List) {
      final order = Map<String, dynamic>.from(row as Map);
      final status = ((order['status'] as String?) ?? '').toLowerCase();
      if (status == 'cancelled' ||
          status == 'completed' ||
          status == 'cancellation_requested') {
        continue;
      }

      final jo = order['job_offers'];
      final jobOffer = jo is Map
          ? Map<String, dynamic>.from(jo)
          : (jo is List && jo.isNotEmpty)
              ? Map<String, dynamic>.from(jo.first as Map)
              : null;
      if (jobOffer == null) continue;

      final jpRaw = jobOffer['job_posts'];
      final jobPost = jpRaw is Map
          ? Map<String, dynamic>.from(jpRaw)
          : (jpRaw is List && jpRaw.isNotEmpty)
              ? Map<String, dynamic>.from(jpRaw.first as Map)
              : null;
      if (jobPost == null) continue;
      if (!isOnsiteJob(jobPost)) continue;

      final jobPostId = jobPost['id'] as String;
      final orderId = order['id'] as String;
      final mode = AttendanceMode.effectiveForJobPost(jobPost);

      final last = await _lastPunchForJob(uid, jobPostId);
      final todayIn = await _hasCheckinToday(uid, jobPostId);

      String clientName = 'Client';
      final jpClient = jobPost['client'];
      if (jpClient is Map) {
        clientName = (jpClient['name'] as String?) ?? clientName;
      } else if (jpClient is List && jpClient.isNotEmpty) {
        clientName = ((jpClient.first as Map)['name'] as String?) ?? clientName;
      }

      jobs.add(OnsiteAttendanceJob(
        orderId: orderId,
        jobPostId: jobPostId,
        title: (jobPost['title'] as String?) ?? 'Job',
        clientName: clientName,
        orderStatus: status,
        attendanceMode: mode,
        isClockedIn: last?.punchType == 'in',
        checkedInToday: todayIn,
        lastPunchType: last?.punchType,
        lastPunchedAt: last?.punchedAt,
      ));
    }
    return jobs;
  }

  static Future<AttendancePunchSummary?> _lastPunchForJob(
    String sellerId,
    String jobPostId,
  ) async {
    final row = await _client
        .from('attendance_punches')
        .select('id, punch_type, punched_at')
        .eq('seller_id', sellerId)
        .eq('job_post_id', jobPostId)
        .order('punched_at', ascending: false)
        .limit(1)
        .maybeSingle();
    if (row == null) return null;
    return AttendancePunchSummary.fromJson(Map<String, dynamic>.from(row));
  }

  static Future<bool> _hasCheckinToday(String sellerId, String jobPostId) async {
    final now = DateTime.now().toUtc();
    final start = DateTime.utc(now.year, now.month, now.day);
    final end = start.add(const Duration(days: 1));
    final rows = await _client
        .from('attendance_punches')
        .select('id')
        .eq('seller_id', sellerId)
        .eq('job_post_id', jobPostId)
        .eq('punch_type', 'in')
        .gte('punched_at', start.toIso8601String())
        .lt('punched_at', end.toIso8601String())
        .limit(1);
    return (rows as List).isNotEmpty;
  }

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

  static Future<void> updateJobAttendanceMode(
    String jobPostId,
    String mode,
  ) async {
    await _client.from('job_posts').update({
      'attendance_mode': AttendanceMode.normalize(mode),
    }).eq('id', jobPostId);
  }
}
