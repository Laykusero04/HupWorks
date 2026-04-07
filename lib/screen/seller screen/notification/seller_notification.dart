import 'package:badges/badges.dart' as t;
import 'package:flutter/material.dart';
import 'package:flutter_feather_icons/flutter_feather_icons.dart';
import 'package:nb_utils/nb_utils.dart';

import '../../widgets/constant.dart';

class SellerNotification extends StatefulWidget {
  const SellerNotification({Key? key}) : super(key: key);

  @override
  State<SellerNotification> createState() => _SellerNotificationState();
}

class _SellerNotificationState extends State<SellerNotification> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: kDarkWhite,
      appBar: AppBar(
        backgroundColor: kDarkWhite,
        elevation: 0,
        iconTheme: const IconThemeData(color: kNeutralColor),
        title: Text(
          'Notifications',
          style: kTextStyle.copyWith(color: kNeutralColor, fontWeight: FontWeight.bold),
        ),
        centerTitle: true,
      ),
      body: Padding(
        padding: const EdgeInsets.only(top: 15.0),
        child: Container(
          padding: const EdgeInsets.only(left: 15.0, right: 15.0),
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
                const SizedBox(height: 15.0),
                ListTile(
                  contentPadding: EdgeInsets.zero,
                  leading: Container(
                    padding: const EdgeInsets.all(10.0),
                    decoration: const BoxDecoration(shape: BoxShape.circle, color: kDarkWhite),
                    child: const Icon(FeatherIcons.bell),
                  ),
                  title: Text(
                    'Start left feedback on their order.Rate your experience to view their',
                    overflow: TextOverflow.ellipsis,
                    maxLines: 2,
                    style: kTextStyle.copyWith(color: kNeutralColor),
                  ),
                  subtitle: Text(
                    '2 min ago “New Message”',
                    overflow: TextOverflow.ellipsis,
                    maxLines: 2,
                    style: kTextStyle.copyWith(color: kLightNeutralColor),
                  ),
                ),
                ListView.builder(
                  padding: EdgeInsets.zero,
                  physics: const NeverScrollableScrollPhysics(),
                  itemCount: 10,
                  shrinkWrap: true,
                  itemBuilder: (_, i) {
                    return Column(
                      children: [
                        ListTile(
                          visualDensity: const VisualDensity(vertical: -4),
                          contentPadding: EdgeInsets.zero,
                          leading: Stack(
                            alignment: Alignment.bottomRight,
                            children: [
                              Container(
                                height: 45,
                                width: 45,
                                padding: const EdgeInsets.all(10.0),
                                decoration: const BoxDecoration(
                                  shape: BoxShape.circle,
                                  color: kDarkWhite,
                                  image: DecorationImage(image: AssetImage('images/profilepic.png'), fit: BoxFit.cover),
                                ),
                              ),
                              const Padding(
                                padding: EdgeInsets.only(right: 5.0),
                                child: t.Badge(
                                  badgeStyle: t.BadgeStyle(
                                    elevation: 0,
                                    shape: t.BadgeShape.circle,
                                    badgeColor: kPrimaryColor,
                                    borderSide: BorderSide(color: kWhite, width: 1.0),
                                  ),
                                ),
                              ),
                            ],
                          ),
                          title: Text(
                            'Leslie Alexander',
                            overflow: TextOverflow.ellipsis,
                            maxLines: 1,
                            style: kTextStyle.copyWith(color: kNeutralColor),
                          ),
                          subtitle: Text(
                            '2 min ago “New Message”',
                            overflow: TextOverflow.ellipsis,
                            maxLines: 1,
                            style: kTextStyle.copyWith(color: kLightNeutralColor),
                          ),
                        ),
                        ListTile(
                          visualDensity: const VisualDensity(vertical: -4),
                          contentPadding: EdgeInsets.zero,
                          leading: Stack(
                            alignment: Alignment.bottomRight,
                            children: [
                              Container(
                                height: 45,
                                width: 45,
                                padding: const EdgeInsets.all(10.0),
                                decoration: const BoxDecoration(
                                  shape: BoxShape.circle,
                                  color: kDarkWhite,
                                  image: DecorationImage(image: AssetImage('images/profilepic.png'), fit: BoxFit.cover),
                                ),
                              ),
                              const Padding(
                                padding: EdgeInsets.only(right: 5.0),
                                child: t.Badge(
                                  badgeStyle: t.BadgeStyle(
                                    elevation: 0,
                                    shape: t.BadgeShape.circle,
                                    badgeColor: kPrimaryColor,
                                    borderSide: BorderSide(color: kWhite, width: 1.0),
                                  ),
                                ),
                              ),
                            ],
                          ),
                          title: Text(
                            'Leslie Alexander',
                            overflow: TextOverflow.ellipsis,
                            maxLines: 1,
                            style: kTextStyle.copyWith(color: kNeutralColor),
                          ),
                          subtitle: Text(
                            '7 min ago “New Message”',
                            overflow: TextOverflow.ellipsis,
                            maxLines: 1,
                            style: kTextStyle.copyWith(color: kLightNeutralColor),
                          ),
                        ),
                        ListTile(
                          visualDensity: const VisualDensity(vertical: -4),
                          contentPadding: EdgeInsets.zero,
                          leading: Stack(
                            alignment: Alignment.bottomRight,
                            children: [
                              Container(
                                height: 45,
                                width: 45,
                                padding: const EdgeInsets.all(10.0),
                                decoration: const BoxDecoration(
                                  shape: BoxShape.circle,
                                  color: kDarkWhite,
                                  image: DecorationImage(image: AssetImage('images/profilepic.png'), fit: BoxFit.cover),
                                ),
                              ),
                              const Padding(
                                padding: EdgeInsets.only(right: 5.0),
                                child: t.Badge(
                                  badgeStyle: t.BadgeStyle(
                                    elevation: 0,
                                    shape: t.BadgeShape.circle,
                                    badgeColor: kPrimaryColor,
                                    borderSide: BorderSide(color: kWhite, width: 1.0),
                                  ),
                                ),
                              ),
                            ],
                          ),
                          title: Text(
                            'Leslie Alexander',
                            overflow: TextOverflow.ellipsis,
                            maxLines: 1,
                            style: kTextStyle.copyWith(color: kNeutralColor),
                          ),
                          subtitle: Text(
                            '1 day ago “New Message”',
                            overflow: TextOverflow.ellipsis,
                            maxLines: 1,
                            style: kTextStyle.copyWith(color: kLightNeutralColor),
                          ),
                        ),
                      ],
                    );
                  },
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
