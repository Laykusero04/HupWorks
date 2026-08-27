import 'package:equatable/equatable.dart';
import 'package:freelancer/core/utils/attendance_format.dart';
import 'package:freelancer/core/utils/shift_schedule.dart';
import 'package:intl/intl.dart';

class HourReport extends Equatable {
  static const pending = 'pending';
  static const accepted = 'accepted';
  static const declined = 'declined';

  final String id;
  final String orderId;
  final String jobPostId;
  final String sellerId;
  final String clientId;
  final DateTime workDate;
  final double minutes;
  final String status;
  final String? declineReason;
  final String? inPunchId;
  final String? outPunchId;
  final DateTime createdAt;
  final DateTime? decidedAt;
  final String? sellerName;

  const HourReport({
    required this.id,
    required this.orderId,
    required this.jobPostId,
    required this.sellerId,
    required this.clientId,
    required this.workDate,
    required this.minutes,
    required this.status,
    this.declineReason,
    this.inPunchId,
    this.outPunchId,
    required this.createdAt,
    this.decidedAt,
    this.sellerName,
  });

  factory HourReport.fromJson(Map<String, dynamic> json) {
    final seller = json['seller'] ?? json['profiles'];
    String? sellerName;
    if (seller is Map<String, dynamic>) {
      sellerName = seller['name'] as String?;
    }

    final workDate = ShiftSchedule.parseDate(json['work_date']) ??
        DateTime.tryParse(json['work_date']?.toString() ?? '') ??
        DateTime.now();

    return HourReport(
      id: json['id'] as String,
      orderId: json['order_id'] as String,
      jobPostId: json['job_post_id'] as String,
      sellerId: json['seller_id'] as String,
      clientId: json['client_id'] as String,
      workDate: DateTime(workDate.year, workDate.month, workDate.day),
      minutes: (json['minutes'] as num?)?.toDouble() ?? 0,
      status: (json['status'] as String?)?.toLowerCase() ?? pending,
      declineReason: json['decline_reason'] as String?,
      inPunchId: json['in_punch_id'] as String?,
      outPunchId: json['out_punch_id'] as String?,
      createdAt: DateTime.parse(json['created_at'] as String),
      decidedAt: json['decided_at'] != null
          ? DateTime.tryParse(json['decided_at'] as String)
          : null,
      sellerName: sellerName,
    );
  }

  bool get isPending => status == pending;
  bool get isAccepted => status == accepted;
  bool get isDeclined => status == declined;

  String get minutesLabel => AttendanceFormat.minutesLabel(minutes);

  String get workDateLabel => DateFormat('d MMM yyyy').format(workDate);

  String get statusLabel {
    switch (status) {
      case accepted:
        return 'Accepted';
      case declined:
        return 'Declined';
      default:
        return 'Pending review';
    }
  }

  @override
  List<Object?> get props => [
        id,
        orderId,
        jobPostId,
        sellerId,
        clientId,
        workDate,
        minutes,
        status,
        declineReason,
        inPunchId,
        outPunchId,
        createdAt,
        decidedAt,
        sellerName,
      ];
}
