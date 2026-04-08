import 'package:flutter/material.dart';
import 'package:freelancer/services/transaction_service.dart';
import 'package:nb_utils/nb_utils.dart';

import '../../widgets/constant.dart';

class DepositHistory extends StatefulWidget {
  const DepositHistory({Key? key}) : super(key: key);

  @override
  State<DepositHistory> createState() => _DepositHistoryState();
}

class _DepositHistoryState extends State<DepositHistory> {
  List<Map<String, dynamic>> _deposits = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadDeposits();
  }

  Future<void> _loadDeposits() async {
    try {
      final deposits = await TransactionService.getDepositHistory();
      if (mounted) {
        setState(() {
          _deposits = deposits;
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

  String _gatewayLabel(String? gateway) {
    switch (gateway) {
      case 'paypal': return 'PayPal';
      case 'credit_card': return 'Credit Card';
      case 'bkash': return 'bkash';
      default: return gateway ?? 'Unknown';
    }
  }

  String _gatewayImage(String? gateway) {
    switch (gateway) {
      case 'paypal': return 'images/paypal2.png';
      case 'credit_card': return 'images/creditcard.png';
      case 'bkash': return 'images/bkash2.png';
      default: return 'images/paypal2.png';
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: kDarkWhite,
      appBar: AppBar(
        backgroundColor: kDarkWhite,
        elevation: 0,
        iconTheme: const IconThemeData(color: kNeutralColor),
        title: Text(
          'Deposit History',
          style: kTextStyle.copyWith(color: kNeutralColor, fontWeight: FontWeight.bold),
        ),
        centerTitle: true,
      ),
      body: Padding(
        padding: const EdgeInsets.only(top: 20.0),
        child: Container(
          padding: const EdgeInsets.only(left: 20.0, right: 20.0),
          width: context.width(),
          decoration: const BoxDecoration(
            color: kWhite,
            borderRadius: BorderRadius.only(
              topLeft: Radius.circular(30.0),
              topRight: Radius.circular(30.0),
            ),
          ),
          child: _isLoading
              ? const Center(child: CircularProgressIndicator(color: kPrimaryColor))
              : _deposits.isEmpty
                  ? Center(
                      child: Text('No deposit history', style: kTextStyle.copyWith(color: kLightNeutralColor)),
                    )
                  : RefreshIndicator(
                      color: kPrimaryColor,
                      onRefresh: _loadDeposits,
                      child: ListView.builder(
                        physics: const AlwaysScrollableScrollPhysics(parent: BouncingScrollPhysics()),
                        padding: const EdgeInsets.only(top: 20.0, bottom: 20.0),
                        itemCount: _deposits.length,
                        itemBuilder: (_, i) {
                          final deposit = _deposits[i];
                          final gateway = deposit['gateway'] as String?;
                          final status = deposit['status'] ?? 'pending';

                          return Padding(
                            padding: const EdgeInsets.only(bottom: 15.0),
                            child: Container(
                              padding: const EdgeInsets.only(left: 10.0, right: 10.0),
                              decoration: BoxDecoration(
                                borderRadius: BorderRadius.circular(9.0),
                                color: kWhite,
                                border: Border.all(color: kBorderColorTextField),
                                boxShadow: const [
                                  BoxShadow(color: kDarkWhite, spreadRadius: 4.0, blurRadius: 4.0, offset: Offset(0, 0)),
                                ],
                              ),
                              child: ListTile(
                                horizontalTitleGap: 10,
                                contentPadding: EdgeInsets.zero,
                                leading: Container(
                                  height: 44,
                                  width: 44,
                                  decoration: BoxDecoration(
                                    shape: BoxShape.circle,
                                    image: DecorationImage(
                                      image: AssetImage(_gatewayImage(gateway)),
                                      fit: BoxFit.cover,
                                    ),
                                  ),
                                ),
                                title: Row(
                                  children: [
                                    Text(
                                      _gatewayLabel(gateway),
                                      style: kTextStyle.copyWith(color: kNeutralColor, fontWeight: FontWeight.bold),
                                    ),
                                    const Spacer(),
                                    Text(
                                      '$currencySign${deposit['amount'] ?? 0}',
                                      style: kTextStyle.copyWith(color: kNeutralColor, fontWeight: FontWeight.bold),
                                    ),
                                  ],
                                ),
                                subtitle: Row(
                                  children: [
                                    Text(
                                      _formatDate(deposit['created_at']),
                                      style: kTextStyle.copyWith(color: kSubTitleColor),
                                    ),
                                    const Spacer(),
                                    Text(
                                      status.toString().substring(0, 1).toUpperCase() + status.toString().substring(1),
                                      style: kTextStyle.copyWith(
                                        color: status == 'completed' ? kPrimaryColor : kLightNeutralColor,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          );
                        },
                      ),
                    ),
        ),
      ),
    );
  }
}
