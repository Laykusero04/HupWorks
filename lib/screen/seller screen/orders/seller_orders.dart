import 'package:flutter/material.dart';
import 'package:freelancer/core/utils/order_contract_display.dart';
import 'package:freelancer/services/seller_orders_service.dart';
import 'package:nb_utils/nb_utils.dart';

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
  String _selectedStatus = 'All';
  final List<String> _statusTabs = ['All', 'Active', 'Pending', 'Completed', 'Delivered'];

  @override
  void initState() {
    super.initState();
    _loadOrders();
  }

  Future<void> _loadOrders() async {
    setState(() => _isLoading = true);
    try {
      final orders = await SellerOrdersService.getSellerOrders(
        status: _selectedStatus == 'All' ? null : _selectedStatus.toLowerCase(),
      );
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

  String _formatRemaining(Duration d) {
    if (d.inSeconds <= 0) return 'Overdue';
    if (d.inDays > 0) return '${d.inDays}d ${d.inHours.remainder(24)}h left';
    if (d.inHours > 0) return '${d.inHours}h ${d.inMinutes.remainder(60)}m left';
    return '${d.inMinutes}m left';
  }

  _StatusStyle _statusStyle(String? status) {
    switch ((status ?? '').toLowerCase()) {
      case 'active':
        return const _StatusStyle('Active', kPrimaryColor, Color(0xFFE8F7EE));
      case 'pending':
        return const _StatusStyle('Pending', Color(0xFFD97706), Color(0xFFFEF3C7));
      case 'delivered':
        return const _StatusStyle('Delivered', kSecondaryColor, Color(0xFFDBEAFE));
      case 'completed':
        return const _StatusStyle('Completed', Color(0xFF059669), Color(0xFFD1FAE5));
      case 'cancelled':
        return const _StatusStyle('Cancelled', Color(0xFFDC2626), Color(0xFFFEE2E2));
      default:
        return _StatusStyle(status?.capitalize ?? 'Unknown', kLightNeutralColor, kDarkWhite);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: kDarkWhite,
      body: SafeArea(
        bottom: false,
        child: Column(
          children: [
            _buildHeader(),
            Expanded(
              child: Container(
                width: context.width(),
                decoration: const BoxDecoration(color: kWhite, borderRadius: BorderRadius.only(topLeft: Radius.circular(30.0), topRight: Radius.circular(30.0))),
                child: Column(
                  children: [
                    HorizontalList(
                padding: const EdgeInsets.only(left: 15.0, top: 15.0),
                itemCount: _statusTabs.length,
                itemBuilder: (_, i) {
                  final selected = _selectedStatus == _statusTabs[i];
                  return GestureDetector(
                    onTap: () { setState(() => _selectedStatus = _statusTabs[i]); _loadOrders(); },
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 9),
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(30.0),
                        color: selected ? kPrimaryColor : kDarkWhite,
                        border: Border.all(color: selected ? kPrimaryColor : kBorderColorTextField),
                      ),
                      child: Text(_statusTabs[i],
                          style: kTextStyle.copyWith(
                              color: selected ? kWhite : kNeutralColor,
                              fontWeight: selected ? FontWeight.w600 : FontWeight.normal,
                              fontSize: 13)),
                    ),
                  );
                },
              ),
              const SizedBox(height: 12.0),
              Expanded(
                child: _isLoading
                    ? const Center(child: CircularProgressIndicator(color: kPrimaryColor))
                    : _orders.isEmpty
                        ? Center(child: Text(
                            _selectedStatus == 'All' ? 'No contracts yet' : 'No ${_selectedStatus.toLowerCase()} contracts',
                            style: kTextStyle.copyWith(color: kLightNeutralColor),
                          ))
                        : RefreshIndicator(
                            color: kPrimaryColor, onRefresh: _loadOrders,
                            child: ListView.builder(
                              physics: const AlwaysScrollableScrollPhysics(parent: BouncingScrollPhysics()),
                              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
                              itemCount: _orders.length,
                              itemBuilder: (_, i) => _buildContractCard(_orders[i]),
                            ),
                          ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader() {
    final activeCount = _orders.where((o) => (o['status'] as String?)?.toLowerCase() == 'active').length;
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 14),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: kPrimaryColor.withOpacity(0.12),
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Icon(Icons.description_outlined, color: kPrimaryColor, size: 22),
          ),
          12.width,
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Contracts',
                    style: kTextStyle.copyWith(
                        color: kNeutralColor, fontWeight: FontWeight.bold, fontSize: 22, height: 1.1)),
                2.height,
                RichText(
                  text: TextSpan(
                    style: kTextStyle.copyWith(color: kLightNeutralColor, fontSize: 12),
                    children: [
                      TextSpan(
                          text: '$activeCount active',
                          style: kTextStyle.copyWith(color: kPrimaryColor, fontWeight: FontWeight.w600, fontSize: 12)),
                      const TextSpan(text: '  ·  '),
                      TextSpan(text: '${_orders.length} total'),
                    ],
                  ),
                ),
              ],
            ),
          ),
          Container(
            decoration: BoxDecoration(
              color: kWhite,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: kBorderColorTextField),
            ),
            child: IconButton(
              onPressed: _isLoading ? null : _loadOrders,
              icon: Icon(Icons.refresh_rounded,
                  color: _isLoading ? kLightNeutralColor : kNeutralColor, size: 20),
              tooltip: 'Refresh',
              splashRadius: 22,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildContractCard(Map<String, dynamic> order) {
    final service = order['services'] as Map<String, dynamic>?;
    final client = order['client'] as Map<String, dynamic>?;
    final clientName = (client?['name'] as String?) ?? 'Unknown';
    final orderId = order['id'].toString();
    final idShort = orderId.length >= 8 ? orderId.substring(0, 8).toUpperCase() : orderId.toUpperCase();
    final status = _statusStyle(order['status'] as String?);
    final remaining = _getTimeRemaining(order);
    final isActive = (order['status'] as String?)?.toLowerCase() == 'active';
    final title = OrderContractDisplay.title(order, service);
    final price = order['price'] ?? 0;

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6.0),
      child: GestureDetector(
        onTap: () async { await SellerOrderDetails(orderId: order['id']).launch(context); _loadOrders(); },
        child: Container(
          decoration: BoxDecoration(
            color: kWhite,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: kBorderColorTextField),
            boxShadow: [
              BoxShadow(color: kNeutralColor.withOpacity(0.04), blurRadius: 10, offset: const Offset(0, 4)),
            ],
          ),
          clipBehavior: Clip.antiAlias,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header strip
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                color: status.bg,
                child: Row(
                  children: [
                    Icon(Icons.description_outlined, size: 16, color: status.fg),
                    8.width,
                    Expanded(
                      child: Text('#$idShort',
                          style: kTextStyle.copyWith(
                              color: kNeutralColor, fontWeight: FontWeight.bold, fontSize: 13, letterSpacing: 0.5)),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                      decoration: BoxDecoration(color: status.fg, borderRadius: BorderRadius.circular(20)),
                      child: Text(status.label,
                          style: kTextStyle.copyWith(color: kWhite, fontSize: 11, fontWeight: FontWeight.bold, letterSpacing: 0.3)),
                    ),
                  ],
                ),
              ),
              // Body
              Padding(
                padding: const EdgeInsets.all(14),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        CircleAvatar(
                          radius: 20,
                          backgroundColor: kPrimaryColor.withOpacity(0.12),
                          child: Text(
                            clientName.isNotEmpty ? clientName[0].toUpperCase() : '?',
                            style: kTextStyle.copyWith(color: kPrimaryColor, fontWeight: FontWeight.bold, fontSize: 15),
                          ),
                        ),
                        10.width,
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(clientName,
                                  style: kTextStyle.copyWith(color: kNeutralColor, fontWeight: FontWeight.w600, fontSize: 14),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis),
                              2.height,
                              Text('Started ${_formatDate(order['created_at'] as String?)}',
                                  style: kTextStyle.copyWith(color: kLightNeutralColor, fontSize: 12)),
                            ],
                          ),
                        ),
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.end,
                          children: [
                            Text('AMOUNT',
                                style: kTextStyle.copyWith(
                                    color: kLightNeutralColor, fontSize: 10, fontWeight: FontWeight.w700, letterSpacing: 0.5)),
                            2.height,
                            Text('$currencySign$price',
                                style: kTextStyle.copyWith(color: kPrimaryColor, fontWeight: FontWeight.bold, fontSize: 18)),
                          ],
                        ),
                      ],
                    ),
                    12.height,
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(color: kDarkWhite, borderRadius: BorderRadius.circular(10)),
                      child: Row(
                        children: [
                          const Icon(Icons.work_outline, size: 16, color: kPrimaryColor),
                          8.width,
                          Expanded(
                            child: Text(title,
                                maxLines: 3,
                                overflow: TextOverflow.ellipsis,
                                style: kTextStyle.copyWith(
                                    color: kNeutralColor,
                                    fontSize: 13,
                                    height: 1.3,
                                    fontWeight: FontWeight.w600)),
                          ),
                        ],
                      ),
                    ),
                    if (isActive && remaining.inSeconds > 0) ...[
                      10.height,
                      Row(
                        children: [
                          Icon(Icons.alarm, size: 14, color: status.fg),
                          6.width,
                          Text(_formatRemaining(remaining),
                              style: kTextStyle.copyWith(color: status.fg, fontWeight: FontWeight.w600, fontSize: 12)),
                          const Spacer(),
                          const Icon(Icons.chevron_right, color: kLightNeutralColor, size: 20),
                        ],
                      ),
                    ] else ...[
                      10.height,
                      Row(
                        children: const [
                          Spacer(),
                          Icon(Icons.chevron_right, color: kLightNeutralColor, size: 20),
                        ],
                      ),
                    ],
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _StatusStyle {
  final String label;
  final Color fg;
  final Color bg;
  const _StatusStyle(this.label, this.fg, this.bg);
}

extension on String {
  String get capitalize => isEmpty ? '' : '${this[0].toUpperCase()}${substring(1)}';
}
