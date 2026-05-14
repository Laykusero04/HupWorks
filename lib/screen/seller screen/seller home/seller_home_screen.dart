import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_feather_icons/flutter_feather_icons.dart';
import 'package:freelancer/core/utils/job_offer_delivery.dart';
import 'package:flutter_iconly/flutter_iconly.dart';
import 'package:freelancer/screen/widgets/constant.dart';
import 'package:freelancer/services/job_posts_service.dart';
import 'package:freelancer/services/seller_home_service.dart';
import 'package:freelancer/services/seller_orders_service.dart';
import 'package:go_router/go_router.dart';
import 'package:nb_utils/nb_utils.dart';

import '../../widgets/chart.dart';
import '../notification/seller_notification.dart';

/// Light icons on the blue hero; transparent status bar so the gradient reaches the top.
const _sellerHubSystemUi = SystemUiOverlayStyle(
  statusBarColor: Colors.transparent,
  statusBarIconBrightness: Brightness.light,
  statusBarBrightness: Brightness.dark,
  systemNavigationBarColor: kWhite,
  systemNavigationBarIconBrightness: Brightness.dark,
);

class SellerHomeScreen extends StatefulWidget {
  const SellerHomeScreen({Key? key}) : super(key: key);

  @override
  State<SellerHomeScreen> createState() => _SellerHomeScreenState();
}

class _SellerHomeScreenState extends State<SellerHomeScreen> {
  Map<String, dynamic>? _profile;
  Map<String, dynamic> _performance = {};
  Map<String, double> _statistics = {};
  Map<String, dynamic> _earnings = {};
  List<Map<String, dynamic>> _myApplications = [];
  int _pendingApplicationCount = 0;
  bool _isLoading = true;

  String _selectedPerformancePeriod = 'This Month';
  String _selectedEarningPeriod = 'This Month';

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      _loadData();
    });
  }

  Future<void> _loadData() async {
    try {
      final results = await Future.wait([
        SellerHomeService.getSellerProfile(),
        SellerHomeService.getPerformance(isLastMonth: _selectedPerformancePeriod == 'Last Month'),
        SellerHomeService.getStatistics(),
        SellerHomeService.getEarnings(isLastMonth: _selectedEarningPeriod == 'Last Month'),
        SellerOrdersService.getMyApplications(),
      ]);

      if (mounted) {
        final apps = results[4] as List<Map<String, dynamic>>;
        final pending = apps.where((a) {
          final s = (a['status'] as String?) ?? 'pending';
          return s == 'pending';
        }).length;
        setState(() {
          _profile = results[0] as Map<String, dynamic>?;
          _performance = results[1] as Map<String, dynamic>;
          _statistics = results[2] as Map<String, double>;
          _earnings = results[3] as Map<String, dynamic>;
          _pendingApplicationCount = pending;
          _myApplications = apps.take(5).toList();
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

  Future<void> _reloadPerformance() async {
    final perf = await SellerHomeService.getPerformance(
      isLastMonth: _selectedPerformancePeriod == 'Last Month',
    );
    if (mounted) setState(() => _performance = perf);
  }

  Future<void> _reloadEarnings() async {
    final earn = await SellerHomeService.getEarnings(
      isLastMonth: _selectedEarningPeriod == 'Last Month',
    );
    if (mounted) setState(() => _earnings = earn);
  }

  Widget _buildPeriodDropdown(String value, List<String> items, ValueChanged<String?> onChanged) {
    return SizedBox(
      height: 30,
      child: Container(
        padding: const EdgeInsets.all(5.0),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(30.0),
          border: Border.all(color: kLightNeutralColor),
        ),
        child: DropdownButtonHideUnderline(
          child: DropdownButton<String>(
            icon: const Icon(FeatherIcons.chevronDown),
            value: value,
            style: kTextStyle.copyWith(color: kSubTitleColor),
            items: items.map((s) => DropdownMenuItem(value: s, child: Text(s, style: kTextStyle.copyWith(color: kSubTitleColor)))).toList(),
            onChanged: onChanged,
          ),
        ),
      ),
    );
  }

  String _sellerTagline() {
    final bio = (_profile?['bio'] as String?)?.trim();
    if (bio != null && bio.isNotEmpty) return bio;
    return 'Deliver great work, build your reputation, and grow your income.';
  }

  Widget _buildSellerHero(
    BuildContext context, {
    required String name,
    required String? profileImageUrl,
    required String tagline,
  }) {
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            Color(0xFF0F4AC9),
            Color(0xFF144BD6),
            Color(0xFF06AEF3),
          ],
        ),
        borderRadius: const BorderRadius.vertical(bottom: Radius.circular(28)),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF144BD6).withOpacity(0.22),
            blurRadius: 18,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      padding: EdgeInsets.fromLTRB(
        16,
        6 + MediaQuery.viewPaddingOf(context).top,
        16,
        18,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              GestureDetector(
                onTap: () => context.go('/seller/profile'),
                child: Container(
                  height: 48,
                  width: 48,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    border: Border.all(color: Colors.white, width: 2),
                    image: DecorationImage(
                      image: profileImageUrl != null
                          ? NetworkImage(profileImageUrl) as ImageProvider
                          : const AssetImage('images/profilepic.png'),
                      fit: BoxFit.cover,
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Seller hub',
                      style: kTextStyle.copyWith(
                        color: Colors.white.withOpacity(0.88),
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      name,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: kTextStyle.copyWith(
                        color: Colors.white,
                        fontWeight: FontWeight.w800,
                        fontSize: 20,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      tagline,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: kTextStyle.copyWith(
                        color: Colors.white.withOpacity(0.9),
                        fontSize: 12,
                        height: 1.35,
                      ),
                    ),
                  ],
                ),
              ),
              GestureDetector(
                onTap: () => const SellerNotification().launch(context),
                child: Stack(
                  clipBehavior: Clip.none,
                  children: [
                    Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.18),
                        shape: BoxShape.circle,
                        border: Border.all(color: Colors.white.withOpacity(0.35)),
                      ),
                      child: const Icon(IconlyLight.notification, color: Colors.white, size: 20),
                    ),
                    if (_pendingApplicationCount > 0)
                      Positioned(
                        right: 2,
                        top: 2,
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 2),
                          decoration: BoxDecoration(
                            color: kAccentColor,
                            borderRadius: BorderRadius.circular(10),
                            border: Border.all(color: Colors.white, width: 1.5),
                          ),
                          constraints: const BoxConstraints(minWidth: 18),
                          child: Text(
                            _pendingApplicationCount > 9 ? '9+' : '$_pendingApplicationCount',
                            textAlign: TextAlign.center,
                            style: kTextStyle.copyWith(
                              color: Colors.white,
                              fontSize: 10,
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                        ),
                      ),
                  ],
                ),
              ),
            ],
          ),
          if (_pendingApplicationCount > 0) ...[
            const SizedBox(height: 14),
            GestureDetector(
              onTap: () => context.push('/seller/applications'),
              child: Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.16),
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: Colors.white.withOpacity(0.28)),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.hourglass_top_rounded, color: Colors.white, size: 18),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        _pendingApplicationCount == 1
                            ? '1 application is still pending'
                            : '$_pendingApplicationCount applications are still pending',
                        style: kTextStyle.copyWith(
                          color: Colors.white,
                          fontWeight: FontWeight.w600,
                          fontSize: 12,
                        ),
                      ),
                    ),
                    const Icon(Icons.chevron_right_rounded, color: Colors.white, size: 22),
                  ],
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return Scaffold(
        backgroundColor: kDarkWhite,
        body: AnnotatedRegion<SystemUiOverlayStyle>(
          value: _sellerHubSystemUi,
          child: const _SellerHomeLoading(),
        ),
      );
    }

    final name = _profile?['name'] ?? 'Seller';
    final profileImageUrl = _profile?['profile_image_url'] as String?;
    final tagline = _sellerTagline();
    final completedOrders = _performance['completed_orders'] ?? 0;
    final avgRating = _performance['avg_rating'] ?? 0.0;
    final totalServices = _performance['total_services'] ?? 0;
    final totalEarnings = _earnings['total_earnings'] ?? 0.0;
    final totalWithdrawals = _earnings['total_withdrawals'] ?? 0.0;
    final currentBalance = _earnings['current_balance'] ?? 0.0;
    final activeOrdersValue = _earnings['active_orders_value'] ?? 0.0;

    // Ensure statistics has non-zero values for the pie chart
    final statsForChart = _statistics.isEmpty || _statistics.values.every((v) => v == 0)
        ? {'Impressions': 1.0, 'Interaction': 1.0, 'Reached-Out': 1.0}
        : _statistics;

    return Scaffold(
      backgroundColor: kDarkWhite,
      body: AnnotatedRegion<SystemUiOverlayStyle>(
        value: _sellerHubSystemUi,
        child: Column(
          children: [
            _buildSellerHero(
              context,
              name: name,
              profileImageUrl: profileImageUrl,
              tagline: tagline,
            ),
            Expanded(
              child: Container(
                width: context.width(),
                padding: const EdgeInsets.only(left: 15.0, right: 15.0),
                decoration: const BoxDecoration(
                  color: kWhite,
                  borderRadius: BorderRadius.only(
                    topLeft: Radius.circular(28.0),
                    topRight: Radius.circular(28.0),
                  ),
                ),
                child: RefreshIndicator(
                  color: kPrimaryColor,
                  onRefresh: _loadData,
                  child: SingleChildScrollView(
                    physics: const AlwaysScrollableScrollPhysics(parent: BouncingScrollPhysics()),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const SizedBox(height: 14.0),
                        GestureDetector(
                          onTap: () => context.go('/seller/find-jobs'),
                          child: Container(
                            width: double.infinity,
                            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(18),
                              gradient: const LinearGradient(
                                begin: Alignment.centerLeft,
                                end: Alignment.centerRight,
                                colors: [
                                  Color(0xFF144BD6),
                                  Color(0xFF0EA5E9),
                                ],
                              ),
                              boxShadow: [
                                BoxShadow(
                                  color: kSecondaryColor.withOpacity(0.28),
                                  blurRadius: 14,
                                  offset: const Offset(0, 8),
                                ),
                              ],
                            ),
                            child: Row(
                              children: [
                                Container(
                                  padding: const EdgeInsets.all(10),
                                  decoration: BoxDecoration(
                                    color: Colors.white.withOpacity(0.2),
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  child: const Icon(Icons.rocket_launch_rounded, color: Colors.white, size: 22),
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        'Find your next job',
                                        style: kTextStyle.copyWith(
                                          color: Colors.white,
                                          fontWeight: FontWeight.w800,
                                          fontSize: 15,
                                        ),
                                      ),
                                      const SizedBox(height: 2),
                                      Text(
                                        'Browse open posts and send tailored offers',
                                        style: kTextStyle.copyWith(
                                          color: Colors.white.withOpacity(0.9),
                                          fontSize: 11.5,
                                          height: 1.25,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                                Icon(Icons.chevron_right_rounded, color: Colors.white.withOpacity(0.95), size: 26),
                              ],
                            ),
                          ),
                        ),
                        const SizedBox(height: 16.0),

                    _buildQuickActions(context),

                    const SizedBox(height: 20.0),

                    // Performance Card
                    _buildCard(
                      title: 'Performance',
                      dropdown: _buildPeriodDropdown(
                        _selectedPerformancePeriod,
                        ['Last Month', 'This Month'],
                        (v) {
                          setState(() => _selectedPerformancePeriod = v!);
                          _reloadPerformance();
                        },
                      ),
                      child: Column(
                        children: [
                          Row(
                            children: [
                              Expanded(child: Summary(title: '$completedOrders Orders', subtitle: 'Order Completions')),
                              const SizedBox(width: 10.0),
                              Expanded(child: Summary2(title1: '${avgRating.toStringAsFixed(1)}/', title2: '5.0', subtitle: 'Positive Ratings')),
                            ],
                          ),
                          const SizedBox(height: 10.0),
                          Row(
                            children: [
                              Expanded(child: Summary(title: 'Services: $totalServices', subtitle: 'Total Services')),
                              const SizedBox(width: 10.0),
                              const Expanded(child: SizedBox()),
                            ],
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 20.0),

                    // Statistics Card
                    _buildCard(
                      title: 'Statistics',
                      dropdown: Text(
                        'All time',
                        style: kTextStyle.copyWith(color: kLightNeutralColor, fontSize: 12),
                      ),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.center,
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Expanded(
                            child: RecordStatistics(dataMap: statsForChart, colorList: colorList),
                          ),
                          Expanded(
                            child: Column(
                              children: [
                                ChartLegend(iconColor: const Color(0xFF69B22A), title: 'Impressions', value: '${(_statistics['Impressions'] ?? 0).toInt()}'),
                                ChartLegend(iconColor: const Color(0xFF144BD6), title: 'Interaction', value: '${(_statistics['Interaction'] ?? 0).toInt()}'),
                                ChartLegend(iconColor: const Color(0xFFFF3B30), title: 'Reached-Out', value: '${(_statistics['Reached-Out'] ?? 0).toInt()}'),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 20.0),

                    // Earnings Card
                    _buildCard(
                      title: 'Earnings',
                      dropdown: _buildPeriodDropdown(
                        _selectedEarningPeriod,
                        ['Last Month', 'This Month'],
                        (v) {
                          setState(() => _selectedEarningPeriod = v!);
                          _reloadEarnings();
                        },
                      ),
                      child: Column(
                        children: [
                          Row(
                            children: [
                              Expanded(child: Summary(title: '$currencySign${totalEarnings.toStringAsFixed(2)}', subtitle: 'Total Earnings')),
                              const SizedBox(width: 10.0),
                              Expanded(child: Summary(title: '$currencySign${totalWithdrawals.toStringAsFixed(2)}', subtitle: 'Withdraw Earnings')),
                            ],
                          ),
                          const SizedBox(height: 10.0),
                          Row(
                            children: [
                              Expanded(child: Summary(title: '$currencySign${currentBalance.toStringAsFixed(2)}', subtitle: 'Current Balance')),
                              const SizedBox(width: 10.0),
                              Expanded(child: Summary(title: '$currencySign${activeOrdersValue.toStringAsFixed(2)}', subtitle: 'Active Orders')),
                            ],
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 20.0),

                    // My Applications
                        GestureDetector(
                          onTap: () => context.push('/seller/applications'),
                          child: Row(
                            children: [
                              Text(
                                'My Applications',
                                style: kTextStyle.copyWith(color: kNeutralColor, fontWeight: FontWeight.bold),
                              ),
                              const Spacer(),
                              Text(
                                'View all',
                                style: kTextStyle.copyWith(
                                  color: kPrimaryColor,
                                  fontWeight: FontWeight.w600,
                                  fontSize: 13,
                                ),
                              ),
                              const Icon(Icons.chevron_right_rounded, size: 20, color: kPrimaryColor),
                            ],
                          ),
                        ),
                    const SizedBox(height: 15.0),
                    _myApplications.isEmpty
                        ? Container(
                            width: double.infinity,
                            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 24),
                            decoration: BoxDecoration(
                              color: kDarkWhite,
                              borderRadius: BorderRadius.circular(16),
                              border: Border.all(color: kBorderColorTextField),
                            ),
                            child: Column(
                              children: [
                                Icon(Icons.outgoing_mail, size: 44, color: kLightNeutralColor.withOpacity(0.85)),
                                const SizedBox(height: 12),
                                Text(
                                  'No applications yet',
                                  textAlign: TextAlign.center,
                                  style: kTextStyle.copyWith(
                                    color: kNeutralColor,
                                    fontWeight: FontWeight.w700,
                                    fontSize: 15,
                                  ),
                                ),
                                const SizedBox(height: 6),
                                Text(
                                  'Browse open jobs and send a clear offer to stand out.',
                                  textAlign: TextAlign.center,
                                  style: kTextStyle.copyWith(color: kLightNeutralColor, fontSize: 12.5, height: 1.35),
                                ),
                                const SizedBox(height: 16),
                                FilledButton(
                                  style: FilledButton.styleFrom(
                                    backgroundColor: kPrimaryColor,
                                    foregroundColor: Colors.white,
                                    padding: const EdgeInsets.symmetric(horizontal: 22, vertical: 12),
                                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
                                  ),
                                  onPressed: () => context.go('/seller/find-jobs'),
                                  child: Text('Browse jobs', style: kTextStyle.copyWith(fontWeight: FontWeight.w700)),
                                ),
                              ],
                            ),
                          )
                        : Column(
                            children: _myApplications.map((app) {
                              final jobPost = app['job_posts'] as Map<String, dynamic>?;
                              final status = (app['status'] as String?) ?? 'pending';
                              final (Color statusBg, Color statusFg, String statusLabel) = switch (status) {
                                'accepted' => (kPrimaryColor.withOpacity(0.1), kPrimaryColor, 'Accepted'),
                                'rejected' => (const Color(0xFFFFE5E3), const Color(0xFFFF3B30), 'Rejected'),
                                _          => (const Color(0xFFFFEFE0), const Color(0xFFFF7A00), 'Pending'),
                              };

                              return Padding(
                                padding: const EdgeInsets.only(bottom: 10.0),
                                child: Material(
                                  color: Colors.transparent,
                                  child: InkWell(
                                    borderRadius: BorderRadius.circular(12),
                                    onTap: () => context.push('/seller/applications'),
                                    child: Ink(
                                      padding: const EdgeInsets.all(12.0),
                                      decoration: BoxDecoration(
                                        color: kWhite,
                                        borderRadius: BorderRadius.circular(12.0),
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
                                              const SizedBox(width: 8),
                                              Container(
                                                padding: const EdgeInsets.symmetric(vertical: 3, horizontal: 8),
                                                decoration: BoxDecoration(
                                                  borderRadius: BorderRadius.circular(20),
                                                  color: statusBg,
                                                ),
                                                child: Text(
                                                  statusLabel,
                                                  style: kTextStyle.copyWith(color: statusFg, fontSize: 12),
                                                ),
                                              ),
                                            ],
                                          ),
                                          const SizedBox(height: 6),
                                          Text(
                                            '${JobPostsService.formatOfferAmountShort(app['price'], app['price_basis'])} • ${JobOfferDelivery.formatShort(app['delivery_time'], app['delivery_time_unit'])}',
                                            style: kTextStyle.copyWith(color: kSubTitleColor),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ),
                                ),
                              );
                            }).toList(),
                          ),
                    const SizedBox(height: 28),
                  ],
                ),
              ),
            ),
          ),
        ),
        ],
        ),
      ),
    );
  }

  Widget _buildQuickActions(BuildContext context) {
    final actions = <({String label, IconData icon, Color color, VoidCallback onTap})>[
      (
        label: 'Find Jobs',
        icon: Icons.work_outline_rounded,
        color: kSecondaryColor,
        onTap: () => context.go('/seller/find-jobs'),
      ),
      (
        label: 'Messages',
        icon: Icons.chat_bubble_outline_rounded,
        color: const Color(0xFF144BD6),
        onTap: () => context.go('/seller/chat'),
      ),
      (
        label: 'Contracts',
        icon: Icons.description_outlined,
        color: const Color(0xFF06AEF3),
        onTap: () => context.go('/seller/orders'),
      ),
      (
        label: 'Applications',
        icon: Icons.outgoing_mail,
        color: kPrimaryColor,
        onTap: () => context.push('/seller/applications'),
      ),
    ];

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: kBorderColorTextField),
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
    );
  }

  Widget _buildCard({required String title, required Widget dropdown, required Widget child}) {
    return Container(
      padding: const EdgeInsets.all(10.0),
      decoration: BoxDecoration(
        color: kWhite,
        borderRadius: BorderRadius.circular(16.0),
        border: Border.all(color: kBorderColorTextField),
        boxShadow: const [BoxShadow(color: kDarkWhite, blurRadius: 5.0, spreadRadius: 2.0, offset: Offset(0, 5))],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            children: [
              Text(title, style: kTextStyle.copyWith(color: kNeutralColor, fontWeight: FontWeight.bold)),
              const Spacer(),
              dropdown,
            ],
          ),
          const SizedBox(height: 15.0),
          child,
        ],
      ),
    );
  }
}

/// Skeleton layout while seller dashboard data loads.
class _SellerHomeLoading extends StatelessWidget {
  const _SellerHomeLoading();

  @override
  Widget build(BuildContext context) {
    final bar = Colors.white.withOpacity(0.22);
    final muted = kLightNeutralColor.withOpacity(0.35);

    return Column(
      children: [
        Container(
          width: double.infinity,
          padding: EdgeInsets.fromLTRB(
            16,
            6 + MediaQuery.viewPaddingOf(context).top,
            16,
            22,
          ),
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                Color(0xFF0F4AC9),
                Color(0xFF144BD6),
                Color(0xFF06AEF3),
              ],
            ),
            borderRadius: BorderRadius.vertical(bottom: Radius.circular(28)),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    height: 48,
                    width: 48,
                    decoration: BoxDecoration(shape: BoxShape.circle, color: bar),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Container(height: 10, width: 72, decoration: BoxDecoration(color: bar, borderRadius: BorderRadius.circular(5))),
                        const SizedBox(height: 8),
                        Container(height: 18, width: 160, decoration: BoxDecoration(color: bar, borderRadius: BorderRadius.circular(6))),
                        const SizedBox(height: 8),
                        Container(height: 10, width: double.infinity, decoration: BoxDecoration(color: bar, borderRadius: BorderRadius.circular(5))),
                        const SizedBox(height: 4),
                        Container(height: 10, width: 200, decoration: BoxDecoration(color: bar, borderRadius: BorderRadius.circular(5))),
                      ],
                    ),
                  ),
                  Container(
                    height: 40,
                    width: 40,
                    decoration: BoxDecoration(shape: BoxShape.circle, color: bar),
                  ),
                ],
              ),
            ],
          ),
        ),
        Expanded(
          child: Container(
            width: double.infinity,
            padding: const EdgeInsets.fromLTRB(15, 18, 15, 16),
            decoration: const BoxDecoration(
              color: kWhite,
              borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
            ),
            child: SingleChildScrollView(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    height: 72,
                    decoration: BoxDecoration(color: muted.withOpacity(0.5), borderRadius: BorderRadius.circular(18)),
                  ),
                  const SizedBox(height: 16),
                  Container(
                    height: 96,
                    decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(22), border: Border.all(color: kBorderColorTextField)),
                  ),
                  const SizedBox(height: 18),
                  Container(
                    height: 140,
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: kBorderColorTextField),
                    ),
                  ),
                  const SizedBox(height: 16),
                  Container(
                    height: 140,
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: kBorderColorTextField),
                    ),
                  ),
                  const SizedBox(height: 16),
                  Container(
                    height: 120,
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: kBorderColorTextField),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }
}

class ChartLegend extends StatelessWidget {
  const ChartLegend({
    Key? key,
    required this.iconColor,
    required this.title,
    required this.value,
  }) : super(key: key);

  final Color iconColor;
  final String title;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(Icons.circle, size: 16.0, color: iconColor),
        const SizedBox(width: 10.0),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(title, style: kTextStyle.copyWith(color: kSubTitleColor)),
            const SizedBox(height: 5.0),
            Text(value, style: kTextStyle.copyWith(color: kNeutralColor, fontWeight: FontWeight.bold)),
          ],
        ),
      ],
    );
  }
}
