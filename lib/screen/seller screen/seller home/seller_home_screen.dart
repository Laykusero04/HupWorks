import 'package:flutter/material.dart';
import 'package:freelancer/core/widgets/empty_state_widget.dart';
import 'package:freelancer/core/widgets/rubik_refresh_indicator.dart';
import 'package:freelancer/core/guide/guide_host.dart';
import 'package:freelancer/core/guide/guide_step.dart';
import 'package:freelancer/l10n/l10n.dart';
import 'package:freelancer/l10n/l10n_labels.dart';
import 'package:freelancer/core/utils/job_offer_delivery.dart';
import 'package:freelancer/screen/seller%20screen/buyer%20request/buyer_request_details.dart';
import 'package:freelancer/screen/widgets/constant.dart';
import 'package:freelancer/services/seller_home_service.dart';
import 'package:freelancer/services/seller_orders_service.dart';
import 'package:freelancer/router/route_names.dart';
import 'package:go_router/go_router.dart';
import 'package:nb_utils/nb_utils.dart';
import 'package:showcaseview/showcaseview.dart';

import '../../widgets/client_shell_app_bar.dart';
import '../../widgets/shell_tab_header.dart';

const _kSellerHomeMaxWidth = 720.0;

class SellerHomeScreen extends StatefulWidget {
  const SellerHomeScreen({Key? key}) : super(key: key);

  @override
  State<SellerHomeScreen> createState() => _SellerHomeScreenState();
}

class _SellerHomeScreenState extends State<SellerHomeScreen>
    with GuideHost<SellerHomeScreen> {
  Map<String, dynamic> _overview = {};
  List<Map<String, dynamic>> _myApplications = [];
  bool _isLoading = true;
  bool _loadFailed = false;
  bool _workOverviewOpen = false;

  // Guide targets (owned by this State, stable across rebuilds).
  final GlobalKey _guideMenuKey = GlobalKey();
  final GlobalKey _guideBellKey = GlobalKey();
  final GlobalKey _guideBannerKey = GlobalKey();
  final GlobalKey _guideShortcutsKey = GlobalKey();
  final GlobalKey _guideWorkKey = GlobalKey();

  @override
  String get guideScreenId => 'seller_home';
  @override
  String get guideRole => 'seller';
  @override
  int get guideVersion => 1;
  @override
  bool get guideLeadsChain => true;
  @override
  bool get guideDataReady => !_isLoading;
  @override
  String get guideSkipLabel => context.l10n.guideSkip;
  @override
  String get guideNextLabel => context.l10n.guideNext;
  @override
  String get guideDoneLabel => context.l10n.guideDone;

  // Order follows on-screen position: menu, bell, banner, shortcuts, work.
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
          title: l10n.guideSellerHomeBellTitle,
          description: l10n.guideSellerHomeBellDesc),
      GuideStep(
          key: _guideBannerKey,
          title: l10n.guideSellerHomeBannerTitle,
          description: l10n.guideSellerHomeBannerDesc),
      GuideStep(
          key: _guideShortcutsKey,
          title: l10n.guideSellerHomeShortcutsTitle,
          description: l10n.guideSellerHomeShortcutsDesc),
      GuideStep(
          key: _guideWorkKey,
          title: l10n.guideSellerHomeWorkTitle,
          description: l10n.guideSellerHomeWorkDesc),
    ];
  }

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
        SellerHomeService.getWorkOverview(),
        SellerOrdersService.getMyApplications(),
      ]);

      if (mounted) {
        final apps = results[1] as List<Map<String, dynamic>>;
        setState(() {
          _overview = results[0] as Map<String, dynamic>;
          _myApplications = apps.take(5).toList();
          _isLoading = false;
          _loadFailed = false;
        });
        scheduleGuide();
      }
    } catch (e) {
      if (mounted) {
        final hadOverview = _overview.isNotEmpty;
        setState(() {
          _isLoading = false;
          _loadFailed = !hadOverview;
        });
        if (hadOverview) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(context.l10n.errorWithDetail('$e'))),
          );
        }
        scheduleGuide();
      }
    }
  }

  int _ov(String key) => (_overview[key] as num?)?.toInt() ?? 0;

  double _ovDouble(String key) => (_overview[key] as num?)?.toDouble() ?? 0;

  String _formatHours(BuildContext context) {
    final minutes = _ovDouble('hours_worked_minutes');
    final hours = minutes / 60.0;
    final label = hours == hours.roundToDouble()
        ? hours.toInt().toString()
        : hours.toStringAsFixed(1);
    return context.l10n.hoursWorkedFormat(label);
  }

  String _formatMoney(String key) {
    final value = _ovDouble(key);
    if (value == value.roundToDouble()) {
      return '$currencySign${value.toInt()}';
    }
    return '$currencySign${value.toStringAsFixed(2)}';
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    return Scaffold(
      backgroundColor: kDarkWhite,
      appBar: ClientShellAppBar(
        title: l10n.home,
        persona: ShellPersona.seller,
        menuShowcaseKey: _guideMenuKey,
        menuShowcaseScope: guideScope,
        menuShowcaseTitle: l10n.guideShellMenuTitle,
        menuShowcaseDescription: l10n.guideShellMenuDesc,
        bellShowcaseKey: _guideBellKey,
        bellShowcaseTitle: l10n.guideSellerHomeBellTitle,
        bellShowcaseDescription: l10n.guideSellerHomeBellDesc,
      ),
      body: _isLoading
          ? const _SellerHomeLoading()
          : _loadFailed
              ? EmptyStateWidget(
                  message: l10n.somethingWentWrong,
                  actionLabel: l10n.retry,
                  onAction: () {
                    setState(() => _isLoading = true);
                    _loadData();
                  },
                )
              : RubikRefreshIndicator(
                  onRefresh: _loadData,
                  child: SingleChildScrollView(
                    physics: const AlwaysScrollableScrollPhysics(
                        parent: BouncingScrollPhysics()),
                    padding: const EdgeInsets.fromLTRB(15, 14, 15, 28),
                    child: Align(
                      alignment: Alignment.topCenter,
                      child: ConstrainedBox(
                        constraints: const BoxConstraints(
                            maxWidth: _kSellerHomeMaxWidth),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Showcase(
                              key: _guideBannerKey,
                              scope: guideScope,
                              title: l10n.guideSellerHomeBannerTitle,
                              description: l10n.guideSellerHomeBannerDesc,
                              targetBorderRadius: BorderRadius.circular(18),
                              child: GestureDetector(
                                onTap: () =>
                                    context.go(AppRoutes.sellerFindJobs),
                                child: Container(
                                  width: double.infinity,
                                  padding: const EdgeInsets.symmetric(
                                      horizontal: 14, vertical: 14),
                                  decoration: BoxDecoration(
                                    borderRadius: BorderRadius.circular(18),
                                    gradient: const LinearGradient(
                                      begin: Alignment.centerLeft,
                                      end: Alignment.centerRight,
                                      colors: kSellerShellGradient,
                                    ),
                                    boxShadow: [
                                      BoxShadow(
                                        color:
                                            kSecondaryColor.withOpacity(0.28),
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
                                          borderRadius:
                                              BorderRadius.circular(12),
                                        ),
                                        child: const Icon(
                                            Icons.rocket_launch_rounded,
                                            color: Colors.white,
                                            size: 22),
                                      ),
                                      const SizedBox(width: 12),
                                      Expanded(
                                        child: Column(
                                          crossAxisAlignment:
                                              CrossAxisAlignment.start,
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
                                                color: Colors.white
                                                    .withOpacity(0.9),
                                                fontSize: 11.5,
                                                height: 1.25,
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                      Icon(Icons.chevron_right_rounded,
                                          color: Colors.white.withOpacity(0.95),
                                          size: 26),
                                    ],
                                  ),
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
                              onTap: () async {
                                await context
                                    .push(AppRoutes.sellerApplications);
                                if (mounted) _loadData();
                              },
                              child: Row(
                                children: [
                                  Text(
                                    l10n.myApplications,
                                    style: kTextStyle.copyWith(
                                        color: kNeutralColor,
                                        fontWeight: FontWeight.bold),
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
                                  const Icon(Icons.chevron_right_rounded,
                                      size: 20, color: kPrimaryColor),
                                ],
                              ),
                            ),
                            const SizedBox(height: 15.0),
                            _myApplications.isEmpty
                                ? Container(
                                    width: double.infinity,
                                    padding: const EdgeInsets.symmetric(
                                        horizontal: 16, vertical: 24),
                                    decoration: BoxDecoration(
                                      color: kDarkWhite,
                                      borderRadius: BorderRadius.circular(16),
                                      border: Border.all(
                                          color: kBorderColorTextField),
                                    ),
                                    child: Column(
                                      children: [
                                        Icon(Icons.outgoing_mail,
                                            size: 44,
                                            color: kLightNeutralColor
                                                .withOpacity(0.85)),
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
                                          style: kTextStyle.copyWith(
                                              color: kLightNeutralColor,
                                              fontSize: 12.5,
                                              height: 1.35),
                                        ),
                                        const SizedBox(height: 16),
                                        FilledButton(
                                          style: FilledButton.styleFrom(
                                            backgroundColor: kPrimaryColor,
                                            foregroundColor: Colors.white,
                                            padding: const EdgeInsets.symmetric(
                                                horizontal: 22, vertical: 12),
                                            shape: RoundedRectangleBorder(
                                                borderRadius:
                                                    BorderRadius.circular(24)),
                                          ),
                                          onPressed: () => context
                                              .go(AppRoutes.sellerFindJobs),
                                          child: Text(l10n.browseJobs,
                                              style: kTextStyle.copyWith(
                                                  fontWeight: FontWeight.w700)),
                                        ),
                                      ],
                                    ),
                                  )
                                : Column(
                                    children: _myApplications.map((app) {
                                      final jobPost = app['job_posts']
                                          as Map<String, dynamic>?;
                                      final status =
                                          (app['status'] as String?) ??
                                              'pending';
                                      final (statusFg, statusBg) =
                                          StatusColors.application(status);
                                      final statusLabel =
                                          L10nLabels.applicationStatus(
                                              l10n, status);

                                      return Padding(
                                        padding:
                                            const EdgeInsets.only(bottom: 10.0),
                                        child: Material(
                                          color: Colors.transparent,
                                          child: InkWell(
                                            borderRadius:
                                                BorderRadius.circular(12),
                                            onTap: () async {
                                              final id =
                                                  jobPost?['id'] as String?;
                                              if (id == null) return;
                                              await BuyerRequestDetails(
                                                      jobPostId: id)
                                                  .launch(context);
                                              if (mounted) _loadData();
                                            },
                                            child: Ink(
                                              padding:
                                                  const EdgeInsets.all(12.0),
                                              decoration: BoxDecoration(
                                                color: kWhite,
                                                borderRadius:
                                                    BorderRadius.circular(12.0),
                                                border: Border.all(
                                                    color:
                                                        kBorderColorTextField),
                                              ),
                                              child: Column(
                                                crossAxisAlignment:
                                                    CrossAxisAlignment.start,
                                                children: [
                                                  Row(
                                                    children: [
                                                      Expanded(
                                                        child: Text(
                                                          jobPost?['title'] ??
                                                              l10n.untitledJob,
                                                          maxLines: 1,
                                                          overflow: TextOverflow
                                                              .ellipsis,
                                                          style: kTextStyle.copyWith(
                                                              color:
                                                                  kNeutralColor,
                                                              fontWeight:
                                                                  FontWeight
                                                                      .bold),
                                                        ),
                                                      ),
                                                      const SizedBox(width: 8),
                                                      Container(
                                                        padding:
                                                            const EdgeInsets
                                                                .symmetric(
                                                                vertical: 3,
                                                                horizontal: 8),
                                                        decoration:
                                                            BoxDecoration(
                                                          borderRadius:
                                                              BorderRadius
                                                                  .circular(20),
                                                          color: statusBg,
                                                        ),
                                                        child: Text(
                                                          statusLabel,
                                                          style: kTextStyle
                                                              .copyWith(
                                                                  color:
                                                                      statusFg,
                                                                  fontSize: 12),
                                                        ),
                                                      ),
                                                    ],
                                                  ),
                                                  const SizedBox(height: 6),
                                                  Text(
                                                    '${L10nLabels.offerAmountShort(l10n, app['price'], app['price_basis'])} • ${JobOfferDelivery.formatShort(app['delivery_time'], app['delivery_time_unit'])}',
                                                    style: kTextStyle.copyWith(
                                                        color: kSubTitleColor),
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

    return _buildCard(
      guideKey: _guideWorkKey,
      guideTitle: l10n.guideSellerHomeWorkTitle,
      guideDescription: l10n.guideSellerHomeWorkDesc,
      guideAutoScroll: true, // card is usually below the fold
      title: l10n.yourWork,
      dropdown: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            l10n.periodLive,
            style: kTextStyle.copyWith(color: kLightNeutralColor, fontSize: 12),
          ),
          Icon(
            _workOverviewOpen ? Icons.expand_less : Icons.expand_more,
            size: 20,
            color: kLightNeutralColor,
          ),
        ],
      ),
      onHeaderTap: () => setState(() => _workOverviewOpen = !_workOverviewOpen),
      showChild: _workOverviewOpen,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
            decoration: BoxDecoration(
              color: kDarkWhite,
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: kBorderColorTextField),
            ),
            child: Text(
              l10n.workOverviewDisclaimer,
              style: kTextStyle.copyWith(
                color: kSubTitleColor,
                fontSize: 11.5,
                height: 1.35,
              ),
            ),
          ),
          const SizedBox(height: 12),
          Container(
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
                          value: _formatHours(context),
                          label: l10n.hoursWorked,
                          color: kSecondaryColor,
                          onTap: () async {
                            await context.push(AppRoutes.sellerAttendance);
                            if (mounted) _loadData();
                          },
                        ),
                      ),
                      VerticalDivider(
                          width: 1, thickness: 1, color: kBorderColorTextField),
                      Expanded(
                        child: _WorkStatPrimary(
                          value: _formatMoney('agreed_contract_value'),
                          label: l10n.agreedContractValue,
                          color: StatusColors.success,
                          onTap: () => context.go('/seller/orders'),
                        ),
                      ),
                    ],
                  ),
                ),
                const Divider(
                    height: 1, thickness: 1, color: kBorderColorTextField),
                Padding(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 4, vertical: 4),
                  child: Row(
                    children: [
                      Expanded(
                        child: _WorkStatCompact(
                          value: _formatMoney('payment_received_value'),
                          label: l10n.paymentReceivedValue,
                          icon: Icons.fact_check_outlined,
                          color: StatusColors.success,
                          onTap: () => context.go('/seller/orders'),
                        ),
                      ),
                      Container(
                        width: 1,
                        height: 44,
                        color: kBorderColorTextField,
                      ),
                      Expanded(
                        child: _WorkStatCompact(
                          value: _formatMoney('outstanding_value'),
                          label: l10n.outstandingValue,
                          icon: Icons.pending_actions_outlined,
                          color: StatusColors.warning,
                          onTap: () => context.go('/seller/orders'),
                        ),
                      ),
                    ],
                  ),
                ),
                const Divider(
                    height: 1, thickness: 1, color: kBorderColorTextField),
                Padding(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 4, vertical: 4),
                  child: Row(
                    children: [
                      Expanded(
                        child: _WorkStatCompact(
                          value: '${_ov('jobs_completed')}',
                          label: l10n.jobsCompleted,
                          icon: Icons.check_circle_outline,
                          color: StatusColors.success,
                          onTap: () =>
                              context.go('/seller/orders?status=completed'),
                        ),
                      ),
                      Container(
                        width: 1,
                        height: 44,
                        color: kBorderColorTextField,
                      ),
                      Expanded(
                        child: _WorkStatCompact(
                          value: '${_ov('active_contracts')}',
                          label: l10n.activeContracts,
                          icon: Icons.work_outline_rounded,
                          color: kSecondaryColor,
                          onTap: () =>
                              context.go('/seller/orders?status=active'),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
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
              onTap: () => context.go('/seller/orders?status=delivered'),
            ),
          if (delivered > 0 && onsite > 0) const SizedBox(height: 8),
          if (onsite > 0)
            _AttentionRow(
              icon: Icons.qr_code_scanner,
              text: onsite == 1
                  ? l10n.attentionOnsiteOne
                  : l10n.attentionOnsiteMany(onsite),
              onTap: () async {
                await context.push(AppRoutes.sellerAttendance);
                if (mounted) _loadData();
              },
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
        onTap: () async {
          await context.push(AppRoutes.sellerApplications);
          if (mounted) _loadData();
        },
      ),
      (
        title: l10n.shortcutAttendance,
        subtitle: l10n.shortcutAttendanceSub,
        icon: Icons.qr_code_scanner_rounded,
        color: StatusColors.success,
        onTap: () async {
          await context.push(AppRoutes.sellerAttendance);
          if (mounted) _loadData();
        },
      ),
    ];

    return _buildCard(
      guideKey: _guideShortcutsKey,
      guideTitle: l10n.guideSellerHomeShortcutsTitle,
      guideDescription: l10n.guideSellerHomeShortcutsDesc,
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

  Widget _buildCard({
    required String title,
    required Widget dropdown,
    required Widget child,
    VoidCallback? onHeaderTap,
    bool showChild = true,
    GlobalKey? guideKey,
    String? guideTitle,
    String? guideDescription,
    bool guideAutoScroll = false,
  }) {
    final card = _buildCardBody(
      title: title,
      dropdown: dropdown,
      child: child,
      onHeaderTap: onHeaderTap,
      showChild: showChild,
    );
    if (guideKey == null) return card;
    return Showcase(
      key: guideKey,
      scope: guideScope,
      title: guideTitle,
      description: guideDescription,
      enableAutoScroll: guideAutoScroll,
      targetBorderRadius: BorderRadius.circular(16),
      child: card,
    );
  }

  Widget _buildCardBody({
    required String title,
    required Widget dropdown,
    required Widget child,
    VoidCallback? onHeaderTap,
    bool showChild = true,
  }) {
    final header = Row(
      children: [
        Text(title,
            style: kTextStyle.copyWith(
                color: kNeutralColor, fontWeight: FontWeight.bold)),
        const Spacer(),
        dropdown,
      ],
    );
    return Container(
      padding: const EdgeInsets.all(10.0),
      decoration: BoxDecoration(
        color: kWhite,
        borderRadius: BorderRadius.circular(16.0),
        border: Border.all(color: kBorderColorTextField),
        boxShadow: const [
          BoxShadow(
              color: kDarkWhite,
              blurRadius: 5.0,
              spreadRadius: 2.0,
              offset: Offset(0, 5))
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          if (onHeaderTap == null)
            header
          else
            InkWell(
              onTap: onHeaderTap,
              borderRadius: BorderRadius.circular(8),
              child: Semantics(
                button: true,
                expanded: showChild,
                child: header,
              ),
            ),
          if (showChild) ...[
            const SizedBox(height: 15.0),
            child,
          ],
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
              FittedBox(
                fit: BoxFit.scaleDown,
                child: Text(
                  value,
                  maxLines: 1,
                  style: kTextStyle.copyWith(
                    color: color,
                    fontWeight: FontWeight.w800,
                    fontSize: 28,
                    height: 1,
                  ),
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
  final VoidCallback? onTap;

  const _WorkStatCompact({
    required this.value,
    required this.label,
    required this.icon,
    required this.color,
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
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: kTextStyle.copyWith(
                        color: kSubTitleColor,
                        fontSize: 11,
                        height: 1.2,
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
              const Icon(Icons.chevron_right,
                  color: Color(0xFFF59E0B), size: 20),
            ],
          ),
        ),
      ),
    );
  }
}
