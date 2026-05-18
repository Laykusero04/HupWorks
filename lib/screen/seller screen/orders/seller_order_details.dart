import 'package:flutter/material.dart';
import 'package:freelancer/core/utils/order_contract_display.dart';
import 'package:freelancer/screen/attendance/attendance_scan_screen.dart';
import 'package:freelancer/services/attendance_service.dart';
import 'package:freelancer/screen/widgets/button_global.dart';
import 'package:freelancer/services/seller_orders_service.dart';
import 'package:nb_utils/nb_utils.dart';
import 'package:slide_countdown/slide_countdown.dart';

import '../../widgets/constant.dart';
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

  @override
  void initState() {
    super.initState();
    _loadOrder();
  }

  Future<void> _loadOrder() async {
    try {
      final data = await SellerOrdersService.getOrderDetails(widget.orderId);
      if (mounted) {
        setState(() {
          _order = data;
          _service = data['services'] as Map<String, dynamic>?;
          _client = data['client'] as Map<String, dynamic>?;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) { setState(() => _isLoading = false); ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: $e'))); }
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
    const days = ['Monday','Tuesday','Wednesday','Thursday','Friday','Saturday','Sunday'];
    const m = ['Jan','Feb','Mar','Apr','May','Jun','Jul','Aug','Sep','Oct','Nov','Dec'];
    return '${days[d.weekday-1]}, ${d.day} ${m[d.month-1]} ${d.year}';
  }

  Future<void> _handleCancel() async {
    try {
      await SellerOrdersService.updateOrderStatus(widget.orderId, 'cancelled');
      if (mounted) { ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Order cancelled'))); Navigator.pop(context); }
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: $e')));
    }
  }

  Future<void> _handleComplete() async {
    try {
      await SellerOrdersService.updateOrderStatus(widget.orderId, 'completed');
      if (mounted) { ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Order marked complete'))); Navigator.pop(context); }
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: $e')));
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) return const Scaffold(backgroundColor: kDarkWhite, body: Center(child: CircularProgressIndicator(color: kPrimaryColor)));

    final status = ((_order?['status'] as String?) ?? 'pending').toLowerCase();
    final isCompleted = status == 'completed';
    final isDelivered = status == 'delivered';
    final title = OrderContractDisplay.title(_order, _service);
    final description = OrderContractDisplay.serviceInfo(_order, _service);
    final durationText = OrderContractDisplay.durationLabel(_order, _service);
    final revisionText = OrderContractDisplay.revisionsLabel(_order, _service);
    final price = _order?['price'] ?? 0;
    final clientName = _client?['name'] ?? 'Client';
    final orderId = widget.orderId.substring(0, 8).toUpperCase();
    final bottomInset = MediaQuery.paddingOf(context).bottom + 12;
    final jobPost = OrderContractDisplay.jobPostFromOrder(_order);
    final showAttendance = _canScanAttendance(status, jobPost);

    return Scaffold(
      backgroundColor: kDarkWhite,
      appBar: AppBar(
        backgroundColor: kDarkWhite, elevation: 0, iconTheme: const IconThemeData(color: kNeutralColor),
        title: Text('Order Details', style: kTextStyle.copyWith(color: kNeutralColor, fontWeight: FontWeight.bold)), centerTitle: true,
      ),
      bottomNavigationBar: Material(
        color: kWhite,
        elevation: 12,
        shadowColor: Colors.black26,
        child: Padding(
          padding: EdgeInsets.only(bottom: bottomInset),
          child: Row(
            children: [
              if (!isCompleted)
                Expanded(
                  child: ButtonGlobalWithoutIcon(
                    buttontext: 'Cancel', buttonTextColor: Colors.red,
                    buttonDecoration: kButtonDecoration.copyWith(color: kWhite, border: Border.all(color: Colors.red)),
                    onPressed: _handleCancel,
                  ),
                ),
              Expanded(
                child: ButtonGlobalWithoutIcon(
                  buttontext: isCompleted ? 'Completed' : isDelivered ? 'Complete Order' : 'Deliver Work',
                  buttonTextColor: kWhite,
                  buttonDecoration: kButtonDecoration.copyWith(color: isCompleted ? kLightNeutralColor : kPrimaryColor),
                  onPressed: isCompleted
                      ? () {}
                      : isDelivered
                          ? _handleComplete
                          : () async {
                              await SellerDeliverOrder(orderId: widget.orderId).launch(context);
                              _loadOrder();
                            },
                ),
              ),
            ],
          ),
        ),
      ),
      body: Padding(
        padding: const EdgeInsets.only(top: 15.0),
        child: Container(
          padding: const EdgeInsets.only(left: 15.0, right: 15.0),
          width: context.width(),
          decoration: const BoxDecoration(color: kWhite, borderRadius: BorderRadius.only(topLeft: Radius.circular(30.0), topRight: Radius.circular(30.0))),
          child: SingleChildScrollView(
            physics: const BouncingScrollPhysics(),
            child: Column(
              children: [
                const SizedBox(height: 15.0),
                Container(
                  padding: const EdgeInsets.all(10.0),
                  width: context.width(),
                  decoration: BoxDecoration(color: kWhite, borderRadius: BorderRadius.circular(8.0), border: Border.all(color: kBorderColorTextField),
                    boxShadow: const [BoxShadow(color: kDarkWhite, spreadRadius: 4.0, blurRadius: 4.0, offset: Offset(0, 2))]),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(children: [
                        Text('Order ID #$orderId', style: kTextStyle.copyWith(color: kNeutralColor, fontWeight: FontWeight.bold)),
                        const Spacer(),
                        SlideCountdownSeparated(duration: _getTimeRemaining(), separatorType: SeparatorType.symbol,
                          separatorStyle: kTextStyle.copyWith(color: Colors.transparent),
                          decoration: BoxDecoration(color: isCompleted ? const Color(0xFFBFBFBF) : kPrimaryColor, borderRadius: BorderRadius.circular(3.0))),
                      ]),
                      const SizedBox(height: 10.0),
                      RichText(text: TextSpan(text: 'Client: ', style: kTextStyle.copyWith(color: kLightNeutralColor), children: [
                        TextSpan(text: clientName, style: kTextStyle.copyWith(color: kNeutralColor)),
                        TextSpan(text: '  |  ', style: kTextStyle.copyWith(color: kLightNeutralColor)),
                        TextSpan(text: _formatDate(_order?['created_at']), style: kTextStyle.copyWith(color: kLightNeutralColor)),
                      ])),
                      const SizedBox(height: 8.0),
                      const Divider(thickness: 1.0, color: kBorderColorTextField, height: 1.0),
                      const SizedBox(height: 8.0),
                      _row('Title', title, emphasizeValue: true),
                      const SizedBox(height: 8.0),
                      _rowExpand('Service Info', description),
                      const SizedBox(height: 8.0),
                      _row('Duration', durationText),
                      const SizedBox(height: 8.0),
                      _row('Amount', '$currencySign$price'),
                      const SizedBox(height: 8.0),
                      _row('Status', status.toString().substring(0, 1).toUpperCase() + status.toString().substring(1)),
                      const SizedBox(height: 15.0),
                      Text('Order Details', style: kTextStyle.copyWith(color: kNeutralColor, fontWeight: FontWeight.bold)),
                      const SizedBox(height: 8.0),
                      _row('Revisions', revisionText),
                      const SizedBox(height: 15.0),
                      Text('Order Summary', style: kTextStyle.copyWith(color: kNeutralColor, fontWeight: FontWeight.bold)),
                      const SizedBox(height: 8.0),
                      _row('Total', '$currencySign$price'),
                      const SizedBox(height: 8.0),
                      _row('Delivery date', _formatDate(_order?['delivery_deadline'])),
                      if (showAttendance) ...[
                        const SizedBox(height: 16),
                        ButtonGlobalWithoutIcon(
                          buttontext: 'Scan attendance QR',
                          buttonDecoration: kButtonDecoration.copyWith(
                            color: const Color(0xFF2E7D32),
                          ),
                          buttonTextColor: kWhite,
                          onPressed: () async {
                            final ok = await Navigator.of(context).push<bool>(
                              MaterialPageRoute(
                                builder: (_) => const AttendanceScanScreen(),
                              ),
                            );
                            if (!mounted) return;
                            if (ok == true) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(
                                  content: Text('Attendance updated'),
                                ),
                              );
                            }
                          },
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

  bool _canScanAttendance(String status, Map<String, dynamic>? jobPost) {
    if (jobPost == null) return false;
    if (!AttendanceService.isOnsiteJob(jobPost)) return false;
    final s = status.toLowerCase();
    return s != 'cancelled' && s != 'completed';
  }

  Widget _row(String l, String v, {bool emphasizeValue = false}) => Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
    Expanded(flex: 2, child: Text(l, style: kTextStyle.copyWith(color: kSubTitleColor))),
    Expanded(flex: 4, child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Text(':', style: kTextStyle.copyWith(color: kSubTitleColor)), const SizedBox(width: 10.0),
      Flexible(
        child: Text(
          v,
          style: emphasizeValue
              ? kTextStyle.copyWith(color: kNeutralColor, fontWeight: FontWeight.w700, height: 1.35)
              : kTextStyle.copyWith(color: kSubTitleColor, height: 1.35),
          overflow: TextOverflow.ellipsis,
          maxLines: emphasizeValue ? 8 : 2,
        ),
      ),
    ])),
  ]);

  Widget _rowExpand(String l, String v) => Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
    Expanded(flex: 2, child: Text(l, style: kTextStyle.copyWith(color: kSubTitleColor))),
    Expanded(flex: 4, child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Text(':', style: kTextStyle.copyWith(color: kSubTitleColor)), const SizedBox(width: 10.0),
      Flexible(child: ReadMoreText(v, style: kTextStyle.copyWith(color: kLightNeutralColor), trimLines: 3, colorClickableText: kPrimaryColor, trimMode: TrimMode.Line, trimCollapsedText: '..Read more', trimExpandedText: '..Read less')),
    ])),
  ]);
}
