import 'package:flutter/material.dart';
import 'package:freelancer/core/guide/guide_anchor.dart';
import 'package:freelancer/core/guide/guide_host.dart';
import 'package:freelancer/core/guide/guide_info_button.dart';
import 'package:freelancer/core/guide/guide_step.dart';
import 'package:freelancer/core/utils/attendance_mode.dart';
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

class _SellerAttendanceHubScreenState extends State<SellerAttendanceHubScreen>
    with GuideHost<SellerAttendanceHubScreen> {
  List<OnsiteAttendanceJob> _jobs = [];
  bool _loading = true;
  bool _loadFailed = false;

  // Guide targets (long-lived; the card keys sit on the FIRST job only).
  final GlobalKey _guideScanKey = GlobalKey();
  final GlobalKey _guideCardKey = GlobalKey();
  final GlobalKey _guideContractKey = GlobalKey();
  final GlobalKey _guideModeKey = GlobalKey();
  final GlobalKey _guideActionsKey = GlobalKey();
  final GlobalKey _guideTodayKey = GlobalKey();

  @override
  String get guideScreenId => 'seller_attendance_hub';
  @override
  String get guideRole => 'seller';
  @override
  int get guideVersion => 1;

  /// False during every (re)load: a clock in/out reloads the list through
  /// [_load], which swaps it for a spinner. The empty and failed states have
  /// inline copy and only one target, so no guide there.
  @override
  bool get guideDataReady => !_loading && !_loadFailed && _jobs.isNotEmpty;
  @override
  String get guideSkipLabel => context.l10n.guideSkip;
  @override
  String get guideNextLabel => context.l10n.guideNext;
  @override
  String get guideDoneLabel => context.l10n.guideDone;

  /// Whether the first job tracks time at all (otherwise the card shows only
  /// "attendance off" text, which is not a button area to explain).
  bool get _firstJobEnabled =>
      _jobs.isNotEmpty &&
      AttendanceMode.isEnabled(
          AttendanceMode.normalize(_jobs.first.attendanceMode));

  GuideAnchor _anchor(GlobalKey key, String title, String desc,
          {BorderRadius? radius}) =>
      GuideAnchor(
        key: key,
        scope: guideScope,
        title: title,
        description: desc,
        borderRadius: radius,
      );

  @override
  List<GuideStep> buildGuideSteps(BuildContext context) {
    final l10n = context.l10n;
    return [
      GuideStep(
          key: _guideScanKey,
          title: l10n.guideAttHubScanTitle,
          description: l10n.guideAttHubScanDesc),
      GuideStep(
          key: _guideCardKey,
          title: l10n.guideAttHubJobTitle,
          description: l10n.guideAttHubJobDesc),
      GuideStep(
          key: _guideContractKey,
          title: l10n.guideAttHubContractTitle,
          description: l10n.guideAttHubContractDesc,
          enableAutoScroll: true),
    ];
  }

  @override
  List<GuideSection> buildGuideExtraSections(BuildContext context) {
    final l10n = context.l10n;
    return [
      GuideSection(
        id: 'clocking',
        title: l10n.guideAttHubSectionClocking,
        steps: [
          GuideStep(
              key: _guideModeKey,
              title: l10n.guideAttHubModeTitle,
              description: l10n.guideAttHubModeDesc),
          // Absent (not attached) when attendance is off for the first job.
          GuideStep(
              key: _guideActionsKey,
              title: l10n.guideAttHubActionsTitle,
              description: l10n.guideAttHubActionsDesc),
          GuideStep(
              key: _guideTodayKey,
              title: l10n.guideAttHubTodayTitle,
              description: l10n.guideAttHubTodayDesc,
              enableAutoScroll: true),
        ],
      ),
    ];
  }

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
        scheduleGuide();
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
    return guideBackScope(Scaffold(
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
          GuideInfoButton(host: this),
          GuideAnchor.wrap(
            _anchor(_guideScanKey, l10n.guideAttHubScanTitle,
                l10n.guideAttHubScanDesc,
                radius: BorderRadius.circular(24)),
            IconButton(
              icon: Icon(Icons.qr_code_scanner, color: primary),
              tooltip: l10n.scanAttendanceQr,
              onPressed: () => context.push('/seller/attendance/scan'),
            ),
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
                            final highlighted =
                                widget.highlightJobPostId != null &&
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
                                    guideAnchor: i == 0
                                        ? _anchor(
                                            _guideCardKey,
                                            l10n.guideAttHubJobTitle,
                                            l10n.guideAttHubJobDesc,
                                            radius: BorderRadius.circular(10))
                                        : null,
                                    modeAnchor: i == 0
                                        ? _anchor(
                                            _guideModeKey,
                                            l10n.guideAttHubModeTitle,
                                            l10n.guideAttHubModeDesc)
                                        : null,
                                    actionsAnchor: i == 0 && _firstJobEnabled
                                        ? _anchor(
                                            _guideActionsKey,
                                            l10n.guideAttHubActionsTitle,
                                            l10n.guideAttHubActionsDesc,
                                            radius: BorderRadius.circular(8))
                                        : null,
                                    todayAnchor: i == 0
                                        ? _anchor(
                                            _guideTodayKey,
                                            l10n.guideAttHubTodayTitle,
                                            l10n.guideAttHubTodayDesc)
                                        : null,
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
                                  GuideAnchor.wrap(
                                    i == 0
                                        ? _anchor(
                                            _guideContractKey,
                                            l10n.guideAttHubContractTitle,
                                            l10n.guideAttHubContractDesc)
                                        : null,
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
                                  ),
                                ],
                              ),
                            );
                          },
                        ),
                ),
    ));
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
