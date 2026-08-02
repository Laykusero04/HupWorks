import 'package:flutter/material.dart';
import 'package:freelancer/l10n/l10n.dart';
import 'package:freelancer/services/client_home_service.dart';
import 'package:freelancer/services/profile_service.dart';
import 'package:freelancer/services/seller_work_trust_service.dart';
import 'package:freelancer/data/models/seller_work_trust_model.dart';
import 'package:nb_utils/nb_utils.dart';

import '../../widgets/constant.dart';
import '../../widgets/profile_detail_theme.dart';
import '../../widgets/profile_rating_summary.dart';
import '../../widgets/profile_skeleton.dart';
import '../../widgets/seller_skills_display.dart';
import '../../widgets/verified_work_trust_section.dart';
import '../client service details/client_service_details.dart';

/// Client-facing view of a freelancer's public profile.
class FreelancerPublicProfile extends StatefulWidget {
  const FreelancerPublicProfile({
    super.key,
    required this.sellerId,
    this.initialName,
  });

  final String sellerId;
  final String? initialName;

  @override
  State<FreelancerPublicProfile> createState() => _FreelancerPublicProfileState();
}

class _FreelancerPublicProfileState extends State<FreelancerPublicProfile> {
  Map<String, dynamic>? _profile;
  List<Map<String, dynamic>> _reviews = [];
  SellerWorkTrust _workTrust = SellerWorkTrust.empty;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    try {
      final results = await Future.wait([
        ProfileService.getPublicSellerProfile(widget.sellerId),
        ProfileService.getReviewsReceived(widget.sellerId),
        SellerWorkTrustService.getPublicWorkTrust(widget.sellerId),
      ]);
      if (!mounted) return;
      setState(() {
        _profile = results[0] as Map<String, dynamic>?;
        _reviews = List<Map<String, dynamic>>.from(results[1] as List<dynamic>? ?? const []);
        _workTrust = results[2] as SellerWorkTrust;
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

  Future<void> _openService() async {
    final serviceId =
        await ClientHomeService.getFirstActiveServiceIdForSeller(widget.sellerId);
    if (!mounted) return;
    if (serviceId != null) {
      await ClientServiceDetails(serviceId: serviceId).launch(context);
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(context.l10n.noActiveServiceListing)),
      );
    }
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
            'Freelancer not found',
            style: kTextStyle.copyWith(color: kSubTitleColor),
          ),
        ),
      );
    }

    final name = _profile!['name'] as String? ?? widget.initialName ?? 'Freelancer';
    final bio = _profile!['bio'] as String?;
    final profileImageUrl = _profile!['profile_image_url'] as String?;
    final jobTitle = ProfileService.sellerJobTitleFromProfile(_profile!);
    final about = ProfileService.sellerAboutFromProfile(_profile!);
    final address = ProfileService.sellerAddressFromProfile(_profile!);
    final age = ProfileService.sellerAgeFromProfile(_profile!);
    final skills = ProfileService.sellerSkillsFromProfile(_profile!);
    final reviewStats = ProfileService.resolveReviewDisplay(
      profile: _profile,
      reviews: _reviews,
    );
    final rating = reviewStats.rating;
    final reviewCount = reviewStats.count;
    final avgLabel = reviewCount > 0 ? rating.toStringAsFixed(1) : '—';

    return Scaffold(
      backgroundColor: kDarkWhite,
      appBar: AppBar(
        backgroundColor: kDarkWhite,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        iconTheme: const IconThemeData(color: kNeutralColor),
        title: Text(
          'Freelancer profile',
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
                        : const AssetImage('images/dev1.png'),
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
              if (jobTitle != null && jobTitle.isNotEmpty) ...[
                const SizedBox(height: 6),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 24),
                  child: Text(
                    jobTitle,
                    textAlign: TextAlign.center,
                    style: kTextStyle.copyWith(color: kSubTitleColor, fontSize: 14),
                  ),
                ),
              ],
              if (address != null && address.isNotEmpty) ...[
                const SizedBox(height: 8),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 24),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(Icons.location_on_outlined, size: 14, color: kPrimaryColor),
                      const SizedBox(width: 4),
                      Flexible(
                        child: Text(
                          address,
                          textAlign: TextAlign.center,
                          style: kTextStyle.copyWith(color: kLightNeutralColor),
                        ),
                      ),
                    ],
                  ),
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
                      _stat('$reviewCount', 'Reviews'),
                      _divider(),
                      _stat(avgLabel, 'Avg rating'),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 16),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 24),
                child: SizedBox(
                  width: double.infinity,
                  height: 48,
                  child: FilledButton(
                    onPressed: _openService,
                    style: FilledButton.styleFrom(
                      backgroundColor: kPrimaryColor,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14),
                      ),
                    ),
                    child: Text(
                      'View services',
                      style: kTextStyle.copyWith(
                        color: kWhite,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ),
              ),
              if (bio != null && bio.trim().isNotEmpty) ...[
                const SizedBox(height: 16),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 24),
                  child: Text(
                    bio.trim(),
                    textAlign: TextAlign.center,
                    style: kTextStyle.copyWith(color: kSubTitleColor),
                  ),
                ),
              ],
              if (about != null && about.isNotEmpty) ...[
                const SizedBox(height: 16),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 24),
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
                      Text(about, style: kTextStyle.copyWith(color: kSubTitleColor)),
                    ],
                  ),
                ),
              ],
              if (skills.isNotEmpty) ...[
                const SizedBox(height: 16),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 24),
                  child: SellerSkillsDisplay(skills: skills, accentColor: kPrimaryColor),
                ),
              ],
              if (_workTrust.shouldShowSection) ...[
                const SizedBox(height: 24),
                VerifiedWorkTrustSection(trust: _workTrust),
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
                        color: kPrimaryColor,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const Spacer(),
                    Text(
                      '$reviewCount total',
                      style: kTextStyle.copyWith(color: kLightNeutralColor),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 12),
              if (_reviews.isEmpty)
                Padding(
                  padding: const EdgeInsets.all(24),
                  child: Text(
                    'No reviews yet',
                    textAlign: TextAlign.center,
                    style: kTextStyle.copyWith(color: kLightNeutralColor),
                  ),
                )
              else
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: Column(
                    children: _reviews.map(_reviewCard).toList(),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _stat(String value, String label) {
    return Column(
      children: [
        Text(
          value,
          style: kTextStyle.copyWith(
            color: kPrimaryColor,
            fontWeight: FontWeight.bold,
            fontSize: 18,
          ),
        ),
        const SizedBox(height: 2),
        Text(label, style: kTextStyle.copyWith(color: kSubTitleColor, fontSize: 12)),
      ],
    );
  }

  Widget _divider() => Container(
        width: 1,
        height: 36,
        color: kPrimaryColor.withValues(alpha: 0.22),
        margin: const EdgeInsets.symmetric(horizontal: 32),
      );

  Widget _reviewCard(Map<String, dynamic> row) {
    final stars = ProfileService.ratingAsStars(row['rating']);
    final comment = (row['comment'] as String?)?.trim();
    final created = row['created_at'] as String?;
    final reviewer = row['reviewer'] as Map<String, dynamic>?;
    final reviewerName = (reviewer?['name'] as String?)?.trim();
    final imageUrl = (reviewer?['profile_image_url'] as String?)?.trim();
    final who =
        (reviewerName != null && reviewerName.isNotEmpty) ? reviewerName : 'Client';
    final dateStr = _formatReviewDate(created);

    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: ProfileDetailTheme.cardOnPage(accent: kPrimaryColor),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            CircleAvatar(
              radius: 22,
              backgroundColor: kDarkWhite,
              backgroundImage: imageUrl != null && imageUrl.isNotEmpty
                  ? NetworkImage(imageUrl) as ImageProvider
                  : null,
              child: imageUrl == null || imageUrl.isEmpty
                  ? Icon(Icons.person_rounded,
                      color: kPrimaryColor.withValues(alpha: 0.55))
                  : null,
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          who,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: kTextStyle.copyWith(fontWeight: FontWeight.bold),
                        ),
                      ),
                      if (dateStr.isNotEmpty)
                        Text(
                          dateStr,
                          style: kTextStyle.copyWith(
                            color: kLightNeutralColor,
                            fontSize: 11,
                          ),
                        ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Row(
                    children: List.generate(5, (i) {
                      return Icon(
                        i < stars ? Icons.star_rounded : Icons.star_outline_rounded,
                        size: 16,
                        color: i < stars ? ratingBarColor : kBorderColorTextField,
                      );
                    }),
                  ),
                  if (comment != null && comment.isNotEmpty) ...[
                    const SizedBox(height: 8),
                    Text(
                      comment,
                      style: kTextStyle.copyWith(color: kSubTitleColor, height: 1.35),
                    ),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Opens [FreelancerPublicProfile] for a talent card tap.
void openFreelancerPublicProfile(
  BuildContext context, {
  required String sellerId,
  String? name,
}) {
  FreelancerPublicProfile(
    sellerId: sellerId,
    initialName: name,
  ).launch(context);
}
