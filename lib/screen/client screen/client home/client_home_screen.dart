import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_iconly/flutter_iconly.dart';
import 'package:freelancer/data/repositories/notification_repository.dart';
import 'package:freelancer/screen/client%20screen/client%20job%20post/client_job_post.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:freelancer/screen/client%20screen/client%20job%20post/job_details.dart';
import 'package:freelancer/services/client_home_service.dart';
import 'package:freelancer/services/job_posts_service.dart';
import 'package:go_router/go_router.dart';
import 'package:nb_utils/nb_utils.dart';

import '../../../router/route_names.dart';
import '../../widgets/client_shell_app_bar.dart';
import '../../widgets/constant.dart';
import '../client notification/client_notification.dart';
import '../search/search.dart';
import 'package:freelancer/core/utils/category_icons.dart';

import '../client talent/freelancer_public_profile.dart';
import 'client_all_categories.dart';

class ClientHomeScreen extends StatefulWidget {
  const ClientHomeScreen({Key? key}) : super(key: key);

  @override
  State<ClientHomeScreen> createState() => _ClientHomeScreenState();
}

class _ClientHomeScreenState extends State<ClientHomeScreen> {
  List<Map<String, dynamic>> _categories = [];
  List<Map<String, dynamic>> _myRecentJobs = [];
  List<Map<String, dynamic>> _topSellers = [];
  bool _isLoading = true;
  int _unreadNotificationCount = 0;
  RealtimeChannel? _notificationChannel;
  NotificationRepository? _notificationRepository;

  final PageController _bannerController =
      PageController(viewportFraction: 0.9);
  int _bannerIndex = 0;

  @override
  void initState() {
    super.initState();
    // Defer Supabase work until after the first frame so the loading
    // skeleton paints immediately instead of blocking the initial render.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      _loadData();
      _loadUnreadNotificationCount();
      _subscribeToNotifications();
    });
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _notificationRepository ??= context.read<NotificationRepository>();
  }

  @override
  void dispose() {
    _notificationRepository?.unsubscribe(_notificationChannel);
    _bannerController.dispose();
    super.dispose();
  }

  Future<void> _loadUnreadNotificationCount() async {
    try {
      final count = await context.read<NotificationRepository>().getUnreadCount();
      if (mounted) setState(() => _unreadNotificationCount = count);
    } catch (_) {}
  }

  void _subscribeToNotifications() {
    try {
      _notificationChannel = context.read<NotificationRepository>().subscribeToNotifications(
            onChange: _loadUnreadNotificationCount,
          );
    } catch (_) {}
  }

  Future<void> _loadData() async {
    try {
      final results = await Future.wait([
        ClientHomeService.getCategories(),
        JobPostsService.getClientJobPosts(),
        ClientHomeService.getTopSellers(),
      ]);

      if (mounted) {
        final myJobs = results[1] as List<Map<String, dynamic>>;
        setState(() {
          _categories = results[0] as List<Map<String, dynamic>>;
          _myRecentJobs = myJobs.take(3).toList();
          _topSellers = results[2] as List<Map<String, dynamic>>;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error loading data: $e')),
        );
      }
    }
  }

  static String _jobTypeLabel(String? t) {
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

  // Soft tints rotated through category cells for visual variety.
  Color _categoryTint(int i) {
    const tints = [
      Color(0x1A16A34A),
      Color(0x1A2563EB),
      Color(0x1AF97316),
      Color(0x1A8B5CF6),
      Color(0x1AEF4444),
      Color(0x1A06B6D4),
      Color(0x1AEAB308),
      Color(0x1AEC4899),
    ];
    return tints[i % tints.length];
  }

  Color _categoryIconColor(int i) {
    const colors = [
      Color(0xFF16A34A),
      Color(0xFF2563EB),
      Color(0xFFF97316),
      Color(0xFF8B5CF6),
      Color(0xFFEF4444),
      Color(0xFF06B6D4),
      Color(0xFFEAB308),
      Color(0xFFEC4899),
    ];
    return colors[i % colors.length];
  }


  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: kDarkWhite,
      appBar: ClientShellAppBar(
        title: 'Home',
        actions: _isLoading ? null : _homeAppBarActions(),
      ),
      body: _isLoading
          ? const _ClientHomeLoading()
          : RefreshIndicator(
              color: kPrimaryColor,
              onRefresh: _loadData,
              child: CustomScrollView(
                physics: const AlwaysScrollableScrollPhysics(
                    parent: BouncingScrollPhysics()),
                slivers: [
                  SliverToBoxAdapter(child: _buildSearchBar()),
                  const SliverToBoxAdapter(child: SizedBox(height: 16)),
                  SliverToBoxAdapter(child: _buildQuickActions()),
                  const SliverToBoxAdapter(child: SizedBox(height: 22)),
                  SliverToBoxAdapter(child: _buildPromoCarousel()),
                  const SliverToBoxAdapter(child: SizedBox(height: 24)),
                  SliverToBoxAdapter(
                    child: _buildSectionHeader(
                      'Browse Categories',
                      onViewAll: () =>
                          const ClientAllCategories().launch(context),
                    ),
                  ),
                  SliverToBoxAdapter(child: _buildCategoriesGrid()),
                  const SliverToBoxAdapter(child: SizedBox(height: 18)),
                  SliverToBoxAdapter(
                    child: _buildSectionHeader(
                      'Your Recent Jobs',
                      onViewAll: () => const JobPost().launch(context),
                    ),
                  ),
                  SliverToBoxAdapter(child: _buildRecentJobs()),
                  const SliverToBoxAdapter(child: SizedBox(height: 18)),
                  SliverToBoxAdapter(
                    child: _buildSectionHeader(
                      'Top Freelancers',
                      onViewAll: () => context.go(AppRoutes.clientTalent),
                    ),
                  ),
                  SliverToBoxAdapter(child: _buildTopFreelancers()),
                  const SliverToBoxAdapter(child: SizedBox(height: 28)),
                ],
              ),
            ),
    );
  }

  List<Widget> _homeAppBarActions() {
    return [
      IconButton(
        tooltip: 'Notifications',
        onPressed: () async {
          await const ClientNotification().launch(context);
          if (mounted) _loadUnreadNotificationCount();
        },
        icon: _unreadNotificationCount > 0
            ? Badge(
                label: Text(
                  _unreadNotificationCount > 9 ? '9+' : '$_unreadNotificationCount',
                  style: const TextStyle(fontSize: 10),
                ),
                child: const Icon(Icons.notifications_outlined),
              )
            : const Icon(Icons.notifications_outlined),
      ),
    ];
  }

  Widget _buildSearchBar() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
      child: GestureDetector(
        onTap: () {
          showSearch(
            context: context,
            delegate: CustomSearchDelegate(),
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
                  'Search services, freelancers...',
                  style: kTextStyle.copyWith(color: kLightNeutralColor, fontSize: 14),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ------------------------- Quick actions -------------------------
  Widget _buildQuickActions() {
    final actions = <_QuickAction>[
      _QuickAction(
        label: 'Post Job',
        icon: Icons.add_business_rounded,
        color: kPrimaryColor,
        onTap: () => const JobPost().launch(context),
      ),
      _QuickAction(
        label: 'Find Talent',
        icon: Icons.people_alt_rounded,
        color: kSecondaryColor,
        onTap: () => context.go(AppRoutes.clientTalent),
      ),
      _QuickAction(
        label: 'Categories',
        icon: Icons.category_rounded,
        color: kAccentColor,
        onTap: () => const ClientAllCategories().launch(context),
      ),
      _QuickAction(
        label: 'Contracts',
        icon: Icons.description_outlined,
        color: const Color(0xFF8B5CF6),
        onTap: () => context.go('/client/orders'),
      ),
    ];

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Container(
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
                  child: InkWell(
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
              )
              .toList(),
        ),
      ),
    );
  }

  // ------------------------- Promo carousel -------------------------
  Widget _buildPromoCarousel() {
    final promos = <_Promo>[
      _Promo(
        title: 'Hire top-rated\nfreelancers',
        subtitle: 'Verified talent for every project',
        cta: 'Explore',
        gradient: const [Color(0xFF16A34A), Color(0xFF0EA5E9)],
        onTap: () => context.go(AppRoutes.clientTalent),
      ),
      _Promo(
        title: 'Post a job\nin seconds',
        subtitle: 'Get proposals within minutes',
        cta: 'Post Now',
        gradient: const [Color(0xFFF97316), Color(0xFFEF4444)],
        onTap: () => const JobPost().launch(context),
      ),
      _Promo(
        title: 'Discover new\ncategories',
        subtitle: 'Find services across every niche',
        cta: 'Browse',
        gradient: const [Color(0xFF8B5CF6), Color(0xFFEC4899)],
        onTap: () => const ClientAllCategories().launch(context),
      ),
    ];

    return Column(
      children: [
        SizedBox(
          height: 150,
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
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      p.title,
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
                                      style: kTextStyle.copyWith(
                                        color: Colors.white.withOpacity(0.85),
                                        fontSize: 12,
                                      ),
                                    ),
                                  ],
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
                color: selected
                    ? kPrimaryColor
                    : kPrimaryColor.withOpacity(0.25),
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
      child: Row(
        children: [
          Text(
            title,
            style: kTextStyle.copyWith(
              color: kNeutralColor,
              fontWeight: FontWeight.w800,
              fontSize: 16,
            ),
          ),
          const Spacer(),
          if (onViewAll != null)
            GestureDetector(
              onTap: onViewAll,
              child: Row(
                children: [
                  Text(
                    'See all',
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
          'No categories yet',
          style: kTextStyle.copyWith(color: kLightNeutralColor),
        ),
      );
    }

    final visible = _categories.take(8).toList();
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: GridView.builder(
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 4,
          mainAxisSpacing: 14,
          crossAxisSpacing: 10,
          childAspectRatio: 0.82,
        ),
        itemCount: visible.length,
        itemBuilder: (_, i) {
          final cat = visible[i];
          return GestureDetector(
            onTap: () => const ClientAllCategories().launch(context),
            child: Column(
              children: [
                Container(
                  height: 56,
                  width: 56,
                  decoration: BoxDecoration(
                    color: _categoryTint(i),
                    borderRadius: BorderRadius.circular(18),
                    border: Border.all(
                      color: _categoryIconColor(i).withOpacity(0.15),
                    ),
                  ),
                  child: Icon(
                    CategoryIcons.iconData(cat['icon'] as String?),
                    size: 28,
                    color: _categoryIconColor(i),
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  cat['name'] ?? '',
                  textAlign: TextAlign.center,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: kTextStyle.copyWith(
                    color: kNeutralColor,
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
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
                      'No jobs posted yet',
                      style: kTextStyle.copyWith(
                        color: kNeutralColor,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      'Tap "Post Job" to get started',
                      style: kTextStyle.copyWith(
                        color: kLightNeutralColor,
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
              ),
              GestureDetector(
                onTap: () => const JobPost().launch(context),
                child: Container(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 12, vertical: 8),
                  decoration: BoxDecoration(
                    color: kPrimaryColor,
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    'Post',
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
          final isOpen = job['status'] == 'open';
          return Padding(
            padding: const EdgeInsets.only(bottom: 10),
            child: GestureDetector(
              onTap: () async {
                await JobDetails(jobPostId: job['id'] as String)
                    .launch(context);
                _loadData();
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
                        color: isOpen ? kPrimaryColor : kLightNeutralColor,
                        borderRadius: BorderRadius.circular(4),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            job['title'] ?? 'Untitled',
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
                                isOpen ? 'Open' : 'Closed',
                                isOpen ? kSecondaryColor : kLightNeutralColor,
                              ),
                              const SizedBox(width: 6),
                              Expanded(
                                child: Text(
                                  category?['name'] ?? 'General',
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
    if (_topSellers.isEmpty) {
      return Padding(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 6),
        child: Text(
          'No freelancers yet',
          style: kTextStyle.copyWith(color: kLightNeutralColor),
        ),
      );
    }

    return SizedBox(
      height: 244,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        physics: const BouncingScrollPhysics(),
        padding: const EdgeInsets.symmetric(horizontal: 16),
        itemCount: _topSellers.length,
        separatorBuilder: (_, __) => const SizedBox(width: 12),
        itemBuilder: (_, i) {
          final seller = _topSellers[i];
          final profileImageUrl = seller['profile_image_url'] as String?;
          final ratingValue =
              double.tryParse('${seller['rating'] ?? 0}') ?? 0;
          final isPro = ratingValue >= 4.5;

          final sellerId = seller['id'] as String?;
          final sellerName = seller['name'] as String?;

          return GestureDetector(
            onTap: sellerId == null
                ? null
                : () => openFreelancerPublicProfile(
                      context,
                      sellerId: sellerId,
                      name: sellerName,
                    ),
            child: Container(
              width: 170,
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(20),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.05),
                    blurRadius: 14,
                    offset: const Offset(0, 8),
                  ),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Stack(
                    children: [
                      Container(
                        height: 130,
                        width: double.infinity,
                        decoration: BoxDecoration(
                          borderRadius: const BorderRadius.vertical(
                              top: Radius.circular(20)),
                          image: DecorationImage(
                            image: profileImageUrl != null
                                ? NetworkImage(profileImageUrl)
                                    as ImageProvider
                                : const AssetImage('images/dev1.png'),
                            fit: BoxFit.cover,
                          ),
                        ),
                      ),
                      if (isPro)
                        Positioned(
                          top: 10,
                          left: 10,
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 8, vertical: 3),
                            decoration: BoxDecoration(
                              color: kAccentColor,
                              borderRadius: BorderRadius.circular(20),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                const Icon(Icons.workspace_premium_rounded,
                                    size: 12, color: Colors.white),
                                const SizedBox(width: 2),
                                Text(
                                  'Pro',
                                  style: kTextStyle.copyWith(
                                    color: Colors.white,
                                    fontSize: 10,
                                    fontWeight: FontWeight.w700,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      Positioned(
                        top: 10,
                        right: 10,
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 6, vertical: 3),
                          decoration: BoxDecoration(
                            color: Colors.black.withOpacity(0.55),
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              const Icon(IconlyBold.star,
                                  color: Colors.amber, size: 12),
                              const SizedBox(width: 2),
                              Text(
                                ratingValue.toStringAsFixed(1),
                                style: kTextStyle.copyWith(
                                  color: Colors.white,
                                  fontSize: 10,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                  Padding(
                    padding: const EdgeInsets.fromLTRB(10, 10, 10, 12),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          seller['name'] ?? 'Freelancer',
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
                          (seller['headline'] as String?) ??
                              'Verified Freelancer',
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: kTextStyle.copyWith(
                            color: kLightNeutralColor,
                            fontSize: 11,
                          ),
                        ),
                        const SizedBox(height: 10),
                        Container(
                          width: double.infinity,
                          padding: const EdgeInsets.symmetric(vertical: 7),
                          decoration: BoxDecoration(
                            color: kPrimaryColor.withOpacity(0.10),
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: Center(
                            child: Text(
                              'View Profile',
                              style: kTextStyle.copyWith(
                                color: kPrimaryColor,
                                fontWeight: FontWeight.w700,
                                fontSize: 11,
                              ),
                            ),
                          ),
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
}

class _QuickAction {
  final String label;
  final IconData icon;
  final Color color;
  final VoidCallback onTap;

  const _QuickAction({
    required this.label,
    required this.icon,
    required this.color,
    required this.onTap,
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
            childAspectRatio: 0.85,
            children: List.generate(
              8,
              (_) => Column(
                children: [
                  Container(
                    height: 52,
                    width: 52,
                    decoration: _card(muted),
                  ),
                  const SizedBox(height: 8),
                  Container(
                    height: 10,
                    width: 40,
                    decoration: _card(muted),
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
