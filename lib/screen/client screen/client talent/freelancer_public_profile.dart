import 'package:flutter/material.dart';
import 'package:flutter_iconly/flutter_iconly.dart';
import 'package:freelancer/core/utils/app_date_format.dart';
import 'package:freelancer/core/utils/profile_image.dart';
import 'package:freelancer/l10n/l10n.dart';
import 'package:freelancer/screen/seller%20screen/seller%20message/chat_inbox.dart';
import 'package:freelancer/services/block_service.dart';
import 'package:freelancer/services/chat_service.dart';
import 'package:freelancer/services/client_home_service.dart';
import 'package:freelancer/services/profile_service.dart';
import 'package:freelancer/services/saved_talent_service.dart';
import 'package:freelancer/services/seller_work_trust_service.dart';
import 'package:freelancer/services/verification_service.dart';
import 'package:freelancer/data/models/seller_work_trust_model.dart';
import 'package:nb_utils/nb_utils.dart';

import '../../widgets/constant.dart';
import '../../widgets/profile_detail_theme.dart';
import '../../widgets/profile_rating_summary.dart';
import '../../widgets/profile_skeleton.dart';
import '../../widgets/seller_skills_display.dart';
import '../../widgets/seller_standing_badge.dart';
import '../../widgets/verification_score_card.dart';
import '../../widgets/verification_status_badge.dart';
import '../../widgets/verified_work_trust_section.dart';
import '../client report/client_report.dart';
import '../client service details/client_service_details.dart';

/// Client-facing view of a freelancer's public profile.
/// Layout matches [SellerProfileDetails] (compact header + stats + sections).
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
  bool _contactBlocked = false;
  List<Map<String, dynamic>> _reviews = [];
  SellerWorkTrust _workTrust = SellerWorkTrust.empty;
  bool _isLoading = true;
  bool _isSaved = false;
  bool _saveBusy = false;

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
        BlockService.isContactBlocked(widget.sellerId)
            .then((v) => v)
            .catchError((_) => false),
        SavedTalentService.isSaved(widget.sellerId).catchError((_) => false),
      ]);
      if (!mounted) return;
      setState(() {
        _profile = results[0] as Map<String, dynamic>?;
        _reviews = List<Map<String, dynamic>>.from(
          results[1] as List<dynamic>? ?? const [],
        );
        _workTrust = results[2] as SellerWorkTrust;
        _contactBlocked = results[3] as bool;
        _isSaved = results[4] as bool;
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

  Future<void> _toggleSaved() async {
    if (_saveBusy) return;
    setState(() => _saveBusy = true);
    try {
      final next = await SavedTalentService.toggle(widget.sellerId);
      if (!mounted) return;
      setState(() {
        _isSaved = next;
        _saveBusy = false;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            next
                ? context.l10n.addedToSavedTalent
                : context.l10n.removedFromSavedTalent,
          ),
        ),
      );
    } catch (e) {
      if (mounted) {
        setState(() => _saveBusy = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(context.l10n.errorWithDetail('$e'))),
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

  Future<void> _handleMessage() async {
    if (_contactBlocked) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(context.l10n.contactBlocked)),
      );
      return;
    }
    try {
      final conversation =
          await ChatService.getOrCreateConversation(widget.sellerId);
      if (!mounted || _profile == null) return;
      final profileImageUrl = _profile!['profile_image_url'] as String? ?? '';
      final name = _profile!['name'] as String? ??
          widget.initialName ??
          context.l10n.roleSeller;
      ChatInbox(
        conversationId: conversation['id'] as String,
        otherUserName: name,
        otherUserImage: profileImageUrl,
        otherUserId: widget.sellerId,
      ).launch(context);
    } catch (e) {
      if (mounted) {
        final msg = '$e'.contains('Contact blocked')
            ? context.l10n.contactBlocked
            : context.l10n.couldNotOpenChatWithDetail('$e');
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(msg)),
        );
      }
    }
  }

  static String _formatReviewDate(String? iso, [String? locale]) =>
      AppDateFormat.tryMmmDY(iso, locale) ?? '';

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Scaffold(
        body: ProfileDetailsSkeleton(extraSection: true),
      );
    }

    final l10n = context.l10n;
    final brand = Theme.of(context).colorScheme.primary;
    final pageBg = Theme.of(context).scaffoldBackgroundColor;

    if (_profile == null) {
      return Scaffold(
        backgroundColor: pageBg,
        appBar: AppBar(
          backgroundColor: pageBg,
          surfaceTintColor: Colors.transparent,
        ),
        body: Center(
          child: Text(
            l10n.freelancerNotFound,
            style: kTextStyle.copyWith(color: kSubTitleColor),
          ),
        ),
      );
    }

    final name =
        _profile!['name'] as String? ?? widget.initialName ?? l10n.roleSeller;
    final bio = _profile!['bio'] as String?;
    final profileImageUrl = _profile!['profile_image_url'] as String?;
    final jobTitle = ProfileService.sellerJobTitleFromProfile(_profile!);
    final verificationStatus =
        VerificationService.statusFromProfile(_profile);
    final verificationScore =
        VerificationService.scoreFromProfile(_profile);
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
      backgroundColor: pageBg,
      appBar: AppBar(
        backgroundColor: pageBg,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        iconTheme: const IconThemeData(color: kNeutralColor),
        title: Text(
          'HupWorks',
          style: kTextStyle.copyWith(color: brand, fontWeight: FontWeight.bold),
        ),
        centerTitle: true,
        actions: [
          IconButton(
            tooltip: _isSaved
                ? l10n.removedFromSavedTalent
                : l10n.favorite,
            onPressed: _saveBusy ? null : _toggleSaved,
            icon: Icon(
              _isSaved ? Icons.bookmark : Icons.bookmark_border,
              color: _isSaved ? brand : kNeutralColor,
            ),
          ),
          IconButton(
            tooltip: l10n.report,
            onPressed: () {
              ClientReport(
                reportedUserId: widget.sellerId,
                reportedUserName: name,
              ).launch(context);
            },
            icon: const Icon(Icons.flag_outlined, color: kNeutralColor),
          ),
        ],
      ),
      body: RefreshIndicator(
        color: brand,
        onRefresh: _load,
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(
            parent: BouncingScrollPhysics(),
          ),
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Compact header — same composition as seller My Profile
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    height: 72,
                    width: 72,
                    decoration: ProfileDetailTheme.avatarDecoration(
                      ProfileImage.provider(profileImageUrl),
                      accent: brand,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          name,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: kTextStyle.copyWith(
                            color: kNeutralColor,
                            fontWeight: FontWeight.bold,
                            fontSize: 18,
                          ),
                        ),
                        if (jobTitle != null && jobTitle.isNotEmpty) ...[
                          const SizedBox(height: 2),
                          Text(
                            jobTitle,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: kTextStyle.copyWith(
                              color: kSubTitleColor,
                              fontSize: 13,
                            ),
                          ),
                        ],
                        if (address != null && address.isNotEmpty) ...[
                          const SizedBox(height: 4),
                          Row(
                            children: [
                              Icon(
                                Icons.location_on_outlined,
                                size: 13,
                                color: brand,
                              ),
                              const SizedBox(width: 3),
                              Flexible(
                                child: Text(
                                  address,
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: kTextStyle.copyWith(
                                    color: kLightNeutralColor,
                                    fontSize: 12,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ],
                        const SizedBox(height: 8),
                        Wrap(
                          spacing: 8,
                          runSpacing: 6,
                          crossAxisAlignment: WrapCrossAlignment.center,
                          children: [
                            VerificationStatusBadge(
                              status: verificationStatus,
                              score: verificationScore,
                              compact: true,
                            ),
                            if (reviewCount > 0)
                              ProfileRatingSummary(
                                rating: rating,
                                reviewCount: reviewCount,
                                compact: true,
                                accentColor: brand,
                              ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 8),
                  SellerStandingBadge(
                    rating: rating,
                    reviewCount: reviewCount,
                    size: 36,
                    compact: true,
                  ),
                ],
              ),

              const SizedBox(height: 12),

              Container(
                padding:
                    const EdgeInsets.symmetric(vertical: 10, horizontal: 6),
                decoration: ProfileDetailTheme.statsPanel(accent: brand),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    _statTile('$reviewCount', l10n.reviews, brand),
                    _statDivider(brand),
                    _statTile(avgLabel, l10n.avgRating, brand),
                    _statDivider(brand),
                    _statTile(
                      '${verificationScore.total}',
                      l10n.trustScoreLabel,
                      brand,
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 10),

              VerificationScoreCard(
                score: verificationScore,
                accent: brand,
                compact: true,
              ),

              const SizedBox(height: 12),

              Row(
                children: [
                  Expanded(
                    child: SizedBox(
                      height: 44,
                      child: OutlinedButton(
                        onPressed: _contactBlocked ? null : _handleMessage,
                        style: OutlinedButton.styleFrom(
                          foregroundColor: brand,
                          side: BorderSide(color: brand),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(14),
                          ),
                        ),
                        child: Text(
                          _contactBlocked
                              ? l10n.contactBlockedShort
                              : l10n.message,
                          style: kTextStyle.copyWith(
                            color: brand,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: SizedBox(
                      height: 44,
                      child: FilledButton(
                        onPressed: _openService,
                        style: FilledButton.styleFrom(
                          backgroundColor: brand,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(14),
                          ),
                        ),
                        child: Text(
                          l10n.viewServices,
                          style: kTextStyle.copyWith(
                            color: kWhite,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              ),

              if (bio != null && bio.trim().isNotEmpty) ...[
                const SizedBox(height: 12),
                Text(
                  bio.trim(),
                  textAlign: TextAlign.start,
                  style: kTextStyle.copyWith(
                    color: kSubTitleColor,
                    height: 1.35,
                  ),
                ),
              ],

              if (about != null && about.isNotEmpty) ...[
                const SizedBox(height: 12),
                Text(
                  l10n.about,
                  style: kTextStyle.copyWith(
                    color: brand,
                    fontWeight: FontWeight.bold,
                    fontSize: 13,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  about,
                  textAlign: TextAlign.start,
                  style: kTextStyle.copyWith(
                    color: kSubTitleColor,
                    height: 1.35,
                  ),
                ),
              ],

              if (skills.isNotEmpty) ...[
                const SizedBox(height: 12),
                SellerSkillsDisplay(skills: skills, accentColor: brand),
              ],

              if (_workTrust.shouldShowSection) ...[
                const SizedBox(height: 14),
                VerifiedWorkTrustSection(trust: _workTrust),
              ],

              if (age != null ||
                  (address != null && address.isNotEmpty)) ...[
                const SizedBox(height: 14),
                ProfileDetailTheme.sectionDivider(
                  gradientStart: brand,
                  gradientEnd: kSecondaryColor,
                ),
                const SizedBox(height: 10),
                Text(
                  l10n.profileDetails,
                  style: kTextStyle.copyWith(
                    color: brand,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 8),
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: ProfileDetailTheme.cardOnPage(accent: brand),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      if (age != null)
                        _detailRow(l10n.ageLabel, l10n.ageYearsOld(age)),
                      if (address != null && address.isNotEmpty)
                        _detailRow(l10n.address, address),
                    ],
                  ),
                ),
              ],

              const SizedBox(height: 14),

              ProfileDetailTheme.sectionDivider(
                gradientStart: brand,
                gradientEnd: kSecondaryColor,
              ),
              const SizedBox(height: 10),

              Row(
                children: [
                  Text(
                    l10n.reviews,
                    style: kTextStyle.copyWith(
                      color: brand,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const Spacer(),
                  Text(
                    l10n.countTotal(reviewCount),
                    style: kTextStyle.copyWith(color: kLightNeutralColor),
                  ),
                ],
              ),
              const SizedBox(height: 8),

              if (_reviews.isEmpty)
                Padding(
                  padding:
                      const EdgeInsets.symmetric(vertical: 16, horizontal: 8),
                  child: Column(
                    children: [
                      Icon(
                        IconlyBold.star,
                        size: 36,
                        color: brand.withValues(alpha: 0.45),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        l10n.noReviewsYet,
                        style: kTextStyle.copyWith(color: kLightNeutralColor),
                      ),
                    ],
                  ),
                )
              else
                Column(
                  children: _reviews.map((r) => _reviewCard(r, brand)).toList(),
                ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _statTile(String value, String label, Color accent) {
    return Expanded(
      child: Column(
        children: [
          Text(
            value,
            style: kTextStyle.copyWith(
              color: accent,
              fontWeight: FontWeight.bold,
              fontSize: 16,
            ),
          ),
          const SizedBox(height: 1),
          Text(
            label,
            style: kTextStyle.copyWith(color: kSubTitleColor, fontSize: 11),
          ),
        ],
      ),
    );
  }

  Widget _statDivider(Color accent) => Container(
        width: 1,
        height: 28,
        color: accent.withValues(alpha: 0.22),
        margin: const EdgeInsets.symmetric(horizontal: 4),
      );

  Widget _detailRow(String label, String value) {
    final v = value.trim().isEmpty ? '—' : value;
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            flex: 2,
            child: Text(
              label,
              style: kTextStyle.copyWith(color: kSubTitleColor, fontSize: 13),
            ),
          ),
          Expanded(
            flex: 4,
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  ':',
                  style: kTextStyle.copyWith(
                    color: kSubTitleColor,
                    fontSize: 13,
                  ),
                ),
                const SizedBox(width: 8.0),
                Flexible(
                  child: Text(
                    v,
                    style: kTextStyle.copyWith(
                      color: kSubTitleColor,
                      fontSize: 13,
                    ),
                    overflow: TextOverflow.ellipsis,
                    maxLines: 3,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _reviewCard(Map<String, dynamic> row, Color brand) {
    final stars = ProfileService.ratingAsStars(row['rating']);
    final comment = (row['comment'] as String?)?.trim();
    final created = row['created_at'] as String?;
    final reviewer = row['reviewer'] as Map<String, dynamic>?;
    final reviewerName = (reviewer?['name'] as String?)?.trim();
    final imageUrl = (reviewer?['profile_image_url'] as String?)?.trim();
    final who = (reviewerName != null && reviewerName.isNotEmpty)
        ? reviewerName
        : context.l10n.roleClient;
    final dateStr = _formatReviewDate(created, AppDateFormat.localeOf(context));

    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(12),
        decoration: ProfileDetailTheme.cardOnPage(accent: brand),
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
                  ? Icon(
                      Icons.person_rounded,
                      color: brand.withValues(alpha: 0.55),
                      size: 24,
                    )
                  : null,
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(
                        child: Text(
                          who,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: kTextStyle.copyWith(
                            color: kNeutralColor,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                      if (dateStr.isNotEmpty)
                        Padding(
                          padding: const EdgeInsets.only(left: 8),
                          child: Text(
                            dateStr,
                            style: kTextStyle.copyWith(
                              color: kLightNeutralColor,
                              fontSize: 11,
                            ),
                          ),
                        ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Row(
                    children: List.generate(5, (i) {
                      return Icon(
                        i < stars
                            ? Icons.star_rounded
                            : Icons.star_outline_rounded,
                        size: 18,
                        color:
                            i < stars ? ratingBarColor : kBorderColorTextField,
                      );
                    }),
                  ),
                  if (comment != null && comment.isNotEmpty) ...[
                    const SizedBox(height: 8),
                    Text(
                      comment,
                      style: kTextStyle.copyWith(
                        color: kSubTitleColor,
                        height: 1.35,
                      ),
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
