import 'package:freelancer/core/chat/chat_contact_policy.dart';
import 'package:freelancer/core/guide/guide_anchor.dart';
import 'package:freelancer/core/guide/guide_host.dart';
import 'package:freelancer/core/guide/guide_info_button.dart';
import 'package:freelancer/core/guide/guide_step.dart';
import 'package:freelancer/l10n/l10n.dart';
import 'package:freelancer/core/widgets/empty_state_widget.dart';
import 'package:freelancer/core/widgets/rubik_refresh_indicator.dart';
import 'package:freelancer/core/widgets/loading_widget.dart';
import 'package:flutter/material.dart';
import 'package:freelancer/core/utils/job_offer_delivery.dart';
import 'package:freelancer/core/utils/localized_category.dart';
import 'package:freelancer/core/utils/profile_image.dart';
import 'package:freelancer/screen/client%20screen/client%20talent/freelancer_public_profile.dart';
import 'package:freelancer/screen/seller%20screen/seller%20message/chat_inbox.dart';
import 'package:freelancer/screen/widgets/button_global.dart';
import 'package:freelancer/core/utils/attendance_mode.dart';
import 'package:freelancer/core/utils/app_date_format.dart';
import 'package:freelancer/core/utils/shift_schedule.dart';
import 'package:freelancer/services/attendance_service.dart';
import 'package:freelancer/services/block_service.dart';
import 'package:freelancer/services/chat_service.dart';
import 'package:freelancer/services/hire_onboarding_service.dart';
import 'package:freelancer/services/job_posts_service.dart';
import 'package:nb_utils/nb_utils.dart';

import '../../attendance/attendance_punch_log_section.dart';
import '../../onboarding/hire_onboarding_editor_screen.dart';
import '../../attendance/attendance_qr_display_screen.dart';
import '../../widgets/constant.dart';
import '../../widgets/job_location_map_preview.dart';
import '../../widgets/map_location_picker_screen.dart';

class JobDetails extends StatefulWidget {
  final String jobPostId;

  const JobDetails({Key? key, required this.jobPostId}) : super(key: key);

  @override
  State<JobDetails> createState() => _JobDetailsState();
}

class _JobDetailsState extends State<JobDetails> with GuideHost<JobDetails> {
  Map<String, dynamic>? _jobPost;
  List<Map<String, dynamic>> _offers = [];
  bool _isLoading = true;
  bool _loadFailed = false;
  String _attendanceMode = AttendanceMode.qrInOut;
  bool _savingAttendanceMode = false;
  // True while _loadData runs (initial load, pull-to-refresh, coming back from
  // chat or the instructions editor): the offer list may change, so a running
  // guide is torn down and restarted when the load ends.
  bool _reloading = false;

  // Guide targets (long-lived). The offer keys sit on at most ONE offer each.
  final GlobalKey _guideCardKey = GlobalKey();
  final GlobalKey _guideApplicationsKey = GlobalKey();
  final GlobalKey _guideHireKey = GlobalKey();
  final GlobalKey _guideApplicantKey = GlobalKey();
  final GlobalKey _guideMessageKey = GlobalKey();
  final GlobalKey _guideInstructionsKey = GlobalKey();
  final GlobalKey _guideAttendanceKey = GlobalKey();
  final GlobalKey _guideMethodKey = GlobalKey();
  final GlobalKey _guideQrKey = GlobalKey();
  final GlobalKey _guidePinKey = GlobalKey();
  final GlobalKey _guideTodayKey = GlobalKey();

  static const _sectionApplicants = 'applicants';
  static const _sectionAttendance = 'attendance';

  @override
  String get guideScreenId => 'job_details';

  @override
  String get guideRole => 'client';

  @override
  int get guideVersion => 1;

  @override
  bool get guideDataReady =>
      !_isLoading && !_reloading && !_loadFailed && _jobPost != null;

  @override
  String get guideSkipLabel => context.l10n.guideSkip;

  @override
  String get guideNextLabel => context.l10n.guideNext;

  @override
  String get guideDoneLabel => context.l10n.guideDone;

  bool get _jobIsOpen => (_jobPost?['status'] as String?) == 'open';

  /// Index of the first offer matching [test] (the guide keys go there only).
  int _firstOfferIndex(bool Function(Map<String, dynamic> offer) test) =>
      _offers.indexWhere(test);

  int get _guideAcceptedIndex =>
      _firstOfferIndex((o) => (o['status'] ?? 'pending') == 'accepted');

  int get _guidePendingIndex => _jobIsOpen
      ? _firstOfferIndex((o) => (o['status'] ?? 'pending') == 'pending')
      : -1;

  Widget _guide(
    GlobalKey key,
    String title,
    String description,
    Widget child, {
    double radius = 8,
  }) =>
      GuideAnchor.wrap(
        GuideAnchor(
          key: key,
          scope: guideScope,
          title: title,
          description: description,
          borderRadius: BorderRadius.circular(radius),
        ),
        child,
      );

  /// Wraps [child] as a guide target only when [attach] (the first offer of the
  /// right kind); every other offer stays untouched, so a key is never twice
  /// in the tree.
  Widget _guideIf(
    bool attach,
    GlobalKey key,
    String title,
    String description,
    Widget child, {
    double radius = 8,
  }) =>
      attach ? _guide(key, title, description, child, radius: radius) : child;

  /// Core: job card, applications heading, Hire on the first pending offer.
  /// Targets not rendered (no offers, closed job) are dropped by the runner;
  /// with fewer than 2 the guide just waits and never marks seen.
  @override
  List<GuideStep> buildGuideSteps(BuildContext context) {
    final l10n = context.l10n;
    return [
      GuideStep(
        key: _guideCardKey,
        title: l10n.guideJobDetailsCardTitle,
        description: l10n.guideJobDetailsCardDesc,
      ),
      GuideStep(
        key: _guideApplicationsKey,
        title: l10n.guideJobDetailsApplicationsTitle,
        description: l10n.guideJobDetailsApplicationsDesc,
        enableAutoScroll: true,
      ),
      GuideStep(
        key: _guideHireKey,
        title: l10n.guideJobDetailsHireTitle,
        description: l10n.guideJobDetailsHireDesc,
        enableAutoScroll: true,
      ),
    ];
  }

  @override
  List<GuideSection> buildGuideExtraSections(BuildContext context) {
    final l10n = context.l10n;
    return [
      GuideSection(
        id: _sectionAttendance,
        title: l10n.guideJobDetailsSectionAttendance,
        steps: [
          GuideStep(
            key: _guideAttendanceKey,
            title: l10n.guideJobDetailsAttendanceTitle,
            description: l10n.guideJobDetailsAttendanceDesc,
            enableAutoScroll: true,
          ),
          GuideStep(
            key: _guideMethodKey,
            title: l10n.guideJobDetailsMethodTitle,
            description: l10n.guideJobDetailsMethodDesc,
            enableAutoScroll: true,
          ),
          GuideStep(
            key: _guideQrKey,
            title: l10n.guideJobDetailsQrTitle,
            description: l10n.guideJobDetailsQrDesc,
            enableAutoScroll: true,
          ),
          GuideStep(
            key: _guidePinKey,
            title: l10n.guideJobDetailsPinTitle,
            description: l10n.guideJobDetailsPinDesc,
            enableAutoScroll: true,
          ),
          GuideStep(
            key: _guideTodayKey,
            title: l10n.guideJobDetailsTodayTitle,
            description: l10n.guideJobDetailsTodayDesc,
            enableAutoScroll: true,
          ),
        ],
      ),
      GuideSection(
        id: _sectionApplicants,
        title: l10n.guideJobDetailsSectionApplicants,
        steps: [
          GuideStep(
            key: _guideApplicantKey,
            title: l10n.guideJobDetailsApplicantTitle,
            description: l10n.guideJobDetailsApplicantDesc,
            enableAutoScroll: true,
          ),
          GuideStep(
            key: _guideMessageKey,
            title: l10n.guideJobDetailsMessageTitle,
            description: l10n.guideJobDetailsMessageDesc,
            enableAutoScroll: true,
          ),
          GuideStep(
            key: _guideInstructionsKey,
            title: l10n.guideJobDetailsInstructionsTitle,
            description: l10n.guideJobDetailsInstructionsDesc,
            enableAutoScroll: true,
          ),
        ],
      ),
    ];
  }

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    // Initial load: _isLoading already covers it (no rebuild needed).
    if (!_isLoading && mounted) setState(() => _reloading = true);
    try {
      final results = await Future.wait([
        JobPostsService.getJobPostDetails(widget.jobPostId),
        JobPostsService.getJobOffers(widget.jobPostId),
      ]);
      if (mounted) {
        setState(() {
          _jobPost = results[0] as Map<String, dynamic>;
          _offers = results[1] as List<Map<String, dynamic>>;
          _attendanceMode = AttendanceMode.effectiveForJobPost(_jobPost);
          _isLoading = false;
          _reloading = false;
          _loadFailed = false;
        });
        scheduleGuide();
      }
    } catch (e) {
      if (mounted) {
        final keepExisting = _jobPost != null;
        setState(() {
          _isLoading = false;
          _reloading = false;
          if (!keepExisting) _loadFailed = true;
        });
        if (keepExisting) scheduleGuide();
        if (keepExisting) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(context.l10n.errorWithDetail('$e'))),
          );
        }
      }
    }
  }

  Future<void> _handleCloseJob() async {
    final l10n = context.l10n;
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(l10n.closeJobTitle),
        content: Text(l10n.closeJobConfirmBody),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: Text(l10n.cancel,
                style: kTextStyle.copyWith(color: kSubTitleColor)),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: Text(l10n.closeJob,
                style: kTextStyle.copyWith(
                    color: Colors.red, fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
    if (confirmed != true || !mounted) return;

    try {
      await JobPostsService.closeJobPost(widget.jobPostId);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(context.l10n.jobPostClosed)),
        );
        Navigator.pop(context);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(context.l10n.errorWithDetail('$e'))));
      }
    }
  }

  void _openSellerProfile(Map<String, dynamic> offer) {
    final seller = offer['profiles'] as Map<String, dynamic>?;
    final sellerId =
        (offer['seller_id'] as String?) ?? (seller?['id'] as String?);
    if (sellerId == null || sellerId.isEmpty) return;
    FreelancerPublicProfile(
      sellerId: sellerId,
      initialName: seller?['name'] as String?,
    ).launch(context);
  }

  Future<void> _handleMessageSeller(Map<String, dynamic> offer) async {
    final seller = offer['profiles'] as Map<String, dynamic>?;
    final sellerId = offer['seller_id'] as String?;
    if (sellerId == null) return;
    try {
      final conversation = await ChatService.getOrCreateConversation(sellerId);
      if (!mounted) return;
      ChatInbox(
        conversationId: conversation['id'] as String,
        otherUserName: seller?['name'] ?? context.l10n.freelancerDefault,
        otherUserImage: seller?['profile_image_url'] ?? '',
        otherUserId: sellerId,
      ).launch(context).then((_) {
        if (mounted) _loadData();
      });
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(messageForChatStartFailure(context.l10n, e))),
        );
      }
    }
  }

  void _showPostHireOnboardingSheet(String orderId) {
    showModalBottomSheet<void>(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (ctx) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 20, 20, 16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                context.l10n.addFirstDayInstructionsTitle,
                style: kTextStyle.copyWith(
                  color: kNeutralColor,
                  fontWeight: FontWeight.bold,
                  fontSize: 18,
                ),
              ),
              const SizedBox(height: 10),
              Text(
                context.l10n.addFirstDayInstructionsBody,
                style: kTextStyle.copyWith(color: kSubTitleColor, height: 1.35),
              ),
              const SizedBox(height: 20),
              ButtonGlobalWithoutIcon(
                buttontext: context.l10n.addInstructionsNow,
                buttonDecoration:
                    kButtonDecoration.copyWith(color: kPrimaryColor),
                onPressed: () {
                  Navigator.pop(ctx);
                  _openOnboardingEditor(orderId);
                },
                buttonTextColor: kWhite,
              ),
              const SizedBox(height: 10),
              TextButton(
                onPressed: () => Navigator.pop(ctx),
                child: Text(
                  context.l10n.sendLater,
                  style: kTextStyle.copyWith(color: kLightNeutralColor),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _openOnboardingEditor(String orderId) async {
    await HireOnboardingEditorScreen(
      orderId: orderId,
      jobLocation: _jobPost?['location'] as String?,
      jobLocationType: _jobPost?['location_type'] as String?,
      attendanceMode: _attendanceMode,
    ).launch(context);
    if (mounted) _loadData();
  }

  Future<void> _openInstructionsForOffer(Map<String, dynamic> offer) async {
    final offerId = offer['id'] as String?;
    if (offerId == null) return;
    try {
      final orderId =
          await HireOnboardingService.getOrderIdForJobOffer(offerId);
      if (!mounted) return;
      if (orderId == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(context.l10n.contractNotFoundForHire)),
        );
        return;
      }
      await _openOnboardingEditor(orderId);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(context.l10n.errorWithDetail('$e'))),
        );
      }
    }
  }

  Future<void> _handleRejectOffer(Map<String, dynamic> offer) async {
    final offerId = offer['id'] as String?;
    if (offerId == null) return;
    final seller = offer['profiles'] as Map<String, dynamic>?;
    final sellerName =
        seller?['name'] as String? ?? context.l10n.thisFreelancer;
    final l10n = context.l10n;
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(l10n.rejectApplicationTitle),
        content: Text(l10n.rejectApplicationConfirmBody(sellerName)),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: Text(l10n.cancel,
                style: kTextStyle.copyWith(color: kSubTitleColor)),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: Text(l10n.rejectApplication,
                style: kTextStyle.copyWith(
                    color: Colors.red, fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
    if (confirmed != true || !mounted) return;

    try {
      await JobPostsService.updateOfferStatus(offerId, 'rejected');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(context.l10n.applicationRejected)),
        );
        _loadData();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(context.l10n.errorWithDetail('$e'))));
      }
    }
  }

  Future<void> _handleAcceptOffer(Map<String, dynamic> offer) async {
    final seller = offer['profiles'] as Map<String, dynamic>?;
    final sellerId =
        (offer['seller_id'] as String?) ?? (seller?['id'] as String?);
    if (sellerId != null) {
      try {
        if (await BlockService.isContactBlocked(sellerId)) {
          if (!mounted) return;
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(context.l10n.contactBlocked)),
          );
          return;
        }
      } catch (_) {
        // Migration may not be applied yet; allow hire to continue.
      }
    }
    if (!mounted) return;
    final l10n = context.l10n;
    final sellerName = seller?['name'] ?? l10n.thisFreelancer;
    final priceLabel = JobPostsService.formatOfferAmountShort(
        offer['price'], offer['price_basis']);
    final accepted = JobPostsService.countAcceptedOffers(_offers);
    final unlimited =
        JobPostsService.workersNeededIsUnlimited(_jobPost?['workers_needed']);
    final fillsAll = JobPostsService.acceptingFillsAllSlots(
        _jobPost?['workers_needed'], accepted);
    final cap = JobPostsService.parseWorkersNeeded(_jobPost?['workers_needed']);

    final String bodyText;
    if (unlimited) {
      bodyText = l10n.hireConfirmUnlimited(sellerName.toString(), priceLabel);
    } else if (fillsAll) {
      bodyText = l10n.hireConfirmFillsAll(
        sellerName.toString(),
        priceLabel,
        accepted + 1,
        cap,
      );
    } else {
      final remaining = cap - accepted - 1;
      bodyText = l10n.hireConfirmRemaining(
        sellerName.toString(),
        priceLabel,
        remaining,
        accepted + 1,
        cap,
      );
    }

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(l10n.hireFreelancerTitle),
        content: Text(bodyText),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: Text(l10n.cancel,
                style: kTextStyle.copyWith(color: kSubTitleColor)),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: Text(l10n.hireAction,
                style: kTextStyle.copyWith(
                    color: kPrimaryColor, fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );

    if (confirmed != true) return;

    try {
      final orderId =
          await JobPostsService.acceptJobOffer(offer['id'] as String);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              fillsAll ? l10n.hiredJobFull : l10n.hiredContractCreated,
            ),
          ),
        );
        await _loadData();
        if (mounted) {
          WidgetsBinding.instance.addPostFrameCallback((_) {
            if (mounted) _showPostHireOnboardingSheet(orderId);
          });
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(context.l10n.errorWithDetail('$e'))));
      }
    }
  }

  String _formatDate(String? dateStr) {
    return AppDateFormat.tryDMmmY(
          dateStr,
          AppDateFormat.localeOf(context),
        ) ??
        '';
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    if (_isLoading) {
      return const Scaffold(
        backgroundColor: kDarkWhite,
        body: const LoadingWidget(),
      );
    }

    if (_loadFailed || _jobPost == null) {
      return Scaffold(
        backgroundColor: kDarkWhite,
        appBar: AppBar(
          backgroundColor: kDarkWhite,
          elevation: 0,
          iconTheme: const IconThemeData(color: kNeutralColor),
          title: Text(
            l10n.buyerRequestDetailsTitle,
            style: kTextStyle.copyWith(
              color: kNeutralColor,
              fontWeight: FontWeight.bold,
            ),
          ),
          centerTitle: true,
        ),
        body: EmptyStateWidget(
          message: l10n.somethingWentWrong,
          actionLabel: l10n.retry,
          onAction: () {
            setState(() => _isLoading = true);
            _loadData();
          },
        ),
      );
    }

    final title = _jobPost?['title'] ?? l10n.jobPostFallback;
    final description = _jobPost?['description'] ?? '';
    final category = LocalizedCategory.name(
      _jobPost?['categories'] as Map<String, dynamic>?,
      LocalizedCategory.languageCodeOf(context),
      fallback: l10n.categoryGeneral,
    );
    final status = (_jobPost?['status'] as String?) ?? '';
    final budgetMin = _jobPost?['budget_min'];
    final budgetMax = _jobPost?['budget_max'];
    final isOpen = status == 'open';
    final statusLabel = switch (status) {
      'open' => l10n.open,
      'closed' => l10n.closed,
      '' => l10n.unknown,
      _ => status.substring(0, 1).toUpperCase() + status.substring(1),
    };

    return guideBackScope(Scaffold(
      backgroundColor: kDarkWhite,
      appBar: AppBar(
        backgroundColor: kDarkWhite,
        elevation: 0,
        iconTheme: const IconThemeData(color: kNeutralColor),
        title: Text(
          l10n.buyerRequestDetailsTitle,
          style: kTextStyle.copyWith(
              color: kNeutralColor, fontWeight: FontWeight.bold),
        ),
        centerTitle: true,
        actions: [
          GuideInfoButton(host: this),
          if (isOpen)
            PopupMenuButton<String>(
              padding: EdgeInsets.zero,
              itemBuilder: (BuildContext context) => [
                PopupMenuItem<String>(
                  value: 'close',
                  child: Text(
                    l10n.closeJob,
                    style: kTextStyle.copyWith(color: Colors.red),
                  ),
                ),
              ],
              onSelected: (value) {
                if (value == 'close') _handleCloseJob();
              },
              child: const Padding(
                padding: EdgeInsets.only(right: 10.0),
                child: Icon(Icons.more_vert_rounded, color: kNeutralColor),
              ),
            ),
        ],
      ),
      body: Container(
        padding: const EdgeInsets.only(left: 15.0, right: 15.0),
        width: context.width(),
        decoration: const BoxDecoration(
          color: kWhite,
          borderRadius: BorderRadius.only(
            topLeft: Radius.circular(30.0),
            topRight: Radius.circular(30.0),
          ),
        ),
        child: RubikRefreshIndicator(
          onRefresh: _loadData,
          child: SingleChildScrollView(
            physics: const AlwaysScrollableScrollPhysics(
              parent: BouncingScrollPhysics(),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SizedBox(height: 15.0),
                // Job info card
                _guide(
                  _guideCardKey,
                  l10n.guideJobDetailsCardTitle,
                  l10n.guideJobDetailsCardDesc,
                  Container(
                    padding: const EdgeInsets.all(10.0),
                    width: context.width(),
                    decoration: BoxDecoration(
                      color: kWhite,
                      borderRadius: BorderRadius.circular(8.0),
                      border: Border.all(color: kBorderColorTextField),
                      boxShadow: const [
                        BoxShadow(
                            color: kDarkWhite,
                            spreadRadius: 4.0,
                            blurRadius: 4.0,
                            offset: Offset(0, 2))
                      ],
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(title,
                            style: kTextStyle.copyWith(
                                color: kNeutralColor,
                                fontWeight: FontWeight.bold)),
                        const SizedBox(height: 10.0),
                        ReadMoreText(
                          description,
                          style: kTextStyle.copyWith(color: kSubTitleColor),
                          trimLines: 2,
                          colorClickableText: kPrimaryColor,
                          trimMode: TrimMode.Line,
                          trimCollapsedText: l10n.readMoreSuffix,
                          trimExpandedText: l10n.readLessSuffix,
                        ),
                        const SizedBox(height: 15.0),
                        _buildRow(l10n.categoryLabel, category),
                        const SizedBox(height: 8.0),
                        if (JobPostsService.skillNamesFromJob(_jobPost)
                            .isNotEmpty) ...[
                          _buildRow(
                            l10n.skills,
                            JobPostsService.skillNamesFromJob(_jobPost)
                                .join(', '),
                          ),
                          const SizedBox(height: 8.0),
                        ],
                        if (budgetMin != null || budgetMax != null) ...[
                          _buildRow(
                              l10n.budgetLabel,
                              JobPostsService.formatBudgetRange(budgetMin,
                                  budgetMax, _jobPost?['budget_basis'])),
                          const SizedBox(height: 8.0),
                        ],
                        _buildLocationSection(_jobPost),
                        _buildRow(
                            l10n.workersNeeded,
                            JobPostsService.workersNeededDetailLabel(
                                _jobPost?['workers_needed'])),
                        const SizedBox(height: 8.0),
                        if (ShiftSchedule.fromMap(_jobPost).displayLabel !=
                            null) ...[
                          _buildRow(
                            l10n.shiftLabel,
                            ShiftSchedule.fromMap(_jobPost).displayLabel!,
                          ),
                          const SizedBox(height: 8.0),
                        ],
                        _buildRow(l10n.labelStatus, statusLabel),
                        const SizedBox(height: 8.0),
                        _buildRow(l10n.dateLabel,
                            _formatDate(_jobPost?['created_at'])),
                      ],
                    ),
                  ),
                ),

                if (_showAttendanceSection) ...[
                  const SizedBox(height: 12.0),
                  _buildAttendanceSection(title),
                ],

                // Applications section
                const SizedBox(height: 20.0),
                _guide(
                  _guideApplicationsKey,
                  l10n.guideJobDetailsApplicationsTitle,
                  l10n.guideJobDetailsApplicationsDesc,
                  Text(
                    l10n.applicationsCount(_offers.length),
                    style: kTextStyle.copyWith(
                        color: kNeutralColor, fontWeight: FontWeight.bold),
                  ),
                ),
                const SizedBox(height: 10.0),
                _offers.isEmpty
                    ? Padding(
                        padding: const EdgeInsets.all(20.0),
                        child: Center(
                          child: Text(l10n.noApplicationsYet,
                              style: kTextStyle.copyWith(
                                  color: kLightNeutralColor)),
                        ),
                      )
                    : ListView.builder(
                        shrinkWrap: true,
                        physics: const NeverScrollableScrollPhysics(),
                        itemCount: _offers.length,
                        itemBuilder: (_, i) {
                          final offer = _offers[i];
                          final acceptedIdx = _guideAcceptedIndex;
                          final pendingIdx = _guidePendingIndex;
                          final seller =
                              offer['profiles'] as Map<String, dynamic>?;
                          final offerStatus = offer['status'] ?? 'pending';
                          final (offerFg, offerBg) =
                              StatusColors.application(offerStatus as String?);
                          final offerStatusLabel =
                              switch (offerStatus.toString()) {
                            'pending' => l10n.statusPending,
                            'accepted' => l10n.statusAccepted,
                            'rejected' => l10n.statusRejected,
                            _ => offerStatus
                                    .toString()
                                    .substring(0, 1)
                                    .toUpperCase() +
                                offerStatus.toString().substring(1),
                          };

                          return Container(
                            margin: const EdgeInsets.only(bottom: 10.0),
                            padding: const EdgeInsets.all(10.0),
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(8.0),
                              border: Border.all(color: kBorderColorTextField),
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  children: [
                                    Expanded(
                                      child: _guideIf(
                                        i == 0,
                                        _guideApplicantKey,
                                        l10n.guideJobDetailsApplicantTitle,
                                        l10n.guideJobDetailsApplicantDesc,
                                        InkWell(
                                          onTap: () =>
                                              _openSellerProfile(offer),
                                          borderRadius:
                                              BorderRadius.circular(8),
                                          child: Padding(
                                            padding: const EdgeInsets.symmetric(
                                              vertical: 2,
                                            ),
                                            child: Row(
                                              children: [
                                                CircleAvatar(
                                                  radius: 22,
                                                  backgroundColor: kDarkWhite,
                                                  backgroundImage:
                                                      ProfileImage.provider(
                                                    seller?['profile_image_url']
                                                        as String?,
                                                  ),
                                                ),
                                                const SizedBox(width: 10),
                                                Expanded(
                                                  child: Column(
                                                    crossAxisAlignment:
                                                        CrossAxisAlignment
                                                            .start,
                                                    children: [
                                                      Text(
                                                        seller?['name'] ??
                                                            l10n.roleSeller,
                                                        style:
                                                            kTextStyle.copyWith(
                                                          color: kNeutralColor,
                                                          fontWeight:
                                                              FontWeight.bold,
                                                        ),
                                                      ),
                                                      Text(
                                                        '${JobPostsService.formatOfferAmountShort(offer['price'], offer['price_basis'])} • ${JobOfferDelivery.formatLabel(offer['delivery_time'], offer['delivery_time_unit'])}',
                                                        style:
                                                            kTextStyle.copyWith(
                                                          color: kSubTitleColor,
                                                        ),
                                                      ),
                                                    ],
                                                  ),
                                                ),
                                              ],
                                            ),
                                          ),
                                        ),
                                      ),
                                    ),
                                    Container(
                                      padding: const EdgeInsets.symmetric(
                                          horizontal: 8, vertical: 4),
                                      decoration: BoxDecoration(
                                        borderRadius: BorderRadius.circular(12),
                                        color: offerBg,
                                      ),
                                      child: Text(
                                        offerStatusLabel,
                                        style: kTextStyle.copyWith(
                                          color: offerFg,
                                          fontSize: 12,
                                        ),
                                      ),
                                    ),
                                    const SizedBox(width: 4),
                                    _guideIf(
                                      i == 0,
                                      _guideMessageKey,
                                      l10n.guideJobDetailsMessageTitle,
                                      l10n.guideJobDetailsMessageDesc,
                                      IconButton(
                                        visualDensity: VisualDensity.compact,
                                        padding: EdgeInsets.zero,
                                        constraints: const BoxConstraints(
                                            minWidth: 36, minHeight: 36),
                                        tooltip: l10n.messageFreelancerTooltip,
                                        icon: const Icon(
                                            Icons.chat_bubble_outline,
                                            size: 20,
                                            color: kPrimaryColor),
                                        onPressed: () =>
                                            _handleMessageSeller(offer),
                                      ),
                                    ),
                                  ],
                                ),
                                if (offer['cover_letter'] != null &&
                                    offer['cover_letter']
                                        .toString()
                                        .isNotEmpty) ...[
                                  const SizedBox(height: 8),
                                  Text(
                                    offer['cover_letter'],
                                    style: kTextStyle.copyWith(
                                        color: kSubTitleColor),
                                    maxLines: 3,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ],
                                if (offerStatus == 'accepted') ...[
                                  const SizedBox(height: 10),
                                  Align(
                                    alignment: Alignment.centerRight,
                                    child: _guideIf(
                                      i == acceptedIdx,
                                      _guideInstructionsKey,
                                      l10n.guideJobDetailsInstructionsTitle,
                                      l10n.guideJobDetailsInstructionsDesc,
                                      TextButton.icon(
                                        onPressed: () =>
                                            _openInstructionsForOffer(offer),
                                        icon: const Icon(
                                          Icons.menu_book_outlined,
                                          size: 18,
                                          color: kPrimaryColor,
                                        ),
                                        label: Text(
                                          l10n.firstDayInstructions,
                                          style: kTextStyle.copyWith(
                                            color: kPrimaryColor,
                                            fontWeight: FontWeight.w600,
                                          ),
                                        ),
                                      ),
                                    ),
                                  ),
                                ],
                                if (offerStatus == 'pending' && isOpen) ...[
                                  const SizedBox(height: 10),
                                  _guideIf(
                                    i == pendingIdx,
                                    _guideHireKey,
                                    l10n.guideJobDetailsHireTitle,
                                    l10n.guideJobDetailsHireDesc,
                                    Row(
                                      children: [
                                        Expanded(
                                          child: ButtonGlobalWithoutIcon(
                                            buttontext: l10n.rejectApplication,
                                            buttonDecoration:
                                                kButtonDecoration.copyWith(
                                              color: kWhite,
                                              border:
                                                  Border.all(color: Colors.red),
                                            ),
                                            onPressed: () =>
                                                _handleRejectOffer(offer),
                                            buttonTextColor: Colors.red,
                                          ),
                                        ),
                                        Expanded(
                                          child: ButtonGlobalWithoutIcon(
                                            buttontext: l10n.hireAction,
                                            buttonDecoration: kButtonDecoration
                                                .copyWith(color: kPrimaryColor),
                                            onPressed: () =>
                                                _handleAcceptOffer(offer),
                                            buttonTextColor: kWhite,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ],
                              ],
                            ),
                          );
                        },
                      ),
                const SizedBox(height: 20),
              ],
            ),
          ),
        ),
      ),
    ));
  }

  bool get _showAttendanceSection => AttendanceService.isOnsiteJob(_jobPost);

  Future<bool> _ensureSitePin({bool explain = true}) async {
    if (jobPostCoordinates(_jobPost) != null) return true;

    if (explain) {
      final l10n = context.l10n;
      final proceed = await showDialog<bool>(
        context: context,
        builder: (ctx) => AlertDialog(
          title: Text(l10n.setSitePin),
          content: Text(l10n.attendancePinSiteToUseQr),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx, false),
              child: Text(l10n.cancel),
            ),
            TextButton(
              onPressed: () => Navigator.pop(ctx, true),
              child: Text(l10n.setSitePin),
            ),
          ],
        ),
      );
      if (proceed != true || !mounted) return false;
    }

    final existing = (_jobPost?['location'] as String?)?.trim();
    final result = await Navigator.of(context).push<MapLocationPickerResult>(
      MaterialPageRoute(
        builder: (_) => MapLocationPickerScreen(
          purpose: MapLocationPickerPurpose.job,
          initialLocation: existing,
          title: context.l10n.setSitePin,
        ),
      ),
    );
    if (result == null || !mounted) return false;

    try {
      final label = result.locationLabel?.trim();
      await JobPostsService.updateJobSitePin(
        jobPostId: widget.jobPostId,
        latitude: result.latitude,
        longitude: result.longitude,
        location: label,
      );
      if (!mounted) return false;
      setState(() {
        _jobPost?['latitude'] = result.latitude;
        _jobPost?['longitude'] = result.longitude;
        if (label != null && label.isNotEmpty) {
          _jobPost?['location'] = label;
        }
      });
      return true;
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(context.l10n.errorWithDetail('$e'))),
        );
      }
      return false;
    }
  }

  Future<void> _onAttendanceModeSelected(String mode) async {
    // Steps 3 to 5 of the attendance guide depend on the chosen mode.
    cancelGuide();
    if (AttendanceMode.canUseQr(mode)) {
      final ok = await _ensureSitePin();
      if (!ok || !mounted) return;
    }
    await _saveAttendanceMode(mode);
  }

  Future<void> _openAttendanceQr(String jobTitle) async {
    final ok = await _ensureSitePin();
    if (!ok || !mounted) return;
    AttendanceQrDisplayScreen(
      jobPostId: widget.jobPostId,
      jobTitle: jobTitle,
    ).launch(context);
  }

  Future<void> _saveAttendanceMode(String mode) async {
    setState(() => _savingAttendanceMode = true);
    try {
      await AttendanceService.updateJobAttendanceMode(widget.jobPostId, mode);
      if (mounted) {
        setState(() {
          _attendanceMode = AttendanceMode.normalize(mode);
          _jobPost?['attendance_mode'] = _attendanceMode;
          _savingAttendanceMode = false;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(context.l10n.attendanceSettingsUpdated)),
        );
      }
    } catch (e) {
      if (mounted) {
        setState(() => _savingAttendanceMode = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(context.l10n.errorWithDetail('$e'))),
        );
      }
    }
  }

  Map<String, String> _attendanceModeLabels(AppLocalizations l10n) => {
        AttendanceMode.qrInOut: l10n.attendanceModeQrInOut,
        AttendanceMode.qrOnce: l10n.attendanceModeQrOnce,
        AttendanceMode.selfReport: l10n.attendanceModeSelfReport,
        AttendanceMode.disabled: l10n.attendanceModeDisabled,
      };

  Widget _buildAttendanceSection(String jobTitle) {
    final l10n = context.l10n;
    final mode = AttendanceMode.normalize(_attendanceMode);
    final showQr = AttendanceMode.canUseQr(mode);
    final needsSitePin = showQr && jobPostCoordinates(_jobPost) == null;
    final modeLabels = _attendanceModeLabels(l10n);

    return _guide(
      _guideAttendanceKey,
      l10n.guideJobDetailsAttendanceTitle,
      l10n.guideJobDetailsAttendanceDesc,
      radius: 10,
      _buildAttendanceSectionContent(
        jobTitle: jobTitle,
        mode: mode,
        showQr: showQr,
        needsSitePin: needsSitePin,
        modeLabels: modeLabels,
      ),
    );
  }

  Widget _buildAttendanceSectionContent({
    required String jobTitle,
    required String mode,
    required bool showQr,
    required bool needsSitePin,
    required Map<String, String> modeLabels,
  }) {
    final l10n = context.l10n;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      width: context.width(),
      decoration: BoxDecoration(
        color: kPrimaryColor.withValues(alpha: 0.05),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: kBorderColorTextField),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text(
                l10n.attendance,
                style: kTextStyle.copyWith(
                  color: kNeutralColor,
                  fontWeight: FontWeight.w700,
                  fontSize: 13,
                ),
              ),
              const Spacer(),
              if (showQr)
                _guide(
                  _guideQrKey,
                  l10n.guideJobDetailsQrTitle,
                  l10n.guideJobDetailsQrDesc,
                  TextButton(
                    onPressed: _savingAttendanceMode
                        ? null
                        : () => _openAttendanceQr(jobTitle),
                    style: TextButton.styleFrom(
                      padding: const EdgeInsets.symmetric(horizontal: 8),
                      minimumSize: Size.zero,
                      tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                    ),
                    child: Text(
                      l10n.attendanceQrShort,
                      style: kTextStyle.copyWith(
                        color: kPrimaryColor,
                        fontWeight: FontWeight.w700,
                        fontSize: 13,
                      ),
                    ),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 4),
          _guide(
            _guideMethodKey,
            l10n.guideJobDetailsMethodTitle,
            l10n.guideJobDetailsMethodDesc,
            DropdownButtonHideUnderline(
              child: DropdownButton<String>(
                isExpanded: true,
                isDense: true,
                value: mode,
                style: kTextStyle.copyWith(color: kNeutralColor, fontSize: 13),
                items: modeLabels.entries
                    .map(
                      (e) => DropdownMenuItem(
                        value: e.key,
                        child: Text(e.value),
                      ),
                    )
                    .toList(),
                onChanged: _savingAttendanceMode
                    ? null
                    : (v) {
                        if (v != null) _onAttendanceModeSelected(v);
                      },
              ),
            ),
          ),
          if (needsSitePin) ...[
            const SizedBox(height: 8),
            _guide(
              _guidePinKey,
              l10n.guideJobDetailsPinTitle,
              l10n.guideJobDetailsPinDesc,
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    l10n.attendancePinSiteToUseQr,
                    style: kTextStyle.copyWith(
                      color: kSubTitleColor,
                      fontSize: 12,
                      height: 1.35,
                    ),
                  ),
                  Align(
                    alignment: Alignment.centerLeft,
                    child: TextButton(
                      onPressed: _savingAttendanceMode
                          ? null
                          : () => _ensureSitePin(explain: false),
                      style: TextButton.styleFrom(
                        padding: EdgeInsets.zero,
                        minimumSize: Size.zero,
                        tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                      ),
                      child: Text(
                        l10n.setSitePin,
                        style: kTextStyle.copyWith(
                          color: kPrimaryColor,
                          fontWeight: FontWeight.w700,
                          fontSize: 13,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
          if (AttendanceMode.isEnabled(mode)) ...[
            const SizedBox(height: 10),
            _guide(
              _guideTodayKey,
              l10n.guideJobDetailsTodayTitle,
              l10n.guideJobDetailsTodayDesc,
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    l10n.calendarToday,
                    style: kTextStyle.copyWith(
                      color: kNeutralColor,
                      fontWeight: FontWeight.w700,
                      fontSize: 13,
                    ),
                  ),
                  const SizedBox(height: 6),
                  AttendancePunchLogSection(
                    jobPostId: widget.jobPostId,
                    showSellerName: true,
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildLocationSection(Map<String, dynamic>? job) {
    final l10n = context.l10n;
    final location = (job?['location'] as String?)?.trim();
    final locationType = (job?['location_type'] as String?)?.trim();
    final coords = jobPostCoordinates(job);

    if ((location == null || location.isEmpty) &&
        coords == null &&
        locationType == null) {
      return const SizedBox.shrink();
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (locationType != null && locationType.isNotEmpty) ...[
          const SizedBox(height: 8),
          Row(
            children: [
              Text(l10n.locationLabel,
                  style: kTextStyle.copyWith(color: kSubTitleColor)),
              const SizedBox(width: 8),
              Text(l10n.labelColon,
                  style: kTextStyle.copyWith(color: kSubTitleColor)),
              const SizedBox(width: 10),
              _locationTypeBadge(locationType),
            ],
          ),
          const SizedBox(height: 8),
        ],
        if (coords != null) ...[
          JobLocationSection(job: job),
          const SizedBox(height: 8),
        ] else if (location != null && location.isNotEmpty) ...[
          _buildRow(l10n.areaLabel, location),
          const SizedBox(height: 8),
        ],
      ],
    );
  }

  Widget _locationTypeBadge(String type) {
    final l10n = context.l10n;
    final (Color bg, Color fg, IconData icon) = switch (type) {
      'On-site' => (
          const Color(0xFFE8F5E9),
          const Color(0xFF2E7D32),
          Icons.location_on_outlined
        ),
      _ => (
          const Color(0xFFE3F2FD),
          const Color(0xFF1565C0),
          Icons.laptop_outlined
        ),
    };
    final label = type == 'On-site' ? l10n.locationOnSite : l10n.locationRemote;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: fg),
          const SizedBox(width: 4),
          Text(label,
              style: kTextStyle.copyWith(
                  color: fg, fontSize: 12, fontWeight: FontWeight.bold)),
        ],
      ),
    );
  }

  Widget _buildRow(String label, String value) {
    final l10n = context.l10n;
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(
          flex: 2,
          child: Text(label, style: kTextStyle.copyWith(color: kSubTitleColor)),
        ),
        Expanded(
          flex: 4,
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(l10n.labelColon,
                  style: kTextStyle.copyWith(color: kSubTitleColor)),
              const SizedBox(width: 10.0),
              Flexible(
                child: Text(value,
                    style: kTextStyle.copyWith(color: kSubTitleColor),
                    overflow: TextOverflow.ellipsis,
                    maxLines: 2),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
