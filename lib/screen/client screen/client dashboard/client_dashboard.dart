import 'package:flutter/material.dart';
import 'package:nb_utils/nb_utils.dart';

import '../../widgets/constant.dart';
import '../../widgets/data.dart';

class ClientDashBoard extends StatefulWidget {
  const ClientDashBoard({Key? key}) : super(key: key);

  @override
  State<ClientDashBoard> createState() => _ClientDashBoardState();
}

class _ClientDashBoardState extends State<ClientDashBoard> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: kDarkWhite,
      appBar: AppBar(
        backgroundColor: kDarkWhite,
        elevation: 0,
        iconTheme: const IconThemeData(color: kNeutralColor),
        title: Text(
          'Dashboard',
          style: kTextStyle.copyWith(color: kNeutralColor, fontWeight: FontWeight.bold),
        ),
        centerTitle: true,
      ),
      body: Padding(
        padding: const EdgeInsets.only(top: 20.0),
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
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 15.0),
              Row(
                children: const [
                  Expanded(
                    child: DashBoardInfo(
                      count: '$currencySign${4000.00}',
                      title: 'Current Balance',
                      image: 'images/cb.png',
                    ),
                  ),
                  SizedBox(width: 10.0),
                  Expanded(
                    child: DashBoardInfo(
                      count: '$currencySign${5000.00}',
                      title: 'Total Deposited',
                      image: 'images/td.png',
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 10.0),
              Row(
                children: const [
                  Expanded(
                    child: DashBoardInfo(
                      count: '$currencySign${4000.00}',
                      title: 'Total Transactions',
                      image: 'images/tt.png',
                    ),
                  ),
                  SizedBox(width: 10.0),
                  Expanded(
                    child: DashBoardInfo(
                      count: '10',
                      title: 'Total Order',
                      image: 'images/to.png',
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 10.0),
              Row(
                children: const [
                  Expanded(
                    child: DashBoardInfo(
                      count: '08',
                      title: 'Completed Order',
                      image: 'images/co.png',
                    ),
                  ),
                  SizedBox(width: 10.0),
                  Expanded(
                    child: DashBoardInfo(
                      count: '02',
                      title: 'Incompleted Order',
                      image: 'images/io.png',
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 20),
              Text(
                'Latest Transactions',
                style: kTextStyle.copyWith(color: kNeutralColor, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 10),
              Container(
                padding: const EdgeInsets.all(10.0),
                decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(10.0),
                    border: Border.all(
                      color: kBorderColorTextField,
                    )),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          flex: 2,
                          child: Text(
                            'Seller',
                            style: kTextStyle.copyWith(color: kSubTitleColor),
                          ),
                        ),
                        Expanded(
                          flex: 4,
                          child: Row(
                            children: [
                              Text(
                                ':',
                                style: kTextStyle.copyWith(color: kSubTitleColor),
                              ),
                              const SizedBox(
                                width: 20,
                              ),
                              Text(
                                'Seller',
                                style: kTextStyle.copyWith(color: kSubTitleColor),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 10.0),
                    Row(
                      children: [
                        Expanded(
                          flex: 2,
                          child: Text(
                            'Date',
                            style: kTextStyle.copyWith(color: kSubTitleColor),
                          ),
                        ),
                        Expanded(
                          flex: 4,
                          child: Row(
                            children: [
                              Text(
                                ':',
                                style: kTextStyle.copyWith(color: kSubTitleColor),
                              ),
                              const SizedBox(
                                width: 20,
                              ),
                              Text(
                                '24 Jun 2023',
                                style: kTextStyle.copyWith(color: kSubTitleColor),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 10.0),
                    Row(
                      children: [
                        Expanded(
                          flex: 2,
                          child: Text(
                            'Amount',
                            style: kTextStyle.copyWith(color: kSubTitleColor),
                          ),
                        ),
                        Expanded(
                          flex: 4,
                          child: Row(
                            children: [
                              Text(
                                ':',
                                style: kTextStyle.copyWith(color: kSubTitleColor),
                              ),
                              const SizedBox(
                                width: 20,
                              ),
                              Text(
                                '$currencySign${3000.00}',
                                style: kTextStyle.copyWith(color: kSubTitleColor),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 10.0),
                    Row(
                      children: [
                        Expanded(
                          flex: 2,
                          child: Text(
                            'Status',
                            style: kTextStyle.copyWith(color: kSubTitleColor),
                          ),
                        ),
                        Expanded(
                          flex: 4,
                          child: Row(
                            children: [
                              Text(
                                ':',
                                style: kTextStyle.copyWith(color: kSubTitleColor),
                              ),
                              const SizedBox(
                                width: 20,
                              ),
                              Text(
                                'Paid',
                                style: kTextStyle.copyWith(color: kSubTitleColor),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              )
            ],
          ),
        ),
      ),
    );
  }
}
