import 'package:flutter/material.dart';
import 'package:flutter_iconly/flutter_iconly.dart';
import 'package:freelancer/l10n/l10n.dart';
import 'package:freelancer/core/utils/order_cancellation.dart';
import 'package:freelancer/core/utils/order_chat_navigation.dart';
import 'package:freelancer/core/utils/order_contract_display.dart';
import 'package:freelancer/data/models/chat_order_context.dart';
import 'package:freelancer/data/models/hire_onboarding_packet_model.dart';
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
import '../report/seller_report.dart';
import 'seller_deliver_order.dart';

class SellerOrderDetails extends StatefulWidget {
  final String orderId;

  const SellerOrderDetails({Key? key, required this.orderId}) : super(key: key);

  @override
  State<SellerOrderDetails> createState() => _SellerOrderDetailsState();
}

class _SellerOrderDetailsState extends State<SellerOrderDetails> {
  Map<String, dynamic>? _order;
  Map<String, dynamic>? _service;
  Map<String, dynamic>? _client;
  bool _isLoading = true;
  bool _actionBusy = false;
  HireOnboardingPacket? _onboardingPacket;
  OnsiteAttendanceJob? _attendanceJob;

  @override
  void initState() {
    super.initState();
    _loadOrder();
  }

  Future<void> _loadOrder() async {
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
          _onboardingPacket = packet;
          _attendanceJob = attJob;
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

  Duration _getTimeRemaining() {
    final deadline = _order?['delivery_deadline'];
    if (deadline == null) return Duration.zero;
    final d = DateTime.tryParse(deadline);
    if (d == null) return Duration.zero;
    final r = d.difference(DateTime.now());
    return r.isNegative ? Duration.zero : r;
  }

  String _formatDate(String? s) {
    if (s == null) return '';
    final d = DateTime.tryParse(s);
    if (d == null) return '';
    const days = [
      'Monday',
      'Tuesday',
      'Wednesday',
      'Thursday',
      'Friday',
      'Saturday',
      'Sunday',
    ];
    const m = [
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
      'Dec',
    ];
    return '${days[d.weekday - 1]}, ${d.day} ${m[d.month - 1]} ${d.year}';
  }

  Future<void> _requestCancellation() async {
    final result = await OrderCancellationSheet.show(context);
    if (result == null || !mounted) return;

    setState(() => _actionBusy = true);
    try {
      await SellerOrdersService.requestCancellation(
        orderId: widget.orderId,
        reasonCode: result.reasonCode,
        reasonNote: result.reasonNote,
      );
      final clientId = _order?['client_id']?.toString();
      if (clientId != null && clientId.isNotEmpty) {
        await SellerOrdersService.notifyClientCancellationRequest(
          orderId: widget.orderId,
          clientId: clientId,
          reasonCode: result.reasonCode,
          reasonNote: result.reasonNote,
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

  Future<void> _handleComplete() async {
    try {
      await SellerOrdersService.updateOrderStatus(widget.orderId, 'completed');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(context.l10n.orderMarkedComplete)),
        );
        Navigator.pop(context);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(context.l10n.errorWithDetail('$e'))),
        );
      }
    }
  }

  ChatOrderContext _chatOrderContext() {
    final status = ((_order?['status'] as String?) ?? 'pending').toLowerCase();
    return ChatOrderContext(
      orderId: widget.orderId,
      title: OrderContractDisplay.title(_order, _service),
      statusLabel: OrderCancellationReason.statusLabel(status, context.l10n),
      deadlineLabel: _formatDate(_order?['delivery_deadline']),
      isClientViewer: false,
    );
  }

  Future<void> _handleMessageClient() async {
    final clientId =
        (_client?['id'] ?? _order?['client_id'])?.toString();
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
        buttontext: _actionBusy
            ? l10n.withdrawingEllipsis
            : l10n.withdrawCancelRequest,
        buttonTextColor: kNeutralColor,
        buttonDecoration: kButtonDecoration.copyWith(
          color: kWhite,
          border: Border.all(color: kBorderColorTextField),
        ),
        onPressed: _actionBusy ? () {} : _withdrawCancellation,
      );
    }

    if (isCompleted) {
      return ButtonGlobalWithoutIcon(
        buttontext: l10n.orderStatusCompleted,
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
            buttontext:
                isDelivered ? l10n.completeOrder : l10n.deliverWork,
            buttonTextColor: kWhite,
            buttonDecoration: kButtonDecoration.copyWith(
              color: kPrimaryColor,
            ),
            onPressed: isDelivered
                ? _handleComplete
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
              const Icon(Icons.hourglass_top, color: StatusColors.warning, size: 22),
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
        body: Center(child: CircularProgressIndicator(color: kPrimaryColor)),
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
        actions: [
          if ((_client?['id'] ?? _order?['client_id']) != null)
            IconButton(
              tooltip: l10n.message,
              onPressed: _handleMessageClient,
              icon: const Icon(IconlyBold.chat, color: kPrimaryColor),
            ),
          if ((_client?['id'] ?? _order?['client_id']) != null)
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
        ],
      ),
      bottomNavigationBar: Material(
        color: kWhite,
        elevation: 12,
        shadowColor: Colors.black26,
        child: Padding(
          padding: EdgeInsets.only(bottom: bottomInset, left: 12, right: 12, top: 10),
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
          child: SingleChildScrollView(
            physics: const BouncingScrollPhysics(),
            child: Column(
              children: [
                const SizedBox(height: 15.0),
                if (isCancellationRequested) ...[
                  _buildCancellationPendingBanner(),
                  const SizedBox(height: 12),
                ],
                if (isCancelled) ...[
                  _buildCancelledSummary(),
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
                              separatorStyle:
                                  kTextStyle.copyWith(color: Colors.transparent),
                              decoration: BoxDecoration(
                                color: isCompleted
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
                          text: '${l10n.clientColon} ',
                          style: kTextStyle.copyWith(color: kLightNeutralColor),
                          children: [
                            TextSpan(
                              text: clientName,
                              style: kTextStyle.copyWith(color: kNeutralColor),
                            ),
                            TextSpan(
                              text: '  |  ',
                              style: kTextStyle.copyWith(color: kLightNeutralColor),
                            ),
                            TextSpan(
                              text: _formatDate(_order?['created_at']),
                              style:
                                  kTextStyle.copyWith(color: kLightNeutralColor),
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
                      _row(l10n.labelTitle, title, emphasizeValue: true),
                      const SizedBox(height: 8.0),
                      _rowExpand(l10n.labelServiceInfo, description),
                      const SizedBox(height: 8.0),
                      _row(l10n.labelDuration, durationText),
                      const SizedBox(height: 8.0),
                      _row(l10n.amount, '$currencySign$price'),
                      const SizedBox(height: 8.0),
                      _row(
                        l10n.labelStatus,
                        OrderCancellationReason.statusLabel(status, l10n),
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
                      if (OrdersService.jobOfferIdFromOrderMap(_order ?? {}) !=
                              null &&
                          !isReadOnlyContract) ...[
                        const SizedBox(height: 16),
                        _buildOnboardingBanner(),
                      ],
                      if (showAttendance) ...[
                        const SizedBox(height: 16),
                        AttendanceActionsCard(
                          orderId: widget.orderId,
                          jobPostId: jobPostId,
                          attendanceMode: _attendanceJob?.attendanceMode ??
                              AttendanceMode.effectiveForJobPost(jobPost),
                          isClockedIn: _attendanceJob?.isClockedIn ?? false,
                          checkedInToday: _attendanceJob?.checkedInToday ?? false,
                          statusLabel: _attendanceJob?.statusLabel,
                          onChanged: _loadOrder,
                        ),
                      ],
                      SizedBox(height: 15.0 + bottomInset),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
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

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: const Color(0xFFE8F5E9),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFF2E7D32).withValues(alpha: 0.35)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.info_outline, color: Color(0xFF2E7D32), size: 22),
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
                Text(context.l10n.labelColon, style: kTextStyle.copyWith(color: kSubTitleColor)),
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
                Text(context.l10n.labelColon, style: kTextStyle.copyWith(color: kSubTitleColor)),
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
