import 'package:flutter/material.dart';
import 'package:freelancer/l10n/l10n.dart';
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

  @override
  void initState() {
    super.initState();
    _loadDashboard();
  }

  Future<void> _loadDashboard() async {
    try {
      final data = await DashboardService.getClientDashboard();
      if (mounted) {
        setState(() {
          _data = data;
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

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Scaffold(
        backgroundColor: kDarkWhite,
        body: Center(child: CircularProgressIndicator(color: kPrimaryColor)),
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
          'Dashboard',
          style: kTextStyle.copyWith(color: kNeutralColor, fontWeight: FontWeight.bold),
        ),
        centerTitle: true,
      ),
      body: Padding(
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
          child: SingleChildScrollView(
            physics: const BouncingScrollPhysics(),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SizedBox(height: 15.0),
                Row(
                  children: [
                    Expanded(
                      child: DashBoardInfo(
                        count: '$currencySign$totalSpent',
                        title: 'Total Spent',
                        image: 'images/td.png',
                      ),
                    ),
                    const SizedBox(width: 10.0),
                    Expanded(
                      child: DashBoardInfo(
                        count: '$totalOrders',
                        title: 'Total Orders',
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
                        title: 'Completed',
                        image: 'images/co.png',
                      ),
                    ),
                    const SizedBox(width: 10.0),
                    Expanded(
                      child: DashBoardInfo(
                        count: '$incompleteOrders',
                        title: 'In Progress',
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
    );
  }
}
