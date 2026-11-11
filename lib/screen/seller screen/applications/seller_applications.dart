import 'dart:async';
import 'package:freelancer/core/chat/chat_contact_policy.dart';
import 'package:freelancer/core/guide/guide_anchor.dart';
import 'package:freelancer/core/guide/guide_host.dart';
import 'package:freelancer/core/guide/guide_info_button.dart';
import 'package:freelancer/core/guide/guide_step.dart';
import 'package:freelancer/core/widgets/rubik_refresh_indicator.dart';
import 'package:freelancer/core/widgets/loading_widget.dart';

import 'package:flutter/material.dart';
import 'package:freelancer/core/utils/app_date_format.dart';
import 'package:freelancer/core/widgets/empty_state_widget.dart';
import 'package:freelancer/l10n/l10n.dart';
import 'package:freelancer/l10n/l10n_labels.dart';
import 'package:freelancer/services/chat_service.dart';
import 'package:freelancer/services/attendance_service.dart';
import 'package:freelancer/services/hire_onboarding_service.dart';
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

class _SellerApplicationsState extends State<SellerApplications>
    with GuideHost<SellerApplications> {
  // Guide targets (long-lived, one widget each). Card-level targets sit on
  // the FIRST matching card only (see _guideIdx, recomputed every build).
  final GlobalKey _guideSearchKey = GlobalKey();
  final GlobalKey _guideTabsKey = GlobalKey();
  final GlobalKey _guideCardKey = GlobalKey();
  final GlobalKey _guideWithdrawKey = GlobalKey();
  final GlobalKey _guideMessageKey = GlobalKey();
  final GlobalKey _guideAttendanceKey = GlobalKey();
  final GlobalKey _guideInstructionsKey = GlobalKey();

  /// Index (in the visible list) of the card that owns each target.
  Map<String, int> _guideIdx = const {};
  bool _reloading = false; // any reload in flight (also pull-to-refresh)

  @override
  String get guideScreenId => 'seller_applications';
  @override
  String get guideRole => 'seller';
  @override
  int get guideVersion => 1;

  /// False during every reload (spinner, pull-to-refresh, return from job
  /// details), so a running guide is torn down and restarted.
  @override
  bool get guideDataReady => !_isLoading && !_reloading;
  @override
  String get guideSkipLabel => context.l10n.guideSkip;
  @override
  String get guideNextLabel => context.l10n.guideNext;
  @override
  String get guideDoneLabel => context.l10n.guideDone;

  @override
  List<GuideStep> buildGuideSteps(BuildContext context) {
    final l10n = context.l10n;
    return [
      GuideStep(
          key: _guideSearchKey,
          title: l10n.guideSellerAppsSearchTitle,
          description: l10n.guideSellerAppsSearchDesc),
      GuideStep(
          key: _guideTabsKey,
          title: l10n.guideSellerAppsTabsTitle,
          description: l10n.guideSellerAppsTabsDesc),
      GuideStep(
          key: _guideCardKey,
          title: l10n.guideSellerAppsCardTitle,
          description: l10n.guideSellerAppsCardDesc),
      GuideStep(
          key: _guideWithdrawKey,
          title: l10n.guideSellerAppsWithdrawTitle,
          description: l10n.guideSellerAppsWithdrawDesc,
          enableAutoScroll: true),
    ];
  }

  @override
  List<GuideSection> buildGuideExtraSections(BuildContext context) {
    final l10n = context.l10n;
    return [
      GuideSection(
        id: 'hired',
        title: l10n.guideSellerAppsSectionHired,
        steps: [
          GuideStep(
              key: _guideMessageKey,
              title: l10n.guideSellerAppsMessageTitle,
              description: l10n.guideSellerAppsMessageDesc,
              enableAutoScroll: true),
          GuideStep(
              key: _guideAttendanceKey,
              title: l10n.guideSellerAppsAttendanceTitle,
              description: l10n.guideSellerAppsAttendanceDesc,
              enableAutoScroll: true),
          GuideStep(
              key: _guideInstructionsKey,
              title: l10n.guideSellerAppsInstructionsTitle,
              description: l10n.guideSellerAppsInstructionsDesc,
              enableAutoScroll: true),
        ],
      ),
    ];
  }

  GuideAnchor? _a(bool on, GlobalKey key, String title, String desc) => on
      ? GuideAnchor(key: key, scope: guideScope, title: title, description: desc)
      : null;

  Map<String, int> _computeGuideIdx(List<Map<String, dynamic>> visible) {
    final m = <String, int>{};
    for (var i = 0; i < visible.length; i++) {
      final app = visible[i];
      final st = (app['status'] as String?)?.toLowerCase() ?? 'pending';
      m.putIfAbsent('card', () => i);
      if (st == 'pending') m.putIfAbsent('withdraw', () => i);
      if (st == 'accepted') {
        m.putIfAbsent('message', () => i);
        if (AttendanceService.isOnsiteJob(
            app['job_posts'] as Map<String, dynamic>?)) {
          m.putIfAbsent('attendance', () => i);
        }
      }
      if (app['instructions_pending'] == true) {
        m.putIfAbsent('instructions', () => i);
      }
    }
    return m;
  }
  static const _statusTabs = [
    'all',
    'pending',
    'accepted',
    'rejected',
    'withdrawn',
  ];

  final _searchController = TextEditingController();
  Timer? _searchDebounce;

  List<Map<String, dynamic>> _applications = [];
  final Set<String> _withdrawBusyIds = {};
  bool _isLoading = true;
  bool _loadFailed = false;
  String _selectedStatus = 'all';
  String _searchQuery = '';

  @override
  void initState() {
    super.initState();
    _load();
  }

  @override
  void dispose() {
    _searchDebounce?.cancel();
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _load({bool showLoader = true}) async {
    if (mounted) {
      setState(() {
        _reloading = true;
        if (showLoader) _isLoading = true;
      });
    }
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
          _reloading = false;
          _loadFailed = false;
        });
        scheduleGuide();
      }
    } catch (e) {
      if (mounted) {
        final keepList = _applications.isNotEmpty;
        setState(() {
          _isLoading = false;
          _reloading = false;
          _loadFailed = !keepList;
        });
        scheduleGuide();
        if (keepList) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(context.l10n.errorLoadingApplications('$e'))),
          );
        }
      }
    }
  }

  List<Map<String, dynamic>> get _visible {
    final q = _searchQuery.trim().toLowerCase();
    return _applications.where((app) {
      final status = (app['status'] as String?)?.toLowerCase() ?? 'pending';
      if (_selectedStatus != 'all' && status != _selectedStatus) return false;
      if (q.isEmpty) return true;
      final jobPost = app['job_posts'] as Map<String, dynamic>?;
      final title = (jobPost?['title'] as String?)?.toLowerCase() ?? '';
      return title.contains(q);
    }).toList();
  }

  void _onSearchChanged(String value) {
    _searchDebounce?.cancel();
    _searchDebounce = Timer(const Duration(milliseconds: 250), () {
      if (!mounted) return;
      setState(() => _searchQuery = value);
    });
  }

  void _clearFilters() {
    _searchDebounce?.cancel();
    _searchController.clear();
    setState(() {
      _selectedStatus = 'all';
      _searchQuery = '';
    });
  }

  String _formatDate(String? s) {
    return AppDateFormat.tryDMmmY(s, AppDateFormat.localeOf(context)) ?? '';
  }

  String _jobTypeLabel(String? t) => L10nLabels.jobType(context.l10n, t);

  ({Color bg, Color fg, String label}) _statusStyle(String? status) {
    final label = L10nLabels.applicationStatus(context.l10n, status);
    if ((status ?? 'pending').toLowerCase() == 'pending') {
      final primary = Theme.of(context).colorScheme.primary;
      return (
        bg: primary.withValues(alpha: 0.15),
        fg: primary,
        label: label,
      );
    }
    final (fg, bg) = StatusColors.application(status);
    return (
      bg: bg,
      fg: fg,
      label: label,
    );
  }

  Future<void> _openChatWithClient(Map<String, dynamic> app) async {
    final l10n = context.l10n;
    final jobPost = app['job_posts'] as Map<String, dynamic>?;
    final client = jobPost?['client'] as Map<String, dynamic>?;
    final clientId = jobPost?['client_id'] as String?;
    if (clientId == null) return;
    try {
      final conversation = await ChatService.getOrCreateConversation(clientId);
      if (!mounted) return;
      ChatInbox(
        conversationId: conversation['id'] as String,
        otherUserName: client?['name'] ?? l10n.roleClient,
        otherUserImage: client?['profile_image_url'] ?? '',
        otherUserId: clientId,
      ).launch(context);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(messageForChatStartFailure(l10n, e))),
        );
      }
    }
  }

  Future<void> _withdraw(Map<String, dynamic> app) async {
    final l10n = context.l10n;
    final offerId = app['id'] as String?;
    if (offerId == null || _withdrawBusyIds.contains(offerId)) return;

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(l10n.withdrawApplicationTitle),
        content: Text(l10n.withdrawApplicationConfirmBody),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: Text(l10n.cancel),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: Text(l10n.withdrawApplication),
          ),
        ],
      ),
    );
    if (confirmed != true || !mounted) return;

    setState(() => _withdrawBusyIds.add(offerId));
    try {
      await SellerOrdersService.withdrawOffer(offerId);
      if (!mounted) return;
      setState(() {
        app['status'] = 'withdrawn';
        _withdrawBusyIds.remove(offerId);
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(l10n.applicationWithdrawn)),
      );
    } catch (e) {
      if (!mounted) return;
      setState(() => _withdrawBusyIds.remove(offerId));
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(l10n.errorWithDetail('$e'))),
      );
    }
  }

  Widget _buildSearchAndTabs(Color primary) {
    final l10n = context.l10n;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        GuideAnchor.wrap(
          _a(true, _guideSearchKey, l10n.guideSellerAppsSearchTitle,
              l10n.guideSellerAppsSearchDesc),
          TextField(
          controller: _searchController,
          onChanged: _onSearchChanged,
          style: kTextStyle.copyWith(color: kNeutralColor, fontSize: 14),
          decoration: InputDecoration(
            hintText: l10n.searchApplicationsHint,
            hintStyle: kTextStyle.copyWith(color: kLightNeutralColor, fontSize: 14),
            prefixIcon: const Icon(Icons.search, color: kLightNeutralColor),
            suffixIcon: _searchQuery.isNotEmpty
                ? IconButton(
                    icon: const Icon(Icons.close, color: kLightNeutralColor, size: 20),
                    onPressed: () {
                      _searchDebounce?.cancel();
                      _searchController.clear();
                      setState(() => _searchQuery = '');
                    },
                  )
                : null,
            filled: true,
            fillColor: kDarkWhite,
            contentPadding: const EdgeInsets.symmetric(vertical: 12),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(color: kBorderColorTextField),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(color: kBorderColorTextField),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(color: primary),
            ),
          ),
        )),
        const SizedBox(height: 12),
        GuideAnchor.wrap(
          _a(true, _guideTabsKey, l10n.guideSellerAppsTabsTitle,
              l10n.guideSellerAppsTabsDesc),
          SizedBox(
          height: 40,
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            itemCount: _statusTabs.length,
            separatorBuilder: (_, __) => const SizedBox(width: 8),
            itemBuilder: (_, i) {
              final tab = _statusTabs[i];
              final selected = _selectedStatus == tab;
              return GestureDetector(
                onTap: () => setState(() => _selectedStatus = tab),
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 9),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(30),
                    color: selected ? primary : kDarkWhite,
                    border: Border.all(
                      color: selected ? primary : kBorderColorTextField,
                    ),
                  ),
                  child: Text(
                    L10nLabels.applicationFilterTabLabel(l10n, tab),
                    style: kTextStyle.copyWith(
                      color: selected ? kWhite : kNeutralColor,
                      fontWeight: selected ? FontWeight.w600 : FontWeight.normal,
                      fontSize: 13,
                    ),
                  ),
                ),
              );
            },
          ),
        )),
      ],
    );
  }

  Widget _buildEmptyState() {
    final l10n = context.l10n;
    if (_loadFailed && _applications.isEmpty) {
      return EmptyStateWidget(
        message: l10n.somethingWentWrong,
        icon: Icons.outgoing_mail,
        actionLabel: l10n.retry,
        onAction: () => _load(),
      );
    }
    if (_applications.isEmpty) {
      return EmptyStateWidget(
        message: l10n.noApplicationsYet,
        hint: l10n.noApplicationsYetHint,
        icon: Icons.outgoing_mail,
        actionLabel: l10n.browseJobs,
        onAction: () => context.go('/seller/find-jobs'),
      );
    }

    return EmptyStateWidget(
      message: l10n.noFilteredApplications,
      hint: l10n.noFilteredApplicationsHint,
      icon: Icons.search_off_outlined,
      actionLabel: l10n.clearFilters,
      onAction: _clearFilters,
    );
  }

  Widget _buildCard(Map<String, dynamic> app, int index) {
    final l10n = context.l10n;
    final primary = Theme.of(context).colorScheme.primary;
    final jobPost = app['job_posts'] as Map<String, dynamic>?;
    final statusRaw = (app['status'] as String?)?.toLowerCase() ?? 'pending';
    final status = _statusStyle(statusRaw);
    final offerId = app['id'] as String?;
    final withdrawing = offerId != null && _withdrawBusyIds.contains(offerId);
    bool own(String k) => _guideIdx[k] == index;

    return Padding(
      padding: const EdgeInsets.only(bottom: 10.0),
      child: Material(
        color: kWhite,
        borderRadius: BorderRadius.circular(10.0),
        child: InkWell(
          borderRadius: BorderRadius.circular(10.0),
          onTap: () async {
            final id = jobPost?['id'] as String?;
            if (id == null) return;
            await BuyerRequestDetails(jobPostId: id).launch(context);
            if (mounted) _load(showLoader: false);
          },
          child: GuideAnchor.wrap(
            _a(own('card'), _guideCardKey, l10n.guideSellerAppsCardTitle,
                l10n.guideSellerAppsCardDesc),
            Container(
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
                        jobPost?['title'] ?? l10n.untitledJob,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: kTextStyle.copyWith(
                          color: kNeutralColor,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                    const SizedBox(width: 8.0),
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
                    if (statusRaw == 'pending' || statusRaw == 'accepted')
                      GuideAnchor.wrap(
                        _a(own('message'), _guideMessageKey,
                            l10n.guideSellerAppsMessageTitle,
                            l10n.guideSellerAppsMessageDesc),
                        IconButton(
                        visualDensity: VisualDensity.compact,
                        padding: EdgeInsets.zero,
                        constraints: const BoxConstraints(
                          minWidth: 36,
                          minHeight: 36,
                        ),
                        tooltip: l10n.messageClientTooltip,
                        icon: Icon(
                          Icons.chat_bubble_outline,
                          size: 20,
                          color: primary,
                        ),
                        onPressed: () => _openChatWithClient(app),
                      )),
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
                        color: primary,
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
                if (statusRaw == 'pending') ...[
                  const SizedBox(height: 10),
                  Align(
                    alignment: Alignment.centerRight,
                    child: GuideAnchor.wrap(
                      _a(own('withdraw'), _guideWithdrawKey,
                          l10n.guideSellerAppsWithdrawTitle,
                          l10n.guideSellerAppsWithdrawDesc),
                      OutlinedButton(
                      onPressed: withdrawing ? null : () => _withdraw(app),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: StatusColors.danger,
                        side: BorderSide(
                          color: StatusColors.danger.withValues(alpha: 0.5),
                        ),
                        visualDensity: VisualDensity.compact,
                      ),
                      child: withdrawing
                          ? const SizedBox(
                              width: 16,
                              height: 16,
                              child: CircularProgressIndicator(strokeWidth: 2),
                            )
                          : Text(l10n.withdrawApplication),
                    )),
                  ),
                ],
                if (statusRaw == 'accepted' &&
                    AttendanceService.isOnsiteJob(jobPost)) ...[
                  const SizedBox(height: 8),
                  GuideAnchor.wrap(
                    _a(own('attendance'), _guideAttendanceKey,
                        l10n.guideSellerAppsAttendanceTitle,
                        l10n.guideSellerAppsAttendanceDesc),
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
                        border: Border.all(color: kBorderColorTextField),
                      ),
                      child: Text(
                        l10n.openAttendance,
                        style: kTextStyle.copyWith(
                          color: primary,
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  )),
                ],
                if (app['instructions_pending'] == true) ...[
                  const SizedBox(height: 8.0),
                  GuideAnchor.wrap(
                    _a(own('instructions'), _guideInstructionsKey,
                        l10n.guideSellerAppsInstructionsTitle,
                        l10n.guideSellerAppsInstructionsDesc),
                    InkWell(
                    onTap: () async {
                      final orderId = app['order_id'] as String?;
                      if (orderId == null) return;
                      context.push('/seller/orders/$orderId');
                      if (mounted) _load(showLoader: false);
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
                        l10n.instructionsReadyTap,
                        style: kTextStyle.copyWith(
                          color: const Color(0xFF2E7D32),
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  )),
                ],
              ],
            ),
          )),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final primary = Theme.of(context).colorScheme.primary;
    final visible = _visible;
    _guideIdx = _computeGuideIdx(visible);

    return guideBackScope(Scaffold(
      backgroundColor: kDarkWhite,
      appBar: AppBar(
        backgroundColor: kDarkWhite,
        elevation: 0,
        iconTheme: const IconThemeData(color: kNeutralColor),
        title: Text(
          l10n.myApplications,
          style: kTextStyle.copyWith(
            color: kNeutralColor,
            fontWeight: FontWeight.bold,
          ),
        ),
        centerTitle: true,
        actions: [GuideInfoButton(host: this)],
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
              ? const LoadingWidget()
              : Column(
                  children: [
                    const SizedBox(height: 15),
                    _buildSearchAndTabs(primary),
                    const SizedBox(height: 8),
                    Expanded(
                      child: visible.isEmpty
                          ? RubikRefreshIndicator(
                              onRefresh: () => _load(showLoader: false),
                              child: ListView(
                                physics: const AlwaysScrollableScrollPhysics(
                                  parent: BouncingScrollPhysics(),
                                ),
                                children: [
                                  SizedBox(
                                    height: MediaQuery.sizeOf(context).height * 0.15,
                                  ),
                                  _buildEmptyState(),
                                ],
                              ),
                            )
                          : RubikRefreshIndicator(
                              onRefresh: () => _load(showLoader: false),
                              child: ListView.builder(
                                physics: const AlwaysScrollableScrollPhysics(
                                  parent: BouncingScrollPhysics(),
                                ),
                                padding: const EdgeInsets.only(top: 8, bottom: 15),
                                itemCount: visible.length,
                                itemBuilder: (_, i) => _buildCard(visible[i], i),
                              ),
                            ),
                    ),
                  ],
                ),
        ),
      ),
    ));
  }
}
