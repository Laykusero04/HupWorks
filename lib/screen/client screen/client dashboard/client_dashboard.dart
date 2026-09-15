import 'package:flutter/material.dart';
import 'package:freelancer/core/widgets/rubik_refresh_indicator.dart';
import 'package:freelancer/core/widgets/loading_widget.dart';
import 'package:freelancer/core/utils/dashboard_period.dart';
import 'package:freelancer/core/widgets/empty_state_widget.dart';
import 'package:freelancer/l10n/l10n.dart';
import 'package:freelancer/screen/widgets/dashboard_period_selector.dart';
import 'package:freelancer/services/dashboard_service.dart';
import 'package:nb_utils/nb_utils.dart';

import '../../widgets/constant.dart';

class ClientDashBoard extends StatefulWidget {
  const ClientDashBoard({Key? key}) : super(key: key);

  @override
  State<ClientDashBoard> createState() => _ClientDashBoardState();
}

class _ClientDashBoardState extends State<ClientDashBoard> {
  Map<String, dynamic>? _data;
  bool _isLoading = true;
  bool _hasError = false;
  DashboardPeriod _period = DashboardPeriod.month;

  @override
  void initState() {
    super.initState();
    _loadDashboard(showLoader: true);
  }

  Future<void> _loadDashboard({bool showLoader = false}) async {
    if (showLoader && mounted) {
      setState(() {
        _isLoading = true;
        _hasError = false;
      });
    }
    try {
      final data = await DashboardService.getClientDashboard(period: _period);
      if (mounted) {
        setState(() {
          _data = data;
          _isLoading = false;
          _hasError = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLoading = false;
          if (_data == null) _hasError = true;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(context.l10n.errorWithDetail('$e'))),
        );
      }
    }
  }

  void _onPeriodChanged(DashboardPeriod period) {
    if (period == _period) return;
    setState(() => _period = period);
    _loadDashboard(showLoader: true);
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

    final totalSpent = _data?['total_spent'] ?? 0;
    final totalOrders = _data?['total_orders'] ?? 0;
    final completedOrders = _data?['completed_orders'] ?? 0;
    final incompleteOrders = _data?['incomplete_orders'] ?? 0;

    return Scaffold(
      backgroundColor: kDarkWhite,
      appBar: AppBar(
        backgroundColor: kDarkWhite,
        elevation: 0,
        iconTheme: const IconThemeData(color: kNeutralColor),
        title: Text(
          l10n.dashboard,
          style: kTextStyle.copyWith(color: kNeutralColor, fontWeight: FontWeight.bold),
        ),
        centerTitle: true,
      ),
      body: _hasError && _data == null
          ? EmptyStateWidget(
              message: l10n.couldNotLoadResults,
              hint: l10n.errorLoading,
              icon: Icons.bar_chart_outlined,
              actionLabel: l10n.retry,
              onAction: () => _loadDashboard(showLoader: true),
            )
          : Padding(
              padding: const EdgeInsets.only(top: 20.0),
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
                  onRefresh: () => _loadDashboard(),
                  child: SingleChildScrollView(
                    physics: const AlwaysScrollableScrollPhysics(
                      parent: BouncingScrollPhysics(),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const SizedBox(height: 15.0),
                        DashboardPeriodSelector(
                          value: _period,
                          onChanged: _onPeriodChanged,
                        ),
                        const SizedBox(height: 14.0),
                        Row(
                          children: [
                            Expanded(
                              child: DashBoardInfo(
                                count: '$currencySign$totalSpent',
                                title: l10n.totalSpent,
                                image: 'images/td.png',
                              ),
                            ),
                            const SizedBox(width: 10.0),
                            Expanded(
                              child: DashBoardInfo(
                                count: '$totalOrders',
                                title: l10n.totalOrders,
                                image: 'images/to.png',
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 10.0),
                        Row(
                          children: [
                            Expanded(
                              child: DashBoardInfo(
                                count: '$completedOrders',
                                title: l10n.orderStatusCompleted,
                                image: 'images/co.png',
                              ),
                            ),
                            const SizedBox(width: 10.0),
                            Expanded(
                              child: DashBoardInfo(
                                count: '$incompleteOrders',
                                title: l10n.inProgress,
                                image: 'images/io.png',
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 20),
                      ],
                    ),
                  ),
                ),
              ),
            ),
    );
  }
}
