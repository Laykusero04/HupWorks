import 'package:flutter/material.dart';
import 'package:flutter_iconly/flutter_iconly.dart';
import 'package:freelancer/services/job_posts_service.dart';
import 'package:freelancer/services/profile_service.dart';
import 'package:nb_utils/nb_utils.dart';

import '../../widgets/constant.dart';
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

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    try {
      final results = await Future.wait([
        ProfileService.getProfile(),
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
      if (mounted) setState(() => _isLoading = false);
    }
  }

  static String _jobTypeLabel(String? t) {
    switch (t) {
      case 'full_time':
        return 'Full-time';
      case 'part_time':
        return 'Part-time';
      case 'gig':
      default:
        return 'Gig';
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Scaffold(
        backgroundColor: kWhite,
        body: Center(child: CircularProgressIndicator(color: kPrimaryColor)),
      );
    }

    final name = _profile?['name'] ?? 'User';
    final email = (_profile?['email'] as String?) ?? '';
    final bio = _profile?['bio'] as String?;
    final city = (_profile?['city'] as String?) ?? '';
    final country = (_profile?['country'] as String?) ?? '';
    final balance = _profile?['balance'] ?? 0;
    final profileImageUrl = _profile?['profile_image_url'];

    final totalJobs = _jobs.length;
    final openJobs = _jobs.where((j) => j['status'] == 'open').length;

    final locationParts = [city, country].where((s) => s.isNotEmpty).toList();
    final locationStr = locationParts.join(', ');

    return Scaffold(
      backgroundColor: kWhite,
      appBar: AppBar(
        backgroundColor: kWhite,
        elevation: 0,
        iconTheme: const IconThemeData(color: kNeutralColor),
        title: Text(
          name,
          style: kTextStyle.copyWith(color: kNeutralColor, fontWeight: FontWeight.bold),
        ),
        centerTitle: true,
      ),
      body: RefreshIndicator(
        color: kPrimaryColor,
        onRefresh: _load,
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(parent: BouncingScrollPhysics()),
          child: Column(
            children: [
              const SizedBox(height: 16.0),

              // Avatar
              Container(
                height: 110,
                width: 110,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(color: kBorderColorTextField, width: 2),
                  image: DecorationImage(
                    image: profileImageUrl != null
                        ? NetworkImage(profileImageUrl) as ImageProvider
                        : const AssetImage('images/profile3.png'),
                    fit: BoxFit.cover,
                  ),
                ),
              ),
              const SizedBox(height: 10.0),

              // @-style handle (uses email's local-part to mimic TikTok handles)
              if (email.isNotEmpty)
                Text(
                  '@${email.split('@').first}',
                  style: kTextStyle.copyWith(color: kNeutralColor, fontWeight: FontWeight.bold),
                ),

              if (locationStr.isNotEmpty) ...[
                const SizedBox(height: 4.0),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(Icons.location_on_outlined, size: 14, color: kLightNeutralColor),
                    const SizedBox(width: 4),
                    Text(locationStr, style: kTextStyle.copyWith(color: kLightNeutralColor)),
                  ],
                ),
              ],

              const SizedBox(height: 18.0),

              // Stats row (TikTok-style 3-column)
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  _statTile('$totalJobs', 'Posted'),
                  _statDivider(),
                  _statTile('$openJobs', 'Open'),
                  _statDivider(),
                  _statTile('$currencySign$balance', 'Balance'),
                ],
              ),

              const SizedBox(height: 18.0),

              // Edit profile button
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 30),
                child: SizedBox(
                  width: double.infinity,
                  child: OutlinedButton.icon(
                    onPressed: () async {
                      await const ClientEditProfile().launch(context);
                      _load();
                    },
                    icon: const Icon(IconlyBold.edit, size: 16, color: kNeutralColor),
                    label: Text(
                      'Edit profile',
                      style: kTextStyle.copyWith(color: kNeutralColor, fontWeight: FontWeight.bold),
                    ),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: kNeutralColor,
                      side: const BorderSide(color: kBorderColorTextField),
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                    ),
                  ),
                ),
              ),

              // Bio
              if (bio != null && bio.trim().isNotEmpty) ...[
                const SizedBox(height: 16.0),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 30),
                  child: Text(
                    bio,
                    textAlign: TextAlign.center,
                    style: kTextStyle.copyWith(color: kSubTitleColor),
                  ),
                ),
              ],

              const SizedBox(height: 22.0),

              // Tab divider (TikTok-style underline)
              Container(
                margin: const EdgeInsets.symmetric(horizontal: 80),
                height: 2,
                color: kNeutralColor,
              ),
              const SizedBox(height: 16.0),

              // Section header
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: Row(
                  children: [
                    Text(
                      'My Job Posts',
                      style: kTextStyle.copyWith(color: kNeutralColor, fontWeight: FontWeight.bold),
                    ),
                    const Spacer(),
                    Text('$totalJobs total', style: kTextStyle.copyWith(color: kLightNeutralColor)),
                  ],
                ),
              ),
              const SizedBox(height: 12.0),

              // Jobs list (or empty state)
              if (_jobs.isEmpty)
                Padding(
                  padding: const EdgeInsets.all(30),
                  child: Column(
                    children: [
                      const Icon(IconlyLight.paper, size: 48, color: kLightNeutralColor),
                      const SizedBox(height: 8),
                      Text('No jobs posted yet', style: kTextStyle.copyWith(color: kLightNeutralColor)),
                      const SizedBox(height: 12),
                      OutlinedButton.icon(
                        onPressed: () async {
                          await const CreateNewJobPost().launch(context);
                          _load();
                        },
                        icon: const Icon(Icons.add, size: 16),
                        label: const Text('Post a job'),
                      ),
                    ],
                  ),
                )
              else
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 15),
                  child: Column(
                    children: _jobs.map(_jobCard).toList(),
                  ),
                ),

              const SizedBox(height: 30),
            ],
          ),
        ),
      ),
    );
  }

  Widget _statTile(String value, String label) {
    return Column(
      children: [
        Text(
          value,
          style: kTextStyle.copyWith(color: kNeutralColor, fontWeight: FontWeight.bold, fontSize: 18),
        ),
        const SizedBox(height: 2),
        Text(label, style: kTextStyle.copyWith(color: kLightNeutralColor, fontSize: 12)),
      ],
    );
  }

  Widget _statDivider() => Container(
        width: 1,
        height: 36,
        color: kBorderColorTextField,
        margin: const EdgeInsets.symmetric(horizontal: 24),
      );

  Widget _jobCard(Map<String, dynamic> job) {
    final category = job['categories'] as Map<String, dynamic>?;
    final isOpen = job['status'] == 'open';
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
          decoration: BoxDecoration(
            color: kWhite,
            borderRadius: BorderRadius.circular(10),
            border: Border.all(color: kBorderColorTextField),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Expanded(
                    child: Text(
                      job['title'] ?? 'Untitled',
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
                      color: kPrimaryColor.withOpacity(0.1),
                    ),
                    child: Text(
                      _jobTypeLabel(job['job_type'] as String?),
                      style: kTextStyle.copyWith(color: kPrimaryColor, fontSize: 12),
                    ),
                  ),
                ],
              ),
              if (location != null && location.isNotEmpty) ...[
                const SizedBox(height: 6),
                Row(
                  children: [
                    const Icon(Icons.location_on_outlined, size: 14, color: kLightNeutralColor),
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
                      color: isOpen ? kPrimaryColor.withOpacity(0.1) : kDarkWhite,
                    ),
                    child: Text(
                      isOpen ? 'Open' : 'Closed',
                      style: kTextStyle.copyWith(
                        color: isOpen ? kPrimaryColor : kNeutralColor,
                        fontSize: 11,
                      ),
                    ),
                  ),
                  const Spacer(),
                  Text(
                    category?['name'] ?? 'General',
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
