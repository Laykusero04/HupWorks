import 'package:flutter/material.dart';
import 'package:freelancer/core/notifications/notification_scope.dart';
import 'package:freelancer/l10n/l10n.dart';
import 'package:freelancer/core/utils/job_offer_delivery.dart';
import 'package:freelancer/screen/widgets/constant.dart';
import 'package:freelancer/services/job_posts_service.dart';
import 'package:freelancer/services/seller_home_service.dart';
import 'package:freelancer/services/seller_orders_service.dart';
import 'package:go_router/go_router.dart';
import 'package:nb_utils/nb_utils.dart';

import '../../widgets/client_shell_app_bar.dart';
import '../../widgets/shell_tab_header.dart';
import '../notification/seller_notification.dart';

const _kSellerHomeMaxWidth = 720.0;

class SellerHomeScreen extends StatefulWidget {
  const SellerHomeScreen({Key? key}) : super(key: key);

  @override
  State<SellerHomeScreen> createState() => _SellerHomeScreenState();
}

class _SellerHomeScreenState extends State<SellerHomeScreen> {
  Map<String, dynamic> _overview = {};
  List<Map<String, dynamic>> _myApplications = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      _loadData();
    });
  }

  List<Widget> _homeAppBarActions() {
    final notifications = NotificationScope.of(context);
    return [
      ListenableBuilder(
        listenable: notifications,
        builder: (context, _) {
          final count = notifications.unreadCount;
          return IconButton(
            tooltip: context.l10n.notifications,
            onPressed: () async {
              await const SellerNotification().launch(context);
              if (mounted) await notifications.refreshUnreadCount();
            },
            icon: count > 0
                ? Badge(
                    label: Text(
                      count > 9 ? '9+' : '$count',
                      style: const TextStyle(fontSize: 10),
                    ),
                    child: const Icon(Icons.notifications_outlined),
                  )
                : const Icon(Icons.notifications_outlined),
          );
        },
      ),
    ];
  }

  Future<void> _loadData() async {
    try {
      final results = await Future.wait([
        SellerHomeService.getWorkOverview(),
        SellerOrdersService.getMyApplications(),
      ]);

      if (mounted) {
        final apps = results[1] as List<Map<String, dynamic>>;
        setState(() {
          _overview = results[0] as Map<String, dynamic>;
          _myApplications = apps.take(5).toList();
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(context.l10n.errorWithDetail('$e'))),
        );
      }
    }
  }

  int _ov(String key) => (_overview[key] as num?)?.toInt() ?? 0;

  double _ovDouble(String key) => (_overview[key] as num?)?.toDouble() ?? 0;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    return Scaffold(
      backgroundColor: kDarkWhite,
      appBar: ClientShellAppBar(
        title: l10n.home,
        persona: ShellPersona.seller,
        actions: _isLoading ? null : _homeAppBarActions(),
      ),
      body: _isLoading
          ? const _SellerHomeLoading()
          : RefreshIndicator(
              color: kSellerPrimary,
              onRefresh: _loadData,
              child: SingleChildScrollView(
                physics: const AlwaysScrollableScrollPhysics(
                    parent: BouncingScrollPhysics()),
                padding: const EdgeInsets.fromLTRB(15, 14, 15, 28),
                child: Align(
                  alignment: Alignment.topCenter,
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: _kSellerHomeMaxWidth),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
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
                                colors: kSellerShellGradient,
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
                                        l10n.findYourNextJob,
                                        style: kTextStyle.copyWith(
                                          color: Colors.white,
                                          fontWeight: FontWeight.w800,
                                          fontSize: 15,
                                        ),
                                      ),
                                      const SizedBox(height: 2),
                                      Text(
                                        l10n.findYourNextJobSubtitle,
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
                        if (_buildNeedsAttention(context) != null) ...[
                          const SizedBox(height: 12.0),
                          _buildNeedsAttention(context)!,
                        ],
                        const SizedBox(height: 20.0),

                        GestureDetector(
                          onTap: () => context.push('/seller/applications'),
                          child: Row(
                            children: [
                              Text(
                                l10n.myApplications,
                                style: kTextStyle.copyWith(color: kNeutralColor, fontWeight: FontWeight.bold),
                              ),
                              const Spacer(),
                              Text(
                                l10n.viewAll,
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
                                  l10n.noApplicationsYet,
                                  textAlign: TextAlign.center,
                                  style: kTextStyle.copyWith(
                                    color: kNeutralColor,
                                    fontWeight: FontWeight.w700,
                                    fontSize: 15,
                                  ),
                                ),
                                const SizedBox(height: 6),
                                Text(
                                  l10n.noApplicationsYetHint,
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
                                  child: Text(l10n.browseJobs, style: kTextStyle.copyWith(fontWeight: FontWeight.w700)),
                                ),
                              ],
                            ),
                          )
                            : Column(
                                children: _myApplications.map((app) {
                              final jobPost = app['job_posts'] as Map<String, dynamic>?;
                              final status = (app['status'] as String?) ?? 'pending';
                              final (Color statusBg, Color statusFg, String statusLabel) = switch (status) {
                                'accepted' => (StatusColors.successBg, StatusColors.success, l10n.statusAccepted),
                                'rejected' => (StatusColors.dangerBg, StatusColors.danger, l10n.statusRejected),
                                _          => (StatusColors.warningBg, StatusColors.warning, l10n.statusPending),
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
                                                  jobPost?['title'] ?? l10n.untitledJob,
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
    );
  }

  Widget _buildWorkOverviewCard(BuildContext context) {
    final l10n = context.l10n;
    final rating = _ovDouble('avg_rating');
    final reviews = _ov('review_count');
    final ratingLabel = reviews > 0 ? rating.toStringAsFixed(1) : '—';
    final ratingSubtitle = reviews > 0 ? l10n.reviewCount(reviews) : l10n.noReviewsYet;

    return _buildCard(
      title: l10n.yourWork,
      dropdown: Text(
        l10n.periodLive,
        style: kTextStyle.copyWith(color: kLightNeutralColor, fontSize: 12),
      ),
      child: Container(
        decoration: BoxDecoration(
          color: kDarkWhite,
          borderRadius: BorderRadius.circular(12),
        ),
        clipBehavior: Clip.antiAlias,
        child: Column(
          children: [
            IntrinsicHeight(
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Expanded(
                    child: _WorkStatPrimary(
                      value: '${_ov('active_contracts')}',
                      label: l10n.activeContracts,
                      color: kSecondaryColor,
                      onTap: () => context.go('/seller/orders'),
                    ),
                  ),
                  VerticalDivider(width: 1, thickness: 1, color: kBorderColorTextField),
                  Expanded(
                    child: _WorkStatPrimary(
                      value: '${_ov('pending_applications')}',
                      label: l10n.pendingApplications,
                      color: StatusColors.warning,
                      onTap: () => context.push('/seller/applications'),
                    ),
                  ),
                ],
              ),
            ),
            const Divider(height: 1, thickness: 1, color: kBorderColorTextField),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 4),
              child: Row(
                children: [
                  Expanded(
                    child: _WorkStatCompact(
                      value: '${_ov('completed_this_month')}',
                      label: l10n.completedThisMonth,
                      icon: Icons.check_circle_outline,
                      color: StatusColors.success,
                    ),
                  ),
                  Container(
                    width: 1,
                    height: 44,
                    color: kBorderColorTextField,
                  ),
                  Expanded(
                    child: _WorkStatCompact(
                      value: ratingLabel,
                      label: l10n.yourRating,
                      subtitle: ratingSubtitle,
                      icon: Icons.star_rounded,
                      color: ratingBarColor,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget? _buildNeedsAttention(BuildContext context) {
    final l10n = context.l10n;
    final delivered = _ov('delivered_awaiting_approval');
    final onsite = _ov('onsite_attendance_jobs');
    if (delivered <= 0 && onsite <= 0) return null;

    final attentionCount = delivered + onsite;

    return _buildCard(
      title: l10n.needsAttention,
      dropdown: Text(
        l10n.attentionItems(attentionCount),
        style: kTextStyle.copyWith(color: kLightNeutralColor, fontSize: 12),
      ),
      child: Column(
        children: [
          if (delivered > 0)
            _AttentionRow(
              icon: Icons.inbox_outlined,
              text: delivered == 1
                  ? l10n.attentionContractDeliveredOne
                  : l10n.attentionContractDeliveredMany(delivered),
              onTap: () => context.go('/seller/orders'),
            ),
          if (delivered > 0 && onsite > 0) const SizedBox(height: 8),
          if (onsite > 0)
            _AttentionRow(
              icon: Icons.qr_code_scanner,
              text: onsite == 1
                  ? l10n.attentionOnsiteOne
                  : l10n.attentionOnsiteMany(onsite),
              onTap: () => context.push('/seller/attendance'),
            ),
        ],
      ),
    );
  }

  Widget _buildQuickActions(BuildContext context) {
    final l10n = context.l10n;
    final shortcuts = [
      (
        title: l10n.shortcutApplications,
        subtitle: l10n.shortcutApplicationsSub,
        icon: Icons.outgoing_mail,
        color: kPrimaryColor,
        onTap: () => context.push('/seller/applications'),
      ),
      (
        title: l10n.shortcutAttendance,
        subtitle: l10n.shortcutAttendanceSub,
        icon: Icons.qr_code_scanner_rounded,
        color: StatusColors.success,
        onTap: () => context.push('/seller/attendance'),
      ),
    ];

    return _buildCard(
      title: l10n.shortcuts,
      dropdown: const SizedBox.shrink(),
      child: IntrinsicHeight(
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            for (var i = 0; i < shortcuts.length; i++) ...[
              if (i > 0) const SizedBox(width: 10),
              Expanded(
                child: _ShortcutTile(
                  title: shortcuts[i].title,
                  subtitle: shortcuts[i].subtitle,
                  icon: shortcuts[i].icon,
                  color: shortcuts[i].color,
                  onTap: shortcuts[i].onTap,
                ),
              ),
            ],
          ],
        ),
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

  static BoxDecoration _card(Color c) => BoxDecoration(
        color: c,
        borderRadius: BorderRadius.circular(20),
      );

  @override
  Widget build(BuildContext context) {
    final muted = kLightNeutralColor.withOpacity(0.35);

    return Align(
      alignment: Alignment.topCenter,
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: _kSellerHomeMaxWidth),
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(15, 14, 15, 24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                height: 72,
                decoration: _card(muted),
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
              const SizedBox(height: 18),
              Container(
                height: 200,
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
            ],
          ),
        ),
      ),
    );
  }
}

class _ShortcutTile extends StatelessWidget {
  final String title;
  final String subtitle;
  final IconData icon;
  final Color color;
  final VoidCallback onTap;

  const _ShortcutTile({
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: color.withValues(alpha: 0.06),
      borderRadius: BorderRadius.circular(12),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 14),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: color.withValues(alpha: 0.18)),
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
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
              const SizedBox(height: 10),
              Text(
                title,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                textAlign: TextAlign.center,
                style: kTextStyle.copyWith(
                  color: kNeutralColor,
                  fontWeight: FontWeight.w700,
                  fontSize: 13,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                subtitle,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                textAlign: TextAlign.center,
                style: kTextStyle.copyWith(
                  color: kSubTitleColor,
                  fontSize: 11,
                  height: 1.25,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _WorkStatPrimary extends StatelessWidget {
  final String value;
  final String label;
  final Color color;
  final VoidCallback? onTap;

  const _WorkStatPrimary({
    required this.value,
    required this.label,
    required this.color,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 16),
          child: Column(
            children: [
              Text(
                value,
                style: kTextStyle.copyWith(
                  color: color,
                  fontWeight: FontWeight.w800,
                  fontSize: 32,
                  height: 1,
                ),
              ),
              const SizedBox(height: 6),
              Text(
                label,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                textAlign: TextAlign.center,
                style: kTextStyle.copyWith(
                  color: kSubTitleColor,
                  fontSize: 12,
                  height: 1.2,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _WorkStatCompact extends StatelessWidget {
  final String value;
  final String label;
  final IconData icon;
  final Color color;
  final String? subtitle;
  final VoidCallback? onTap;

  const _WorkStatCompact({
    required this.value,
    required this.label,
    required this.icon,
    required this.color,
    this.subtitle,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(8),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 12),
          child: Row(
            children: [
              Container(
                height: 36,
                width: 36,
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(icon, size: 18, color: color),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      value,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: kTextStyle.copyWith(
                        color: kNeutralColor,
                        fontWeight: FontWeight.w800,
                        fontSize: 16,
                        height: 1.1,
                      ),
                    ),
                    Text(
                      label,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: kTextStyle.copyWith(
                        color: kSubTitleColor,
                        fontSize: 11,
                        height: 1.2,
                      ),
                    ),
                    if (subtitle != null && subtitle!.isNotEmpty)
                      Text(
                        subtitle!,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: kTextStyle.copyWith(
                          color: kLightNeutralColor,
                          fontSize: 10,
                          height: 1.1,
                        ),
                      ),
                  ],
                ),
              ),
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
