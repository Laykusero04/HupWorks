import 'package:flutter/material.dart';
import 'package:freelancer/screen/widgets/button_global.dart';
import 'package:nb_utils/nb_utils.dart';

import '../../widgets/constant.dart';
import '../seller popUp/seller_popup.dart';

class SellerOrderReview extends StatefulWidget {
  const SellerOrderReview({Key? key}) : super(key: key);

  @override
  State<SellerOrderReview> createState() => _SellerOrderReviewState();
}

class _SellerOrderReviewState extends State<SellerOrderReview> {
  //__________review_Submitted_PopUp________________________________________________
  void reviewSubmittedPopUp() {
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
              child: const ReviewSubmittedPopUp(),
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
          'Write a Review',
          style: kTextStyle.copyWith(color: kNeutralColor, fontWeight: FontWeight.bold),
        ),
        centerTitle: true,
      ),
      bottomNavigationBar: Container(
        decoration: const BoxDecoration(color: kWhite),
        child: ButtonGlobalWithoutIcon(
            buttontext: 'Published Review',
            buttonDecoration: kButtonDecoration.copyWith(color: kPrimaryColor, borderRadius: BorderRadius.circular(30.0)),
            onPressed: () {
              reviewSubmittedPopUp();
            },
            buttonTextColor: kWhite),
      ),
      body: Padding(
        padding: const EdgeInsets.only(top: 20.0),
        child: Container(
          padding: const EdgeInsets.only(left: 15.0, right: 15.0),
          width: context.width(),
          height: context.height(),
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
                const SizedBox(height: 15.0),
                Text(
                  'Review your experience',
                  style: kTextStyle.copyWith(color: kNeutralColor, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 5.0),
                Text(
                  'How would you rate your overall experience with this buyer?',
                  style: kTextStyle.copyWith(color: kSubTitleColor),
                ),
                const SizedBox(height: 20.0),
                Center(
                  child: Column(
                    children: [
                      Container(
                        height: 100,
                        width: 100,
                        decoration: const BoxDecoration(
                          shape: BoxShape.circle,
                          image: DecorationImage(
                            image: AssetImage('images/profilepic2.png'),
                            fit: BoxFit.cover,
                          ),
                        ),
                      ),
                      const SizedBox(height: 10.0),
                      Text(
                        'William Liam',
                        style: kTextStyle.copyWith(color: kNeutralColor, fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(height: 5.0),
                      Text(
                        'Seller Level - 1',
                        style: kTextStyle.copyWith(color: kSubTitleColor),
                      ),
                    ],
                  ),
                ),
                Text(
                  'Select Rating',
                  style: kTextStyle.copyWith(color: kNeutralColor),
                ),
                const SizedBox(height: 5.0),
                RatingBarWidget(
                  itemCount: 5,
                  activeColor: ratingBarColor,
                  inActiveColor: kBorderColorTextField,
                  onRatingChanged: (rating) {},
                ),
                const SizedBox(height: 20.0),
                TextFormField(
                  keyboardType: TextInputType.multiline,
                  cursorColor: kNeutralColor,
                  maxLines: 3,
                  decoration: kInputDecoration.copyWith(labelText: 'Write a Comment', labelStyle: kTextStyle.copyWith(color: kNeutralColor), hintText: 'Share your experience...', hintStyle: kTextStyle.copyWith(color: kLightNeutralColor), focusColor: kNeutralColor, floatingLabelBehavior: FloatingLabelBehavior.always),
                )
              ],
            ),
          ),
        ),
      ),
    );
  }
}
