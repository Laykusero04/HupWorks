import 'package:flutter/material.dart';
import 'package:flutter_iconly/flutter_iconly.dart';
import 'package:freelancer/core/utils/order_contract_display.dart';
import 'package:freelancer/screen/widgets/button_global.dart';
import 'package:freelancer/services/orders_service.dart';
import 'package:nb_utils/nb_utils.dart';
import 'package:slide_countdown/slide_countdown.dart';

import '../../seller screen/seller messgae/chat_list.dart';
import '../../widgets/constant.dart';
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
  bool _clientHasReviewed = false;

  @override
  void initState() {
    super.initState();
    _loadOrder();
  }

  Future<void> _loadOrder() async {
    try {
      final data = await OrdersService.getOrderDetails(widget.orderId);
      if (mounted) {
        setState(() {
          _order = data;
          _service = data['services'] as Map<String, dynamic>?;
          _seller = data['seller'] as Map<String, dynamic>?;
          _clientHasReviewed = OrdersService.currentUserHasReviewedOrder(data);
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error loading order: $e')),
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
    const days = ['Monday', 'Tuesday', 'Wednesday', 'Thursday', 'Friday', 'Saturday', 'Sunday'];
    const months = ['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', 'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'];
    return '${days[date.weekday - 1]}, ${date.day} ${months[date.month - 1]} ${date.year}';
  }

  Future<void> _handleCancelOrder() async {
    try {
      await OrdersService.updateOrderStatus(widget.orderId, 'cancelled');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Order cancelled')),
        );
        Navigator.pop(context);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e')),
        );
      }
    }
  }

  String _statusKey() => ((_order?['status'] as String?) ?? 'pending').toLowerCase();

  String _statusLabelForUi(String status) {
    switch (status.toLowerCase()) {
      case 'delivered':
        return 'Awaiting your approval';
      case 'active':
        return 'In progress';
      case 'pending':
        return 'Pending';
      case 'completed':
        return 'Completed';
      case 'cancelled':
        return 'Cancelled';
      default:
        if (status.isEmpty) return 'Unknown';
        return '${status[0].toUpperCase()}${status.length > 1 ? status.substring(1) : ''}';
    }
  }

  Future<void> _handleMarkJobComplete() async {
    final sellerName = _seller?['name'] ?? 'the seller';
    final deliverySubmitted = _statusKey() == 'delivered';
    final confirmed = await showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Text(
          'Mark this job complete?',
          style: kTextStyle.copyWith(color: kNeutralColor, fontWeight: FontWeight.bold),
        ),
        content: Text(
          deliverySubmitted
              ? 'You are confirming you received the work from $sellerName through their delivery submission. The contract will close as completed and you can leave a review next.'
              : 'You are about to close this contract as finished. Use this when you have received the deliverables from $sellerName (for example via chat or files), even if they have not pressed “Submit delivery” yet.',
          style: kTextStyle.copyWith(color: kSubTitleColor, height: 1.35),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: Text('Not yet', style: kTextStyle.copyWith(color: kLightNeutralColor)),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: Text('Yes, complete job', style: kTextStyle.copyWith(color: kPrimaryColor, fontWeight: FontWeight.w700)),
          ),
        ],
      ),
    );
    if (confirmed != true || !mounted) return;

    setState(() => _isCompletingJob = true);
    try {
      await OrdersService.updateOrderStatus(widget.orderId, 'completed');
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Job marked complete. Thank you!')),
      );
      await _loadOrder();
      if (!mounted) return;
      if (!_clientHasReviewed) {
        final review = await showDialog<bool>(
          context: context,
          builder: (ctx) => AlertDialog(
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
            title: Text(
              'Leave a review?',
              style: kTextStyle.copyWith(color: kNeutralColor, fontWeight: FontWeight.bold),
            ),
            content: Text(
              'Reviews help other clients and reward great work.',
              style: kTextStyle.copyWith(color: kSubTitleColor, height: 1.35),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(ctx, false),
                child: Text('Later', style: kTextStyle.copyWith(color: kLightNeutralColor)),
              ),
              TextButton(
                onPressed: () => Navigator.pop(ctx, true),
                child: Text('Write review', style: kTextStyle.copyWith(color: kPrimaryColor, fontWeight: FontWeight.w700)),
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
          SnackBar(content: Text('Could not complete job: $e')),
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
          const SnackBar(content: Text('Could not open review (missing seller).')),
        );
      }
      return;
    }
    final order = _order;
    await ClientOrderReview(
      orderId: widget.orderId,
      sellerId: sid,
      serviceId: order != null ? OrdersService.serviceIdFromOrderMap(order) : null,
      jobOfferId: order != null ? OrdersService.jobOfferIdFromOrderMap(order) : null,
      sellerName: _seller?['name'] as String?,
      sellerProfileImageUrl: _seller?['profile_image_url'] as String?,
    ).launch(context);
    if (mounted) await _loadOrder();
  }

  Widget _buildDeliveredCallout() {
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
                  'Seller submitted delivery',
                  style: kTextStyle.copyWith(color: kNeutralColor, fontWeight: FontWeight.w700),
                ),
                const SizedBox(height: 6),
                Text(
                  'Review what they sent. When you are happy with the result, tap Mark job complete below to close the order. To chat with the seller, use the ⋮ menu at the top.',
                  style: kTextStyle.copyWith(color: kSubTitleColor, fontSize: 13, height: 1.35),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildActiveWorkCallout() {
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
                  'Open contract',
                  style: kTextStyle.copyWith(color: kNeutralColor, fontWeight: FontWeight.w700),
                ),
                const SizedBox(height: 6),
                Text(
                  'When your freelancer has finished and you have the final result, tap Mark job complete below to close the contract. You can message the seller from the ⋮ menu at the top.',
                  style: kTextStyle.copyWith(color: kSubTitleColor, fontSize: 13, height: 1.35),
                ),
              ],
            ),
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
  }) {
    if (isCancelled) {
      return Container(
        padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
        decoration: const BoxDecoration(color: kWhite),
        child: ButtonGlobalWithoutIcon(
          buttontext: 'Close',
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
              Icon(Icons.check_circle_outline, color: Colors.green.shade600, size: 22),
              const SizedBox(width: 10),
              Flexible(
                child: Text(
                  'You submitted a review for this order.',
                  textAlign: TextAlign.center,
                  style: kTextStyle.copyWith(color: kSubTitleColor, fontSize: 14, height: 1.35),
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
          buttontext: 'Write review',
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
          buttontext: _isCompletingJob ? 'Completing…' : 'Mark job complete',
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
          buttontext: _isCompletingJob ? 'Completing…' : 'Mark job complete',
          buttonDecoration: kButtonDecoration.copyWith(
            color: _isCompletingJob ? kLightNeutralColor : kPrimaryColor,
          ),
          onPressed: _isCompletingJob ? () {} : _handleMarkJobComplete,
          buttonTextColor: kWhite,
        ),
      );
    }

    return Container(
      decoration: const BoxDecoration(color: kWhite),
      padding: const EdgeInsets.fromLTRB(12, 10, 12, 16),
      child: ButtonGlobalWithoutIcon(
        buttontext: _isCompletingJob ? 'Completing…' : 'Mark job complete',
        buttonDecoration: kButtonDecoration.copyWith(
          color: _isCompletingJob ? kLightNeutralColor : kPrimaryColor,
        ),
        onPressed: _isCompletingJob ? () {} : _handleMarkJobComplete,
        buttonTextColor: kWhite,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Scaffold(
        backgroundColor: kDarkWhite,
        body: Center(child: CircularProgressIndicator(color: kPrimaryColor)),
      );
    }

    final status = _statusKey();
    final isCompleted = status == 'completed';
    final isDelivered = status == 'delivered';
    final isCancelled = status == 'cancelled';
    /// New hires start as `pending` (see accept_job_offer); treat like an open job for client actions.
    final isOpenContract = status == 'active' || status == 'pending';
    final title = OrderContractDisplay.title(_order, _service);
    final description = OrderContractDisplay.serviceInfo(_order, _service);
    final durationText = OrderContractDisplay.durationLabel(_order, _service);
    final revisionText = OrderContractDisplay.revisionsLabel(_order, _service);
    final price = _order?['price'] ?? 0;
    final sellerName = _seller?['name'] ?? 'Seller';
    final orderId = widget.orderId.substring(0, 8).toUpperCase();
    /// Insets for home indicator; tab bar no longer overlaps the body.
    final bottomInset = MediaQuery.paddingOf(context).bottom + 12;

    return Scaffold(
      backgroundColor: kDarkWhite,
      appBar: AppBar(
        backgroundColor: kDarkWhite,
        elevation: 0,
        iconTheme: const IconThemeData(color: kNeutralColor),
        title: Text(
          'Order Details',
          style: kTextStyle.copyWith(color: kNeutralColor, fontWeight: FontWeight.bold),
        ),
        centerTitle: true,
        actions: [
          PopupMenuButton(
            padding: EdgeInsets.zero,
            itemBuilder: (BuildContext context) => [
              PopupMenuItem(
                child: Row(
                  children: [
                    const Icon(IconlyBold.chat, color: kPrimaryColor),
                    const SizedBox(width: 5.0),
                    Text('Message', style: kTextStyle.copyWith(color: kNeutralColor))
                        .onTap(() => const ChatScreen().launch(context)),
                  ],
                ),
              ),
              if (isOpenContract)
                PopupMenuItem(
                  child: Row(
                    children: [
                      const Icon(Icons.cancel_outlined, color: Colors.red),
                      const SizedBox(width: 5.0),
                      Text('Cancel order', style: kTextStyle.copyWith(color: Colors.red))
                          .onTap(_handleCancelOrder),
                    ],
                  ),
                ),
              PopupMenuItem(
                child: Row(
                  children: [
                    const Icon(IconlyBold.document, color: Colors.red),
                    const SizedBox(width: 5.0),
                    Text('Report', style: kTextStyle.copyWith(color: kNeutralColor)),
                  ],
                ),
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
                  if (isDelivered) ...[
                    _buildDeliveredCallout(),
                    const SizedBox(height: 16),
                  ],
                  if (isOpenContract) ...[
                    _buildActiveWorkCallout(),
                    const SizedBox(height: 16),
                  ],
                  Container(
                  padding: const EdgeInsets.all(10.0),
                  width: context.width(),
                  decoration: BoxDecoration(
                    color: kWhite,
                    borderRadius: BorderRadius.circular(8.0),
                    border: Border.all(color: kBorderColorTextField),
                    boxShadow: const [BoxShadow(color: kDarkWhite, spreadRadius: 4.0, blurRadius: 4.0, offset: Offset(0, 2))],
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Text(
                            'Order ID #$orderId',
                            style: kTextStyle.copyWith(color: kNeutralColor, fontWeight: FontWeight.bold),
                          ),
                          const Spacer(),
                          SlideCountdownSeparated(
                            duration: _getTimeRemaining(),
                            separatorType: SeparatorType.symbol,
                            separatorStyle: kTextStyle.copyWith(color: Colors.transparent),
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
                          text: 'Seller: ',
                          style: kTextStyle.copyWith(color: kLightNeutralColor),
                          children: [
                            TextSpan(text: sellerName, style: kTextStyle.copyWith(color: kNeutralColor)),
                            TextSpan(text: '  |  ', style: kTextStyle.copyWith(color: kLightNeutralColor)),
                            TextSpan(
                              text: _formatDate(_order?['created_at']),
                              style: kTextStyle.copyWith(color: kLightNeutralColor),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 8.0),
                      const Divider(thickness: 1.0, color: kBorderColorTextField, height: 1.0),
                      const SizedBox(height: 8.0),
                      _buildRow('Title', title, emphasizeValue: true),
                      const SizedBox(height: 8.0),
                      _buildRow('Service Info', description, isExpandable: true),
                      const SizedBox(height: 8.0),
                      _buildRow('Duration', durationText),
                      const SizedBox(height: 8.0),
                      _buildRow('Amount', '$currencySign$price'),
                      const SizedBox(height: 8.0),
                      _buildRow('Status', _statusLabelForUi(status)),
                      const SizedBox(height: 15.0),
                      Text('Order Details', style: kTextStyle.copyWith(color: kNeutralColor, fontWeight: FontWeight.bold)),
                      const SizedBox(height: 8.0),
                      _buildRow('Revisions', revisionText),
                      const SizedBox(height: 15.0),
                      Text('Order Summary', style: kTextStyle.copyWith(color: kNeutralColor, fontWeight: FontWeight.bold)),
                      const SizedBox(height: 8.0),
                      _buildRow('Subtotal', '$currencySign$price'),
                      const SizedBox(height: 8.0),
                      _buildRow('Total', '$currencySign$price'),
                      const SizedBox(height: 8.0),
                      _buildRow('Delivery date', _formatDate(_order?['delivery_deadline'])),
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

  Widget _buildRow(String label, String value, {bool isExpandable = false, bool emphasizeValue = false}) {
    final valueStyle = emphasizeValue
        ? kTextStyle.copyWith(color: kNeutralColor, fontWeight: FontWeight.w700, height: 1.35)
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
              Text(':', style: kTextStyle.copyWith(color: kSubTitleColor)),
              const SizedBox(width: 10.0),
              Flexible(
                child: isExpandable
                    ? ReadMoreText(
                        value,
                        style: kTextStyle.copyWith(color: kLightNeutralColor),
                        trimLines: 3,
                        colorClickableText: kPrimaryColor,
                        trimMode: TrimMode.Line,
                        trimCollapsedText: '..Read more',
                        trimExpandedText: '..Read less',
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
