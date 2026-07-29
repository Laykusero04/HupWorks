import 'package:flutter/material.dart';
import 'package:freelancer/l10n/l10n.dart';
import 'package:freelancer/l10n/l10n_labels.dart';
import 'package:flutter_iconly/flutter_iconly.dart';
import 'package:freelancer/data/models/seller_skill_model.dart';
import 'package:freelancer/services/profile_service.dart';
import 'package:nb_utils/nb_utils.dart';

import '../../widgets/constant.dart';
import '../../widgets/profile_detail_theme.dart';
import '../../widgets/profile_rating_summary.dart';
import '../../widgets/profile_skeleton.dart';
import '../../widgets/seller_skills_display.dart';
import 'seller_edit_profile_details.dart';

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
      if (mounted) setState(() => _isLoading = false);
    }
  }

  static String _formatReviewDate(String? iso) {
    if (iso == null || iso.isEmpty) return '';
    final d = DateTime.tryParse(iso);
    if (d == null) return '';
    const months = ['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', 'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'];
    return '${months[d.month - 1]} ${d.day}, ${d.year}';
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const ProfileDetailsSkeleton(extraSection: true);
    }

    final name = _profile?['name'] ?? 'Seller';
    final email = (_profile?['email'] as String?) ?? '';
    final bio = _profile?['bio'] as String?;
    final balance = _profile?['balance'] ?? 0;
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
    final gender = _profile?['gender'] as String? ?? '';

    final avgLabel = reviewCount > 0 ? rating.toStringAsFixed(1) : '—';

    final brand = Theme.of(context).colorScheme.primary;
    final pageBg = Theme.of(context).scaffoldBackgroundColor;

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
      ),
      body: RefreshIndicator(
        color: brand,
        onRefresh: _load,
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(parent: BouncingScrollPhysics()),
          child: Column(
            children: [
              const SizedBox(height: 16.0),

              Container(
                height: 110,
                width: 110,
                decoration: ProfileDetailTheme.avatarDecoration(
                  profileImageUrl != null
                      ? NetworkImage(profileImageUrl) as ImageProvider
                      : const AssetImage('images/profile3.png'),
                  accent: brand,
                ),
              ),
              const SizedBox(height: 10.0),

              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 24),
                child: Text(
                  name,
                  textAlign: TextAlign.center,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: kTextStyle.copyWith(
                    color: kNeutralColor,
                    fontWeight: FontWeight.bold,
                    fontSize: 20,
                  ),
                ),
              ),

              if (jobTitle != null && jobTitle.isNotEmpty) ...[
                const SizedBox(height: 6.0),
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
                const SizedBox(height: 8.0),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 24),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(Icons.location_on_outlined, size: 14, color: kSellerAccent),
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

              const SizedBox(height: 10.0),
              Center(
                child: ProfileRatingSummary(
                  rating: rating,
                  reviewCount: reviewCount,
                  compact: false,
                  accentColor: brand,
                ),
              ),

              const SizedBox(height: 18.0),

              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Container(
                  padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 8),
                  decoration: ProfileDetailTheme.statsPanel(accent: brand),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      _statTile('$reviewCount', 'Reviews', brand),
                      _statDivider(brand),
                      _statTile(avgLabel, 'Avg rating', brand),
                      _statDivider(brand),
                      _statTile('$currencySign$balance', 'Balance', brand),
                    ],
                  ),
                ),
              ),

              const SizedBox(height: 18.0),

              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 30),
                child: SizedBox(
                  width: double.infinity,
                  child: OutlinedButton.icon(
                    onPressed: () async {
                      await const SellerEditProfile().launch(context);
                      _load();
                    },
                    icon: Icon(IconlyBold.edit, size: 18, color: brand),
                    label: Text(
                      'Edit profile',
                      style: kTextStyle.copyWith(color: brand, fontWeight: FontWeight.bold),
                    ),
                    style: ProfileDetailTheme.editProfileOutlinedStyle(accent: brand),
                  ),
                ),
              ),

              if (bio != null && bio.trim().isNotEmpty) ...[
                const SizedBox(height: 16.0),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 30),
                  child: Text(
                    bio.trim(),
                    textAlign: TextAlign.center,
                    style: kTextStyle.copyWith(color: kSubTitleColor),
                  ),
                ),
              ],

              if (about != null && about.isNotEmpty) ...[
                const SizedBox(height: 16.0),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 30),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Text(
                        'About',
                        textAlign: TextAlign.center,
                        style: kTextStyle.copyWith(
                          color: brand,
                          fontWeight: FontWeight.bold,
                          fontSize: 13,
                        ),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        about,
                        textAlign: TextAlign.center,
                        style: kTextStyle.copyWith(color: kSubTitleColor),
                      ),
                    ],
                  ),
                ),
              ],

              if (_skills.isNotEmpty) ...[
                const SizedBox(height: 16.0),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 30),
                  child: SellerSkillsDisplay(skills: _skills, accentColor: brand),
                ),
              ],

              const SizedBox(height: 22.0),

              ProfileDetailTheme.sectionDivider(
                gradientStart: brand,
                gradientEnd: kSellerAccent,
              ),
              const SizedBox(height: 16.0),

              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: Row(
                  children: [
                    Text(
                      'Profile details',
                      style: kTextStyle.copyWith(color: brand, fontWeight: FontWeight.bold),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 12.0),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 12),
                child: Container(
                  padding: const EdgeInsets.all(14),
                  decoration: ProfileDetailTheme.cardOnPage(accent: brand),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _detailRow('Email', email),
                      _detailRow('Phone', phone),
                      _detailRow('Gender', gender),
                      if (age != null) _detailRow('Age', '$age years old'),
                      if (address != null && address.isNotEmpty) _detailRow('Address', address),
                    ],
                  ),
                ),
              ),

              const SizedBox(height: 22.0),

              ProfileDetailTheme.sectionDivider(
                gradientStart: brand,
                gradientEnd: kSellerAccent,
              ),
              const SizedBox(height: 16.0),

              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: Row(
                  children: [
                    Text(
                      'Reviews',
                      style: kTextStyle.copyWith(color: brand, fontWeight: FontWeight.bold),
                    ),
                    const Spacer(),
                    Text('$reviewCount total', style: kTextStyle.copyWith(color: kLightNeutralColor)),
                  ],
                ),
              ),
              const SizedBox(height: 12.0),

              if (_reviews.isEmpty)
                Padding(
                  padding: const EdgeInsets.all(30),
                  child: Column(
                    children: [
                      Icon(IconlyBold.star, size: 48, color: brand.withValues(alpha: 0.45)),
                      const SizedBox(height: 8),
                      Text(
                        'No reviews yet',
                        style: kTextStyle.copyWith(color: kLightNeutralColor),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        'Reviews from clients appear here after completed orders.',
                        textAlign: TextAlign.center,
                        style: kTextStyle.copyWith(color: kLightNeutralColor, fontSize: 12, height: 1.35),
                      ),
                    ],
                  ),
                )
              else
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 15),
                  child: Column(
                    children: _reviews.map((r) => _reviewCard(r, brand)).toList(),
                  ),
                ),

              const SizedBox(height: 36),
            ],
          ),
        ),
      ),
    );
  }

  Widget _statTile(String value, String label, Color accent) {
    return Column(
      children: [
        Text(
          value,
          style: kTextStyle.copyWith(color: accent, fontWeight: FontWeight.bold, fontSize: 18),
        ),
        const SizedBox(height: 2),
        Text(label, style: kTextStyle.copyWith(color: kSubTitleColor, fontSize: 12)),
      ],
    );
  }

  Widget _statDivider(Color accent) => Container(
        width: 1,
        height: 36,
        color: accent.withValues(alpha: 0.22),
        margin: const EdgeInsets.symmetric(horizontal: 24),
      );

  Widget _detailRow(String label, String value) {
    final v = value.trim().isEmpty ? '—' : value;
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            flex: 2,
            child: Text(label, style: kTextStyle.copyWith(color: kSubTitleColor)),
          ),
          Expanded(
            flex: 4,
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(':', style: kTextStyle.copyWith(color: kSubTitleColor)),
                const SizedBox(width: 10.0),
                Flexible(
                  child: Text(
                    v,
                    style: kTextStyle.copyWith(color: kSubTitleColor),
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
    final who = (reviewerName != null && reviewerName.isNotEmpty) ? reviewerName : 'Client';
    final dateStr = _formatReviewDate(created);

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
