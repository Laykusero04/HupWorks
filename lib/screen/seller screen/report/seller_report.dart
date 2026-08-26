import 'package:flutter/material.dart';

import '../../widgets/report_user_screen.dart';

/// Freelancer report entry — prefers context from chat, job, or contract.
class SellerReport extends StatelessWidget {
  const SellerReport({
    Key? key,
    this.reportedUserId,
    this.reportedUserName,
    this.jobPostId,
    this.jobTitle,
    this.orderId,
    @Deprecated('URLs are no longer collected; ignored') this.initialContentUrl,
  }) : super(key: key);

  final String? reportedUserId;
  final String? reportedUserName;
  final String? jobPostId;
  final String? jobTitle;
  final String? orderId;
  final String? initialContentUrl;

  @override
  Widget build(BuildContext context) {
    return ReportUserScreen(
      reportedUserId: reportedUserId,
      reportedUserName: reportedUserName,
      jobPostId: jobPostId,
      jobTitle: jobTitle,
      orderId: orderId,
    );
  }
}
