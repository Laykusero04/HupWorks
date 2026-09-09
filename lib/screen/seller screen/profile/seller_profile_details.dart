import 'package:flutter/material.dart';
import 'package:freelancer/l10n/l10n.dart';
import 'package:freelancer/l10n/l10n_labels.dart';
import 'package:flutter_iconly/flutter_iconly.dart';
import 'package:freelancer/core/utils/app_date_format.dart';
import 'package:freelancer/core/utils/profile_avatar_picker.dart';
import 'package:freelancer/core/utils/profile_image.dart';
import 'package:freelancer/data/models/seller_skill_model.dart';
import 'package:freelancer/router/route_names.dart';
import 'package:freelancer/services/profile_service.dart';
import 'package:freelancer/services/verification_service.dart';
import 'package:go_router/go_router.dart';

import '../../widgets/constant.dart';
import '../../widgets/editable_profile_avatar.dart';
import '../../widgets/profile_detail_theme.dart';
import '../../widgets/profile_rating_summary.dart';
import '../../widgets/profile_skeleton.dart';
import '../../widgets/seller_skills_display.dart';
import '../../widgets/seller_standing_badge.dart';
import '../../widgets/verification_score_card.dart';
import '../../widgets/verification_status_badge.dart';

class SellerProfileDetails extends StatefulWidget {
  const SellerProfileDetails({Key? key}) : super(key: key);

  @override
  State<SellerProfileDetails> createState() => _SellerProfileDetailsState();
}

class _SellerProfileDetailsState extends State<SellerProfileDetails> {
  Map<String, dynamic>? _profile;
  List<Map<String, dynamic>> _reviews = [];
  List<SellerSkill> _skills = const [];
  bool _isLoading = true;
  bool _uploadingPhoto = false;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    try {
      final profile = await ProfileService.getSellerProfileForEdit();
      if (!mounted) return;
      final userId = profile?['id'] as String?;
      final reviews = userId != null
          ? await ProfileService.getReviewsReceived(userId)
          : <Map<String, dynamic>>[];
      if (!mounted) return;
      setState(() {
        _profile = profile;
        _reviews = reviews;
        _skills = profile != null ? ProfileService.sellerSkillsFromProfile(profile) : const [];
        _isLoading = false;
      });
    } catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(context.l10n.errorWithDetail('$e'))),
        );
      }
    }
  }

  Future<void> _changePhoto() async {
    final file = await ProfileAvatarPicker.pickAndCrop(context);
    if (file == null || !mounted) return;
    setState(() => _uploadingPhoto = true);
    try {
      final url = await ProfileService.uploadProfileImage(file);
      if (!mounted) return;
      setState(() {
        _profile = {
          ...?_profile,
          'profile_image_url': url,
        };
        _uploadingPhoto = false;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(context.l10n.profileUpdatedShort)),
      );
    } catch (e) {
      if (!mounted) return;
      setState(() => _uploadingPhoto = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(context.l10n.errorWithDetail('$e'))),
      );
    }
  }

  static String _formatReviewDate(String? iso, [String? locale]) =>
      AppDateFormat.tryMmmDY(iso, locale) ?? '';

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const ProfileDetailsSkeleton(extraSection: true);
    }

    final l10n = context.l10n;
    final name = _profile?['name'] ?? l10n.roleSeller;
    final email = (_profile?['email'] as String?) ?? '';
    final bio = _profile?['bio'] as String?;
    final profileImageUrl = _profile?['profile_image_url'];
    final jobTitle = _profile != null ? ProfileService.sellerJobTitleFromProfile(_profile!) : null;
    final about = _profile != null ? ProfileService.sellerAboutFromProfile(_profile!) : null;
    final address = _profile != null ? ProfileService.sellerAddressFromProfile(_profile!) : null;
    final age = _profile != null ? ProfileService.sellerAgeFromProfile(_profile!) : null;
    final reviewStats = ProfileService.resolveReviewDisplay(
      profile: _profile,
      reviews: _reviews,
    );
    final rating = reviewStats.rating;
    final reviewCount = reviewStats.count;
    final phone = _profile?['phone'] as String? ?? '';
    final genderRaw = _profile?['gender'] as String? ?? '';
    final gender = genderRaw.isEmpty
        ? ''
        : L10nLabels.gender(l10n, genderRaw);
    final verificationStatus =
        VerificationService.statusFromProfile(_profile);
    final verificationScore =
        VerificationService.scoreFromProfile(_profile);

    final avgLabel = reviewCount > 0 ? rating.toStringAsFixed(1) : '—';

    Future<void> openVerification() async {
      await context.push(AppRoutes.sellerProfileVerify);
      if (mounted) _load();
    }

    final brand = Theme.of(context).colorScheme.primary;
    final pageBg = Theme.of(context).scaffoldBackgroundColor;

    Future<void> openEdit() async {
      await context.push(AppRoutes.sellerProfileEdit);
      if (mounted) _load();
    }

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
            tooltip: l10n.editProfile,
            onPressed: openEdit,
            icon: Icon(IconlyBold.edit, size: 20, color: brand),
          ),
        ],
      ),
      body: RefreshIndicator(
        color: brand,
        onRefresh: _load,
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(parent: BouncingScrollPhysics()),
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Identity header: avatar + name stack + standing
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  EditableProfileAvatar(
                    imageUrl: ProfileImage.normalize(
                      profileImageUrl is String ? profileImageUrl : null,
                    ),
                    size: 72,
                    accent: brand,
                    uploading: _uploadingPhoto,
                    onTap: _changePhoto,
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
                            style: kTextStyle.copyWith(color: kSubTitleColor, fontSize: 13),
                          ),
                        ],
                        if (address != null && address.isNotEmpty) ...[
                          const SizedBox(height: 4),
                          Row(
                            children: [
                              const Icon(Icons.location_on_outlined, size: 13, color: kSellerAccent),
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
                              onTap: openVerification,
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
                padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 6),
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
                onTap: openVerification,
                compact: true,
              ),

              if (bio != null && bio.trim().isNotEmpty) ...[
                const SizedBox(height: 12),
                Text(
                  bio.trim(),
                  textAlign: TextAlign.start,
                  style: kTextStyle.copyWith(color: kSubTitleColor, height: 1.35),
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
                  style: kTextStyle.copyWith(color: kSubTitleColor, height: 1.35),
                ),
              ],

              if (_skills.isNotEmpty) ...[
                const SizedBox(height: 12),
                SellerSkillsDisplay(skills: _skills, accentColor: brand),
              ],

              const SizedBox(height: 14),

              ProfileDetailTheme.sectionDivider(
                gradientStart: brand,
                gradientEnd: kSellerAccent,
              ),
              const SizedBox(height: 10),

              Text(
                l10n.profileDetails,
                style: kTextStyle.copyWith(color: brand, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: ProfileDetailTheme.cardOnPage(accent: brand),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _detailRow(l10n.email, email),
                    _detailRow(l10n.phone, phone),
                    _detailRow(l10n.genderLabel, gender),
                    if (age != null) _detailRow(l10n.ageLabel, l10n.ageYearsOld(age)),
                    if (address != null && address.isNotEmpty)
                      _detailRow(l10n.address, address),
                  ],
                ),
              ),

              const SizedBox(height: 14),

              ProfileDetailTheme.sectionDivider(
                gradientStart: brand,
                gradientEnd: kSellerAccent,
              ),
              const SizedBox(height: 10),

              Row(
                children: [
                  Text(
                    l10n.reviews,
                    style: kTextStyle.copyWith(color: brand, fontWeight: FontWeight.bold),
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
                  padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 8),
                  child: Column(
                    children: [
                      Icon(IconlyBold.star, size: 36, color: brand.withValues(alpha: 0.45)),
                      const SizedBox(height: 6),
                      Text(
                        l10n.noReviewsYet,
                        style: kTextStyle.copyWith(color: kLightNeutralColor),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        l10n.reviewsFromClientsHint,
                        textAlign: TextAlign.center,
                        style: kTextStyle.copyWith(
                          color: kLightNeutralColor,
                          fontSize: 12,
                          height: 1.35,
                        ),
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
            style: kTextStyle.copyWith(color: accent, fontWeight: FontWeight.bold, fontSize: 16),
          ),
          const SizedBox(height: 1),
          Text(label, style: kTextStyle.copyWith(color: kSubTitleColor, fontSize: 11)),
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
            child: Text(label, style: kTextStyle.copyWith(color: kSubTitleColor, fontSize: 13)),
          ),
          Expanded(
            flex: 4,
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(':', style: kTextStyle.copyWith(color: kSubTitleColor, fontSize: 13)),
                const SizedBox(width: 8.0),
                Flexible(
                  child: Text(
                    v,
                    style: kTextStyle.copyWith(color: kSubTitleColor, fontSize: 13),
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

  Widget _reviewStarsRow(int ratingValue) {
    final v = ratingValue.clamp(0, 5);
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: List.generate(5, (i) {
        final filled = i < v;
        return Icon(
          filled ? Icons.star_rounded : Icons.star_outline_rounded,
          size: 18,
          color: filled ? ratingBarColor : kBorderColorTextField,
        );
      }),
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
                  ? Icon(Icons.person_rounded, color: brand.withValues(alpha: 0.55), size: 24)
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
                          style: kTextStyle.copyWith(color: kNeutralColor, fontWeight: FontWeight.bold),
                        ),
                      ),
                      if (dateStr.isNotEmpty)
                        Padding(
                          padding: const EdgeInsets.only(left: 8),
                          child: Text(
                            dateStr,
                            style: kTextStyle.copyWith(color: kLightNeutralColor, fontSize: 11),
                          ),
                        ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  _reviewStarsRow(stars),
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
