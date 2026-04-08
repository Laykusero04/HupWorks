import 'package:flutter/material.dart';
import 'package:nb_utils/nb_utils.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../widgets/constant.dart';

class SellerWithDrawHistory extends StatefulWidget {
  const SellerWithDrawHistory({Key? key}) : super(key: key);

  @override
  State<SellerWithDrawHistory> createState() => _SellerWithDrawHistoryState();
}

class _SellerWithDrawHistoryState extends State<SellerWithDrawHistory> {
  List<Map<String, dynamic>> _withdrawals = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadHistory();
  }

  Future<void> _loadHistory() async {
    try {
      final client = Supabase.instance.client;
      final user = client.auth.currentUser;
      if (user == null) { setState(() => _isLoading = false); return; }

      final data = await client
          .from('withdrawal_requests')
          .select()
          .eq('seller_id', user.id)
          .order('created_at', ascending: false);

      if (mounted) setState(() { _withdrawals = List<Map<String, dynamic>>.from(data); _isLoading = false; });
    } catch (e) {
      if (mounted) { setState(() => _isLoading = false); ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: $e'))); }
    }
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
        title: Text('Withdraw History', style: kTextStyle.copyWith(color: kNeutralColor, fontWeight: FontWeight.bold)), centerTitle: true),
      body: Padding(
        padding: const EdgeInsets.only(top: 20.0),
        child: Container(
          padding: const EdgeInsets.only(left: 20.0, right: 20.0), width: context.width(),
          decoration: const BoxDecoration(color: kWhite, borderRadius: BorderRadius.only(topLeft: Radius.circular(30.0), topRight: Radius.circular(30.0))),
          child: _isLoading
              ? const Center(child: CircularProgressIndicator(color: kPrimaryColor))
              : _withdrawals.isEmpty
                  ? Center(child: Text('No withdrawal history', style: kTextStyle.copyWith(color: kLightNeutralColor)))
                  : RefreshIndicator(
                      color: kPrimaryColor, onRefresh: _loadHistory,
                      child: ListView.builder(
                        physics: const AlwaysScrollableScrollPhysics(parent: BouncingScrollPhysics()),
                        padding: const EdgeInsets.only(top: 20.0, bottom: 20.0),
                        itemCount: _withdrawals.length,
                        itemBuilder: (_, i) {
                          final w = _withdrawals[i];
                          final status = w['status'] ?? 'pending';
                          return Padding(
                            padding: const EdgeInsets.only(bottom: 15.0),
                            child: Container(
                              padding: const EdgeInsets.all(12.0),
                              decoration: BoxDecoration(borderRadius: BorderRadius.circular(9.0), color: kWhite, border: Border.all(color: kBorderColorTextField),
                                boxShadow: const [BoxShadow(color: kDarkWhite, spreadRadius: 4.0, blurRadius: 4.0, offset: Offset(0, 0))]),
                              child: Row(children: [
                                Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                                  Text('$currencySign${w['amount'] ?? 0}', style: kTextStyle.copyWith(color: kNeutralColor, fontWeight: FontWeight.bold)),
                                  const SizedBox(height: 4),
                                  Text(_formatDate(w['created_at']), style: kTextStyle.copyWith(color: kSubTitleColor)),
                                ])),
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                                  decoration: BoxDecoration(borderRadius: BorderRadius.circular(20),
                                    color: status == 'approved' ? kPrimaryColor.withOpacity(0.1) : status == 'rejected' ? Colors.red.withOpacity(0.1) : kDarkWhite),
                                  child: Text(status.toString().substring(0, 1).toUpperCase() + status.toString().substring(1),
                                    style: kTextStyle.copyWith(color: status == 'approved' ? kPrimaryColor : status == 'rejected' ? Colors.red : kNeutralColor)),
                                ),
                              ]),
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
