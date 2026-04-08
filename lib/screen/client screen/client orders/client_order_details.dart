import 'package:flutter/material.dart';
import 'package:flutter_iconly/flutter_iconly.dart';
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

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Scaffold(
        backgroundColor: kDarkWhite,
        body: Center(child: CircularProgressIndicator(color: kPrimaryColor)),
      );
    }

    final status = _order?['status'] ?? 'pending';
    final isCompleted = status == 'completed';
    final title = _service?['title'] ?? 'Service';
    final description = _service?['description'] ?? '';
    final price = _order?['price'] ?? 0;
    final deliveryTime = _service?['delivery_time'] ?? 0;
    final revisionCount = _service?['revision_count'] ?? 0;
    final sellerName = _seller?['name'] ?? 'Seller';
    final orderId = widget.orderId.substring(0, 8).toUpperCase();

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
      bottomNavigationBar: Container(
        decoration: const BoxDecoration(color: kWhite),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Expanded(
              child: ButtonGlobalWithoutIcon(
                buttontext: isCompleted ? 'Re-Order' : 'Cancel',
                buttonDecoration: kButtonDecoration.copyWith(
                  color: isCompleted ? kPrimaryColor : kWhite,
                  border: Border.all(color: isCompleted ? Colors.transparent : Colors.red),
                ),
                onPressed: () {
                  if (!isCompleted) _handleCancelOrder();
                },
                buttonTextColor: isCompleted ? kWhite : Colors.red,
              ),
            ),
            Expanded(
              child: ButtonGlobalWithoutIcon(
                buttontext: isCompleted ? 'Review' : 'Deliver Work',
                buttonDecoration: kButtonDecoration.copyWith(
                  color: isCompleted ? kWhite : kPrimaryColor,
                  border: Border.all(color: isCompleted ? kPrimaryColor : Colors.transparent),
                ),
                onPressed: () {
                  const ClientOrderReview().launch(context);
                },
                buttonTextColor: isCompleted ? kPrimaryColor : kWhite,
              ),
            ),
          ],
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
                              color: isCompleted ? const Color(0xFFBFBFBF) : kPrimaryColor,
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
                      _buildRow('Title', title),
                      const SizedBox(height: 8.0),
                      _buildRow('Service Info', description, isExpandable: true),
                      const SizedBox(height: 8.0),
                      _buildRow('Duration', '$deliveryTime Days'),
                      const SizedBox(height: 8.0),
                      _buildRow('Amount', '$currencySign$price'),
                      const SizedBox(height: 8.0),
                      _buildRow('Status', status.toString().substring(0, 1).toUpperCase() + status.toString().substring(1)),
                      const SizedBox(height: 15.0),
                      Text('Order Details', style: kTextStyle.copyWith(color: kNeutralColor, fontWeight: FontWeight.bold)),
                      const SizedBox(height: 8.0),
                      _buildRow('Revisions', revisionCount == 0 ? 'Unlimited Revisions' : '$revisionCount Revisions'),
                      const SizedBox(height: 15.0),
                      Text('Order Summary', style: kTextStyle.copyWith(color: kNeutralColor, fontWeight: FontWeight.bold)),
                      const SizedBox(height: 8.0),
                      _buildRow('Subtotal', '$currencySign$price'),
                      const SizedBox(height: 8.0),
                      _buildRow('Total', '$currencySign$price'),
                      const SizedBox(height: 8.0),
                      _buildRow('Delivery date', _formatDate(_order?['delivery_deadline'])),
                      const SizedBox(height: 15.0),
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

  Widget _buildRow(String label, String value, {bool isExpandable = false}) {
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
                        style: kTextStyle.copyWith(color: kSubTitleColor),
                        overflow: TextOverflow.ellipsis,
                        maxLines: 2,
                      ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
