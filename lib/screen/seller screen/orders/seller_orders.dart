import 'package:flutter/material.dart';
import 'package:freelancer/core/utils/order_cancellation.dart';
import 'package:freelancer/core/utils/order_contract_display.dart';
import 'package:go_router/go_router.dart';
import 'package:freelancer/services/orders_service.dart';
import 'package:freelancer/l10n/l10n.dart';
import 'package:freelancer/l10n/l10n_labels.dart';
import 'package:freelancer/services/seller_orders_service.dart';
import 'package:nb_utils/nb_utils.dart';

import '../../widgets/client_shell_app_bar.dart';
import '../../widgets/constant.dart';
import '../../widgets/shell_tab_header.dart';

class SellerOrderList extends StatefulWidget {
  const SellerOrderList({Key? key}) : super(key: key);

  @override
  State<SellerOrderList> createState() => _SellerOrderListState();
}

class _SellerOrderListState extends State<SellerOrderList> {
  List<Map<String, dynamic>> _orders = [];
  bool _isLoading = true;
  String _selectedStatus = 'all';
  static const _statusTabs = [
    'all',
    'active',
    'pending',
    'completed',
    'delivered',
  ];

  @override
  void initState() {
    super.initState();
    _loadOrders();
  }

  Future<void> _loadOrders() async {
    setState(() => _isLoading = true);
    try {
      await OrdersService.expireStaleCancellationRequests();
      final orders = await SellerOrdersService.getSellerOrders(
        status: _selectedStatus == 'all' ? null : _selectedStatus,
      );
      if (mounted) setState(() { _orders = orders; _isLoading = false; });
    } catch (e) {
      if (mounted) { setState(() => _isLoading = false); ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(context.l10n.errorWithDetail('$e')))); }
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

  String _formatRemaining(Duration d) =>
      L10nLabels.formatContractDeadlineRemaining(context.l10n, d);

  _StatusStyle _statusStyle(String? status, Color primary) {
    final l10n = context.l10n;
    final label = OrderCancellationReason.statusLabel(status, l10n);
    switch ((status ?? '').toLowerCase()) {
      case 'active':
        return _StatusStyle(label, primary, const Color(0xFFE8EEF8));
      case 'pending':
        return _StatusStyle(
          label,
          const Color(0xFFD97706),
          const Color(0xFFFEF3C7),
        );
      case 'delivered':
        return _StatusStyle(
          label,
          kSecondaryColor,
          const Color(0xFFDBEAFE),
        );
      case 'completed':
        return _StatusStyle(
          label,
          const Color(0xFF059669),
          const Color(0xFFD1FAE5),
        );
      case 'cancelled':
        return _StatusStyle(
          label,
          const Color(0xFFDC2626),
          const Color(0xFFFEE2E2),
        );
      case 'cancellation_requested':
        return _StatusStyle(
          l10n.orderStatusCancellationPending,
          const Color(0xFFD97706),
          const Color(0xFFFFF8E1),
        );
      default:
        return _StatusStyle(label, kLightNeutralColor, kDarkWhite);
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final primary = Theme.of(context).colorScheme.primary;
    return Scaffold(
      backgroundColor: kWhite,
      appBar: ClientShellAppBar(
        title: l10n.contracts,
        persona: ShellPersona.seller,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            tooltip: l10n.refreshTooltip,
            onPressed: _isLoading ? null : _loadOrders,
          ),
        ],
      ),
      body: Column(
        children: [
          HorizontalList(
                padding: const EdgeInsets.only(left: 15.0, top: 15.0),
                itemCount: _statusTabs.length,
                itemBuilder: (_, i) {
                  final tab = _statusTabs[i];
                  final selected = _selectedStatus == tab;
                  return GestureDetector(
                    onTap: () { setState(() => _selectedStatus = tab); _loadOrders(); },
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 9),
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(30.0),
                        color: selected ? primary : kDarkWhite,
                        border: Border.all(color: selected ? primary : kBorderColorTextField),
                      ),
                      child: Text(L10nLabels.orderFilterTabLabel(l10n, tab),
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
                    ? Center(child: CircularProgressIndicator(color: primary))
                    : _orders.isEmpty
                        ? Center(child: Text(
                            _selectedStatus == 'all'
                                ? l10n.noContractsYet
                                : l10n.noFilteredContracts(
                                    L10nLabels.orderFilterTabLabel(
                                      l10n,
                                      _selectedStatus,
                                    ).toLowerCase(),
                                  ),
                            style: kTextStyle.copyWith(color: kLightNeutralColor),
                          ))
                        : RefreshIndicator(
                            color: primary, onRefresh: _loadOrders,
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
    );
  }

  Widget _buildContractCard(Map<String, dynamic> order) {
    final primary = Theme.of(context).colorScheme.primary;
    final service = order['services'] as Map<String, dynamic>?;
    final client = order['client'] as Map<String, dynamic>?;
    final clientName = (client?['name'] as String?) ?? context.l10n.unknown;
    final orderId = order['id'].toString();
    final idShort = orderId.length >= 8 ? orderId.substring(0, 8).toUpperCase() : orderId.toUpperCase();
    final status = _statusStyle(order['status'] as String?, primary);
    final remaining = _getTimeRemaining(order);
    final isActive = (order['status'] as String?)?.toLowerCase() == 'active';
    final title = OrderContractDisplay.title(order, service);
    final price = order['price'] ?? 0;

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6.0),
      child: GestureDetector(
        onTap: () {
          final id = order['id'] as String?;
          if (id != null) {
            context.push('/seller/orders/$id').then((_) {
              if (mounted) _loadOrders();
            });
          }
        },
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
                          backgroundColor: primary.withValues(alpha: 0.12),
                          child: Text(
                            clientName.isNotEmpty ? clientName[0].toUpperCase() : '?',
                            style: kTextStyle.copyWith(color: primary, fontWeight: FontWeight.bold, fontSize: 15),
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
                              Text(context.l10n.contractStartedOn(_formatDate(order['created_at'] as String?)),
                                  style: kTextStyle.copyWith(color: kLightNeutralColor, fontSize: 12)),
                            ],
                          ),
                        ),
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.end,
                          children: [
                            Text(context.l10n.amountCaps,
                                style: kTextStyle.copyWith(
                                    color: kLightNeutralColor, fontSize: 10, fontWeight: FontWeight.w700, letterSpacing: 0.5)),
                            2.height,
                            Text('$currencySign$price',
                                style: kTextStyle.copyWith(color: primary, fontWeight: FontWeight.bold, fontSize: 18)),
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
                          Icon(Icons.work_outline, size: 16, color: primary),
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
