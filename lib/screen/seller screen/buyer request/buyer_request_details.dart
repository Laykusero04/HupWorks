import 'package:flutter/material.dart';
import 'package:freelancer/screen/widgets/button_global.dart';
import 'package:freelancer/services/seller_orders_service.dart';
import 'package:nb_utils/nb_utils.dart';

import '../../widgets/constant.dart';
import 'create_customer_offer.dart';

class BuyerRequestDetails extends StatefulWidget {
  final String jobPostId;

  const BuyerRequestDetails({Key? key, required this.jobPostId}) : super(key: key);

  @override
  State<BuyerRequestDetails> createState() => _BuyerRequestDetailsState();
}

class _BuyerRequestDetailsState extends State<BuyerRequestDetails> {
  Map<String, dynamic>? _jobPost;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadDetails();
  }

  Future<void> _loadDetails() async {
    try {
      final data = await SellerOrdersService.getBuyerRequestDetails(widget.jobPostId);
      if (mounted) setState(() { _jobPost = data; _isLoading = false; });
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
    if (_isLoading) return const Scaffold(backgroundColor: kDarkWhite, body: Center(child: CircularProgressIndicator(color: kPrimaryColor)));

    final buyer = _jobPost?['profiles'] as Map<String, dynamic>?;
    final category = (_jobPost?['categories'] as Map<String, dynamic>?)?['name'] ?? 'General';
    final title = _jobPost?['title'] ?? 'Job Post';
    final description = _jobPost?['description'] ?? '';
    final budgetMin = _jobPost?['budget_min'];
    final budgetMax = _jobPost?['budget_max'];
    final offerCount = _jobPost?['offer_count'] ?? 0;

    return Scaffold(
      backgroundColor: kDarkWhite,
      appBar: AppBar(
        backgroundColor: kDarkWhite, elevation: 0, iconTheme: const IconThemeData(color: kNeutralColor),
        title: Text('Buyer Request', style: kTextStyle.copyWith(color: kNeutralColor, fontWeight: FontWeight.bold)), centerTitle: true,
      ),
      bottomNavigationBar: Container(
        decoration: const BoxDecoration(color: kWhite),
        child: ButtonGlobalWithoutIcon(
          buttontext: 'Send Offer',
          buttonDecoration: kButtonDecoration.copyWith(color: kPrimaryColor, borderRadius: BorderRadius.circular(30.0)),
          onPressed: () async {
            await CreateCustomerOffer(jobPostId: widget.jobPostId, jobTitle: title).launch(context);
            _loadDetails();
          },
          buttonTextColor: kWhite,
        ),
      ),
      body: Padding(
        padding: const EdgeInsets.only(top: 15.0),
        child: Container(
          padding: const EdgeInsets.only(left: 15.0, right: 15.0),
          width: context.width(),
          decoration: const BoxDecoration(color: kWhite, borderRadius: BorderRadius.only(topLeft: Radius.circular(30.0), topRight: Radius.circular(30.0))),
          child: SingleChildScrollView(
            physics: const BouncingScrollPhysics(),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SizedBox(height: 15.0),
                // Buyer info
                Row(
                  children: [
                    CircleAvatar(
                      radius: 25,
                      backgroundImage: buyer?['profile_image_url'] != null
                          ? NetworkImage(buyer!['profile_image_url'])
                          : const AssetImage('images/profile1.png') as ImageProvider,
                    ),
                    const SizedBox(width: 10),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(buyer?['name'] ?? 'Buyer', style: kTextStyle.copyWith(color: kNeutralColor, fontWeight: FontWeight.bold)),
                        Text(_formatDate(_jobPost?['created_at']), style: kTextStyle.copyWith(color: kLightNeutralColor)),
                      ],
                    ),
                  ],
                ),
                const SizedBox(height: 15.0),

                // Title
                Text(title, style: kTextStyle.copyWith(color: kNeutralColor, fontWeight: FontWeight.bold, fontSize: 16)),
                const SizedBox(height: 10.0),

                // Description
                ReadMoreText(
                  description,
                  style: kTextStyle.copyWith(color: kSubTitleColor),
                  trimLines: 3, colorClickableText: kPrimaryColor, trimMode: TrimMode.Line,
                  trimCollapsedText: '..Read more', trimExpandedText: '..Read less',
                ),
                const SizedBox(height: 15.0),

                // Details
                _row('Category', category),
                const SizedBox(height: 8.0),
                if (budgetMin != null || budgetMax != null) ...[
                  _row('Budget', '$currencySign${budgetMin ?? 0} - $currencySign${budgetMax ?? 0}'),
                  const SizedBox(height: 8.0),
                ],
                _row('Offers Sent', '$offerCount'),
                const SizedBox(height: 8.0),
                _row('Date', _formatDate(_jobPost?['created_at'])),
                const SizedBox(height: 20.0),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _row(String l, String v) => Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
    Expanded(flex: 2, child: Text(l, style: kTextStyle.copyWith(color: kSubTitleColor))),
    Expanded(flex: 4, child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Text(':', style: kTextStyle.copyWith(color: kSubTitleColor)), const SizedBox(width: 10.0),
      Flexible(child: Text(v, style: kTextStyle.copyWith(color: kSubTitleColor), overflow: TextOverflow.ellipsis, maxLines: 2)),
    ])),
  ]);
}
