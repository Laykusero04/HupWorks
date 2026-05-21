import 'package:flutter/material.dart';
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

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() => _loading = true);
    try {
      final jobs = await AttendanceService.getMyOnsiteAttendanceJobs();
      if (mounted) {
        setState(() {
          _jobs = jobs;
          _loading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() => _loading = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: kDarkWhite,
      appBar: AppBar(
        backgroundColor: kDarkWhite,
        elevation: 0,
        iconTheme: const IconThemeData(color: kNeutralColor),
        title: Text(
          'Attendance',
          style: kTextStyle.copyWith(
            color: kNeutralColor,
            fontWeight: FontWeight.bold,
          ),
        ),
        centerTitle: true,
        actions: [
          IconButton(
            icon: const Icon(Icons.qr_code_scanner, color: Color(0xFF2E7D32)),
            tooltip: 'Scan QR',
            onPressed: () => context.push('/seller/attendance/scan'),
          ),
        ],
      ),
      body: _loading
          ? const Center(
              child: CircularProgressIndicator(color: kPrimaryColor),
            )
          : RefreshIndicator(
              color: kPrimaryColor,
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
                                    'Selected job',
                                    style: kTextStyle.copyWith(
                                      color: kPrimaryColor,
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
                                  'Open contract',
                                  style: kTextStyle.copyWith(
                                    color: kPrimaryColor,
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
          'No on-site jobs yet',
          textAlign: TextAlign.center,
          style: kTextStyle.copyWith(
            color: kNeutralColor,
            fontWeight: FontWeight.bold,
            fontSize: 18,
          ),
        ),
        const SizedBox(height: 10),
        Text(
          'You need an accepted on-site contract. Your client chooses how attendance works (QR scan or self-report) when they post the job.',
          textAlign: TextAlign.center,
          style: kTextStyle.copyWith(color: kSubTitleColor, height: 1.4),
        ),
        const SizedBox(height: 24),
        ButtonGlobalWithoutIcon(
          buttontext: 'Find on-site jobs',
          buttonDecoration: kButtonDecoration.copyWith(color: kPrimaryColor),
          onPressed: () => context.go('/seller/find-jobs'),
          buttonTextColor: kWhite,
        ),
      ],
    );
  }
}
