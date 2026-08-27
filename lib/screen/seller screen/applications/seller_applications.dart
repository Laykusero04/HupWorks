import 'package:flutter/material.dart';
import 'package:freelancer/l10n/l10n.dart';
import 'package:freelancer/services/chat_service.dart';
import 'package:freelancer/services/attendance_service.dart';
import 'package:freelancer/services/hire_onboarding_service.dart';
import 'package:freelancer/services/job_posts_service.dart';
import 'package:freelancer/services/seller_orders_service.dart';
import 'package:go_router/go_router.dart';
import 'package:nb_utils/nb_utils.dart';

import '../../widgets/constant.dart';
import '../buyer request/buyer_request_details.dart';
import '../seller message/chat_inbox.dart';

class SellerApplications extends StatefulWidget {
  const SellerApplications({super.key});

  @override
  State<SellerApplications> createState() => _SellerApplicationsState();
}

class _SellerApplicationsState extends State<SellerApplications> {
  List<Map<String, dynamic>> _applications = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    try {
      final apps = await SellerOrdersService.getMyApplications();
      for (final app in apps) {
        if ((app['status'] as String?)?.toLowerCase() != 'accepted') continue;
        final offerId = app['id'] as String?;
        if (offerId == null) continue;
        final orderId = await HireOnboardingService.getOrderIdForJobOffer(offerId);
        if (orderId == null) continue;
        app['order_id'] = orderId;
        final packet = await HireOnboardingService.getPacketForOrder(
          orderId,
          sellerView: true,
        );
        app['instructions_pending'] =
            packet != null && packet.isPublished && !packet.acknowledged;
      }
      if (mounted) {
        setState(() {
          _applications = apps;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(context.l10n.errorLoadingApplications('$e'))),
        );
      }
    }
  }

  String _formatDate(String? s) {
    if (s == null) return '';
    final d = DateTime.tryParse(s);
    if (d == null) return '';
    const m = ['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', 'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'];
    return '${d.day} ${m[d.month - 1]} ${d.year}';
  }

  String _jobTypeLabel(String? t) {
    switch (t) {
      case 'full_time':
        return 'Full-time';
      case 'part_time':
        return 'Part-time';
      case 'gig':
      default:
        return 'Gig';
    }
  }

  Future<void> _openChatWithClient(Map<String, dynamic> app) async {
    final jobPost = app['job_posts'] as Map<String, dynamic>?;
    final client = jobPost?['client'] as Map<String, dynamic>?;
    final clientId = jobPost?['client_id'] as String?;
    if (clientId == null) return;
    try {
      final conversation = await ChatService.getOrCreateConversation(clientId);
      if (!mounted) return;
      ChatInbox(
        conversationId: conversation['id'] as String,
        otherUserName: client?['name'] ?? 'Client',
        otherUserImage: client?['profile_image_url'] ?? '',
        otherUserId: clientId,
      ).launch(context);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(context.l10n.couldNotOpenChatWithDetail('$e'))),
        );
      }
    }
  }

  ({Color bg, Color fg, String label}) _statusStyle(String? status) {
    final (fg, bg) = StatusColors.application(status);
    switch (status) {
      case 'accepted':
        return (bg: bg, fg: fg, label: 'Accepted');
      case 'rejected':
        return (bg: bg, fg: fg, label: 'Rejected');
      case 'pending':
      default:
        return (bg: bg, fg: fg, label: 'Pending');
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
          'My Applications',
          style: kTextStyle.copyWith(color: kNeutralColor, fontWeight: FontWeight.bold),
        ),
        centerTitle: true,
      ),
      body: Padding(
        padding: const EdgeInsets.only(top: 10.0),
        child: Container(
          width: context.width(),
          padding: const EdgeInsets.symmetric(horizontal: 15.0),
          decoration: const BoxDecoration(
            color: kWhite,
            borderRadius: BorderRadius.only(
              topLeft: Radius.circular(30.0),
              topRight: Radius.circular(30.0),
            ),
          ),
          child: _isLoading
              ? const Center(child: CircularProgressIndicator(color: kPrimaryColor))
              : _applications.isEmpty
                  ? Center(
                      child: Text(
                        'You haven\'t applied to any jobs yet',
                        style: kTextStyle.copyWith(color: kLightNeutralColor),
                      ),
                    )
                  : RefreshIndicator(
                      color: kPrimaryColor,
                      onRefresh: _load,
                      child: ListView.builder(
                        physics: const AlwaysScrollableScrollPhysics(parent: BouncingScrollPhysics()),
                        padding: const EdgeInsets.only(top: 15.0, bottom: 15.0),
                        itemCount: _applications.length,
                        itemBuilder: (_, i) {
                          final app = _applications[i];
                          final jobPost = app['job_posts'] as Map<String, dynamic>?;
                          final status = _statusStyle(app['status'] as String?);

                          return Padding(
                            padding: const EdgeInsets.only(bottom: 10.0),
                            child: Material(
                              color: kWhite,
                              borderRadius: BorderRadius.circular(10.0),
                              child: InkWell(
                                borderRadius: BorderRadius.circular(10.0),
                                onTap: () {
                                  final id = jobPost?['id'] as String?;
                                  if (id == null) return;
                                  BuyerRequestDetails(jobPostId: id).launch(context);
                                },
                                child: Container(
                              padding: const EdgeInsets.all(12.0),
                              decoration: BoxDecoration(
                                borderRadius: BorderRadius.circular(10.0),
                                border: Border.all(color: kBorderColorTextField),
                              ),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Row(
                                    children: [
                                      Expanded(
                                        child: Text(
                                          jobPost?['title'] ?? 'Untitled job',
                                          maxLines: 1,
                                          overflow: TextOverflow.ellipsis,
                                          style: kTextStyle.copyWith(color: kNeutralColor, fontWeight: FontWeight.bold),
                                        ),
                                      ),
                                      const SizedBox(width: 8.0),
                                      Container(
                                        padding: const EdgeInsets.symmetric(vertical: 3.0, horizontal: 8.0),
                                        decoration: BoxDecoration(
                                          borderRadius: BorderRadius.circular(20.0),
                                          color: status.bg,
                                        ),
                                        child: Text(
                                          status.label,
                                          style: kTextStyle.copyWith(color: status.fg, fontSize: 12.0),
                                        ),
                                      ),
                                      IconButton(
                                        visualDensity: VisualDensity.compact,
                                        padding: EdgeInsets.zero,
                                        constraints: const BoxConstraints(minWidth: 36, minHeight: 36),
                                        tooltip: 'Message client',
                                        icon: const Icon(Icons.chat_bubble_outline, size: 20, color: kPrimaryColor),
                                        onPressed: () => _openChatWithClient(app),
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 8.0),
                                  Row(
                                    children: [
                                      Container(
                                        padding: const EdgeInsets.symmetric(vertical: 2.0, horizontal: 8.0),
                                        decoration: BoxDecoration(
                                          borderRadius: BorderRadius.circular(20.0),
                                          color: kDarkWhite,
                                        ),
                                        child: Text(
                                          _jobTypeLabel(jobPost?['job_type'] as String?),
                                          style: kTextStyle.copyWith(color: kNeutralColor, fontSize: 12.0),
                                        ),
                                      ),
                                      const SizedBox(width: 10.0),
                                      Text(
                                        JobPostsService.formatOfferAmountShort(app['price'], app['price_basis']),
                                        style: kTextStyle.copyWith(color: kPrimaryColor, fontWeight: FontWeight.bold),
                                      ),
                                      const Spacer(),
                                      Text(
                                        _formatDate(app['created_at'] as String?),
                                        style: kTextStyle.copyWith(color: kLightNeutralColor),
                                      ),
                                    ],
                                  ),
                                  if ((app['cover_letter'] as String?)?.isNotEmpty ?? false) ...[
                                    const SizedBox(height: 8.0),
                                    Text(
                                      app['cover_letter'] as String,
                                      maxLines: 2,
                                      overflow: TextOverflow.ellipsis,
                                      style: kTextStyle.copyWith(color: kSubTitleColor),
                                    ),
                                  ],
                                  if ((app['status'] as String?)?.toLowerCase() ==
                                          'accepted' &&
                                      AttendanceService.isOnsiteJob(
                                        jobPost,
                                      )) ...[
                                    const SizedBox(height: 8),
                                    InkWell(
                                      onTap: () => context.push(
                                        '/seller/attendance?jobPostId=${jobPost?['id']}',
                                      ),
                                      child: Container(
                                        width: double.infinity,
                                        padding: const EdgeInsets.symmetric(
                                          horizontal: 10,
                                          vertical: 8,
                                        ),
                                        decoration: BoxDecoration(
                                          color: kDarkWhite,
                                          borderRadius: BorderRadius.circular(8),
                                          border: Border.all(
                                            color: kBorderColorTextField,
                                          ),
                                        ),
                                        child: Text(
                                          'Open attendance',
                                          style: kTextStyle.copyWith(
                                            color: kPrimaryColor,
                                            fontSize: 13,
                                            fontWeight: FontWeight.w600,
                                          ),
                                        ),
                                      ),
                                    ),
                                  ],
                                  if (app['instructions_pending'] == true) ...[
                                    const SizedBox(height: 8.0),
                                    InkWell(
                                      onTap: () async {
                                        final orderId = app['order_id'] as String?;
                                        if (orderId == null) return;
                                        context.push('/seller/orders/$orderId');
                                        if (mounted) _load();
                                      },
                                      child: Container(
                                        width: double.infinity,
                                        padding: const EdgeInsets.symmetric(
                                          horizontal: 10,
                                          vertical: 8,
                                        ),
                                        decoration: BoxDecoration(
                                          color: const Color(0xFFE8F5E9),
                                          borderRadius: BorderRadius.circular(8),
                                        ),
                                        child: Text(
                                          'Instructions ready — tap to read',
                                          style: kTextStyle.copyWith(
                                            color: const Color(0xFF2E7D32),
                                            fontSize: 13,
                                            fontWeight: FontWeight.w600,
                                          ),
                                        ),
                                      ),
                                    ),
                                  ],
                                ],
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
