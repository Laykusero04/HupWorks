import 'package:flutter/material.dart';
import 'package:flutter_feather_icons/flutter_feather_icons.dart';
import 'package:freelancer/screen/seller%20screen/orders/seller_order_review.dart';
import 'package:freelancer/screen/widgets/button_global.dart';
import 'package:nb_utils/nb_utils.dart';

import '../../widgets/constant.dart';

class SellerDeliverOrder extends StatefulWidget {
  const SellerDeliverOrder({Key? key}) : super(key: key);

  @override
  State<SellerDeliverOrder> createState() => _SellerDeliverOrderState();
}

class _SellerDeliverOrderState extends State<SellerDeliverOrder> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: kDarkWhite,
      appBar: AppBar(
        backgroundColor: kDarkWhite,
        elevation: 0,
        iconTheme: const IconThemeData(color: kNeutralColor),
        title: Text(
          'Deliver Order',
          style: kTextStyle.copyWith(color: kNeutralColor, fontWeight: FontWeight.bold),
        ),
        centerTitle: true,
      ),
      bottomNavigationBar: ButtonGlobalWithoutIcon(
          buttontext: 'Send',
          buttonDecoration: kButtonDecoration.copyWith(
            color: kPrimaryColor,
            borderRadius: BorderRadius.circular(30.0),
          ),
          onPressed: () {
            const SellerOrderReview().launch(context);
          },
          buttonTextColor: kWhite),
      body: Container(
        padding: const EdgeInsets.all(15.0),
        width: context.width(),
        decoration: const BoxDecoration(
          color: kWhite,
          borderRadius: BorderRadius.only(
            topLeft: Radius.circular(30.0),
            topRight: Radius.circular(30.0),
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Deliver Completed Word',
              style: kTextStyle.copyWith(color: kNeutralColor, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 30.0),
            TextFormField(
              readOnly: true,
              keyboardType: TextInputType.name,
              cursorColor: kNeutralColor,
              textInputAction: TextInputAction.next,
              decoration: kInputDecoration.copyWith(labelText: 'Upload File,Photo and Document', labelStyle: kTextStyle.copyWith(color: kNeutralColor, fontWeight: FontWeight.bold), hintText: 'Tap icon to attach a file', hintStyle: kTextStyle.copyWith(color: kSubTitleColor), focusColor: kNeutralColor, border: const OutlineInputBorder(), floatingLabelBehavior: FloatingLabelBehavior.always, suffixIcon: const Icon(FeatherIcons.upload)),
            ),
            const SizedBox(height: 5.0),
            Text(
              'Max size 1 GB',
              style: kTextStyle.copyWith(color: kSubTitleColor),
            ),
            const SizedBox(height: 30.0),
            TextFormField(
              keyboardType: TextInputType.multiline,
              maxLines: 4,
              cursorColor: kNeutralColor,
              textInputAction: TextInputAction.next,
              decoration: kInputDecoration.copyWith(
                labelText: 'Describe your delivery in details',
                labelStyle: kTextStyle.copyWith(color: kNeutralColor, fontWeight: FontWeight.bold),
                hintText: 'Enter you delivery in details...',
                hintStyle: kTextStyle.copyWith(color: kSubTitleColor),
                focusColor: kNeutralColor,
                border: const OutlineInputBorder(),
                floatingLabelBehavior: FloatingLabelBehavior.always,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
