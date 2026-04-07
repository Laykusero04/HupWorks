import 'package:flutter/material.dart';
import 'package:flutter_iconly/flutter_iconly.dart';
import 'package:nb_utils/nb_utils.dart';

import '../../widgets/constant.dart';

class TopSeller extends StatefulWidget {
  const TopSeller({Key? key}) : super(key: key);

  @override
  State<TopSeller> createState() => _TopSellerState();
}

class _TopSellerState extends State<TopSeller> {
  List<String> serviceList = [
    'All',
    'Logo Designer',
    'Programmer',
    'Developer',
  ];

  String selectedServiceList = 'All';

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: kDarkWhite,
      appBar: AppBar(
        elevation: 0.0,
        backgroundColor: kDarkWhite,
        centerTitle: true,
        iconTheme: const IconThemeData(color: kNeutralColor),
        title: Text(
          'Top Sellers',
          style: kTextStyle.copyWith(color: kNeutralColor, fontWeight: FontWeight.bold),
        ),
      ),
      body: Padding(
        padding: const EdgeInsets.only(top: 15.0),
        child: Container(
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
                const SizedBox(height: 15.0),
                HorizontalList(
                  padding: const EdgeInsets.only(left: 15.0, right: 15.0),
                  itemCount: serviceList.length,
                  itemBuilder: (_, i) {
                    return Padding(
                      padding: const EdgeInsets.only(bottom: 10.0),
                      child: GestureDetector(
                        onTap: () {
                          setState(() {
                            selectedServiceList = serviceList[i];
                          });
                        },
                        child: Container(
                          padding: const EdgeInsets.all(10),
                          decoration: BoxDecoration(
                            color: selectedServiceList == serviceList[i] ? kPrimaryColor : kDarkWhite,
                            borderRadius: BorderRadius.circular(40.0),
                          ),
                          child: Text(
                            serviceList[i],
                            style: kTextStyle.copyWith(
                              color: selectedServiceList == serviceList[i] ? kWhite : kNeutralColor,
                            ),
                          ),
                        ),
                      ),
                    );
                  },
                ),
                Padding(
                  padding: const EdgeInsets.all(15.0),
                  child: GridView.count(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    mainAxisSpacing: 10.0,
                    crossAxisSpacing: 10.0,
                    childAspectRatio: 0.7,
                    crossAxisCount: 2,
                    children: List.generate(
                      10,
                      (index) => Container(
                        height: 220,
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
                              width: context.width(),
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
                                      Text(
                                        '(520 review)',
                                        style: kTextStyle.copyWith(color: kLightNeutralColor),
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
                    ),
                  ),
                )
              ],
            ),
          ),
        ),
      ),
    );
  }
}
