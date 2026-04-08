import 'package:flutter/material.dart';
import 'package:flutter_feather_icons/flutter_feather_icons.dart';
import 'package:flutter_iconly/flutter_iconly.dart';
import 'package:freelancer/screen/client%20screen/client%20home/popular_services.dart';
import 'package:freelancer/screen/client%20screen/client%20home/recently_view.dart';
import 'package:freelancer/screen/client%20screen/client%20home/top_seller.dart';
import 'package:freelancer/services/client_home_service.dart';
import 'package:freelancer/services/recently_viewed_service.dart';
import 'package:nb_utils/nb_utils.dart';

import '../../widgets/constant.dart';
import '../client notification/client_notification.dart';
import '../client service details/client_service_details.dart';
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
  List<Map<String, dynamic>> _popularServices = [];
  List<Map<String, dynamic>> _topSellers = [];
  List<Map<String, dynamic>> _recentlyViewed = [];
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
        ClientHomeService.getPopularServices(),
        ClientHomeService.getTopSellers(),
        RecentlyViewedService.getRecentlyViewedServices(),
      ]);

      if (mounted) {
        setState(() {
          _profile = results[0] as Map<String, dynamic>?;
          _categories = results[1] as List<Map<String, dynamic>>;
          _popularServices = results[2] as List<Map<String, dynamic>>;
          _topSellers = results[3] as List<Map<String, dynamic>>;
          _recentlyViewed = results[4] as List<Map<String, dynamic>>;
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

                          // Popular Services
                          Padding(
                            padding: const EdgeInsets.only(left: 15.0, right: 15.0, top: 10),
                            child: Row(
                              children: [
                                Text(
                                  'Popular Services',
                                  style: kTextStyle.copyWith(color: kNeutralColor, fontWeight: FontWeight.bold),
                                ),
                                const Spacer(),
                                GestureDetector(
                                  onTap: () => const PopularServices().launch(context),
                                  child: Text(
                                    'View All',
                                    style: kTextStyle.copyWith(color: kLightNeutralColor),
                                  ),
                                ),
                              ],
                            ),
                          ),
                          _popularServices.isEmpty
                              ? Padding(
                                  padding: const EdgeInsets.all(20.0),
                                  child: Text('No services yet', style: kTextStyle.copyWith(color: kLightNeutralColor)),
                                )
                              : HorizontalList(
                                  physics: const BouncingScrollPhysics(),
                                  padding: const EdgeInsets.only(top: 20, bottom: 20, left: 15.0, right: 15.0),
                                  spacing: 10.0,
                                  itemCount: _popularServices.length,
                                  itemBuilder: (_, i) {
                                    final service = _popularServices[i];
                                    final seller = service['profiles'] as Map<String, dynamic>?;
                                    final images = service['images'] as List<dynamic>?;
                                    final imageUrl = (images != null && images.isNotEmpty) ? images[0] : null;

                                    return Padding(
                                      padding: const EdgeInsets.only(bottom: 10.0),
                                      child: GestureDetector(
                                        onTap: () => ClientServiceDetails(serviceId: service['id']).launch(context),
                                        child: Container(
                                          height: 120,
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
                                          child: Row(
                                            mainAxisSize: MainAxisSize.min,
                                            mainAxisAlignment: MainAxisAlignment.start,
                                            children: [
                                              Container(
                                                height: 120,
                                                width: 120,
                                                decoration: BoxDecoration(
                                                  borderRadius: const BorderRadius.only(
                                                    bottomLeft: Radius.circular(8.0),
                                                    topLeft: Radius.circular(8.0),
                                                  ),
                                                  image: DecorationImage(
                                                    image: imageUrl != null
                                                        ? NetworkImage(imageUrl) as ImageProvider
                                                        : const AssetImage('images/shot1.png'),
                                                    fit: BoxFit.cover,
                                                  ),
                                                ),
                                              ),
                                              Padding(
                                                padding: const EdgeInsets.all(5.0),
                                                child: Column(
                                                  crossAxisAlignment: CrossAxisAlignment.start,
                                                  mainAxisSize: MainAxisSize.min,
                                                  children: [
                                                    Flexible(
                                                      child: SizedBox(
                                                        width: 190,
                                                        child: Text(
                                                          service['title'] ?? 'Service',
                                                          style: kTextStyle.copyWith(color: kNeutralColor, fontWeight: FontWeight.bold),
                                                          maxLines: 2,
                                                          overflow: TextOverflow.ellipsis,
                                                        ),
                                                      ),
                                                    ),
                                                    const SizedBox(height: 5.0),
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
                                                          '${service['rating'] ?? 0}',
                                                          style: kTextStyle.copyWith(color: kNeutralColor),
                                                        ),
                                                        const SizedBox(width: 2.0),
                                                        Text(
                                                          '(${service['review_count'] ?? 0})',
                                                          style: kTextStyle.copyWith(color: kLightNeutralColor),
                                                        ),
                                                        const SizedBox(width: 40),
                                                        RichText(
                                                          text: TextSpan(
                                                            text: 'Price: ',
                                                            style: kTextStyle.copyWith(color: kLightNeutralColor),
                                                            children: [
                                                              TextSpan(
                                                                text: '$currencySign${service['price'] ?? 0}',
                                                                style: kTextStyle.copyWith(color: kPrimaryColor, fontWeight: FontWeight.bold),
                                                              )
                                                            ],
                                                          ),
                                                        )
                                                      ],
                                                    ),
                                                    const SizedBox(height: 5.0),
                                                    Row(
                                                      children: [
                                                        Container(
                                                          height: 32,
                                                          width: 32,
                                                          decoration: BoxDecoration(
                                                            shape: BoxShape.circle,
                                                            image: DecorationImage(
                                                              image: seller?['profile_image_url'] != null
                                                                  ? NetworkImage(seller!['profile_image_url']) as ImageProvider
                                                                  : const AssetImage('images/profilepic2.png'),
                                                              fit: BoxFit.cover,
                                                            ),
                                                          ),
                                                        ),
                                                        const SizedBox(width: 5.0),
                                                        Text(
                                                          seller?['name'] ?? 'Seller',
                                                          maxLines: 1,
                                                          overflow: TextOverflow.ellipsis,
                                                          style: kTextStyle.copyWith(color: kNeutralColor, fontWeight: FontWeight.bold),
                                                        ),
                                                      ],
                                                    ),
                                                  ],
                                                ),
                                              ),
                                            ],
                                          ),
                                        ),
                                      ),
                                    );
                                  },
                                ),

                          // Top Sellers
                          Padding(
                            padding: const EdgeInsets.only(left: 15.0, right: 15.0),
                            child: Row(
                              children: [
                                Text(
                                  'Top Sellers',
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
                                  child: Text('No sellers yet', style: kTextStyle.copyWith(color: kLightNeutralColor)),
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

                          // Recently Viewed
                          Padding(
                            padding: const EdgeInsets.only(left: 15.0, right: 15.0),
                            child: Row(
                              children: [
                                Text(
                                  'Recent Viewed',
                                  style: kTextStyle.copyWith(color: kNeutralColor, fontWeight: FontWeight.bold),
                                ),
                                const Spacer(),
                                GestureDetector(
                                  onTap: () => const RecentlyView().launch(context),
                                  child: Text(
                                    'View All',
                                    style: kTextStyle.copyWith(color: kLightNeutralColor),
                                  ),
                                ),
                              ],
                            ),
                          ),
                          _recentlyViewed.isEmpty
                              ? Padding(
                                  padding: const EdgeInsets.all(20.0),
                                  child: Text('No recently viewed services', style: kTextStyle.copyWith(color: kLightNeutralColor)),
                                )
                              : HorizontalList(
                                  physics: const BouncingScrollPhysics(),
                                  padding: const EdgeInsets.only(top: 20, bottom: 10, left: 15.0, right: 15.0),
                                  spacing: 10.0,
                                  itemCount: _recentlyViewed.length,
                                  itemBuilder: (_, i) {
                                    final service = _recentlyViewed[i];
                                    final seller = service['profiles'] as Map<String, dynamic>?;
                                    final images = service['images'] as List<dynamic>?;
                                    final imageUrl = (images != null && images.isNotEmpty) ? images[0] : null;

                                    return Padding(
                                      padding: const EdgeInsets.only(bottom: 10.0),
                                      child: GestureDetector(
                                        onTap: () => ClientServiceDetails(serviceId: service['id']).launch(context),
                                        child: Container(
                                          height: 120,
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
                                          child: Row(
                                            mainAxisSize: MainAxisSize.min,
                                            mainAxisAlignment: MainAxisAlignment.start,
                                            children: [
                                              Container(
                                                height: 120,
                                                width: 120,
                                                decoration: BoxDecoration(
                                                  borderRadius: const BorderRadius.only(
                                                    bottomLeft: Radius.circular(8.0),
                                                    topLeft: Radius.circular(8.0),
                                                  ),
                                                  image: DecorationImage(
                                                    image: imageUrl != null
                                                        ? NetworkImage(imageUrl) as ImageProvider
                                                        : const AssetImage('images/shot5.png'),
                                                    fit: BoxFit.cover,
                                                  ),
                                                ),
                                              ),
                                              Padding(
                                                padding: const EdgeInsets.all(5.0),
                                                child: Column(
                                                  crossAxisAlignment: CrossAxisAlignment.start,
                                                  mainAxisSize: MainAxisSize.min,
                                                  children: [
                                                    Flexible(
                                                      child: SizedBox(
                                                        width: 190,
                                                        child: Text(
                                                          service['title'] ?? 'Service',
                                                          style: kTextStyle.copyWith(color: kNeutralColor, fontWeight: FontWeight.bold),
                                                          maxLines: 2,
                                                          overflow: TextOverflow.ellipsis,
                                                        ),
                                                      ),
                                                    ),
                                                    const SizedBox(height: 5.0),
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
                                                          '${service['rating'] ?? 0}',
                                                          style: kTextStyle.copyWith(color: kNeutralColor),
                                                        ),
                                                        const SizedBox(width: 2.0),
                                                        Text(
                                                          '(${service['review_count'] ?? 0})',
                                                          style: kTextStyle.copyWith(color: kLightNeutralColor),
                                                        ),
                                                        const SizedBox(width: 40),
                                                        RichText(
                                                          text: TextSpan(
                                                            text: 'Price: ',
                                                            style: kTextStyle.copyWith(color: kLightNeutralColor),
                                                            children: [
                                                              TextSpan(
                                                                text: '$currencySign${service['price'] ?? 0}',
                                                                style: kTextStyle.copyWith(color: kPrimaryColor, fontWeight: FontWeight.bold),
                                                              )
                                                            ],
                                                          ),
                                                        )
                                                      ],
                                                    ),
                                                    const SizedBox(height: 5.0),
                                                    Row(
                                                      children: [
                                                        Container(
                                                          height: 32,
                                                          width: 32,
                                                          decoration: BoxDecoration(
                                                            shape: BoxShape.circle,
                                                            image: DecorationImage(
                                                              image: seller?['profile_image_url'] != null
                                                                  ? NetworkImage(seller!['profile_image_url']) as ImageProvider
                                                                  : const AssetImage('images/profilepic2.png'),
                                                              fit: BoxFit.cover,
                                                            ),
                                                          ),
                                                        ),
                                                        const SizedBox(width: 5.0),
                                                        Text(
                                                          seller?['name'] ?? 'Seller',
                                                          maxLines: 1,
                                                          overflow: TextOverflow.ellipsis,
                                                          style: kTextStyle.copyWith(color: kNeutralColor, fontWeight: FontWeight.bold),
                                                        ),
                                                      ],
                                                    ),
                                                  ],
                                                ),
                                              ),
                                            ],
                                          ),
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
