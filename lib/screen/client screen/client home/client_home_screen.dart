import 'package:flutter/material.dart';
import 'package:flutter_feather_icons/flutter_feather_icons.dart';
import 'package:flutter_iconly/flutter_iconly.dart';
import 'package:freelancer/screen/client%20screen/client%20home/top_seller.dart';
import 'package:freelancer/screen/client%20screen/client%20job%20post/client_job_post.dart';
import 'package:freelancer/screen/client%20screen/client%20job%20post/job_details.dart';
import 'package:freelancer/services/client_home_service.dart';
import 'package:freelancer/services/job_posts_service.dart';
import 'package:nb_utils/nb_utils.dart';

import '../../widgets/constant.dart';
import '../client notification/client_notification.dart';
import '../search/search.dart';
import 'client_all_categories.dart';

class ClientHomeScreen extends StatefulWidget {
  const ClientHomeScreen({Key? key}) : super(key: key);

  @override
  State<ClientHomeScreen> createState() => _ClientHomeScreenState();
}

class _ClientHomeScreenState extends State<ClientHomeScreen> {
  Map<String, dynamic>? _profile;
  List<Map<String, dynamic>> _categories = [];
  List<Map<String, dynamic>> _myRecentJobs = [];
  List<Map<String, dynamic>> _topSellers = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    try {
      final results = await Future.wait([
        ClientHomeService.getUserProfile(),
        ClientHomeService.getCategories(),
        JobPostsService.getClientJobPosts(),
        ClientHomeService.getTopSellers(),
      ]);

      if (mounted) {
        final myJobs = results[2] as List<Map<String, dynamic>>;
        setState(() {
          _profile = results[0] as Map<String, dynamic>?;
          _categories = results[1] as List<Map<String, dynamic>>;
          _myRecentJobs = myJobs.take(3).toList();
          _topSellers = results[3] as List<Map<String, dynamic>>;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error loading data: $e')),
        );
      }
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

  // Map category name to local asset icon
  String _getCategoryIcon(String? iconName) {
    switch (iconName) {
      case 'design':
        return 'images/graphic.png';
      case 'video':
        return 'images/videoicon.png';
      case 'marketing':
        return 'images/dm.png';
      case 'business':
        return 'images/b.png';
      case 'writing':
        return 'images/t.png';
      case 'code':
        return 'images/p.png';
      case 'lifestyle':
        return 'images/l.png';
      default:
        return 'images/p.png';
    }
  }

  @override
  Widget build(BuildContext context) {
    final userName = _profile?['name'] ?? 'User';
    final profileImageUrl = _profile?['profile_image_url'];

    return SafeArea(
      child: Scaffold(
        backgroundColor: kDarkWhite,
        appBar: AppBar(
          backgroundColor: kDarkWhite,
          elevation: 0,
          automaticallyImplyLeading: false,
          title: ListTile(
            contentPadding: const EdgeInsets.only(top: 10),
            leading: Padding(
              padding: const EdgeInsets.only(left: 10.0),
              child: Container(
                height: 44,
                width: 44,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  image: DecorationImage(
                    image: profileImageUrl != null
                        ? NetworkImage(profileImageUrl) as ImageProvider
                        : const AssetImage('images/profile3.png'),
                    fit: BoxFit.cover,
                  ),
                ),
              ),
            ),
            title: Text(
              userName,
              style: kTextStyle.copyWith(color: kNeutralColor, fontWeight: FontWeight.bold),
            ),
            subtitle: Text(
              'I\'m a Client',
              style: kTextStyle.copyWith(color: kLightNeutralColor),
            ),
            trailing: GestureDetector(
              onTap: () => const ClientNotification().launch(context),
              child: Container(
                padding: const EdgeInsets.all(8.0),
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: kPrimaryColor.withOpacity(0.2),
                  ),
                ),
                child: const Icon(
                  IconlyLight.notification,
                  color: kNeutralColor,
                ),
              ),
            ),
          ),
        ),
        body: _isLoading
            ? const Center(child: CircularProgressIndicator(color: kPrimaryColor))
            : Padding(
                padding: const EdgeInsets.only(top: 15.0),
                child: Container(
                  width: context.width(),
                  decoration: const BoxDecoration(
                    color: kWhite,
                    borderRadius: BorderRadius.only(
                      topLeft: Radius.circular(30.0),
                      topRight: Radius.circular(30.0),
                    ),
                  ),
                  child: RefreshIndicator(
                    color: kPrimaryColor,
                    onRefresh: _loadData,
                    child: SingleChildScrollView(
                      physics: const AlwaysScrollableScrollPhysics(parent: BouncingScrollPhysics()),
                      child: Column(
                        children: [
                          // Search bar
                          Padding(
                            padding: const EdgeInsets.all(15.0),
                            child: Container(
                              decoration: BoxDecoration(
                                color: kDarkWhite,
                                borderRadius: BorderRadius.circular(30.0),
                              ),
                              child: ListTile(
                                horizontalTitleGap: 0,
                                visualDensity: const VisualDensity(vertical: -2),
                                leading: const Icon(
                                  FeatherIcons.search,
                                  color: kNeutralColor,
                                ),
                                title: Text(
                                  'Search services...',
                                  style: kTextStyle.copyWith(color: kSubTitleColor),
                                ),
                                onTap: () {
                                  showSearch(
                                    context: context,
                                    delegate: CustomSearchDelegate(),
                                  );
                                },
                              ),
                            ),
                          ),
                          const SizedBox(height: 10.0),

                          // Banner
                          HorizontalList(
                            physics: const BouncingScrollPhysics(),
                            padding: const EdgeInsets.only(left: 15),
                            spacing: 10.0,
                            itemCount: 3,
                            itemBuilder: (_, i) {
                              return Container(
                                height: 140,
                                width: 304,
                                decoration: BoxDecoration(
                                  borderRadius: BorderRadius.circular(8.0),
                                  image: const DecorationImage(image: AssetImage('images/banner.png'), fit: BoxFit.cover),
                                ),
                              );
                            },
                          ),
                          const SizedBox(height: 25.0),

                          // Categories
                          Padding(
                            padding: const EdgeInsets.only(left: 15.0, right: 15.0),
                            child: Row(
                              children: [
                                Text(
                                  'Categories',
                                  style: kTextStyle.copyWith(color: kNeutralColor, fontWeight: FontWeight.bold),
                                ),
                                const Spacer(),
                                GestureDetector(
                                  onTap: () => const ClientAllCategories().launch(context),
                                  child: Text(
                                    'View All',
                                    style: kTextStyle.copyWith(color: kLightNeutralColor),
                                  ),
                                ),
                              ],
                            ),
                          ),
                          _categories.isEmpty
                              ? Padding(
                                  padding: const EdgeInsets.all(20.0),
                                  child: Text('No categories yet', style: kTextStyle.copyWith(color: kLightNeutralColor)),
                                )
                              : HorizontalList(
                                  physics: const BouncingScrollPhysics(),
                                  padding: const EdgeInsets.only(top: 20, bottom: 20, left: 15.0, right: 15.0),
                                  spacing: 10.0,
                                  itemCount: _categories.length,
                                  itemBuilder: (_, i) {
                                    final cat = _categories[i];
                                    return Container(
                                      padding: const EdgeInsets.only(left: 5.0, right: 10.0, top: 5.0, bottom: 5.0),
                                      decoration: BoxDecoration(
                                        borderRadius: BorderRadius.circular(30.0),
                                        color: kWhite,
                                        boxShadow: const [
                                          BoxShadow(
                                            color: kBorderColorTextField,
                                            blurRadius: 7.0,
                                            spreadRadius: 1.0,
                                            offset: Offset(0, 0),
                                          ),
                                        ],
                                      ),
                                      child: Row(
                                        mainAxisSize: MainAxisSize.min,
                                        children: [
                                          Container(
                                            height: 39,
                                            width: 39,
                                            decoration: BoxDecoration(
                                              shape: BoxShape.circle,
                                              image: DecorationImage(
                                                image: AssetImage(_getCategoryIcon(cat['icon'])),
                                                fit: BoxFit.cover,
                                              ),
                                            ),
                                          ),
                                          const SizedBox(width: 5.0),
                                          Column(
                                            crossAxisAlignment: CrossAxisAlignment.start,
                                            children: [
                                              Text(
                                                cat['name'] ?? '',
                                                style: kTextStyle.copyWith(color: kNeutralColor, fontWeight: FontWeight.bold),
                                              ),
                                              const SizedBox(height: 2.0),
                                              Text(
                                                cat['description'] ?? 'Related all categories',
                                                style: kTextStyle.copyWith(color: kLightNeutralColor),
                                                maxLines: 1,
                                                overflow: TextOverflow.ellipsis,
                                              ),
                                            ],
                                          ),
                                        ],
                                      ),
                                    );
                                  },
                                ),

                          // My Recent Jobs
                          Padding(
                            padding: const EdgeInsets.only(left: 15.0, right: 15.0, top: 10),
                            child: Row(
                              children: [
                                Text(
                                  'My Recent Jobs',
                                  style: kTextStyle.copyWith(color: kNeutralColor, fontWeight: FontWeight.bold),
                                ),
                                const Spacer(),
                                GestureDetector(
                                  onTap: () => const JobPost().launch(context),
                                  child: Text(
                                    'View All',
                                    style: kTextStyle.copyWith(color: kLightNeutralColor),
                                  ),
                                ),
                              ],
                            ),
                          ),
                          _myRecentJobs.isEmpty
                              ? Padding(
                                  padding: const EdgeInsets.all(20.0),
                                  child: Text(
                                    'You haven\'t posted any jobs yet',
                                    style: kTextStyle.copyWith(color: kLightNeutralColor),
                                  ),
                                )
                              : Padding(
                                  padding: const EdgeInsets.only(top: 15, left: 15, right: 15, bottom: 5),
                                  child: Column(
                                    children: _myRecentJobs.map((job) {
                                      final category = job['categories'] as Map<String, dynamic>?;
                                      final isOpen = job['status'] == 'open';
                                      return Padding(
                                        padding: const EdgeInsets.only(bottom: 10),
                                        child: GestureDetector(
                                          onTap: () async {
                                            await JobDetails(jobPostId: job['id'] as String).launch(context);
                                            _loadData();
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
                                                const SizedBox(height: 8),
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
                                    }).toList(),
                                  ),
                                ),

                          // Suggested Freelancers
                          Padding(
                            padding: const EdgeInsets.only(left: 15.0, right: 15.0),
                            child: Row(
                              children: [
                                Text(
                                  'Suggested Freelancers',
                                  style: kTextStyle.copyWith(color: kNeutralColor, fontWeight: FontWeight.bold),
                                ),
                                const Spacer(),
                                GestureDetector(
                                  onTap: () => const TopSeller().launch(context),
                                  child: Text(
                                    'View All',
                                    style: kTextStyle.copyWith(color: kLightNeutralColor),
                                  ),
                                ),
                              ],
                            ),
                          ),
                          _topSellers.isEmpty
                              ? Padding(
                                  padding: const EdgeInsets.all(20.0),
                                  child: Text('No freelancers yet', style: kTextStyle.copyWith(color: kLightNeutralColor)),
                                )
                              : HorizontalList(
                                  physics: const BouncingScrollPhysics(),
                                  padding: const EdgeInsets.only(top: 20, bottom: 20, left: 15.0, right: 15.0),
                                  spacing: 10.0,
                                  itemCount: _topSellers.length,
                                  itemBuilder: (_, i) {
                                    final seller = _topSellers[i];
                                    final profileImageUrl = seller['profile_image_url'];

                                    return Padding(
                                      padding: const EdgeInsets.only(bottom: 10.0),
                                      child: Container(
                                        height: 230,
                                        width: 156,
                                        decoration: BoxDecoration(
                                          color: kWhite,
                                          borderRadius: BorderRadius.circular(8.0),
                                          border: Border.all(color: kBorderColorTextField),
                                          boxShadow: const [
                                            BoxShadow(
                                              color: kDarkWhite,
                                              blurRadius: 5.0,
                                              spreadRadius: 2.0,
                                              offset: Offset(0, 5),
                                            ),
                                          ],
                                        ),
                                        child: Column(
                                          children: [
                                            Container(
                                              height: 135,
                                              width: 156,
                                              decoration: BoxDecoration(
                                                borderRadius: const BorderRadius.only(
                                                  topRight: Radius.circular(8.0),
                                                  topLeft: Radius.circular(8.0),
                                                ),
                                                image: DecorationImage(
                                                  image: profileImageUrl != null
                                                      ? NetworkImage(profileImageUrl) as ImageProvider
                                                      : const AssetImage('images/dev1.png'),
                                                  fit: BoxFit.cover,
                                                ),
                                              ),
                                            ),
                                            Padding(
                                              padding: const EdgeInsets.all(6.0),
                                              child: Column(
                                                crossAxisAlignment: CrossAxisAlignment.start,
                                                children: [
                                                  Text(
                                                    seller['name'] ?? 'Seller',
                                                    style: kTextStyle.copyWith(color: kNeutralColor, fontWeight: FontWeight.bold),
                                                    maxLines: 1,
                                                    overflow: TextOverflow.ellipsis,
                                                  ),
                                                  const SizedBox(height: 6.0),
                                                  Row(
                                                    mainAxisAlignment: MainAxisAlignment.start,
                                                    children: [
                                                      const Icon(
                                                        IconlyBold.star,
                                                        color: Colors.amber,
                                                        size: 18.0,
                                                      ),
                                                      const SizedBox(width: 2.0),
                                                      Text(
                                                        '${seller['rating'] ?? 0}',
                                                        style: kTextStyle.copyWith(color: kNeutralColor),
                                                      ),
                                                    ],
                                                  ),
                                                ],
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                    );
                                  },
                                ),

                          const SizedBox(height: 20.0),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
      ),
    );
  }
}
