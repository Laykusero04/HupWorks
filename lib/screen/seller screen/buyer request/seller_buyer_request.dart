import 'dart:async';

import 'package:flutter/material.dart';
import 'package:freelancer/core/utils/app_logger.dart';
import 'package:freelancer/l10n/l10n.dart';
import 'package:freelancer/screen/seller%20screen/job%20alerts/seller_job_alert_editor_screen.dart';
import 'package:freelancer/screen/seller%20screen/job%20alerts/seller_job_alerts_screen.dart';
import 'package:freelancer/screen/widgets/map_location_picker_screen.dart';
import 'package:freelancer/services/category_service.dart';
import 'package:freelancer/services/favourite_service.dart';
import 'package:freelancer/services/job_posts_service.dart';
import 'package:freelancer/services/profile_service.dart';
import 'package:freelancer/services/seller_orders_service.dart';
import 'package:freelancer/services/skill_service.dart';
import 'package:latlong2/latlong.dart';
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
  Timer? _titleDebounce;

  List<Map<String, dynamic>> _requests = [];
  List<Map<String, dynamic>> _categories = [];
  List<Map<String, dynamic>> _skillCatalog = [];
  final Set<String> _savedJobIds = {};
  final Set<String> _saveBusyIds = {};
  bool _isLoading = true;
  bool _isRefreshing = false;
  String _titleQuery = '';
  String? _jobTypeFilter;
  final List<String> _skillNames = [];
  final Set<String> _categoryIds = {};
  bool _useDistance = false;
  double _distanceKm = 25;
  bool _includeRemote = true;
  double? _sellerLat;
  double? _sellerLng;
  String? _sellerCity;
  String? _sellerCountry;

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
    _loadFilterMeta();
  }

  @override
  void dispose() {
    _titleDebounce?.cancel();
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _loadFilterMeta() async {
    try {
      final results = await Future.wait([
        CategoryService.listForPicker(),
        SkillService.listForPicker(),
        ProfileService.getProfile(),
      ]);
      if (!mounted) return;
      final profile = results[2] as Map<String, dynamic>?;
      setState(() {
        _categories = List<Map<String, dynamic>>.from(results[0] as List);
        _skillCatalog = List<Map<String, dynamic>>.from(results[1] as List);
        if (profile != null) {
          _sellerLat = ProfileService.latitudeFromProfile(profile);
          _sellerLng = ProfileService.longitudeFromProfile(profile);
          _sellerCity = profile['city'] as String?;
          _sellerCountry = profile['country'] as String?;
        }
      });
    } catch (e, st) {
      AppLogger.error('SellerBuyerRequest.loadFilterMeta', e, st);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(context.l10n.errorWithDetail('$e'))),
        );
      }
    }
  }

  Future<void> _pickSellerLocation() async {
    final LatLng? initial = _sellerLat != null && _sellerLng != null
        ? LatLng(_sellerLat!, _sellerLng!)
        : null;
    final result = await Navigator.of(context).push<MapLocationPickerResult>(
      MaterialPageRoute(
        builder: (_) => MapLocationPickerScreen(
          purpose: MapLocationPickerPurpose.profile,
          initialCity: _sellerCity,
          initialCountry: _sellerCountry,
          initialPosition: initial,
          accentColor: kSellerPrimary,
        ),
      ),
    );
    if (result == null || !mounted) return;

    try {
      await ProfileService.updateProfile({
        if (result.country != null && result.country!.isNotEmpty)
          'country': result.country,
        if (result.city != null && result.city!.isNotEmpty) 'city': result.city,
        'latitude': result.latitude,
        'longitude': result.longitude,
      });
      setState(() {
        _sellerLat = result.latitude;
        _sellerLng = result.longitude;
        _sellerCity = result.city;
        _sellerCountry = result.country;
      });
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(context.l10n.errorWithDetail('$e'))),
        );
      }
    }
  }

  Future<void> _loadRequests({bool showSpinner = false}) async {
    if (showSpinner) {
      setState(() => _isLoading = true);
    } else if (!_isLoading) {
      setState(() => _isRefreshing = true);
    }
    try {
      final results = await Future.wait([
        SellerOrdersService.getBuyerRequests(
          titleQuery: _titleQuery,
          categoryIds: _categoryIds.toList(),
          skillNames: List<String>.from(_skillNames),
          jobType: _jobTypeFilter,
          maxDistanceKm: _useDistance ? _distanceKm : null,
          includeRemote: _includeRemote,
          sellerLat: _sellerLat,
          sellerLng: _sellerLng,
        ),
        FavouriteService.getFavouritedJobPostIds(),
      ]);
      if (mounted) {
        setState(() {
          _requests = results[0] as List<Map<String, dynamic>>;
          _savedJobIds
            ..clear()
            ..addAll(results[1] as Set<String>);
          _isLoading = false;
          _isRefreshing = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLoading = false;
          _isRefreshing = false;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(context.l10n.errorWithDetail('$e'))),
        );
      }
    }
  }

  void _onTitleQueryChanged(String q) {
    setState(() => _titleQuery = q);
    _titleDebounce?.cancel();
    _titleDebounce = Timer(const Duration(milliseconds: 350), () {
      if (!mounted) return;
      _loadRequests();
    });
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
      _skillNames.isNotEmpty ||
      _categoryIds.isNotEmpty ||
      _useDistance ||
      !_includeRemote;

  int get _secondaryFilterCount {
    var n = 0;
    if (_jobTypeFilter != null) n++;
    if (_skillNames.isNotEmpty) n++;
    if (_categoryIds.isNotEmpty) n++;
    if (_useDistance) n++;
    if (!_includeRemote) n++;
    return n;
  }

  bool get _hasActiveFilters => _titleQuery.trim().isNotEmpty || _hasSecondaryFilters;

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

  Future<void> _clearSecondaryFilters() async {
    setState(() {
      _jobTypeFilter = null;
      _skillNames.clear();
      _categoryIds.clear();
      _useDistance = false;
      _distanceKm = 25;
      _includeRemote = true;
    });
    await _loadRequests();
  }

  Future<void> _openCategoryPicker({
    required Set<String> selected,
    required void Function(void Function()) setSheetState,
  }) async {
    final draft = Set<String>.from(selected);
    final l10n = context.l10n;
    await showDialog<void>(
      context: context,
      builder: (ctx) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            return AlertDialog(
              title: Text(l10n.jobAlertPickCategories),
              content: SizedBox(
                width: double.maxFinite,
                child: ListView(
                  shrinkWrap: true,
                  children: _categories.map((c) {
                    final id = c['id'] as String;
                    final name = c['name'] as String? ?? '';
                    return CheckboxListTile(
                      value: draft.contains(id),
                      title: Text(name, style: kTextStyle.copyWith(fontSize: 14)),
                      onChanged: (v) {
                        setDialogState(() {
                          if (v == true) {
                            draft.add(id);
                          } else {
                            draft.remove(id);
                          }
                        });
                      },
                    );
                  }).toList(),
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(ctx),
                  child: Text(l10n.cancel),
                ),
                TextButton(
                  onPressed: () {
                    setSheetState(() {
                      selected
                        ..clear()
                        ..addAll(draft);
                    });
                    Navigator.pop(ctx);
                  },
                  child: Text(l10n.filterApply),
                ),
              ],
            );
          },
        );
      },
    );
  }

  Future<void> _openFilterSheet() async {
    var tempJobType = _jobTypeFilter;
    final tempSkillNames = List<String>.from(_skillNames);
    final tempCategoryIds = Set<String>.from(_categoryIds);
    var tempUseDistance = _useDistance;
    var tempDistanceKm = _distanceKm;
    var tempIncludeRemote = _includeRemote;

    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) {
        final primary = Theme.of(ctx).colorScheme.primary;
        final l10n = context.l10n;
        return StatefulBuilder(
          builder: (context, setSheetState) {
            final hasCoords = _sellerLat != null && _sellerLng != null;
            final locationLabel = [
              if (_sellerCity?.trim().isNotEmpty == true) _sellerCity,
              if (_sellerCountry?.trim().isNotEmpty == true) _sellerCountry,
            ].whereType<String>().join(', ');
            final hasDraftFilters = tempJobType != null ||
                tempSkillNames.isNotEmpty ||
                tempCategoryIds.isNotEmpty ||
                tempUseDistance ||
                !tempIncludeRemote;

            return Padding(
              padding: EdgeInsets.only(
                bottom: MediaQuery.viewInsetsOf(context).bottom,
              ),
              child: SafeArea(
                child: ConstrainedBox(
                  constraints: BoxConstraints(
                    maxHeight: MediaQuery.sizeOf(context).height * 0.88,
                  ),
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
                        const SizedBox(height: 16),
                        Flexible(
                          child: SingleChildScrollView(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  l10n.jobAlertCategoriesSection,
                                  style: kTextStyle.copyWith(
                                    color: kLightNeutralColor,
                                    fontSize: 12,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                                const SizedBox(height: 8),
                                OutlinedButton(
                                  onPressed: () => _openCategoryPicker(
                                    selected: tempCategoryIds,
                                    setSheetState: setSheetState,
                                  ),
                                  style: OutlinedButton.styleFrom(
                                    minimumSize: const Size(double.infinity, 46),
                                    alignment: Alignment.centerLeft,
                                    foregroundColor: kNeutralColor,
                                    side: BorderSide(
                                      color: tempCategoryIds.isNotEmpty
                                          ? primary
                                          : kBorderColorTextField,
                                    ),
                                  ),
                                  child: Text(
                                    tempCategoryIds.isEmpty
                                        ? l10n.jobAlertAnyCategory
                                        : l10n.jobAlertCategoriesCount(
                                            tempCategoryIds.length,
                                          ),
                                  ),
                                ),

                                const SizedBox(height: 20),
                                Text(
                                  l10n.jobAlertSkillsSection,
                                  style: kTextStyle.copyWith(
                                    color: kLightNeutralColor,
                                    fontSize: 12,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  'Match jobs tagged with these skills.',
                                  style: kTextStyle.copyWith(
                                    color: kSubTitleColor,
                                    fontSize: 12,
                                  ),
                                ),
                                const SizedBox(height: 8),
                                Wrap(
                                  spacing: 8,
                                  runSpacing: 8,
                                  children: [
                                    ...tempSkillNames.map(
                                      (s) => Chip(
                                        label: Text(s),
                                        onDeleted: () => setSheetState(
                                          () => tempSkillNames.remove(s),
                                        ),
                                      ),
                                    ),
                                    ActionChip(
                                      avatar: const Icon(Icons.add, size: 18),
                                      label: Text(l10n.jobAlertAddSkill),
                                      onPressed: () async {
                                        await showSkillPickerSheet(
                                          context: context,
                                          skills: _skillCatalog,
                                          title: l10n.jobAlertAddSkill,
                                          allowCustomSkill: false,
                                          excludedNames: tempSkillNames
                                              .map((s) => s.toLowerCase())
                                              .toSet(),
                                          onSelected: (name) {
                                            final trimmed = name.trim();
                                            if (trimmed.isEmpty) return;
                                            if (tempSkillNames.any(
                                              (s) =>
                                                  s.toLowerCase() ==
                                                  trimmed.toLowerCase(),
                                            )) {
                                              return;
                                            }
                                            setSheetState(
                                              () => tempSkillNames.add(trimmed),
                                            );
                                          },
                                        );
                                      },
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 20),
                                Text(
                                  l10n.jobAlertJobTypeSection,
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
                                        setSheetState(
                                          () => tempJobType = opt['value'],
                                        );
                                      },
                                      selectedColor: primary,
                                      backgroundColor: kDarkWhite,
                                      labelStyle: kTextStyle.copyWith(
                                        color: selected ? kWhite : kNeutralColor,
                                      ),
                                      shape: RoundedRectangleBorder(
                                        borderRadius: BorderRadius.circular(20),
                                        side: BorderSide(
                                          color: selected
                                              ? primary
                                              : kBorderColorTextField,
                                        ),
                                      ),
                                    );
                                  }).toList(),
                                ),
                                const SizedBox(height: 20),
                                Text(
                                  l10n.jobAlertLocationSection,
                                  style: kTextStyle.copyWith(
                                    color: kLightNeutralColor,
                                    fontSize: 12,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                                const SizedBox(height: 8),
                                Text(
                                  hasCoords
                                      ? (locationLabel.isNotEmpty
                                          ? locationLabel
                                          : l10n.jobAlertLocationSet)
                                      : l10n.jobAlertLocationMissing,
                                  style: kTextStyle.copyWith(
                                    color: kSubTitleColor,
                                    fontSize: 13,
                                  ),
                                ),
                                const SizedBox(height: 8),
                                OutlinedButton.icon(
                                  onPressed: () async {
                                    await _pickSellerLocation();
                                    if (mounted) setSheetState(() {});
                                  },
                                  icon: const Icon(Icons.map_outlined),
                                  label: Text(l10n.pickLocationOnMap),
                                ),
                                const SizedBox(height: 8),
                                SwitchListTile(
                                  contentPadding: EdgeInsets.zero,
                                  value: tempUseDistance,
                                  onChanged: (v) =>
                                      setSheetState(() => tempUseDistance = v),
                                  title: Text(
                                    l10n.jobAlertLimitDistance,
                                    style: kTextStyle.copyWith(
                                      color: kNeutralColor,
                                    ),
                                  ),
                                  activeThumbColor: primary,
                                ),
                                if (tempUseDistance)
                                  Slider(
                                    value: tempDistanceKm,
                                    min: 5,
                                    max: 100,
                                    divisions: 19,
                                    label: l10n.jobAlertWithinKm(
                                      tempDistanceKm.round(),
                                    ),
                                    onChanged: (v) => setSheetState(
                                      () => tempDistanceKm = v,
                                    ),
                                  ),
                                SwitchListTile(
                                  contentPadding: EdgeInsets.zero,
                                  value: tempIncludeRemote,
                                  onChanged: (v) => setSheetState(
                                    () => tempIncludeRemote = v,
                                  ),
                                  title: Text(
                                    l10n.jobAlertIncludeRemote,
                                    style: kTextStyle.copyWith(
                                      color: kNeutralColor,
                                    ),
                                  ),
                                  activeThumbColor: primary,
                                ),
                                if (hasDraftFilters) ...[
                                  const SizedBox(height: 8),
                                  Align(
                                    alignment: Alignment.centerLeft,
                                    child: TextButton(
                                      onPressed: () {
                                        if (tempUseDistance &&
                                            (_sellerLat == null ||
                                                _sellerLng == null)) {
                                          ScaffoldMessenger.of(context)
                                              .showSnackBar(
                                            SnackBar(
                                              content: Text(
                                                l10n.jobAlertNeedProfileLocation,
                                              ),
                                            ),
                                          );
                                          return;
                                        }
                                        Navigator.pop(ctx);
                                        SellerJobAlertEditorScreen(
                                          initialSkillNames: tempSkillNames,
                                          initialJobType: tempJobType,
                                          initialCategoryIds:
                                              tempCategoryIds.toList(),
                                          initialMaxDistanceKm: tempUseDistance
                                              ? tempDistanceKm
                                              : null,
                                          initialIncludeRemote:
                                              tempIncludeRemote,
                                        ).launch(context);
                                      },
                                      child: Text(l10n.jobAlertSaveFromFilter),
                                    ),
                                  ),
                                ],
                              ],
                            ),
                          ),
                        ),
                        const SizedBox(height: 12),
                        Row(
                          children: [
                            Expanded(
                              child: OutlinedButton(
                                onPressed: () {
                                  setSheetState(() {
                                    tempJobType = null;
                                    tempSkillNames.clear();
                                    tempCategoryIds.clear();
                                    tempUseDistance = false;
                                    tempDistanceKm = 25;
                                    tempIncludeRemote = true;
                                  });
                                },
                                style: OutlinedButton.styleFrom(
                                  foregroundColor: kNeutralColor,
                                  side: const BorderSide(
                                    color: kBorderColorTextField,
                                  ),
                                  minimumSize: const Size(0, 46),
                                ),
                                child: Text(l10n.filterClear),
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: FilledButton(
                                onPressed: () {
                                  if (tempUseDistance &&
                                      (_sellerLat == null ||
                                          _sellerLng == null)) {
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      SnackBar(
                                        content: Text(
                                          l10n.jobAlertNeedProfileLocation,
                                        ),
                                      ),
                                    );
                                    return;
                                  }
                                  setState(() {
                                    _jobTypeFilter = tempJobType;
                                    _skillNames
                                      ..clear()
                                      ..addAll(tempSkillNames);
                                    _categoryIds
                                      ..clear()
                                      ..addAll(tempCategoryIds);
                                    _useDistance = tempUseDistance;
                                    _distanceKm = tempDistanceKm;
                                    _includeRemote = tempIncludeRemote;
                                  });
                                  Navigator.pop(ctx);
                                  _loadRequests();
                                },
                                style: FilledButton.styleFrom(
                                  backgroundColor: primary,
                                  minimumSize: const Size(0, 46),
                                ),
                                child: Text(l10n.filterApply),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
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
            onChanged: _onTitleQueryChanged,
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
                        _titleDebounce?.cancel();
                        setState(() => _titleQuery = '');
                        _loadRequests();
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

    final l10n = context.l10n;
    InputChip chip(String label, VoidCallback onDeleted) {
      return InputChip(
        label: Text(label),
        deleteIcon: Icon(Icons.close, size: 16, color: primary),
        onDeleted: onDeleted,
        backgroundColor: primary.withValues(alpha: 0.08),
        side: BorderSide(color: primary.withValues(alpha: 0.35)),
        labelStyle: kTextStyle.copyWith(
          color: primary,
          fontWeight: FontWeight.w600,
          fontSize: 12,
        ),
      );
    }

    return Padding(
      padding: const EdgeInsets.only(top: 10),
      child: Wrap(
        spacing: 8,
        runSpacing: 8,
        children: [
          if (_categoryIds.isNotEmpty)
            chip(
              l10n.jobAlertCategoriesCount(_categoryIds.length),
              () {
                setState(() => _categoryIds.clear());
                _loadRequests();
              },
            ),
          ..._skillNames.map(
            (s) => chip(s, () {
              setState(() => _skillNames.remove(s));
              _loadRequests();
            }),
          ),
          if (_jobTypeFilter != null)
            chip(
              _jobTypeLabel(_jobTypeFilter),
              () {
                setState(() => _jobTypeFilter = null);
                _loadRequests();
              },
            ),
          if (_useDistance)
            chip(
              l10n.jobAlertWithinKm(_distanceKm.round()),
              () {
                setState(() => _useDistance = false);
                _loadRequests();
              },
            ),
          if (!_includeRemote)
            chip(
              'On-site only',
              () {
                setState(() => _includeRemote = true);
                _loadRequests();
              },
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
          '${_requests.length} job${_requests.length == 1 ? '' : 's'}',
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
    final skillTags = JobPostsService.skillNamesFromJob(req);
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
              if (skillTags.isNotEmpty) ...[
                const SizedBox(height: 8),
                Wrap(
                  spacing: 6,
                  runSpacing: 6,
                  children: skillTags
                      .take(4)
                      .map(
                        (s) => Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 3,
                          ),
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(16),
                            color: kDarkWhite,
                            border: Border.all(color: kBorderColorTextField),
                          ),
                          child: Text(
                            s,
                            style: kTextStyle.copyWith(
                              color: kSubTitleColor,
                              fontSize: 11,
                            ),
                          ),
                        ),
                      )
                      .toList(),
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
              'Try adjusting category, job type, distance, or remote.',
              textAlign: TextAlign.center,
              style: kTextStyle.copyWith(color: kLightNeutralColor),
            ),
            if (_hasActiveFilters) ...[
              const SizedBox(height: 16),
              TextButton(
                onPressed: () async {
                  _searchController.clear();
                  _titleDebounce?.cancel();
                  setState(() {
                    _titleQuery = '';
                    _jobTypeFilter = null;
                    _skillNames.clear();
                    _categoryIds.clear();
                    _useDistance = false;
                    _distanceKm = 25;
                    _includeRemote = true;
                  });
                  await _loadRequests();
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
    final visible = _requests;

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
          : Column(
              children: [
                if (_isRefreshing)
                  LinearProgressIndicator(
                    minHeight: 2,
                    color: primary,
                    backgroundColor: primary.withValues(alpha: 0.15),
                  ),
                Expanded(
                  child: RefreshIndicator(
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
                ),
              ],
            ),
    );
  }
}
