import 'package:flutter/material.dart';
import 'package:flutter_feather_icons/flutter_feather_icons.dart';

import '../../widgets/constant.dart';

class ClientAllCategories extends StatefulWidget {
  const ClientAllCategories({Key? key}) : super(key: key);

  @override
  State<ClientAllCategories> createState() => _ClientAllCategoriesState();
}

class _ClientAllCategoriesState extends State<ClientAllCategories> {
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
          'All Categories',
          style: kTextStyle.copyWith(color: kNeutralColor, fontWeight: FontWeight.bold),
        ),
      ),
      body: Padding(
        padding: const EdgeInsets.only(top: 15.0),
        child: Container(
          padding: const EdgeInsets.only(left: 15.0, right: 15),
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
                ListView.builder(
                    itemCount: catName.length,
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    itemBuilder: (_, i) {
                      return Container(
                        margin: const EdgeInsets.only(top: 10.0),
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(8.0),
                          border: Border.all(color: kBorderColorTextField),
                        ),
                        child: Theme(
                          data: Theme.of(context).copyWith(dividerColor: Colors.transparent),
                          child: ExpansionTile(
                            initiallyExpanded: i == 0 ? true : false,
                            tilePadding: const EdgeInsets.only(left: 10.0, right: 10.0),
                            childrenPadding: EdgeInsets.zero,
                            leading: Container(
                              height: 40,
                              width: 40,
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                image: DecorationImage(image: AssetImage(catIcon[i]), fit: BoxFit.cover),
                              ),
                            ),
                            title: Text(
                              catName[i],
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: kTextStyle.copyWith(color: kNeutralColor, fontWeight: FontWeight.bold),
                            ),
                            subtitle: Text(
                              'Related all categories',
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: kTextStyle.copyWith(color: kLightNeutralColor),
                            ),
                            trailing: const Icon(
                              FeatherIcons.chevronDown,
                              color: kSubTitleColor,
                            ),
                            children: [
                              Column(
                                children: [
                                  const Divider(
                                    height: 1,
                                    thickness: 1.0,
                                    color: kBorderColorTextField,
                                  ),
                                  ListTile(
                                    visualDensity: const VisualDensity(vertical: -4),
                                    contentPadding: const EdgeInsets.only(left: 10.0, right: 10.0),
                                    horizontalTitleGap: 10,
                                    title: Text(
                                      'Logo Design',
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                      style: kTextStyle.copyWith(color: kSubTitleColor),
                                    ),
                                    trailing: GestureDetector(
                                      // onTap: () => const SellerNotification().launch(context),
                                      child: const Icon(
                                        FeatherIcons.chevronRight,
                                        color: kSubTitleColor,
                                      ),
                                    ),
                                  ),
                                  const Divider(
                                    thickness: 1.0,
                                    color: kBorderColorTextField,
                                  ),
                                  ListTile(
                                    visualDensity: const VisualDensity(vertical: -4),
                                    contentPadding: const EdgeInsets.only(left: 10.0, right: 10.0),
                                    horizontalTitleGap: 10,
                                    title: Text(
                                      'Brand Style Guides',
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                      style: kTextStyle.copyWith(color: kSubTitleColor),
                                    ),
                                    trailing: GestureDetector(
                                      // onTap: () => const SellerNotification().launch(context),
                                      child: const Icon(
                                        FeatherIcons.chevronRight,
                                        color: kSubTitleColor,
                                      ),
                                    ),
                                  ),
                                  const Divider(
                                    thickness: 1.0,
                                    color: kBorderColorTextField,
                                  ),
                                  ListTile(
                                    visualDensity: const VisualDensity(vertical: -4),
                                    contentPadding: const EdgeInsets.only(left: 10.0, right: 10.0),
                                    horizontalTitleGap: 10,
                                    title: Text(
                                      'Fonts & Typography',
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                      style: kTextStyle.copyWith(color: kSubTitleColor),
                                    ),
                                    trailing: GestureDetector(
                                      // onTap: () => const SellerNotification().launch(context),
                                      child: const Icon(
                                        FeatherIcons.chevronRight,
                                        color: kSubTitleColor,
                                      ),
                                    ),
                                  ),
                                  const Divider(
                                    thickness: 1.0,
                                    color: kBorderColorTextField,
                                  ),
                                  ListTile(
                                    visualDensity: const VisualDensity(vertical: -4),
                                    contentPadding: const EdgeInsets.only(left: 10.0, right: 10.0),
                                    horizontalTitleGap: 10,
                                    title: Text(
                                      'Business Cards & Stationery',
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                      style: kTextStyle.copyWith(color: kSubTitleColor),
                                    ),
                                    trailing: GestureDetector(
                                      // onTap: () => const SellerNotification().launch(context),
                                      child: const Icon(
                                        FeatherIcons.chevronRight,
                                        color: kSubTitleColor,
                                      ),
                                    ),
                                  ),
                                ],
                              )
                            ],
                          ),
                        ),
                      );
                    }),
                const SizedBox(
                  height: 15,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
