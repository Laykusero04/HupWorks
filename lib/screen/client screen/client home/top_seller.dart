import 'dart:async';
import 'package:freelancer/core/widgets/rubik_refresh_indicator.dart';
import 'package:freelancer/core/widgets/loading_widget.dart';

import 'package:flutter/material.dart';
import 'package:flutter_iconly/flutter_iconly.dart';
import 'package:freelancer/core/utils/profile_image.dart';
import 'package:freelancer/core/utils/talent_seller_filters.dart';
import 'package:freelancer/l10n/l10n.dart';
import 'package:freelancer/services/client_home_service.dart';
import 'package:freelancer/services/profile_service.dart';
import 'package:freelancer/screen/widgets/talent_filter_sheet.dart';

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
  Timer? _searchDebounce;

  List<Map<String, dynamic>> _sellers = [];
  bool _isLoading = true;
  String _searchQuery = '';
  TalentSellerFilters _filters = TalentSellerFilters.empty;
  TalentFilterOrigin _origin = TalentFilterOrigin.empty;

  @override
  void initState() {
    super.initState();
    _bootstrap();
  }

  @override
  void dispose() {
    _searchDebounce?.cancel();
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _bootstrap() async {
    try {
      final profile = await ProfileService.getProfile();
      if (mounted) {
        setState(() => _origin = TalentFilterOrigin.fromProfile(profile));
      }
    } catch (_) {
      // Origin stays empty; nearby requires a map pin later.
    }
    await _load();
  }

  Future<void> _load() async {
    if (mounted) setState(() => _isLoading = true);
    try {
      final list = await ClientHomeService.browseSellers(
        query: _filters.usesNearbySearch ? _searchQuery : '',
        maxDistanceKm: _filters.maxDistanceKm,
        clientLat: _origin.latitude,
        clientLng: _origin.longitude,
        limit: 48,
      );
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

  List<Map<String, dynamic>> get _filteredSellers => TalentSellerFilters.apply(
        _sellers,
        filters: _filters,
        // Nearby text match is server-side; otherwise filter locally.
        query: _filters.usesNearbySearch ? '' : _searchQuery,
      );

  void _onSearchChanged(String q) {
    setState(() => _searchQuery = q);
    if (!_filters.usesNearbySearch) return;
    _searchDebounce?.cancel();
    _searchDebounce = Timer(const Duration(milliseconds: 350), _load);
  }

  String _subtitle(Map<String, dynamic> seller) {
    final sp = TalentSellerFilters.sellerProfileRow(seller);
    final jobTitle = sp?['job_title'] as String?;
    final distance = (seller['distance_km'] as num?)?.toDouble();
    String? distanceLabel;
    if (distance != null && _filters.usesNearbySearch) {
      distanceLabel = distance < 10
          ? '${distance.toStringAsFixed(1)} km'
          : '${distance.round()} km';
    }

    if (jobTitle != null && jobTitle.trim().isNotEmpty) {
      return distanceLabel == null
          ? jobTitle.trim()
          : '$distanceLabel · ${jobTitle.trim()}';
    }

    final topSkills = ProfileService.sellerSkillsFromProfile(seller)
        .where((s) => s.stars == 5)
        .map((s) => s.name)
        .toList();
    if (topSkills.isNotEmpty) {
      final skills = topSkills.take(2).join(' · ');
      return distanceLabel == null ? skills : '$distanceLabel · $skills';
    }

    if (distanceLabel != null) return distanceLabel;

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

  Future<void> _openFilterSheet() async {
    final next = await showTalentFilterSheet(
      context,
      initial: _filters,
      origin: _origin,
      onOriginChanged: (o) {
        if (mounted) setState(() => _origin = o);
      },
    );
    if (next != null && mounted) {
      setState(() => _filters = next);
      await _load();
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
              onChanged: _onSearchChanged,
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
          TalentFilterButton(
            filters: _filters,
            onPressed: _openFilterSheet,
          ),
        ],
      ),
    );
  }

  Widget _buildGrid(List<Map<String, dynamic>> sellers) {
    return RubikRefreshIndicator(
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
          TalentFilterActiveChips(
            filters: _filters,
            onChanged: (f) {
              final nearbyChanged =
                  f.maxDistanceKm != _filters.maxDistanceKm;
              setState(() => _filters = f);
              if (nearbyChanged) {
                _load();
              }
            },
          ),
          Expanded(
            child: _isLoading
                ? const LoadingWidget()
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
                                  if (_filters.hasActive) ...[
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
                                      onPressed: () async {
                                        setState(
                                          () => _filters =
                                              TalentSellerFilters.empty,
                                        );
                                        await _load();
                                      },
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
