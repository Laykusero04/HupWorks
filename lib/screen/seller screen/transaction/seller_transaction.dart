import 'package:flutter/material.dart';
import 'package:flutter_feather_icons/flutter_feather_icons.dart';
import 'package:nb_utils/nb_utils.dart';

import '../../widgets/constant.dart';

class SellerTransaction extends StatefulWidget {
  const SellerTransaction({Key? key}) : super(key: key);

  @override
  State<SellerTransaction> createState() => _SellerTransactionState();
}

class _SellerTransactionState extends State<SellerTransaction> {
  DateTime selectedDate = DateTime.now();

  Future<void> _selectDate(BuildContext context) async {
    final DateTime? picked = await showDatePicker(context: context, initialDate: selectedDate, firstDate: DateTime(2015, 8), lastDate: DateTime(2101));
    if (picked != null && picked != selectedDate) {
      setState(() {
        selectedDate = picked;
      });
    }
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
          'Transaction',
          style: kTextStyle.copyWith(color: kNeutralColor, fontWeight: FontWeight.bold),
        ),
        centerTitle: true,
      ),
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
                const SizedBox(height: 15.0),
                Row(
                  children: [
                    Text(
                      'Transactions',
                      style: kTextStyle.copyWith(color: kNeutralColor, fontWeight: FontWeight.bold),
                    ),
                    const Spacer(),
                    GestureDetector(
                      onTap: () => _selectDate(context),
                      child: Text(
                        '${selectedDate.day}/${selectedDate.month}/${selectedDate.year}',
                        style: kTextStyle.copyWith(color: kNeutralColor),
                      ),
                    ),
                    const Icon(
                      FeatherIcons.chevronDown,
                      color: kLightNeutralColor,
                    ),
                  ],
                ),
                const SizedBox(height: 20.0),
                ListView.builder(
                    itemCount: 10,
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
                              height: 44,
                              width: 44,
                              decoration: const BoxDecoration(
                                shape: BoxShape.circle,
                                image: DecorationImage(image: AssetImage('images/usericon.png'), fit: BoxFit.cover),
                              ),
                            ),
                            title: Text(
                              'Marvin McKinney',
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: kTextStyle.copyWith(color: kNeutralColor, fontWeight: FontWeight.bold),
                            ),
                            subtitle: Text(
                              '10 Jun 2023',
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: kTextStyle.copyWith(color: kLightNeutralColor),
                            ),
                            trailing: Text(
                              '$currencySign 5,000',
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: kTextStyle.copyWith(color: kNeutralColor, fontWeight: FontWeight.bold),
                            ),
                          ),
                        ),
                      );
                    })
              ],
            ),
          ),
        ),
      ),
    );
  }
}
