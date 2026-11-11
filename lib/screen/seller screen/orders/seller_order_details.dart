import 'package:flutter/material.dart';
import 'package:freelancer/core/guide/guide_anchor.dart';
import 'package:freelancer/core/guide/guide_host.dart';
import 'package:freelancer/core/guide/guide_info_button.dart';
import 'package:freelancer/core/guide/guide_step.dart';
import 'package:freelancer/core/widgets/empty_state_widget.dart';
import 'package:freelancer/core/widgets/rubik_refresh_indicator.dart';
import 'package:freelancer/core/widgets/loading_widget.dart';
import 'package:flutter_iconly/flutter_iconly.dart';
import 'package:freelancer/l10n/l10n.dart';
import 'package:freelancer/core/utils/app_date_format.dart';
import 'package:freelancer/core/utils/order_cancellation.dart';
import 'package:freelancer/core/utils/order_chat_navigation.dart';
import 'package:freelancer/core/utils/order_contract_display.dart';
import 'package:freelancer/core/utils/shift_schedule.dart';
import 'package:freelancer/data/models/chat_order_context.dart';
import 'package:freelancer/screen/widgets/chat_preferred_contact_banner.dart';
import 'package:freelancer/data/models/hire_onboarding_packet_model.dart';
import 'package:freelancer/data/models/order_delivery_model.dart';
import 'package:freelancer/core/utils/attendance_mode.dart';
import 'package:freelancer/screen/attendance/attendance_actions_card.dart';
import 'package:freelancer/screen/onboarding/hire_onboarding_reader_screen.dart';
import 'package:freelancer/screen/widgets/order_cancellation_sheet.dart';
import 'package:freelancer/services/attendance_service.dart';
import 'package:freelancer/services/hire_onboarding_service.dart';
import 'package:freelancer/services/orders_service.dart';
import 'package:freelancer/screen/widgets/button_global.dart';
import 'package:freelancer/services/seller_orders_service.dart';
import 'package:nb_utils/nb_utils.dart';
import 'package:slide_countdown/slide_countdown.dart';

import '../../widgets/constant.dart';
import '../../widgets/hour_reports_section.dart';
import '../../widgets/order_delivery_panel.dart';
import '../../widgets/order_payment_received_card.dart';
import '../report/seller_report.dart';
import 'seller_deliver_order.dart';
import 'seller_order_review.dart';

class SellerOrderDetails extends StatefulWidget {
  final String orderId;

  const SellerOrderDetails({Key? key, required this.orderId}) : super(key: key);

  @override
  State<SellerOrderDetails> createState() => _SellerOrderDetailsState();
}

class _SellerOrderDetailsState extends State<SellerOrderDetails>
    with GuideHost<SellerOrderDetails> {
  Map<String, dynamic>? _order;
  Map<String, dynamic>? _service;
  Map<String, dynamic>? _client;
  bool _isLoading = true;
  bool _actionBusy = false;
  bool _sellerHasReviewed = false;
  HireOnboardingPacket? _onboardingPacket;
  OnsiteAttendanceJob? _attendanceJob;

  // Guide targets (long-lived; each on exactly one widget).
  final GlobalKey _guideSummaryKey = GlobalKey();
  final GlobalKey _guideOnboardKey = GlobalKey();
  final GlobalKey _guideAttendKey = GlobalKey();
  final GlobalKey _guideHoursKey = GlobalKey();
  final GlobalKey _guideDeliverKey = GlobalKey();
  final GlobalKey _guideMessageKey = GlobalKey();
  final GlobalKey _guideReportKey = GlobalKey();
  final GlobalKey _guideCancelKey = GlobalKey();
  final GlobalKey _guideDeliveryKey = GlobalKey();
  final GlobalKey _guidePaidKey = GlobalKey();
  final GlobalKey _guidePendingKey = GlobalKey();
  final GlobalKey _guideModeKey = GlobalKey();
  final GlobalKey _guideActionsKey = GlobalKey();
  final GlobalKey _guideTodayKey = GlobalKey();

  /// True after the push animation (targets at their final place).
  bool _routeSettled = false;

  /// True during every RELOAD after the first load (pull-to-refresh, return
  /// from Deliver/review/reader, attendance and hour-report `onChanged`).
  bool _reloading = false;

  @override
  String get guideScreenId => 'seller_contract_details';
  @override
  String get guideRole => 'seller';
  @override
  int get guideVersion => 1;
  @override
  bool get guideDataReady =>
      !_isLoading && !_reloading && _order != null && _routeSettled;
  @override
  String get guideSkipLabel => context.l10n.guideSkip;
  @override
  String get guideNextLabel => context.l10n.guideNext;
  @override
  String get guideDoneLabel => context.l10n.guideDone;

  GuideAnchor _anchor(GlobalKey key, String title, String desc,
          {BorderRadius? radius}) =>
      GuideAnchor(
        key: key,
        scope: guideScope,
        title: title,
        description: desc,
        borderRadius: radius,
      );

  // Targets that are not on screen for the current stage (no onboarding
  // packet, no attendance, no reports, other bottom bar) are not rendered and
  // are dropped by the runner, so the steps below are listed in full.
  @override
  List<GuideStep> buildGuideSteps(BuildContext context) {
    final l10n = context.l10n;
    return [
      GuideStep(
          key: _guideSummaryKey,
          title: l10n.guideSellerContractSummaryTitle,
          description: l10n.guideSellerContractSummaryDesc),
      GuideStep(
          key: _guideOnboardKey,
          title: l10n.guideSellerContractOnboardTitle,
          description: l10n.guideSellerContractOnboardDesc,
          enableAutoScroll: true),
      GuideStep(
          key: _guideAttendKey,
          title: l10n.guideSellerContractAttendTitle,
          description: l10n.guideSellerContractAttendDesc,
          enableAutoScroll: true),
      GuideStep(
          key: _guideHoursKey,
          title: l10n.guideSellerContractHoursTitle,
          description: l10n.guideSellerContractHoursDesc,
          enableAutoScroll: true),
      GuideStep(
          key: _guideDeliverKey,
          title: l10n.guideSellerContractDeliverTitle,
          description: l10n.guideSellerContractDeliverDesc,
          targetNearBottom: true),
    ];
  }

  @override
  List<GuideSection> buildGuideExtraSections(BuildContext context) {
    final l10n = context.l10n;
    return [
      GuideSection(
        id: 'messages',
        title: l10n.guideSellerContractSectionMessages,
        steps: [
          GuideStep(
              key: _guideMessageKey,
              title: l10n.guideSellerContractMessageTitle,
              description: l10n.guideSellerContractMessageDesc),
          GuideStep(
              key: _guideReportKey,
              title: l10n.guideSellerContractReportTitle,
              description: l10n.guideSellerContractReportDesc),
          GuideStep(
              key: _guideCancelKey,
              title: l10n.guideSellerContractCancelTitle,
              description: l10n.guideSellerContractCancelDesc,
              targetNearBottom: true),
        ],
      ),
      GuideSection(
        id: 'delivery',
        title: l10n.guideSellerContractSectionDelivery,
        steps: [
          GuideStep(
              key: _guideDeliveryKey,
              title: l10n.guideSellerContractDeliveryTitle,
              description: l10n.guideSellerContractDeliveryDesc,
              enableAutoScroll: true),
          GuideStep(
              key: _guidePaidKey,
              title: l10n.guideSellerContractPaidTitle,
              description: l10n.guideSellerContractPaidDesc,
              enableAutoScroll: true),
          GuideStep(
              key: _guidePendingKey,
              title: l10n.guideSellerContractPendingTitle,
              description: l10n.guideSellerContractPendingDesc,
              enableAutoScroll: true),
        ],
      ),
      // Same card anchors and texts as the attendance hub.
      GuideSection(
        id: 'clocking',
        title: l10n.guideAttHubSectionClocking,
        steps: [
          GuideStep(
              key: _guideModeKey,
              title: l10n.guideAttHubModeTitle,
              description: l10n.guideAttHubModeDesc,
              enableAutoScroll: true),
          GuideStep(
              key: _guideActionsKey,
              title: l10n.guideAttHubActionsTitle,
              description: l10n.guideAttHubActionsDesc,
              enableAutoScroll: true),
          GuideStep(
              key: _guideTodayKey,
              title: l10n.guideAttHubTodayTitle,
              description: l10n.guideAttHubTodayDesc,
              enableAutoScroll: true),
        ],
      ),
    ];
  }

  void _awaitRouteSettled() {
    if (!mounted) return;
    final anim = ModalRoute.of(context)?.animation;
    if (anim == null || anim.isCompleted) {
      _settleRoute();
      return;
    }
    void listener(AnimationStatus st) {
      if (st == AnimationStatus.completed) {
        anim.removeStatusListener(listener);
        _settleRoute();
      }
    }

    anim.addStatusListener(listener);
  }

  void _settleRoute() {
    if (!mounted) return;
    setState(() => _routeSettled = true);
    scheduleGuide();
  }

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _awaitRouteSettled());
    _loadOrder();
  }

  Future<void> _loadOrder() async {
    // A reload (not the first load) keeps the body but must tear a running
    // guide down; it restarts once the data is back.
    if (mounted && !_isLoading && !_reloading) {
      setState(() => _reloading = true);
    }
    try {
      await OrdersService.expireStaleCancellationRequests();
      final data = await SellerOrdersService.getOrderDetails(widget.orderId);
      HireOnboardingPacket? packet;
      if (OrdersService.jobOfferIdFromOrderMap(data) != null) {
        packet = await HireOnboardingService.getPacketForOrder(
          widget.orderId,
          sellerView: true,
        );
      }
      OnsiteAttendanceJob? attJob;
      final jobs = await AttendanceService.getMyOnsiteAttendanceJobs();
      for (final j in jobs) {
        if (j.orderId == widget.orderId) {
          attJob = j;
          break;
        }
      }
      if (mounted) {
        setState(() {
          _order = data;
          _service = data['services'] as Map<String, dynamic>?;
          _client = data['client'] as Map<String, dynamic>?;
          _sellerHasReviewed = OrdersService.currentUserHasReviewedOrder(data);
          _onboardingPacket = packet;
          _attendanceJob = attJob;
          _isLoading = false;
          _reloading = false;
        });
        scheduleGuide();
      }
    } catch (e) {
      if (mounted) {
        final keepExisting = _order != null;
        setState(() {
          _isLoading = false;
          _reloading = false;
        });
        scheduleGuide();
        if (keepExisting) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(context.l10n.errorWithDetail('$e'))),
          );
        }
      }
    }
  }

  Duration _getTimeRemaining() {
    final deadline = _order?['delivery_deadline'];
    if (deadline == null) return Duration.zero;
    final d = DateTime.tryParse(deadline);
    if (d == null) return Duration.zero;
    final r = d.difference(DateTime.now());
    return r.isNegative ? Duration.zero : r;
  }

  String _formatDate(String? s) {
    final d = DateTime.tryParse(s ?? '');
    if (d == null) return '';
    return AppDateFormat.eeeeDMmmY(d, AppDateFormat.localeOf(context));
  }

  Future<void> _requestCancellation() async {
    var reasonCode = '';
    var reasonNote = '';
    final submitted = await OrderCancellationSheet.show(
      context,
      onSubmit: (code, note) async {
        await SellerOrdersService.requestCancellation(
          orderId: widget.orderId,
          reasonCode: code,
          reasonNote: note,
        );
        reasonCode = code;
        reasonNote = note;
      },
    );
    if (!submitted || !mounted) return;

    setState(() => _actionBusy = true);
    try {
      final clientId = _order?['client_id']?.toString();
      if (clientId != null && clientId.isNotEmpty) {
        await SellerOrdersService.notifyClientCancellationRequest(
          orderId: widget.orderId,
          clientId: clientId,
          reasonCode: reasonCode,
          reasonNote: reasonNote,
        );
      }
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(context.l10n.cancellationRequestSent48h),
          ),
        );
        await _loadOrder();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(context.l10n.errorWithDetail('$e'))),
        );
      }
    } finally {
      if (mounted) setState(() => _actionBusy = false);
    }
  }

  Future<void> _withdrawCancellation() async {
    final l10n = context.l10n;
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(l10n.withdrawCancellationTitle),
        content: Text(l10n.withdrawCancellationConfirmBody),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: Text(l10n.cancel),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: Text(l10n.withdrawCancelRequest),
          ),
        ],
      ),
    );
    if (confirmed != true || !mounted) return;

    setState(() => _actionBusy = true);
    try {
      await SellerOrdersService.withdrawCancellation(widget.orderId);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(context.l10n.cancellationRequestWithdrawn)),
        );
        await _loadOrder();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(context.l10n.errorWithDetail('$e'))),
        );
      }
    } finally {
      if (mounted) setState(() => _actionBusy = false);
    }
  }

  Future<void> _openSellerReviewScreen() async {
    final clientId = (_client?['id'] ?? _order?['client_id'])?.toString();
    if (clientId == null || clientId.isEmpty) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
              content: Text(context.l10n.errorWithDetail('Missing client'))),
        );
      }
      return;
    }
    final order = _order;
    await SellerOrderReview(
      orderId: widget.orderId,
      clientId: clientId,
      serviceId:
          order != null ? OrdersService.serviceIdFromOrderMap(order) : null,
      jobOfferId:
          order != null ? OrdersService.jobOfferIdFromOrderMap(order) : null,
      clientName: _client?['name'] as String?,
      clientProfileImageUrl: _client?['profile_image_url'] as String?,
    ).launch(context);
    if (mounted) await _loadOrder();
  }

  ChatOrderContext _chatOrderContext() {
    final status = ((_order?['status'] as String?) ?? 'pending').toLowerCase();
    final preferred = preferredContactFromOrder(_order ?? {});
    return ChatOrderContext(
      orderId: widget.orderId,
      title: OrderContractDisplay.title(_order, _service),
      statusLabel: OrderCancellationReason.statusLabel(status, context.l10n),
      deadlineLabel: _formatDate(_order?['delivery_deadline']),
      preferredContactLabel: preferred.label,
      isWithinPreferredWindow: preferred.inWindow,
      isClientViewer: false,
    );
  }

  Future<void> _handleMessageClient() async {
    final clientId = (_client?['id'] ?? _order?['client_id'])?.toString();
    if (clientId == null || clientId.isEmpty) return;
    await openOrderChat(
      context,
      otherUserId: clientId,
      otherUserName: _client?['name'] as String? ?? context.l10n.roleClient,
      otherUserImage: _client?['profile_image_url'] as String? ?? '',
      orderContext: _chatOrderContext(),
    );
  }

  Widget _buildBottomBar({
    required String status,
    required bool isCompleted,
    required bool isDelivered,
    required bool isCancelled,
    required bool isCancellationRequested,
    required bool canRequestCancel,
    required double bottomInset,
  }) {
    final l10n = context.l10n;
    if (isCancelled) {
      return ButtonGlobalWithoutIcon(
        buttontext: l10n.closeAction,
        buttonDecoration: kButtonDecoration.copyWith(color: kPrimaryColor),
        onPressed: () => Navigator.pop(context),
        buttonTextColor: kWhite,
      );
    }

    if (isCancellationRequested) {
      return ButtonGlobalWithoutIcon(
        buttontext:
            _actionBusy ? l10n.withdrawingEllipsis : l10n.withdrawCancelRequest,
        buttonTextColor: kNeutralColor,
        buttonDecoration: kButtonDecoration.copyWith(
          color: kWhite,
          border: Border.all(color: kBorderColorTextField),
        ),
        onPressed: _actionBusy ? () {} : _withdrawCancellation,
      );
    }

    if (isCompleted) {
      if (_sellerHasReviewed) {
        return ButtonGlobalWithoutIcon(
          buttontext: l10n.reviewSubmittedForOrder,
          buttonTextColor: kWhite,
          buttonDecoration:
              kButtonDecoration.copyWith(color: kLightNeutralColor),
          onPressed: () {},
        );
      }
      return ButtonGlobalWithoutIcon(
        buttontext: l10n.writeReviewAction,
        buttonTextColor: kWhite,
        buttonDecoration: kButtonDecoration.copyWith(color: kPrimaryColor),
        onPressed: _openSellerReviewScreen,
      );
    }

    if (isDelivered) {
      return ButtonGlobalWithoutIcon(
        buttontext: l10n.waitingForClientApproval,
        buttonTextColor: kWhite,
        buttonDecoration: kButtonDecoration.copyWith(color: kLightNeutralColor),
        onPressed: () {},
      );
    }

    return Row(
      children: [
        if (canRequestCancel)
          Expanded(
            child: ButtonGlobalWithoutIcon(
              guideAnchor: _anchor(
                  _guideCancelKey,
                  l10n.guideSellerContractCancelTitle,
                  l10n.guideSellerContractCancelDesc,
                  radius: BorderRadius.circular(8)),
              buttontext: l10n.requestCancel,
              buttonTextColor: Colors.red,
              buttonDecoration: kButtonDecoration.copyWith(
                color: kWhite,
                border: Border.all(color: Colors.red),
              ),
              onPressed: _actionBusy ? () {} : _requestCancellation,
            ),
          ),
        if (canRequestCancel) const SizedBox(width: 8),
        Expanded(
          child: ButtonGlobalWithoutIcon(
            guideAnchor: _anchor(
                _guideDeliverKey,
                l10n.guideSellerContractDeliverTitle,
                l10n.guideSellerContractDeliverDesc,
                radius: BorderRadius.circular(8)),
            buttontext: l10n.deliverWork,
            buttonTextColor: kWhite,
            buttonDecoration: kButtonDecoration.copyWith(
              color: _actionBusy ? kLightNeutralColor : kPrimaryColor,
            ),
            onPressed: _actionBusy
                ? null
                : () async {
                    await SellerDeliverOrder(orderId: widget.orderId)
                        .launch(context);
                    _loadOrder();
                  },
          ),
        ),
      ],
    );
  }

  Widget _buildCancellationPendingBanner() {
    final l10n = context.l10n;
    final code = _order?['cancellation_reason_code'] as String?;
    final note = _order?['cancellation_reason_note'] as String?;
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: StatusColors.warningBg,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: StatusColors.warning.withValues(alpha: 0.4)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.hourglass_top,
                  color: StatusColors.warning, size: 22),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  l10n.waitingForClientResponse,
                  style: kTextStyle.copyWith(
                    color: kNeutralColor,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          Text(
            l10n.sellerCancellationPendingBody,
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
                fontSize: 13,
                fontWeight: FontWeight.w600,
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
        ],
      ),
    );
  }

  Widget _buildCancelledSummary() {
    final l10n = context.l10n;
    final code = _order?['cancellation_reason_code'] as String?;
    final note = _order?['cancellation_reason_note'] as String?;
    final at = _order?['cancelled_at'] as String?;
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: StatusColors.dangerBg,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: StatusColors.danger.withValues(alpha: 0.35)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            l10n.contractCancelledTitle,
            style: kTextStyle.copyWith(
              color: StatusColors.danger,
              fontWeight: FontWeight.bold,
            ),
          ),
          if (at != null) ...[
            const SizedBox(height: 4),
            Text(
              _formatDate(at),
              style: kTextStyle.copyWith(color: kSubTitleColor, fontSize: 12),
            ),
          ],
          if (code != null) ...[
            const SizedBox(height: 8),
            Text(
              OrderCancellationReason.label(code, l10n),
              style: kTextStyle.copyWith(
                color: kNeutralColor,
                fontSize: 13,
                fontWeight: FontWeight.w600,
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
        ],
      ),
    );
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

    if (_order == null) {
      return Scaffold(
        backgroundColor: kDarkWhite,
        appBar: AppBar(
          backgroundColor: kDarkWhite,
          elevation: 0,
          iconTheme: const IconThemeData(color: kNeutralColor),
          title: Text(
            l10n.orderDetailsTitle,
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
            _loadOrder();
          },
        ),
      );
    }

    final status = ((_order?['status'] as String?) ?? 'pending').toLowerCase();
    final isCompleted = status == 'completed';
    final isDelivered = status == 'delivered';
    final isCancelled = status == 'cancelled';
    final isCancellationRequested = status == 'cancellation_requested';
    final canRequestCancel = status == 'pending' || status == 'active';
    final isReadOnlyContract =
        isCancelled || isCancellationRequested || isCompleted;

    final title = OrderContractDisplay.title(_order, _service);
    final description = OrderContractDisplay.serviceInfo(_order, _service);
    final durationText = OrderContractDisplay.durationLabel(_order, _service);
    final revisionText = OrderContractDisplay.revisionsLabel(_order, _service);
    final price = _order?['price'] ?? 0;
    final clientName = _client?['name'] ?? l10n.roleClient;
    final orderId = widget.orderId.substring(0, 8).toUpperCase();
    final bottomInset = MediaQuery.paddingOf(context).bottom + 12;
    final jobPost = OrderContractDisplay.jobPostFromOrder(_order);
    final jobPostId = OrderContractDisplay.jobPostIdFromOrder(_order);
    final isOnsiteJobOffer =
        OrdersService.jobOfferIdFromOrderMap(_order ?? {}) != null &&
            AttendanceService.isOnsiteJob(jobPost);
    final showAttendance = isOnsiteJobOffer &&
        jobPostId != null &&
        !isReadOnlyContract &&
        AttendanceMode.isEnabled(AttendanceMode.effectiveForJobPost(jobPost));
    final deliveries = OrderDelivery.listFromOrderMap(_order);

    return guideBackScope(Scaffold(
      backgroundColor: kDarkWhite,
      appBar: AppBar(
        backgroundColor: kDarkWhite,
        elevation: 0,
        iconTheme: const IconThemeData(color: kNeutralColor),
        title: Text(
          l10n.orderDetailsTitle,
          style: kTextStyle.copyWith(
            color: kNeutralColor,
            fontWeight: FontWeight.bold,
          ),
        ),
        centerTitle: true,
        actions: [
          GuideInfoButton(host: this),
          if ((_client?['id'] ?? _order?['client_id']) != null)
            GuideAnchor.wrap(
              _anchor(_guideMessageKey, l10n.guideSellerContractMessageTitle,
                  l10n.guideSellerContractMessageDesc,
                  radius: BorderRadius.circular(24)),
              IconButton(
                tooltip: l10n.message,
                onPressed: _handleMessageClient,
                icon: const Icon(IconlyBold.chat, color: kPrimaryColor),
              ),
            ),
          if ((_client?['id'] ?? _order?['client_id']) != null)
            GuideAnchor.wrap(
              _anchor(_guideReportKey, l10n.guideSellerContractReportTitle,
                  l10n.guideSellerContractReportDesc,
                  radius: BorderRadius.circular(24)),
              IconButton(
                tooltip: l10n.report,
                onPressed: () {
                  final clientId =
                      (_client?['id'] ?? _order?['client_id'])?.toString();
                  SellerReport(
                    reportedUserId: clientId,
                    reportedUserName: _client?['name'] as String?,
                    orderId: widget.orderId,
                    jobPostId: jobPostId,
                    jobTitle: jobPost?['title'] as String?,
                  ).launch(context);
                },
                icon: const Icon(Icons.flag_outlined, color: kNeutralColor),
              ),
            ),
        ],
      ),
      bottomNavigationBar: Material(
        color: kWhite,
        elevation: 12,
        shadowColor: Colors.black26,
        child: Padding(
          padding: EdgeInsets.only(
              bottom: bottomInset, left: 12, right: 12, top: 10),
          child: _buildBottomBar(
            status: status,
            isCompleted: isCompleted,
            isDelivered: isDelivered,
            isCancelled: isCancelled,
            isCancellationRequested: isCancellationRequested,
            canRequestCancel: canRequestCancel,
            bottomInset: bottomInset,
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
          child: RubikRefreshIndicator(
            onRefresh: _loadOrder,
            child: SingleChildScrollView(
              physics: const AlwaysScrollableScrollPhysics(
                parent: BouncingScrollPhysics(),
              ),
              child: Column(
                children: [
                  const SizedBox(height: 15.0),
                  if (isCancellationRequested) ...[
                    GuideAnchor.wrap(
                      _anchor(
                          _guidePendingKey,
                          l10n.guideSellerContractPendingTitle,
                          l10n.guideSellerContractPendingDesc,
                          radius: BorderRadius.circular(12)),
                      _buildCancellationPendingBanner(),
                    ),
                    const SizedBox(height: 12),
                  ],
                  if (isCancelled) ...[
                    _buildCancelledSummary(),
                    const SizedBox(height: 12),
                  ],
                  if (isCompleted) ...[
                    OrderPaymentReceivedCard(
                      guideAnchor: _anchor(
                          _guidePaidKey,
                          l10n.guideSellerContractPaidTitle,
                          l10n.guideSellerContractPaidDesc,
                          radius: BorderRadius.circular(12)),
                      orderId: widget.orderId,
                      order: _order,
                      isSellerView: true,
                      onChanged: _loadOrder,
                    ),
                    const SizedBox(height: 12),
                  ],
                  if (deliveries.isNotEmpty) ...[
                    OrderDeliveryPanel(
                      guideAnchor: _anchor(
                          _guideDeliveryKey,
                          l10n.guideSellerContractDeliveryTitle,
                          l10n.guideSellerContractDeliveryDesc,
                          radius: BorderRadius.circular(12)),
                      deliveries: deliveries,
                      title: l10n.yourDelivery,
                    ),
                    const SizedBox(height: 12),
                  ],
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
                          offset: Offset(0, 2),
                        ),
                      ],
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        GuideAnchor.wrap(
                          _anchor(
                              _guideSummaryKey,
                              l10n.guideSellerContractSummaryTitle,
                              l10n.guideSellerContractSummaryDesc,
                              radius: BorderRadius.circular(8)),
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  Text(
                                    l10n.orderIdHash(orderId),
                                    style: kTextStyle.copyWith(
                                      color: kNeutralColor,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                  const Spacer(),
                                  if (!isCancelled && !isCancellationRequested)
                                    SlideCountdownSeparated(
                                      duration: _getTimeRemaining(),
                                      separatorType: SeparatorType.symbol,
                                      separatorStyle: kTextStyle.copyWith(
                                          color: Colors.transparent),
                                      decoration: BoxDecoration(
                                        color: isCompleted
                                            ? const Color(0xFFBFBFBF)
                                            : kPrimaryColor,
                                        borderRadius:
                                            BorderRadius.circular(3.0),
                                      ),
                                    ),
                                ],
                              ),
                              const SizedBox(height: 10.0),
                              RichText(
                                text: TextSpan(
                                  text: '${l10n.clientColon} ',
                                  style: kTextStyle.copyWith(
                                      color: kLightNeutralColor),
                                  children: [
                                    TextSpan(
                                      text: clientName,
                                      style: kTextStyle.copyWith(
                                          color: kNeutralColor),
                                    ),
                                    TextSpan(
                                      text: '  |  ',
                                      style: kTextStyle.copyWith(
                                          color: kLightNeutralColor),
                                    ),
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
                                height: 1.0,
                              ),
                              const SizedBox(height: 8.0),
                              _row(l10n.labelTitle, title,
                                  emphasizeValue: true),
                              const SizedBox(height: 8.0),
                              _rowExpand(l10n.labelServiceInfo, description),
                              const SizedBox(height: 8.0),
                              _row(l10n.labelDuration, durationText),
                              const SizedBox(height: 8.0),
                              _row(l10n.amount, '$currencySign$price'),
                              const SizedBox(height: 8.0),
                              _row(
                                l10n.labelStatus,
                                OrderCancellationReason.statusLabel(
                                    status, l10n),
                              ),
                              const SizedBox(height: 15.0),
                              Text(
                                l10n.orderDetailsTitle,
                                style: kTextStyle.copyWith(
                                  color: kNeutralColor,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              const SizedBox(height: 8.0),
                              _row(l10n.labelRevisions, revisionText),
                              const SizedBox(height: 15.0),
                              Text(
                                l10n.orderSummary,
                                style: kTextStyle.copyWith(
                                  color: kNeutralColor,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              const SizedBox(height: 8.0),
                              _row(l10n.labelTotal, '$currencySign$price'),
                              const SizedBox(height: 8.0),
                              _row(
                                l10n.deliveryDate,
                                _formatDate(_order?['delivery_deadline']),
                              ),
                              if (ShiftSchedule.fromOrderMap(_order)
                                      .displayLabel !=
                                  null) ...[
                                const SizedBox(height: 8.0),
                                _row(
                                  l10n.shiftLabel,
                                  ShiftSchedule.fromOrderMap(_order)
                                      .displayLabel!,
                                ),
                              ],
                            ],
                          ),
                        ),
                        if (OrdersService.jobOfferIdFromOrderMap(
                                    _order ?? {}) !=
                                null &&
                            !isReadOnlyContract) ...[
                          const SizedBox(height: 16),
                          _buildOnboardingBanner(),
                        ],
                        if (showAttendance) ...[
                          const SizedBox(height: 16),
                          AttendanceActionsCard(
                            guideAnchor: _anchor(
                                _guideAttendKey,
                                l10n.guideSellerContractAttendTitle,
                                l10n.guideSellerContractAttendDesc,
                                radius: BorderRadius.circular(10)),
                            modeAnchor: _anchor(
                                _guideModeKey,
                                l10n.guideAttHubModeTitle,
                                l10n.guideAttHubModeDesc),
                            actionsAnchor: _anchor(
                                _guideActionsKey,
                                l10n.guideAttHubActionsTitle,
                                l10n.guideAttHubActionsDesc,
                                radius: BorderRadius.circular(8)),
                            todayAnchor: _anchor(
                                _guideTodayKey,
                                l10n.guideAttHubTodayTitle,
                                l10n.guideAttHubTodayDesc),
                            orderId: widget.orderId,
                            jobPostId: jobPostId,
                            attendanceMode: _attendanceJob?.attendanceMode ??
                                AttendanceMode.effectiveForJobPost(jobPost),
                            isClockedIn: _attendanceJob?.isClockedIn ?? false,
                            checkedInToday:
                                _attendanceJob?.checkedInToday ?? false,
                            statusLabel: _attendanceJob?.statusLabel,
                            onChanged: _loadOrder,
                          ),
                        ],
                        if (!isReadOnlyContract)
                          HourReportsSection(
                            guideAnchor: _anchor(
                                _guideHoursKey,
                                l10n.guideSellerContractHoursTitle,
                                l10n.guideSellerContractHoursDesc,
                                radius: BorderRadius.circular(12)),
                            orderId: widget.orderId,
                            isEmployer: false,
                            onChanged: _loadOrder,
                          ),
                        SizedBox(height: 15.0 + bottomInset),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    ));
  }

  Future<void> _openOnboardingReader() async {
    final jobPost = OrderContractDisplay.jobPostFromOrder(_order);
    final result = await HireOnboardingReaderScreen(
      orderId: widget.orderId,
      jobPost: jobPost,
    ).launch(context);
    if (mounted && result == true) await _loadOrder();
  }

  Widget _buildOnboardingBanner() {
    final l10n = context.l10n;
    final packet = _onboardingPacket;
    if (packet == null || !packet.isPublished) return const SizedBox.shrink();

    if (packet.acknowledged) {
      return Align(
        alignment: Alignment.centerLeft,
        child: TextButton.icon(
          onPressed: _openOnboardingReader,
          icon: const Icon(
            Icons.menu_book_outlined,
            size: 18,
            color: kPrimaryColor,
          ),
          label: Text(
            l10n.viewFirstDayInstructions,
            style: kTextStyle.copyWith(
              color: kPrimaryColor,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
      );
    }

    return GuideAnchor.wrap(
      _anchor(_guideOnboardKey, l10n.guideSellerContractOnboardTitle,
          l10n.guideSellerContractOnboardDesc,
          radius: BorderRadius.circular(12)),
      _buildOnboardingUnread(),
    );
  }

  Widget _buildOnboardingUnread() {
    final l10n = context.l10n;
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: const Color(0xFFE8F5E9),
        borderRadius: BorderRadius.circular(12),
        border:
            Border.all(color: const Color(0xFF2E7D32).withValues(alpha: 0.35)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.info_outline,
                  color: Color(0xFF2E7D32), size: 22),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  l10n.readFirstDayInstructions,
                  style: kTextStyle.copyWith(
                    color: kNeutralColor,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          Text(
            l10n.firstDayInstructionsSharedBody,
            style: kTextStyle.copyWith(
              color: kSubTitleColor,
              fontSize: 13,
              height: 1.35,
            ),
          ),
          const SizedBox(height: 10),
          ButtonGlobalWithoutIcon(
            buttontext: l10n.openInstructions,
            buttonDecoration: kButtonDecoration.copyWith(
              color: const Color(0xFF2E7D32),
            ),
            onPressed: _openOnboardingReader,
            buttonTextColor: kWhite,
          ),
        ],
      ),
    );
  }

  Widget _row(String l, String v, {bool emphasizeValue = false}) => Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            flex: 2,
            child: Text(l, style: kTextStyle.copyWith(color: kSubTitleColor)),
          ),
          Expanded(
            flex: 4,
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(context.l10n.labelColon,
                    style: kTextStyle.copyWith(color: kSubTitleColor)),
                const SizedBox(width: 10.0),
                Flexible(
                  child: Text(
                    v,
                    style: emphasizeValue
                        ? kTextStyle.copyWith(
                            color: kNeutralColor,
                            fontWeight: FontWeight.w700,
                            height: 1.35,
                          )
                        : kTextStyle.copyWith(
                            color: kSubTitleColor,
                            height: 1.35,
                          ),
                    overflow: TextOverflow.ellipsis,
                    maxLines: emphasizeValue ? 8 : 2,
                  ),
                ),
              ],
            ),
          ),
        ],
      );

  Widget _rowExpand(String l, String v) => Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            flex: 2,
            child: Text(l, style: kTextStyle.copyWith(color: kSubTitleColor)),
          ),
          Expanded(
            flex: 4,
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(context.l10n.labelColon,
                    style: kTextStyle.copyWith(color: kSubTitleColor)),
                const SizedBox(width: 10.0),
                Flexible(
                  child: ReadMoreText(
                    v,
                    style: kTextStyle.copyWith(color: kLightNeutralColor),
                    trimLines: 3,
                    colorClickableText: kPrimaryColor,
                    trimMode: TrimMode.Line,
                    trimCollapsedText: context.l10n.readMoreSuffix,
                    trimExpandedText: context.l10n.readLessSuffix,
                  ),
                ),
              ],
            ),
          ),
        ],
      );
}
