import 'package:flutter/material.dart';
import 'package:freelancer/screen/attendance/attendance_punch_log_section.dart';

import 'constant.dart';

/// Client-facing today attendance log (time in / out cells).
class ClientAttendanceTodayCard extends StatelessWidget {
  final String jobPostId;

  const ClientAttendanceTodayCard({super.key, required this.jobPostId});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: kPrimaryColor.withValues(alpha: 0.05),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: kBorderColorTextField),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Today',
            style: kTextStyle.copyWith(
              color: kNeutralColor,
              fontWeight: FontWeight.w700,
              fontSize: 13,
            ),
          ),
          const SizedBox(height: 8),
          AttendancePunchLogSection(
            jobPostId: jobPostId,
            showSellerName: true,
          ),
        ],
      ),
    );
  }
}
