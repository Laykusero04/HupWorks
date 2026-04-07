import 'package:flutter/material.dart';
import 'package:flutter_iconly/flutter_iconly.dart';
import 'package:nb_utils/nb_utils.dart';
import 'package:percent_indicator/linear_percent_indicator.dart';

import 'constant.dart';

class Review extends StatefulWidget {
  const Review({Key? key}) : super(key: key);

  @override
  State<Review> createState() => _ReviewState();
}

class _ReviewState extends State<Review> with TickerProviderStateMixin {
  @override
  void initState() {
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        SizedBox(
          width: double.infinity,
          child: Stack(
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    height: 70,
                    width: 70,
                    decoration: BoxDecoration(
                      borderRadius: const BorderRadius.all(Radius.circular(40)),
                      border: Border.all(width: 2, color: kPrimaryColor),
                    ),
                    child: Center(
                      child: Text(
                        '4.9',
                        style: kTextStyle.copyWith(
                          fontSize: 30,
                          fontWeight: FontWeight.bold,
                          color: kPrimaryColor,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 10),
                  Text(
                    'Total 22 Reviews',
                    style: kTextStyle.copyWith(
                      color: kNeutralColor,
                    ),
                  ),
                ],
              ),
              Positioned(
                right: 0,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Row(
                      children: [
                        const Icon(Icons.star, size: 18, color: ratingBarColor),
                        const Icon(Icons.star, size: 18, color: ratingBarColor),
                        const Icon(Icons.star, size: 18, color: ratingBarColor),
                        const Icon(Icons.star, size: 18, color: ratingBarColor),
                        const Icon(Icons.star, size: 18, color: ratingBarColor),
                        LinearPercentIndicator(
                          width: 130,
                          lineHeight: 8.0,
                          percent: 0.8,
                          progressColor: kPrimaryColor,
                          backgroundColor: Colors.transparent,
                          barRadius: const Radius.circular(15),
                        ),
                        const SizedBox(width: 30, child: Center(child: Text('12'))),
                      ],
                    ),
                    Row(
                      children: [
                        const Icon(Icons.star, size: 18, color: ratingBarColor),
                        const Icon(Icons.star, size: 18, color: ratingBarColor),
                        const Icon(Icons.star, size: 18, color: ratingBarColor),
                        const Icon(Icons.star, size: 18, color: ratingBarColor),
                        LinearPercentIndicator(
                          width: 130,
                          lineHeight: 8.0,
                          percent: 0.4,
                          progressColor: kPrimaryColor,
                          backgroundColor: Colors.transparent,
                          barRadius: const Radius.circular(15),
                        ),
                        const SizedBox(width: 30, child: Center(child: Text('5'))),
                      ],
                    ),
                    Row(
                      children: [
                        const Icon(Icons.star, size: 18, color: ratingBarColor),
                        const Icon(Icons.star, size: 18, color: ratingBarColor),
                        const Icon(Icons.star, size: 18, color: ratingBarColor),
                        LinearPercentIndicator(
                          width: 130,
                          lineHeight: 8.0,
                          percent: 0.3,
                          progressColor: kPrimaryColor,
                          backgroundColor: Colors.transparent,
                          barRadius: const Radius.circular(15),
                        ),
                        const SizedBox(width: 30, child: Center(child: Text('4'))),
                      ],
                    ),
                    Row(
                      children: [
                        const Icon(Icons.star, size: 18, color: ratingBarColor),
                        const Icon(Icons.star, size: 18, color: ratingBarColor),
                        LinearPercentIndicator(
                          width: 130,
                          lineHeight: 8.0,
                          percent: 0.2,
                          progressColor: kPrimaryColor,
                          backgroundColor: Colors.transparent,
                          barRadius: const Radius.circular(15),
                        ),
                        const SizedBox(width: 30, child: Center(child: Text('2'))),
                      ],
                    ),
                    Row(
                      children: [
                        const Icon(Icons.star, size: 18, color: ratingBarColor),
                        LinearPercentIndicator(
                          width: 130,
                          lineHeight: 8.0,
                          percent: 0.1,
                          progressColor: kPrimaryColor,
                          backgroundColor: Colors.transparent,
                          barRadius: const Radius.circular(15),
                        ),
                        const SizedBox(width: 30, child: Center(child: Text('0'))),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class ReviewDetails extends StatelessWidget {
  const ReviewDetails({
    Key? key,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(10.0),
      width: context.width(),
      decoration: BoxDecoration(color: kWhite, borderRadius: BorderRadius.circular(8.0), border: Border.all(color: kBorderColorTextField), boxShadow: const [BoxShadow(color: kBorderColorTextField, spreadRadius: 1.0, blurRadius: 5.0, offset: Offset(0, 3))]),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.start,
        children: [
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                height: 40.0,
                width: 40.0,
                decoration: const BoxDecoration(
                  shape: BoxShape.circle,
                  image: DecorationImage(
                    image: AssetImage('images/profilepic.png'),
                    fit: BoxFit.cover,
                  ),
                ),
              ),
              const SizedBox(width: 10.0),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Abdul Korim',
                    style: kTextStyle.copyWith(color: kNeutralColor, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 4.0),
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(
                        IconlyBold.star,
                        color: ratingBarColor,
                        size: 18.0,
                      ),
                      const SizedBox(width: 5.0),
                      Text(
                        '4.9',
                        style: kTextStyle.copyWith(color: kNeutralColor),
                      ),
                      const SizedBox(width: 120),
                      Text(
                        '5, June 2023',
                        style: kTextStyle.copyWith(color: kLightNeutralColor),
                      ),
                    ],
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 10.0),
          Text(
            'Nibh nibh quis dolor in. Etiam cras nisi, turpis quisque diam',
            style: kTextStyle.copyWith(color: kSubTitleColor),
          ),
          const SizedBox(height: 10.0),
          Text(
            'Review',
            style: kTextStyle.copyWith(color: kLightNeutralColor),
          ),
        ],
      ),
    );
  }
}

class ReviewDetails2 extends StatelessWidget {
  const ReviewDetails2({
    Key? key,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(10.0),
      width: context.width(),
      decoration: BoxDecoration(color: kWhite, borderRadius: BorderRadius.circular(8.0), border: Border.all(color: kBorderColorTextField), boxShadow: const [BoxShadow(color: kBorderColorTextField, spreadRadius: 1.0, blurRadius: 5.0, offset: Offset(0, 3))]),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.start,
        children: [
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                height: 40.0,
                width: 40.0,
                decoration: const BoxDecoration(
                  shape: BoxShape.circle,
                  image: DecorationImage(
                    image: AssetImage('images/profilepic.png'),
                    fit: BoxFit.cover,
                  ),
                ),
              ),
              const SizedBox(width: 10.0),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Abdul Korim',
                    style: kTextStyle.copyWith(color: kNeutralColor, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 4.0),
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(
                        IconlyBold.star,
                        color: ratingBarColor,
                        size: 18.0,
                      ),
                      const SizedBox(width: 5.0),
                      Text(
                        '4.9',
                        style: kTextStyle.copyWith(color: kNeutralColor),
                      ),
                      const SizedBox(width: 120),
                      Text(
                        '5, June 2023',
                        style: kTextStyle.copyWith(color: kLightNeutralColor),
                      ),
                    ],
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 10.0),
          Text(
            'Nibh nibh quis dolor in. Etiam cras nisi, turpis quisque diam',
            style: kTextStyle.copyWith(color: kSubTitleColor),
          ),
          const SizedBox(height: 10.0),
          Row(
            children: [
              Container(
                height: 40,
                width: 60,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(4.0),
                  border: Border.all(color: kBorderColorTextField),
                  image: const DecorationImage(image: AssetImage('images/pic2.png'), fit: BoxFit.cover),
                ),
              ),
              const SizedBox(width: 10.0),
              Container(
                height: 40,
                width: 60,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(4.0),
                  border: Border.all(color: kBorderColorTextField),
                  image: const DecorationImage(image: AssetImage('images/pic2.png'), fit: BoxFit.cover),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10.0),
          Text(
            'Review',
            style: kTextStyle.copyWith(color: kLightNeutralColor),
          ),
        ],
      ),
    );
  }
}
