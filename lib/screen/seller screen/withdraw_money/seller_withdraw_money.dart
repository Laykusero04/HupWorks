import 'package:flutter/material.dart';
import 'package:flutter_feather_icons/flutter_feather_icons.dart';
import 'package:nb_utils/nb_utils.dart';

import '../../widgets/button_global.dart';
import '../../widgets/constant.dart';
import '../seller popUp/seller_popup.dart';

class SellerWithdrawMoney extends StatefulWidget {
  const SellerWithdrawMoney({Key? key}) : super(key: key);

  @override
  State<SellerWithdrawMoney> createState() => _SellerWithdrawMoneyState();
}

class _SellerWithdrawMoneyState extends State<SellerWithdrawMoney> {
  //__________gateway____________________________________________________________
  DropdownButton<String> getGateway() {
    List<DropdownMenuItem<String>> dropDownItems = [];
    for (String des in gateWay) {
      var item = DropdownMenuItem(
        value: des,
        child: Text(des),
      );
      dropDownItems.add(item);
    }
    return DropdownButton(
      icon: const Icon(FeatherIcons.chevronDown),
      items: dropDownItems,
      value: selectedGateWay,
      style: kTextStyle.copyWith(color: kSubTitleColor),
      onChanged: (value) {
        setState(() {
          selectedGateWay = value!;
        });
      },
    );
  }

  //__________withdraw_amount_popup________________________________________________
  void withdrawAmountPopUp() {
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
              child: const WithdrawAmountPopUp(),
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
      bottomNavigationBar: ButtonGlobalWithoutIcon(
          buttontext: 'Submit',
          buttonDecoration: kButtonDecoration.copyWith(
            color: kPrimaryColor,
            borderRadius: BorderRadius.circular(30.0),
          ),
          onPressed: () {
            withdrawAmountPopUp();
          },
          buttonTextColor: kWhite),
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
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SizedBox(height: 20.0),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    Expanded(
                      child: Container(
                        padding: const EdgeInsets.all(10.0),
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(8.0),
                          color: kWhite,
                          border: Border.all(color: kBorderColorTextField),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              '$currencySign 220',
                              style: kTextStyle.copyWith(color: kNeutralColor, fontWeight: FontWeight.bold),
                            ),
                            const SizedBox(height: 8.0),
                            Text(
                              'Pending Clearance',
                              style: kTextStyle.copyWith(color: kSubTitleColor),
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(width: 10.0),
                    Expanded(
                      child: Container(
                        padding: const EdgeInsets.all(10.0),
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(8.0),
                          color: kWhite,
                          border: Border.all(color: kBorderColorTextField),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              '$currencySign 7,000',
                              style: kTextStyle.copyWith(color: kNeutralColor, fontWeight: FontWeight.bold),
                            ),
                            const SizedBox(height: 8.0),
                            Text(
                              'Withdrawal Available ',
                              maxLines: 1,
                              style: kTextStyle.copyWith(color: kSubTitleColor),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 20.0),
                Text(
                  'Withdraw Method',
                  style: kTextStyle.copyWith(color: kNeutralColor, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 20.0),
                FormField(
                  builder: (FormFieldState<dynamic> field) {
                    return InputDecorator(
                      decoration: kInputDecoration.copyWith(
                        enabledBorder: const OutlineInputBorder(
                          borderRadius: BorderRadius.all(
                            Radius.circular(8.0),
                          ),
                          borderSide: BorderSide(color: kBorderColorTextField, width: 2),
                        ),
                        contentPadding: const EdgeInsets.all(7.0),
                        floatingLabelBehavior: FloatingLabelBehavior.always,
                        labelText: 'Select Gateway',
                        labelStyle: kTextStyle.copyWith(color: kNeutralColor),
                      ),
                      child: DropdownButtonHideUnderline(child: getGateway()),
                    );
                  },
                ),
                const SizedBox(height: 20.0),
                TextFormField(
                  keyboardType: TextInputType.number,
                  cursorColor: kNeutralColor,
                  textInputAction: TextInputAction.next,
                  decoration: kInputDecoration.copyWith(
                    labelText: 'Amount',
                    labelStyle: kTextStyle.copyWith(color: kNeutralColor),
                    hintText: '\$500',
                    hintStyle: kTextStyle.copyWith(color: kLightNeutralColor),
                    focusColor: kNeutralColor,
                    border: const OutlineInputBorder(),
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
