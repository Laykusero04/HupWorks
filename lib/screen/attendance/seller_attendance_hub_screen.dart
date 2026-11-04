import 'package:flutter/material.dart';
import 'package:freelancer/core/widgets/empty_state_widget.dart';
import 'package:freelancer/core/widgets/rubik_refresh_indicator.dart';
import 'package:freelancer/core/widgets/loading_widget.dart';
import 'package:freelancer/l10n/l10n.dart';
import 'package:freelancer/services/attendance_service.dart';
import 'package:go_router/go_router.dart';

import 'attendance_actions_card.dart';
import '../widgets/button_global.dart';
import '../widgets/constant.dart';

class SellerAttendanceHubScreen extends StatefulWidget {
  final String? highlightJobPostId;

  const SellerAttendanceHubScreen({super.key, this.highlightJobPostId});

  @override
  State<SellerAttendanceHubScreen> createState() =>
      _SellerAttendanceHubScreenState();
}

class _SellerAttendanceHubScreenState extends State<SellerAttendanceHubScreen> {
  List<OnsiteAttendanceJob> _jobs = [];
  bool _loading = true;
  bool _loadFailed = false;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _loadFailed = false;
    });
    try {
      final jobs = await AttendanceService.getMyOnsiteAttendanceJobs();
      if (mounted) {
        setState(() {
          _jobs = jobs;
          _loading = false;
          _loadFailed = false;
        });
      }
    } catch (_) {
      if (mounted) {
        setState(() {
          _loading = false;
          _loadFailed = true;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final primary = Theme.of(context).colorScheme.primary;
    return Scaffold(
      backgroundColor: kDarkWhite,
      appBar: AppBar(
        backgroundColor: kDarkWhite,
        elevation: 0,
        iconTheme: const IconThemeData(color: kNeutralColor),
        title: Text(
          l10n.attendance,
          style: kTextStyle.copyWith(
            color: kNeutralColor,
            fontWeight: FontWeight.bold,
          ),
        ),
        centerTitle: true,
        actions: [
          IconButton(
            icon: Icon(Icons.qr_code_scanner, color: primary),
            tooltip: l10n.scanAttendanceQr,
            onPressed: () => context.push('/seller/attendance/scan'),
          ),
        ],
      ),
      body: _loading
          ? const LoadingWidget()
          : _loadFailed
              ? EmptyStateWidget(
                  message: l10n.somethingWentWrong,
                  actionLabel: l10n.retry,
                  onAction: () {
                    _load();
                  },
                )
              : RubikRefreshIndicator(
              onRefresh: _load,
              child: _jobs.isEmpty
                  ? ListView(
                      physics: const AlwaysScrollableScrollPhysics(),
                      padding: const EdgeInsets.all(24),
                      children: [
                        _emptyState(),
                      ],
                    )
                  : ListView.builder(
                      physics: const AlwaysScrollableScrollPhysics(
                        parent: BouncingScrollPhysics(),
                      ),
                      padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
                      itemCount: _jobs.length,
                      itemBuilder: (_, i) {
                        final job = _jobs[i];
                        final highlighted = widget.highlightJobPostId != null &&
                            widget.highlightJobPostId == job.jobPostId;
                        return Padding(
                          padding: const EdgeInsets.only(bottom: 14),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              if (highlighted)
                                Padding(
                                  padding: const EdgeInsets.only(bottom: 8),
                                  child: Text(
                                    l10n.selectedJob,
                                    style: kTextStyle.copyWith(
                                      color: primary,
                                      fontWeight: FontWeight.w600,
                                      fontSize: 12,
                                    ),
                                  ),
                                ),
                              Text(
                                job.title,
                                style: kTextStyle.copyWith(
                                  color: kNeutralColor,
                                  fontWeight: FontWeight.bold,
                                  fontSize: 16,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                job.clientName,
                                style: kTextStyle.copyWith(
                                  color: kSubTitleColor,
                                  fontSize: 13,
                                ),
                              ),
                              const SizedBox(height: 10),
                              AttendanceActionsCard(
                                orderId: job.orderId,
                                jobPostId: job.jobPostId,
                                attendanceMode: job.attendanceMode,
                                isClockedIn: job.isClockedIn,
                                checkedInToday: job.checkedInToday,
                                statusLabel: job.statusLabel,
                                onChanged: _load,
                                compact: true,
                              ),
                              const SizedBox(height: 8),
                              TextButton(
                                onPressed: () => context.push(
                                  '/seller/orders/${job.orderId}',
                                ),
                                child: Text(
                                  l10n.openContract,
                                  style: kTextStyle.copyWith(
                                    color: primary,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        );
                      },
                    ),
            ),
    );
  }

  Widget _emptyState() {
    final l10n = context.l10n;
    final primary = Theme.of(context).colorScheme.primary;
    return Column(
      children: [
        const SizedBox(height: 40),
        Icon(
          Icons.qr_code_scanner_outlined,
          size: 64,
          color: kLightNeutralColor,
        ),
        const SizedBox(height: 16),
        Text(
          l10n.noOnsiteJobsYet,
          textAlign: TextAlign.center,
          style: kTextStyle.copyWith(
            color: kNeutralColor,
            fontWeight: FontWeight.bold,
            fontSize: 18,
          ),
        ),
        const SizedBox(height: 10),
        Text(
          l10n.noOnsiteJobsBody,
          textAlign: TextAlign.center,
          style: kTextStyle.copyWith(color: kSubTitleColor, height: 1.4),
        ),
        const SizedBox(height: 24),
        ButtonGlobalWithoutIcon(
          buttontext: l10n.findOnsiteJobs,
          buttonDecoration: kButtonDecoration.copyWith(color: primary),
          onPressed: () => context.go('/seller/find-jobs'),
          buttonTextColor: kWhite,
        ),
      ],
    );
  }
}
