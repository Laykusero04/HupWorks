import 'package:flutter/material.dart';
import 'package:nb_utils/nb_utils.dart';

import '../../widgets/constant.dart';
import '../../widgets/icons.dart';
import '../seller popUp/seller_popup.dart';

class BuyerRequestDetails extends StatefulWidget {
  const BuyerRequestDetails({Key? key}) : super(key: key);

  @override
  State<BuyerRequestDetails> createState() => _BuyerRequestDetailsState();
}

class _BuyerRequestDetailsState extends State<BuyerRequestDetails> {
  //__________send_Offer_PopUp________________________________________________
  void sendOfferPopUp() {
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
              child: const SendOfferPopUp(),
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
          'Buyer Request',
          style: kTextStyle.copyWith(color: kNeutralColor, fontWeight: FontWeight.bold),
        ),
        centerTitle: true,
      ),
      bottomNavigationBar: Container(
        decoration: const BoxDecoration(color: kWhite),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Expanded(
              child: Button(
                containerBg: kWhite,
                borderColor: Colors.red,
                buttonText: 'Cancel Offer',
                textColor: Colors.red,
                onPressed: () {},
              ),
            ),
            Expanded(
              child: Button(
                containerBg: kPrimaryColor,
                borderColor: kPrimaryColor,
                buttonText: 'Send Offer',
                textColor: kWhite,
                onPressed: () {
                  setState(() {
                    sendOfferPopUp();
                  });
                },
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
          height: context.height(),
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
                const SizedBox(height: 20),
                Container(
                  padding: const EdgeInsets.all(10.0),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(10.0),
                    color: kWhite,
                    border: Border.all(color: kBorderColorTextField),
                    boxShadow: const [
                      BoxShadow(
                        color: kBorderColorTextField,
                        spreadRadius: 0.2,
                        blurRadius: 4.0,
                        offset: Offset(0, 2),
                      ),
                    ],
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      ListTile(
                        contentPadding: EdgeInsets.zero,
                        leading: Container(
                          height: 44,
                          width: 44,
                          decoration: const BoxDecoration(
                            shape: BoxShape.circle,
                            image: DecorationImage(
                              image: AssetImage('images/profile1.png'),
                              fit: BoxFit.cover,
                            ),
                          ),
                        ),
                        title: Text(
                          'Shaidul Islam',
                          style: kTextStyle.copyWith(color: kNeutralColor, fontWeight: FontWeight.bold),
                        ),
                        subtitle: Text(
                          '28 Jun 2023',
                          style: kTextStyle.copyWith(color: kSubTitleColor),
                        ),
                      ),
                      const Divider(
                        height: 0,
                        thickness: 1.0,
                        color: kBorderColorTextField,
                      ),
                      const SizedBox(height: 10.0),
                      Text(
                        'I Need UI UX Designer',
                        style: kTextStyle.copyWith(color: kNeutralColor, fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(height: 5.0),
                      Text(
                        'Lorem ipsum dolor sit amet consectetur. Elementum nulla quis nunc Lorem ipsum dolor sit amet consectetur. O rci pulvinar sit nec donec pellentesque ve nenatis nunc vel pretium. Dictumst bib en dum pharetra hendrerit tortor nisl. Nulla accumsan ',
                        style: kTextStyle.copyWith(color: kSubTitleColor),
                      ),
                      const SizedBox(height: 20.0),
                      RichText(
                        text: TextSpan(text: 'Category: ', style: kTextStyle.copyWith(color: kSubTitleColor, fontWeight: FontWeight.bold), children: [
                          TextSpan(
                            text: 'UI UX Designer',
                            style: kTextStyle.copyWith(color: kNeutralColor),
                          )
                        ]),
                      ),
                      const SizedBox(height: 10.0),
                      RichText(
                        text: TextSpan(text: 'Duration: ', style: kTextStyle.copyWith(color: kSubTitleColor, fontWeight: FontWeight.bold), children: [
                          TextSpan(
                            text: '3 Days',
                            style: kTextStyle.copyWith(color: kNeutralColor),
                          )
                        ]),
                      ),
                      const SizedBox(height: 10.0),
                      RichText(
                        text: TextSpan(text: 'Price: ', style: kTextStyle.copyWith(color: kSubTitleColor, fontWeight: FontWeight.bold), children: [
                          TextSpan(
                            text: '$currencySign 50',
                            style: kTextStyle.copyWith(color: kNeutralColor),
                          )
                        ]),
                      ),
                      const SizedBox(height: 10.0),
                      RichText(
                        text: TextSpan(
                          text: 'Offer Sent: ',
                          style: kTextStyle.copyWith(color: kSubTitleColor, fontWeight: FontWeight.bold),
                          children: [
                            TextSpan(
                              text: '17',
                              style: kTextStyle.copyWith(color: kNeutralColor),
                            )
                          ],
                        ),
                      ),
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
