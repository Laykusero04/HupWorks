import 'package:flutter/material.dart';
import 'package:flutter_feather_icons/flutter_feather_icons.dart';
import 'package:flutter_iconly/flutter_iconly.dart';
import 'package:freelancer/screen/widgets/button_global.dart';
import 'package:nb_utils/nb_utils.dart';
import 'package:slide_countdown/slide_countdown.dart';

import '../../seller screen/seller messgae/chat_list.dart';
import '../../widgets/constant.dart';
import '../client popup/client_popup.dart';
import '../client review/client_review.dart';

class ClientOrderDetails extends StatefulWidget {
  const ClientOrderDetails({Key? key}) : super(key: key);

  @override
  State<ClientOrderDetails> createState() => _ClientOrderDetailsState();
}

class _ClientOrderDetailsState extends State<ClientOrderDetails> {
  //__________cancel_order_reason_popup________________________________________________
  void cancelOrderPopUp() {
    showDialog(
      barrierDismissible: false,
      context: context,
      builder: (BuildContext context) {
        return StatefulBuilder(
          builder: (BuildContext context, void Function(void Function()) setState) {
            return Dialog(
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(20.0),
              ),
              child: const CancelOrderPopUp(),
            );
          },
        );
      },
    );
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
          'Order Details',
          style: kTextStyle.copyWith(color: kNeutralColor, fontWeight: FontWeight.bold),
        ),
        centerTitle: true,
        actions: [
          PopupMenuButton(
            padding: EdgeInsets.zero,
            itemBuilder: (BuildContext context) => [
              PopupMenuItem(
                child: Row(
                  children: [
                    const Icon(IconlyBold.chat, color: kPrimaryColor),
                    const SizedBox(width: 5.0),
                    Text(
                      'Message',
                      style: kTextStyle.copyWith(color: kNeutralColor),
                    ).onTap(
                      () => const ChatScreen().launch(context),
                    ),
                  ],
                ),
              ),
              PopupMenuItem(
                  child: Row(
                children: [
                  const Icon(IconlyBold.document, color: Colors.red),
                  const SizedBox(width: 5.0),
                  Text(
                    'Report',
                    style: kTextStyle.copyWith(color: kNeutralColor),
                  ),
                ],
              ))
            ],
            onSelected: (value) {},
            child: const Padding(
              padding: EdgeInsets.only(right: 10.0),
              child: Icon(
                Icons.more_vert_rounded,
                color: kNeutralColor,
              ),
            ),
          ),
        ],
      ),
      bottomNavigationBar: Container(
        decoration: const BoxDecoration(
          color: kWhite,
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Expanded(
              child: ButtonGlobalWithoutIcon(
                buttontext: isSelected == 'Completed' ? 'Re-Order' : 'Cancel',
                buttonDecoration: kButtonDecoration.copyWith(
                  color: isSelected == 'Completed' ? kPrimaryColor : kWhite,
                  border: Border.all(color: isSelected == 'Completed' ? Colors.transparent : Colors.red),
                ),
                onPressed: () {
                  setState(() {
                    isSelected == 'Completed' ? Container() : cancelOrderPopUp();
                  });
                },
                buttonTextColor: isSelected == 'Completed' ? kWhite : Colors.red,
              ),
            ),
            Expanded(
              child: ButtonGlobalWithoutIcon(
                buttontext: isSelected == 'Completed' ? 'Review' : 'Deliver Work',
                buttonDecoration: kButtonDecoration.copyWith(
                  color: isSelected == 'Completed' ? kWhite : kPrimaryColor,
                  border: Border.all(color: isSelected == 'Completed' ? kPrimaryColor : Colors.transparent),
                ),
                onPressed: () {
                  setState(() {
                    const ClientOrderReview().launch(context);
                  });
                },
                buttonTextColor: isSelected == 'Completed' ? kPrimaryColor : kWhite,
              ),
            ),
          ],
        ),
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
                Container(
                  padding: const EdgeInsets.all(10.0),
                  width: context.width(),
                  decoration: BoxDecoration(color: kWhite, borderRadius: BorderRadius.circular(8.0), border: Border.all(color: kBorderColorTextField), boxShadow: const [BoxShadow(color: kDarkWhite, spreadRadius: 4.0, blurRadius: 4.0, offset: Offset(0, 2))]),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Text(
                            'Order ID #F025E15',
                            style: kTextStyle.copyWith(color: kNeutralColor, fontWeight: FontWeight.bold),
                          ),
                          const Spacer(),
                          SlideCountdownSeparated(
                            duration: const Duration(days: 3),
                            separatorType: SeparatorType.symbol,
                            separatorStyle: kTextStyle.copyWith(color: Colors.transparent),
                            decoration: BoxDecoration(
                              color: kPrimaryColor,
                              borderRadius: BorderRadius.circular(3.0),
                            ),
                          )
                        ],
                      ),
                      const SizedBox(height: 10.0),
                      RichText(
                        text: TextSpan(
                          text: 'Seller: ',
                          style: kTextStyle.copyWith(color: kLightNeutralColor),
                          children: [
                            TextSpan(
                              text: 'Shaidul Islam',
                              style: kTextStyle.copyWith(color: kNeutralColor),
                            ),
                            TextSpan(
                              text: '  |  ',
                              style: kTextStyle.copyWith(color: kLightNeutralColor),
                            ),
                            TextSpan(
                              text: '24 Jun 2023',
                              style: kTextStyle.copyWith(color: kLightNeutralColor),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 8.0),
                      const Divider(
                        thickness: 1.0,
                        color: kBorderColorTextField,
                        height: 1.0,
                      ),
                      const SizedBox(height: 8.0),
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Expanded(
                            flex: 2,
                            child: Text(
                              'Title',
                              style: kTextStyle.copyWith(color: kSubTitleColor),
                            ),
                          ),
                          Expanded(
                            flex: 4,
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.start,
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  ':',
                                  style: kTextStyle.copyWith(color: kSubTitleColor),
                                ),
                                const SizedBox(width: 10.0),
                                Flexible(
                                  child: Text(
                                    'Mobile UI UX design or app UI UX design',
                                    style: kTextStyle.copyWith(color: kSubTitleColor),
                                    overflow: TextOverflow.ellipsis,
                                    maxLines: 2,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8.0),
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Expanded(
                            flex: 2,
                            child: Text(
                              'Service Info',
                              style: kTextStyle.copyWith(color: kSubTitleColor),
                            ),
                          ),
                          Expanded(
                            flex: 4,
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.start,
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  ':',
                                  style: kTextStyle.copyWith(color: kSubTitleColor),
                                ),
                                const SizedBox(width: 10.0),
                                Flexible(
                                  child: ReadMoreText(
                                    'Lorem ipsum dolor sit amet consectetur. Tortor sapien aliquam amet elit. Quis varius amet grav ida molestie rhoncus. Lorem ipsum dolor sit amet consectetur. Tortor sapien aliquam amet elit. Quis varius amet grav ida molestie rhoncus.',
                                    style: kTextStyle.copyWith(color: kLightNeutralColor),
                                    trimLines: 3,
                                    colorClickableText: kPrimaryColor,
                                    trimMode: TrimMode.Line,
                                    trimCollapsedText: '..Read more',
                                    trimExpandedText: '..Read less',
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8.0),
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Expanded(
                            flex: 2,
                            child: Text(
                              'Duration',
                              style: kTextStyle.copyWith(color: kSubTitleColor),
                            ),
                          ),
                          Expanded(
                            flex: 4,
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.start,
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  ':',
                                  style: kTextStyle.copyWith(color: kSubTitleColor),
                                ),
                                const SizedBox(width: 10.0),
                                Flexible(
                                  child: Text(
                                    '3 Days',
                                    style: kTextStyle.copyWith(color: kSubTitleColor),
                                    overflow: TextOverflow.ellipsis,
                                    maxLines: 1,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8.0),
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Expanded(
                            flex: 2,
                            child: Text(
                              'Amount',
                              style: kTextStyle.copyWith(color: kSubTitleColor),
                            ),
                          ),
                          Expanded(
                            flex: 4,
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.start,
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  ':',
                                  style: kTextStyle.copyWith(color: kSubTitleColor),
                                ),
                                const SizedBox(width: 10.0),
                                Flexible(
                                  child: Text(
                                    '$currencySign${5.00}',
                                    style: kTextStyle.copyWith(color: kSubTitleColor),
                                    overflow: TextOverflow.ellipsis,
                                    maxLines: 1,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8.0),
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Expanded(
                            flex: 2,
                            child: Text(
                              'Status',
                              style: kTextStyle.copyWith(color: kSubTitleColor),
                            ),
                          ),
                          Expanded(
                            flex: 4,
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.start,
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  ':',
                                  style: kTextStyle.copyWith(color: kSubTitleColor),
                                ),
                                const SizedBox(width: 10.0),
                                Flexible(
                                  child: Text(
                                    'Active',
                                    style: kTextStyle.copyWith(color: kNeutralColor),
                                    overflow: TextOverflow.ellipsis,
                                    maxLines: 1,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 15.0),
                      Text(
                        'Order Details',
                        style: kTextStyle.copyWith(color: kNeutralColor, fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(height: 8.0),
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Expanded(
                            flex: 2,
                            child: Text(
                              'Revisions',
                              style: kTextStyle.copyWith(color: kSubTitleColor),
                            ),
                          ),
                          Expanded(
                            flex: 4,
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.start,
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  ':',
                                  style: kTextStyle.copyWith(color: kSubTitleColor),
                                ),
                                const SizedBox(width: 10.0),
                                Flexible(
                                  child: Text(
                                    'Unlimited Revisions',
                                    style: kTextStyle.copyWith(color: kSubTitleColor),
                                    overflow: TextOverflow.ellipsis,
                                    maxLines: 1,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8.0),
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Expanded(
                            flex: 2,
                            child: Text(
                              'File',
                              style: kTextStyle.copyWith(color: kSubTitleColor),
                            ),
                          ),
                          Expanded(
                            flex: 4,
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.start,
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  ':',
                                  style: kTextStyle.copyWith(color: kSubTitleColor),
                                ),
                                const SizedBox(width: 10.0),
                                Flexible(
                                  child: Text(
                                    'Source file, JPG, PNG, ZIP ',
                                    style: kTextStyle.copyWith(color: kSubTitleColor),
                                    overflow: TextOverflow.ellipsis,
                                    maxLines: 1,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8.0),
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Expanded(
                            flex: 2,
                            child: Text(
                              'Resolution',
                              style: kTextStyle.copyWith(color: kSubTitleColor),
                            ),
                          ),
                          Expanded(
                            flex: 4,
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.start,
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  ':',
                                  style: kTextStyle.copyWith(color: kSubTitleColor),
                                ),
                                const SizedBox(width: 10.0),
                                Flexible(
                                  child: Text(
                                    'High resolution',
                                    style: kTextStyle.copyWith(color: kSubTitleColor),
                                    overflow: TextOverflow.ellipsis,
                                    maxLines: 1,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8.0),
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Expanded(
                            flex: 2,
                            child: Text(
                              'Package',
                              style: kTextStyle.copyWith(color: kSubTitleColor),
                            ),
                          ),
                          Expanded(
                            flex: 4,
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.start,
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  ':',
                                  style: kTextStyle.copyWith(color: kSubTitleColor),
                                ),
                                const SizedBox(width: 10.0),
                                Flexible(
                                  child: Text(
                                    'Basic',
                                    style: kTextStyle.copyWith(color: kSubTitleColor),
                                    overflow: TextOverflow.ellipsis,
                                    maxLines: 1,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 15.0),
                      Text(
                        'Order Summary',
                        style: kTextStyle.copyWith(color: kNeutralColor, fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(height: 8.0),
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Expanded(
                            flex: 2,
                            child: Text(
                              'Subtotal',
                              style: kTextStyle.copyWith(color: kSubTitleColor),
                            ),
                          ),
                          Expanded(
                            flex: 4,
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.start,
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  ':',
                                  style: kTextStyle.copyWith(color: kSubTitleColor),
                                ),
                                const SizedBox(width: 10.0),
                                Flexible(
                                  child: Text(
                                    '$currencySign 5.00',
                                    style: kTextStyle.copyWith(color: kSubTitleColor),
                                    overflow: TextOverflow.ellipsis,
                                    maxLines: 1,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8.0),
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Expanded(
                            flex: 2,
                            child: Text(
                              'Service',
                              style: kTextStyle.copyWith(color: kSubTitleColor),
                            ),
                          ),
                          Expanded(
                            flex: 4,
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.start,
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  ':',
                                  style: kTextStyle.copyWith(color: kSubTitleColor),
                                ),
                                const SizedBox(width: 10.0),
                                Flexible(
                                  child: Text(
                                    '$currencySign 2.00',
                                    style: kTextStyle.copyWith(color: kSubTitleColor),
                                    overflow: TextOverflow.ellipsis,
                                    maxLines: 1,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8.0),
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Expanded(
                            flex: 2,
                            child: Text(
                              'Total',
                              style: kTextStyle.copyWith(color: kSubTitleColor),
                            ),
                          ),
                          Expanded(
                            flex: 4,
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.start,
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  ':',
                                  style: kTextStyle.copyWith(color: kSubTitleColor),
                                ),
                                const SizedBox(width: 10.0),
                                Flexible(
                                  child: Text(
                                    '$currencySign 7.00',
                                    style: kTextStyle.copyWith(color: kSubTitleColor),
                                    overflow: TextOverflow.ellipsis,
                                    maxLines: 1,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8.0),
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Expanded(
                            flex: 2,
                            child: Text(
                              'Delivery date',
                              style: kTextStyle.copyWith(color: kSubTitleColor),
                            ),
                          ),
                          Expanded(
                            flex: 4,
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.start,
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  ':',
                                  style: kTextStyle.copyWith(color: kSubTitleColor),
                                ),
                                const SizedBox(width: 10.0),
                                Flexible(
                                  child: Text(
                                    'Thursday, 24 Jun 2023',
                                    style: kTextStyle.copyWith(color: kSubTitleColor),
                                    overflow: TextOverflow.ellipsis,
                                    maxLines: 1,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const SizedBox(height: 15.0),
                          Text(
                            'Delivery File From Seller',
                            style: kTextStyle.copyWith(color: kNeutralColor, fontWeight: FontWeight.bold),
                          ),
                          const SizedBox(height: 15.0),
                          Container(
                            padding: const EdgeInsets.only(left: 10.0, right: 10.0),
                            decoration: BoxDecoration(borderRadius: BorderRadius.circular(8.0), border: Border.all(color: kBorderColorTextField)),
                            child: ListTile(
                              visualDensity: const VisualDensity(vertical: -3),
                              contentPadding: EdgeInsets.zero,
                              leading: Container(
                                padding: const EdgeInsets.all(10.0),
                                decoration: BoxDecoration(
                                  shape: BoxShape.circle,
                                  color: kPrimaryColor.withOpacity(0.1),
                                ),
                                child: const Icon(
                                  IconlyBold.document,
                                  color: kPrimaryColor,
                                ),
                              ),
                              title: Text(
                                'UI UX Design Mobile app...',
                                style: kTextStyle.copyWith(color: kNeutralColor),
                                maxLines: 1,
                              ),
                              subtitle: Text(
                                'Figma file 23564 25452...',
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: kTextStyle.copyWith(color: kSubTitleColor),
                              ),
                              trailing: Container(
                                padding: const EdgeInsets.all(10.0),
                                decoration: BoxDecoration(
                                  shape: BoxShape.circle,
                                  color: kLightNeutralColor.withOpacity(0.1),
                                ),
                                child: const Icon(
                                  FeatherIcons.download,
                                  color: kLightNeutralColor,
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(height: 10.0),
                          Text(
                            'Image',
                            style: kTextStyle.copyWith(color: kNeutralColor, fontWeight: FontWeight.bold),
                          ),
                          const SizedBox(height: 10.0),
                          Container(
                            width: 100,
                            height: 70,
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(3.0),
                              image: const DecorationImage(
                                image: AssetImage('images/file.png'),
                                fit: BoxFit.cover,
                              ),
                            ),
                          )
                        ],
                      ).visible(isSelected == 'Completed'),
                    ],
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
