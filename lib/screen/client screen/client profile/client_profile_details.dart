import 'package:flutter/material.dart';
import 'package:flutter_iconly/flutter_iconly.dart';
import 'package:freelancer/core/utils/localized_category.dart';
import 'package:freelancer/core/utils/profile_avatar_picker.dart';
import 'package:freelancer/core/utils/profile_image.dart';
import 'package:freelancer/l10n/l10n.dart';
import 'package:freelancer/l10n/l10n_labels.dart';
import 'package:freelancer/services/job_posts_service.dart';
import 'package:freelancer/services/profile_service.dart';
import 'package:nb_utils/nb_utils.dart';

import '../../widgets/constant.dart';
import '../../widgets/editable_profile_avatar.dart';
import '../../widgets/profile_detail_theme.dart';
import '../../widgets/profile_rating_summary.dart';
import '../../widgets/profile_skeleton.dart';
import '../client job post/create_new_job_post.dart';
import '../client job post/job_details.dart';
import 'client_edit_profile_details.dart';

class ClientProfileDetails extends StatefulWidget {
  const ClientProfileDetails({super.key});

  @override
  State<ClientProfileDetails> createState() => _ClientProfileDetailsState();
}

class _ClientProfileDetailsState extends State<ClientProfileDetails> {
  Map<String, dynamic>? _profile;
  List<Map<String, dynamic>> _jobs = [];
  bool _isLoading = true;
  bool _uploadingPhoto = false;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    try {
      final results = await Future.wait([
        ProfileService.getProfile(forceRefresh: true),
        JobPostsService.getClientJobPosts(),
      ]);
      if (mounted) {
        setState(() {
          _profile = results[0] as Map<String, dynamic>?;
          _jobs = results[1] as List<Map<String, dynamic>>;
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

  static String _jobTypeLabel(AppLocalizations l10n, String? t) =>
      L10nLabels.jobTypeLabel(l10n, t);

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    if (_isLoading) {
      return const ProfileDetailsSkeleton(extraSection: false);
    }

    final name = _profile?['name'] ?? l10n.userName;
    final bio = _profile?['bio'] as String?;
    final city = (_profile?['city'] as String?) ?? '';
    final country = (_profile?['country'] as String?) ?? '';
    final profileImageUrl =
        ProfileImage.normalize(_profile?['profile_image_url'] as String?);
    final rating = (_profile?['rating'] as num?)?.toDouble() ?? 0;
    final reviewCount = (_profile?['review_count'] as num?)?.toInt() ?? 0;

    final totalJobs = _jobs.length;
    final openJobs = _jobs.where((j) => j['status'] == 'open').length;
    final closedJobs = totalJobs - openJobs;

    final locationParts = [city, country].where((s) => s.isNotEmpty).toList();
    final locationStr = locationParts.join(', ');

    Future<void> openEdit() async {
      await const ClientEditProfile().launch(context);
      await ProfileService.getProfile(forceRefresh: true);
      if (mounted) _load();
    }

    return Scaffold(
      backgroundColor: ProfileDetailTheme.scaffoldBg,
      appBar: AppBar(
        backgroundColor: ProfileDetailTheme.scaffoldBg,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        iconTheme: const IconThemeData(color: kNeutralColor),
        title: Text(
          l10n.appTitle,
          style: kTextStyle.copyWith(color: kPrimaryColor, fontWeight: FontWeight.bold),
        ),
        centerTitle: true,
        actions: [
          IconButton(
            tooltip: l10n.editProfile,
            onPressed: openEdit,
            icon: const Icon(IconlyBold.edit, size: 20, color: kPrimaryColor),
          ),
        ],
      ),
      body: RefreshIndicator(
        color: kPrimaryColor,
        onRefresh: _load,
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(parent: BouncingScrollPhysics()),
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  EditableProfileAvatar(
                    imageUrl: profileImageUrl,
                    size: 72,
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
                        if (locationStr.isNotEmpty) ...[
                          const SizedBox(height: 4),
                          Row(
                            children: [
                              const Icon(Icons.location_on_outlined, size: 13, color: kSecondaryColor),
                              const SizedBox(width: 3),
                              Flexible(
                                child: Text(
                                  locationStr,
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
                        if (reviewCount > 0) ...[
                          const SizedBox(height: 8),
                          ProfileRatingSummary(
                            rating: rating,
                            reviewCount: reviewCount,
                            compact: true,
                          ),
                        ],
                      ],
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 12),

              Container(
                padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 6),
                decoration: ProfileDetailTheme.statsPanel(),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    _statTile('$totalJobs', l10n.statPosted),
                    _statDivider(),
                    _statTile('$openJobs', l10n.open),
                    _statDivider(),
                    _statTile('$closedJobs', l10n.closed),
                  ],
                ),
              ),

              if (bio != null && bio.trim().isNotEmpty) ...[
                const SizedBox(height: 12),
                Text(
                  bio.trim(),
                  textAlign: TextAlign.start,
                  style: kTextStyle.copyWith(color: kSubTitleColor, height: 1.35),
                ),
              ],

              const SizedBox(height: 14),

              ProfileDetailTheme.sectionDivider(),
              const SizedBox(height: 10),

              Row(
                children: [
                  Text(
                    l10n.myJobPosts,
                    style: kTextStyle.copyWith(color: kPrimaryColor, fontWeight: FontWeight.bold),
                  ),
                  const Spacer(),
                  Text(
                    l10n.countTotal(totalJobs),
                    style: kTextStyle.copyWith(color: kLightNeutralColor),
                  ),
                ],
              ),
              const SizedBox(height: 8),

              if (_jobs.isEmpty)
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 8),
                  child: Column(
                    children: [
                      Icon(IconlyLight.paper, size: 36, color: kPrimaryColor.withValues(alpha: 0.45)),
                      const SizedBox(height: 6),
                      Text(
                        l10n.noJobsPostedYet,
                        style: kTextStyle.copyWith(color: kLightNeutralColor),
                      ),
                      const SizedBox(height: 10),
                      OutlinedButton.icon(
                        onPressed: () async {
                          await const CreateNewJobPost().launch(context);
                          _load();
                        },
                        style: ProfileDetailTheme.editProfileOutlinedStyle(),
                        icon: const Icon(Icons.add, size: 18, color: kPrimaryColor),
                        label: Text(
                          l10n.postAJob,
                          style: kTextStyle.copyWith(
                            color: kPrimaryColor,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ],
                  ),
                )
              else
                Column(
                  children: _jobs.map((j) => _jobCard(context, j)).toList(),
                ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _statTile(String value, String label) {
    return Expanded(
      child: Column(
        children: [
          Text(
            value,
            style: kTextStyle.copyWith(color: kPrimaryColor, fontWeight: FontWeight.bold, fontSize: 16),
          ),
          const SizedBox(height: 1),
          Text(label, style: kTextStyle.copyWith(color: kSubTitleColor, fontSize: 11)),
        ],
      ),
    );
  }

  Widget _statDivider() => Container(
        width: 1,
        height: 28,
        color: kPrimaryColor.withValues(alpha: 0.22),
        margin: const EdgeInsets.symmetric(horizontal: 4),
      );

  Widget _jobCard(BuildContext context, Map<String, dynamic> job) {
    final l10n = context.l10n;
    final category = job['categories'] as Map<String, dynamic>?;
    final isOpen = job['status'] == 'open';
    final (jobStatusFg, jobStatusBg) = StatusColors.jobPost(job['status'] as String?);
    final location = job['location'] as String?;

    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: GestureDetector(
        onTap: () async {
          await JobDetails(jobPostId: job['id'] as String).launch(context);
          _load();
        },
        child: Container(
          padding: const EdgeInsets.all(12),
          decoration: ProfileDetailTheme.cardOnPage(),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Expanded(
                    child: Text(
                      job['title'] ?? l10n.untitled,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: kTextStyle.copyWith(color: kNeutralColor, fontWeight: FontWeight.bold),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Container(
                    padding: const EdgeInsets.symmetric(vertical: 3, horizontal: 8),
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(20),
                      color: kPrimaryColor.withValues(alpha: 0.1),
                    ),
                    child: Text(
                      _jobTypeLabel(l10n, job['job_type'] as String?),
                      style: kTextStyle.copyWith(color: kPrimaryColor, fontSize: 12),
                    ),
                  ),
                ],
              ),
              if (location != null && location.isNotEmpty) ...[
                const SizedBox(height: 6),
                Row(
                  children: [
                    const Icon(Icons.location_on_outlined, size: 14, color: kSecondaryColor),
                    const SizedBox(width: 4),
                    Expanded(
                      child: Text(
                        location,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: kTextStyle.copyWith(color: kSubTitleColor, fontSize: 12),
                      ),
                    ),
                  ],
                ),
              ],
              const SizedBox(height: 6),
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(vertical: 2, horizontal: 8),
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(20),
                      color: jobStatusBg,
                    ),
                    child: Text(
                      isOpen ? l10n.open : l10n.closed,
                      style: kTextStyle.copyWith(
                        color: jobStatusFg,
                        fontSize: 11,
                      ),
                    ),
                  ),
                  const Spacer(),
                  Text(
                    LocalizedCategory.name(
                      category,
                      LocalizedCategory.languageCodeOf(context),
                      fallback: l10n.categoryGeneral,
                    ),
                    style: kTextStyle.copyWith(color: kLightNeutralColor, fontSize: 12),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
