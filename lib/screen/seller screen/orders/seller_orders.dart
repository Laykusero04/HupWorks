import 'package:flutter/material.dart';
import 'package:freelancer/services/seller_orders_service.dart';
import 'package:nb_utils/nb_utils.dart';
import 'package:slide_countdown/slide_countdown.dart';

import '../../widgets/constant.dart';
import 'seller_order_details.dart';

class SellerOrderList extends StatefulWidget {
  const SellerOrderList({Key? key}) : super(key: key);

  @override
  State<SellerOrderList> createState() => _SellerOrderListState();
}

class _SellerOrderListState extends State<SellerOrderList> {
  List<Map<String, dynamic>> _orders = [];
  bool _isLoading = true;
  String _selectedStatus = 'Active';
  final List<String> _statusTabs = ['Active', 'Pending', 'Completed', 'Delivered'];

  @override
  void initState() {
    super.initState();
    _loadOrders();
  }

  Future<void> _loadOrders() async {
    setState(() => _isLoading = true);
    try {
      final orders = await SellerOrdersService.getSellerOrders(status: _selectedStatus.toLowerCase());
      if (mounted) setState(() { _orders = orders; _isLoading = false; });
    } catch (e) {
      if (mounted) { setState(() => _isLoading = false); ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: $e'))); }
    }
  }

  Duration _getTimeRemaining(Map<String, dynamic> order) {
    final deadline = order['delivery_deadline'];
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
    const m = ['Jan','Feb','Mar','Apr','May','Jun','Jul','Aug','Sep','Oct','Nov','Dec'];
    return '${d.day} ${m[d.month-1]} ${d.year}';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: kDarkWhite,
      appBar: AppBar(backgroundColor: kDarkWhite, elevation: 0, iconTheme: const IconThemeData(color: kNeutralColor),
        title: Text('Orders', style: kTextStyle.copyWith(color: kNeutralColor, fontWeight: FontWeight.bold)), centerTitle: true),
      body: Padding(
        padding: const EdgeInsets.only(top: 10.0),
        child: Container(
          width: context.width(),
          decoration: const BoxDecoration(color: kWhite, borderRadius: BorderRadius.only(topLeft: Radius.circular(30.0), topRight: Radius.circular(30.0))),
          child: Column(
            children: [
              HorizontalList(
                padding: const EdgeInsets.only(left: 15.0, top: 15.0),
                itemCount: _statusTabs.length,
                itemBuilder: (_, i) => GestureDetector(
                  onTap: () { setState(() => _selectedStatus = _statusTabs[i]); _loadOrders(); },
                  child: Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(borderRadius: BorderRadius.circular(30.0), color: _selectedStatus == _statusTabs[i] ? kPrimaryColor : kDarkWhite),
                    child: Text(_statusTabs[i], style: kTextStyle.copyWith(color: _selectedStatus == _statusTabs[i] ? kWhite : kNeutralColor)),
                  ),
                ),
              ),
              const SizedBox(height: 15.0),
              Expanded(
                child: _isLoading
                    ? const Center(child: CircularProgressIndicator(color: kPrimaryColor))
                    : _orders.isEmpty
                        ? Center(child: Text('No ${_selectedStatus.toLowerCase()} orders', style: kTextStyle.copyWith(color: kLightNeutralColor)))
                        : RefreshIndicator(
                            color: kPrimaryColor, onRefresh: _loadOrders,
                            child: ListView.builder(
                              physics: const AlwaysScrollableScrollPhysics(parent: BouncingScrollPhysics()),
                              itemCount: _orders.length,
                              itemBuilder: (_, i) {
                                final order = _orders[i];
                                final service = order['services'] as Map<String, dynamic>?;
                                final client = order['client'] as Map<String, dynamic>?;
                                return Padding(
                                  padding: const EdgeInsets.all(10.0),
                                  child: GestureDetector(
                                    onTap: () async { await SellerOrderDetails(orderId: order['id']).launch(context); _loadOrders(); },
                                    child: Container(
                                      padding: const EdgeInsets.all(10.0),
                                      decoration: BoxDecoration(color: kWhite, borderRadius: BorderRadius.circular(8.0), border: Border.all(color: kBorderColorTextField),
                                        boxShadow: const [BoxShadow(color: kDarkWhite, spreadRadius: 4.0, blurRadius: 4.0, offset: Offset(0, 2))]),
                                      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                                        Row(children: [
                                          Expanded(child: Text('Order #${order['id'].toString().substring(0, 8).toUpperCase()}', style: kTextStyle.copyWith(color: kNeutralColor, fontWeight: FontWeight.bold))),
                                          SlideCountdownSeparated(showZeroValue: true, duration: _getTimeRemaining(order), separatorType: SeparatorType.symbol,
                                            separatorStyle: kTextStyle.copyWith(color: Colors.transparent),
                                            decoration: BoxDecoration(color: _selectedStatus == 'Active' ? kPrimaryColor : const Color(0xFFBFBFBF), borderRadius: BorderRadius.circular(3.0))),
                                        ]),
                                        const SizedBox(height: 10.0),
                                        RichText(text: TextSpan(text: 'Client: ', style: kTextStyle.copyWith(color: kLightNeutralColor), children: [
                                          TextSpan(text: client?['name'] ?? 'Unknown', style: kTextStyle.copyWith(color: kNeutralColor)),
                                          TextSpan(text: '  |  ', style: kTextStyle.copyWith(color: kLightNeutralColor)),
                                          TextSpan(text: _formatDate(order['created_at']), style: kTextStyle.copyWith(color: kLightNeutralColor)),
                                        ])),
                                        const SizedBox(height: 8.0),
                                        const Divider(thickness: 1.0, color: kBorderColorTextField, height: 1.0),
                                        const SizedBox(height: 8.0),
                                        _row('Title', service?['title'] ?? 'Service'),
                                        const SizedBox(height: 8.0),
                                        _row('Amount', '$currencySign${order['price'] ?? 0}'),
                                        const SizedBox(height: 8.0),
                                        _row('Status', _selectedStatus),
                                      ]),
                                    ),
                                  ),
                                );
                              },
                            ),
                          ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _row(String l, String v) => Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
    Expanded(flex: 1, child: Text(l, style: kTextStyle.copyWith(color: kSubTitleColor))),
    Expanded(flex: 3, child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Text(':', style: kTextStyle.copyWith(color: kSubTitleColor)), const SizedBox(width: 10.0),
      Flexible(child: Text(v, style: kTextStyle.copyWith(color: kNeutralColor), overflow: TextOverflow.ellipsis, maxLines: 2)),
    ])),
  ]);
}
