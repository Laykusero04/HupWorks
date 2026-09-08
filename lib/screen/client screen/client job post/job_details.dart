import 'package:freelancer/l10n/l10n.dart';
import 'package:flutter/material.dart';
import 'package:freelancer/core/utils/job_offer_delivery.dart';
import 'package:freelancer/core/utils/localized_category.dart';
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

class JobDetails extends StatefulWidget {
  final String jobPostId;

  const JobDetails({Key? key, required this.jobPostId}) : super(key: key);

  @override
  State<JobDetails> createState() => _JobDetailsState();
}

class _JobDetailsState extends State<JobDetails> {
  Map<String, dynamic>? _jobPost;
  List<Map<String, dynamic>> _offers = [];
  bool _isLoading = true;
  String _attendanceMode = AttendanceMode.qrInOut;
  bool _savingAttendanceMode = false;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
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
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(context.l10n.errorWithDetail('$e'))),
        );
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
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text(context.l10n.errorWithDetail('$e'))));
      }
    }
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
          SnackBar(content: Text(context.l10n.couldNotOpenChatWithDetail('$e'))),
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
    final sellerName = seller?['name'] as String? ?? context.l10n.thisFreelancer;
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
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text(context.l10n.errorWithDetail('$e'))));
      }
    }
  }

  Future<void> _handleAcceptOffer(Map<String, dynamic> offer) async {
    final seller = offer['profiles'] as Map<String, dynamic>?;
    final sellerId = (offer['seller_id'] as String?) ??
        (seller?['id'] as String?);
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
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text(context.l10n.errorWithDetail('$e'))));
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
        body: Center(child: CircularProgressIndicator(color: kPrimaryColor)),
      );
    }

    final title = _jobPost?['title'] ?? l10n.jobPostFallback;
    final description = _jobPost?['description'] ?? '';
    final category = LocalizedCategory.name(
      _jobPost?['categories'] as Map<String, dynamic>?,
      LocalizedCategory.languageCodeOf(context),
      fallback: l10n.categoryGeneral,
    );
    final status = _jobPost?['status'] ?? 'open';
    final budgetMin = _jobPost?['budget_min'];
    final budgetMax = _jobPost?['budget_max'];
    final isOpen = status == 'open';
    final statusLabel = switch (status.toString()) {
      'open' => l10n.open,
      'closed' => l10n.closed,
      _ => status.toString().substring(0, 1).toUpperCase() +
          status.toString().substring(1),
    };

    return Scaffold(
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
          if (isOpen)
            PopupMenuButton(
              padding: EdgeInsets.zero,
              itemBuilder: (BuildContext context) => [
                PopupMenuItem(
                  child: Text(l10n.closeJob,
                          style: kTextStyle.copyWith(color: Colors.red))
                      .onTap(() => _handleCloseJob()),
                ),
              ],
              onSelected: (value) {},
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
        child: RefreshIndicator(
          color: kPrimaryColor,
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
                            color: kNeutralColor, fontWeight: FontWeight.bold)),
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
                    if (JobPostsService.skillNamesFromJob(_jobPost).isNotEmpty) ...[
                      _buildRow(
                        l10n.skills,
                        JobPostsService.skillNamesFromJob(_jobPost).join(', '),
                      ),
                      const SizedBox(height: 8.0),
                    ],
                    if (budgetMin != null || budgetMax != null) ...[
                      _buildRow(
                          l10n.budgetLabel,
                          JobPostsService.formatBudgetRange(
                              budgetMin, budgetMax, _jobPost?['budget_basis'])),
                      const SizedBox(height: 8.0),
                    ],
                    _buildLocationSection(_jobPost),
                    _buildRow(
                        l10n.workersNeeded,
                        JobPostsService.workersNeededDetailLabel(
                            _jobPost?['workers_needed'])),
                    const SizedBox(height: 8.0),
                    if (ShiftSchedule.fromMap(_jobPost).displayLabel != null) ...[
                      _buildRow(
                        l10n.shiftLabel,
                        ShiftSchedule.fromMap(_jobPost).displayLabel!,
                      ),
                      const SizedBox(height: 8.0),
                    ],
                    _buildRow(l10n.labelStatus, statusLabel),
                    const SizedBox(height: 8.0),
                    _buildRow(l10n.dateLabel, _formatDate(_jobPost?['created_at'])),
                  ],
                ),
              ),

              if (_showAttendanceSection) ...[
                const SizedBox(height: 12.0),
                _buildAttendanceSection(title),
              ],

              // Applications section
              const SizedBox(height: 20.0),
              Text(
                l10n.applicationsCount(_offers.length),
                style: kTextStyle.copyWith(
                    color: kNeutralColor, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 10.0),
              _offers.isEmpty
                  ? Padding(
                      padding: const EdgeInsets.all(20.0),
                      child: Center(
                        child: Text(l10n.noApplicationsYet,
                            style:
                                kTextStyle.copyWith(color: kLightNeutralColor)),
                      ),
                    )
                  : ListView.builder(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      itemCount: _offers.length,
                      itemBuilder: (_, i) {
                        final offer = _offers[i];
                        final seller =
                            offer['profiles'] as Map<String, dynamic>?;
                        final offerStatus = offer['status'] ?? 'pending';
                        final (offerFg, offerBg) =
                            StatusColors.application(offerStatus as String?);
                        final offerStatusLabel = switch (offerStatus.toString()) {
                          'pending' => l10n.statusPending,
                          'accepted' => l10n.statusAccepted,
                          'rejected' => l10n.statusRejected,
                          _ => offerStatus.toString().substring(0, 1).toUpperCase() +
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
                                  CircleAvatar(
                                    radius: 20,
                                    backgroundImage:
                                        seller?['profile_image_url'] != null
                                            ? NetworkImage(
                                                seller!['profile_image_url'])
                                            : const AssetImage(
                                                    'images/profilepic2.png')
                                                as ImageProvider,
                                  ),
                                  const SizedBox(width: 10),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          seller?['name'] ?? l10n.roleSeller,
                                          style: kTextStyle.copyWith(
                                              color: kNeutralColor,
                                              fontWeight: FontWeight.bold),
                                        ),
                                        Text(
                                          '${JobPostsService.formatOfferAmountShort(offer['price'], offer['price_basis'])} • ${JobOfferDelivery.formatLabel(offer['delivery_time'], offer['delivery_time_unit'])}',
                                          style: kTextStyle.copyWith(
                                              color: kSubTitleColor),
                                        ),
                                      ],
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
                                  IconButton(
                                    visualDensity: VisualDensity.compact,
                                    padding: EdgeInsets.zero,
                                    constraints: const BoxConstraints(
                                        minWidth: 36, minHeight: 36),
                                    tooltip: l10n.messageFreelancerTooltip,
                                    icon: const Icon(Icons.chat_bubble_outline,
                                        size: 20, color: kPrimaryColor),
                                    onPressed: () =>
                                        _handleMessageSeller(offer),
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
                                  child: TextButton.icon(
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
                              ],
                              if (offerStatus == 'pending' && isOpen) ...[
                                const SizedBox(height: 10),
                                Row(
                                  children: [
                                    Expanded(
                                      child: ButtonGlobalWithoutIcon(
                                        buttontext: l10n.rejectApplication,
                                        buttonDecoration:
                                            kButtonDecoration.copyWith(
                                          color: kWhite,
                                          border: Border.all(color: Colors.red),
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
    );
  }

  bool get _showAttendanceSection => AttendanceService.isOnsiteJob(_jobPost);

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
    final modeLabels = _attendanceModeLabels(l10n);

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
                TextButton(
                  onPressed: _savingAttendanceMode
                      ? null
                      : () {
                          AttendanceQrDisplayScreen(
                            jobPostId: widget.jobPostId,
                            jobTitle: jobTitle,
                          ).launch(context);
                        },
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
            ],
          ),
          const SizedBox(height: 4),
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
                      if (v != null) _saveAttendanceMode(v);
                    },
            ),
          ),
          if (AttendanceMode.isEnabled(mode)) ...[
            const SizedBox(height: 10),
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
              Text(l10n.labelColon, style: kTextStyle.copyWith(color: kSubTitleColor)),
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
    final label =
        type == 'On-site' ? l10n.locationOnSite : l10n.locationRemote;
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
              Text(l10n.labelColon, style: kTextStyle.copyWith(color: kSubTitleColor)),
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
