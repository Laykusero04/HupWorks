import 'package:flutter/material.dart';
import 'package:flutter_feather_icons/flutter_feather_icons.dart';
import 'package:freelancer/screen/widgets/constant.dart';
import 'package:freelancer/services/job_posts_service.dart';
import 'package:nb_utils/nb_utils.dart';

import '../../../router/app_router.dart';
import '../../widgets/shell_tab_header.dart';
import 'create_new_job_post.dart';
import 'job_details.dart';

class JobPost extends StatefulWidget {
  const JobPost({Key? key}) : super(key: key);

  @override
  State<JobPost> createState() => _JobPostState();
}

class _JobPostState extends State<JobPost> {
  List<Map<String, dynamic>> _jobPosts = [];
  bool _isLoading = true;
  String? _typeFilter; // null = all

  /// Tail padding for scroll content above the tab bar + FAB.
  static const double _scrollEndPadding = 24;

  static const _filterOptions = <Map<String, String?>>[
    {'value': null, 'label': 'All'},
    {'value': 'gig', 'label': 'Gig'},
    {'value': 'full_time', 'label': 'Full-time'},
    {'value': 'part_time', 'label': 'Part-time'},
  ];

  static String _jobTypeLabel(String? type) {
    switch (type) {
      case 'full_time':
        return 'Full-time';
      case 'part_time':
        return 'Part-time';
      case 'gig':
      default:
        return 'Gig';
    }
  }

  List<Map<String, dynamic>> get _visibleJobPosts {
    if (_typeFilter == null) return _jobPosts;
    return _jobPosts.where((j) => j['job_type'] == _typeFilter).toList();
  }

  @override
  void initState() {
    super.initState();
    _loadJobPosts();
  }

  Future<void> _loadJobPosts() async {
    try {
      final posts = await JobPostsService.getClientJobPosts();
      if (mounted) {
        setState(() {
          _jobPosts = posts;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error loading job posts: $e')),
        );
      }
    }
  }

  String _formatDate(String? dateStr) {
    if (dateStr == null) return '';
    final date = DateTime.tryParse(dateStr);
    if (date == null) return '';
    const months = [
      'Jan',
      'Feb',
      'Mar',
      'Apr',
      'May',
      'Jun',
      'Jul',
      'Aug',
      'Sep',
      'Oct',
      'Nov',
      'Dec'
    ];
    return '${date.day} ${months[date.month - 1]} ${date.year}';
  }

  @override
  Widget build(BuildContext context) {
    final safeBottom = MediaQuery.paddingOf(context).bottom;
    final scrollBottomGap = safeBottom + _scrollEndPadding;

    return Scaffold(
      backgroundColor: kDarkWhite,
      floatingActionButton: FloatingActionButton(
        onPressed: () async {
          await Navigator.of(context).push(
            MaterialPageRoute(builder: (context) => const CreateNewJobPost()),
          );
          _loadJobPosts();
        },
        backgroundColor: kPrimaryColor,
        child: const Icon(FeatherIcons.plus, color: kWhite),
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.endFloat,
      body: Column(
          children: [
            ShellTabHeader(
              persona: ShellPersona.client,
              title: 'Job Posts',
              subtitle: Text(
                'Create and manage your listings',
                style: kTextStyle.copyWith(
                  color: Colors.white.withValues(alpha: 0.9),
                  fontSize: 12,
                ),
              ),
              leading: ShellTabIconButton(
                icon: Icons.menu_rounded,
                onPressed: () => clientShellScaffoldKey.currentState?.openDrawer(),
                tooltip: 'Menu',
              ),
            ),
            Expanded(
              child: Container(
                width: context.width(),
                padding: const EdgeInsets.only(left: 15.0, right: 15.0),
                decoration: const BoxDecoration(
                  color: kWhite,
                  borderRadius: BorderRadius.only(
                    topLeft: Radius.circular(30.0),
                    topRight: Radius.circular(30.0),
                  ),
                ),
                child: _isLoading
                    ? const Center(
                        child: CircularProgressIndicator(color: kPrimaryColor))
                    : _jobPosts.isEmpty
                        ? Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Container(
                                height: 213,
                                width: 269,
                                decoration: const BoxDecoration(
                                  image: DecorationImage(
                                      image:
                                          AssetImage('images/emptyservice.png'),
                                      fit: BoxFit.cover),
                                ),
                              ),
                              const SizedBox(height: 20.0),
                              Text(
                                'No Job Posts Yet',
                                style: kTextStyle.copyWith(
                                    color: kNeutralColor,
                                    fontWeight: FontWeight.bold,
                                    fontSize: 24.0),
                              ),
                              SizedBox(height: scrollBottomGap),
                            ],
                          )
                        : RefreshIndicator(
                            color: kPrimaryColor,
                            onRefresh: _loadJobPosts,
                            child: SingleChildScrollView(
                              physics: const AlwaysScrollableScrollPhysics(
                                  parent: BouncingScrollPhysics()),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  const SizedBox(height: 15.0),
                                  // Job-type filter chips
                                  SingleChildScrollView(
                                    scrollDirection: Axis.horizontal,
                                    physics: const BouncingScrollPhysics(),
                                    child: Row(
                                      children: _filterOptions.map((opt) {
                                        final selected =
                                            _typeFilter == opt['value'];
                                        return Padding(
                                          padding:
                                              const EdgeInsets.only(right: 8.0),
                                          child: ChoiceChip(
                                            label: Text(opt['label']!),
                                            selected: selected,
                                            onSelected: (_) => setState(() =>
                                                _typeFilter = opt['value']),
                                            selectedColor: kPrimaryColor,
                                            backgroundColor: kDarkWhite,
                                            labelStyle: kTextStyle.copyWith(
                                              color: selected
                                                  ? kWhite
                                                  : kNeutralColor,
                                            ),
                                            shape: RoundedRectangleBorder(
                                              borderRadius:
                                                  BorderRadius.circular(20.0),
                                              side: BorderSide(
                                                color: selected
                                                    ? kPrimaryColor
                                                    : kBorderColorTextField,
                                              ),
                                            ),
                                          ),
                                        );
                                      }).toList(),
                                    ),
                                  ),
                                  const SizedBox(height: 15.0),
                                  Text(
                                    'Total Job Post (${_visibleJobPosts.length})',
                                    style: kTextStyle.copyWith(
                                        color: kNeutralColor,
                                        fontWeight: FontWeight.bold),
                                  ),
                                  const SizedBox(height: 15.0),
                                  ListView.builder(
                                    itemCount: _visibleJobPosts.length,
                                    shrinkWrap: true,
                                    padding: EdgeInsets.only(
                                        bottom: scrollBottomGap),
                                    physics:
                                        const NeverScrollableScrollPhysics(),
                                    itemBuilder: (_, i) {
                                      final job = _visibleJobPosts[i];
                                      final category = job['categories']
                                          as Map<String, dynamic>?;

                                      return Padding(
                                        padding:
                                            const EdgeInsets.only(bottom: 10.0),
                                        child: GestureDetector(
                                          onTap: () async {
                                            await JobDetails(
                                                    jobPostId: job['id'])
                                                .launch(context);
                                            _loadJobPosts();
                                          },
                                          child: Container(
                                            width: context.width(),
                                            padding: const EdgeInsets.all(10.0),
                                            decoration: BoxDecoration(
                                              borderRadius:
                                                  BorderRadius.circular(10.0),
                                              color: kWhite,
                                              border: Border.all(
                                                  color: kBorderColorTextField),
                                            ),
                                            child: Column(
                                              crossAxisAlignment:
                                                  CrossAxisAlignment.start,
                                              children: [
                                                Row(
                                                  children: [
                                                    Expanded(
                                                      child: Text(
                                                        job['title'] ??
                                                            'Untitled',
                                                        style:
                                                            kTextStyle.copyWith(
                                                                color:
                                                                    kNeutralColor,
                                                                fontWeight:
                                                                    FontWeight
                                                                        .bold),
                                                        maxLines: 1,
                                                        overflow: TextOverflow
                                                            .ellipsis,
                                                      ),
                                                    ),
                                                    const SizedBox(width: 8.0),
                                                    Container(
                                                      padding: const EdgeInsets
                                                          .symmetric(
                                                          vertical: 3.0,
                                                          horizontal: 8.0),
                                                      decoration: BoxDecoration(
                                                        borderRadius:
                                                            BorderRadius
                                                                .circular(20.0),
                                                        color: kPrimaryColor
                                                            .withOpacity(0.1),
                                                      ),
                                                      child: Text(
                                                        _jobTypeLabel(
                                                            job['job_type']
                                                                as String?),
                                                        style:
                                                            kTextStyle.copyWith(
                                                          color: kPrimaryColor,
                                                          fontSize: 12.0,
                                                        ),
                                                      ),
                                                    ),
                                                  ],
                                                ),
                                                const SizedBox(height: 10.0),
                                                Text(
                                                  job['description'] ?? '',
                                                  maxLines: 2,
                                                  overflow:
                                                      TextOverflow.ellipsis,
                                                  style: kTextStyle.copyWith(
                                                      color: kSubTitleColor),
                                                ),
                                                const SizedBox(height: 10.0),
                                                RichText(
                                                  text: TextSpan(
                                                    text: 'Category: ',
                                                    style: kTextStyle.copyWith(
                                                        color: kNeutralColor),
                                                    children: [
                                                      TextSpan(
                                                        text:
                                                            category?['name'] ??
                                                                'General',
                                                        style: kTextStyle.copyWith(
                                                            color:
                                                                kSubTitleColor),
                                                      ),
                                                    ],
                                                  ),
                                                ),
                                                if ((job['location'] as String?)
                                                        ?.isNotEmpty ??
                                                    false) ...[
                                                  const SizedBox(height: 6.0),
                                                  Row(
                                                    children: [
                                                      const Icon(
                                                          FeatherIcons.mapPin,
                                                          size: 14,
                                                          color:
                                                              kLightNeutralColor),
                                                      const SizedBox(
                                                          width: 4.0),
                                                      Expanded(
                                                        child: Text(
                                                          job['location']
                                                              as String,
                                                          style: kTextStyle
                                                              .copyWith(
                                                                  color:
                                                                      kSubTitleColor),
                                                          maxLines: 1,
                                                          overflow: TextOverflow
                                                              .ellipsis,
                                                        ),
                                                      ),
                                                    ],
                                                  ),
                                                ],
                                                if (JobPostsService
                                                    .workersNeededShowOnCard(job[
                                                        'workers_needed'])) ...[
                                                  const SizedBox(height: 6.0),
                                                  Row(
                                                    children: [
                                                      const Icon(
                                                          FeatherIcons.users,
                                                          size: 14,
                                                          color:
                                                              kLightNeutralColor),
                                                      const SizedBox(
                                                          width: 4.0),
                                                      Text(
                                                        JobPostsService
                                                            .workersNeededCardLine(
                                                                job['workers_needed']),
                                                        style: kTextStyle.copyWith(
                                                            color:
                                                                kSubTitleColor),
                                                      ),
                                                    ],
                                                  ),
                                                ],
                                                const SizedBox(height: 10.0),
                                                Row(
                                                  children: [
                                                    Container(
                                                      padding: const EdgeInsets
                                                          .symmetric(
                                                          vertical: 5.0,
                                                          horizontal: 10),
                                                      decoration: BoxDecoration(
                                                        borderRadius:
                                                            BorderRadius
                                                                .circular(30.0),
                                                        color: job['status'] ==
                                                                'open'
                                                            ? kPrimaryColor
                                                                .withOpacity(
                                                                    0.1)
                                                            : kDarkWhite,
                                                      ),
                                                      child: Text(
                                                        (job['status'] ??
                                                                    'open')
                                                                .toString()
                                                                .substring(0, 1)
                                                                .toUpperCase() +
                                                            (job['status'] ??
                                                                    'open')
                                                                .toString()
                                                                .substring(1),
                                                        style:
                                                            kTextStyle.copyWith(
                                                          color: job['status'] ==
                                                                  'open'
                                                              ? kPrimaryColor
                                                              : kNeutralColor,
                                                        ),
                                                      ),
                                                    ),
                                                    const Spacer(),
                                                    Text(
                                                      'Date: ${_formatDate(job['created_at'])}',
                                                      style: kTextStyle.copyWith(
                                                          color:
                                                              kLightNeutralColor),
                                                    ),
                                                  ],
                                                ),
                                              ],
                                            ),
                                          ),
                                        ),
                                      );
                                    },
                                  ),
                                ],
                              ),
                            ),
                          ),
              ),
            ),
          ],
        ),
    );
  }
}
