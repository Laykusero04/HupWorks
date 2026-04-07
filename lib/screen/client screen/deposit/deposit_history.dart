import 'package:flutter/material.dart';
import 'package:flutter_feather_icons/flutter_feather_icons.dart';
import 'package:freelancer/screen/widgets/button_global.dart';
import 'package:nb_utils/nb_utils.dart';

import '../../widgets/constant.dart';

class DepositHistory extends StatefulWidget {
  const DepositHistory({Key? key}) : super(key: key);

  @override
  State<DepositHistory> createState() => _DepositHistoryState();
}

class _DepositHistoryState extends State<DepositHistory> {
  Future<void> _selectDate(BuildContext context) async {
    final DateTime? picked = await showDatePicker(context: context, initialDate: selectedDate, firstDate: DateTime(2015, 8), lastDate: DateTime(2101));
    if (picked != null && picked != selectedDate) {
      setState(() {
        selectedDate = picked;
      });
    }
  }

  DateTime selectedDate = DateTime.now();

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
              Row(
                children: [
                  Text(
                    'Deposit',
                    style: kTextStyle.copyWith(color: kNeutralColor, fontWeight: FontWeight.bold),
                  ),
                  const Spacer(),
                  GestureDetector(
                    onTap: () => _selectDate(context),
                    child: Row(
                      children: [
                        Text(
                          '${selectedDate.day}/${selectedDate.month}/${selectedDate.year}',
                          style: kTextStyle.copyWith(color: kSubTitleColor),
                        ),
                        const Icon(
                          FeatherIcons.chevronDown,
                          color: kSubTitleColor,
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 20.0),
              Container(
                padding: const EdgeInsets.only(left: 10.0, right: 10.0),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(9.0),
                  color: kWhite,
                  border: Border.all(color: kBorderColorTextField),
                  boxShadow: const [
                    BoxShadow(
                      color: kDarkWhite,
                      spreadRadius: 4.0,
                      blurRadius: 4.0,
                      offset: Offset(0, 0),
                    ),
                  ],
                ),
                child: ListTile(
                  horizontalTitleGap: 10,
                  contentPadding: EdgeInsets.zero,
                  leading: Container(
                    height: 44,
                    width: 44,
                    decoration: const BoxDecoration(
                      shape: BoxShape.circle,
                      image: DecorationImage(
                        image: AssetImage('images/paypal2.png'),
                        fit: BoxFit.cover,
                      ),
                    ),
                  ),
                  title: Row(
                    children: [
                      Text(
                        'PayPal',
                        style: kTextStyle.copyWith(color: kNeutralColor, fontWeight: FontWeight.bold),
                      ),
                      const Spacer(),
                      Text(
                        '$currencySign${5000.00}',
                        style: kTextStyle.copyWith(color: kNeutralColor, fontWeight: FontWeight.bold),
                      ),
                    ],
                  ),
                  subtitle: Row(
                    children: [
                      Text(
                        '24 Jun 2023',
                        style: kTextStyle.copyWith(color: kSubTitleColor),
                      ),
                      const Spacer(),
                      Text(
                        'Paid',
                        style: kTextStyle.copyWith(color: kPrimaryColor),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 20.0),
              Container(
                padding: const EdgeInsets.only(left: 10.0, right: 10.0),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(9.0),
                  color: kWhite,
                  border: Border.all(color: kBorderColorTextField),
                  boxShadow: const [
                    BoxShadow(
                      color: kDarkWhite,
                      spreadRadius: 4.0,
                      blurRadius: 4.0,
                      offset: Offset(0, 0),
                    ),
                  ],
                ),
                child: ListTile(
                  horizontalTitleGap: 10,
                  contentPadding: EdgeInsets.zero,
                  leading: Container(
                    height: 44,
                    width: 44,
                    decoration: const BoxDecoration(
                      shape: BoxShape.circle,
                      image: DecorationImage(
                        image: AssetImage('images/creditcard.png'),
                        fit: BoxFit.cover,
                      ),
                    ),
                  ),
                  title: Row(
                    children: [
                      Text(
                        'Credit or Debit Card',
                        style: kTextStyle.copyWith(color: kNeutralColor, fontWeight: FontWeight.bold),
                      ),
                      const Spacer(),
                      Text(
                        '$currencySign${5000.00}',
                        style: kTextStyle.copyWith(color: kNeutralColor, fontWeight: FontWeight.bold),
                      ),
                    ],
                  ),
                  subtitle: Row(
                    children: [
                      Text(
                        '24 Jun 2023',
                        style: kTextStyle.copyWith(color: kSubTitleColor),
                      ),
                      const Spacer(),
                      Text(
                        'Paid',
                        style: kTextStyle.copyWith(color: kPrimaryColor),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 20.0),
              Container(
                padding: const EdgeInsets.only(left: 10.0, right: 10.0),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(9.0),
                  color: kWhite,
                  border: Border.all(color: kBorderColorTextField),
                  boxShadow: const [
                    BoxShadow(
                      color: kDarkWhite,
                      spreadRadius: 4.0,
                      blurRadius: 4.0,
                      offset: Offset(0, 0),
                    ),
                  ],
                ),
                child: ListTile(
                  horizontalTitleGap: 10,
                  contentPadding: EdgeInsets.zero,
                  leading: Container(
                    height: 44,
                    width: 44,
                    decoration: const BoxDecoration(
                      shape: BoxShape.circle,
                      image: DecorationImage(
                        image: AssetImage('images/bkash2.png'),
                        fit: BoxFit.cover,
                      ),
                    ),
                  ),
                  title: Row(
                    children: [
                      Text(
                        'bkash',
                        style: kTextStyle.copyWith(color: kNeutralColor, fontWeight: FontWeight.bold),
                      ),
                      const Spacer(),
                      Text(
                        '$currencySign${5000.00}',
                        style: kTextStyle.copyWith(color: kNeutralColor, fontWeight: FontWeight.bold),
                      ),
                    ],
                  ),
                  subtitle: Row(
                    children: [
                      Text(
                        '24 Jun 2023',
                        style: kTextStyle.copyWith(color: kSubTitleColor),
                      ),
                      const Spacer(),
                      Text(
                        'Paid',
                        style: kTextStyle.copyWith(color: kPrimaryColor),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
