import 'package:flutter/material.dart';
import 'package:flutter_feather_icons/flutter_feather_icons.dart';
import 'package:flutter_iconly/flutter_iconly.dart';
import 'package:freelancer/screen/widgets/button_global.dart';
import 'package:nb_utils/nb_utils.dart';
import 'package:step_progress_indicator/step_progress_indicator.dart';

import '../../widgets/constant.dart';
import '../client popup/client_popup.dart';

class Requirements extends StatefulWidget {
  const Requirements({Key? key}) : super(key: key);

  @override
  State<Requirements> createState() => _RequirementsState();
}

class _RequirementsState extends State<Requirements> {
  //__________Show_upload_popup________________________________________________
  void showUploadDocPopUp() {
    showDialog(
      barrierDismissible: false,
      context: context,
      builder: (BuildContext context) {
        return StatefulBuilder(
          builder: (BuildContext context, void Function(void Function()) setState) {
            return Dialog(
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16.0),
              ),
              child: const UploadRequirementsPopUp(),
            );
          },
        );
      },
    );
  }

  //__________Show_success_popup________________________________________________
  void uploadCompletePopUp() {
    showDialog(
      barrierDismissible: false,
      context: context,
      builder: (BuildContext context) {
        return StatefulBuilder(
          builder: (BuildContext context, void Function(void Function()) setState) {
            return Dialog(
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16.0),
              ),
              child: const UploadCompletePopUp(),
            );
          },
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      bottomNavigationBar: Container(
        decoration: const BoxDecoration(color: kWhite),
        child: ButtonGlobalWithoutIcon(
            buttontext: 'Submit Requirements',
            buttonDecoration: kButtonDecoration.copyWith(
              color: kPrimaryColor,
              borderRadius: BorderRadius.circular(30.0),
            ),
            onPressed: () {
              setState(() {
                uploadCompletePopUp();
              });
            },
            buttonTextColor: kWhite),
      ),
      backgroundColor: kDarkWhite,
      appBar: AppBar(
        backgroundColor: kDarkWhite,
        elevation: 0,
        iconTheme: const IconThemeData(color: kNeutralColor),
        title: Text(
          'Send Requirements',
          style: kTextStyle.copyWith(color: kNeutralColor, fontWeight: FontWeight.bold),
        ),
        centerTitle: true,
      ),
      body: Padding(
        padding: const EdgeInsets.only(top: 15.0),
        child: Container(
          padding: const EdgeInsets.all(
            20.0,
          ),
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
              Text(
                'Please give me your file, photo.',
                style: kTextStyle.copyWith(color: kNeutralColor, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 20.0),
              TextFormField(
                onTap: () {
                  setState(() {
                    showUploadDocPopUp();
                  });
                },
                readOnly: true,
                keyboardType: TextInputType.name,
                cursorColor: kNeutralColor,
                textInputAction: TextInputAction.next,
                decoration: kInputDecoration.copyWith(
                  labelText: 'Uplaod file,photo and docoment',
                  labelStyle: kTextStyle.copyWith(color: kNeutralColor),
                  hintText: 'Tap icon to attach a file',
                  hintStyle: kTextStyle.copyWith(color: kSubTitleColor),
                  focusColor: kLightNeutralColor,
                  border: const OutlineInputBorder(),
                  floatingLabelBehavior: FloatingLabelBehavior.always,
                  suffixIcon: const Icon(
                    FeatherIcons.upload,
                    color: kLightNeutralColor,
                  ),
                ),
              ),
              const SizedBox(height: 20.0),
              ListTile(
                contentPadding: EdgeInsets.zero,
                horizontalTitleGap: 10.0,
                leading: Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: kPrimaryColor.withOpacity(0.1),
                  ),
                  child: const Icon(
                    IconlyBold.document,
                    color: kPrimaryColor,
                  ),
                ),
                title: Text(
                  'Uploading file 23564 2545265',
                  style: kTextStyle.copyWith(color: kNeutralColor),
                ),
                subtitle: StepProgressIndicator(
                  totalSteps: 100,
                  currentStep: 60,
                  size: 8,
                  padding: 0,
                  selectedColor: kPrimaryColor,
                  unselectedColor: kPrimaryColor.withOpacity(0.1),
                  roundedEdges: const Radius.circular(10),
                ),
              ),
              ListTile(
                contentPadding: EdgeInsets.zero,
                horizontalTitleGap: 10.0,
                leading: Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: kPrimaryColor.withOpacity(0.1),
                  ),
                  child: const Icon(
                    IconlyBold.document,
                    color: kPrimaryColor,
                  ),
                ),
                title: Text(
                  'Uploading file 23564 2545265',
                  style: kTextStyle.copyWith(color: kNeutralColor),
                ),
                subtitle: StepProgressIndicator(
                  totalSteps: 100,
                  currentStep: 60,
                  size: 8,
                  padding: 0,
                  selectedColor: kPrimaryColor,
                  unselectedColor: kPrimaryColor.withOpacity(0.1),
                  roundedEdges: const Radius.circular(10),
                ),
              )
            ],
          ),
        ),
      ),
    );
  }
}
