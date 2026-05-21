import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:freelancer/data/repositories/notification_repository.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:freelancer/core/utils/job_offer_delivery.dart';
import 'package:flutter_iconly/flutter_iconly.dart';
import 'package:freelancer/screen/widgets/constant.dart';
import 'package:freelancer/services/job_posts_service.dart';
import 'package:freelancer/services/seller_home_service.dart';
import 'package:freelancer/services/seller_orders_service.dart';
import 'package:go_router/go_router.dart';
import 'package:nb_utils/nb_utils.dart';

import 'package:freelancer/router/app_router.dart';
import '../notification/seller_notification.dart';
import '../transaction/seller_transaction.dart';

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
  Map<String, dynamic> _overview = {};
  List<Map<String, dynamic>> _myApplications = [];
  int _unreadNotificationCount = 0;
  RealtimeChannel? _notificationChannel;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      _loadData();
      _loadUnreadNotificationCount();
      _subscribeToNotifications();
    });
  }

  @override
  void dispose() {
    context.read<NotificationRepository>().unsubscribe(_notificationChannel);
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

  Widget _notificationCountBadge() {
    if (_unreadNotificationCount <= 0) return const SizedBox.shrink();
    final label = _unreadNotificationCount > 9 ? '9+' : '$_unreadNotificationCount';
    return Positioned(
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
          label,
          textAlign: TextAlign.center,
          style: kTextStyle.copyWith(
            color: Colors.white,
            fontSize: 10,
            fontWeight: FontWeight.w800,
          ),
        ),
      ),
    );
  }

  Future<void> _loadData() async {
    try {
      final results = await Future.wait([
        SellerHomeService.getSellerProfile(),
        SellerHomeService.getWorkOverview(),
        SellerOrdersService.getMyApplications(),
      ]);

      if (mounted) {
        final apps = results[2] as List<Map<String, dynamic>>;
        setState(() {
          _profile = results[0] as Map<String, dynamic>?;
          _overview = results[1] as Map<String, dynamic>;
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

  int _ov(String key) => (_overview[key] as num?)?.toInt() ?? 0;

  double _ovDouble(String key) => (_overview[key] as num?)?.toDouble() ?? 0;

  String _sellerTagline() {
    final active = _ov('active_contracts');
    final pending = _ov('pending_applications');
    final open = _ov('open_jobs_count');
    if (active > 0) {
      return '$active active contract${active == 1 ? '' : 's'} — stay on top of delivery and attendance.';
    }
    if (pending > 0) {
      return '$pending application${pending == 1 ? '' : 's'} waiting for client decisions.';
    }
    if (open > 0) {
      return '$open open job${open == 1 ? '' : 's'} on HupWorks — find your next contract.';
    }
    return 'Apply to jobs, win contracts, and track work in one place.';
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
          colors: kSellerShellGradient,
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
                onTap: () => sellerShellScaffoldKey.currentState?.openDrawer(),
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
                onTap: () => sellerShellScaffoldKey.currentState?.openDrawer(),
                child: Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.18),
                    shape: BoxShape.circle,
                    border: Border.all(color: Colors.white.withOpacity(0.35)),
                  ),
                  child: const Icon(Icons.menu_rounded, color: Colors.white, size: 22),
                ),
              ),
              const SizedBox(width: 8),
              GestureDetector(
                onTap: () async {
                  await const SellerNotification().launch(context);
                  if (mounted) _loadUnreadNotificationCount();
                },
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
                    _notificationCountBadge(),
                  ],
                ),
              ),
            ],
          ),
          if (_ov('pending_applications') > 0) ...[
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
                        _ov('pending_applications') == 1
                            ? '1 application awaiting client reply'
                            : '${_ov('pending_applications')} applications awaiting client reply',
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
        backgroundColor: Theme.of(context).scaffoldBackgroundColor,
        body: AnnotatedRegion<SystemUiOverlayStyle>(
          value: _sellerHubSystemUi,
          child: const _SellerHomeLoading(),
        ),
      );
    }

    final name = _profile?['name'] ?? 'Seller';
    final profileImageUrl = _profile?['profile_image_url'] as String?;
    final tagline = _sellerTagline();
    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
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

                    const SizedBox(height: 16.0),
                    _buildWorkOverviewCard(context),
                    const SizedBox(height: 12.0),
                    _buildWalletCard(context),
                    if (_buildNeedsAttention(context) != null) ...[
                      const SizedBox(height: 12.0),
                      _buildNeedsAttention(context)!,
                    ],
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

  Widget _buildWorkOverviewCard(BuildContext context) {
    final rating = _ovDouble('avg_rating');
    final reviews = _ov('review_count');
    final ratingLabel = reviews > 0 ? rating.toStringAsFixed(1) : '—';

    return _buildCard(
      title: 'Your work',
      dropdown: Text(
        'Live',
        style: kTextStyle.copyWith(color: kLightNeutralColor, fontSize: 12),
      ),
      child: Column(
        children: [
          Row(
            children: [
              Expanded(
                child: _DashboardMetricCell(
                  label: 'Active contracts',
                  value: '${_ov('active_contracts')}',
                  icon: Icons.description_outlined,
                  color: kSecondaryColor,
                  onTap: () => context.go('/seller/orders'),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: _DashboardMetricCell(
                  label: 'Pending applications',
                  value: '${_ov('pending_applications')}',
                  icon: Icons.outgoing_mail,
                  color: kPrimaryColor,
                  onTap: () => context.push('/seller/applications'),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              Expanded(
                child: _DashboardMetricCell(
                  label: 'Completed this month',
                  value: '${_ov('completed_this_month')}',
                  icon: Icons.check_circle_outline,
                  color: const Color(0xFF2E7D32),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: _DashboardMetricCell(
                  label: 'Your rating',
                  value: ratingLabel,
                  icon: Icons.star_outline_rounded,
                  color: const Color(0xFFFFB300),
                  subtitle: reviews > 0 ? '$reviews reviews' : 'No reviews yet',
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          GestureDetector(
            onTap: () => context.go('/seller/find-jobs'),
            child: Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
              decoration: BoxDecoration(
                color: kDarkWhite,
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: kBorderColorTextField),
              ),
              child: Row(
                children: [
                  Icon(Icons.work_outline, size: 20, color: kSecondaryColor),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      '${_ov('open_jobs_count')} open jobs to browse',
                      style: kTextStyle.copyWith(
                        color: kNeutralColor,
                        fontWeight: FontWeight.w600,
                        fontSize: 13,
                      ),
                    ),
                  ),
                  const Icon(Icons.chevron_right, color: kSecondaryColor, size: 22),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildWalletCard(BuildContext context) {
    final balance = _ovDouble('balance');
    final earned = _ovDouble('earned_this_month');

    return _buildCard(
      title: 'Wallet',
      dropdown: Text(
        'This month',
        style: kTextStyle.copyWith(color: kLightNeutralColor, fontSize: 12),
      ),
      child: IntrinsicHeight(
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Expanded(
              child: _DashboardMetricCell(
                label: 'Available balance',
                value: '$currencySign${balance.toStringAsFixed(2)}',
                icon: Icons.account_balance_wallet_outlined,
                color: kPrimaryColor,
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: _DashboardMetricCell(
                label: 'Earned this month',
                value: '$currencySign${earned.toStringAsFixed(2)}',
                icon: Icons.payments_outlined,
                color: const Color(0xFF06AEF3),
                onTap: () => const SellerTransaction().launch(context),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget? _buildNeedsAttention(BuildContext context) {
    final delivered = _ov('delivered_awaiting_approval');
    final onsite = _ov('onsite_attendance_jobs');
    if (delivered <= 0 && onsite <= 0) return null;

    return _buildCard(
      title: 'Needs attention',
      dropdown: const SizedBox.shrink(),
      child: Column(
        children: [
          if (delivered > 0)
            _AttentionRow(
              icon: Icons.inbox_outlined,
              text: delivered == 1
                  ? '1 contract delivered — waiting for client approval'
                  : '$delivered contracts delivered — waiting for client approval',
              onTap: () => context.go('/seller/orders'),
            ),
          if (delivered > 0 && onsite > 0) const SizedBox(height: 8),
          if (onsite > 0)
            _AttentionRow(
              icon: Icons.qr_code_scanner,
              text: onsite == 1
                  ? '1 on-site contract — clock in via Attendance'
                  : '$onsite on-site contracts — use Attendance',
              onTap: () => context.push('/seller/attendance'),
            ),
        ],
      ),
    );
  }

  Widget _buildQuickActions(BuildContext context) {
    final shortcuts = [
      (
        title: 'Find jobs',
        subtitle: 'Browse open posts and send offers',
        icon: Icons.work_outline_rounded,
        color: kSecondaryColor,
        onTap: () => context.go('/seller/find-jobs'),
      ),
      (
        title: 'Messages',
        subtitle: 'Chat with clients',
        icon: Icons.chat_bubble_outline_rounded,
        color: const Color(0xFF144BD6),
        onTap: () => context.go('/seller/chat'),
      ),
      (
        title: 'Contracts',
        subtitle: 'Active work and delivery',
        icon: Icons.description_outlined,
        color: const Color(0xFF06AEF3),
        onTap: () => context.go('/seller/orders'),
      ),
      (
        title: 'Applications',
        subtitle: 'Track offers you submitted',
        icon: Icons.outgoing_mail,
        color: kPrimaryColor,
        onTap: () => context.push('/seller/applications'),
      ),
      (
        title: 'Attendance',
        subtitle: 'Clock in on site with QR',
        icon: Icons.qr_code_scanner_rounded,
        color: const Color(0xFF2E7D32),
        onTap: () => context.push('/seller/attendance'),
      ),
    ];

    return _buildCard(
      title: 'Shortcuts',
      dropdown: const SizedBox.shrink(),
      child: Column(
        children: [
          for (var i = 0; i < shortcuts.length; i++) ...[
            if (i > 0)
              const Divider(height: 1, thickness: 1, color: kBorderColorTextField),
            _ShortcutRow(
              title: shortcuts[i].title,
              subtitle: shortcuts[i].subtitle,
              icon: shortcuts[i].icon,
              color: shortcuts[i].color,
              onTap: shortcuts[i].onTap,
            ),
          ],
        ],
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
                    height: 220,
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: kBorderColorTextField),
                    ),
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
                    height: 168,
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: kBorderColorTextField),
                    ),
                  ),
                  const SizedBox(height: 16),
                  Container(
                    height: 88,
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

class _ShortcutRow extends StatelessWidget {
  final String title;
  final String subtitle;
  final IconData icon;
  final Color color;
  final VoidCallback onTap;

  const _ShortcutRow({
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(10),
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 4),
          child: Row(
            children: [
              Container(
                height: 44,
                width: 44,
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(icon, color: color, size: 22),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: kTextStyle.copyWith(
                        color: kNeutralColor,
                        fontWeight: FontWeight.w700,
                        fontSize: 14,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      subtitle,
                      style: kTextStyle.copyWith(
                        color: kSubTitleColor,
                        fontSize: 12,
                        height: 1.25,
                      ),
                    ),
                  ],
                ),
              ),
              Icon(Icons.chevron_right_rounded, color: kLightNeutralColor, size: 22),
            ],
          ),
        ),
      ),
    );
  }
}

class _DashboardMetricCell extends StatelessWidget {
  final String label;
  final String value;
  final IconData icon;
  final Color color;
  final String? subtitle;
  final VoidCallback? onTap;

  const _DashboardMetricCell({
    required this.label,
    required this.value,
    required this.icon,
    required this.color,
    this.subtitle,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: color.withValues(alpha: 0.06),
      borderRadius: BorderRadius.circular(10),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(10),
        child: Container(
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(10),
            border: Border.all(color: color.withValues(alpha: 0.2)),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Icon(icon, size: 18, color: color),
              const SizedBox(height: 6),
              Text(
                value,
                style: kTextStyle.copyWith(
                  color: kNeutralColor,
                  fontWeight: FontWeight.w800,
                  fontSize: 18,
                ),
              ),
              Text(
                label,
                style: kTextStyle.copyWith(color: kSubTitleColor, fontSize: 11),
              ),
              if (subtitle != null) ...[
                const SizedBox(height: 2),
                Text(
                  subtitle!,
                  style: kTextStyle.copyWith(color: kLightNeutralColor, fontSize: 10),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

class _AttentionRow extends StatelessWidget {
  final IconData icon;
  final String text;
  final VoidCallback onTap;

  const _AttentionRow({
    required this.icon,
    required this.text,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: const Color(0xFFFFF8E1),
      borderRadius: BorderRadius.circular(10),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(10),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
          child: Row(
            children: [
              Icon(icon, color: const Color(0xFFF59E0B), size: 20),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  text,
                  style: kTextStyle.copyWith(
                    color: kNeutralColor,
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
              const Icon(Icons.chevron_right, color: Color(0xFFF59E0B), size: 20),
            ],
          ),
        ),
      ),
    );
  }
}
