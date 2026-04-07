import 'package:flutter/material.dart';
import 'package:flutter_iconly/flutter_iconly.dart';
import 'package:nb_utils/nb_utils.dart';

import '../../widgets/constant.dart';
import '../client service details/client_service_details.dart';

class RecentlyView extends StatefulWidget {
  const RecentlyView({Key? key}) : super(key: key);

  @override
  State<RecentlyView> createState() => _RecentlyViewState();
}

class _RecentlyViewState extends State<RecentlyView> {
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
          'Recent Viewed',
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
                Padding(
                  padding: const EdgeInsets.all(15.0),
                  child: ListView.builder(
                    shrinkWrap: true,
                    itemCount: 10,
                    physics: const NeverScrollableScrollPhysics(),
                    padding: EdgeInsets.zero,
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
                                            'Mobile UI UX design or app UI UX design.',
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
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
