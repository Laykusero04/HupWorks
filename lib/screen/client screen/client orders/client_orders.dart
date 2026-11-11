import 'package:flutter/material.dart';
import 'package:freelancer/core/widgets/rubik_refresh_indicator.dart';
import 'package:freelancer/core/widgets/loading_widget.dart';
import 'package:freelancer/core/guide/guide_anchor.dart';
import 'package:freelancer/core/guide/guide_host.dart';
import 'package:freelancer/core/guide/guide_info_button.dart';
import 'package:freelancer/core/guide/guide_step.dart';
import 'package:freelancer/core/utils/app_date_format.dart';
import 'package:freelancer/core/utils/order_cancellation.dart';
import 'package:freelancer/core/utils/order_contract_display.dart';
import 'package:freelancer/core/widgets/empty_state_widget.dart';
import 'package:freelancer/l10n/l10n.dart';
import 'package:freelancer/l10n/l10n_labels.dart';
import 'package:freelancer/screen/client%20screen/client%20job%20post/create_new_job_post.dart';
import 'package:freelancer/services/orders_service.dart';
import 'package:nb_utils/nb_utils.dart';

import '../../widgets/client_shell_app_bar.dart';
import '../../widgets/constant.dart';
import 'client_order_details.dart';

class ClientOrderList extends StatefulWidget {
  const ClientOrderList({Key? key}) : super(key: key);

  @override
  State<ClientOrderList> createState() => _ClientOrderListState();
}

class _ClientOrderListState extends State<ClientOrderList>
    with GuideHost<ClientOrderList> {
  List<Map<String, dynamic>> _orders = [];
  bool _isLoading = true;
  String _selectedStatus = 'all';

  // Guide targets (long-lived; the card keys sit on the FIRST card only).
  final GlobalKey _guideFilterKey = GlobalKey();
  final GlobalKey _guideStatusKey = GlobalKey();
  final GlobalKey _guideCardKey = GlobalKey();

  /// True during every reload (status chip, refresh button, pull-to-refresh,
  /// return from a contract), so a running guide is torn down and restarted.
  bool _reloading = false;

  @override
  String get guideScreenId => 'client_contracts';

  @override
  String get guideRole => 'client';

  @override
  int get guideVersion => 1;

  @override
  bool get guideDataReady => !_isLoading && !_reloading;

  @override
  String get guideSkipLabel => context.l10n.guideSkip;

  @override
  String get guideNextLabel => context.l10n.guideNext;

  @override
  String get guideDoneLabel => context.l10n.guideDone;

  Widget _guide(GlobalKey key, String title, String description, Widget child,
          {double radius = 8}) =>
      GuideAnchor.wrap(
        GuideAnchor(
          key: key,
          scope: guideScope,
          title: title,
          description: description,
          borderRadius: BorderRadius.circular(radius),
        ),
        child,
      );

  /// Core: status chips, status strip and body of the first card. With no
  /// contracts only the chips render, so the guide does not auto-run.
  @override
  List<GuideStep> buildGuideSteps(BuildContext context) {
    final l10n = context.l10n;
    return [
      GuideStep(
        key: _guideFilterKey,
        title: l10n.guideContractsFilterTitle,
        description: l10n.guideContractsFilterDesc,
      ),
      GuideStep(
        key: _guideStatusKey,
        title: l10n.guideContractsStatusTitle,
        description: l10n.guideContractsStatusDesc,
      ),
      GuideStep(
        key: _guideCardKey,
        title: l10n.guideContractsOpenTitle,
        description: l10n.guideContractsOpenDesc,
      ),
    ];
  }

  static const _statusTabs = [
    'all',
    'active',
    'pending',
    'delivered',
    'completed',
    'cancelled',
  ];

  @override
  void initState() {
    super.initState();
    _loadOrders();
  }

  Future<void> _loadOrders({bool showLoader = true}) async {
    if (showLoader && mounted) setState(() => _isLoading = true);
    if (mounted && !_isLoading) setState(() => _reloading = true);
    try {
      await OrdersService.expireStaleCancellationRequests();
      final orders = await OrdersService.getClientOrders(
        status: _selectedStatus == 'all' ? null : _selectedStatus,
      );
      if (mounted) {
        setState(() {
          _orders = orders;
          _isLoading = false;
          _reloading = false;
        });
        scheduleGuide();
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLoading = false;
          _reloading = false;
        });
        scheduleGuide();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(context.l10n.errorLoadingOrders('$e')),
          ),
        );
      }
    }
  }

  Duration _getTimeRemaining(Map<String, dynamic> order) {
    final deadline = order['delivery_deadline'];
    if (deadline == null) return Duration.zero;
    final deadlineDate = DateTime.tryParse(deadline);
    if (deadlineDate == null) return Duration.zero;
    final remaining = deadlineDate.difference(DateTime.now());
    return remaining.isNegative ? Duration.zero : remaining;
  }

  String _formatDate(String? dateStr) {
    return AppDateFormat.tryDMmmY(
          dateStr,
          AppDateFormat.localeOf(context),
        ) ??
        '';
  }

  _StatusStyle _statusStyle(String? status) {
    final l10n = context.l10n;
    final label = OrderCancellationReason.statusLabel(status, l10n);
    final (fg, bg) = StatusColors.order(status);
    if ((status ?? '').toLowerCase() == 'cancellation_requested') {
      return _StatusStyle(l10n.orderStatusCancellationPending, fg, bg);
    }
    return _StatusStyle(label, fg, bg);
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    return guideBackScope(Scaffold(
      backgroundColor: kWhite,
      appBar: ClientShellAppBar(
        title: l10n.contracts,
        actions: [
          GuideInfoButton(host: this),
          IconButton(
            icon: const Icon(Icons.refresh),
            tooltip: l10n.refreshTooltip,
            onPressed: _isLoading ? null : _loadOrders,
          ),
        ],
      ),
      body: Container(
        width: context.width(),
        child: Column(
          children: [
            _guide(
              _guideFilterKey,
              l10n.guideContractsFilterTitle,
              l10n.guideContractsFilterDesc,
              HorizontalList(
                padding: const EdgeInsets.only(left: 15.0, top: 15.0),
                itemCount: _statusTabs.length,
                itemBuilder: (_, i) {
                  final tab = _statusTabs[i];
                  final selected = _selectedStatus == tab;
                  return GestureDetector(
                    onTap: () {
                      setState(() => _selectedStatus = tab);
                      _loadOrders();
                    },
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 14, vertical: 9),
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(30.0),
                        color: selected ? kPrimaryColor : kDarkWhite,
                        border: Border.all(
                            color: selected
                                ? kPrimaryColor
                                : kBorderColorTextField),
                      ),
                      child: Text(
                        L10nLabels.orderFilterTabLabel(l10n, tab),
                        style: kTextStyle.copyWith(
                            color: selected ? kWhite : kNeutralColor,
                            fontWeight:
                                selected ? FontWeight.w600 : FontWeight.normal,
                            fontSize: 13),
                      ),
                    ),
                  );
                },
              ),
            ),
            const SizedBox(height: 12.0),
            Expanded(
              child: _isLoading
                  ? const LoadingWidget()
                  : _orders.isEmpty
                      ? RubikRefreshIndicator(
                          onRefresh: () => _loadOrders(showLoader: false),
                          child: ListView(
                            physics: const AlwaysScrollableScrollPhysics(
                              parent: BouncingScrollPhysics(),
                            ),
                            children: [
                              SizedBox(
                                height: MediaQuery.sizeOf(context).height * 0.2,
                              ),
                              EmptyStateWidget(
                                message: _selectedStatus == 'all'
                                    ? l10n.noContractsYet
                                    : l10n.noFilteredContracts(
                                        L10nLabels.orderFilterTabLabel(
                                          l10n,
                                          _selectedStatus,
                                        ).toLowerCase(),
                                      ),
                                hint: _selectedStatus == 'all'
                                    ? l10n.noContractsYetClientHint
                                    : l10n.noFilteredContractsHint,
                                icon: Icons.description_outlined,
                                actionLabel: _selectedStatus == 'all'
                                    ? l10n.postAJob
                                    : l10n.clearFilters,
                                onAction: _selectedStatus == 'all'
                                    ? () async {
                                        await const CreateNewJobPost()
                                            .launch(context);
                                        _loadOrders(showLoader: false);
                                      }
                                    : () {
                                        setState(() => _selectedStatus = 'all');
                                        _loadOrders();
                                      },
                              ),
                            ],
                          ),
                        )
                      : RubikRefreshIndicator(
                          onRefresh: () => _loadOrders(showLoader: false),
                          child: ListView.builder(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 14, vertical: 6),
                            physics: const AlwaysScrollableScrollPhysics(
                                parent: BouncingScrollPhysics()),
                            itemCount: _orders.length,
                            itemBuilder: (_, i) =>
                                _buildContractCard(_orders[i], first: i == 0),
                          ),
                        ),
            ),
          ],
        ),
      ),
    ));
  }

  Widget _buildContractCard(Map<String, dynamic> order, {bool first = false}) {
    final l10n = context.l10n;
    final service = order['services'] as Map<String, dynamic>?;
    final seller = order['seller'] as Map<String, dynamic>?;
    final sellerName = (seller?['name'] as String?) ?? l10n.unknown;
    final orderId = order['id'].toString();
    final idShort = orderId.length >= 8
        ? orderId.substring(0, 8).toUpperCase()
        : orderId.toUpperCase();
    final status = _statusStyle(order['status'] as String?);
    final remaining = _getTimeRemaining(order);
    final isActive = (order['status'] as String?)?.toLowerCase() == 'active';
    final title = OrderContractDisplay.title(order, service);
    final price = order['price'] ?? 0;

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6.0),
      child: GestureDetector(
        onTap: () async {
          await ClientOrderDetails(orderId: order['id']).launch(context);
          if (mounted) await _loadOrders(showLoader: false);
        },
        child: Container(
          decoration: BoxDecoration(
            color: kWhite,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: kBorderColorTextField),
            boxShadow: [
              BoxShadow(
                  color: kNeutralColor.withOpacity(0.04),
                  blurRadius: 10,
                  offset: const Offset(0, 4)),
            ],
          ),
          clipBehavior: Clip.antiAlias,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _guideIf(
                first,
                _guideStatusKey,
                l10n.guideContractsStatusTitle,
                l10n.guideContractsStatusDesc,
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                  color: status.bg,
                  child: Row(
                    children: [
                      Icon(Icons.description_outlined,
                          size: 16, color: status.fg),
                      8.width,
                      Expanded(
                        child: Text('#$idShort',
                            style: kTextStyle.copyWith(
                                color: kNeutralColor,
                                fontWeight: FontWeight.bold,
                                fontSize: 13,
                                letterSpacing: 0.5)),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 10, vertical: 4),
                        decoration: BoxDecoration(
                            color: status.fg,
                            borderRadius: BorderRadius.circular(20)),
                        child: Text(status.label,
                            style: kTextStyle.copyWith(
                                color: kWhite,
                                fontSize: 11,
                                fontWeight: FontWeight.bold,
                                letterSpacing: 0.3)),
                      ),
                    ],
                  ),
                ),
              ),
              _guideIf(
                first,
                _guideCardKey,
                l10n.guideContractsOpenTitle,
                l10n.guideContractsOpenDesc,
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
                              sellerName.isNotEmpty
                                  ? sellerName[0].toUpperCase()
                                  : '?',
                              style: kTextStyle.copyWith(
                                  color: kPrimaryColor,
                                  fontWeight: FontWeight.bold,
                                  fontSize: 15),
                            ),
                          ),
                          10.width,
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(sellerName,
                                    style: kTextStyle.copyWith(
                                        color: kNeutralColor,
                                        fontWeight: FontWeight.w600,
                                        fontSize: 14),
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis),
                                2.height,
                                Text(
                                    l10n.contractStartedOn(_formatDate(
                                        order['created_at'] as String?)),
                                    style: kTextStyle.copyWith(
                                        color: kLightNeutralColor,
                                        fontSize: 12)),
                              ],
                            ),
                          ),
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.end,
                            children: [
                              Text(l10n.amountCaps,
                                  style: kTextStyle.copyWith(
                                      color: kLightNeutralColor,
                                      fontSize: 10,
                                      fontWeight: FontWeight.w700,
                                      letterSpacing: 0.5)),
                              2.height,
                              Text('$currencySign$price',
                                  style: kTextStyle.copyWith(
                                      color: kPrimaryColor,
                                      fontWeight: FontWeight.bold,
                                      fontSize: 18)),
                            ],
                          ),
                        ],
                      ),
                      12.height,
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(
                            color: kDarkWhite,
                            borderRadius: BorderRadius.circular(10)),
                        child: Row(
                          children: [
                            const Icon(Icons.work_outline,
                                size: 16, color: kPrimaryColor),
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
                            Text(
                                L10nLabels.formatContractDeadlineRemaining(
                                    l10n, remaining),
                                style: kTextStyle.copyWith(
                                    color: status.fg,
                                    fontWeight: FontWeight.w600,
                                    fontSize: 12)),
                            const Spacer(),
                            const Icon(Icons.chevron_right,
                                color: kLightNeutralColor, size: 20),
                          ],
                        ),
                      ] else ...[
                        10.height,
                        Row(
                          children: const [
                            Spacer(),
                            Icon(Icons.chevron_right,
                                color: kLightNeutralColor, size: 20),
                          ],
                        ),
                      ],
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _guideIf(bool attach, GlobalKey key, String title, String description,
          Widget child) =>
      attach ? _guide(key, title, description, child) : child;
}

class _StatusStyle {
  final String label;
  final Color fg;
  final Color bg;
  const _StatusStyle(this.label, this.fg, this.bg);
}
