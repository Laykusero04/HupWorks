import 'package:equatable/equatable.dart';

class WorkTrustHighlight extends Equatable {
  const WorkTrustHighlight({
    required this.jobTitle,
    required this.completedMonth,
    required this.hadAttendance,
    this.categoryName,
  });

  final String jobTitle;
  /// ISO year-month from server (`YYYY-MM`).
  final String completedMonth;
  final bool hadAttendance;
  final String? categoryName;

  factory WorkTrustHighlight.fromJson(Map<String, dynamic> json) {
    return WorkTrustHighlight(
      jobTitle: (json['job_title'] as String?)?.trim() ?? 'On-site job',
      completedMonth: (json['completed_month'] as String?)?.trim() ?? '',
      hadAttendance: (json['had_attendance'] as bool?) ?? false,
      categoryName: (json['category_name'] as String?)?.trim(),
    );
  }

  @override
  List<Object?> get props => [jobTitle, completedMonth, hadAttendance, categoryName];
}

class SellerWorkTrust extends Equatable {
  const SellerWorkTrust({
    this.completedOnsiteJobs = 0,
    this.verifiedCheckins = 0,
    this.verifiedShiftDays = 0,
    this.jobsWithAttendance = 0,
    this.highlights = const [],
  });

  static const empty = SellerWorkTrust();

  final int completedOnsiteJobs;
  final int verifiedCheckins;
  final int verifiedShiftDays;
  final int jobsWithAttendance;
  final List<WorkTrustHighlight> highlights;

  bool get shouldShowSection =>
      completedOnsiteJobs > 0 || verifiedCheckins > 0;

  factory SellerWorkTrust.fromJson(Map<String, dynamic> json) {
    final rawHighlights = json['highlights'];
    final highlights = rawHighlights is List
        ? rawHighlights
            .whereType<Map>()
            .map((e) => WorkTrustHighlight.fromJson(Map<String, dynamic>.from(e)))
            .toList()
        : <WorkTrustHighlight>[];

    return SellerWorkTrust(
      completedOnsiteJobs: (json['completed_onsite_jobs'] as num?)?.toInt() ?? 0,
      verifiedCheckins: (json['verified_checkins'] as num?)?.toInt() ?? 0,
      verifiedShiftDays: (json['verified_shift_days'] as num?)?.toInt() ?? 0,
      jobsWithAttendance: (json['jobs_with_attendance'] as num?)?.toInt() ?? 0,
      highlights: highlights,
    );
  }

  @override
  List<Object?> get props => [
        completedOnsiteJobs,
        verifiedCheckins,
        verifiedShiftDays,
        jobsWithAttendance,
        highlights,
      ];
}
