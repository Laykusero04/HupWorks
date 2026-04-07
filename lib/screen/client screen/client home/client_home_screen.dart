import 'package:flutter/material.dart';
import 'package:flutter_feather_icons/flutter_feather_icons.dart';
import 'package:flutter_iconly/flutter_iconly.dart';
import 'package:freelancer/screen/client%20screen/client%20home/popular_services.dart';
import 'package:freelancer/screen/client%20screen/client%20home/recently_view.dart';
import 'package:freelancer/screen/client%20screen/client%20home/top_seller.dart';
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
  @override
  Widget build(BuildContext context) {
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
              child: GestureDetector(
                // onTap: ()=>const SellerProfile().launch(context),
                child: Container(
                  height: 44,
                  width: 44,
                  decoration: const BoxDecoration(
                    shape: BoxShape.circle,
                    image: DecorationImage(image: AssetImage('images/profile3.png'), fit: BoxFit.cover),
                  ),
                ),
              ),
            ),
            title: Text(
              'Shaidulislam',
              style: kTextStyle.copyWith(color: kNeutralColor, fontWeight: FontWeight.bold),
            ),
            subtitle: Text(
              'I’m a Client',
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
        body: Padding(
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
            child: SingleChildScrollView(
              physics: const BouncingScrollPhysics(),
              child: Column(
                children: [
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
                  HorizontalList(
                    physics: const BouncingScrollPhysics(),
                    padding: const EdgeInsets.only(left: 15),
                    spacing: 10.0,
                    itemCount: 10,
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
                  HorizontalList(
                    physics: const BouncingScrollPhysics(),
                    padding: const EdgeInsets.only(top: 20, bottom: 20, left: 15.0, right: 15.0),
                    spacing: 10.0,
                    itemCount: catName.length,
                    itemBuilder: (_, i) {
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
                                image: DecorationImage(image: AssetImage(catIcon[i]), fit: BoxFit.cover),
                              ),
                            ),
                            const SizedBox(width: 5.0),
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  catName[i],
                                  style: kTextStyle.copyWith(color: kNeutralColor, fontWeight: FontWeight.bold),
                                ),
                                const SizedBox(height: 2.0),
                                Text(
                                  'Related all categories',
                                  style: kTextStyle.copyWith(color: kLightNeutralColor),
                                ),
                              ],
                            ),
                          ],
                        ),
                      );
                    },
                  ),
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
                  HorizontalList(
                    physics: const BouncingScrollPhysics(),
                    padding: const EdgeInsets.only(top: 20, bottom: 20, left: 15.0, right: 15.0),
                    spacing: 10.0,
                    itemCount: 10,
                    itemBuilder: (_, i) {
                      return Padding(
                        padding: const EdgeInsets.only(bottom: 10.0),
                        child: GestureDetector(
                          onTap: () => const ClientServiceDetails().launch(context),
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
                                Stack(
                                  alignment: Alignment.topLeft,
                                  children: [
                                    Container(
                                      height: 120,
                                      width: 120,
                                      decoration: const BoxDecoration(
                                        borderRadius: BorderRadius.only(
                                          bottomLeft: Radius.circular(8.0),
                                          topLeft: Radius.circular(8.0),
                                        ),
                                        image: DecorationImage(
                                            image: AssetImage(
                                              'images/shot1.png',
                                            ),
                                            fit: BoxFit.cover),
                                      ),
                                    ),
                                    GestureDetector(
                                      onTap: () {
                                        setState(() {
                                          isFavorite = !isFavorite;
                                        });
                                      },
                                      child: Padding(
                                        padding: const EdgeInsets.all(5.0),
                                        child: Container(
                                          height: 25,
                                          width: 25,
                                          decoration: const BoxDecoration(
                                            color: Colors.white,
                                            shape: BoxShape.circle,
                                            boxShadow: [
                                              BoxShadow(
                                                color: Colors.black12,
                                                blurRadius: 10.0,
                                                spreadRadius: 1.0,
                                                offset: Offset(0, 2),
                                              ),
                                            ],
                                          ),
                                          child: isFavorite
                                              ? const Center(
                                                  child: Icon(
                                                    Icons.favorite,
                                                    color: Colors.red,
                                                    size: 16.0,
                                                  ),
                                                )
                                              : const Center(
                                                  child: Icon(
                                                    Icons.favorite_border,
                                                    color: kNeutralColor,
                                                    size: 16.0,
                                                  ),
                                                ),
                                        ),
                                      ),
                                    ),
                                  ],
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
                                            'Mobile UI UX design or app design',
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
                                            '5.0',
                                            style: kTextStyle.copyWith(color: kNeutralColor),
                                          ),
                                          const SizedBox(width: 2.0),
                                          Text(
                                            '(520)',
                                            style: kTextStyle.copyWith(color: kLightNeutralColor),
                                          ),
                                          const SizedBox(width: 40),
                                          RichText(
                                            text: TextSpan(
                                              text: 'Price: ',
                                              style: kTextStyle.copyWith(color: kLightNeutralColor),
                                              children: [
                                                TextSpan(
                                                  text: '$currencySign${30}',
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
                                            decoration: const BoxDecoration(
                                              shape: BoxShape.circle,
                                              image: DecorationImage(image: AssetImage('images/profilepic2.png'), fit: BoxFit.cover),
                                            ),
                                          ),
                                          const SizedBox(width: 5.0),
                                          Column(
                                            crossAxisAlignment: CrossAxisAlignment.start,
                                            children: [
                                              Text(
                                                'William Liam',
                                                maxLines: 1,
                                                overflow: TextOverflow.ellipsis,
                                                style: kTextStyle.copyWith(color: kNeutralColor, fontWeight: FontWeight.bold),
                                              ),
                                              Text(
                                                'Seller Level - 1',
                                                maxLines: 1,
                                                overflow: TextOverflow.ellipsis,
                                                style: kTextStyle.copyWith(color: kSubTitleColor),
                                              ),
                                            ],
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
                  HorizontalList(
                    physics: const BouncingScrollPhysics(),
                    padding: const EdgeInsets.only(top: 20, bottom: 20, left: 15.0, right: 15.0),
                    spacing: 10.0,
                    itemCount: 10,
                    itemBuilder: (_, i) {
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
                                decoration: const BoxDecoration(
                                  borderRadius: BorderRadius.only(
                                    topRight: Radius.circular(8.0),
                                    topLeft: Radius.circular(8.0),
                                  ),
                                  image: DecorationImage(
                                      image: AssetImage(
                                        'images/dev1.png',
                                      ),
                                      fit: BoxFit.cover),
                                ),
                              ),
                              Padding(
                                padding: const EdgeInsets.all(6.0),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      'William Liam',
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
                                          '5.0',
                                          style: kTextStyle.copyWith(color: kNeutralColor),
                                        ),
                                        const SizedBox(width: 2.0),
                                        Flexible(
                                          child: Text(
                                            '(520 review)',
                                            style: kTextStyle.copyWith(color: kLightNeutralColor),
                                            overflow: TextOverflow.ellipsis,
                                          ),
                                        ),
                                      ],
                                    ),
                                    const SizedBox(height: 6.0),
                                    RichText(
                                      text: TextSpan(
                                        text: 'Seller Level - ',
                                        style: kTextStyle.copyWith(color: kNeutralColor),
                                        children: [
                                          TextSpan(
                                            text: '2',
                                            style: kTextStyle.copyWith(color: kLightNeutralColor),
                                          )
                                        ],
                                      ),
                                    )
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),
                      );
                    },
                  ),
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
                  HorizontalList(
                    physics: const BouncingScrollPhysics(),
                    padding: const EdgeInsets.only(top: 20, bottom: 10, left: 15.0, right: 15.0),
                    spacing: 10.0,
                    itemCount: 10,
                    itemBuilder: (_, i) {
                      return Padding(
                        padding: const EdgeInsets.only(bottom: 10.0),
                        child: GestureDetector(
                          onTap: () => const ClientServiceDetails().launch(context),
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
                                Stack(
                                  alignment: Alignment.topLeft,
                                  children: [
                                    Container(
                                      height: 120,
                                      width: 120,
                                      decoration: const BoxDecoration(
                                        borderRadius: BorderRadius.only(
                                          bottomLeft: Radius.circular(8.0),
                                          topLeft: Radius.circular(8.0),
                                        ),
                                        image: DecorationImage(
                                            image: AssetImage(
                                              'images/shot5.png',
                                            ),
                                            fit: BoxFit.cover),
                                      ),
                                    ),
                                    GestureDetector(
                                      onTap: () {
                                        setState(() {
                                          isFavorite = !isFavorite;
                                        });
                                      },
                                      child: Padding(
                                        padding: const EdgeInsets.all(5.0),
                                        child: Container(
                                          height: 25,
                                          width: 25,
                                          decoration: const BoxDecoration(
                                            color: Colors.white,
                                            shape: BoxShape.circle,
                                            boxShadow: [
                                              BoxShadow(
                                                color: Colors.black12,
                                                blurRadius: 10.0,
                                                spreadRadius: 1.0,
                                                offset: Offset(0, 2),
                                              ),
                                            ],
                                          ),
                                          child: isFavorite
                                              ? const Center(
                                                  child: Icon(
                                                    Icons.favorite,
                                                    color: Colors.red,
                                                    size: 16.0,
                                                  ),
                                                )
                                              : const Center(
                                                  child: Icon(
                                                    Icons.favorite_border,
                                                    color: kNeutralColor,
                                                    size: 16.0,
                                                  ),
                                                ),
                                        ),
                                      ),
                                    ),
                                  ],
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
                                            'modern unique business logo design',
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
                                            '5.0',
                                            style: kTextStyle.copyWith(color: kNeutralColor),
                                          ),
                                          const SizedBox(width: 2.0),
                                          Text(
                                            '(520)',
                                            style: kTextStyle.copyWith(color: kLightNeutralColor),
                                          ),
                                          const SizedBox(width: 40),
                                          RichText(
                                            text: TextSpan(
                                              text: 'Price: ',
                                              style: kTextStyle.copyWith(color: kLightNeutralColor),
                                              children: [
                                                TextSpan(
                                                  text: '$currencySign${30}',
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
                                            decoration: const BoxDecoration(
                                              shape: BoxShape.circle,
                                              image: DecorationImage(image: AssetImage('images/profilepic2.png'), fit: BoxFit.cover),
                                            ),
                                          ),
                                          const SizedBox(width: 5.0),
                                          Column(
                                            crossAxisAlignment: CrossAxisAlignment.start,
                                            children: [
                                              Text(
                                                'William Liam',
                                                maxLines: 1,
                                                overflow: TextOverflow.ellipsis,
                                                style: kTextStyle.copyWith(color: kNeutralColor, fontWeight: FontWeight.bold),
                                              ),
                                              Text(
                                                'Seller Level - 1',
                                                maxLines: 1,
                                                overflow: TextOverflow.ellipsis,
                                                style: kTextStyle.copyWith(color: kSubTitleColor),
                                              ),
                                            ],
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
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
