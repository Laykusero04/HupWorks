import 'package:flutter/material.dart';
import 'package:freelancer/services/transaction_service.dart';
import 'package:nb_utils/nb_utils.dart';

import '../../widgets/constant.dart';

class ClientTransaction extends StatefulWidget {
  const ClientTransaction({Key? key}) : super(key: key);

  @override
  State<ClientTransaction> createState() => _ClientTransactionState();
}

class _ClientTransactionState extends State<ClientTransaction> {
  List<Map<String, dynamic>> _transactions = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadTransactions();
  }

  Future<void> _loadTransactions() async {
    try {
      final txns = await TransactionService.getTransactions();
      if (mounted) {
        setState(() {
          _transactions = txns;
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

  String _typeLabel(String? type) {
    switch (type) {
      case 'deposit': return 'Deposit';
      case 'withdrawal': return 'Withdrawal';
      case 'earning': return 'Earning';
      case 'payment': return 'Payment';
      default: return type ?? '';
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
          'Transaction',
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
          child: _isLoading
              ? const Center(child: CircularProgressIndicator(color: kPrimaryColor))
              : _transactions.isEmpty
                  ? Center(
                      child: Text('No transactions yet', style: kTextStyle.copyWith(color: kLightNeutralColor)),
                    )
                  : RefreshIndicator(
                      color: kPrimaryColor,
                      onRefresh: _loadTransactions,
                      child: ListView.builder(
                        physics: const AlwaysScrollableScrollPhysics(parent: BouncingScrollPhysics()),
                        padding: const EdgeInsets.only(top: 15.0, bottom: 15.0),
                        itemCount: _transactions.length,
                        itemBuilder: (_, i) {
                          final tx = _transactions[i];
                          final type = tx['type'] as String?;
                          final isPositive = type == 'deposit' || type == 'earning';

                          return Padding(
                            padding: const EdgeInsets.only(bottom: 10.0),
                            child: Container(
                              padding: const EdgeInsets.all(8.0),
                              decoration: BoxDecoration(
                                color: kWhite,
                                borderRadius: BorderRadius.circular(10.0),
                                border: Border.all(color: kBorderColorTextField),
                                boxShadow: const [
                                  BoxShadow(color: kDarkWhite, blurRadius: 4.0, spreadRadius: 2.0, offset: Offset(0, 2)),
                                ],
                              ),
                              child: ListTile(
                                visualDensity: const VisualDensity(vertical: -3),
                                contentPadding: EdgeInsets.zero,
                                horizontalTitleGap: 10,
                                leading: Container(
                                  height: 44,
                                  width: 44,
                                  decoration: BoxDecoration(
                                    shape: BoxShape.circle,
                                    color: isPositive ? kPrimaryColor.withOpacity(0.1) : Colors.red.withOpacity(0.1),
                                  ),
                                  child: Icon(
                                    isPositive ? Icons.arrow_downward : Icons.arrow_upward,
                                    color: isPositive ? kPrimaryColor : Colors.red,
                                  ),
                                ),
                                title: Text(
                                  _typeLabel(type),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: kTextStyle.copyWith(color: kNeutralColor, fontWeight: FontWeight.bold),
                                ),
                                subtitle: Text(
                                  _formatDate(tx['created_at']),
                                  maxLines: 1,
                                  style: kTextStyle.copyWith(color: kLightNeutralColor),
                                ),
                                trailing: Text(
                                  '${isPositive ? '+' : '-'}$currencySign${tx['amount'] ?? 0}',
                                  maxLines: 1,
                                  style: kTextStyle.copyWith(
                                    color: isPositive ? kPrimaryColor : Colors.red,
                                    fontWeight: FontWeight.bold,
                                  ),
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
