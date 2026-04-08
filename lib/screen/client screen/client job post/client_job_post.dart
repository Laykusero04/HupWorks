import 'package:flutter/material.dart';
import 'package:flutter_feather_icons/flutter_feather_icons.dart';
import 'package:freelancer/screen/widgets/constant.dart';
import 'package:freelancer/services/job_posts_service.dart';
import 'package:nb_utils/nb_utils.dart';

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
    const months = ['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', 'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'];
    return '${date.day} ${months[date.month - 1]} ${date.year}';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: kDarkWhite,
      appBar: AppBar(
        backgroundColor: kDarkWhite,
        elevation: 0,
        iconTheme: const IconThemeData(color: kNeutralColor),
        title: Text(
          'Job Posts',
          style: kTextStyle.copyWith(color: kNeutralColor, fontWeight: FontWeight.bold),
        ),
        centerTitle: true,
      ),
      floatingActionButton: Padding(
        padding: const EdgeInsets.only(bottom: 20.0),
        child: FloatingActionButton(
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
      body: Padding(
        padding: const EdgeInsets.only(top: 10.0),
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
              ? const Center(child: CircularProgressIndicator(color: kPrimaryColor))
              : _jobPosts.isEmpty
                  ? Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Container(
                          height: 213,
                          width: 269,
                          decoration: const BoxDecoration(
                            image: DecorationImage(image: AssetImage('images/emptyservice.png'), fit: BoxFit.cover),
                          ),
                        ),
                        const SizedBox(height: 20.0),
                        Text(
                          'No Job Posts Yet',
                          style: kTextStyle.copyWith(color: kNeutralColor, fontWeight: FontWeight.bold, fontSize: 24.0),
                        ),
                      ],
                    )
                  : RefreshIndicator(
                      color: kPrimaryColor,
                      onRefresh: _loadJobPosts,
                      child: SingleChildScrollView(
                        physics: const AlwaysScrollableScrollPhysics(parent: BouncingScrollPhysics()),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const SizedBox(height: 15.0),
                            Text(
                              'Total Job Post (${_jobPosts.length})',
                              style: kTextStyle.copyWith(color: kNeutralColor, fontWeight: FontWeight.bold),
                            ),
                            const SizedBox(height: 15.0),
                            ListView.builder(
                              itemCount: _jobPosts.length,
                              shrinkWrap: true,
                              padding: const EdgeInsets.only(bottom: 10.0),
                              physics: const NeverScrollableScrollPhysics(),
                              itemBuilder: (_, i) {
                                final job = _jobPosts[i];
                                final category = job['categories'] as Map<String, dynamic>?;

                                return Padding(
                                  padding: const EdgeInsets.only(bottom: 10.0),
                                  child: GestureDetector(
                                    onTap: () async {
                                      await JobDetails(jobPostId: job['id']).launch(context);
                                      _loadJobPosts();
                                    },
                                    child: Container(
                                      width: context.width(),
                                      padding: const EdgeInsets.all(10.0),
                                      decoration: BoxDecoration(
                                        borderRadius: BorderRadius.circular(10.0),
                                        color: kWhite,
                                        border: Border.all(color: kBorderColorTextField),
                                      ),
                                      child: Column(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          Text(
                                            job['title'] ?? 'Untitled',
                                            style: kTextStyle.copyWith(color: kNeutralColor, fontWeight: FontWeight.bold),
                                          ),
                                          const SizedBox(height: 10.0),
                                          Text(
                                            job['description'] ?? '',
                                            maxLines: 2,
                                            overflow: TextOverflow.ellipsis,
                                            style: kTextStyle.copyWith(color: kSubTitleColor),
                                          ),
                                          const SizedBox(height: 10.0),
                                          RichText(
                                            text: TextSpan(
                                              text: 'Category: ',
                                              style: kTextStyle.copyWith(color: kNeutralColor),
                                              children: [
                                                TextSpan(
                                                  text: category?['name'] ?? 'General',
                                                  style: kTextStyle.copyWith(color: kSubTitleColor),
                                                ),
                                              ],
                                            ),
                                          ),
                                          const SizedBox(height: 10.0),
                                          Row(
                                            children: [
                                              Container(
                                                padding: const EdgeInsets.symmetric(vertical: 5.0, horizontal: 10),
                                                decoration: BoxDecoration(
                                                  borderRadius: BorderRadius.circular(30.0),
                                                  color: job['status'] == 'open' ? kPrimaryColor.withOpacity(0.1) : kDarkWhite,
                                                ),
                                                child: Text(
                                                  (job['status'] ?? 'open').toString().substring(0, 1).toUpperCase() +
                                                      (job['status'] ?? 'open').toString().substring(1),
                                                  style: kTextStyle.copyWith(
                                                    color: job['status'] == 'open' ? kPrimaryColor : kNeutralColor,
                                                  ),
                                                ),
                                              ),
                                              const Spacer(),
                                              Text(
                                                'Date: ${_formatDate(job['created_at'])}',
                                                style: kTextStyle.copyWith(color: kLightNeutralColor),
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
    );
  }
}
