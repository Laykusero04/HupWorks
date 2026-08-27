import 'package:flutter/material.dart';
import 'package:freelancer/l10n/l10n.dart';
import 'package:flutter_feather_icons/flutter_feather_icons.dart';
import 'package:freelancer/core/auth_navigation.dart';
import 'package:freelancer/screen/widgets/button_global.dart';
import 'package:nb_utils/nb_utils.dart';

import '../../widgets/constant.dart';
import '../../widgets/icons.dart';

// ---------------------------------------------------------------------------
// SaveProfilePopUp — shown after profile creation
// ---------------------------------------------------------------------------
class SaveProfilePopUp extends StatefulWidget {
  const SaveProfilePopUp({Key? key}) : super(key: key);

  @override
  State<SaveProfilePopUp> createState() => _SaveProfilePopUpState();
}

class _SaveProfilePopUpState extends State<SaveProfilePopUp> {
  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    return Padding(
      padding: const EdgeInsets.all(15.0),
      child: SingleChildScrollView(
        physics: const BouncingScrollPhysics(),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Container(
              height: 186,
              width: 209,
              decoration: const BoxDecoration(
                shape: BoxShape.rectangle,
                image: DecorationImage(image: AssetImage('images/success.png'), fit: BoxFit.cover),
              ),
            ),
            const SizedBox(height: 15.0),
            Text(
              l10n.congratulations,
              style: kTextStyle.copyWith(color: kNeutralColor, fontWeight: FontWeight.bold, fontSize: 18.0),
            ),
            const SizedBox(height: 10.0),
            Text(
              l10n.profileSetupCompleteBody,
              style: kTextStyle.copyWith(color: kLightNeutralColor),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 10.0),
            Button(
              containerBg: kPrimaryColor,
              borderColor: Colors.transparent,
              buttonText: l10n.done,
              textColor: kWhite,
              onPressed: () {
                finish(context);
                AuthNavigation.goToHomeAfterAuth(context);
              },
            )
          ],
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// BlockingReasonPopUp — shown from chat inbox
// ---------------------------------------------------------------------------
class BlockingReasonPopUp extends StatefulWidget {
  const BlockingReasonPopUp({Key? key}) : super(key: key);

  @override
  State<BlockingReasonPopUp> createState() => _BlockingReasonPopUpState();
}

class _BlockingReasonPopUpState extends State<BlockingReasonPopUp> {
  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    return Padding(
      padding: const EdgeInsets.all(15.0),
      child: SingleChildScrollView(
        physics: const BouncingScrollPhysics(),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Text(
                  'Block on Messenger',
                  style: kTextStyle.copyWith(color: kNeutralColor, fontWeight: FontWeight.bold),
                ),
                const Spacer(),
                GestureDetector(
                  onTap: () => finish(context),
                  child: const Icon(FeatherIcons.x, color: kSubTitleColor),
                ),
              ],
            ),
            const SizedBox(height: 20.0),
            Text(
              'If you\'re friends, blocking will remove this user. The conversation will stay in chats unless you hide it.',
              style: kTextStyle.copyWith(color: kSubTitleColor),
            ),
            const SizedBox(height: 20.0),
            Row(
              children: [
                Expanded(
                  child: Button(
                    containerBg: kWhite,
                    borderColor: Colors.red,
                    buttonText: l10n.cancel,
                    textColor: Colors.red,
                    onPressed: () {
                      finish(context);
                    },
                  ),
                ),
                Expanded(
                  child: Button(
                    containerBg: kPrimaryColor,
                    borderColor: Colors.transparent,
                    buttonText: l10n.block,
                    textColor: kWhite,
                    onPressed: () {
                      finish(context);
                    },
                  ),
                )
              ],
            )
          ],
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// ReviewSubmittedPopUp — shown after leaving a review
// ---------------------------------------------------------------------------
class ReviewSubmittedPopUp extends StatefulWidget {
  const ReviewSubmittedPopUp({Key? key}) : super(key: key);

  @override
  State<ReviewSubmittedPopUp> createState() => _ReviewSubmittedPopUpState();
}

class _ReviewSubmittedPopUpState extends State<ReviewSubmittedPopUp> {
  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    return Padding(
      padding: const EdgeInsets.all(15.0),
      child: SingleChildScrollView(
        physics: const BouncingScrollPhysics(),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            const SizedBox(height: 10.0),
            Container(
              height: 124,
              width: 124,
              decoration: BoxDecoration(
                color: kPrimaryColor.withOpacity(0.2),
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.check_rounded,
                color: kPrimaryColor,
                size: 50,
              ),
            ),
            const SizedBox(height: 20.0),
            Text(
              l10n.reviewSuccessTitle,
              maxLines: 1,
              textAlign: TextAlign.center,
              style: kTextStyle.copyWith(color: kNeutralColor, fontWeight: FontWeight.bold, fontSize: 18.0),
            ),
            const SizedBox(height: 10.0),
            Text(
              l10n.reviewSuccessBody,
              maxLines: 2,
              textAlign: TextAlign.center,
              style: kTextStyle.copyWith(color: kLightNeutralColor),
            ),
            const SizedBox(height: 20.0),
            ButtonGlobalWithoutIcon(
                buttontext: l10n.gotIt,
                buttonDecoration: kButtonDecoration.copyWith(
                  color: kPrimaryColor,
                  borderRadius: BorderRadius.circular(30.0),
                ),
                onPressed: () {
                  Navigator.of(context).pop();
                },
                buttonTextColor: kWhite),
          ],
        ),
      ),
    );
  }
}
