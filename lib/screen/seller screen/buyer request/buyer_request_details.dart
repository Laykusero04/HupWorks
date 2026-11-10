import 'package:flutter/material.dart';
import 'package:freelancer/core/guide/guide_anchor.dart';
import 'package:freelancer/core/guide/guide_host.dart';
import 'package:freelancer/core/guide/guide_info_button.dart';
import 'package:freelancer/core/guide/guide_step.dart';
import 'package:freelancer/core/widgets/empty_state_widget.dart';
import 'package:freelancer/core/widgets/loading_widget.dart';
import 'package:freelancer/core/widgets/rubik_refresh_indicator.dart';
import 'package:freelancer/core/utils/app_date_format.dart';
import 'package:freelancer/core/utils/localized_category.dart';
import 'package:freelancer/core/utils/shift_schedule.dart';
import 'package:freelancer/screen/widgets/button_global.dart';
import 'package:freelancer/services/favourite_service.dart';
import 'package:freelancer/services/job_posts_service.dart';
import 'package:freelancer/services/seller_orders_service.dart';
import 'package:freelancer/l10n/l10n.dart';
import 'package:freelancer/screen/seller%20screen/report/seller_report.dart';
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

class _BuyerRequestDetailsState extends State<BuyerRequestDetails>
    with GuideHost<BuyerRequestDetails> {
  Map<String, dynamic>? _jobPost;
  bool _isLoading = true;
  bool _isFavourited = false;
  bool _favBusy = false;

  final GlobalKey _guideClientKey = GlobalKey();
  final GlobalKey _guideSaveKey = GlobalKey();
  final GlobalKey _guideReadKey = GlobalKey();
  final GlobalKey _guideApplyKey = GlobalKey();
  final GlobalKey _guideWhereKey = GlobalKey();
  final GlobalKey _guideBudgetKey = GlobalKey();
  final GlobalKey _guideShiftKey = GlobalKey();
  final GlobalKey _guideAppsKey = GlobalKey();

  @override
  String get guideScreenId => 'seller_job_details';
  @override
  String get guideRole => 'seller';
  @override
  int get guideVersion => 1;

  /// Only once the job is loaded (the loading and error scaffolds have no
  /// targets). A retry sets `_isLoading` again, which cancels a running guide.
  @override
  bool get guideDataReady => !_isLoading && _jobPost != null && _routeSettled;
  @override
  String get guideSkipLabel => context.l10n.guideSkip;
  @override
  String get guideNextLabel => context.l10n.guideNext;
  @override
  String get guideDoneLabel => context.l10n.guideDone;

  /// Why applying is blocked, or null when the seller can apply.
  String? _applyBlockedReason(AppLocalizations l10n) {
    final jobStatus = (_jobPost?['status'] as String?) ?? 'open';
    final myUid = Supabase.instance.client.auth.currentUser?.id;
    final clientId = _jobPost?['client_id'] as String?;
    final myOffer = _jobPost?['my_offer'] as Map<String, dynamic>?;
    if (jobStatus.toLowerCase() != 'open') {
      return l10n.jobClosedNoApplications;
    }
    if (myUid != null && clientId != null && myUid == clientId) {
      return l10n.cannotApplyToOwnJob;
    }
    if (myOffer != null) {
      final st = (myOffer['status'] as String?)?.toLowerCase();
      if (st == 'pending' || st == 'accepted') {
        return l10n.alreadySubmittedApplication;
      }
    }
    return null;
  }

  // Order follows on-screen position: bookmark (app bar), client, job text,
  // apply button. Apply is skipped when applying is blocked (the grey button
  // stays, but it is not worth a tip).
  @override
  List<GuideStep> buildGuideSteps(BuildContext context) {
    final l10n = context.l10n;
    return [
      GuideStep(
          key: _guideSaveKey,
          title: l10n.guideSellerJobSaveTitle,
          description: l10n.guideSellerJobSaveDesc),
      GuideStep(
          key: _guideClientKey,
          title: l10n.guideSellerJobClientTitle,
          description: l10n.guideSellerJobClientDesc),
      GuideStep(
          key: _guideReadKey,
          title: l10n.guideSellerJobReadTitle,
          description: l10n.guideSellerJobReadDesc),
      if (_applyBlockedReason(l10n) == null)
        GuideStep(
            key: _guideApplyKey,
            title: l10n.guideSellerJobApplyTitle,
            description: l10n.guideSellerJobApplyDesc,
            targetNearBottom: true),
    ];
  }

  @override
  List<GuideSection> buildGuideExtraSections(BuildContext context) {
    final l10n = context.l10n;
    return [
      GuideSection(
        id: 'fit',
        title: l10n.guideSellerJobSectionFit,
        steps: [
          GuideStep(
              key: _guideWhereKey,
              title: l10n.guideSellerJobWhereTitle,
              description: l10n.guideSellerJobWhereDesc,
              enableAutoScroll: true),
          GuideStep(
              key: _guideBudgetKey,
              title: l10n.guideSellerJobBudgetTitle,
              description: l10n.guideSellerJobBudgetDesc,
              enableAutoScroll: true),
          GuideStep(
              key: _guideShiftKey,
              title: l10n.guideSellerJobShiftTitle,
              description: l10n.guideSellerJobShiftDesc,
              enableAutoScroll: true),
          GuideStep(
              key: _guideAppsKey,
              title: l10n.guideSellerJobAppsTitle,
              description: l10n.guideSellerJobAppsDesc,
              enableAutoScroll: true),
        ],
      ),
    ];
  }

  /// True once the push animation finished: targets are at their final place.
  bool _routeSettled = false;

  void _awaitRouteSettled() {
    if (!mounted) return;
    final anim = ModalRoute.of(context)?.animation;
    if (anim == null || anim.isCompleted) {
      _settleRoute();
      return;
    }
    void listener(AnimationStatus st) {
      if (st == AnimationStatus.completed) {
        anim.removeStatusListener(listener);
        _settleRoute();
      }
    }

    anim.addStatusListener(listener);
  }

  void _settleRoute() {
    if (!mounted) return;
    setState(() => _routeSettled = true);
    scheduleGuide();
  }

  GuideAnchor _anchor(GlobalKey key, String title, String desc) => GuideAnchor(
        key: key,
        scope: guideScope,
        title: title,
        description: desc,
      );

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _awaitRouteSettled());
    _loadDetails();
  }

  Future<void> _loadDetails() async {
    try {
      final results = await Future.wait([
        SellerOrdersService.getBuyerRequestDetails(widget.jobPostId),
        FavouriteService.isFavourited(widget.jobPostId),
      ]);
      if (mounted) {
        setState(() {
          _jobPost = results[0] as Map<String, dynamic>;
          _isFavourited = results[1] as bool;
          _isLoading = false;
        });
        scheduleGuide();
      }
    } catch (e) {
      if (mounted) {
        final keepJob = _jobPost != null;
        setState(() => _isLoading = false);
        scheduleGuide();
        if (keepJob) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(context.l10n.errorWithDetail('$e'))),
          );
        }
      }
    }
  }

  Future<void> _toggleFavourite() async {
    if (_favBusy) return;
    setState(() => _favBusy = true);
    try {
      final next = await FavouriteService.toggleFavourite(widget.jobPostId);
      if (!mounted) return;
      setState(() {
        _isFavourited = next;
        _favBusy = false;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(next ? context.l10n.addedToFavourites : context.l10n.removedFromFavourites),
        ),
      );
    } catch (e) {
      if (!mounted) return;
      setState(() => _favBusy = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(context.l10n.errorWithDetail('$e'))),
      );
    }
  }

  String _formatDate(String? s) {
    return AppDateFormat.tryDMmmY(s, AppDateFormat.localeOf(context)) ?? '';
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) return const Scaffold(backgroundColor: kDarkWhite, body: const LoadingWidget());

    final l10n = context.l10n;
    if (_jobPost == null) {
      return Scaffold(
        backgroundColor: kDarkWhite,
        appBar: AppBar(
          backgroundColor: kDarkWhite,
          elevation: 0,
          iconTheme: const IconThemeData(color: kNeutralColor),
          title: Text(
            l10n.buyerRequestDetailsTitle,
            style: kTextStyle.copyWith(
              color: kNeutralColor,
              fontWeight: FontWeight.bold,
            ),
          ),
          centerTitle: true,
        ),
        body: EmptyStateWidget(
          message: l10n.somethingWentWrong,
          actionLabel: l10n.retry,
          onAction: () {
            setState(() => _isLoading = true);
            _loadDetails();
          },
        ),
      );
    }

    final category = LocalizedCategory.name(
      _jobPost?['categories'] as Map<String, dynamic>?,
      LocalizedCategory.languageCodeOf(context),
      fallback: l10n.categoryGeneral,
    );
    final title = _jobPost?['title'] ?? l10n.jobPostFallback;
    final description = _jobPost?['description'] ?? '';
    final budgetMin = _jobPost?['budget_min'];
    final budgetMax = _jobPost?['budget_max'];
    final offerCount = _jobPost?['offer_count'] ?? 0;
    final myUid = Supabase.instance.client.auth.currentUser?.id;
    final clientId = _jobPost?['client_id'] as String?;

    final applyBlock = _applyBlockedReason(l10n);
    final canApply = applyBlock == null;

    final bottomLift = MediaQuery.paddingOf(context).bottom + BuyerRequestDetails._shellFloatingNavLift;

    return guideBackScope(Scaffold(
      backgroundColor: kDarkWhite,
      appBar: AppBar(
        backgroundColor: kDarkWhite, elevation: 0, iconTheme: const IconThemeData(color: kNeutralColor),
        title: Text(l10n.buyerRequestDetailsTitle, style: kTextStyle.copyWith(color: kNeutralColor, fontWeight: FontWeight.bold)), centerTitle: true,
        actions: [
          GuideInfoButton(host: this),
          GuideAnchor.wrap(
            _anchor(_guideSaveKey, l10n.guideSellerJobSaveTitle,
                l10n.guideSellerJobSaveDesc),
            IconButton(
              tooltip: _isFavourited ? l10n.removeFavourite : l10n.favorite,
              onPressed: _favBusy ? null : _toggleFavourite,
              icon: Icon(
                _isFavourited ? Icons.bookmark : Icons.bookmark_border,
                color: _isFavourited ? kPrimaryColor : kNeutralColor,
              ),
            ),
          ),
          if (clientId != null && myUid != clientId)
            IconButton(
              tooltip: l10n.report,
              onPressed: () {
                final client = _jobPost?['profiles'] as Map<String, dynamic>?;
                SellerReport(
                  reportedUserId: clientId,
                  reportedUserName: client?['name'] as String?,
                  jobPostId: widget.jobPostId,
                  jobTitle: title as String?,
                ).launch(context);
              },
              icon: const Icon(Icons.flag_outlined, color: kNeutralColor),
            ),
        ],
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
                guideAnchor: canApply
                    ? _anchor(_guideApplyKey, l10n.guideSellerJobApplyTitle,
                        l10n.guideSellerJobApplyDesc)
                    : null,
                buttontext: canApply
                    ? l10n.submitOfferAction
                    : l10n.cannotSubmitApplication,
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
          child: RubikRefreshIndicator(
            onRefresh: _loadDetails,
            child: SingleChildScrollView(
            physics: const AlwaysScrollableScrollPhysics(
              parent: BouncingScrollPhysics(),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SizedBox(height: 15.0),
                JobClientInfoCard.fromJobPost(
                  _jobPost,
                  guideAnchor: _anchor(_guideClientKey,
                      l10n.guideSellerJobClientTitle,
                      l10n.guideSellerJobClientDesc),
                ),
                const SizedBox(height: 15.0),

                // Title + description
                GuideAnchor.wrap(
                  _anchor(_guideReadKey, l10n.guideSellerJobReadTitle,
                      l10n.guideSellerJobReadDesc),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(title, style: kTextStyle.copyWith(color: kNeutralColor, fontWeight: FontWeight.bold, fontSize: 16)),
                      const SizedBox(height: 10.0),
                      ReadMoreText(
                        description,
                        style: kTextStyle.copyWith(color: kSubTitleColor),
                        trimLines: 3, colorClickableText: kPrimaryColor, trimMode: TrimMode.Line,
                        trimCollapsedText: l10n.readMoreSuffix, trimExpandedText: l10n.readLessSuffix,
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 15.0),

                // Details
                _row(l10n.categoryLabel, category),
                const SizedBox(height: 8.0),
                if (JobPostsService.skillNamesFromJob(_jobPost).isNotEmpty) ...[
                  _row(
                    l10n.skills,
                    JobPostsService.skillNamesFromJob(_jobPost).join(', '),
                  ),
                  const SizedBox(height: 8.0),
                ],
                if (budgetMin != null || budgetMax != null) ...[
                  _row(l10n.budgetLabel, JobPostsService.formatBudgetRange(budgetMin, budgetMax, _jobPost?['budget_basis']),
                      anchor: _anchor(_guideBudgetKey, l10n.guideSellerJobBudgetTitle, l10n.guideSellerJobBudgetDesc)),
                  const SizedBox(height: 8.0),
                ],
                _buildLocationSection(_jobPost),
                _row(l10n.workersNeeded, JobPostsService.workersNeededDetailLabel(_jobPost?['workers_needed'])),
                const SizedBox(height: 8.0),
                if (ShiftSchedule.fromMap(_jobPost).displayLabel != null) ...[
                  _row(l10n.shiftLabel, ShiftSchedule.fromMap(_jobPost).displayLabel!,
                      anchor: _anchor(_guideShiftKey, l10n.guideSellerJobShiftTitle, l10n.guideSellerJobShiftDesc)),
                  const SizedBox(height: 8.0),
                ],
                _row(l10n.applicationsReceived, '$offerCount',
                    anchor: _anchor(_guideAppsKey, l10n.guideSellerJobAppsTitle, l10n.guideSellerJobAppsDesc)),
                const SizedBox(height: 8.0),
                _row(l10n.dateLabel, _formatDate(_jobPost?['created_at'])),
                SizedBox(height: bottomLift + 24),
              ],
            ),
            ),
          ),
        ),
      ),
    ));
  }

  Widget _row(String l, String v, {GuideAnchor? anchor}) => GuideAnchor.wrap(anchor, _rowContent(l, v));

  Widget _rowContent(String l, String v) => Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
    Expanded(flex: 2, child: Text(l, style: kTextStyle.copyWith(color: kSubTitleColor))),
    Expanded(flex: 4, child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Text(context.l10n.labelColon, style: kTextStyle.copyWith(color: kSubTitleColor)), const SizedBox(width: 10.0),
      Flexible(child: Text(v, style: kTextStyle.copyWith(color: kSubTitleColor), overflow: TextOverflow.ellipsis, maxLines: 2)),
    ])),
  ]);

  Widget _buildLocationSection(Map<String, dynamic>? job) {
    final l10n = context.l10n;
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
          GuideAnchor.wrap(
            _anchor(_guideWhereKey, l10n.guideSellerJobWhereTitle,
                l10n.guideSellerJobWhereDesc),
            Row(children: [
              Text(l10n.locationLabel, style: kTextStyle.copyWith(color: kSubTitleColor)),
              const SizedBox(width: 8),
              Text(l10n.labelColon, style: kTextStyle.copyWith(color: kSubTitleColor)),
              const SizedBox(width: 10),
              _locationTypeBadge(locationType),
            ]),
          ),
          const SizedBox(height: 8),
        ],
        if (coords != null) ...[
          JobLocationSection(job: job),
          const SizedBox(height: 8),
        ] else if (location != null && location.isNotEmpty) ...[
          _row(l10n.areaLabel, location),
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
        Text(
          switch (type) {
            'On-site' => context.l10n.locationOnSite,
            'Remote' => context.l10n.locationRemote,
            _ => type,
          },
          style: kTextStyle.copyWith(color: fg, fontSize: 12, fontWeight: FontWeight.bold),
        ),
      ]),
    );
  }
}
