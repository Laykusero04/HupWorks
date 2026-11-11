import 'package:flutter/material.dart';
import 'package:freelancer/core/widgets/rubik_refresh_indicator.dart';
import 'package:freelancer/core/widgets/loading_widget.dart';
import 'package:flutter_feather_icons/flutter_feather_icons.dart';
import 'package:freelancer/core/guide/guide_anchor.dart';
import 'package:freelancer/core/guide/guide_host.dart';
import 'package:freelancer/core/guide/guide_info_button.dart';
import 'package:freelancer/core/guide/guide_step.dart';
import 'package:freelancer/core/utils/app_date_format.dart';
import 'package:freelancer/core/utils/localized_category.dart';
import 'package:freelancer/core/widgets/empty_state_widget.dart';
import 'package:freelancer/l10n/l10n.dart';
import 'package:freelancer/l10n/l10n_labels.dart';
import 'package:freelancer/screen/widgets/constant.dart';
import 'package:freelancer/services/job_posts_service.dart';
import 'package:nb_utils/nb_utils.dart';

import '../../widgets/client_shell_app_bar.dart';
import 'create_new_job_post.dart';
import 'job_details.dart';

class JobPost extends StatefulWidget {
  const JobPost({Key? key}) : super(key: key);

  @override
  State<JobPost> createState() => _JobPostState();
}

class _JobPostState extends State<JobPost> with GuideHost<JobPost> {
  List<Map<String, dynamic>> _jobPosts = [];
  bool _isLoading = true;
  String? _typeFilter; // null = all

  // Guide targets (long-lived; the card key sits on the FIRST card only).
  final GlobalKey _guideFilterKey = GlobalKey();
  final GlobalKey _guideCardKey = GlobalKey();
  final GlobalKey _guideFabKey = GlobalKey();

  /// True during every reload after the first (pull-to-refresh, return from a
  /// pushed screen) so a running guide is torn down and restarted.
  bool _reloading = false;

  @override
  String get guideScreenId => 'client_jobs';

  @override
  String get guideRole => 'client';

  @override
  int get guideVersion => 1;

  @override
  bool get guideDataReady => !_isLoading && !_reloading;

  @override
  String get guideSkipLabel => context.l10n.guideSkip;

  @override
  String get guideNextLabel => context.l10n.guideNext;

  @override
  String get guideDoneLabel => context.l10n.guideDone;

  Widget _guide(GlobalKey key, String title, String description, Widget child,
          {double radius = 8}) =>
      GuideAnchor.wrap(
        GuideAnchor(
          key: key,
          scope: guideScope,
          title: title,
          description: description,
          borderRadius: BorderRadius.circular(radius),
        ),
        child,
      );

  /// Core: filter chips, first job card, post button. With no jobs only the
  /// button renders, so the guide does not auto-run.
  @override
  List<GuideStep> buildGuideSteps(BuildContext context) {
    final l10n = context.l10n;
    return [
      GuideStep(
        key: _guideFilterKey,
        title: l10n.guideMyJobsFilterTitle,
        description: l10n.guideMyJobsFilterDesc,
      ),
      GuideStep(
        key: _guideCardKey,
        title: l10n.guideMyJobsCardTitle,
        description: l10n.guideMyJobsCardDesc,
      ),
      GuideStep(
        key: _guideFabKey,
        title: l10n.guideMyJobsPostTitle,
        description: l10n.guideMyJobsPostDesc,
        targetNearBottom: true,
      ),
    ];
  }

  /// Tail padding for scroll content above the tab bar + FAB.
  static const double _scrollEndPadding = 24;
  static const double _horizontalPadding = 16;

  static const _filterValues = <String?>[null, 'gig', 'full_time', 'part_time'];

  String _filterLabel(String? value) {
    final l10n = context.l10n;
    if (value == null) return l10n.filterAll;
    return L10nLabels.jobType(l10n, value);
  }

  String _jobTypeLabel(String? type) => L10nLabels.jobType(context.l10n, type);

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
    if (mounted && !_isLoading) setState(() => _reloading = true);
    try {
      final posts = await JobPostsService.getClientJobPosts();
      if (mounted) {
        setState(() {
          _jobPosts = posts;
          _isLoading = false;
          _reloading = false;
        });
        scheduleGuide();
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLoading = false;
          _reloading = false;
        });
        scheduleGuide();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(context.l10n.errorLoadingJobPosts('$e'))),
        );
      }
    }
  }

  String _formatDate(String? dateStr) {
    return AppDateFormat.tryDMmmY(
          dateStr,
          AppDateFormat.localeOf(context),
        ) ??
        '';
  }

  @override
  Widget build(BuildContext context) {
    final safeBottom = MediaQuery.paddingOf(context).bottom;
    final scrollBottomGap = safeBottom + _scrollEndPadding;

    final l10n = context.l10n;
    return guideBackScope(Scaffold(
      backgroundColor: kWhite,
      appBar: ClientShellAppBar(
        title: l10n.myJobs,
        actions: [GuideInfoButton(host: this)],
      ),
      floatingActionButton: _guide(
        _guideFabKey,
        l10n.guideMyJobsPostTitle,
        l10n.guideMyJobsPostDesc,
        radius: 28,
        FloatingActionButton(
          tooltip: l10n.postAJob,
          onPressed: () async {
            await Navigator.of(context).push(
              MaterialPageRoute(builder: (context) => const CreateNewJobPost()),
            );
            _loadJobPosts();
          },
          backgroundColor: kPrimaryColor,
          child: const Icon(FeatherIcons.plus, color: kWhite),
        ),
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.endFloat,
      body: _isLoading
          ? const LoadingWidget()
          : _jobPosts.isEmpty
              ? EmptyStateWidget(
                  message: l10n.noJobsPostedYet,
                  hint: l10n.noJobsPostedYetHint,
                  imageAsset: 'images/emptyservice.png',
                  imageHeight: 213,
                  imageWidth: 269,
                  actionLabel: l10n.postAJob,
                  onAction: () async {
                    await Navigator.of(context).push(
                      MaterialPageRoute(
                        builder: (context) => const CreateNewJobPost(),
                      ),
                    );
                    _loadJobPosts();
                  },
                )
              : _visibleJobPosts.isEmpty
                  ? EmptyStateWidget(
                      message: l10n.noJobsMatchFilters,
                      icon: Icons.filter_alt_off_outlined,
                      actionLabel: l10n.clearFilters,
                      onAction: () => setState(() => _typeFilter = null),
                    )
                  : RubikRefreshIndicator(
                      onRefresh: _loadJobPosts,
                      child: SingleChildScrollView(
                        physics: const AlwaysScrollableScrollPhysics(
                          parent: BouncingScrollPhysics(),
                        ),
                        padding: const EdgeInsets.symmetric(
                            horizontal: _horizontalPadding),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const SizedBox(height: 15.0),
                            // Job-type filter chips
                            _guide(
                              _guideFilterKey,
                              l10n.guideMyJobsFilterTitle,
                              l10n.guideMyJobsFilterDesc,
                              SingleChildScrollView(
                                scrollDirection: Axis.horizontal,
                                physics: const BouncingScrollPhysics(),
                                child: Row(
                                  children: _filterValues.map((value) {
                                    final selected = _typeFilter == value;
                                    return Padding(
                                      padding:
                                          const EdgeInsets.only(right: 8.0),
                                      child: ChoiceChip(
                                        label: Text(_filterLabel(value)),
                                        selected: selected,
                                        onSelected: (_) =>
                                            setState(() => _typeFilter = value),
                                        selectedColor: kPrimaryColor,
                                        backgroundColor: kDarkWhite,
                                        labelStyle: kTextStyle.copyWith(
                                          color:
                                              selected ? kWhite : kNeutralColor,
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
                            ),
                            const SizedBox(height: 15.0),
                            Text(
                              l10n.totalJobPostCount(_visibleJobPosts.length),
                              style: kTextStyle.copyWith(
                                  color: kNeutralColor,
                                  fontWeight: FontWeight.bold),
                            ),
                            const SizedBox(height: 15.0),
                            ListView.builder(
                              itemCount: _visibleJobPosts.length,
                              shrinkWrap: true,
                              padding: EdgeInsets.only(bottom: scrollBottomGap),
                              physics: const NeverScrollableScrollPhysics(),
                              itemBuilder: (_, i) {
                                final job = _visibleJobPosts[i];
                                final category =
                                    job['categories'] as Map<String, dynamic>?;

                                return Padding(
                                  padding: const EdgeInsets.only(bottom: 10.0),
                                  child: _guideIf(
                                    i == 0,
                                    _guideCardKey,
                                    l10n.guideMyJobsCardTitle,
                                    l10n.guideMyJobsCardDesc,
                                    GestureDetector(
                                      onTap: () async {
                                        await JobDetails(jobPostId: job['id'])
                                            .launch(context);
                                        _loadJobPosts();
                                      },
                                      child: Container(
                                        width: double.infinity,
                                        padding: const EdgeInsets.all(12.0),
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
                                                        l10n.untitled,
                                                    style: kTextStyle.copyWith(
                                                        color: kNeutralColor,
                                                        fontWeight:
                                                            FontWeight.bold),
                                                    maxLines: 1,
                                                    overflow:
                                                        TextOverflow.ellipsis,
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
                                                        BorderRadius.circular(
                                                            20.0),
                                                    color: kPrimaryColor
                                                        .withOpacity(0.1),
                                                  ),
                                                  child: Text(
                                                    _jobTypeLabel(
                                                        job['job_type']
                                                            as String?),
                                                    style: kTextStyle.copyWith(
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
                                              overflow: TextOverflow.ellipsis,
                                              style: kTextStyle.copyWith(
                                                  color: kSubTitleColor),
                                            ),
                                            const SizedBox(height: 10.0),
                                            RichText(
                                              text: TextSpan(
                                                text: '${l10n.categoryLabel}: ',
                                                style: kTextStyle.copyWith(
                                                    color: kNeutralColor),
                                                children: [
                                                  TextSpan(
                                                    text:
                                                        LocalizedCategory.name(
                                                      category,
                                                      LocalizedCategory
                                                          .languageCodeOf(
                                                              context),
                                                      fallback:
                                                          l10n.categoryGeneral,
                                                    ),
                                                    style: kTextStyle.copyWith(
                                                        color: kSubTitleColor),
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
                                                  const SizedBox(width: 4.0),
                                                  Expanded(
                                                    child: Text(
                                                      job['location'] as String,
                                                      style: kTextStyle.copyWith(
                                                          color:
                                                              kSubTitleColor),
                                                      maxLines: 1,
                                                      overflow:
                                                          TextOverflow.ellipsis,
                                                    ),
                                                  ),
                                                ],
                                              ),
                                            ],
                                            if (JobPostsService
                                                .workersNeededShowOnCard(
                                                    job['workers_needed'])) ...[
                                              const SizedBox(height: 6.0),
                                              Row(
                                                children: [
                                                  const Icon(FeatherIcons.users,
                                                      size: 14,
                                                      color:
                                                          kLightNeutralColor),
                                                  const SizedBox(width: 4.0),
                                                  Text(
                                                    JobPostsService
                                                        .workersNeededCardLine(
                                                            job['workers_needed']),
                                                    style: kTextStyle.copyWith(
                                                        color: kSubTitleColor),
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
                                                        BorderRadius.circular(
                                                            30.0),
                                                    color: job['status'] ==
                                                            'open'
                                                        ? kPrimaryColor
                                                            .withOpacity(0.1)
                                                        : kDarkWhite,
                                                  ),
                                                  child: Text(
                                                    switch ((job['status']
                                                            as String?) ??
                                                        '') {
                                                      'open' => l10n.open,
                                                      'closed' => l10n.closed,
                                                      '' => l10n.unknown,
                                                      final other => other,
                                                    },
                                                    style: kTextStyle.copyWith(
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
                                  ),
                                );
                              },
                            ),
                          ],
                        ),
                      ),
                    ),
    ));
  }

  Widget _guideIf(bool attach, GlobalKey key, String title, String description,
          Widget child) =>
      attach ? _guide(key, title, description, child) : child;
}
