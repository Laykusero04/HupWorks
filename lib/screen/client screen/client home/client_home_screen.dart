import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart' show ScrollCacheExtent;
import 'package:freelancer/core/widgets/rubik_refresh_indicator.dart';
import 'package:flutter_iconly/flutter_iconly.dart';
import 'package:freelancer/core/guide/guide_host.dart';
import 'package:freelancer/core/guide/guide_info_button.dart';
import 'package:freelancer/core/guide/guide_step.dart';
import 'package:freelancer/core/utils/client_profile_completeness.dart';
import 'package:freelancer/core/utils/profile_image.dart';
import 'package:freelancer/l10n/l10n.dart';
import 'package:freelancer/screen/client%20screen/client%20job%20post/client_job_post.dart';
import 'package:freelancer/screen/client%20screen/client%20job%20post/create_new_job_post.dart';
import 'package:freelancer/screen/client%20screen/client%20job%20post/job_details.dart';
import 'package:freelancer/screen/client%20screen/client%20profile/client_edit_profile_details.dart';
import 'package:freelancer/services/client_home_service.dart';
import 'package:freelancer/services/job_posts_service.dart';
import 'package:freelancer/services/profile_service.dart';
import 'package:freelancer/services/verification_service.dart';
import 'package:go_router/go_router.dart';
import 'package:nb_utils/nb_utils.dart';
import 'package:showcaseview/showcaseview.dart';

import '../../../router/route_names.dart';
import '../../widgets/client_shell_app_bar.dart';
import '../../widgets/constant.dart';
import '../../widgets/seller_standing_badge.dart';
import '../../widgets/talent_card_verification_mark.dart';
import '../search/search.dart';
import 'package:freelancer/core/utils/category_icons.dart';
import 'package:freelancer/core/utils/localized_category.dart';

import '../client talent/freelancer_public_profile.dart';
import 'client_all_categories.dart';

class ClientHomeScreen extends StatefulWidget {
  const ClientHomeScreen({Key? key}) : super(key: key);

  @override
  State<ClientHomeScreen> createState() => _ClientHomeScreenState();
}

class _ClientHomeScreenState extends State<ClientHomeScreen>
    with GuideHost<ClientHomeScreen> {
  List<Map<String, dynamic>> _categories = [];
  List<Map<String, dynamic>> _myRecentJobs = [];
  List<Map<String, dynamic>> _topSellers = [];
  bool _isLoading = true;
  // True while a pull-to-refresh / reload runs with the content still on
  // screen: the guide is torn down (and re-armed) instead of pointing at
  // widgets that are about to be rebuilt.
  bool _refreshing = false;
  bool _showProfileNudge = false;

  final PageController _bannerController =
      PageController(viewportFraction: 0.9);
  int _bannerIndex = 0;

  // Guide targets (owned by this State, stable across rebuilds).
  final GlobalKey _guideMenuKey = GlobalKey();
  final GlobalKey _guideBellKey = GlobalKey();
  final GlobalKey _guideSearchKey = GlobalKey();
  final GlobalKey _guideNudgeKey = GlobalKey();
  final GlobalKey _guidePostJobKey = GlobalKey();
  // "Explore" section targets.
  final GlobalKey _guideShortcutsKey = GlobalKey();
  final GlobalKey _guideHighlightsKey = GlobalKey();
  final GlobalKey _guideCategoriesKey = GlobalKey();
  final GlobalKey _guideRecentJobsKey = GlobalKey();
  final GlobalKey _guideTopFreelancersKey = GlobalKey();

  @override
  String get guideScreenId => 'client_home';
  @override
  String get guideRole => 'client';
  @override
  int get guideVersion => 1;
  @override
  bool get guideLeadsChain => true;
  @override
  bool get guideDataReady => !_isLoading && !_refreshing;
  @override
  String get guideSkipLabel => context.l10n.guideSkip;
  @override
  String get guideNextLabel => context.l10n.guideNext;
  @override
  String get guideDoneLabel => context.l10n.guideDone;

  // Order follows on-screen position: menu, bell, search, nudge, Post job.
  @override
  List<GuideStep> buildGuideSteps(BuildContext context) {
    final l10n = context.l10n;
    return [
      GuideStep(
          key: _guideMenuKey,
          title: l10n.guideShellMenuTitle,
          description: l10n.guideShellMenuDesc),
      GuideStep(
          key: _guideBellKey,
          title: l10n.guideClientHomeBellTitle,
          description: l10n.guideClientHomeBellDesc),
      GuideStep(
          key: _guideSearchKey,
          title: l10n.guideClientHomeSearchTitle,
          description: l10n.guideClientHomeSearchDesc),
      // Only rendered while the profile nudge is shown (dropped otherwise).
      GuideStep(
          key: _guideNudgeKey,
          title: l10n.guideClientHomeNudgeTitle,
          description: l10n.guideClientHomeNudgeDesc),
      GuideStep(
          key: _guidePostJobKey,
          title: l10n.guideClientHomePostJobTitle,
          description: l10n.guideClientHomePostJobDesc),
    ];
  }

  // On demand from the (i): everything below the fold, so every step scrolls.
  @override
  List<GuideSection> buildGuideExtraSections(BuildContext context) {
    final l10n = context.l10n;
    return [
      GuideSection(
        id: 'explore',
        title: l10n.guideClientHomeSectionExplore,
        steps: [
          GuideStep(
              key: _guideShortcutsKey,
              enableAutoScroll: true,
              title: l10n.guideClientHomeShortcutsTitle,
              description: l10n.guideClientHomeShortcutsDesc),
          GuideStep(
              key: _guideHighlightsKey,
              enableAutoScroll: true,
              title: l10n.guideClientHomeHighlightsTitle,
              description: l10n.guideClientHomeHighlightsDesc),
          GuideStep(
              key: _guideCategoriesKey,
              enableAutoScroll: true,
              title: l10n.guideClientHomeCategoriesTitle,
              description: l10n.guideClientHomeCategoriesDesc),
          GuideStep(
              key: _guideRecentJobsKey,
              enableAutoScroll: true,
              title: l10n.guideClientHomeRecentJobsTitle,
              description: l10n.guideClientHomeRecentJobsDesc),
          GuideStep(
              key: _guideTopFreelancersKey,
              enableAutoScroll: true,
              title: l10n.guideClientHomeTopFreelancersTitle,
              description: l10n.guideClientHomeTopFreelancersDesc),
        ],
      ),
    ];
  }

  /// Wraps [child] as a target of the "Explore" section.
  Widget _exploreTarget(
      GlobalKey key, String title, String description, Widget child,
      {double radius = 16}) {
    return Showcase(
      key: key,
      scope: guideScope,
      title: title,
      description: description,
      targetBorderRadius: BorderRadius.circular(radius),
      child: child,
    );
  }

  // The large cache extent builds the whole page so every "Explore" target
  // exists. Only enabled while that section is being started / run.
  bool _exploreCache = false;
  bool _exploreStarted = false;

  void _onExploreRunningChanged() {
    if (guideRunning.value) {
      if (_exploreCache) _exploreStarted = true;
    } else if (_exploreStarted) {
      _endExploreCache();
    }
  }

  void _endExploreCache() {
    _exploreStarted = false;
    if (_exploreCache && mounted) setState(() => _exploreCache = false);
  }

  @override
  bool replayGuide({String? sectionId}) {
    if (sectionId != 'explore' || !mounted || _exploreCache) {
      return super.replayGuide(sectionId: sectionId);
    }
    setState(() => _exploreCache = true);
    // Start after the larger cache extent has built the targets.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      if (!super.replayGuide(sectionId: sectionId)) _endExploreCache();
    });
    // Safety net: never keep the large extent if the guide did not start.
    Future.delayed(const Duration(seconds: 5), () {
      if (mounted && !_exploreStarted && !guideRunning.value) {
        _endExploreCache();
      }
    });
    return true;
  }

  @override
  void initState() {
    super.initState();
    guideRunning.addListener(_onExploreRunningChanged);
    // Defer Supabase work until after the first frame so the loading
    // skeleton paints immediately instead of blocking the initial render.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      _loadData();
    });
  }

  @override
  void dispose() {
    guideRunning.removeListener(_onExploreRunningChanged);
    _bannerController.dispose();
    super.dispose();
  }

  Future<void> _loadData() async {
    if (mounted && !_isLoading && !_refreshing) {
      setState(() => _refreshing = true); // guideDataReady false: tear down
    }
    try {
      final results = await Future.wait([
        ClientHomeService.getCategories(),
        JobPostsService.getClientJobPosts(),
        ClientHomeService.getTopSellers(),
        ProfileService.getProfile(),
        ClientProfileCompleteness.isNudgeDismissed(),
      ]);

      if (mounted) {
        final myJobs = results[1] as List<Map<String, dynamic>>;
        final profile = results[3] as Map<String, dynamic>?;
        final dismissed = results[4] as bool;
        final incomplete = ClientProfileCompleteness.isIncomplete(profile);
        if (!incomplete) {
          await ClientProfileCompleteness.clearNudgeDismissed();
        }
        setState(() {
          _categories = results[0] as List<Map<String, dynamic>>;
          _myRecentJobs = myJobs.take(3).toList();
          _topSellers = results[2] as List<Map<String, dynamic>>;
          _showProfileNudge = incomplete && !dismissed;
          _isLoading = false;
          _refreshing = false;
        });
        scheduleGuide();
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLoading = false;
          _refreshing = false;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(context.l10n.errorWithDetail('$e'))),
        );
        scheduleGuide();
      }
    }
  }

  Future<void> _dismissProfileNudge() async {
    cancelGuide(); // the nudge target is about to disappear
    await ClientProfileCompleteness.dismissNudge();
    if (mounted) setState(() => _showProfileNudge = false);
  }

  Future<void> _openCompleteProfile() async {
    await const ClientEditProfile().launch(context);
    if (mounted) await _loadData();
  }

  String _jobTypeLabel(String? t) {
    final l10n = context.l10n;
    switch (t) {
      case 'full_time':
        return l10n.fullTime;
      case 'part_time':
        return l10n.partTime;
      case 'gig':
      default:
        return l10n.jobTypeGig;
    }
  }

  // Soft tints rotated through category cells for visual variety.
  Color _categoryTint(int i) {
    const tints = [
      Color(0x1AF97316),
      Color(0x1A06B6D4),
      Color(0x1A2D3436),
      Color(0x1AFB923C),
      Color(0x1A22D3EE),
      Color(0x1A636E72),
      Color(0x1A0891B2),
      Color(0x1A95A5A6),
    ];
    return tints[i % tints.length];
  }

  Color _categoryIconColor(int i) {
    const colors = [
      kPrimaryColor,
      kSecondaryColor,
      kNeutralColor,
      kAccentColor,
      kSellerAccent,
      kSubTitleColor,
      kSellerPrimary,
      kLightNeutralColor,
    ];
    return colors[i % colors.length];
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    return guideBackScope(Scaffold(
      backgroundColor: kDarkWhite,
      appBar: ClientShellAppBar(
        title: l10n.home,
        actions: [GuideInfoButton(host: this)],
        menuShowcaseKey: _guideMenuKey,
        menuShowcaseScope: guideScope,
        menuShowcaseTitle: l10n.guideShellMenuTitle,
        menuShowcaseDescription: l10n.guideShellMenuDesc,
        bellShowcaseKey: _guideBellKey,
        bellShowcaseTitle: l10n.guideClientHomeBellTitle,
        bellShowcaseDescription: l10n.guideClientHomeBellDesc,
      ),
      body: _isLoading
          ? const _ClientHomeLoading()
          : RubikRefreshIndicator(
              onRefresh: _loadData,
              child: CustomScrollView(
                physics: const AlwaysScrollableScrollPhysics(
                    parent: BouncingScrollPhysics()),
                // Build the whole (short) page so below-the-fold guide
                // targets exist and can be scrolled to.
                scrollCacheExtent: _exploreCache
                    ? const ScrollCacheExtent.pixels(4000)
                    : null,
                slivers: [
                  SliverToBoxAdapter(child: _buildSearchBar()),
                  if (_showProfileNudge) ...[
                    const SliverToBoxAdapter(child: SizedBox(height: 14)),
                    SliverToBoxAdapter(child: _buildProfileNudge()),
                  ],
                  const SliverToBoxAdapter(child: SizedBox(height: 16)),
                  SliverToBoxAdapter(child: _buildQuickActions()),
                  const SliverToBoxAdapter(child: SizedBox(height: 22)),
                  SliverToBoxAdapter(
                      child: _exploreTarget(
                          _guideHighlightsKey,
                          l10n.guideClientHomeHighlightsTitle,
                          l10n.guideClientHomeHighlightsDesc,
                          _buildPromoCarousel())),
                  const SliverToBoxAdapter(child: SizedBox(height: 24)),
                  SliverToBoxAdapter(
                    child: _buildSectionHeader(
                      l10n.browseCategories,
                      onViewAll: () =>
                          const ClientAllCategories().launch(context),
                    ),
                  ),
                  SliverToBoxAdapter(
                      child: _exploreTarget(
                          _guideCategoriesKey,
                          l10n.guideClientHomeCategoriesTitle,
                          l10n.guideClientHomeCategoriesDesc,
                          _buildCategoriesGrid())),
                  const SliverToBoxAdapter(child: SizedBox(height: 18)),
                  SliverToBoxAdapter(
                    child: _buildSectionHeader(
                      l10n.yourRecentJobs,
                      onViewAll: () async {
                        await const JobPost().launch(context);
                        if (mounted) _loadData();
                      },
                    ),
                  ),
                  SliverToBoxAdapter(
                      child: _exploreTarget(
                          _guideRecentJobsKey,
                          l10n.guideClientHomeRecentJobsTitle,
                          l10n.guideClientHomeRecentJobsDesc,
                          _buildRecentJobs())),
                  const SliverToBoxAdapter(child: SizedBox(height: 18)),
                  SliverToBoxAdapter(
                    child: _buildSectionHeader(
                      l10n.topFreelancers,
                      onViewAll: () => context.go(AppRoutes.clientTalent),
                    ),
                  ),
                  SliverToBoxAdapter(
                      child: _exploreTarget(
                          _guideTopFreelancersKey,
                          l10n.guideClientHomeTopFreelancersTitle,
                          l10n.guideClientHomeTopFreelancersDesc,
                          _buildTopFreelancers())),
                  const SliverToBoxAdapter(child: SizedBox(height: 28)),
                ],
              ),
            ),
    ));
  }

  Widget _buildProfileNudge() {
    final l10n = context.l10n;
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Showcase(
        key: _guideNudgeKey,
        scope: guideScope,
        title: l10n.guideClientHomeNudgeTitle,
        description: l10n.guideClientHomeNudgeDesc,
        targetBorderRadius: BorderRadius.circular(16),
        child: Material(
          color: kWhite,
          borderRadius: BorderRadius.circular(16),
          child: InkWell(
            borderRadius: BorderRadius.circular(16),
            onTap: _openCompleteProfile,
            child: Container(
              padding: const EdgeInsets.fromLTRB(14, 12, 8, 12),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(16),
                border:
                    Border.all(color: kPrimaryColor.withValues(alpha: 0.35)),
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: kPrimaryColor.withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Icon(Icons.person_outline_rounded,
                        color: kPrimaryColor, size: 22),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          l10n.completeYourProfileTitle,
                          style: kTextStyle.copyWith(
                            color: kNeutralColor,
                            fontWeight: FontWeight.w700,
                            fontSize: 14,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          l10n.completeYourProfileBody,
                          style: kTextStyle.copyWith(
                            color: kSubTitleColor,
                            fontSize: 12.5,
                            height: 1.35,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          l10n.completeProfileAction,
                          style: kTextStyle.copyWith(
                            color: kPrimaryColor,
                            fontWeight: FontWeight.w700,
                            fontSize: 13,
                          ),
                        ),
                      ],
                    ),
                  ),
                  IconButton(
                    tooltip: l10n.later,
                    onPressed: _dismissProfileNudge,
                    icon: const Icon(Icons.close,
                        size: 18, color: kLightNeutralColor),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildSearchBar() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
      child: Showcase(
        key: _guideSearchKey,
        scope: guideScope,
        title: context.l10n.guideClientHomeSearchTitle,
        description: context.l10n.guideClientHomeSearchDesc,
        targetBorderRadius: BorderRadius.circular(12),
        child: GestureDetector(
          onTap: () {
            showSearch(
              context: context,
              delegate: CustomSearchDelegate(l10nContext: context),
            );
          },
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
            decoration: BoxDecoration(
              color: kWhite,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: kBorderColorTextField),
            ),
            child: Row(
              children: [
                const Icon(Icons.search, color: kLightNeutralColor, size: 22),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    context.l10n.searchHint,
                    style: kTextStyle.copyWith(
                        color: kLightNeutralColor, fontSize: 14),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  /// Wraps [child] as a guide target when [key] is set, else returns it as is.
  Widget _guideWrap(
      GlobalKey? key, String title, String description, Widget child) {
    if (key == null) return child;
    return Showcase(
      key: key,
      scope: guideScope,
      title: title,
      description: description,
      targetBorderRadius: BorderRadius.circular(14),
      child: child,
    );
  }

  // ------------------------- Quick actions -------------------------
  Widget _buildQuickActions() {
    final l10n = context.l10n;
    final actions = <_QuickAction>[
      _QuickAction(
        label: l10n.postJob,
        icon: Icons.add_business_rounded,
        color: kPrimaryColor,
        showcaseKey: _guidePostJobKey,
        onTap: () async {
          await const CreateNewJobPost().launch(context);
          if (mounted) _loadData();
        },
      ),
      _QuickAction(
        label: l10n.findTalent,
        icon: Icons.people_alt_rounded,
        color: kSecondaryColor,
        onTap: () => context.go(AppRoutes.clientTalent),
      ),
      _QuickAction(
        label: l10n.applications,
        icon: Icons.assignment_outlined,
        color: kAccentColor,
        onTap: () => context.push(AppRoutes.clientApplications),
      ),
      _QuickAction(
        label: l10n.contracts,
        icon: Icons.description_outlined,
        color: const Color(0xFF8B5CF6),
        onTap: () => context.go('/client/orders'),
      ),
    ];

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: _exploreTarget(
        _guideShortcutsKey,
        l10n.guideClientHomeShortcutsTitle,
        l10n.guideClientHomeShortcutsDesc,
        radius: 22,
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 14),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(22),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.05),
                blurRadius: 18,
                offset: const Offset(0, 8),
              ),
            ],
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: actions
                .map(
                  (a) => Expanded(
                    child: _guideWrap(
                      a.showcaseKey,
                      l10n.guideClientHomePostJobTitle,
                      l10n.guideClientHomePostJobDesc,
                      InkWell(
                        borderRadius: BorderRadius.circular(14),
                        onTap: a.onTap,
                        child: Padding(
                          padding: const EdgeInsets.symmetric(vertical: 4),
                          child: Column(
                            children: [
                              Container(
                                height: 46,
                                width: 46,
                                decoration: BoxDecoration(
                                  color: a.color.withOpacity(0.12),
                                  borderRadius: BorderRadius.circular(14),
                                ),
                                child: Icon(a.icon, color: a.color, size: 22),
                              ),
                              const SizedBox(height: 6),
                              Text(
                                a.label,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                textAlign: TextAlign.center,
                                style: kTextStyle.copyWith(
                                  fontSize: 11.5,
                                  fontWeight: FontWeight.w600,
                                  color: kNeutralColor,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ),
                )
                .toList(),
          ),
        ),
      ),
    );
  }

  // ------------------------- Promo carousel -------------------------
  Widget _buildPromoCarousel() {
    final l10n = context.l10n;
    final promos = <_Promo>[
      _Promo(
        title: l10n.hireTopRated,
        subtitle: l10n.promoVerifiedTalentSubtitle,
        cta: l10n.explore,
        gradient: kClientShellGradient,
        onTap: () => context.go(AppRoutes.clientTalent),
      ),
      _Promo(
        title: l10n.postAJobBanner,
        subtitle: l10n.promoProposalsSubtitle,
        cta: l10n.postNow,
        gradient: const [Color(0xFFEA580C), Color(0xFFF97316)],
        onTap: () async {
          await const CreateNewJobPost().launch(context);
          if (mounted) _loadData();
        },
      ),
      _Promo(
        title: l10n.browseCategories,
        subtitle: l10n.promoNicheServicesSubtitle,
        cta: l10n.browse,
        gradient: kSellerShellGradient,
        onTap: () => const ClientAllCategories().launch(context),
      ),
    ];

    return Column(
      children: [
        SizedBox(
          height: 160,
          child: PageView.builder(
            controller: _bannerController,
            itemCount: promos.length,
            onPageChanged: (i) => setState(() => _bannerIndex = i),
            itemBuilder: (_, i) {
              final p = promos[i];
              return Padding(
                padding: const EdgeInsets.symmetric(horizontal: 8),
                child: GestureDetector(
                  onTap: p.onTap,
                  child: Container(
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(22),
                      gradient: LinearGradient(
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                        colors: p.gradient,
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: p.gradient.first.withOpacity(0.32),
                          blurRadius: 18,
                          offset: const Offset(0, 10),
                        ),
                      ],
                    ),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(22),
                      child: Stack(
                        children: [
                          Positioned(
                            right: -20,
                            top: -20,
                            child: Container(
                              width: 140,
                              height: 140,
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                color: Colors.white.withOpacity(0.10),
                              ),
                            ),
                          ),
                          Positioned(
                            right: 40,
                            bottom: -30,
                            child: Container(
                              width: 100,
                              height: 100,
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                color: Colors.white.withOpacity(0.06),
                              ),
                            ),
                          ),
                          Padding(
                            padding: const EdgeInsets.all(18),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Expanded(
                                  child: LayoutBuilder(
                                    builder: (context, constraints) {
                                      return FittedBox(
                                        fit: BoxFit.scaleDown,
                                        alignment: Alignment.topLeft,
                                        child: SizedBox(
                                          width: constraints.maxWidth,
                                          child: Column(
                                            crossAxisAlignment:
                                                CrossAxisAlignment.start,
                                            mainAxisSize: MainAxisSize.min,
                                            children: [
                                              Text(
                                                p.title,
                                                softWrap: true,
                                                style: kTextStyle.copyWith(
                                                  color: Colors.white,
                                                  fontWeight: FontWeight.w800,
                                                  fontSize: 18,
                                                  height: 1.2,
                                                ),
                                              ),
                                              const SizedBox(height: 6),
                                              Text(
                                                p.subtitle,
                                                softWrap: true,
                                                style: kTextStyle.copyWith(
                                                  color: Colors.white
                                                      .withOpacity(0.85),
                                                  fontSize: 12,
                                                ),
                                              ),
                                            ],
                                          ),
                                        ),
                                      );
                                    },
                                  ),
                                ),
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                      horizontal: 14, vertical: 7),
                                  decoration: BoxDecoration(
                                    color: Colors.white,
                                    borderRadius: BorderRadius.circular(20),
                                  ),
                                  child: Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      Text(
                                        p.cta,
                                        style: kTextStyle.copyWith(
                                          color: kNeutralColor,
                                          fontWeight: FontWeight.w700,
                                          fontSize: 12,
                                        ),
                                      ),
                                      const SizedBox(width: 4),
                                      const Icon(Icons.arrow_forward_rounded,
                                          size: 14, color: kNeutralColor),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              );
            },
          ),
        ),
        const SizedBox(height: 12),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: List.generate(promos.length, (i) {
            final selected = i == _bannerIndex;
            return AnimatedContainer(
              duration: const Duration(milliseconds: 250),
              margin: const EdgeInsets.symmetric(horizontal: 3),
              height: 6,
              width: selected ? 22 : 6,
              decoration: BoxDecoration(
                color:
                    selected ? kPrimaryColor : kPrimaryColor.withOpacity(0.25),
                borderRadius: BorderRadius.circular(6),
              ),
            );
          }),
        ),
      ],
    );
  }

  // ------------------------- Section header -------------------------
  Widget _buildSectionHeader(String title, {VoidCallback? onViewAll}) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 8, 20, 12),
      child: Wrap(
        crossAxisAlignment: WrapCrossAlignment.center,
        alignment: WrapAlignment.spaceBetween,
        spacing: 8,
        runSpacing: 6,
        children: [
          Text(
            title,
            style: kTextStyle.copyWith(
              color: kNeutralColor,
              fontWeight: FontWeight.w800,
              fontSize: 16,
            ),
          ),
          if (onViewAll != null)
            GestureDetector(
              onTap: onViewAll,
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    context.l10n.seeAll,
                    style: kTextStyle.copyWith(
                      color: kPrimaryColor,
                      fontWeight: FontWeight.w600,
                      fontSize: 12,
                    ),
                  ),
                  const Icon(Icons.chevron_right_rounded,
                      size: 18, color: kPrimaryColor),
                ],
              ),
            ),
        ],
      ),
    );
  }

  // ------------------------- Categories grid -------------------------
  Widget _buildCategoriesGrid() {
    if (_categories.isEmpty) {
      return Padding(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 6),
        child: Text(
          context.l10n.noCategoriesYet,
          style: kTextStyle.copyWith(color: kLightNeutralColor),
        ),
      );
    }

    final visible = _categories.take(12).toList();
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: GridView.builder(
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 4,
          mainAxisSpacing: 14,
          crossAxisSpacing: 10,
          childAspectRatio: 0.75,
        ),
        itemCount: visible.length,
        itemBuilder: (_, i) {
          final cat = visible[i];
          final lang = LocalizedCategory.languageCodeOf(context);
          final catName = LocalizedCategory.name(cat, lang);
          return GestureDetector(
            onTap: () => ClientAllCategories(
              initialQuery: catName,
            ).launch(context),
            child: Column(
              children: [
                Expanded(
                  flex: 5,
                  child: Center(
                    child: LayoutBuilder(
                      builder: (context, constraints) {
                        final size =
                            constraints.biggest.shortestSide.clamp(40.0, 56.0);
                        return CategoryVisual(
                          iconKey: cat['icon'] as String?,
                          tint: _categoryTint(i),
                          iconColor: _categoryIconColor(i),
                          size: size,
                          radius: 18,
                        );
                      },
                    ),
                  ),
                ),
                Expanded(
                  flex: 3,
                  child: Padding(
                    padding: const EdgeInsets.only(top: 4),
                    child: Text(
                      catName,
                      textAlign: TextAlign.center,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: kTextStyle.copyWith(
                        color: kNeutralColor,
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                        height: 1.2,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  // ------------------------- Recent jobs -------------------------
  Widget _buildRecentJobs() {
    final l10n = context.l10n;
    if (_myRecentJobs.isEmpty) {
      return Padding(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 6),
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: kBorderColorTextField),
          ),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: kPrimaryColor.withOpacity(0.10),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(Icons.work_outline_rounded,
                    color: kPrimaryColor),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      l10n.noJobsYet,
                      style: kTextStyle.copyWith(
                        color: kNeutralColor,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      l10n.recentJobsEmptyHint,
                      style: kTextStyle.copyWith(
                        color: kLightNeutralColor,
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
              ),
              GestureDetector(
                onTap: () async {
                  await const CreateNewJobPost().launch(context);
                  if (mounted) _loadData();
                },
                child: Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  decoration: BoxDecoration(
                    color: kPrimaryColor,
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    l10n.postJobShort,
                    style: kTextStyle.copyWith(
                      color: Colors.white,
                      fontWeight: FontWeight.w700,
                      fontSize: 12,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      );
    }

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Column(
        children: _myRecentJobs.map((job) {
          final category = job['categories'] as Map<String, dynamic>?;
          final jobStatus = job['status'] as String? ?? 'open';
          final isOpen = jobStatus == 'open';
          final (jobStatusFg, _) = StatusColors.jobPost(jobStatus);
          return Padding(
            padding: const EdgeInsets.only(bottom: 10),
            child: GestureDetector(
              onTap: () async {
                await JobDetails(jobPostId: job['id'] as String)
                    .launch(context);
                if (mounted) await _loadData();
              },
              child: Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.04),
                      blurRadius: 12,
                      offset: const Offset(0, 6),
                    ),
                  ],
                ),
                child: Row(
                  children: [
                    Container(
                      width: 4,
                      height: 56,
                      decoration: BoxDecoration(
                        color: isOpen
                            ? StatusColors.success
                            : StatusColors.neutral,
                        borderRadius: BorderRadius.circular(4),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            job['title'] ?? l10n.untitled,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: kTextStyle.copyWith(
                              color: kNeutralColor,
                              fontWeight: FontWeight.w700,
                              fontSize: 14,
                            ),
                          ),
                          const SizedBox(height: 6),
                          Row(
                            children: [
                              _miniChip(
                                _jobTypeLabel(job['job_type'] as String?),
                                kPrimaryColor,
                              ),
                              const SizedBox(width: 6),
                              _miniChip(
                                isOpen
                                    ? context.l10n.open
                                    : context.l10n.closed,
                                jobStatusFg,
                              ),
                              const SizedBox(width: 6),
                              Expanded(
                                child: Text(
                                  LocalizedCategory.name(
                                    category,
                                    LocalizedCategory.languageCodeOf(context),
                                    fallback: l10n.categoryGeneral,
                                  ),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: kTextStyle.copyWith(
                                    color: kLightNeutralColor,
                                    fontSize: 11,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 8),
                    Container(
                      padding: const EdgeInsets.all(6),
                      decoration: BoxDecoration(
                        color: kDarkWhite,
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: const Icon(Icons.arrow_forward_ios_rounded,
                          size: 12, color: kNeutralColor),
                    ),
                  ],
                ),
              ),
            ),
          );
        }).toList(),
      ),
    );
  }

  Widget _miniChip(String label, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: color.withOpacity(0.12),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        label,
        style: kTextStyle.copyWith(
          color: color,
          fontSize: 10,
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }

  // ------------------------- Top freelancers -------------------------
  Widget _buildTopFreelancers() {
    final l10n = context.l10n;
    if (_topSellers.isEmpty) {
      return Padding(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 6),
        child: Text(
          l10n.noFreelancersYet,
          style: kTextStyle.copyWith(color: kLightNeutralColor),
        ),
      );
    }

    return SizedBox(
      height: 262,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        physics: const BouncingScrollPhysics(),
        padding: const EdgeInsets.symmetric(horizontal: 16),
        itemCount: _topSellers.length,
        separatorBuilder: (_, __) => const SizedBox(width: 14),
        itemBuilder: (_, i) {
          final seller = _topSellers[i];
          final profileImageUrl = seller['profile_image_url'] as String?;
          final ratingValue = double.tryParse('${seller['rating'] ?? 0}') ?? 0;
          final reviewCount = (seller['review_count'] as num?)?.toInt() ?? 0;
          final isVerified =
              VerificationService.statusFromProfile(seller) == 'verified';
          final sellerId = seller['id'] as String?;
          final sellerName = seller['name'] as String?;
          final subtitle = _topSellerSubtitle(seller, l10n, isVerified);

          return GestureDetector(
            onTap: sellerId == null
                ? null
                : () => openFreelancerPublicProfile(
                      context,
                      sellerId: sellerId,
                      name: sellerName,
                    ),
            child: Container(
              width: 200,
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: kBorderColorTextField),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.04),
                    blurRadius: 12,
                    offset: const Offset(0, 6),
                  ),
                ],
              ),
              clipBehavior: Clip.antiAlias,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: Stack(
                      fit: StackFit.expand,
                      children: [
                        DecoratedBox(
                          decoration: BoxDecoration(
                            image: DecorationImage(
                              image: ProfileImage.provider(profileImageUrl),
                              fit: BoxFit.cover,
                            ),
                          ),
                        ),
                        Positioned(
                          left: 0,
                          right: 0,
                          bottom: 0,
                          height: 28,
                          child: DecoratedBox(
                            decoration: BoxDecoration(
                              gradient: LinearGradient(
                                begin: Alignment.topCenter,
                                end: Alignment.bottomCenter,
                                colors: [
                                  Colors.transparent,
                                  Colors.black.withValues(alpha: 0.28),
                                ],
                              ),
                            ),
                          ),
                        ),
                        Positioned(
                          top: 8,
                          left: 8,
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 8,
                              vertical: 4,
                            ),
                            decoration: BoxDecoration(
                              color: Colors.black.withValues(alpha: 0.5),
                              borderRadius: BorderRadius.circular(20),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                const Icon(
                                  IconlyBold.star,
                                  color: Colors.amber,
                                  size: 13,
                                ),
                                const SizedBox(width: 3),
                                Text(
                                  ratingValue.toStringAsFixed(1),
                                  style: kTextStyle.copyWith(
                                    color: Colors.white,
                                    fontSize: 11,
                                    fontWeight: FontWeight.w700,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                        Positioned(
                          top: 8,
                          right: 8,
                          child: TalentCardVerificationMark(
                            profile: seller,
                            size: 34,
                            onPhoto: true,
                          ),
                        ),
                      ],
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.fromLTRB(10, 8, 10, 10),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          seller['name'] ?? l10n.authRoleFreelancer,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: kTextStyle.copyWith(
                            color: kNeutralColor,
                            fontWeight: FontWeight.w700,
                            fontSize: 13,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          subtitle,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: kTextStyle.copyWith(
                            color: kLightNeutralColor,
                            fontSize: 11,
                          ),
                        ),
                        const SizedBox(height: 6),
                        TalentCardStandingChip(
                          rating: ratingValue,
                          reviewCount: reviewCount,
                          onPhoto: false,
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  String _topSellerSubtitle(
    Map<String, dynamic> seller,
    AppLocalizations l10n,
    bool isVerified,
  ) {
    final headline = (seller['headline'] as String?)?.trim();
    if (headline != null && headline.isNotEmpty) return headline;

    final sp = seller['seller_profiles'];
    Map<String, dynamic>? row;
    if (sp is Map<String, dynamic>) {
      row = sp;
    } else if (sp is List &&
        sp.isNotEmpty &&
        sp.first is Map<String, dynamic>) {
      row = sp.first as Map<String, dynamic>;
    }
    final jobTitle = (row?['job_title'] as String?)?.trim();
    if (jobTitle != null && jobTitle.isNotEmpty) return jobTitle;

    if (isVerified) return l10n.verifiedFreelancer;
    return l10n.freelancerDefault;
  }
}

class _QuickAction {
  final String label;
  final IconData icon;
  final Color color;
  final VoidCallback onTap;

  /// Guide target key; set on the first action only (one key, one widget).
  final GlobalKey? showcaseKey;

  const _QuickAction({
    required this.label,
    required this.icon,
    required this.color,
    required this.onTap,
    this.showcaseKey,
  });
}

class _Promo {
  final String title;
  final String subtitle;
  final String cta;
  final List<Color> gradient;
  final VoidCallback onTap;

  const _Promo({
    required this.title,
    required this.subtitle,
    required this.cta,
    required this.gradient,
    required this.onTap,
  });
}

/// Placeholder layout while home data loads (first paint stays fast).
class _ClientHomeLoading extends StatelessWidget {
  const _ClientHomeLoading();

  static BoxDecoration _card(Color c) => BoxDecoration(
        color: c,
        borderRadius: BorderRadius.circular(20),
      );

  @override
  Widget build(BuildContext context) {
    final muted = kLightNeutralColor.withOpacity(0.35);

    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            height: 48,
            decoration: _card(muted),
          ),
          const SizedBox(height: 22),
          Container(
            height: 96,
            decoration: _card(Colors.white),
          ),
          const SizedBox(height: 22),
          Container(
            height: 150,
            decoration: _card(Colors.white),
          ),
          const SizedBox(height: 24),
          Container(
            height: 16,
            width: 140,
            decoration: _card(muted),
          ),
          const SizedBox(height: 14),
          GridView.count(
            crossAxisCount: 4,
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            mainAxisSpacing: 12,
            crossAxisSpacing: 10,
            childAspectRatio: 0.75,
            children: List.generate(
              8,
              (_) => Column(
                children: [
                  Expanded(
                    flex: 5,
                    child: Center(
                      child: Container(
                        height: 52,
                        width: 52,
                        decoration: _card(muted),
                      ),
                    ),
                  ),
                  Expanded(
                    flex: 3,
                    child: Padding(
                      padding: const EdgeInsets.only(top: 4),
                      child: Container(
                        height: 10,
                        width: 40,
                        decoration: _card(muted),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
