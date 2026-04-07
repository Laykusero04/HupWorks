import 'package:flutter/material.dart';
import 'package:nb_utils/nb_utils.dart';
import 'package:slide_countdown/slide_countdown.dart';

import '../../widgets/constant.dart';
import 'client_order_details.dart';

class ClientOrderList extends StatefulWidget {
  const ClientOrderList({Key? key}) : super(key: key);

  @override
  State<ClientOrderList> createState() => _ClientOrderListState();
}

class _ClientOrderListState extends State<ClientOrderList> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: kDarkWhite,
      appBar: AppBar(
        backgroundColor: kDarkWhite,
        elevation: 0,
        iconTheme: const IconThemeData(color: kNeutralColor),
        title: Text(
          'Orders',
          style: kTextStyle.copyWith(color: kNeutralColor, fontWeight: FontWeight.bold),
        ),
        centerTitle: true,
      ),
      body: Padding(
        padding: const EdgeInsets.only(top: 10.0),
        child: Container(
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
                HorizontalList(
                  padding: const EdgeInsets.only(left: 15.0, top: 15.0),
                  itemCount: titleList.length,
                  itemBuilder: (_, i) {
                    return GestureDetector(
                      onTap: () {
                        setState(() {
                          isSelected = titleList[i];
                        });
                      },
                      child: Container(
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(30.0),
                          color: isSelected == titleList[i] ? kPrimaryColor : kDarkWhite,
                        ),
                        child: Text(
                          titleList[i],
                          style: kTextStyle.copyWith(color: isSelected == titleList[i] ? kWhite : kNeutralColor),
                        ),
                      ),
                    );
                  },
                ),
                const SizedBox(height: 15.0),
                ListView.builder(
                  padding: EdgeInsets.zero,
                  physics: const NeverScrollableScrollPhysics(),
                  shrinkWrap: true,
                  itemCount: 5,
                  itemBuilder: (_, i) {
                    return Padding(
                      padding: const EdgeInsets.all(10.0),
                      child: GestureDetector(
                        onTap: () {
                          setState(() {
                            const ClientOrderDetails().launch(context);
                          });
                        },
                        child: Container(
                          padding: const EdgeInsets.all(10.0),
                          width: context.width(),
                          decoration: BoxDecoration(color: kWhite, borderRadius: BorderRadius.circular(8.0), border: Border.all(color: kBorderColorTextField), boxShadow: const [BoxShadow(color: kDarkWhite, spreadRadius: 4.0, blurRadius: 4.0, offset: Offset(0, 2))]),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  Text(
                                    'Order ID #F025E15',
                                    style: kTextStyle.copyWith(color: kNeutralColor, fontWeight: FontWeight.bold),
                                  ),
                                  const Spacer(),
                                  SlideCountdownSeparated(
                                    duration: const Duration(days: 3),
                                    separatorType: SeparatorType.symbol,
                                    separatorStyle: kTextStyle.copyWith(color: Colors.transparent),
                                    decoration: BoxDecoration(
                                      color: kPrimaryColor,
                                      borderRadius: BorderRadius.circular(3.0),
                                    ),
                                  )
                                ],
                              ),
                              const SizedBox(height: 10.0),
                              RichText(
                                text: TextSpan(
                                  text: 'Seller: ',
                                  style: kTextStyle.copyWith(color: kLightNeutralColor),
                                  children: [
                                    TextSpan(
                                      text: 'Shaidul Islam',
                                      style: kTextStyle.copyWith(color: kNeutralColor),
                                    ),
                                    TextSpan(
                                      text: '  |  ',
                                      style: kTextStyle.copyWith(color: kLightNeutralColor),
                                    ),
                                    TextSpan(
                                      text: '24 Jun 2023',
                                      style: kTextStyle.copyWith(color: kLightNeutralColor),
                                    ),
                                  ],
                                ),
                              ),
                              const SizedBox(height: 8.0),
                              const Divider(
                                thickness: 1.0,
                                color: kBorderColorTextField,
                                height: 1.0,
                              ),
                              const SizedBox(height: 8.0),
                              Row(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Expanded(
                                    flex: 1,
                                    child: Text(
                                      'Title',
                                      style: kTextStyle.copyWith(color: kSubTitleColor),
                                    ),
                                  ),
                                  Expanded(
                                    flex: 3,
                                    child: Row(
                                      mainAxisAlignment: MainAxisAlignment.start,
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          ':',
                                          style: kTextStyle.copyWith(color: kSubTitleColor),
                                        ),
                                        const SizedBox(width: 10.0),
                                        Flexible(
                                          child: Text(
                                            'Mobile UI UX design or app UI UX design',
                                            style: kTextStyle.copyWith(color: kSubTitleColor),
                                            overflow: TextOverflow.ellipsis,
                                            maxLines: 2,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 8.0),
                              Row(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Expanded(
                                    flex: 1,
                                    child: Text(
                                      'Duration',
                                      style: kTextStyle.copyWith(color: kSubTitleColor),
                                    ),
                                  ),
                                  Expanded(
                                    flex: 3,
                                    child: Row(
                                      mainAxisAlignment: MainAxisAlignment.start,
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          ':',
                                          style: kTextStyle.copyWith(color: kSubTitleColor),
                                        ),
                                        const SizedBox(width: 10.0),
                                        Flexible(
                                          child: Text(
                                            '3 Days',
                                            style: kTextStyle.copyWith(color: kSubTitleColor),
                                            overflow: TextOverflow.ellipsis,
                                            maxLines: 1,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 8.0),
                              Row(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Expanded(
                                    flex: 1,
                                    child: Text(
                                      'Amount',
                                      style: kTextStyle.copyWith(color: kSubTitleColor),
                                    ),
                                  ),
                                  Expanded(
                                    flex: 3,
                                    child: Row(
                                      mainAxisAlignment: MainAxisAlignment.start,
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          ':',
                                          style: kTextStyle.copyWith(color: kSubTitleColor),
                                        ),
                                        const SizedBox(width: 10.0),
                                        Flexible(
                                          child: Text(
                                            '$currencySign 5.00',
                                            style: kTextStyle.copyWith(color: kSubTitleColor),
                                            overflow: TextOverflow.ellipsis,
                                            maxLines: 1,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 8.0),
                              Row(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Expanded(
                                    flex: 1,
                                    child: Text(
                                      'Status',
                                      style: kTextStyle.copyWith(color: kSubTitleColor),
                                    ),
                                  ),
                                  Expanded(
                                    flex: 3,
                                    child: Row(
                                      mainAxisAlignment: MainAxisAlignment.start,
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          ':',
                                          style: kTextStyle.copyWith(color: kSubTitleColor),
                                        ),
                                        const SizedBox(width: 10.0),
                                        Flexible(
                                          child: Text(
                                            'Active',
                                            style: kTextStyle.copyWith(color: kNeutralColor),
                                            overflow: TextOverflow.ellipsis,
                                            maxLines: 1,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                      ),
                    );
                  },
                ).visible(isSelected == 'Active'),
                ListView.builder(
                  padding: EdgeInsets.zero,
                  physics: const NeverScrollableScrollPhysics(),
                  shrinkWrap: true,
                  itemCount: 5,
                  itemBuilder: (_, i) {
                    return Padding(
                      padding: const EdgeInsets.all(10.0),
                      child: GestureDetector(
                        onTap: () {
                          setState(() {
                            const ClientOrderDetails().launch(context);
                          });
                        },
                        child: Container(
                          padding: const EdgeInsets.all(10.0),
                          width: context.width(),
                          decoration: BoxDecoration(color: kWhite, borderRadius: BorderRadius.circular(8.0), border: Border.all(color: kBorderColorTextField), boxShadow: const [BoxShadow(color: kDarkWhite, spreadRadius: 4.0, blurRadius: 4.0, offset: Offset(0, 2))]),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  Text(
                                    'Order ID #F025E15',
                                    style: kTextStyle.copyWith(color: kNeutralColor, fontWeight: FontWeight.bold),
                                  ),
                                  const Spacer(),
                                  SlideCountdownSeparated(
                                    showZeroValue: true,
                                    duration: const Duration(days: 0),
                                    separatorType: SeparatorType.symbol,
                                    separatorStyle: kTextStyle.copyWith(color: Colors.transparent),
                                    decoration: BoxDecoration(
                                      color: const Color(0xFFBFBFBF),
                                      borderRadius: BorderRadius.circular(3.0),
                                    ),
                                  )
                                ],
                              ),
                              const SizedBox(height: 10.0),
                              RichText(
                                text: TextSpan(
                                  text: 'Seller: ',
                                  style: kTextStyle.copyWith(color: kLightNeutralColor),
                                  children: [
                                    TextSpan(
                                      text: 'Shaidul Islam',
                                      style: kTextStyle.copyWith(color: kNeutralColor),
                                    ),
                                    TextSpan(
                                      text: '  |  ',
                                      style: kTextStyle.copyWith(color: kLightNeutralColor),
                                    ),
                                    TextSpan(
                                      text: '24 Jun 2023',
                                      style: kTextStyle.copyWith(color: kLightNeutralColor),
                                    ),
                                  ],
                                ),
                              ),
                              const SizedBox(height: 8.0),
                              const Divider(
                                thickness: 1.0,
                                color: kBorderColorTextField,
                                height: 1.0,
                              ),
                              const SizedBox(height: 8.0),
                              Row(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Expanded(
                                    flex: 1,
                                    child: Text(
                                      'Title',
                                      style: kTextStyle.copyWith(color: kSubTitleColor),
                                    ),
                                  ),
                                  Expanded(
                                    flex: 3,
                                    child: Row(
                                      mainAxisAlignment: MainAxisAlignment.start,
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          ':',
                                          style: kTextStyle.copyWith(color: kSubTitleColor),
                                        ),
                                        const SizedBox(width: 10.0),
                                        Flexible(
                                          child: Text(
                                            'Mobile UI UX design or app UI UX design',
                                            style: kTextStyle.copyWith(color: kSubTitleColor),
                                            overflow: TextOverflow.ellipsis,
                                            maxLines: 2,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 8.0),
                              Row(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Expanded(
                                    flex: 1,
                                    child: Text(
                                      'Duration',
                                      style: kTextStyle.copyWith(color: kSubTitleColor),
                                    ),
                                  ),
                                  Expanded(
                                    flex: 3,
                                    child: Row(
                                      mainAxisAlignment: MainAxisAlignment.start,
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          ':',
                                          style: kTextStyle.copyWith(color: kSubTitleColor),
                                        ),
                                        const SizedBox(width: 10.0),
                                        Flexible(
                                          child: Text(
                                            '3 Days',
                                            style: kTextStyle.copyWith(color: kSubTitleColor),
                                            overflow: TextOverflow.ellipsis,
                                            maxLines: 1,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 8.0),
                              Row(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Expanded(
                                    flex: 1,
                                    child: Text(
                                      'Amount',
                                      style: kTextStyle.copyWith(color: kSubTitleColor),
                                    ),
                                  ),
                                  Expanded(
                                    flex: 3,
                                    child: Row(
                                      mainAxisAlignment: MainAxisAlignment.start,
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          ':',
                                          style: kTextStyle.copyWith(color: kSubTitleColor),
                                        ),
                                        const SizedBox(width: 10.0),
                                        Flexible(
                                          child: Text(
                                            '$currencySign 5.00',
                                            style: kTextStyle.copyWith(color: kSubTitleColor),
                                            overflow: TextOverflow.ellipsis,
                                            maxLines: 1,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 8.0),
                              Row(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Expanded(
                                    flex: 1,
                                    child: Text(
                                      'Status',
                                      style: kTextStyle.copyWith(color: kSubTitleColor),
                                    ),
                                  ),
                                  Expanded(
                                    flex: 3,
                                    child: Row(
                                      mainAxisAlignment: MainAxisAlignment.start,
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          ':',
                                          style: kTextStyle.copyWith(color: kSubTitleColor),
                                        ),
                                        const SizedBox(width: 10.0),
                                        Flexible(
                                          child: Text(
                                            'Pending',
                                            style: kTextStyle.copyWith(color: kNeutralColor),
                                            overflow: TextOverflow.ellipsis,
                                            maxLines: 1,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                      ),
                    );
                  },
                ).visible(isSelected == 'Pending'),
                ListView.builder(
                  padding: EdgeInsets.zero,
                  physics: const NeverScrollableScrollPhysics(),
                  shrinkWrap: true,
                  itemCount: 5,
                  itemBuilder: (_, i) {
                    return Padding(
                      padding: const EdgeInsets.all(10.0),
                      child: GestureDetector(
                        onTap: () {
                          setState(() {
                            const ClientOrderDetails().launch(context);
                          });
                        },
                        child: Container(
                          padding: const EdgeInsets.all(10.0),
                          width: context.width(),
                          decoration: BoxDecoration(color: kWhite, borderRadius: BorderRadius.circular(8.0), border: Border.all(color: kBorderColorTextField), boxShadow: const [BoxShadow(color: kDarkWhite, spreadRadius: 4.0, blurRadius: 4.0, offset: Offset(0, 2))]),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  Text(
                                    'Order ID #F025E15',
                                    style: kTextStyle.copyWith(color: kNeutralColor, fontWeight: FontWeight.bold),
                                  ),
                                  const Spacer(),
                                  SlideCountdownSeparated(
                                    showZeroValue: true,
                                    duration: const Duration(days: 0),
                                    separatorType: SeparatorType.symbol,
                                    separatorStyle: kTextStyle.copyWith(color: Colors.transparent),
                                    decoration: BoxDecoration(
                                      color: const Color(0xFFBFBFBF),
                                      borderRadius: BorderRadius.circular(3.0),
                                    ),
                                  )
                                ],
                              ),
                              const SizedBox(height: 10.0),
                              RichText(
                                text: TextSpan(
                                  text: 'Seller: ',
                                  style: kTextStyle.copyWith(color: kLightNeutralColor),
                                  children: [
                                    TextSpan(
                                      text: 'Shaidul Islam',
                                      style: kTextStyle.copyWith(color: kNeutralColor),
                                    ),
                                    TextSpan(
                                      text: '  |  ',
                                      style: kTextStyle.copyWith(color: kLightNeutralColor),
                                    ),
                                    TextSpan(
                                      text: '24 Jun 2023',
                                      style: kTextStyle.copyWith(color: kLightNeutralColor),
                                    ),
                                  ],
                                ),
                              ),
                              const SizedBox(height: 8.0),
                              const Divider(
                                thickness: 1.0,
                                color: kBorderColorTextField,
                                height: 1.0,
                              ),
                              const SizedBox(height: 8.0),
                              Row(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Expanded(
                                    flex: 1,
                                    child: Text(
                                      'Title',
                                      style: kTextStyle.copyWith(color: kSubTitleColor),
                                    ),
                                  ),
                                  Expanded(
                                    flex: 3,
                                    child: Row(
                                      mainAxisAlignment: MainAxisAlignment.start,
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          ':',
                                          style: kTextStyle.copyWith(color: kSubTitleColor),
                                        ),
                                        const SizedBox(width: 10.0),
                                        Flexible(
                                          child: Text(
                                            'Mobile UI UX design or app UI UX design',
                                            style: kTextStyle.copyWith(color: kSubTitleColor),
                                            overflow: TextOverflow.ellipsis,
                                            maxLines: 2,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 8.0),
                              Row(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Expanded(
                                    flex: 1,
                                    child: Text(
                                      'Duration',
                                      style: kTextStyle.copyWith(color: kSubTitleColor),
                                    ),
                                  ),
                                  Expanded(
                                    flex: 3,
                                    child: Row(
                                      mainAxisAlignment: MainAxisAlignment.start,
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          ':',
                                          style: kTextStyle.copyWith(color: kSubTitleColor),
                                        ),
                                        const SizedBox(width: 10.0),
                                        Flexible(
                                          child: Text(
                                            '3 Days',
                                            style: kTextStyle.copyWith(color: kSubTitleColor),
                                            overflow: TextOverflow.ellipsis,
                                            maxLines: 1,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 8.0),
                              Row(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Expanded(
                                    flex: 1,
                                    child: Text(
                                      'Amount',
                                      style: kTextStyle.copyWith(color: kSubTitleColor),
                                    ),
                                  ),
                                  Expanded(
                                    flex: 3,
                                    child: Row(
                                      mainAxisAlignment: MainAxisAlignment.start,
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          ':',
                                          style: kTextStyle.copyWith(color: kSubTitleColor),
                                        ),
                                        const SizedBox(width: 10.0),
                                        Flexible(
                                          child: Text(
                                            '$currencySign 5.00',
                                            style: kTextStyle.copyWith(color: kSubTitleColor),
                                            overflow: TextOverflow.ellipsis,
                                            maxLines: 1,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 8.0),
                              Row(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Expanded(
                                    flex: 1,
                                    child: Text(
                                      'Status',
                                      style: kTextStyle.copyWith(color: kSubTitleColor),
                                    ),
                                  ),
                                  Expanded(
                                    flex: 3,
                                    child: Row(
                                      mainAxisAlignment: MainAxisAlignment.start,
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          ':',
                                          style: kTextStyle.copyWith(color: kSubTitleColor),
                                        ),
                                        const SizedBox(width: 10.0),
                                        Flexible(
                                          child: Text(
                                            'Completed',
                                            style: kTextStyle.copyWith(color: kNeutralColor),
                                            overflow: TextOverflow.ellipsis,
                                            maxLines: 1,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                      ),
                    );
                  },
                ).visible(isSelected == 'Completed'),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
