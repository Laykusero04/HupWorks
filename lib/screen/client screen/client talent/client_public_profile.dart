import 'package:flutter/material.dart';
import 'package:freelancer/l10n/l10n.dart';
import 'package:freelancer/services/profile_service.dart';

import '../../widgets/constant.dart';
import '../../widgets/profile_detail_theme.dart';
import '../../widgets/profile_rating_summary.dart';
import '../../widgets/profile_skeleton.dart';

/// Seller-facing view of a client's public profile (find jobs).
class ClientPublicProfile extends StatefulWidget {
  const ClientPublicProfile({
    super.key,
    required this.clientId,
    this.initialName,
  });

  final String clientId;
  final String? initialName;

  @override
  State<ClientPublicProfile> createState() => _ClientPublicProfileState();
}

class _ClientPublicProfileState extends State<ClientPublicProfile> {
  Map<String, dynamic>? _profile;
  List<Map<String, dynamic>> _reviews = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    try {
      final results = await Future.wait([
        ProfileService.getPublicClientProfile(widget.clientId),
        ProfileService.getReviewsReceived(widget.clientId),
      ]);
      if (!mounted) return;
      setState(() {
        _profile = results[0] as Map<String, dynamic>?;
        _reviews = List<Map<String, dynamic>>.from(
          results[1] as List<dynamic>? ?? const [],
        );
        _isLoading = false;
      });
    } catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(context.l10n.couldNotLoadProfile('$e'))),
        );
      }
    }
  }

  static String _formatMemberSince(String? iso) {
    if (iso == null || iso.isEmpty) return '—';
    final d = DateTime.tryParse(iso);
    if (d == null) return '—';
    const months = [
      'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
      'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec',
    ];
    return '${months[d.month - 1]} ${d.day}, ${d.year}';
  }

  static String _formatReviewDate(String? iso) {
    if (iso == null || iso.isEmpty) return '';
    final d = DateTime.tryParse(iso);
    if (d == null) return '';
    const months = [
      'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
      'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec',
    ];
    return '${months[d.month - 1]} ${d.day}, ${d.year}';
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Scaffold(
        body: ProfileDetailsSkeleton(extraSection: true),
      );
    }

    if (_profile == null) {
      return Scaffold(
        appBar: AppBar(),
        body: Center(
          child: Text(
            'Client not found',
            style: kTextStyle.copyWith(color: kSubTitleColor),
          ),
        ),
      );
    }

    final name = _profile!['name'] as String? ?? widget.initialName ?? 'Client';
    final bio = (_profile!['bio'] as String?)?.trim();
    final city = (_profile!['city'] as String?)?.trim() ?? '';
    final country = (_profile!['country'] as String?)?.trim() ?? '';
    final profileImageUrl = _profile!['profile_image_url'] as String?;
    final jobCount = (_profile!['job_posts_count'] as num?)?.toInt() ?? 0;
    final memberSince = _formatMemberSince(_profile!['created_at'] as String?);
    final reviewStats = ProfileService.resolveReviewDisplay(
      profile: _profile,
      reviews: _reviews,
    );
    final rating = reviewStats.rating;
    final reviewCount = reviewStats.count;
    final avgLabel = reviewCount > 0 ? rating.toStringAsFixed(1) : '—';
    final locationParts = [city, country].where((s) => s.isNotEmpty).toList();
    final locationStr = locationParts.join(', ');

    return Scaffold(
      backgroundColor: kDarkWhite,
      appBar: AppBar(
        backgroundColor: kDarkWhite,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        iconTheme: const IconThemeData(color: kNeutralColor),
        title: Text(
          'Client profile',
          style: kTextStyle.copyWith(
            color: kPrimaryColor,
            fontWeight: FontWeight.bold,
          ),
        ),
        centerTitle: true,
      ),
      body: RefreshIndicator(
        color: kPrimaryColor,
        onRefresh: _load,
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(
            parent: BouncingScrollPhysics(),
          ),
          padding: const EdgeInsets.only(bottom: 32),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const SizedBox(height: 8),
              Center(
                child: Container(
                  height: 110,
                  width: 110,
                  decoration: ProfileDetailTheme.avatarDecoration(
                    profileImageUrl != null && profileImageUrl.isNotEmpty
                        ? NetworkImage(profileImageUrl) as ImageProvider
                        : const AssetImage('images/profile1.png'),
                    accent: kPrimaryColor,
                  ),
                ),
              ),
              const SizedBox(height: 12),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 24),
                child: Text(
                  name,
                  textAlign: TextAlign.center,
                  style: kTextStyle.copyWith(
                    fontWeight: FontWeight.bold,
                    fontSize: 22,
                  ),
                ),
              ),
              if (locationStr.isNotEmpty) ...[
                const SizedBox(height: 8),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(
                      Icons.location_on_outlined,
                      size: 14,
                      color: kPrimaryColor,
                    ),
                    const SizedBox(width: 4),
                    Text(
                      locationStr,
                      style: kTextStyle.copyWith(color: kLightNeutralColor),
                    ),
                  ],
                ),
              ],
              const SizedBox(height: 10),
              Center(
                child: ProfileRatingSummary(
                  rating: rating,
                  reviewCount: reviewCount,
                  accentColor: kPrimaryColor,
                ),
              ),
              const SizedBox(height: 18),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 24),
                child: Container(
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  decoration: ProfileDetailTheme.statsPanel(accent: kPrimaryColor),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      _stat('$jobCount', 'Jobs posted'),
                      _divider(),
                      _stat(memberSince, 'Member since'),
                      _divider(),
                      _stat(avgLabel, 'Avg rating'),
                    ],
                  ),
                ),
              ),
              if (bio != null && bio.isNotEmpty) ...[
                const SizedBox(height: 16),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 24),
                  child: Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(14),
                    decoration: ProfileDetailTheme.cardOnPage(accent: kPrimaryColor),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'About',
                          style: kTextStyle.copyWith(
                            color: kPrimaryColor,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 6),
                        Text(
                          bio,
                          style: kTextStyle.copyWith(
                            color: kSubTitleColor,
                            height: 1.35,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
              const SizedBox(height: 24),
              ProfileDetailTheme.sectionDivider(
                gradientStart: kPrimaryColor,
                gradientEnd: kSecondaryColor,
              ),
              const SizedBox(height: 16),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 24),
                child: Row(
                  children: [
                    Text(
                      'Reviews',
                      style: kTextStyle.copyWith(
                        color: kNeutralColor,
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                      ),
                    ),
                    const Spacer(),
                    Text(
                      reviewCount == 0
                          ? 'None yet'
                          : '$reviewCount total',
                      style: kTextStyle.copyWith(color: kLightNeutralColor, fontSize: 12),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 10),
              if (_reviews.isEmpty)
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 24),
                  child: Text(
                    'No reviews for this client yet.',
                    style: kTextStyle.copyWith(color: kSubTitleColor),
                  ),
                )
              else
                ..._reviews.map((r) {
                  final reviewer = r['reviewer'];
                  final reviewerName = reviewer is Map
                      ? (reviewer['name'] as String?) ?? 'User'
                      : 'User';
                  final stars = ProfileService.ratingAsStars(r['rating']);
                  final comment = (r['comment'] as String?)?.trim();
                  return Padding(
                    padding: const EdgeInsets.fromLTRB(24, 0, 24, 10),
                    child: Container(
                      padding: const EdgeInsets.all(12),
                      decoration: ProfileDetailTheme.cardOnPage(
                        accent: kPrimaryColor,
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Expanded(
                                child: Text(
                                  reviewerName,
                                  style: kTextStyle.copyWith(
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ),
                              Row(
                                children: List.generate(
                                  5,
                                  (i) => Icon(
                                    i < stars
                                        ? Icons.star_rounded
                                        : Icons.star_outline_rounded,
                                    size: 16,
                                    color: ratingBarColor,
                                  ),
                                ),
                              ),
                            ],
                          ),
                          if (comment != null && comment.isNotEmpty) ...[
                            const SizedBox(height: 6),
                            Text(
                              comment,
                              style: kTextStyle.copyWith(
                                color: kSubTitleColor,
                                fontSize: 13,
                                height: 1.35,
                              ),
                            ),
                          ],
                          const SizedBox(height: 4),
                          Text(
                            _formatReviewDate(r['created_at'] as String?),
                            style: kTextStyle.copyWith(
                              color: kLightNeutralColor,
                              fontSize: 11,
                            ),
                          ),
                        ],
                      ),
                    ),
                  );
                }),
            ],
          ),
        ),
      ),
    );
  }

  Widget _stat(String value, String label) {
    return Expanded(
      child: Column(
        children: [
          Text(
            value,
            textAlign: TextAlign.center,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: kTextStyle.copyWith(
              fontWeight: FontWeight.bold,
              fontSize: 16,
              color: kNeutralColor,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            label,
            textAlign: TextAlign.center,
            style: kTextStyle.copyWith(color: kSubTitleColor, fontSize: 11),
          ),
        ],
      ),
    );
  }

  Widget _divider() => Container(
        width: 1,
        height: 36,
        color: kBorderColorTextField,
      );
}
