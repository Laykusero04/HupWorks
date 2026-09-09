import 'dart:async';

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

class _SellerApplicationsState extends State<SellerApplications> {
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
    if (showLoader && mounted) setState(() => _isLoading = true);
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
    final (fg, bg) = StatusColors.application(status);
    return (
      bg: bg,
      fg: fg,
      label: L10nLabels.applicationStatus(context.l10n, status),
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
          SnackBar(content: Text(l10n.couldNotOpenChatWithDetail('$e'))),
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
        ),
        const SizedBox(height: 12),
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
        ),
      ],
    );
  }

  Widget _buildEmptyState() {
    final l10n = context.l10n;
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

  Widget _buildCard(Map<String, dynamic> app) {
    final l10n = context.l10n;
    final jobPost = app['job_posts'] as Map<String, dynamic>?;
    final statusRaw = (app['status'] as String?)?.toLowerCase() ?? 'pending';
    final status = _statusStyle(statusRaw);
    final offerId = app['id'] as String?;
    final withdrawing = offerId != null && _withdrawBusyIds.contains(offerId);

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
                    IconButton(
                      visualDensity: VisualDensity.compact,
                      padding: EdgeInsets.zero,
                      constraints: const BoxConstraints(
                        minWidth: 36,
                        minHeight: 36,
                      ),
                      tooltip: l10n.messageClientTooltip,
                      icon: const Icon(
                        Icons.chat_bubble_outline,
                        size: 20,
                        color: kPrimaryColor,
                      ),
                      onPressed: () => _openChatWithClient(app),
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
                if (statusRaw == 'pending') ...[
                  const SizedBox(height: 10),
                  Align(
                    alignment: Alignment.centerRight,
                    child: OutlinedButton(
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
                    ),
                  ),
                ],
                if (statusRaw == 'accepted' &&
                    AttendanceService.isOnsiteJob(jobPost)) ...[
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
                        border: Border.all(color: kBorderColorTextField),
                      ),
                      child: Text(
                        l10n.openAttendance,
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
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final primary = Theme.of(context).colorScheme.primary;
    final visible = _visible;

    return Scaffold(
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
              : Column(
                  children: [
                    const SizedBox(height: 15),
                    _buildSearchAndTabs(primary),
                    const SizedBox(height: 8),
                    Expanded(
                      child: visible.isEmpty
                          ? RefreshIndicator(
                              color: kPrimaryColor,
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
                          : RefreshIndicator(
                              color: kPrimaryColor,
                              onRefresh: () => _load(showLoader: false),
                              child: ListView.builder(
                                physics: const AlwaysScrollableScrollPhysics(
                                  parent: BouncingScrollPhysics(),
                                ),
                                padding: const EdgeInsets.only(top: 8, bottom: 15),
                                itemCount: visible.length,
                                itemBuilder: (_, i) => _buildCard(visible[i]),
                              ),
                            ),
                    ),
                  ],
                ),
        ),
      ),
    );
  }
}
