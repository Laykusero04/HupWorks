import 'package:flutter/material.dart';
import 'package:freelancer/screen/widgets/button_global.dart';
import 'package:freelancer/services/job_posts_service.dart';
import 'package:freelancer/services/seller_orders_service.dart';
import 'package:nb_utils/nb_utils.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../widgets/constant.dart';
import '../../widgets/job_client_info_card.dart';
import '../../widgets/job_location_map_preview.dart';
import 'create_customer_offer.dart';

class BuyerRequestDetails extends StatefulWidget {
  final String jobPostId;

  const BuyerRequestDetails({Key? key, required this.jobPostId}) : super(key: key);

  /// Parent seller shell uses a floating capsule nav; inner [Scaffold.bottomNavigationBar]
  /// sits under it unless we add this lift (see client Job Post FAB pattern).
  static const double _shellFloatingNavLift = 72;

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

    final category = (_jobPost?['categories'] as Map<String, dynamic>?)?['name'] ?? 'General';
    final title = _jobPost?['title'] ?? 'Job Post';
    final description = _jobPost?['description'] ?? '';
    final budgetMin = _jobPost?['budget_min'];
    final budgetMax = _jobPost?['budget_max'];
    final offerCount = _jobPost?['offer_count'] ?? 0;
    final jobStatus = (_jobPost?['status'] as String?) ?? 'open';
    final myUid = Supabase.instance.client.auth.currentUser?.id;
    final clientId = _jobPost?['client_id'] as String?;
    final myOffer = _jobPost?['my_offer'] as Map<String, dynamic>?;

    String? applyBlockedReason() {
      if (jobStatus.toLowerCase() != 'open') {
        return 'This job is closed and is not accepting applications.';
      }
      if (myUid != null && clientId != null && myUid == clientId) {
        return 'You cannot apply to your own job post.';
      }
      if (myOffer != null) {
        final st = (myOffer['status'] as String?)?.toLowerCase();
        if (st == 'pending' || st == 'accepted') {
          return 'You have already submitted an application for this job.';
        }
      }
      return null;
    }

    final applyBlock = applyBlockedReason();
    final canApply = applyBlock == null;

    final bottomLift = MediaQuery.paddingOf(context).bottom + BuyerRequestDetails._shellFloatingNavLift;

    return Scaffold(
      backgroundColor: kDarkWhite,
      appBar: AppBar(
        backgroundColor: kDarkWhite, elevation: 0, iconTheme: const IconThemeData(color: kNeutralColor),
        title: Text('Job Details', style: kTextStyle.copyWith(color: kNeutralColor, fontWeight: FontWeight.bold)), centerTitle: true,
      ),
      bottomNavigationBar: Material(
        color: kWhite,
        elevation: 12,
        shadowColor: Colors.black26,
        child: Padding(
          padding: EdgeInsets.fromLTRB(16, 8, 16, bottomLift),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (!canApply)
                Padding(
                  padding: const EdgeInsets.only(bottom: 8),
                  child: Text(
                    applyBlock,
                    textAlign: TextAlign.center,
                    style: kTextStyle.copyWith(color: const Color(0xFF92400E), fontSize: 13, height: 1.35),
                  ),
                ),
              ButtonGlobalWithoutIcon(
                buttontext: canApply ? 'Submit offer' : 'Cannot submit offer',
                buttonDecoration: kButtonDecoration.copyWith(
                  color: canApply ? kPrimaryColor : kLightNeutralColor,
                  borderRadius: BorderRadius.circular(30.0),
                ),
                onPressed: !canApply
                    ? () {
                        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(applyBlock)));
                      }
                    : () async {
                        await CreateCustomerOffer(
                          jobPostId: widget.jobPostId,
                          jobTitle: title,
                          budgetMin: budgetMin,
                          budgetMax: budgetMax,
                          budgetBasis: _jobPost?['budget_basis'],
                        ).launch(context);
                        _loadDetails();
                      },
                buttonTextColor: kWhite,
              ),
            ],
          ),
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
                JobClientInfoCard.fromJobPost(_jobPost),
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
                  _row('Budget', JobPostsService.formatBudgetRange(budgetMin, budgetMax, _jobPost?['budget_basis'])),
                  const SizedBox(height: 8.0),
                ],
                _buildLocationSection(_jobPost),
                _row('Workers needed', JobPostsService.workersNeededDetailLabel(_jobPost?['workers_needed'])),
                const SizedBox(height: 8.0),
                _row('Offers Sent', '$offerCount'),
                const SizedBox(height: 8.0),
                _row('Job posted', _formatDate(_jobPost?['created_at'])),
                SizedBox(height: bottomLift + 24),
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

  Widget _buildLocationSection(Map<String, dynamic>? job) {
    final location = (job?['location'] as String?)?.trim();
    final locationType = (job?['location_type'] as String?)?.trim();
    final coords = jobPostCoordinates(job);
    if ((location == null || location.isEmpty) && coords == null && locationType == null) {
      return const SizedBox.shrink();
    }
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (locationType != null && locationType.isNotEmpty) ...[
          const SizedBox(height: 8),
          Row(children: [
            Text('Location', style: kTextStyle.copyWith(color: kSubTitleColor)),
            const SizedBox(width: 8),
            Text(':', style: kTextStyle.copyWith(color: kSubTitleColor)),
            const SizedBox(width: 10),
            _locationTypeBadge(locationType),
          ]),
          const SizedBox(height: 8),
        ],
        if (coords != null) ...[
          JobLocationSection(job: job),
          const SizedBox(height: 8),
        ] else if (location != null && location.isNotEmpty) ...[
          _row('Area', location),
          const SizedBox(height: 8),
        ],
      ],
    );
  }

  Widget _locationTypeBadge(String type) {
    final (Color bg, Color fg, IconData icon) = switch (type) {
      'On-site' => (const Color(0xFFE8F5E9), const Color(0xFF2E7D32), Icons.location_on_outlined),
      _         => (const Color(0xFFE3F2FD), const Color(0xFF1565C0), Icons.laptop_outlined),
    };
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(color: bg, borderRadius: BorderRadius.circular(20)),
      child: Row(mainAxisSize: MainAxisSize.min, children: [
        Icon(icon, size: 14, color: fg),
        const SizedBox(width: 4),
        Text(type, style: kTextStyle.copyWith(color: fg, fontSize: 12, fontWeight: FontWeight.bold)),
      ]),
    );
  }
}
