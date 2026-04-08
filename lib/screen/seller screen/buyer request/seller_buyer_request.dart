import 'package:flutter/material.dart';
import 'package:freelancer/services/seller_orders_service.dart';
import 'package:nb_utils/nb_utils.dart';

import '../../widgets/constant.dart';
import 'buyer_request_details.dart';

class SellerBuyerRequest extends StatefulWidget {
  const SellerBuyerRequest({Key? key}) : super(key: key);

  @override
  State<SellerBuyerRequest> createState() => _SellerBuyerRequestState();
}

class _SellerBuyerRequestState extends State<SellerBuyerRequest> {
  List<Map<String, dynamic>> _requests = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadRequests();
  }

  Future<void> _loadRequests() async {
    try {
      final reqs = await SellerOrdersService.getBuyerRequests();
      if (mounted) setState(() { _requests = reqs; _isLoading = false; });
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
      appBar: AppBar(
        backgroundColor: kDarkWhite, elevation: 0, iconTheme: const IconThemeData(color: kNeutralColor),
        title: Text('Buyer Requests', style: kTextStyle.copyWith(color: kNeutralColor, fontWeight: FontWeight.bold)), centerTitle: true,
      ),
      body: Padding(
        padding: const EdgeInsets.only(top: 10.0),
        child: Container(
          width: context.width(),
          padding: const EdgeInsets.only(left: 15.0, right: 15.0),
          decoration: const BoxDecoration(color: kWhite, borderRadius: BorderRadius.only(topLeft: Radius.circular(30.0), topRight: Radius.circular(30.0))),
          child: _isLoading
              ? const Center(child: CircularProgressIndicator(color: kPrimaryColor))
              : _requests.isEmpty
                  ? Center(child: Text('No buyer requests', style: kTextStyle.copyWith(color: kLightNeutralColor)))
                  : RefreshIndicator(
                      color: kPrimaryColor,
                      onRefresh: _loadRequests,
                      child: ListView.builder(
                        physics: const AlwaysScrollableScrollPhysics(parent: BouncingScrollPhysics()),
                        padding: const EdgeInsets.only(top: 15.0, bottom: 15.0),
                        itemCount: _requests.length,
                        itemBuilder: (_, i) {
                          final req = _requests[i];
                          final buyer = req['profiles'] as Map<String, dynamic>?;
                          final category = req['categories'] as Map<String, dynamic>?;

                          return Padding(
                            padding: const EdgeInsets.only(bottom: 10.0),
                            child: GestureDetector(
                              onTap: () async {
                                await BuyerRequestDetails(jobPostId: req['id']).launch(context);
                                _loadRequests();
                              },
                              child: Container(
                                padding: const EdgeInsets.all(10.0),
                                decoration: BoxDecoration(
                                  borderRadius: BorderRadius.circular(10.0), color: kWhite,
                                  border: Border.all(color: kBorderColorTextField),
                                ),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Row(
                                      children: [
                                        CircleAvatar(
                                          radius: 20,
                                          backgroundImage: buyer?['profile_image_url'] != null
                                              ? NetworkImage(buyer!['profile_image_url'])
                                              : const AssetImage('images/profile1.png') as ImageProvider,
                                        ),
                                        const SizedBox(width: 10),
                                        Expanded(
                                          child: Column(
                                            crossAxisAlignment: CrossAxisAlignment.start,
                                            children: [
                                              Text(buyer?['name'] ?? 'Buyer', style: kTextStyle.copyWith(color: kNeutralColor, fontWeight: FontWeight.bold)),
                                              Text(_formatDate(req['created_at']), style: kTextStyle.copyWith(color: kLightNeutralColor)),
                                            ],
                                          ),
                                        ),
                                      ],
                                    ),
                                    const SizedBox(height: 10.0),
                                    Text(req['title'] ?? 'Job Post', style: kTextStyle.copyWith(color: kNeutralColor, fontWeight: FontWeight.bold)),
                                    const SizedBox(height: 5.0),
                                    Text(req['description'] ?? '', maxLines: 2, overflow: TextOverflow.ellipsis, style: kTextStyle.copyWith(color: kSubTitleColor)),
                                    const SizedBox(height: 10.0),
                                    Row(
                                      children: [
                                        Container(
                                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                                          decoration: BoxDecoration(borderRadius: BorderRadius.circular(20), color: kDarkWhite),
                                          child: Text(category?['name'] ?? 'General', style: kTextStyle.copyWith(color: kNeutralColor)),
                                        ),
                                        const Spacer(),
                                        if (req['budget_min'] != null || req['budget_max'] != null)
                                          Text('$currencySign${req['budget_min'] ?? 0} - $currencySign${req['budget_max'] ?? 0}',
                                            style: kTextStyle.copyWith(color: kPrimaryColor, fontWeight: FontWeight.bold)),
                                      ],
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
