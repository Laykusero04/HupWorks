import 'package:flutter/material.dart';
import 'package:flutter_iconly/flutter_iconly.dart';
import 'package:nb_utils/nb_utils.dart';

import 'constant.dart';

class InfoShowCase extends StatelessWidget {
  const InfoShowCase({
    Key? key,
    required this.title,
    required this.subTitle,
  }) : super(key: key);

  final String title;
  final String subTitle;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(10.0),
      decoration: BoxDecoration(borderRadius: BorderRadius.circular(8.0), color: kWhite, border: Border.all(color: kBorderColorTextField)),
      child: Column(
        children: [
          Row(
            children: [
              Text(
                title,
                style: kTextStyle.copyWith(color: kNeutralColor, fontWeight: FontWeight.bold),
              ),
              const Spacer(),
              const Icon(IconlyBold.edit, color: kLightNeutralColor, size: 18.0),
            ],
          ),
          const SizedBox(height: 8.0),
          Row(
            children: [
              Text(
                subTitle,
                style: kTextStyle.copyWith(color: kLightNeutralColor),
              ),
              const Spacer(),
              const Icon(IconlyBold.delete, color: kLightNeutralColor, size: 18.0),
            ],
          ),
        ],
      ),
    );
  }
}

class InfoShowCaseWithoutIcon extends StatelessWidget {
  const InfoShowCaseWithoutIcon({
    Key? key,
    required this.title,
    required this.subTitle,
  }) : super(key: key);

  final String title;
  final String subTitle;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: context.width(),
      padding: const EdgeInsets.all(10.0),
      decoration: BoxDecoration(borderRadius: BorderRadius.circular(8.0), color: kWhite, border: Border.all(color: kBorderColorTextField)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: kTextStyle.copyWith(color: kNeutralColor, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 8.0),
          Text(
            subTitle,
            style: kTextStyle.copyWith(color: kLightNeutralColor),
          ),
        ],
      ),
    );
  }
}

class InfoShowCase2 extends StatelessWidget {
  const InfoShowCase2({
    Key? key,
    required this.title,
    required this.subTitle,
  }) : super(key: key);

  final String title;
  final String subTitle;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(10.0),
      decoration: BoxDecoration(borderRadius: BorderRadius.circular(8.0), color: kWhite, border: Border.all(color: kBorderColorTextField)),
      child: Column(
        children: [
          Row(
            children: [
              Text(
                title,
                style: kTextStyle.copyWith(color: kNeutralColor, fontWeight: FontWeight.bold),
              ),
              const Spacer(),
              const Icon(IconlyBold.edit, color: kLightNeutralColor, size: 18.0),
            ],
          ),
          const SizedBox(height: 8.0),
          Row(
            children: [
              SizedBox(
                width: 280,
                child: Text(
                  subTitle,
                  style: kTextStyle.copyWith(color: kLightNeutralColor),
                  maxLines: 2,
                ),
              ),
              const Spacer(),
              const Icon(IconlyBold.delete, color: kLightNeutralColor, size: 18.0),
            ],
          ),
        ],
      ),
    );
  }
}

class Summary extends StatelessWidget {
  const Summary({
    Key? key,
    required this.title,
    required this.subtitle,
  }) : super(key: key);

  final String title;
  final String subtitle;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 72,
      padding: const EdgeInsets.all(10.0),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(4.0),
        color: kDarkWhite,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(
            title,
            style: kTextStyle.copyWith(color: kNeutralColor, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 10.0),
          Text(
            subtitle,
            style: kTextStyle.copyWith(color: kSubTitleColor),
          ),
        ],
      ),
    );
  }
}

class SummaryWithoutIcon extends StatelessWidget {
  const SummaryWithoutIcon({
    Key? key,
    required this.title,
    required this.subtitle,
  }) : super(key: key);

  final String title;
  final String subtitle;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: context.width(),
      padding: const EdgeInsets.all(10.0),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(8.0),
        border: Border.all(color: kBorderColorTextField),
        color: kWhite,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(
            title,
            style: kTextStyle.copyWith(color: kNeutralColor, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 10.0),
          Text(
            subtitle,
            style: kTextStyle.copyWith(color: kSubTitleColor),
          ),
        ],
      ),
    );
  }
}

class Summary2 extends StatelessWidget {
  const Summary2({
    Key? key,
    required this.title1,
    required this.subtitle,
    required this.title2,
  }) : super(key: key);

  final String title1;
  final String title2;
  final String subtitle;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 72,
      padding: const EdgeInsets.all(10.0),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(4.0),
        color: kDarkWhite,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          RichText(
            text: TextSpan(text: title1, style: kTextStyle.copyWith(color: kNeutralColor, fontWeight: FontWeight.bold), children: [
              TextSpan(
                text: title2,
                style: kTextStyle.copyWith(color: kLightNeutralColor, fontSize: 12.0),
              )
            ]),
          ),
          const SizedBox(height: 10.0),
          Text(
            subtitle,
            style: kTextStyle.copyWith(color: kSubTitleColor),
          ),
        ],
      ),
    );
  }
}

class LevelSummary extends StatelessWidget {
  const LevelSummary({
    Key? key,
    required this.title,
    required this.subTitle,
    required this.trailing1,
    required this.trailing2,
  }) : super(key: key);

  final String title;
  final String subTitle;
  final String trailing1;
  final String trailing2;

  @override
  Widget build(BuildContext context) {
    return Container(
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
                title,
                style: kTextStyle.copyWith(color: kNeutralColor, fontWeight: FontWeight.bold),
              ),
              const Spacer(),
              RichText(
                text: TextSpan(text: trailing1, style: kTextStyle.copyWith(color: kSubTitleColor, fontWeight: FontWeight.bold), children: [
                  TextSpan(
                    text: ' / $trailing2',
                    style: kTextStyle.copyWith(color: kPrimaryColor, fontWeight: FontWeight.bold),
                  )
                ]),
              )
            ],
          ),
          const SizedBox(height: 8.0),
          Padding(
            padding: const EdgeInsets.only(right: 50.0),
            child: Text(
              'Receive and complete at least 30 orders (all time)',
              style: kTextStyle.copyWith(color: kLightNeutralColor),
              maxLines: 2,
            ),
          ),
        ],
      ),
    );
  }
}

class TitleModel {
  String title;
  bool isSelected;

  TitleModel(this.title, this.isSelected);
}

class DashBoardInfo extends StatelessWidget {
  const DashBoardInfo({
    Key? key,
    required this.count,
    required this.title,
    required this.image,
  }) : super(key: key);

  final String count;
  final String title;
  final String image;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(10.0),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(12.0),
        color: kWhite,
        border: Border.all(color: kBorderColorTextField),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            height: 50.0,
            width: 50.0,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: kPrimaryColor,
              image: DecorationImage(
                image: AssetImage(image),
                fit: BoxFit.cover,
              ),
            ),
          ),
          const SizedBox(height: 5.0),
          Text(
            count,
            style: kTextStyle.copyWith(color: kNeutralColor, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 5.0),
          Text(
            title,
            style: kTextStyle.copyWith(color: kSubTitleColor),
          ),
        ],
      ),
    );
  }
}
