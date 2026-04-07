import 'package:flutter/material.dart';
import 'package:flutter_feather_icons/flutter_feather_icons.dart';
import 'package:freelancer/screen/widgets/button_global.dart';
import 'package:nb_utils/nb_utils.dart';

import '../../widgets/constant.dart';

class AddDeposit extends StatefulWidget {
  const AddDeposit({Key? key}) : super(key: key);

  @override
  State<AddDeposit> createState() => _AddDepositState();
}

class _AddDepositState extends State<AddDeposit> {
  //__________Payment_Method_____________________________________________
  DropdownButton<String> getMethod() {
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

  //__________Currency___________________________________________________
  DropdownButton<String> getCurrency() {
    List<DropdownMenuItem<String>> dropDownItems = [];
    for (String des in currency) {
      var item = DropdownMenuItem(
        value: des,
        child: Text(des),
      );
      dropDownItems.add(item);
    }
    return DropdownButton(
      icon: const Icon(FeatherIcons.chevronDown),
      items: dropDownItems,
      value: selectedCurrency,
      style: kTextStyle.copyWith(color: kSubTitleColor),
      onChanged: (value) {
        setState(() {
          selectedCurrency = value!;
        });
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
          'Add Deposit',
          style: kTextStyle.copyWith(color: kNeutralColor, fontWeight: FontWeight.bold),
        ),
        centerTitle: true,
      ),
      bottomNavigationBar: Container(
        decoration: const BoxDecoration(color: kWhite),
        child: ButtonGlobalWithoutIcon(
          buttontext: 'Submit',
          buttonDecoration: kButtonDecoration.copyWith(
            color: kPrimaryColor,
            borderRadius: BorderRadius.circular(30.0),
          ),
          onPressed: () {},
          buttonTextColor: kWhite,
        ),
      ),
      body: Padding(
        padding: const EdgeInsets.only(top: 20.0),
        child: Container(
          padding: const EdgeInsets.only(left: 20.0, right: 20.0),
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
                      labelText: 'Select Payment Method',
                      labelStyle: kTextStyle.copyWith(color: kNeutralColor),
                    ),
                    child: DropdownButtonHideUnderline(child: getMethod()),
                  );
                },
              ),
              const SizedBox(height: 20.0),
              Row(
                children: [
                  Expanded(
                    child: TextFormField(
                      keyboardType: TextInputType.name,
                      cursorColor: kNeutralColor,
                      textInputAction: TextInputAction.next,
                      decoration: kInputDecoration.copyWith(
                        labelText: 'Amount',
                        labelStyle: kTextStyle.copyWith(color: kNeutralColor),
                        hintText: '\$5000.00',
                        hintStyle: kTextStyle.copyWith(color: kSubTitleColor),
                        focusColor: kNeutralColor,
                        border: const OutlineInputBorder(),
                      ),
                    ),
                  ),
                  const SizedBox(width: 10.0),
                  Expanded(
                    child: FormField(
                      builder: (FormFieldState<dynamic> field) {
                        return InputDecorator(
                          decoration: kInputDecoration.copyWith(
                            border: const OutlineInputBorder(),
                            contentPadding: const EdgeInsets.all(6.0),
                            floatingLabelBehavior: FloatingLabelBehavior.always,
                            labelText: 'Currency',
                            labelStyle: kTextStyle.copyWith(color: kNeutralColor),
                          ),
                          child: DropdownButtonHideUnderline(child: getCurrency()),
                        );
                      },
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 20.0),
              Row(
                children: [
                  Expanded(
                      flex: 2,
                      child: Text(
                        'Charge',
                        style: kTextStyle.copyWith(color: kSubTitleColor),
                      )),
                  const Expanded(flex: 1, child: Text(':')),
                  Expanded(
                    flex: 2,
                    child: Text(
                      '10.00 USD',
                      style: kTextStyle.copyWith(color: kSubTitleColor),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 20.0),
              Row(
                children: [
                  Expanded(
                      flex: 2,
                      child: Text(
                        'Total Payable',
                        style: kTextStyle.copyWith(color: kNeutralColor, fontWeight: FontWeight.bold),
                      )),
                  const Expanded(flex: 1, child: Text(':')),
                  Expanded(
                    flex: 2,
                    child: Text(
                      '5010 USD',
                      style: kTextStyle.copyWith(color: kSubTitleColor, fontWeight: FontWeight.bold),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
