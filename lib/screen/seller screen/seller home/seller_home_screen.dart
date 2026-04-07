import 'package:flutter/material.dart';
import 'package:flutter_feather_icons/flutter_feather_icons.dart';
import 'package:flutter_iconly/flutter_iconly.dart';
import 'package:freelancer/screen/seller%20screen/profile/seller_profile.dart';
import 'package:freelancer/screen/seller%20screen/seller%20home/my%20service/service_details.dart';
import 'package:freelancer/screen/widgets/constant.dart';
import 'package:nb_utils/nb_utils.dart';

import '../../widgets/chart.dart';
import '../../widgets/data.dart';
import '../notification/seller_notification.dart';
import 'my service/my_service.dart';

class SellerHomeScreen extends StatefulWidget {
  const SellerHomeScreen({Key? key}) : super(key: key);

  @override
  State<SellerHomeScreen> createState() => _SellerHomeScreenState();
}

class _SellerHomeScreenState extends State<SellerHomeScreen> {
  //__________performance_time_period_____________________________________________________
  DropdownButton<String> getPerformancePeriod() {
    List<DropdownMenuItem<String>> dropDownItems = [];
    for (String des in period) {
      var item = DropdownMenuItem(
        value: des,
        child: Text(
          des,
          style: kTextStyle.copyWith(color: kSubTitleColor),
        ),
      );
      dropDownItems.add(item);
    }
    return DropdownButton(
      icon: const Icon(FeatherIcons.chevronDown),
      items: dropDownItems,
      value: selectedPeriod,
      style: kTextStyle.copyWith(color: kSubTitleColor),
      onChanged: (value) {
        setState(() {
          selectedPeriod = value!;
        });
      },
    );
  }

  //__________statistics_time_period_____________________________________________________
  DropdownButton<String> getStatisticsPeriod() {
    List<DropdownMenuItem<String>> dropDownItems = [];
    for (String des in staticsPeriod) {
      var item = DropdownMenuItem(
        value: des,
        child: Text(
          des,
          style: kTextStyle.copyWith(color: kSubTitleColor),
        ),
      );
      dropDownItems.add(item);
    }
    return DropdownButton(
      icon: const Icon(FeatherIcons.chevronDown),
      items: dropDownItems,
      value: selectedStaticsPeriod,
      style: kTextStyle.copyWith(color: kSubTitleColor),
      onChanged: (value) {
        setState(() {
          selectedStaticsPeriod = value!;
        });
      },
    );
  }

  //__________earning_time_period_____________________________________________________
  DropdownButton<String> getEarningPeriod() {
    List<DropdownMenuItem<String>> dropDownItems = [];
    for (String des in earningPeriod) {
      var item = DropdownMenuItem(
        value: des,
        child: Text(
          des,
          style: kTextStyle.copyWith(color: kSubTitleColor),
        ),
      );
      dropDownItems.add(item);
    }
    return DropdownButton(
      icon: const Icon(FeatherIcons.chevronDown),
      items: dropDownItems,
      value: selectedEarningPeriod,
      style: kTextStyle.copyWith(color: kSubTitleColor),
      onChanged: (value) {
        setState(() {
          selectedEarningPeriod = value!;
        });
      },
    );
  }

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
            contentPadding: EdgeInsets.zero,
            leading: Padding(
              padding: const EdgeInsets.only(left: 10.0),
              child: GestureDetector(
                onTap: () => const SellerProfile().launch(context),
                child: Container(
                  height: 44,
                  width: 44,
                  decoration: const BoxDecoration(
                    shape: BoxShape.circle,
                    image: DecorationImage(
                      image: AssetImage('images/profilepic.png'),
                    ),
                  ),
                ),
              ),
            ),
            title: Text(
              'Mr. Panda Swamy',
              style: kTextStyle.copyWith(color: kNeutralColor, fontWeight: FontWeight.bold),
            ),
            subtitle: Text(
              'New Seller',
              style: kTextStyle.copyWith(color: kLightNeutralColor),
            ),
            trailing: GestureDetector(
              onTap: () => const SellerNotification().launch(context),
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
            padding: const EdgeInsets.only(left: 15.0, right: 15.0),
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
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const SizedBox(height: 15.0),
                  Container(
                    padding: const EdgeInsets.all(10.0),
                    decoration: BoxDecoration(
                      color: kWhite,
                      borderRadius: BorderRadius.circular(16.0),
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
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Row(
                          children: [
                            Text(
                              'Performance',
                              style: kTextStyle.copyWith(color: kNeutralColor, fontWeight: FontWeight.bold),
                            ),
                            const Spacer(),
                            SizedBox(
                              height: 30,
                              child: Container(
                                padding: const EdgeInsets.all(5.0),
                                decoration: BoxDecoration(
                                  borderRadius: BorderRadius.circular(30.0),
                                  border: Border.all(color: kLightNeutralColor),
                                ),
                                child: DropdownButtonHideUnderline(
                                  child: getPerformancePeriod(),
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 15.0),
                        Row(
                          children: const [
                            Expanded(
                              flex: 1,
                              child: Summary(
                                title: '80 Orders',
                                subtitle: 'Order Completions',
                              ),
                            ),
                            SizedBox(width: 10.0),
                            Expanded(
                              flex: 1,
                              child: Summary2(
                                title1: '5.0/',
                                title2: '5.0',
                                subtitle: 'Positive Ratings',
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 10.0),
                        Row(
                          children: const [
                            Expanded(
                              flex: 1,
                              child: Summary(
                                title: '100% On time',
                                subtitle: 'On-Time-Delivery',
                              ),
                            ),
                            SizedBox(width: 10.0),
                            Expanded(
                              flex: 1,
                              child: Summary(
                                title: 'Gigs 6 of 7',
                                subtitle: 'Total Gig',
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 20.0),
                  Container(
                    padding: const EdgeInsets.all(10.0),
                    decoration: BoxDecoration(
                      color: kWhite,
                      borderRadius: BorderRadius.circular(16.0),
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
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisSize: MainAxisSize.min,
                      mainAxisAlignment: MainAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Text(
                              'Statistics',
                              style: kTextStyle.copyWith(color: kNeutralColor, fontWeight: FontWeight.bold),
                            ),
                            const Spacer(),
                            SizedBox(
                              height: 30,
                              child: Container(
                                padding: const EdgeInsets.all(5.0),
                                decoration: BoxDecoration(
                                  borderRadius: BorderRadius.circular(30.0),
                                  border: Border.all(color: kLightNeutralColor),
                                ),
                                child: DropdownButtonHideUnderline(
                                  child: getStatisticsPeriod(),
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 15.0),
                        Row(
                          crossAxisAlignment: CrossAxisAlignment.center,
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Expanded(
                              flex: 1,
                              child: RecordStatistics(
                                dataMap: dataMap,
                                colorList: colorList,
                              ),
                            ),
                            Expanded(
                              flex: 1,
                              child: Column(
                                children: const [
                                  ChartLegend(
                                    iconColor: Color(0xFF69B22A),
                                    title: 'Impressions',
                                    value: '5.3K',
                                  ),
                                  ChartLegend(
                                    iconColor: Color(0xFF144BD6),
                                    title: 'Interaction',
                                    value: '3.5K',
                                  ),
                                  ChartLegend(
                                    iconColor: Color(0xFFFF3B30),
                                    title: 'Reached-Out',
                                    value: '2.3K',
                                  ),
                                ],
                              ),
                            ),
                          ],
                        )
                      ],
                    ),
                  ),
                  const SizedBox(height: 20.0),
                  Container(
                    padding: const EdgeInsets.all(10.0),
                    decoration: BoxDecoration(
                      color: kWhite,
                      borderRadius: BorderRadius.circular(16.0),
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
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Row(
                          children: [
                            Text(
                              'Earnings',
                              style: kTextStyle.copyWith(color: kNeutralColor, fontWeight: FontWeight.bold),
                            ),
                            const Spacer(),
                            SizedBox(
                              height: 30,
                              child: Container(
                                padding: const EdgeInsets.all(5.0),
                                decoration: BoxDecoration(
                                  borderRadius: BorderRadius.circular(30.0),
                                  border: Border.all(color: kLightNeutralColor),
                                ),
                                child: DropdownButtonHideUnderline(
                                  child: getEarningPeriod(),
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 15.0),
                        Row(
                          children: const [
                            Expanded(
                              flex: 1,
                              child: Summary(
                                title: '$currencySign${500.00}',
                                subtitle: 'Total Earnings',
                              ),
                            ),
                            SizedBox(width: 10.0),
                            Expanded(
                              flex: 1,
                              child: Summary(
                                title: '$currencySign${300.00}',
                                subtitle: 'Withdraw Earnings',
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 10.0),
                        Row(
                          children: const [
                            Expanded(
                              flex: 1,
                              child: Summary(
                                title: '$currencySign${300.00}',
                                subtitle: 'Current Balance',
                              ),
                            ),
                            SizedBox(width: 10.0),
                            Expanded(
                              flex: 1,
                              child: Summary(
                                title: '$currencySign${300.00}',
                                subtitle: 'Active Orders',
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 10.0),
                  Theme(
                    data: Theme.of(context).copyWith(dividerColor: Colors.transparent),
                    child: ExpansionTile(
                      initiallyExpanded: true,
                      tilePadding: EdgeInsets.zero,
                      childrenPadding: EdgeInsets.zero,
                      collapsedIconColor: kLightNeutralColor,
                      iconColor: kLightNeutralColor,
                      title: Text(
                        'Reach Your Next Level',
                        style: kTextStyle.copyWith(color: kNeutralColor, fontWeight: FontWeight.bold),
                      ),
                      children: const [
                        LevelSummary(
                          title: 'Level 1',
                          subTitle: 'Receive and complete at least 30 orders (all time)',
                          trailing1: '20',
                          trailing2: '30',
                        ),
                        SizedBox(height: 15.0),
                        LevelSummary(
                          title: 'Level 2',
                          subTitle: 'Receive and complete at least 30 orders (all time)',
                          trailing1: '0',
                          trailing2: '70',
                        ),
                        SizedBox(height: 15.0),
                        LevelSummary(
                          title: 'Level 3',
                          subTitle: 'Receive and complete at least 30 orders (all time)',
                          trailing1: '0',
                          trailing2: '120',
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 20.0),
                  Row(
                    children: [
                      Text(
                        'My Services',
                        style: kTextStyle.copyWith(color: kNeutralColor, fontWeight: FontWeight.bold),
                      ),
                      const Spacer(),
                      GestureDetector(
                        onTap: () => const MyServices().launch(context),
                        child: Text(
                          'view All',
                          style: kTextStyle.copyWith(color: kLightNeutralColor),
                        ),
                      )
                    ],
                  ),
                  const SizedBox(height: 15.0),
                  HorizontalList(
                    spacing: 10.0,
                    padding: const EdgeInsets.only(bottom: 10.0),
                    itemCount: 10,
                    itemBuilder: (_, i) {
                      return GestureDetector(
                        onTap: () => const ServiceDetails().launch(context),
                        child: Container(
                          height: 205,
                          width: 156,
                          decoration: BoxDecoration(
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
                              Stack(
                                alignment: Alignment.topRight,
                                children: [
                                  Container(
                                    height: 100,
                                    width: 156,
                                    decoration: const BoxDecoration(
                                      borderRadius: BorderRadius.only(
                                        topRight: Radius.circular(8.0),
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
                                        height: 30,
                                        width: 30,
                                        decoration: const BoxDecoration(
                                          color: Colors.white,
                                          shape: BoxShape.circle,
                                        ),
                                        child: isFavorite
                                            ? const Center(
                                                child: Icon(
                                                  Icons.favorite,
                                                  color: Colors.red,
                                                  size: 18.0,
                                                ),
                                              )
                                            : const Center(
                                                child: Icon(
                                                  Icons.favorite_border,
                                                  color: kNeutralColor,
                                                  size: 18.0,
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
                                  children: [
                                    Text(
                                      'Mobile UI UX design or app design',
                                      style: kTextStyle.copyWith(color: kNeutralColor, fontWeight: FontWeight.bold),
                                      maxLines: 2,
                                      overflow: TextOverflow.ellipsis,
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
                                          '(520 review)',
                                          style: kTextStyle.copyWith(color: kLightNeutralColor),
                                        ),
                                      ],
                                    ),
                                    const SizedBox(height: 5.0),
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
                              ),
                            ],
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

class ChartLegend extends StatelessWidget {
  const ChartLegend({
    Key? key,
    required this.iconColor,
    required this.title,
    required this.value,
  }) : super(key: key);

  final Color iconColor;
  final String title;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisAlignment: MainAxisAlignment.start,
      children: [
        Icon(
          Icons.circle,
          size: 16.0,
          color: iconColor,
        ),
        const SizedBox(width: 10.0),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              title,
              style: kTextStyle.copyWith(color: kSubTitleColor),
            ),
            const SizedBox(
              height: 5.0,
            ),
            Text(
              value,
              style: kTextStyle.copyWith(color: kNeutralColor, fontWeight: FontWeight.bold),
            ),
          ],
        ),
      ],
    );
  }
}
