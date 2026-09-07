import 'package:flutter/material.dart';
import 'package:freelancer/l10n/l10n.dart';
import 'package:freelancer/services/dashboard_service.dart';
import 'package:nb_utils/nb_utils.dart';

import '../../widgets/constant.dart';

class SellerDashBoard extends StatefulWidget {
  const SellerDashBoard({Key? key}) : super(key: key);

  @override
  State<SellerDashBoard> createState() => _SellerDashBoardState();
}

class _SellerDashBoardState extends State<SellerDashBoard> {
  Map<String, dynamic>? _data;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadDashboard();
  }

  Future<void> _loadDashboard() async {
    try {
      final data = await DashboardService.getSellerDashboard();
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

  String _formatHours(BuildContext context) {
    final minutes = (_data?['hours_worked_minutes'] as num?)?.toDouble() ?? 0;
    final hours = minutes / 60.0;
    final label = hours == hours.roundToDouble()
        ? hours.toInt().toString()
        : hours.toStringAsFixed(1);
    return context.l10n.hoursWorkedFormat(label);
  }

  String _formatMoney(String key) {
    final value = (_data?[key] as num?)?.toDouble() ?? 0;
    if (value == value.roundToDouble()) {
      return '$currencySign${value.toInt()}';
    }
    return '$currencySign${value.toStringAsFixed(2)}';
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;

    if (_isLoading) {
      return const Scaffold(
        backgroundColor: kDarkWhite,
        body: Center(child: CircularProgressIndicator(color: kPrimaryColor)),
      );
    }

    final jobsCompleted = (_data?['jobs_completed'] as num?)?.toInt() ?? 0;
    final activeContracts = (_data?['active_contracts'] as num?)?.toInt() ?? 0;

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
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                  decoration: BoxDecoration(
                    color: kDarkWhite,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: kBorderColorTextField),
                  ),
                  child: Text(
                    l10n.workOverviewDisclaimer,
                    style: kTextStyle.copyWith(
                      color: kSubTitleColor,
                      fontSize: 12,
                      height: 1.35,
                    ),
                  ),
                ),
                const SizedBox(height: 14.0),
                Row(
                  children: [
                    Expanded(
                      child: DashBoardInfo(
                        count: _formatHours(context),
                        title: l10n.hoursWorked,
                        image: 'images/td.png',
                      ),
                    ),
                    const SizedBox(width: 10.0),
                    Expanded(
                      child: DashBoardInfo(
                        count: _formatMoney('agreed_contract_value'),
                        title: l10n.agreedContractValue,
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
                        count: _formatMoney('payment_received_value'),
                        title: l10n.paymentReceivedValue,
                        image: 'images/co.png',
                      ),
                    ),
                    const SizedBox(width: 10.0),
                    Expanded(
                      child: DashBoardInfo(
                        count: _formatMoney('outstanding_value'),
                        title: l10n.outstandingValue,
                        image: 'images/io.png',
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 10.0),
                Row(
                  children: [
                    Expanded(
                      child: DashBoardInfo(
                        count: '$jobsCompleted',
                        title: l10n.jobsCompleted,
                        image: 'images/co.png',
                      ),
                    ),
                    const SizedBox(width: 10.0),
                    Expanded(
                      child: DashBoardInfo(
                        count: '$activeContracts',
                        title: l10n.activeContracts,
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
