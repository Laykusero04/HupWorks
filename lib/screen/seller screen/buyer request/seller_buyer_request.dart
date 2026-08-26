import 'package:flutter/material.dart';
import 'package:freelancer/l10n/l10n.dart';
import 'package:freelancer/core/utils/app_logger.dart';
import 'package:freelancer/services/favourite_service.dart';
import 'package:freelancer/services/job_posts_service.dart';
import 'package:freelancer/services/seller_orders_service.dart';
import 'package:freelancer/services/skill_service.dart';
import 'package:freelancer/screen/seller%20screen/job%20alerts/seller_job_alert_editor_screen.dart';
import 'package:freelancer/screen/seller%20screen/job%20alerts/seller_job_alerts_screen.dart';
import 'package:nb_utils/nb_utils.dart';

import '../../widgets/client_shell_app_bar.dart';
import '../../widgets/constant.dart';
import '../../widgets/shell_tab_header.dart';
import '../../widgets/skill_picker_field.dart';
import 'buyer_request_details.dart';

class SellerBuyerRequest extends StatefulWidget {
  const SellerBuyerRequest({Key? key}) : super(key: key);

  @override
  State<SellerBuyerRequest> createState() => _SellerBuyerRequestState();
}

class _SellerBuyerRequestState extends State<SellerBuyerRequest> {
  final _searchController = TextEditingController();

  List<Map<String, dynamic>> _requests = [];
  List<Map<String, dynamic>> _skillCatalog = [];
  final Set<String> _savedJobIds = {};
  final Set<String> _saveBusyIds = {};
  bool _isLoading = true;
  String _titleQuery = '';
  String? _jobTypeFilter;
  String? _skillFilter;

  static const _employmentTypeOptions = <Map<String, String?>>[
    {'value': null, 'label': 'All'},
    {'value': 'gig', 'label': 'Gig'},
    {'value': 'full_time', 'label': 'Full-time'},
    {'value': 'part_time', 'label': 'Part-time'},
  ];

  @override
  void initState() {
    super.initState();
    _loadRequests();
    _loadSkillCatalog();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _loadSkillCatalog() async {
    try {
      final skills = await SkillService.listForPicker();
      if (mounted) setState(() => _skillCatalog = skills);
    } catch (e, st) {
      AppLogger.error('SellerBuyerRequest.loadSkillCatalog', e, st);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(context.l10n.couldNotLoadSkillsFilter)),
        );
      }
    }
  }

  Future<void> _loadRequests() async {
    try {
      final results = await Future.wait([
        SellerOrdersService.getBuyerRequests(),
        FavouriteService.getFavouritedJobPostIds(),
      ]);
      if (mounted) {
        setState(() {
          _requests = results[0] as List<Map<String, dynamic>>;
          _savedJobIds
            ..clear()
            ..addAll(results[1] as Set<String>);
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

  Future<void> _toggleSaveJob(String jobPostId) async {
    if (_saveBusyIds.contains(jobPostId)) return;
    setState(() => _saveBusyIds.add(jobPostId));
    try {
      final saved = await FavouriteService.toggleFavourite(jobPostId);
      if (!mounted) return;
      setState(() {
        _saveBusyIds.remove(jobPostId);
        if (saved) {
          _savedJobIds.add(jobPostId);
        } else {
          _savedJobIds.remove(jobPostId);
        }
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            saved ? context.l10n.addedToFavourites : context.l10n.removedFromFavourites,
          ),
        ),
      );
    } catch (e) {
      if (!mounted) return;
      setState(() => _saveBusyIds.remove(jobPostId));
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(context.l10n.errorWithDetail('$e'))),
      );
    }
  }

  bool get _hasSecondaryFilters =>
      _jobTypeFilter != null ||
      (_skillFilter != null && _skillFilter!.trim().isNotEmpty);

  int get _secondaryFilterCount {
    var n = 0;
    if (_skillFilter != null && _skillFilter!.trim().isNotEmpty) n++;
    if (_jobTypeFilter != null) n++;
    return n;
  }

  bool get _hasActiveFilters => _titleQuery.trim().isNotEmpty || _hasSecondaryFilters;

  List<Map<String, dynamic>> get _visibleRequests {
    var list = _requests;

    final titleQ = _titleQuery.trim().toLowerCase();
    if (titleQ.isNotEmpty) {
      list = list.where((r) {
        final title = (r['title'] as String? ?? '').toLowerCase();
        return title.contains(titleQ);
      }).toList();
    }

    if (_jobTypeFilter != null) {
      list = list.where((r) => r['job_type'] == _jobTypeFilter).toList();
    }

    final skillQ = _skillFilter?.trim().toLowerCase() ?? '';
    if (skillQ.isNotEmpty) {
      list = list.where((r) {
        final title = (r['title'] as String? ?? '').toLowerCase();
        final desc = (r['description'] as String? ?? '').toLowerCase();
        final cat =
            ((r['categories'] as Map<String, dynamic>?)?['name'] as String? ?? '')
                .toLowerCase();
        return title.contains(skillQ) ||
            desc.contains(skillQ) ||
            cat.contains(skillQ);
      }).toList();
    }

    return list;
  }

  static String _jobTypeLabel(String? type) {
    switch (type) {
      case 'full_time':
        return 'Full-time';
      case 'part_time':
        return 'Part-time';
      case 'gig':
      default:
        return 'Gig';
    }
  }

  String _formatDate(String? s) {
    if (s == null) return '';
    final d = DateTime.tryParse(s);
    if (d == null) return '';
    const m = [
      'Jan',
      'Feb',
      'Mar',
      'Apr',
      'May',
      'Jun',
      'Jul',
      'Aug',
      'Sep',
      'Oct',
      'Nov',
      'Dec'
    ];
    return '${d.day} ${m[d.month - 1]} ${d.year}';
  }

  void _clearSecondaryFilters() {
    setState(() {
      _jobTypeFilter = null;
      _skillFilter = null;
    });
  }

  Future<void> _openFilterSheet() async {
    var tempJobType = _jobTypeFilter;
    var tempSkill = _skillFilter;

    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) {
        final primary = Theme.of(ctx).colorScheme.primary;
        return StatefulBuilder(
          builder: (context, setSheetState) {
            final skillSelected =
                tempSkill != null && tempSkill!.trim().isNotEmpty;

            return Padding(
              padding: EdgeInsets.only(
                bottom: MediaQuery.viewInsetsOf(context).bottom,
              ),
              child: SafeArea(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(20, 12, 20, 16),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Center(
                        child: Container(
                          width: 36,
                          height: 4,
                          decoration: BoxDecoration(
                            color: kBorderColorTextField,
                            borderRadius: BorderRadius.circular(2),
                          ),
                        ),
                      ),
                      const SizedBox(height: 16),
                      Text(
                        'Filter jobs',
                        style: kTextStyle.copyWith(
                          color: kNeutralColor,
                          fontWeight: FontWeight.bold,
                          fontSize: 17,
                        ),
                      ),
                      const SizedBox(height: 20),
                      Text(
                        'Skill',
                        style: kTextStyle.copyWith(
                          color: kLightNeutralColor,
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(height: 8),
                      InkWell(
                        onTap: () async {
                          await showSkillPickerSheet(
                            context: context,
                            skills: _skillCatalog,
                            title: 'Filter by skill',
                            allowCustomSkill: true,
                            onSelected: (name) {
                              setSheetState(() => tempSkill = name);
                            },
                          );
                        },
                        borderRadius: BorderRadius.circular(12),
                        child: Container(
                          width: double.infinity,
                          padding: const EdgeInsets.symmetric(
                            horizontal: 14,
                            vertical: 14,
                          ),
                          decoration: BoxDecoration(
                            color: skillSelected
                                ? primary.withValues(alpha: 0.06)
                                : kDarkWhite,
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(
                              color: skillSelected
                                  ? primary.withValues(alpha: 0.4)
                                  : kBorderColorTextField,
                            ),
                          ),
                          child: Row(
                            children: [
                              Icon(
                                Icons.construction_outlined,
                                size: 20,
                                color: skillSelected ? primary : kLightNeutralColor,
                              ),
                              const SizedBox(width: 10),
                              Expanded(
                                child: Text(
                                  skillSelected ? tempSkill! : 'Any skill',
                                  style: kTextStyle.copyWith(
                                    color: skillSelected ? kNeutralColor : kLightNeutralColor,
                                    fontWeight: skillSelected
                                        ? FontWeight.w600
                                        : FontWeight.normal,
                                  ),
                                ),
                              ),
                              if (skillSelected)
                                GestureDetector(
                                  onTap: () => setSheetState(() => tempSkill = null),
                                  child: Icon(
                                    Icons.close,
                                    size: 18,
                                    color: primary,
                                  ),
                                )
                              else
                                Icon(
                                  Icons.chevron_right,
                                  color: kLightNeutralColor.withValues(alpha: 0.8),
                                ),
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(height: 20),
                      Text(
                        'Employment type',
                        style: kTextStyle.copyWith(
                          color: kLightNeutralColor,
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Wrap(
                        spacing: 8,
                        runSpacing: 8,
                        children: _employmentTypeOptions.map((opt) {
                          final selected = tempJobType == opt['value'];
                          return ChoiceChip(
                            label: Text(opt['label']!),
                            selected: selected,
                            onSelected: (_) {
                              setSheetState(() => tempJobType = opt['value']);
                            },
                            selectedColor: primary,
                            backgroundColor: kDarkWhite,
                            labelStyle: kTextStyle.copyWith(
                              color: selected ? kWhite : kNeutralColor,
                            ),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(20),
                              side: BorderSide(
                                color: selected ? primary : kBorderColorTextField,
                              ),
                            ),
                          );
                        }).toList(),
                      ),
                      const SizedBox(height: 24),
                      if (tempJobType != null ||
                          (tempSkill != null && tempSkill!.trim().isNotEmpty)) ...[
                        const SizedBox(height: 8),
                        Align(
                          alignment: Alignment.centerLeft,
                          child: TextButton(
                            onPressed: () {
                              Navigator.pop(ctx);
                              SellerJobAlertEditorScreen(
                                initialSkillName: tempSkill,
                                initialJobType: tempJobType,
                              ).launch(context);
                            },
                            child: Text(context.l10n.jobAlertSaveFromFilter),
                          ),
                        ),
                      ],
                      const SizedBox(height: 12),
                      Row(
                        children: [
                          Expanded(
                            child: OutlinedButton(
                              onPressed: () {
                                setSheetState(() {
                                  tempJobType = null;
                                  tempSkill = null;
                                });
                              },
                              style: OutlinedButton.styleFrom(
                                foregroundColor: kNeutralColor,
                                side: const BorderSide(color: kBorderColorTextField),
                                minimumSize: const Size(0, 46),
                              ),
                              child: Text(context.l10n.filterClear),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: FilledButton(
                              onPressed: () {
                                setState(() {
                                  _jobTypeFilter = tempJobType;
                                  _skillFilter = tempSkill;
                                });
                                Navigator.pop(ctx);
                              },
                              style: FilledButton.styleFrom(
                                backgroundColor: primary,
                                minimumSize: const Size(0, 46),
                              ),
                              child: Text(context.l10n.filterApply),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            );
          },
        );
      },
    );
  }

  Widget _buildSearchRow(Color primary) {
    return Row(
      children: [
        Expanded(
          child: TextField(
            controller: _searchController,
            onChanged: (q) => setState(() => _titleQuery = q),
            style: kTextStyle.copyWith(color: kNeutralColor, fontSize: 14),
            decoration: InputDecoration(
              hintText: 'Search job title...',
              hintStyle:
                  kTextStyle.copyWith(color: kLightNeutralColor, fontSize: 14),
              prefixIcon: const Icon(Icons.search, color: kLightNeutralColor),
              suffixIcon: _titleQuery.isNotEmpty
                  ? IconButton(
                      icon: const Icon(
                        Icons.close,
                        color: kLightNeutralColor,
                        size: 20,
                      ),
                      onPressed: () {
                        _searchController.clear();
                        setState(() => _titleQuery = '');
                      },
                    )
                  : null,
              filled: true,
              fillColor: kWhite,
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
        ),
        const SizedBox(width: 10),
        Material(
          color: _hasSecondaryFilters
              ? primary.withValues(alpha: 0.1)
              : kDarkWhite,
          borderRadius: BorderRadius.circular(12),
          child: InkWell(
            onTap: _openFilterSheet,
            borderRadius: BorderRadius.circular(12),
            child: Container(
              width: 48,
              height: 48,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: _hasSecondaryFilters
                      ? primary.withValues(alpha: 0.45)
                      : kBorderColorTextField,
                ),
              ),
              child: Stack(
                alignment: Alignment.center,
                children: [
                  Icon(
                    Icons.tune_rounded,
                    color: _hasSecondaryFilters ? primary : kLightNeutralColor,
                    size: 22,
                  ),
                  if (_secondaryFilterCount > 0)
                    Positioned(
                      top: 8,
                      right: 8,
                      child: Container(
                        width: 8,
                        height: 8,
                        decoration: BoxDecoration(
                          color: primary,
                          shape: BoxShape.circle,
                          border: Border.all(color: kWhite, width: 1.5),
                        ),
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

  Widget _buildActiveFilterChips(Color primary) {
    if (!_hasSecondaryFilters) return const SizedBox.shrink();

    return Padding(
      padding: const EdgeInsets.only(top: 10),
      child: Wrap(
        spacing: 8,
        runSpacing: 8,
        children: [
          if (_skillFilter != null && _skillFilter!.trim().isNotEmpty)
            InputChip(
              label: Text(_skillFilter!),
              deleteIcon: Icon(Icons.close, size: 16, color: primary),
              onDeleted: () => setState(() => _skillFilter = null),
              backgroundColor: primary.withValues(alpha: 0.08),
              side: BorderSide(color: primary.withValues(alpha: 0.35)),
              labelStyle: kTextStyle.copyWith(
                color: primary,
                fontWeight: FontWeight.w600,
                fontSize: 12,
              ),
            ),
          if (_jobTypeFilter != null)
            InputChip(
              label: Text(_jobTypeLabel(_jobTypeFilter)),
              deleteIcon: Icon(Icons.close, size: 16, color: primary),
              onDeleted: () => setState(() => _jobTypeFilter = null),
              backgroundColor: primary.withValues(alpha: 0.08),
              side: BorderSide(color: primary.withValues(alpha: 0.35)),
              labelStyle: kTextStyle.copyWith(
                color: primary,
                fontWeight: FontWeight.w600,
                fontSize: 12,
              ),
            ),
          GestureDetector(
            onTap: _clearSecondaryFilters,
            child: Text(
              'Clear all',
              style: kTextStyle.copyWith(
                color: primary,
                fontWeight: FontWeight.w600,
                fontSize: 12,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFilters(Color primary) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildSearchRow(primary),
        _buildActiveFilterChips(primary),
        const SizedBox(height: 12),
        Text(
          '${_visibleRequests.length} job${_visibleRequests.length == 1 ? '' : 's'}',
          style: kTextStyle.copyWith(
            color: kNeutralColor,
            fontWeight: FontWeight.bold,
          ),
        ),
      ],
    );
  }

  Widget _buildJobCard(Map<String, dynamic> req, Color primary) {
    final buyer = req['profiles'] as Map<String, dynamic>?;
    final category = req['categories'] as Map<String, dynamic>?;
    final jobId = req['id'] as String?;
    final isSaved = jobId != null && _savedJobIds.contains(jobId);
    final saveBusy = jobId != null && _saveBusyIds.contains(jobId);

    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: GestureDetector(
        onTap: () async {
          await BuyerRequestDetails(jobPostId: req['id']).launch(context);
          _loadRequests();
        },
        child: Container(
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(10),
            color: kWhite,
            border: Border.all(color: kBorderColorTextField),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  CircleAvatar(
                    radius: 20,
                    backgroundImage: buyer?['profile_image_url'] != null
                        ? NetworkImage(buyer!['profile_image_url'])
                        : const AssetImage('images/profile1.png') as ImageProvider,
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          buyer?['name'] ?? 'Buyer',
                          style: kTextStyle.copyWith(
                            color: kNeutralColor,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        Text(
                          _formatDate(req['created_at']),
                          style: kTextStyle.copyWith(color: kLightNeutralColor),
                        ),
                      ],
                    ),
                  ),
                  if (jobId != null)
                    IconButton(
                      tooltip: isSaved ? context.l10n.favourites : context.l10n.favorite,
                      onPressed: saveBusy ? null : () => _toggleSaveJob(jobId),
                      visualDensity: VisualDensity.compact,
                      icon: Icon(
                        isSaved ? Icons.bookmark : Icons.bookmark_border,
                        color: isSaved ? primary : kNeutralColor,
                      ),
                    ),
                ],
              ),
              const SizedBox(height: 10),
              Text(
                req['title'] ?? 'Job Post',
                style: kTextStyle.copyWith(
                  color: kNeutralColor,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 5),
              Text(
                req['description'] ?? '',
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: kTextStyle.copyWith(color: kSubTitleColor),
              ),
              if ((req['location'] as String?)?.isNotEmpty ?? false) ...[
                const SizedBox(height: 6),
                Row(
                  children: [
                    const Icon(
                      Icons.location_on_outlined,
                      size: 14,
                      color: kLightNeutralColor,
                    ),
                    const SizedBox(width: 4),
                    Expanded(
                      child: Text(
                        req['location'] as String,
                        style: kTextStyle.copyWith(color: kSubTitleColor),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
              ],
              if (JobPostsService.workersNeededShowOnCard(req['workers_needed'])) ...[
                const SizedBox(height: 6),
                Row(
                  children: [
                    const Icon(
                      Icons.group_outlined,
                      size: 14,
                      color: kLightNeutralColor,
                    ),
                    const SizedBox(width: 4),
                    Text(
                      JobPostsService.workersNeededCardLine(req['workers_needed']),
                      style: kTextStyle.copyWith(color: kSubTitleColor),
                    ),
                  ],
                ),
              ],
              const SizedBox(height: 10),
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(20),
                      color: kDarkWhite,
                    ),
                    child: Text(
                      category?['name'] ?? 'General',
                      style: kTextStyle.copyWith(color: kNeutralColor),
                    ),
                  ),
                  const SizedBox(width: 6),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(20),
                      color: primary.withValues(alpha: 0.08),
                    ),
                    child: Text(
                      _jobTypeLabel(req['job_type'] as String?),
                      style: kTextStyle.copyWith(
                        color: primary,
                        fontWeight: FontWeight.w600,
                        fontSize: 12,
                      ),
                    ),
                  ),
                  const Spacer(),
                  if (req['budget_min'] != null || req['budget_max'] != null)
                    Text(
                      JobPostsService.formatBudgetRangeShort(
                        req['budget_min'],
                        req['budget_max'],
                        req['budget_basis'],
                      ),
                      style: kTextStyle.copyWith(
                        color: primary,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildEmptyState() {
    if (_requests.isEmpty) {
      return Center(
        child: Text(
          'No open jobs right now',
          style: kTextStyle.copyWith(color: kLightNeutralColor),
        ),
      );
    }

    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              'No jobs match your filters',
              textAlign: TextAlign.center,
              style: kTextStyle.copyWith(
                color: kNeutralColor,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Try a different title, skill, or employment type.',
              textAlign: TextAlign.center,
              style: kTextStyle.copyWith(color: kLightNeutralColor),
            ),
            if (_hasActiveFilters) ...[
              const SizedBox(height: 16),
              TextButton(
                onPressed: () {
                  _searchController.clear();
                  setState(() {
                    _titleQuery = '';
                    _jobTypeFilter = null;
                    _skillFilter = null;
                  });
                },
                child: Text(context.l10n.clearFilters),
              ),
            ],
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final primary = Theme.of(context).colorScheme.primary;
    final visible = _visibleRequests;

    return Scaffold(
      backgroundColor: kWhite,
      appBar: ClientShellAppBar(
        title: context.l10n.findJobsTitle,
        persona: ShellPersona.seller,
        actions: [
          IconButton(
            tooltip: context.l10n.jobAlertsAppBarTooltip,
            icon: const Icon(Icons.notifications_active_outlined, color: kWhite),
            onPressed: () => const SellerJobAlertsScreen().launch(context),
          ),
        ],
      ),
      body: _isLoading
          ? Center(child: CircularProgressIndicator(color: primary))
          : RefreshIndicator(
              color: primary,
              onRefresh: _loadRequests,
              child: visible.isEmpty
                  ? ListView(
                      physics: const AlwaysScrollableScrollPhysics(
                        parent: BouncingScrollPhysics(),
                      ),
                      padding: const EdgeInsets.fromLTRB(15, 15, 15, 15),
                      children: [
                        _buildFilters(primary),
                        const SizedBox(height: 48),
                        _buildEmptyState(),
                      ],
                    )
                  : ListView.builder(
                      physics: const AlwaysScrollableScrollPhysics(
                        parent: BouncingScrollPhysics(),
                      ),
                      padding: const EdgeInsets.fromLTRB(15, 15, 15, 15),
                      itemCount: visible.length + 1,
                      itemBuilder: (_, i) {
                        if (i == 0) {
                          return Padding(
                            padding: const EdgeInsets.only(bottom: 12),
                            child: _buildFilters(primary),
                          );
                        }
                        return _buildJobCard(visible[i - 1], primary);
                      },
                    ),
            ),
    );
  }
}
