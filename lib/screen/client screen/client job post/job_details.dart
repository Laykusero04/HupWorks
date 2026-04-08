import 'package:flutter/material.dart';
import 'package:freelancer/screen/widgets/button_global.dart';
import 'package:freelancer/services/job_posts_service.dart';
import 'package:nb_utils/nb_utils.dart';

import '../../widgets/constant.dart';

class JobDetails extends StatefulWidget {
  final String jobPostId;

  const JobDetails({Key? key, required this.jobPostId}) : super(key: key);

  @override
  State<JobDetails> createState() => _JobDetailsState();
}

class _JobDetailsState extends State<JobDetails> {
  Map<String, dynamic>? _jobPost;
  List<Map<String, dynamic>> _offers = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    try {
      final results = await Future.wait([
        JobPostsService.getJobPostDetails(widget.jobPostId),
        JobPostsService.getJobOffers(widget.jobPostId),
      ]);
      if (mounted) {
        setState(() {
          _jobPost = results[0] as Map<String, dynamic>;
          _offers = results[1] as List<Map<String, dynamic>>;
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

  Future<void> _handleCloseJob() async {
    try {
      await JobPostsService.closeJobPost(widget.jobPostId);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Job post closed')),
        );
        Navigator.pop(context);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: $e')));
      }
    }
  }

  Future<void> _handleOfferAction(String offerId, String status) async {
    try {
      await JobPostsService.updateOfferStatus(offerId, status);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Offer ${status}')),
        );
        _loadData();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: $e')));
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

    final title = _jobPost?['title'] ?? 'Job Post';
    final description = _jobPost?['description'] ?? '';
    final category = (_jobPost?['categories'] as Map<String, dynamic>?)?['name'] ?? 'General';
    final status = _jobPost?['status'] ?? 'open';
    final budgetMin = _jobPost?['budget_min'];
    final budgetMax = _jobPost?['budget_max'];
    final isOpen = status == 'open';

    return Scaffold(
      backgroundColor: kDarkWhite,
      appBar: AppBar(
        backgroundColor: kDarkWhite,
        elevation: 0,
        iconTheme: const IconThemeData(color: kNeutralColor),
        title: Text(
          'Job Details',
          style: kTextStyle.copyWith(color: kNeutralColor, fontWeight: FontWeight.bold),
        ),
        centerTitle: true,
        actions: [
          if (isOpen)
            PopupMenuButton(
              padding: EdgeInsets.zero,
              itemBuilder: (BuildContext context) => [
                PopupMenuItem(
                  child: Text('Close Job', style: kTextStyle.copyWith(color: Colors.red))
                      .onTap(() => _handleCloseJob()),
                ),
              ],
              onSelected: (value) {},
              child: const Padding(
                padding: EdgeInsets.only(right: 10.0),
                child: Icon(Icons.more_vert_rounded, color: kNeutralColor),
              ),
            ),
        ],
      ),
      body: Container(
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
              // Job info card
              Container(
                padding: const EdgeInsets.all(10.0),
                width: context.width(),
                decoration: BoxDecoration(
                  color: kWhite,
                  borderRadius: BorderRadius.circular(8.0),
                  border: Border.all(color: kBorderColorTextField),
                  boxShadow: const [BoxShadow(color: kDarkWhite, spreadRadius: 4.0, blurRadius: 4.0, offset: Offset(0, 2))],
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(title, style: kTextStyle.copyWith(color: kNeutralColor, fontWeight: FontWeight.bold)),
                    const SizedBox(height: 10.0),
                    ReadMoreText(
                      description,
                      style: kTextStyle.copyWith(color: kSubTitleColor),
                      trimLines: 2,
                      colorClickableText: kPrimaryColor,
                      trimMode: TrimMode.Line,
                      trimCollapsedText: '..Read more',
                      trimExpandedText: '..Read less',
                    ),
                    const SizedBox(height: 15.0),
                    _buildRow('Category', category),
                    const SizedBox(height: 8.0),
                    if (budgetMin != null || budgetMax != null)
                      ...[
                        _buildRow('Budget', '$currencySign${budgetMin ?? 0} - $currencySign${budgetMax ?? 0}'),
                        const SizedBox(height: 8.0),
                      ],
                    _buildRow('Status', status.toString().substring(0, 1).toUpperCase() + status.toString().substring(1)),
                    const SizedBox(height: 8.0),
                    _buildRow('Date', _formatDate(_jobPost?['created_at'])),
                  ],
                ),
              ),

              // Offers section
              const SizedBox(height: 20.0),
              Text(
                'Seller Offers (${_offers.length})',
                style: kTextStyle.copyWith(color: kNeutralColor, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 10.0),
              _offers.isEmpty
                  ? Padding(
                      padding: const EdgeInsets.all(20.0),
                      child: Center(
                        child: Text('No offers yet', style: kTextStyle.copyWith(color: kLightNeutralColor)),
                      ),
                    )
                  : ListView.builder(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      itemCount: _offers.length,
                      itemBuilder: (_, i) {
                        final offer = _offers[i];
                        final seller = offer['profiles'] as Map<String, dynamic>?;
                        final offerStatus = offer['status'] ?? 'pending';

                        return Container(
                          margin: const EdgeInsets.only(bottom: 10.0),
                          padding: const EdgeInsets.all(10.0),
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(8.0),
                            border: Border.all(color: kBorderColorTextField),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  CircleAvatar(
                                    radius: 20,
                                    backgroundImage: seller?['profile_image_url'] != null
                                        ? NetworkImage(seller!['profile_image_url'])
                                        : const AssetImage('images/profilepic2.png') as ImageProvider,
                                  ),
                                  const SizedBox(width: 10),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          seller?['name'] ?? 'Seller',
                                          style: kTextStyle.copyWith(color: kNeutralColor, fontWeight: FontWeight.bold),
                                        ),
                                        Text(
                                          '$currencySign${offer['price']} • ${offer['delivery_time']} days',
                                          style: kTextStyle.copyWith(color: kSubTitleColor),
                                        ),
                                      ],
                                    ),
                                  ),
                                  Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                    decoration: BoxDecoration(
                                      borderRadius: BorderRadius.circular(12),
                                      color: offerStatus == 'accepted'
                                          ? kPrimaryColor.withOpacity(0.1)
                                          : offerStatus == 'rejected'
                                              ? Colors.red.withOpacity(0.1)
                                              : kDarkWhite,
                                    ),
                                    child: Text(
                                      offerStatus.toString().substring(0, 1).toUpperCase() + offerStatus.toString().substring(1),
                                      style: kTextStyle.copyWith(
                                        color: offerStatus == 'accepted' ? kPrimaryColor : offerStatus == 'rejected' ? Colors.red : kNeutralColor,
                                        fontSize: 12,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                              if (offer['cover_letter'] != null && offer['cover_letter'].toString().isNotEmpty) ...[
                                const SizedBox(height: 8),
                                Text(
                                  offer['cover_letter'],
                                  style: kTextStyle.copyWith(color: kSubTitleColor),
                                  maxLines: 3,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ],
                              if (offerStatus == 'pending' && isOpen) ...[
                                const SizedBox(height: 10),
                                Row(
                                  children: [
                                    Expanded(
                                      child: ButtonGlobalWithoutIcon(
                                        buttontext: 'Reject',
                                        buttonDecoration: kButtonDecoration.copyWith(
                                          color: kWhite,
                                          border: Border.all(color: Colors.red),
                                        ),
                                        onPressed: () => _handleOfferAction(offer['id'], 'rejected'),
                                        buttonTextColor: Colors.red,
                                      ),
                                    ),
                                    Expanded(
                                      child: ButtonGlobalWithoutIcon(
                                        buttontext: 'Accept',
                                        buttonDecoration: kButtonDecoration.copyWith(color: kPrimaryColor),
                                        onPressed: () => _handleOfferAction(offer['id'], 'accepted'),
                                        buttonTextColor: kWhite,
                                      ),
                                    ),
                                  ],
                                ),
                              ],
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
    );
  }

  Widget _buildRow(String label, String value) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(
          flex: 2,
          child: Text(label, style: kTextStyle.copyWith(color: kSubTitleColor)),
        ),
        Expanded(
          flex: 4,
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(':', style: kTextStyle.copyWith(color: kSubTitleColor)),
              const SizedBox(width: 10.0),
              Flexible(
                child: Text(value, style: kTextStyle.copyWith(color: kSubTitleColor), overflow: TextOverflow.ellipsis, maxLines: 2),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
