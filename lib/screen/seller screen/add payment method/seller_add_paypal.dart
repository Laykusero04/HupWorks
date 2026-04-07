import 'package:flutter/material.dart';
import 'package:freelancer/screen/widgets/button_global.dart';
import 'package:nb_utils/nb_utils.dart';

import '../../widgets/constant.dart';
import '../seller popUp/seller_popup.dart';

class SellerAssPaypal extends StatefulWidget {
  const SellerAssPaypal({Key? key}) : super(key: key);

  @override
  State<SellerAssPaypal> createState() => _SellerAssPaypalState();
}

class _SellerAssPaypalState extends State<SellerAssPaypal> {
  bool isCheck = true;

  //__________verifyPopUp________________________________________________
  void verifyPopUp() {
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
              child: const VerifyPopUp(),
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
          'Add PayPal',
          style: kTextStyle.copyWith(color: kNeutralColor, fontWeight: FontWeight.bold),
        ),
        centerTitle: true,
      ),
      bottomNavigationBar: ButtonGlobalWithoutIcon(
          buttontext: 'Connect My PayPal Account',
          buttonDecoration: kButtonDecoration.copyWith(
            color: kPrimaryColor,
            borderRadius: BorderRadius.circular(30.0),
          ),
          onPressed: () {
            verifyPopUp();
          },
          buttonTextColor: kWhite),
      body: Padding(
        padding: const EdgeInsets.only(top: 20.0),
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
                const SizedBox(height: 30.0),
                TextFormField(
                  keyboardType: TextInputType.emailAddress,
                  cursorColor: kNeutralColor,
                  textInputAction: TextInputAction.next,
                  decoration: kInputDecoration.copyWith(
                    labelText: 'Email Address',
                    labelStyle: kTextStyle.copyWith(color: kNeutralColor),
                    hintText: 'Your@example.com',
                    hintStyle: kTextStyle.copyWith(color: kSubTitleColor),
                    focusColor: kNeutralColor,
                    border: const OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: 20.0),
                TextFormField(
                  keyboardType: TextInputType.emailAddress,
                  cursorColor: kNeutralColor,
                  textInputAction: TextInputAction.next,
                  decoration: kInputDecoration.copyWith(
                    labelText: 'Repeat Email Address',
                    labelStyle: kTextStyle.copyWith(color: kNeutralColor),
                    hintText: 'Your@example.com',
                    hintStyle: kTextStyle.copyWith(color: kSubTitleColor),
                    focusColor: kNeutralColor,
                    border: const OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: 20.0),
                Text(
                  'We will not be able to recover funds sent to the wrong address, please make sure the information you enter is correct',
                  style: kTextStyle.copyWith(color: kSubTitleColor),
                ),
                const SizedBox(height: 5.0),
                Row(
                  children: [
                    Checkbox(
                        activeColor: kPrimaryColor,
                        visualDensity: const VisualDensity(horizontal: -4),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(2.0),
                        ),
                        value: isCheck,
                        onChanged: (value) {
                          setState(() {
                            isCheck = !isCheck;
                          });
                        }),
                    Text(
                      'I understand and agree',
                      style: kTextStyle.copyWith(color: kSubTitleColor),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
