import 'package:flutter/material.dart';
import 'package:freelancer/screen/seller%20screen/add%20payment%20method/seller_add_paypal.dart';
import 'package:nb_utils/nb_utils.dart';

import '../../widgets/constant.dart';
import 'add_credit_card.dart';

class SellerAddPaymentMethod extends StatefulWidget {
  const SellerAddPaymentMethod({Key? key}) : super(key: key);

  @override
  State<SellerAddPaymentMethod> createState() => _SellerAddPaymentMethodState();
}

class _SellerAddPaymentMethodState extends State<SellerAddPaymentMethod> {
  List<String> accList = [
    'PayPal',
    'Credit or Debit Card',
    'bkash',
  ];

  List<String> imageList = [
    'images/paypal.png',
    'images/card.png',
    'images/bkash.png',
  ];

  List<Widget> linkList = [
    const SellerAssPaypal(),
    const AddCreditCard(),
    const SellerAssPaypal(),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: kDarkWhite,
      appBar: AppBar(
        backgroundColor: kDarkWhite,
        elevation: 0,
        iconTheme: const IconThemeData(color: kNeutralColor),
        title: Text(
          'Add Payment Method',
          style: kTextStyle.copyWith(color: kNeutralColor, fontWeight: FontWeight.bold),
        ),
        centerTitle: true,
      ),
      body: Padding(
        padding: const EdgeInsets.only(top: 20.0),
        child: Container(
          height: context.height(),
          padding: const EdgeInsets.only(
            left: 15.0,
            right: 15.0,
          ),
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
                const SizedBox(height: 20.0),
                ListView.builder(
                  itemCount: 3,
                  physics: const NeverScrollableScrollPhysics(),
                  shrinkWrap: true,
                  padding: const EdgeInsets.only(bottom: 10.0),
                  itemBuilder: (_, i) {
                    return Padding(
                      padding: const EdgeInsets.only(bottom: 10.0),
                      child: Container(
                        padding: const EdgeInsets.all(8.0),
                        decoration: BoxDecoration(
                          color: kWhite,
                          borderRadius: BorderRadius.circular(10.0),
                          border: Border.all(color: kBorderColorTextField),
                          boxShadow: const [
                            BoxShadow(
                              color: kDarkWhite,
                              blurRadius: 4.0,
                              spreadRadius: 2.0,
                              offset: Offset(0, 2),
                            ),
                          ],
                        ),
                        child: ListTile(
                          visualDensity: const VisualDensity(vertical: -3),
                          contentPadding: EdgeInsets.zero,
                          horizontalTitleGap: 10,
                          leading: Container(
                            height: 40,
                            width: 40,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              image: DecorationImage(image: AssetImage(imageList[i]), fit: BoxFit.cover),
                            ),
                          ),
                          title: Text(
                            accList[i],
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: kTextStyle.copyWith(color: kNeutralColor, fontWeight: FontWeight.bold),
                          ),
                          trailing: Container(
                            padding: const EdgeInsets.only(left: 20, right: 20, top: 10, bottom: 10),
                            height: 40,
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(6.0),
                              color: kPrimaryColor,
                            ),
                            child: GestureDetector(
                              onTap: () => linkList[i].launch(context),
                              child: Text(
                                'Add',
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: kTextStyle.copyWith(color: kWhite, fontWeight: FontWeight.bold),
                              ),
                            ),
                          ),
                        ),
                      ),
                    );
                  },
                )
              ],
            ),
          ),
        ),
      ),
    );
  }
}
