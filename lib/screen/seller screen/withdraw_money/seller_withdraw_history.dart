import 'package:flutter/material.dart';
import 'package:nb_utils/nb_utils.dart';

import '../../widgets/constant.dart';
import '../seller popUp/seller_popup.dart';

class SellerWithDrawHistory extends StatefulWidget {
  const SellerWithDrawHistory({Key? key}) : super(key: key);

  @override
  State<SellerWithDrawHistory> createState() => _SellerWithDrawHistoryState();
}

class _SellerWithDrawHistoryState extends State<SellerWithDrawHistory> {
  //__________withdraw_amount_popup________________________________________________
  void withdrawHistoryPopUp() {
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
              child: const WithdrawHistoryPopUp(),
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
          'Withdraw Money',
          style: kTextStyle.copyWith(color: kNeutralColor, fontWeight: FontWeight.bold),
        ),
        centerTitle: true,
      ),
      body: Padding(
        padding: const EdgeInsets.only(top: 15.0),
        child: Container(
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
                const SizedBox(height: 20),
                ListView.builder(
                  shrinkWrap: true,
                  itemCount: 10,
                  physics: const NeverScrollableScrollPhysics(),
                  padding: const EdgeInsets.only(bottom: 10.0),
                  itemBuilder: (_, i) {
                    return Column(
                      children: [
                        GestureDetector(
                          onTap: () => withdrawHistoryPopUp(),
                          child: Container(
                            padding: const EdgeInsets.all(10.0),
                            decoration: BoxDecoration(
                              color: kWhite,
                              borderRadius: BorderRadius.circular(6.0),
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
                                      'Withdrawal Completed',
                                      style: kTextStyle.copyWith(color: kNeutralColor, fontWeight: FontWeight.bold),
                                    ),
                                    const Spacer(),
                                    Text(
                                      '$currencySign 5,000',
                                      style: kTextStyle.copyWith(color: kNeutralColor, fontWeight: FontWeight.bold),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 8.0),
                                Text(
                                  '10 Jun 2023',
                                  style: kTextStyle.copyWith(color: kLightNeutralColor),
                                  maxLines: 2,
                                ),
                              ],
                            ),
                          ),
                        ),
                        const SizedBox(height: 10.0),
                        Container(
                          padding: const EdgeInsets.all(10.0),
                          decoration: BoxDecoration(
                            color: kWhite,
                            borderRadius: BorderRadius.circular(6.0),
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
                                    'Withdrawal Initiated',
                                    style: kTextStyle.copyWith(color: kNeutralColor, fontWeight: FontWeight.bold),
                                  ),
                                  const Spacer(),
                                  Text(
                                    '$currencySign 5,000',
                                    style: kTextStyle.copyWith(color: Colors.red, fontWeight: FontWeight.bold),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 8.0),
                              Text(
                                '10 Jun 2023',
                                style: kTextStyle.copyWith(color: kLightNeutralColor),
                                maxLines: 2,
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 10.0),
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
