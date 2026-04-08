import 'package:flutter/material.dart';
import 'package:freelancer/services/dashboard_service.dart';
import 'package:nb_utils/nb_utils.dart';

import '../../widgets/constant.dart';
import '../../widgets/data.dart';

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
          SnackBar(content: Text('Error: $e')),
        );
      }
    }
  }

  String _formatDate(String? dateStr) {
    if (dateStr == null) return '';
    final date = DateTime.tryParse(dateStr);
    if (date == null) return '';
    const months = ['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', 'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'];
    return '${date.day} ${months[date.month - 1]} ${date.year}';
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Scaffold(
        backgroundColor: kDarkWhite,
        body: Center(child: CircularProgressIndicator(color: kPrimaryColor)),
      );
    }

    final balance = _data?['balance'] ?? 0;
    final totalSpent = _data?['total_spent'] ?? 0;
    final totalOrders = _data?['total_orders'] ?? 0;
    final completedOrders = _data?['completed_orders'] ?? 0;
    final incompleteOrders = _data?['incomplete_orders'] ?? 0;
    final transactions = (_data?['transactions'] as List<Map<String, dynamic>>?) ?? [];

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
                        count: '$currencySign$balance',
                        title: 'Current Balance',
                        image: 'images/cb.png',
                      ),
                    ),
                    const SizedBox(width: 10.0),
                    Expanded(
                      child: DashBoardInfo(
                        count: '$currencySign$totalSpent',
                        title: 'Total Spent',
                        image: 'images/td.png',
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 10.0),
                Row(
                  children: [
                    Expanded(
                      child: DashBoardInfo(
                        count: '$totalOrders',
                        title: 'Total Orders',
                        image: 'images/to.png',
                      ),
                    ),
                    const SizedBox(width: 10.0),
                    Expanded(
                      child: DashBoardInfo(
                        count: '$completedOrders',
                        title: 'Completed',
                        image: 'images/co.png',
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 10.0),
                Row(
                  children: [
                    Expanded(
                      child: DashBoardInfo(
                        count: '$incompleteOrders',
                        title: 'In Progress',
                        image: 'images/io.png',
                      ),
                    ),
                    const SizedBox(width: 10.0),
                    const Expanded(child: SizedBox()),
                  ],
                ),
                const SizedBox(height: 20),
                Text(
                  'Latest Transactions',
                  style: kTextStyle.copyWith(color: kNeutralColor, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 10),
                transactions.isEmpty
                    ? Padding(
                        padding: const EdgeInsets.all(20.0),
                        child: Center(
                          child: Text('No transactions yet', style: kTextStyle.copyWith(color: kLightNeutralColor)),
                        ),
                      )
                    : ListView.builder(
                        shrinkWrap: true,
                        physics: const NeverScrollableScrollPhysics(),
                        itemCount: transactions.length,
                        itemBuilder: (_, i) {
                          final tx = transactions[i];
                          return Container(
                            margin: const EdgeInsets.only(bottom: 10.0),
                            padding: const EdgeInsets.all(10.0),
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(10.0),
                              border: Border.all(color: kBorderColorTextField),
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                _buildRow('Type', (tx['type'] ?? '').toString().substring(0, 1).toUpperCase() + (tx['type'] ?? '').toString().substring(1)),
                                const SizedBox(height: 10.0),
                                _buildRow('Date', _formatDate(tx['created_at'])),
                                const SizedBox(height: 10.0),
                                _buildRow('Amount', '$currencySign${tx['amount'] ?? 0}'),
                                const SizedBox(height: 10.0),
                                _buildRow('Status', (tx['status'] ?? '').toString().substring(0, 1).toUpperCase() + (tx['status'] ?? '').toString().substring(1)),
                              ],
                            ),
                          );
                        },
                      ),
                const SizedBox(height: 20),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildRow(String label, String value) {
    return Row(
      children: [
        Expanded(
          flex: 2,
          child: Text(label, style: kTextStyle.copyWith(color: kSubTitleColor)),
        ),
        Expanded(
          flex: 4,
          child: Row(
            children: [
              Text(':', style: kTextStyle.copyWith(color: kSubTitleColor)),
              const SizedBox(width: 20),
              Text(value, style: kTextStyle.copyWith(color: kSubTitleColor)),
            ],
          ),
        ),
      ],
    );
  }
}
