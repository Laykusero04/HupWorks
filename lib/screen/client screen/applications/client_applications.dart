import 'package:flutter/material.dart';
import 'package:freelancer/core/utils/app_date_format.dart';
import 'package:freelancer/core/utils/job_offer_chat_actions.dart';
import 'package:freelancer/core/utils/profile_image.dart';
import 'package:freelancer/core/widgets/empty_state_widget.dart';
import 'package:freelancer/l10n/app_localizations.dart';
import 'package:freelancer/l10n/l10n.dart';
import 'package:freelancer/l10n/l10n_labels.dart';
import 'package:freelancer/screen/seller%20screen/seller%20message/chat_inbox.dart';
import 'package:freelancer/screen/widgets/button_global.dart';
import 'package:freelancer/services/chat_service.dart';
import 'package:freelancer/services/job_posts_service.dart';
import 'package:nb_utils/nb_utils.dart';

import '../../widgets/constant.dart';
import '../client job post/create_new_job_post.dart';
import '../client job post/job_details.dart';
import '../client talent/freelancer_public_profile.dart';

/// Employer inbox of applications across all jobs.
class ClientApplications extends StatefulWidget {
  const ClientApplications({super.key});

  @override
  State<ClientApplications> createState() => _ClientApplicationsState();
}

class _ClientApplicationsState extends State<ClientApplications> {
  List<Map<String, dynamic>> _applications = [];
  bool _isLoading = true;

  /// `null` = all; otherwise `pending` / `accepted` / `rejected`.
  String? _statusFilter = 'pending';

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load({bool showLoader = true}) async {
    if (showLoader && mounted) setState(() => _isLoading = true);
    try {
      final apps = await JobPostsService.getClientApplications();
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

  List<Map<String, dynamic>> get _visible {
    final filter = _statusFilter;
    if (filter == null) return _applications;
    return _applications
        .where((a) => (a['status'] as String?)?.toLowerCase() == filter)
        .toList();
  }

  String _formatDate(String? s) {
    return AppDateFormat.tryDMmmY(s, AppDateFormat.localeOf(context)) ?? '';
  }

  String _jobTypeLabel(String? t) => L10nLabels.jobType(context.l10n, t);

  ({Color bg, Color fg, String label}) _statusStyle(String? status) {
    final l10n = context.l10n;
    final (fg, bg) = StatusColors.application(status);
    switch (status) {
      case 'accepted':
        return (bg: bg, fg: fg, label: l10n.statusAccepted);
      case 'rejected':
        return (bg: bg, fg: fg, label: l10n.statusRejected);
      case 'pending':
      default:
        return (bg: bg, fg: fg, label: l10n.statusPending);
    }
  }

  List<Map<String, dynamic>> _siblingsFor(Map<String, dynamic> offer) {
    final jobId = offer['job_post_id'] as String? ??
        (offer['job_posts'] as Map?)?['id'] as String?;
    if (jobId == null) return [offer];
    return _applications
        .where(
          (a) =>
              (a['job_post_id'] as String?) == jobId ||
              (a['job_posts'] as Map?)?['id'] == jobId,
        )
        .toList();
  }

  Future<void> _openJob(Map<String, dynamic> app) async {
    final jobPost = app['job_posts'] as Map<String, dynamic>?;
    final id = jobPost?['id'] as String? ?? app['job_post_id'] as String?;
    if (id == null) return;
    await JobDetails(jobPostId: id).launch(context);
    if (mounted) _load(showLoader: false);
  }

  Future<void> _messageSeller(Map<String, dynamic> app) async {
    final l10n = context.l10n;
    final seller = app['profiles'] as Map<String, dynamic>?;
    final sellerId =
        app['seller_id'] as String? ?? seller?['id'] as String?;
    if (sellerId == null) return;
    try {
      final conversation = await ChatService.getOrCreateConversation(sellerId);
      if (!mounted) return;
      await ChatInbox(
        conversationId: conversation['id'] as String,
        otherUserName: seller?['name'] as String? ?? l10n.talent,
        otherUserImage: seller?['profile_image_url'] as String? ?? '',
        otherUserId: sellerId,
      ).launch(context);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(l10n.couldNotOpenChatWithDetail('$e'))),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final visible = _visible;

    return Scaffold(
      backgroundColor: kDarkWhite,
      appBar: AppBar(
        backgroundColor: kDarkWhite,
        elevation: 0,
        iconTheme: const IconThemeData(color: kNeutralColor),
        title: Text(
          l10n.applications,
          style: kTextStyle.copyWith(
            color: kNeutralColor,
            fontWeight: FontWeight.bold,
          ),
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
          child: Column(
            children: [
              const SizedBox(height: 12),
              _FilterChips(
                selected: _statusFilter,
                onChanged: (v) => setState(() => _statusFilter = v),
              ),
              const SizedBox(height: 8),
              Expanded(
                child: _isLoading
                    ? const Center(
                        child: CircularProgressIndicator(color: kPrimaryColor),
                      )
                    : visible.isEmpty
                        ? EmptyStateWidget(
                            message: l10n.noApplicationsYet,
                            hint: l10n.noClientApplicationsYetHint,
                            icon: Icons.inbox_outlined,
                            actionLabel: l10n.postAJob,
                            onAction: () async {
                              await const CreateNewJobPost().launch(context);
                              if (mounted) _load(showLoader: false);
                            },
                          )
                        : RefreshIndicator(
                            color: kPrimaryColor,
                            onRefresh: () => _load(showLoader: false),
                            child: ListView.builder(
                              physics: const AlwaysScrollableScrollPhysics(
                                parent: BouncingScrollPhysics(),
                              ),
                              padding: const EdgeInsets.only(
                                top: 8.0,
                                bottom: 15.0,
                              ),
                              itemCount: visible.length,
                              itemBuilder: (_, i) =>
                                  _buildCard(visible[i], l10n),
                            ),
                          ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildCard(Map<String, dynamic> app, AppLocalizations l10n) {
    final jobPost = app['job_posts'] as Map<String, dynamic>?;
    final seller = app['profiles'] as Map<String, dynamic>?;
    final statusRaw = (app['status'] as String?) ?? 'pending';
    final status = _statusStyle(statusRaw);
    final jobOpen = (jobPost?['status'] as String?) == 'open';
    final sellerName = (seller?['name'] as String?)?.trim().isNotEmpty == true
        ? seller!['name'] as String
        : l10n.talent;
    final sellerId =
        app['seller_id'] as String? ?? seller?['id'] as String?;
    final imageUrl = seller?['profile_image_url'] as String?;

    return Padding(
      padding: const EdgeInsets.only(bottom: 10.0),
      child: Material(
        color: kWhite,
        borderRadius: BorderRadius.circular(10.0),
        child: InkWell(
          borderRadius: BorderRadius.circular(10.0),
          onTap: () => _openJob(app),
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
                    GestureDetector(
                      onTap: sellerId == null
                          ? null
                          : () => FreelancerPublicProfile(
                                sellerId: sellerId,
                                initialName: sellerName,
                              ).launch(context),
                      child: CircleAvatar(
                        radius: 22,
                        backgroundColor: kDarkWhite,
                        backgroundImage: ProfileImage.provider(imageUrl),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            sellerName,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: kTextStyle.copyWith(
                              color: kNeutralColor,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            jobPost?['title'] ?? l10n.untitledJob,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: kTextStyle.copyWith(
                              color: kSubTitleColor,
                              fontSize: 13,
                            ),
                          ),
                        ],
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        vertical: 3.0,
                        horizontal: 8.0,
                      ),
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(20.0),
                        color: status.bg,
                      ),
                      child: Text(
                        status.label,
                        style: kTextStyle.copyWith(
                          color: status.fg,
                          fontSize: 12.0,
                        ),
                      ),
                    ),
                    IconButton(
                      visualDensity: VisualDensity.compact,
                      padding: EdgeInsets.zero,
                      constraints: const BoxConstraints(
                        minWidth: 36,
                        minHeight: 36,
                      ),
                      tooltip: l10n.message,
                      icon: const Icon(
                        Icons.chat_bubble_outline,
                        size: 20,
                        color: kPrimaryColor,
                      ),
                      onPressed: () => _messageSeller(app),
                    ),
                  ],
                ),
                const SizedBox(height: 8.0),
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(
                        vertical: 2.0,
                        horizontal: 8.0,
                      ),
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(20.0),
                        color: kDarkWhite,
                      ),
                      child: Text(
                        _jobTypeLabel(jobPost?['job_type'] as String?),
                        style: kTextStyle.copyWith(
                          color: kNeutralColor,
                          fontSize: 12.0,
                        ),
                      ),
                    ),
                    const SizedBox(width: 10.0),
                    Text(
                      L10nLabels.offerAmountShort(
                        l10n,
                        app['price'],
                        app['price_basis'],
                      ),
                      style: kTextStyle.copyWith(
                        color: kPrimaryColor,
                        fontWeight: FontWeight.bold,
                      ),
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
                if (statusRaw == 'pending' && jobOpen) ...[
                  const SizedBox(height: 10),
                  Row(
                    children: [
                      Expanded(
                        child: ButtonGlobalWithoutIcon(
                          buttontext: l10n.rejectApplication,
                          buttonDecoration: kButtonDecoration.copyWith(
                            color: kWhite,
                            border: Border.all(color: Colors.red),
                          ),
                          onPressed: () => JobOfferChatActions.rejectOffer(
                            context,
                            offerId: app['id'] as String,
                            sellerName: sellerName,
                            onComplete: () => _load(showLoader: false),
                          ),
                          buttonTextColor: Colors.red,
                        ),
                      ),
                      Expanded(
                        child: ButtonGlobalWithoutIcon(
                          buttontext: l10n.hireAction,
                          buttonDecoration: kButtonDecoration.copyWith(
                            color: kPrimaryColor,
                          ),
                          onPressed: () => JobOfferChatActions.acceptOffer(
                            context,
                            offer: app,
                            siblingOffers: _siblingsFor(app),
                            onComplete: () => _load(showLoader: false),
                          ),
                          buttonTextColor: kWhite,
                        ),
                      ),
                    ],
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _FilterChips extends StatelessWidget {
  const _FilterChips({
    required this.selected,
    required this.onChanged,
  });

  final String? selected;
  final ValueChanged<String?> onChanged;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final chips = <(String?, String)>[
      (null, l10n.filterAll),
      ('pending', l10n.statusPending),
      ('accepted', l10n.statusAccepted),
      ('rejected', l10n.statusRejected),
    ];

    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: [
          for (final (value, label) in chips)
            Padding(
              padding: const EdgeInsets.only(right: 8),
              child: ChoiceChip(
                label: Text(label),
                selected: selected == value,
                onSelected: (_) => onChanged(value),
                selectedColor: kPrimaryColor.withValues(alpha: 0.15),
                labelStyle: kTextStyle.copyWith(
                  color: selected == value ? kPrimaryColor : kNeutralColor,
                  fontWeight:
                      selected == value ? FontWeight.w600 : FontWeight.w500,
                  fontSize: 13,
                ),
                backgroundColor: kDarkWhite,
                side: BorderSide(
                  color: selected == value
                      ? kPrimaryColor
                      : kBorderColorTextField,
                ),
              ),
            ),
        ],
      ),
    );
  }
}
