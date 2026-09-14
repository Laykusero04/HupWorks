import 'package:flutter/material.dart';
import 'package:flutter_iconly/flutter_iconly.dart';
import 'package:freelancer/core/utils/profile_image.dart';
import 'package:freelancer/core/utils/seller_standing.dart';
import 'package:freelancer/l10n/l10n.dart';
import 'package:freelancer/services/client_home_service.dart';
import 'package:freelancer/services/profile_service.dart';
import 'package:freelancer/services/verification_service.dart';

import '../../widgets/client_shell_app_bar.dart';
import '../../widgets/constant.dart';
import '../../widgets/seller_standing_badge.dart';
import '../../widgets/talent_card_verification_mark.dart';
import '../client talent/freelancer_public_profile.dart';

class TopSeller extends StatefulWidget {
  const TopSeller({Key? key}) : super(key: key);

  @override
  State<TopSeller> createState() => _TopSellerState();
}

class _TopSellerState extends State<TopSeller> {
  final TextEditingController _searchController = TextEditingController();

  List<Map<String, dynamic>> _sellers = [];
  bool _isLoading = true;
  String _searchQuery = '';

  /// `null` = any verification status.
  bool? _verifiedOnly;
  SellerStanding? _standingFilter;
  double? _minRating;

  static const _minRatingOptions = <double>[3.5, 4.0, 4.5];

  @override
  void initState() {
    super.initState();
    _load();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  bool get _hasActiveFilters =>
      _verifiedOnly == true || _standingFilter != null || _minRating != null;

  int get _activeFilterCount {
    var n = 0;
    if (_verifiedOnly == true) n++;
    if (_standingFilter != null) n++;
    if (_minRating != null) n++;
    return n;
  }

  Future<void> _load() async {
    try {
      final list = await ClientHomeService.getTopSellers(limit: 48);
      if (mounted) {
        setState(() {
          _sellers = list;
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

  List<Map<String, dynamic>> get _filteredSellers {
    final q = _searchQuery.trim().toLowerCase();

    return _sellers.where((seller) {
      if (q.isNotEmpty) {
        final name = (seller['name'] as String? ?? '').toLowerCase();
        final sp = _sellerProfileRow(seller);
        final jobTitle = (sp?['job_title'] as String? ?? '').toLowerCase();
        final about = (sp?['about'] as String? ?? '').toLowerCase();
        final skillNames = ProfileService.sellerSkillsFromProfile(seller)
            .map((s) => s.name.toLowerCase())
            .join(' ');
        final matchesSearch = name.contains(q) ||
            jobTitle.contains(q) ||
            about.contains(q) ||
            skillNames.contains(q);
        if (!matchesSearch) return false;
      }

      if (_verifiedOnly == true) {
        if (VerificationService.statusFromProfile(seller) != 'verified') {
          return false;
        }
      }

      final rating = double.tryParse('${seller['rating'] ?? 0}') ?? 0;
      final reviewCount = (seller['review_count'] as num?)?.toInt() ?? 0;

      if (_minRating != null && rating < _minRating!) return false;

      if (_standingFilter != null) {
        final standing = SellerStandingResolver.resolve(
          rating: rating,
          reviewCount: reviewCount,
        );
        if (standing != _standingFilter) return false;
      }

      return true;
    }).toList();
  }

  static Map<String, dynamic>? _sellerProfileRow(Map<String, dynamic> seller) {
    final sp = seller['seller_profiles'];
    if (sp is Map<String, dynamic>) return sp;
    if (sp is List && sp.isNotEmpty && sp.first is Map<String, dynamic>) {
      return sp.first as Map<String, dynamic>;
    }
    return null;
  }

  String _subtitle(Map<String, dynamic> seller) {
    final sp = _sellerProfileRow(seller);
    final jobTitle = sp?['job_title'] as String?;
    if (jobTitle != null && jobTitle.trim().isNotEmpty) return jobTitle.trim();

    final topSkills = ProfileService.sellerSkillsFromProfile(seller)
        .where((s) => s.stars == 5)
        .map((s) => s.name)
        .toList();
    if (topSkills.isNotEmpty) return topSkills.take(2).join(' · ');

    final about = sp?['about'] as String?;
    if (about != null && about.trim().isNotEmpty) {
      final t = about.trim();
      return t.length > 48 ? '${t.substring(0, 48)}…' : t;
    }
    return context.l10n.freelancerDefault;
  }

  void _openSeller(Map<String, dynamic> seller) {
    final id = seller['id'] as String?;
    if (id == null) return;
    openFreelancerPublicProfile(
      context,
      sellerId: id,
      name: seller['name'] as String?,
    );
  }

  void _clearFilters() {
    setState(() {
      _verifiedOnly = null;
      _standingFilter = null;
      _minRating = null;
    });
  }

  Future<void> _openFilterSheet() async {
    final l10n = context.l10n;
    var draftVerified = _verifiedOnly;
    var draftStanding = _standingFilter;
    var draftMinRating = _minRating;

    final applied = await showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      backgroundColor: kWhite,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) {
        return StatefulBuilder(
          builder: (ctx, setSheetState) {
            Widget sectionLabel(String text) => Text(
                  text,
                  style: kTextStyle.copyWith(
                    color: kLightNeutralColor,
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                  ),
                );

            Widget chip({
              required String label,
              required bool selected,
              required VoidCallback onTap,
            }) {
              return ChoiceChip(
                label: Text(label),
                selected: selected,
                onSelected: (_) => onTap(),
                selectedColor: kPrimaryColor.withValues(alpha: 0.15),
                labelStyle: kTextStyle.copyWith(
                  color: selected ? kPrimaryColor : kNeutralColor,
                  fontWeight: selected ? FontWeight.w600 : FontWeight.w500,
                  fontSize: 13,
                ),
                backgroundColor: kDarkWhite,
                side: BorderSide(
                  color: selected ? kPrimaryColor : kBorderColorTextField,
                ),
              );
            }

            return SafeArea(
              child: Padding(
                padding: EdgeInsets.fromLTRB(
                  20,
                  12,
                  20,
                  16 + MediaQuery.viewInsetsOf(ctx).bottom,
                ),
                child: ConstrainedBox(
                  constraints: BoxConstraints(
                    maxHeight: MediaQuery.sizeOf(ctx).height * 0.75,
                  ),
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
                        l10n.filterTalent,
                        style: kTextStyle.copyWith(
                          color: kNeutralColor,
                          fontWeight: FontWeight.bold,
                          fontSize: 17,
                        ),
                      ),
                      const SizedBox(height: 20),
                      Flexible(
                        child: SingleChildScrollView(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              sectionLabel(l10n.statusVerified),
                              const SizedBox(height: 8),
                              Wrap(
                                spacing: 8,
                                runSpacing: 8,
                                children: [
                                  chip(
                                    label: l10n.filterAll,
                                    selected: draftVerified != true,
                                    onTap: () => setSheetState(
                                      () => draftVerified = null,
                                    ),
                                  ),
                                  chip(
                                    label: l10n.statusVerified,
                                    selected: draftVerified == true,
                                    onTap: () => setSheetState(
                                      () => draftVerified = true,
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 20),
                              sectionLabel(l10n.standingTitle),
                              const SizedBox(height: 8),
                              Wrap(
                                spacing: 8,
                                runSpacing: 8,
                                children: [
                                  chip(
                                    label: l10n.filterAll,
                                    selected: draftStanding == null,
                                    onTap: () => setSheetState(
                                      () => draftStanding = null,
                                    ),
                                  ),
                                  for (final standing in SellerStanding.values)
                                    chip(
                                      label: standing.label(l10n),
                                      selected: draftStanding == standing,
                                      onTap: () => setSheetState(
                                        () => draftStanding = standing,
                                      ),
                                    ),
                                ],
                              ),
                              const SizedBox(height: 20),
                              sectionLabel(l10n.filterMinRating),
                              const SizedBox(height: 8),
                              Wrap(
                                spacing: 8,
                                runSpacing: 8,
                                children: [
                                  chip(
                                    label: l10n.filterAll,
                                    selected: draftMinRating == null,
                                    onTap: () => setSheetState(
                                      () => draftMinRating = null,
                                    ),
                                  ),
                                  for (final rating in _minRatingOptions)
                                    chip(
                                      label: l10n.ratingAtLeast(
                                        rating.toStringAsFixed(1),
                                      ),
                                      selected: draftMinRating == rating,
                                      onTap: () => setSheetState(
                                        () => draftMinRating = rating,
                                      ),
                                    ),
                                ],
                              ),
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(height: 20),
                      Row(
                        children: [
                          Expanded(
                            child: OutlinedButton(
                              onPressed: () {
                                setSheetState(() {
                                  draftVerified = null;
                                  draftStanding = null;
                                  draftMinRating = null;
                                });
                              },
                              style: OutlinedButton.styleFrom(
                                foregroundColor: kNeutralColor,
                                side: const BorderSide(
                                  color: kBorderColorTextField,
                                ),
                                minimumSize: const Size.fromHeight(46),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(12),
                                ),
                              ),
                              child: Text(l10n.filterClear),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: ElevatedButton(
                              onPressed: () => Navigator.pop(ctx, true),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: kPrimaryColor,
                                foregroundColor: kWhite,
                                minimumSize: const Size.fromHeight(46),
                                elevation: 0,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(12),
                                ),
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
            );
          },
        );
      },
    );

    if (applied == true && mounted) {
      setState(() {
        _verifiedOnly = draftVerified;
        _standingFilter = draftStanding;
        _minRating = draftMinRating;
      });
    }
  }

  Widget _buildSearchBar() {
    final l10n = context.l10n;
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
      child: Row(
        children: [
          Expanded(
            child: TextField(
              controller: _searchController,
              onChanged: (q) => setState(() => _searchQuery = q),
              style: kTextStyle.copyWith(color: kNeutralColor, fontSize: 14),
              decoration: InputDecoration(
                hintText: l10n.searchFreelancers,
                hintStyle:
                    kTextStyle.copyWith(color: kLightNeutralColor, fontSize: 14),
                prefixIcon: const Icon(Icons.search, color: kLightNeutralColor),
                suffixIcon: _searchQuery.isNotEmpty
                    ? IconButton(
                        icon: const Icon(
                          Icons.close,
                          color: kLightNeutralColor,
                          size: 20,
                        ),
                        onPressed: () {
                          _searchController.clear();
                          setState(() => _searchQuery = '');
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
                  borderSide: const BorderSide(color: kPrimaryColor),
                ),
              ),
            ),
          ),
          const SizedBox(width: 8),
          Material(
            color: _hasActiveFilters
                ? kPrimaryColor.withValues(alpha: 0.12)
                : kDarkWhite,
            borderRadius: BorderRadius.circular(12),
            child: InkWell(
              onTap: _openFilterSheet,
              borderRadius: BorderRadius.circular(12),
              child: Container(
                width: 48,
                height: 48,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: _hasActiveFilters
                        ? kPrimaryColor
                        : kBorderColorTextField,
                  ),
                ),
                child: Badge(
                  isLabelVisible: _hasActiveFilters,
                  label: Text('$_activeFilterCount'),
                  backgroundColor: kPrimaryColor,
                  child: Icon(
                    Icons.tune_rounded,
                    color: _hasActiveFilters ? kPrimaryColor : kNeutralColor,
                    size: 22,
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildActiveFilterChips() {
    if (!_hasActiveFilters) return const SizedBox.shrink();
    final l10n = context.l10n;

    Widget pill(String label, VoidCallback onClear) {
      return Padding(
        padding: const EdgeInsets.only(right: 8),
        child: InputChip(
          label: Text(label),
          onDeleted: onClear,
          deleteIconColor: kPrimaryColor,
          backgroundColor: kPrimaryColor.withValues(alpha: 0.1),
          side: BorderSide(color: kPrimaryColor.withValues(alpha: 0.35)),
          labelStyle: kTextStyle.copyWith(
            color: kPrimaryColor,
            fontSize: 12,
            fontWeight: FontWeight.w600,
          ),
        ),
      );
    }

    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: Row(
          children: [
            if (_verifiedOnly == true)
              pill(l10n.statusVerified, () => setState(() => _verifiedOnly = null)),
            if (_standingFilter != null)
              pill(
                _standingFilter!.label(l10n),
                () => setState(() => _standingFilter = null),
              ),
            if (_minRating != null)
              pill(
                l10n.ratingAtLeast(_minRating!.toStringAsFixed(1)),
                () => setState(() => _minRating = null),
              ),
            TextButton(
              onPressed: _clearFilters,
              style: TextButton.styleFrom(
                foregroundColor: kSubTitleColor,
                padding: const EdgeInsets.symmetric(horizontal: 8),
                minimumSize: Size.zero,
                tapTargetSize: MaterialTapTargetSize.shrinkWrap,
              ),
              child: Text(
                l10n.clearFilters,
                style: kTextStyle.copyWith(fontSize: 12),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildGrid(List<Map<String, dynamic>> sellers) {
    return RefreshIndicator(
      color: kPrimaryColor,
      onRefresh: _load,
      child: GridView.builder(
        physics: const AlwaysScrollableScrollPhysics(parent: BouncingScrollPhysics()),
        padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 2,
          mainAxisSpacing: 14,
          crossAxisSpacing: 14,
          childAspectRatio: 0.62,
        ),
        itemCount: sellers.length,
        itemBuilder: (_, i) {
          final seller = sellers[i];
          final l10n = context.l10n;
          final profileImageUrl = seller['profile_image_url'] as String?;
          final name = seller['name'] as String? ?? l10n.authRoleFreelancer;
          final rating = double.tryParse('${seller['rating'] ?? 0}') ?? 0;
          final reviewCount = (seller['review_count'] as num?)?.toInt();

          return Material(
            color: Colors.transparent,
            child: InkWell(
              borderRadius: BorderRadius.circular(14),
              onTap: () => _openSeller(seller),
              child: Container(
                decoration: BoxDecoration(
                  color: kWhite,
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: kBorderColorTextField),
                ),
                clipBehavior: Clip.antiAlias,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
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
                            height: 40,
                            child: DecoratedBox(
                              decoration: BoxDecoration(
                                gradient: LinearGradient(
                                  begin: Alignment.topCenter,
                                  end: Alignment.bottomCenter,
                                  colors: [
                                    Colors.transparent,
                                    Colors.black.withValues(alpha: 0.4),
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
                                    rating.toStringAsFixed(1),
                                    style: kTextStyle.copyWith(
                                      color: Colors.white,
                                      fontSize: 11,
                                      fontWeight: FontWeight.w700,
                                    ),
                                  ),
                                  if (reviewCount != null) ...[
                                    Text(
                                      ' ($reviewCount)',
                                      style: kTextStyle.copyWith(
                                        color: Colors.white70,
                                        fontSize: 10,
                                      ),
                                    ),
                                  ],
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
                            name,
                            style: kTextStyle.copyWith(
                              color: kNeutralColor,
                              fontWeight: FontWeight.bold,
                              fontSize: 13,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                          const SizedBox(height: 2),
                          Text(
                            _subtitle(seller),
                            style: kTextStyle.copyWith(
                              color: kSubTitleColor,
                              fontSize: 11,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                          const SizedBox(height: 6),
                          TalentCardStandingChip(
                            rating: rating,
                            reviewCount: reviewCount ?? 0,
                            onPhoto: false,
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final filtered = _filteredSellers;

    return Scaffold(
      backgroundColor: kWhite,
      appBar: ClientShellAppBar(title: l10n.talent),
      body: Column(
        children: [
          _buildSearchBar(),
          _buildActiveFilterChips(),
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator(color: kPrimaryColor))
                : _sellers.isEmpty
                    ? Center(
                        child: Text(
                          l10n.noFreelancersYet,
                          style: kTextStyle.copyWith(color: kLightNeutralColor),
                        ),
                      )
                    : filtered.isEmpty
                        ? Center(
                            child: Padding(
                              padding: const EdgeInsets.symmetric(horizontal: 32),
                              child: Column(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Text(
                                    l10n.noFreelancersMatch,
                                    textAlign: TextAlign.center,
                                    style: kTextStyle.copyWith(
                                      color: kNeutralColor,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                  if (_hasActiveFilters) ...[
                                    const SizedBox(height: 8),
                                    Text(
                                      l10n.tryAdjustingFilters,
                                      textAlign: TextAlign.center,
                                      style: kTextStyle.copyWith(
                                        color: kLightNeutralColor,
                                        fontSize: 13,
                                      ),
                                    ),
                                    const SizedBox(height: 12),
                                    TextButton(
                                      onPressed: _clearFilters,
                                      child: Text(l10n.clearFilters),
                                    ),
                                  ],
                                ],
                              ),
                            ),
                          )
                        : _buildGrid(filtered),
          ),
        ],
      ),
    );
  }
}
