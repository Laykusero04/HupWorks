import 'package:flutter/material.dart';
import 'package:freelancer/l10n/l10n.dart';
import 'package:flutter_feather_icons/flutter_feather_icons.dart';
import 'package:flutter_iconly/flutter_iconly.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:nb_utils/nb_utils.dart';

import '../../widgets/constant.dart';
import '../../widgets/icons.dart';

class ProcessingPopUp extends StatefulWidget {
  const ProcessingPopUp({Key? key}) : super(key: key);

  @override
  State<ProcessingPopUp> createState() => _ProcessingPopUpState();
}

class _ProcessingPopUpState extends State<ProcessingPopUp> {
  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    return Padding(
      padding: const EdgeInsets.all(20.0),
      child: SingleChildScrollView(
        physics: const BouncingScrollPhysics(),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Container(
              height: 166,
              width: 208,
              decoration: const BoxDecoration(
                image: DecorationImage(
                  image: AssetImage('images/robot.png'),
                  fit: BoxFit.cover,
                ),
              ),
            ),
            const SizedBox(height: 20.0),
            Text(
              l10n.processingOrder,
              maxLines: 2,
              textAlign: TextAlign.center,
              style: kTextStyle.copyWith(color: kNeutralColor, fontWeight: FontWeight.bold, fontSize: 18.0),
            ),
            const SizedBox(height: 10.0),
            Text(
              l10n.stayTuned,
              maxLines: 2,
              textAlign: TextAlign.center,
              style: kTextStyle.copyWith(color: kLightNeutralColor),
            ),
          ],
        ),
      ),
    );
  }
}

class UploadRequirementsPopUp extends StatefulWidget {
  const UploadRequirementsPopUp({Key? key}) : super(key: key);

  @override
  State<UploadRequirementsPopUp> createState() => _UploadRequirementsPopUpState();
}

class _UploadRequirementsPopUpState extends State<UploadRequirementsPopUp> {
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
                  l10n.chooseYourAction,
                  style: kTextStyle.copyWith(color: kNeutralColor, fontWeight: FontWeight.bold),
                ),
                const Spacer(),
                GestureDetector(
                  onTap: () => finish(context),
                  child: const Icon(FeatherIcons.x, color: kSubTitleColor),
                ),
              ],
            ),
            const SizedBox(height: 30.0),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                Column(
                  children: [
                    FaIcon(
                      FontAwesomeIcons.images,
                      color: kPrimaryColor,
                      size: 40,
                    ),
                    const SizedBox(height: 10.0),
                    Text(
                      l10n.openGallery,
                      style: kTextStyle.copyWith(color: kPrimaryColor),
                    ),
                  ],
                ),
                const SizedBox(width: 20.0),
                Column(
                  children: [
                    const Icon(
                      IconlyBold.document,
                      color: kLightNeutralColor,
                      size: 40,
                    ),
                    const SizedBox(height: 10.0),
                    Text(
                      l10n.openFile,
                      style: kTextStyle.copyWith(color: kLightNeutralColor),
                    ),
                  ],
                ),
              ],
            ),
            const SizedBox(height: 10.0),
          ],
        ),
      ),
    );
  }
}

class UploadCompletePopUp extends StatefulWidget {
  const UploadCompletePopUp({Key? key}) : super(key: key);

  @override
  State<UploadCompletePopUp> createState() => _UploadCompletePopUpState();
}

class _UploadCompletePopUpState extends State<UploadCompletePopUp> {
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
                Navigator.of(context).pop();
              },
            )
          ],
        ),
      ),
    );
  }
}

class CancelJobPopUp extends StatefulWidget {
  const CancelJobPopUp({Key? key}) : super(key: key);

  @override
  State<CancelJobPopUp> createState() => _CancelJobPopUpState();
}

class _CancelJobPopUpState extends State<CancelJobPopUp> {
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
              mainAxisAlignment: MainAxisAlignment.start,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  l10n.cancelJobConfirmTitle,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: kTextStyle.copyWith(color: kNeutralColor, fontWeight: FontWeight.bold),
                ),
                const Spacer(),
                const Icon(
                  FeatherIcons.x,
                  color: kSubTitleColor,
                )
              ],
            ),
            const SizedBox(height: 15.0),
            Text(
              'Lorem ipsum dolor sit amet conse ctetur. Nunc habitant felis pharetra nibh elementum ut.',
              style: kTextStyle.copyWith(color: kLightNeutralColor),
              textAlign: TextAlign.start,
            ),
            const SizedBox(height: 10.0),
            Row(
              children: [
                Expanded(
                  child: Button(
                    containerBg: kWhite,
                    borderColor: redColor,
                    buttonText: l10n.noLabel,
                    textColor: Colors.red,
                    onPressed: () {
                      setState(() {
                        finish(context);
                      });
                    },
                  ),
                ),
                Expanded(
                  child: Button(
                    containerBg: kPrimaryColor,
                    borderColor: Colors.transparent,
                    buttonText: l10n.yesLabel,
                    textColor: kWhite,
                    onPressed: () {
                      setState(() {
                        finish(context);
                      });
                    },
                  ),
                ),
              ],
            )
          ],
        ),
      ),
    );
  }
}

class CancelOrderPopUp extends StatefulWidget {
  const CancelOrderPopUp({Key? key}) : super(key: key);

  @override
  State<CancelOrderPopUp> createState() => _CancelOrderPopUpState();
}

class _CancelOrderPopUpState extends State<CancelOrderPopUp> {
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
            Text(
              l10n.cancelOrderWhy,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: kTextStyle.copyWith(color: kNeutralColor, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 10.0),
            const Divider(
              height: 1.0,
              thickness: 1.0,
              color: kBorderColorTextField,
            ),
            const SizedBox(height: 20.0),
            TextFormField(
              keyboardType: TextInputType.multiline,
              maxLines: 2,
              cursorColor: kNeutralColor,
              textInputAction: TextInputAction.next,
              decoration: kInputDecoration.copyWith(labelText: l10n.enterReason, labelStyle: kTextStyle.copyWith(color: kNeutralColor), hintText: '', hintStyle: kTextStyle.copyWith(color: kSubTitleColor), focusColor: kNeutralColor, border: const OutlineInputBorder(), floatingLabelBehavior: FloatingLabelBehavior.always),
            ),
            const SizedBox(height: 10.0),
            Row(
              children: [
                Expanded(
                  child: Button(
                    containerBg: kWhite,
                    borderColor: redColor,
                    buttonText: l10n.cancel,
                    textColor: Colors.red,
                    onPressed: () {
                      setState(() {
                        finish(context);
                      });
                    },
                  ),
                ),
                Expanded(
                  child: Button(
                    containerBg: kPrimaryColor,
                    borderColor: Colors.transparent,
                    buttonText: l10n.confirm,
                    textColor: kWhite,
                    onPressed: () {
                      setState(() {
                        finish(context);
                      });
                    },
                  ),
                ),
              ],
            )
          ],
        ),
      ),
    );
  }
}
