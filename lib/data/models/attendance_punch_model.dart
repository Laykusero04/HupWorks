import 'package:equatable/equatable.dart';

class AttendancePunchSummary extends Equatable {
  final String id;
  final String punchType;
  final DateTime punchedAt;
  final String? sellerId;
  final String? sellerName;

  const AttendancePunchSummary({
    required this.id,
    required this.punchType,
    required this.punchedAt,
    this.sellerId,
    this.sellerName,
  });

  factory AttendancePunchSummary.fromJson(Map<String, dynamic> json) {
    return AttendancePunchSummary(
      id: json['id'] as String,
      punchType: json['punch_type'] as String,
      punchedAt: DateTime.parse(json['punched_at'] as String),
      sellerId: json['seller_id'] as String?,
      sellerName: json['seller_name'] as String?,
    );
  }

  bool get isClockIn => punchType == 'in';

  @override
  List<Object?> get props => [id, punchType, punchedAt, sellerId, sellerName];
}

class AttendanceTokenResult extends Equatable {
  final String? token;
  final String? qrPayload;
  final String jobPostId;

  const AttendanceTokenResult({
    this.token,
    this.qrPayload,
    required this.jobPostId,
  });

  factory AttendanceTokenResult.fromJson(Map<String, dynamic> json) {
    return AttendanceTokenResult(
      token: json['token'] as String?,
      qrPayload: json['qr_payload'] as String?,
      jobPostId: json['job_post_id'] as String,
    );
  }

  bool get hasToken => token != null && token!.isNotEmpty;

  @override
  List<Object?> get props => [token, qrPayload, jobPostId];
}

class AttendanceResolveResult extends Equatable {
  final String jobPostId;
  final String orderId;
  final String title;
  final String? location;
  final String? locationType;
  final double? latitude;
  final double? longitude;
  final String clientName;
  final String attendanceMode;
  final String suggestedAction;
  final bool isClockedIn;
  final bool checkedInToday;
  final String? lastPunchType;
  final DateTime? lastPunchedAt;
  final List<AttendancePunchSummary> todayPunches;

  const AttendanceResolveResult({
    required this.jobPostId,
    required this.orderId,
    required this.title,
    this.location,
    this.locationType,
    this.latitude,
    this.longitude,
    required this.clientName,
    this.attendanceMode = 'qr_in_out',
    required this.suggestedAction,
    required this.isClockedIn,
    this.checkedInToday = false,
    this.lastPunchType,
    this.lastPunchedAt,
    this.todayPunches = const [],
  });

  factory AttendanceResolveResult.fromJson(Map<String, dynamic> json) {
    final rawPunches = json['today_punches'];
    final List<AttendancePunchSummary> punches;
    if (rawPunches is List) {
      punches = rawPunches
          .whereType<Map<String, dynamic>>()
          .map(AttendancePunchSummary.fromJson)
          .toList();
    } else {
      punches = const [];
    }

    return AttendanceResolveResult(
      jobPostId: json['job_post_id'] as String,
      orderId: json['order_id'] as String,
      title: json['title'] as String? ?? 'Job',
      location: json['location'] as String?,
      locationType: json['location_type'] as String?,
      latitude: (json['latitude'] as num?)?.toDouble(),
      longitude: (json['longitude'] as num?)?.toDouble(),
      clientName: json['client_name'] as String? ?? 'Client',
      attendanceMode: json['attendance_mode'] as String? ?? 'qr_in_out',
      suggestedAction: json['suggested_action'] as String? ?? 'in',
      checkedInToday: (json['checked_in_today'] as bool?) ?? false,
      isClockedIn: (json['is_clocked_in'] as bool?) ?? false,
      lastPunchType: json['last_punch_type'] as String?,
      lastPunchedAt: json['last_punched_at'] != null
          ? DateTime.tryParse(json['last_punched_at'] as String)
          : null,
      todayPunches: punches,
    );
  }

  bool get suggestClockIn => suggestedAction == 'in';

  @override
  List<Object?> get props => [
        jobPostId,
        orderId,
        title,
        location,
        locationType,
        latitude,
        longitude,
        clientName,
        attendanceMode,
        suggestedAction,
        checkedInToday,
        isClockedIn,
        lastPunchType,
        lastPunchedAt,
        todayPunches,
      ];
}

class AttendancePunchRecordResult extends Equatable {
  final bool success;
  final String punchId;
  final String punchType;
  final DateTime punchedAt;
  final bool isClockedIn;
  final double minutesWorkedToday;
  final String jobPostId;
  final String orderId;
  final String? hourReportId;

  const AttendancePunchRecordResult({
    required this.success,
    required this.punchId,
    required this.punchType,
    required this.punchedAt,
    required this.isClockedIn,
    required this.minutesWorkedToday,
    required this.jobPostId,
    required this.orderId,
    this.hourReportId,
  });

  factory AttendancePunchRecordResult.fromJson(Map<String, dynamic> json) {
    return AttendancePunchRecordResult(
      success: (json['success'] as bool?) ?? true,
      punchId: json['punch_id'] as String,
      punchType: json['punch_type'] as String,
      punchedAt: DateTime.parse(json['punched_at'] as String),
      isClockedIn: (json['is_clocked_in'] as bool?) ?? false,
      minutesWorkedToday:
          (json['minutes_worked_today'] as num?)?.toDouble() ?? 0,
      jobPostId: json['job_post_id'] as String,
      orderId: json['order_id'] as String,
      hourReportId: json['hour_report_id'] as String?,
    );
  }

  @override
  List<Object?> get props => [
        success,
        punchId,
        punchType,
        punchedAt,
        isClockedIn,
        minutesWorkedToday,
        jobPostId,
        orderId,
        hourReportId,
      ];
}
