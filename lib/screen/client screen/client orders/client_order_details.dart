import 'package:flutter/material.dart';
import 'package:flutter_iconly/flutter_iconly.dart';
import 'package:freelancer/core/utils/attendance_mode.dart';
import 'package:freelancer/core/utils/order_cancellation.dart';
import 'package:freelancer/core/utils/order_chat_navigation.dart';
import 'package:freelancer/core/utils/order_contract_display.dart';
import 'package:freelancer/core/utils/shift_schedule.dart';
import 'package:freelancer/data/models/chat_order_context.dart';
import 'package:freelancer/screen/widgets/chat_preferred_contact_banner.dart';
import 'package:freelancer/data/models/hire_onboarding_packet_model.dart';
import 'package:freelancer/data/models/order_delivery_model.dart';
import 'package:freelancer/l10n/l10n.dart';
import 'package:freelancer/l10n/l10n_labels.dart';
import 'package:freelancer/screen/onboarding/hire_onboarding_editor_screen.dart';
import 'package:freelancer/screen/widgets/button_global.dart';
import 'package:freelancer/services/attendance_service.dart';
import 'package:freelancer/services/hire_onboarding_service.dart';
import 'package:freelancer/services/orders_service.dart';
import 'package:nb_utils/nb_utils.dart';
import 'package:slide_countdown/slide_countdown.dart';

import '../../widgets/client_attendance_today_card.dart';
import '../../widgets/client_site_setup_panel.dart';
import '../../widgets/constant.dart';
import '../../widgets/hour_reports_section.dart';
import '../../widgets/order_delivery_panel.dart';
import '../client report/client_report.dart';
import '../client review/client_review.dart';

class ClientOrderDetails extends StatefulWidget {
  final String orderId;

  const ClientOrderDetails({Key? key, required this.orderId}) : super(key: key);

  @override
  State<ClientOrderDetails> createState() => _ClientOrderDetailsState();
}

class _ClientOrderDetailsState extends State<ClientOrderDetails> {
  Map<String, dynamic>? _order;
  Map<String, dynamic>? _service;
  Map<String, dynamic>? _seller;
  bool _isLoading = true;
  bool _isCompletingJob = false;
  bool _cancellationBusy = false;
  bool _clientHasReviewed = false;
  HireOnboardingPacket? _onboardingPacket;

  @override
  void initState() {
    super.initState();
    _loadOrder();
  }

  Future<void> _loadOrder() async {
    try {
      await OrdersService.expireStaleCancellationRequests();
      final data = await OrdersService.getOrderDetails(widget.orderId);
      HireOnboardingPacket? packet;
      if (OrdersService.jobOfferIdFromOrderMap(data) != null) {
        packet = await HireOnboardingService.getPacketForOrder(widget.orderId);
        packet ??= await _tryEnsureOnboardingDraft();
      }
      if (mounted) {
        setState(() {
          _order = data;
          _service = data['services'] as Map<String, dynamic>?;
          _seller = data['seller'] as Map<String, dynamic>?;
          _clientHasReviewed = OrdersService.currentUserHasReviewedOrder(data);
          _onboardingPacket = packet;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(context.l10n.errorLoadingOrder('$e'))),
        );
      }
    }
  }

  Duration _getTimeRemaining() {
    final deadline = _order?['delivery_deadline'];
    if (deadline == null) return Duration.zero;
    final deadlineDate = DateTime.tryParse(deadline);
    if (deadlineDate == null) return Duration.zero;
    final remaining = deadlineDate.difference(DateTime.now());
    return remaining.isNegative ? Duration.zero : remaining;
  }

  String _formatDate(String? dateStr) {
    if (dateStr == null) return '';
    final date = DateTime.tryParse(dateStr);
    if (date == null) return '';
    const days = [
      'Monday',
      'Tuesday',
      'Wednesday',
      'Thursday',
      'Friday',
      'Saturday',
      'Sunday'
    ];
    const months = [
      'Jan',
      'Feb',
      'Mar',
      'Apr',
      'May',
      'Jun',
      'Jul',
      'Aug',
      'Sep',
      'Oct',
      'Nov',
      'Dec'
    ];
    return '${days[date.weekday - 1]}, ${date.day} ${months[date.month - 1]} ${date.year}';
  }

  Future<void> _respondToCancellation({required bool approve}) async {
    setState(() => _cancellationBusy = true);
    try {
      await OrdersService.respondToCancellation(
        orderId: widget.orderId,
        approve: approve,
      );
      if (mounted) {
        final l10n = context.l10n;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              approve
                  ? l10n.contractCancelledSnack
                  : l10n.contractKeptActive,
            ),
          ),
        );
        if (approve) {
          Navigator.pop(context);
        } else {
          await _loadOrder();
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(context.l10n.errorWithDetail('$e'))),
        );
      }
    } finally {
      if (mounted) setState(() => _cancellationBusy = false);
    }
  }

  Future<HireOnboardingPacket?> _tryEnsureOnboardingDraft() async {
    try {
      await HireOnboardingService.ensureDraft(widget.orderId);
      return HireOnboardingService.getPacketForOrder(widget.orderId);
    } catch (_) {
      return null;
    }
  }

  Future<void> _openOnboardingEditor() async {
    final jobPost = OrderContractDisplay.jobPostFromOrder(_order);
    final result = await HireOnboardingEditorScreen(
      orderId: widget.orderId,
      jobLocation: jobPost?['location'] as String?,
      jobLocationType: jobPost?['location_type'] as String?,
      attendanceMode:
          jobPost != null ? AttendanceMode.effectiveForJobPost(jobPost) : null,
    ).launch(context);
    if (mounted && result == true) await _loadOrder();
  }

  String? _onboardingStatusShort() {
    final l10n = context.l10n;
    final packet = _onboardingPacket;
    if (packet == null || !packet.isPublished) return l10n.onboardingNotSet;
    if (packet.acknowledged) return l10n.onboardingAcknowledgedShort;
    return l10n.onboardingAwaitingAck;
  }

  Widget? _buildSiteSetupPanel({required bool readOnly}) {
    if (OrdersService.jobOfferIdFromOrderMap(_order ?? {}) == null) {
      return null;
    }
    if (readOnly) return null;
    return ClientSiteSetupPanel(
      onboardingStatus: _onboardingStatusShort(),
      onOnboarding: _openOnboardingEditor,
      jobPost: OrderContractDisplay.jobPostFromOrder(_order),
    );
  }

  Widget? _buildAttendanceTodayCard() {
    final jobPost = OrderContractDisplay.jobPostFromOrder(_order);
    final jobPostId = OrderContractDisplay.jobPostIdFromOrder(_order);
    if (jobPostId == null || !AttendanceService.isOnsiteJob(jobPost)) {
      return null;
    }
    if (!AttendanceMode.isEnabled(AttendanceMode.effectiveForJobPost(jobPost))) {
      return null;
    }
    return ClientAttendanceTodayCard(jobPostId: jobPostId);
  }

  String _statusKey() =>
      ((_order?['status'] as String?) ?? 'pending').toLowerCase();

  String _statusLabelForUi(String status) =>
      L10nLabels.clientOrderStatusForUi(context.l10n, status);

  Future<void> _handleMarkJobComplete() async {
    final l10n = context.l10n;
    final sellerName = _seller?['name'] ?? l10n.theSeller;
    if (_statusKey() != 'delivered') {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(l10n.waitingForDelivery)),
        );
      }
      return;
    }
    final confirmed = await showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Text(
          l10n.markJobCompleteTitle,
          style: kTextStyle.copyWith(
              color: kNeutralColor, fontWeight: FontWeight.bold),
        ),
        content: Text(
          l10n.markJobCompleteDeliveredBody(sellerName),
          style: kTextStyle.copyWith(color: kSubTitleColor, height: 1.35),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: Text(l10n.notYet,
                style: kTextStyle.copyWith(color: kLightNeutralColor)),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: Text(l10n.yesCompleteJob,
                style: kTextStyle.copyWith(
                    color: kPrimaryColor, fontWeight: FontWeight.w700)),
          ),
        ],
      ),
    );
    if (confirmed != true || !mounted) return;

    setState(() => _isCompletingJob = true);
    try {
      await OrdersService.completeOrder(widget.orderId);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(context.l10n.jobMarkedCompleteThanks)),
      );
      await _loadOrder();
      if (!mounted) return;
      if (!_clientHasReviewed) {
        final review = await showDialog<bool>(
          context: context,
          builder: (ctx) => AlertDialog(
            shape:
                RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
            title: Text(
              l10n.leaveReviewTitle,
              style: kTextStyle.copyWith(
                  color: kNeutralColor, fontWeight: FontWeight.bold),
            ),
            content: Text(
              l10n.leaveReviewBody,
              style: kTextStyle.copyWith(color: kSubTitleColor, height: 1.35),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(ctx, false),
                child: Text(l10n.later,
                    style: kTextStyle.copyWith(color: kLightNeutralColor)),
              ),
              TextButton(
                onPressed: () => Navigator.pop(ctx, true),
                child: Text(l10n.writeReviewAction,
                    style: kTextStyle.copyWith(
                        color: kPrimaryColor, fontWeight: FontWeight.w700)),
              ),
            ],
          ),
        );
        if (review == true && mounted) {
          await _openClientReviewScreen();
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(context.l10n.couldNotCompleteJob('$e'))),
        );
      }
    } finally {
      if (mounted) setState(() => _isCompletingJob = false);
    }
  }

  Future<void> _openClientReviewScreen() async {
    final sid = _seller?['id'] as String?;
    if (sid == null || sid.isEmpty) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
              content: Text(context.l10n.couldNotOpenReviewMissingSeller)),
        );
      }
      return;
    }
    final order = _order;
    await ClientOrderReview(
      orderId: widget.orderId,
      sellerId: sid,
      serviceId:
          order != null ? OrdersService.serviceIdFromOrderMap(order) : null,
      jobOfferId:
          order != null ? OrdersService.jobOfferIdFromOrderMap(order) : null,
      sellerName: _seller?['name'] as String?,
      sellerProfileImageUrl: _seller?['profile_image_url'] as String?,
    ).launch(context);
    if (mounted) await _loadOrder();
  }

  ChatOrderContext _chatOrderContext({required bool isClientViewer}) {
    final preferred = preferredContactFromOrder(_order ?? {});
    return ChatOrderContext(
      orderId: widget.orderId,
      title: OrderContractDisplay.title(_order, _service),
      statusLabel: _statusLabelForUi(_statusKey()),
      deadlineLabel: _formatDate(_order?['delivery_deadline']),
      preferredContactLabel: preferred.label,
      isWithinPreferredWindow: preferred.inWindow,
      isClientViewer: isClientViewer,
    );
  }

  Future<void> _handleMessageSeller() async {
    final sellerId = _seller?['id'] as String?;
    if (sellerId == null || sellerId.isEmpty) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(context.l10n.couldNotOpenReviewMissingSeller)),
        );
      }
      return;
    }
    await openOrderChat(
      context,
      otherUserId: sellerId,
      otherUserName: _seller?['name'] as String? ?? context.l10n.roleSeller,
      otherUserImage: _seller?['profile_image_url'] as String? ?? '',
      orderContext: _chatOrderContext(isClientViewer: true),
    );
  }

  Widget _buildDeliveredCallout() {
    final l10n = context.l10n;
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: kSecondaryColor.withOpacity(0.08),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: kSecondaryColor.withOpacity(0.35)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(Icons.inbox_rounded, color: kSecondaryColor, size: 26),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  l10n.sellerSubmittedDelivery,
                  style: kTextStyle.copyWith(
                      color: kNeutralColor, fontWeight: FontWeight.w700),
                ),
                const SizedBox(height: 6),
                Text(
                  l10n.deliveredCalloutBody,
                  style: kTextStyle.copyWith(
                      color: kSubTitleColor, fontSize: 13, height: 1.35),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildActiveWorkCallout() {
    final l10n = context.l10n;
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: kPrimaryColor.withOpacity(0.06),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: kPrimaryColor.withOpacity(0.25)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(Icons.handshake_rounded, color: kPrimaryColor, size: 26),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  l10n.openContract,
                  style: kTextStyle.copyWith(
                      color: kNeutralColor, fontWeight: FontWeight.w700),
                ),
                const SizedBox(height: 6),
                Text(
                  l10n.openContractCalloutBody,
                  style: kTextStyle.copyWith(
                      color: kSubTitleColor, fontSize: 13, height: 1.35),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCancellationRequestBanner(String sellerName) {
    final l10n = context.l10n;
    final code = _order?['cancellation_reason_code'] as String?;
    final note = _order?['cancellation_reason_note'] as String?;
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: StatusColors.warningBg,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: StatusColors.warning.withValues(alpha: 0.45)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            l10n.cancellationRequested,
            style: kTextStyle.copyWith(
              color: kNeutralColor,
              fontWeight: FontWeight.bold,
              fontSize: 16,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            l10n.cancellationRequestBannerBody(sellerName),
            style: kTextStyle.copyWith(
              color: kSubTitleColor,
              fontSize: 13,
              height: 1.35,
            ),
          ),
          if (code != null) ...[
            const SizedBox(height: 8),
            Text(
              l10n.cancellationReasonLine(
                OrderCancellationReason.label(code, l10n),
              ),
              style: kTextStyle.copyWith(
                color: kNeutralColor,
                fontWeight: FontWeight.w600,
                fontSize: 13,
              ),
            ),
          ],
          if (note != null && note.trim().isNotEmpty) ...[
            const SizedBox(height: 4),
            Text(
              note.trim(),
              style: kTextStyle.copyWith(
                color: kSubTitleColor,
                fontSize: 13,
                height: 1.35,
              ),
            ),
          ],
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: ButtonGlobalWithoutIcon(
                  buttontext: _cancellationBusy
                      ? l10n.ellipsisBusy
                      : l10n.keepContract,
                  buttonTextColor: kNeutralColor,
                  buttonDecoration: kButtonDecoration.copyWith(
                    color: kWhite,
                    border: Border.all(color: kBorderColorTextField),
                  ),
                  onPressed: _cancellationBusy
                      ? () {}
                      : () => _respondToCancellation(approve: false),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: ButtonGlobalWithoutIcon(
                  buttontext: _cancellationBusy
                      ? l10n.ellipsisBusy
                      : l10n.approveCancellation,
                  buttonTextColor: kWhite,
                  buttonDecoration: kButtonDecoration.copyWith(
                    color: _cancellationBusy
                        ? kLightNeutralColor
                        : StatusColors.danger,
                  ),
                  onPressed: _cancellationBusy
                      ? () {}
                      : () => _respondToCancellation(approve: true),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildBottomBar({
    required String status,
    required bool isCompleted,
    required bool isDelivered,
    required bool isCancelled,
    required bool isCancellationRequested,
  }) {
    final l10n = context.l10n;
    if (isCancellationRequested) {
      return Container(
        padding: const EdgeInsets.symmetric(vertical: 4),
        child: Text(
          l10n.respondUsingBanner,
          textAlign: TextAlign.center,
          style: kTextStyle.copyWith(color: kSubTitleColor, fontSize: 13),
        ),
      );
    }

    if (isCancelled) {
      return Container(
        padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
        decoration: const BoxDecoration(color: kWhite),
        child: ButtonGlobalWithoutIcon(
          buttontext: l10n.closeAction,
          buttonDecoration: kButtonDecoration.copyWith(color: kPrimaryColor),
          onPressed: () => Navigator.pop(context),
          buttonTextColor: kWhite,
        ),
      );
    }

    if (isCompleted) {
      if (_clientHasReviewed) {
        return Container(
          decoration: const BoxDecoration(color: kWhite),
          padding: const EdgeInsets.fromLTRB(16, 14, 16, 16),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.check_circle_outline,
                  color: Colors.green.shade600, size: 22),
              const SizedBox(width: 10),
              Flexible(
                child: Text(
                  l10n.reviewSubmittedForOrder,
                  textAlign: TextAlign.center,
                  style: kTextStyle.copyWith(
                      color: kSubTitleColor, fontSize: 14, height: 1.35),
                ),
              ),
            ],
          ),
        );
      }
      return Container(
        decoration: const BoxDecoration(color: kWhite),
        padding: const EdgeInsets.fromLTRB(12, 10, 12, 16),
        child: ButtonGlobalWithoutIcon(
          buttontext: l10n.writeReviewAction,
          buttonDecoration: kButtonDecoration.copyWith(color: kPrimaryColor),
          onPressed: _openClientReviewScreen,
          buttonTextColor: kWhite,
        ),
      );
    }

    if (isDelivered) {
      return Container(
        decoration: const BoxDecoration(color: kWhite),
        padding: const EdgeInsets.fromLTRB(12, 10, 12, 16),
        child: ButtonGlobalWithoutIcon(
          buttontext: _isCompletingJob
              ? l10n.completingEllipsis
              : l10n.markJobComplete,
          buttonDecoration: kButtonDecoration.copyWith(
            color: _isCompletingJob ? kLightNeutralColor : kPrimaryColor,
          ),
          onPressed: _isCompletingJob ? () {} : _handleMarkJobComplete,
          buttonTextColor: kWhite,
        ),
      );
    }

    final isOpenContract = status == 'active' || status == 'pending';

    if (isOpenContract) {
      return Container(
        decoration: const BoxDecoration(color: kWhite),
        padding: const EdgeInsets.fromLTRB(12, 10, 12, 16),
        child: ButtonGlobalWithoutIcon(
          buttontext: l10n.waitingForDelivery,
          buttonTextColor: kWhite,
          buttonDecoration: kButtonDecoration.copyWith(color: kLightNeutralColor),
          onPressed: () {},
        ),
      );
    }

    return const SizedBox.shrink();
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Scaffold(
        backgroundColor: kDarkWhite,
        body: Center(child: CircularProgressIndicator(color: kPrimaryColor)),
      );
    }

    final l10n = context.l10n;
    final status = _statusKey();
    final isCompleted = status == 'completed';
    final isDelivered = status == 'delivered';
    final isCancelled = status == 'cancelled';
    final isCancellationRequested = status == 'cancellation_requested';

    /// Open work: active (hire / purchase) or legacy pending rows not yet migrated.
    final isOpenContract =
        (status == 'active' || status == 'pending') && !isCancellationRequested;
    final title = OrderContractDisplay.title(_order, _service);
    final description = OrderContractDisplay.serviceInfo(_order, _service);
    final durationText = OrderContractDisplay.durationLabel(_order, _service);
    final revisionText = OrderContractDisplay.revisionsLabel(_order, _service);
    final price = _order?['price'] ?? 0;
    final sellerName = _seller?['name'] ?? l10n.roleSeller;
    final orderId = widget.orderId.substring(0, 8).toUpperCase();

    /// Insets for home indicator; tab bar no longer overlaps the body.
    final bottomInset = MediaQuery.paddingOf(context).bottom + 12;
    final siteSetup = _buildSiteSetupPanel(readOnly: isCancellationRequested);
    final attendanceToday =
        isCancellationRequested ? null : _buildAttendanceTodayCard();
    final deliveries = OrderDelivery.listFromOrderMap(_order);

    return Scaffold(
      backgroundColor: kDarkWhite,
      appBar: AppBar(
        backgroundColor: kDarkWhite,
        elevation: 0,
        iconTheme: const IconThemeData(color: kNeutralColor),
        title: Text(
          l10n.orderDetailsTitle,
          style: kTextStyle.copyWith(
              color: kNeutralColor, fontWeight: FontWeight.bold),
        ),
        centerTitle: true,
        actions: [
          PopupMenuButton<String>(
            padding: EdgeInsets.zero,
            itemBuilder: (BuildContext context) => [
              PopupMenuItem(
                value: 'message',
                child: Row(
                  children: [
                    const Icon(IconlyBold.chat, color: kPrimaryColor),
                    const SizedBox(width: 5.0),
                    Text(l10n.message,
                        style: kTextStyle.copyWith(color: kNeutralColor)),
                  ],
                ),
              ),
              PopupMenuItem(
                value: 'report',
                child: Row(
                  children: [
                    const Icon(IconlyBold.document, color: Colors.red),
                    const SizedBox(width: 5.0),
                    Text(l10n.report,
                        style: kTextStyle.copyWith(color: kNeutralColor)),
                  ],
                ),
              ),
            ],
            onSelected: (value) {
              if (value == 'message') {
                _handleMessageSeller();
              } else if (value == 'report') {
                final sellerId = _seller?['id'] as String?;
                ClientReport(
                  reportedUserId: sellerId,
                  reportedUserName: _seller?['name'] as String?,
                  orderId: widget.orderId,
                ).launch(context);
              }
            },
            child: const Padding(
              padding: EdgeInsets.only(right: 10.0),
              child: Icon(Icons.more_vert_rounded, color: kNeutralColor),
            ),
          ),
        ],
      ),
      bottomNavigationBar: Material(
        color: kWhite,
        elevation: 12,
        shadowColor: Colors.black26,
        child: Padding(
          padding: EdgeInsets.only(bottom: bottomInset),
          child: _buildBottomBar(
            status: status,
            isCompleted: isCompleted,
            isDelivered: isDelivered,
            isCancelled: isCancelled,
            isCancellationRequested: isCancellationRequested,
          ),
        ),
      ),
      body: Padding(
        padding: const EdgeInsets.only(top: 15.0),
        child: Container(
          padding: const EdgeInsets.only(left: 15.0, right: 15.0),
          width: context.width(),
          decoration: const BoxDecoration(
            color: kWhite,
            borderRadius: BorderRadius.only(
              topLeft: Radius.circular(30.0),
              topRight: Radius.circular(30.0),
            ),
          ),
          child: SingleChildScrollView(
            physics: const BouncingScrollPhysics(),
            child: Column(
              children: [
                const SizedBox(height: 15.0),
                if (isCancellationRequested) ...[
                  _buildCancellationRequestBanner(sellerName),
                  const SizedBox(height: 16),
                ],
                if (deliveries.isNotEmpty) ...[
                  OrderDeliveryPanel(
                    deliveries: deliveries,
                    title: l10n.sellerSubmittedDelivery,
                    instruction:
                        isDelivered ? l10n.deliveredCalloutBody : null,
                  ),
                  const SizedBox(height: 16),
                ] else if (isDelivered) ...[
                  _buildDeliveredCallout(),
                  const SizedBox(height: 16),
                ],
                if (isOpenContract) ...[
                  _buildActiveWorkCallout(),
                  const SizedBox(height: 16),
                ],
                if (siteSetup != null) ...[
                  siteSetup,
                  const SizedBox(height: 12),
                ],
                if (attendanceToday != null) ...[
                  attendanceToday,
                  const SizedBox(height: 12),
                ],
                if (!isCancellationRequested)
                  HourReportsSection(
                    orderId: widget.orderId,
                    isEmployer: true,
                    onChanged: _loadOrder,
                  ),
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
                      Row(
                        children: [
                          Text(
                            l10n.orderIdHash(orderId),
                            style: kTextStyle.copyWith(
                                color: kNeutralColor,
                                fontWeight: FontWeight.bold),
                          ),
                          const Spacer(),
                          if (!isCancelled && !isCancellationRequested)
                            SlideCountdownSeparated(
                              duration: _getTimeRemaining(),
                              separatorType: SeparatorType.symbol,
                              separatorStyle: kTextStyle.copyWith(
                                color: Colors.transparent,
                              ),
                              decoration: BoxDecoration(
                                color: (isCompleted || isDelivered)
                                    ? const Color(0xFFBFBFBF)
                                    : kPrimaryColor,
                                borderRadius: BorderRadius.circular(3.0),
                              ),
                            ),
                        ],
                      ),
                      const SizedBox(height: 10.0),
                      RichText(
                        text: TextSpan(
                          text: '${l10n.sellerColon} ',
                          style: kTextStyle.copyWith(color: kLightNeutralColor),
                          children: [
                            TextSpan(
                                text: sellerName,
                                style:
                                    kTextStyle.copyWith(color: kNeutralColor)),
                            TextSpan(
                                text: '  |  ',
                                style: kTextStyle.copyWith(
                                    color: kLightNeutralColor)),
                            TextSpan(
                              text: _formatDate(_order?['created_at']),
                              style: kTextStyle.copyWith(
                                  color: kLightNeutralColor),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 8.0),
                      const Divider(
                          thickness: 1.0,
                          color: kBorderColorTextField,
                          height: 1.0),
                      const SizedBox(height: 8.0),
                      _buildRow(l10n.labelTitle, title, emphasizeValue: true),
                      const SizedBox(height: 8.0),
                      _buildRow(l10n.labelServiceInfo, description,
                          isExpandable: true),
                      const SizedBox(height: 8.0),
                      _buildRow(l10n.labelDuration, durationText),
                      const SizedBox(height: 8.0),
                      _buildRow(l10n.amount, '$currencySign$price'),
                      const SizedBox(height: 8.0),
                      _buildRow(l10n.labelStatus, _statusLabelForUi(status)),
                      const SizedBox(height: 15.0),
                      Text(l10n.orderDetailsTitle,
                          style: kTextStyle.copyWith(
                              color: kNeutralColor,
                              fontWeight: FontWeight.bold)),
                      const SizedBox(height: 8.0),
                      _buildRow(l10n.labelRevisions, revisionText),
                      const SizedBox(height: 15.0),
                      Text(l10n.orderSummary,
                          style: kTextStyle.copyWith(
                              color: kNeutralColor,
                              fontWeight: FontWeight.bold)),
                      const SizedBox(height: 8.0),
                      _buildRow(l10n.subtotal, '$currencySign$price'),
                      const SizedBox(height: 8.0),
                      _buildRow(l10n.labelTotal, '$currencySign$price'),
                      const SizedBox(height: 8.0),
                      _buildRow(l10n.deliveryDate,
                          _formatDate(_order?['delivery_deadline'])),
                      if (ShiftSchedule.fromOrderMap(_order).displayLabel !=
                          null) ...[
                        const SizedBox(height: 8.0),
                        _buildRow(
                          'Shift',
                          ShiftSchedule.fromOrderMap(_order).displayLabel!,
                        ),
                      ],
                    ],
                  ),
                ),
                SizedBox(height: 15.0 + bottomInset),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildRow(String label, String value,
      {bool isExpandable = false, bool emphasizeValue = false}) {
    final valueStyle = emphasizeValue
        ? kTextStyle.copyWith(
            color: kNeutralColor, fontWeight: FontWeight.w700, height: 1.35)
        : kTextStyle.copyWith(color: kSubTitleColor, height: 1.35);
    final maxLines = emphasizeValue ? 8 : 2;
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
              Text(context.l10n.labelColon, style: kTextStyle.copyWith(color: kSubTitleColor)),
              const SizedBox(width: 10.0),
              Flexible(
                child: isExpandable
                    ? ReadMoreText(
                        value,
                        style: kTextStyle.copyWith(color: kLightNeutralColor),
                        trimLines: 3,
                        colorClickableText: kPrimaryColor,
                        trimMode: TrimMode.Line,
                        trimCollapsedText: context.l10n.readMoreSuffix,
                        trimExpandedText: context.l10n.readLessSuffix,
                      )
                    : Text(
                        value,
                        style: valueStyle,
                        overflow: TextOverflow.ellipsis,
                        maxLines: maxLines,
                      ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
