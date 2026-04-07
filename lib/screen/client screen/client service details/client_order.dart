import 'package:flutter/material.dart';
import 'package:flutter_iconly/flutter_iconly.dart';
import 'package:nb_utils/nb_utils.dart';

import '../../widgets/button_global.dart';
import '../../widgets/constant.dart';
import 'client_add_card.dart';

class ClientOrder extends StatefulWidget {
  const ClientOrder({Key? key}) : super(key: key);

  @override
  State<ClientOrder> createState() => _ClientOrderState();
}

class _ClientOrderState extends State<ClientOrder> {
  List<String> paymentMethod = [
    'Credit or Debit Card',
    'Paypal',
    'bkash',
  ];

  String selectedPaymentMethod = 'Credit or Debit Card';

  List<String> imageList = [
    'images/creditcard.png',
    'images/paypal2.png',
    'images/bkash2.png',
  ];

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
          'Order',
          style: kTextStyle.copyWith(color: kNeutralColor, fontWeight: FontWeight.bold),
        ),
      ),
      bottomNavigationBar: Container(
        decoration: const BoxDecoration(color: kWhite),
        child: ButtonGlobalWithoutIcon(
          buttontext: 'Continue',
          buttonDecoration: kButtonDecoration.copyWith(
            color: kPrimaryColor,
            borderRadius: BorderRadius.circular(30.0),
          ),
          onPressed: () {
            setState(() {
              const AddNewCard().launch(context);
            });
          },
          buttonTextColor: kWhite,
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
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SizedBox(height: 15.0),
                Container(
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
                const SizedBox(height: 15.0),
                Text(
                  'Order Details',
                  style: kTextStyle.copyWith(color: kNeutralColor, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 15.0),
                Row(
                  children: [
                    Text(
                      'Delivery days',
                      style: kTextStyle.copyWith(color: kSubTitleColor),
                    ),
                    const Spacer(),
                    Text(
                      '2 days',
                      style: kTextStyle.copyWith(color: kSubTitleColor),
                    ),
                  ],
                ),
                const SizedBox(height: 15.0),
                Row(
                  children: [
                    Text(
                      'Revisions',
                      style: kTextStyle.copyWith(color: kSubTitleColor),
                    ),
                    const Spacer(),
                    Text(
                      'Unlimited',
                      style: kTextStyle.copyWith(color: kSubTitleColor),
                    ),
                  ],
                ),
                const SizedBox(height: 15.0),
                Row(
                  children: [
                    Text(
                      '3 Page/Screen',
                      style: kTextStyle.copyWith(color: kSubTitleColor),
                    ),
                    const Spacer(),
                    const Icon(
                      Icons.check_rounded,
                      color: kPrimaryColor,
                    ),
                  ],
                ),
                const SizedBox(height: 15.0),
                Row(
                  children: [
                    Text(
                      'Responsive design',
                      style: kTextStyle.copyWith(color: kSubTitleColor),
                    ),
                    const Spacer(),
                    const Icon(
                      Icons.check_rounded,
                      color: kPrimaryColor,
                    ),
                  ],
                ),
                const SizedBox(height: 15.0),
                Row(
                  children: [
                    Text(
                      'Source file',
                      style: kTextStyle.copyWith(color: kSubTitleColor),
                    ),
                    const Spacer(),
                    const Icon(
                      Icons.check_rounded,
                      color: kPrimaryColor,
                    ),
                  ],
                ),
                const SizedBox(height: 20.0),
                Text(
                  'Payment Method',
                  style: kTextStyle.copyWith(color: kNeutralColor, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 20.0),
                ListView.builder(
                  itemCount: paymentMethod.length,
                  shrinkWrap: true,
                  padding: EdgeInsets.zero,
                  physics: const NeverScrollableScrollPhysics(),
                  itemBuilder: (_, i) {
                    return Padding(
                      padding: const EdgeInsets.only(bottom: 10.0),
                      child: Container(
                        padding: const EdgeInsets.all(5.0),
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(30.0),
                          color: kWhite,
                          border: Border.all(color: kBorderColorTextField),
                        ),
                        child: ListTile(
                          visualDensity: const VisualDensity(vertical: -2),
                          onTap: () {
                            setState(
                              () {
                                selectedPaymentMethod = paymentMethod[i];
                              },
                            );
                          },
                          contentPadding: const EdgeInsets.only(right: 8.0),
                          leading: Container(
                            height: 50.0,
                            width: 50.0,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              image: DecorationImage(image: AssetImage(imageList[i]), fit: BoxFit.cover),
                            ),
                          ),
                          title: Text(
                            paymentMethod[i],
                            style: kTextStyle.copyWith(color: kNeutralColor),
                          ),
                          trailing: Icon(
                            selectedPaymentMethod == paymentMethod[i] ? Icons.radio_button_checked_rounded : Icons.radio_button_off_rounded,
                            color: selectedPaymentMethod == paymentMethod[i] ? kPrimaryColor : kSubTitleColor,
                          ),
                        ),
                      ),
                    );
                  },
                ),
                const SizedBox(height: 20.0),
                Text(
                  'Order Summary',
                  style: kTextStyle.copyWith(color: kNeutralColor, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 20.0),
                Row(
                  children: [
                    Text(
                      'Subtotal',
                      style: kTextStyle.copyWith(color: kSubTitleColor),
                    ),
                    const Spacer(),
                    Text(
                      '$currencySign${30}',
                      style: kTextStyle.copyWith(color: kSubTitleColor),
                    ),
                  ],
                ),
                const SizedBox(height: 10.0),
                Row(
                  children: [
                    Text(
                      'Service Fee',
                      style: kTextStyle.copyWith(color: kSubTitleColor),
                    ),
                    const Spacer(),
                    Text(
                      '$currencySign${5.50}',
                      style: kTextStyle.copyWith(color: kSubTitleColor),
                    ),
                  ],
                ),
                const SizedBox(height: 10.0),
                Row(
                  children: [
                    Text(
                      'Total',
                      style: kTextStyle.copyWith(color: kNeutralColor, fontWeight: FontWeight.bold, fontSize: 18.0),
                    ),
                    const Spacer(),
                    Text(
                      '$currencySign${35.50}',
                      style: kTextStyle.copyWith(color: kNeutralColor, fontWeight: FontWeight.bold, fontSize: 18.0),
                    ),
                  ],
                ),
                const SizedBox(height: 10.0),
                Row(
                  children: [
                    Text(
                      'Delivery Date',
                      style: kTextStyle.copyWith(color: kSubTitleColor),
                    ),
                    const Spacer(),
                    Text(
                      'Thursday, 14 July 2023',
                      style: kTextStyle.copyWith(color: kSubTitleColor),
                    ),
                  ],
                ),
                const SizedBox(height: 10.0),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
