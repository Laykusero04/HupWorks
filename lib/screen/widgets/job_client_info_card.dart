import 'package:flutter/material.dart';
import 'package:freelancer/screen/client%20screen/client%20talent/client_public_profile.dart';
import 'package:freelancer/services/profile_service.dart';
import 'package:nb_utils/nb_utils.dart';

import 'constant.dart';
import 'profile_rating_summary.dart';

/// Client summary on seller "find jobs" job details (rating, jobs posted, member since).
class JobClientInfoCard extends StatelessWidget {
  final Map<String, dynamic>? clientProfile;
  final String? clientId;
  final double? rating;
  final int? reviewCount;
  final int? jobPostsCount;
  final String? memberSince;

  const JobClientInfoCard({
    super.key,
    this.clientProfile,
    this.clientId,
    this.rating,
    this.reviewCount,
    this.jobPostsCount,
    this.memberSince,
  });

  factory JobClientInfoCard.fromJobPost(Map<String, dynamic>? jobPost) {
    final client = jobPost?['profiles'];
    final Map<String, dynamic>? profile =
        client is Map<String, dynamic> ? client : null;
    final id = (profile?['id'] ?? jobPost?['client_id'])?.toString();

    String? since;
    final created = profile?['created_at'] as String?;
    if (created != null) {
      final d = DateTime.tryParse(created);
      if (d != null) {
        const m = [
          'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
          'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec',
        ];
        since = '${m[d.month - 1]} ${d.year}';
      }
    }

    return JobClientInfoCard(
      clientProfile: profile,
      clientId: id,
      rating: ProfileService.parseRatingValue(
        jobPost?['client_rating'] ?? profile?['rating'],
      ),
      reviewCount: (jobPost?['client_review_count'] as num?)?.toInt() ??
          (profile?['review_count'] as num?)?.toInt(),
      jobPostsCount: (jobPost?['client_job_posts_count'] as num?)?.toInt() ??
          (profile?['job_posts_count'] as num?)?.toInt(),
      memberSince: since,
    );
  }

  void _openProfile(BuildContext context) {
    final id = clientId;
    if (id == null || id.isEmpty) return;
    ClientPublicProfile(
      clientId: id,
      initialName: clientProfile?['name'] as String?,
    ).launch(context);
  }

  @override
  Widget build(BuildContext context) {
    final name = clientProfile?['name'] as String? ?? 'Client';
    final imageUrl = clientProfile?['profile_image_url'] as String?;
    final city = (clientProfile?['city'] as String?)?.trim() ?? '';
    final country = (clientProfile?['country'] as String?)?.trim() ?? '';
    final location = [city, country].where((s) => s.isNotEmpty).join(', ');
    final r = rating ?? 0.0;
    final reviews = reviewCount ?? 0;
    final jobs = jobPostsCount ?? 0;

    return Material(
      color: kPrimaryColor.withValues(alpha: 0.05),
      borderRadius: BorderRadius.circular(10),
      child: InkWell(
        onTap: clientId != null ? () => _openProfile(context) : null,
        borderRadius: BorderRadius.circular(10),
        child: Container(
          width: double.infinity,
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(10),
            border: Border.all(color: kBorderColorTextField),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  CircleAvatar(
                    radius: 22,
                    backgroundImage: imageUrl != null && imageUrl.isNotEmpty
                        ? NetworkImage(imageUrl)
                        : const AssetImage('images/profile1.png') as ImageProvider,
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          name,
                          style: kTextStyle.copyWith(
                            color: kNeutralColor,
                            fontWeight: FontWeight.bold,
                            fontSize: 15,
                          ),
                        ),
                        if (location.isNotEmpty)
                          Text(
                            location,
                            style: kTextStyle.copyWith(
                              color: kSubTitleColor,
                              fontSize: 12,
                            ),
                          ),
                        ProfileRatingSummary(
                          rating: r,
                          reviewCount: reviews,
                          compact: true,
                          accentColor: kPrimaryColor,
                        ),
                      ],
                    ),
                  ),
                  if (clientId != null)
                    const Icon(Icons.chevron_right, color: kPrimaryColor),
                ],
              ),
              const SizedBox(height: 10),
              Container(
                decoration: BoxDecoration(
                  color: kWhite,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: kBorderColorTextField),
                ),
                clipBehavior: Clip.antiAlias,
                child: IntrinsicHeight(
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Expanded(
                        child: _StatCell(
                          label: 'Rating',
                          value: reviews > 0 ? r.toStringAsFixed(1) : '—',
                        ),
                      ),
                      Container(width: 1, color: kBorderColorTextField),
                      Expanded(
                        child: _StatCell(
                          label: 'Jobs posted',
                          value: '$jobs',
                        ),
                      ),
                      Container(width: 1, color: kBorderColorTextField),
                      Expanded(
                        child: _StatCell(
                          label: 'Member since',
                          value: memberSince ?? '—',
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              if (clientId != null) ...[
                const SizedBox(height: 6),
                Text(
                  'Tap to view full client profile',
                  style: kTextStyle.copyWith(
                    color: kPrimaryColor,
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

class _StatCell extends StatelessWidget {
  final String label;
  final String value;

  const _StatCell({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 10),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: kTextStyle.copyWith(color: kSubTitleColor, fontSize: 10),
          ),
          const SizedBox(height: 4),
          Text(
            value,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: kTextStyle.copyWith(
              color: kNeutralColor,
              fontWeight: FontWeight.w700,
              fontSize: 13,
            ),
          ),
        ],
      ),
    );
  }
}
