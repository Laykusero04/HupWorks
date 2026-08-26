import 'package:flutter/material.dart';

import '../../widgets/report_user_screen.dart';

/// Client report entry — prefers context from chat, job, or contract.
class ClientReport extends StatelessWidget {
  const ClientReport({
    Key? key,
    this.reportedUserId,
    this.reportedUserName,
    this.jobPostId,
    this.jobTitle,
    this.orderId,
    @Deprecated('URLs are no longer collected; ignored') this.initialProfileUrl,
  }) : super(key: key);

  final String? reportedUserId;
  final String? reportedUserName;
  final String? jobPostId;
  final String? jobTitle;
  final String? orderId;
  final String? initialProfileUrl;

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
