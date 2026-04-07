import 'package:flutter/material.dart';
import 'package:flutter_feather_icons/flutter_feather_icons.dart';
import 'package:freelancer/screen/widgets/button_global.dart';
import 'package:nb_utils/nb_utils.dart';

import '../../widgets/constant.dart';

class ClientReport extends StatefulWidget {
  const ClientReport({Key? key}) : super(key: key);

  @override
  State<ClientReport> createState() => _ClientReportState();
}

class _ClientReportState extends State<ClientReport> {
  DropdownButton<String> getReportType() {
    List<DropdownMenuItem<String>> dropDownItems = [];
    for (String des in reportTitle) {
      var item = DropdownMenuItem(
        value: des,
        child: Text(des),
      );
      dropDownItems.add(item);
    }
    return DropdownButton(
      icon: const Icon(FeatherIcons.chevronDown),
      items: dropDownItems,
      value: selectedReportTitle,
      style: kTextStyle.copyWith(color: kSubTitleColor),
      onChanged: (value) {
        setState(() {
          selectedReportTitle = value!;
        });
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
          'Report',
          style: kTextStyle.copyWith(color: kNeutralColor, fontWeight: FontWeight.bold),
        ),
        centerTitle: true,
      ),
      bottomNavigationBar: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Expanded(
            child: ButtonGlobalWithoutIcon(
                buttontext: 'Cancel',
                buttonDecoration: kButtonDecoration.copyWith(
                  color: kWhite,
                  borderRadius: BorderRadius.circular(30.0),
                  border: Border.all(color: redColor),
                ),
                onPressed: () {},
                buttonTextColor: redColor),
          ),
          Expanded(
            child: ButtonGlobalWithoutIcon(
                buttontext: 'Send',
                buttonDecoration: kButtonDecoration.copyWith(
                  color: kPrimaryColor,
                  borderRadius: BorderRadius.circular(30.0),
                ),
                onPressed: () {},
                buttonTextColor: kWhite),
          ),
        ],
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
                const SizedBox(height: 30.0),
                TextFormField(
                  keyboardType: TextInputType.name,
                  cursorColor: kNeutralColor,
                  textInputAction: TextInputAction.next,
                  decoration: kInputDecoration.copyWith(
                    labelText: 'Seller Profile URL',
                    labelStyle: kTextStyle.copyWith(color: kNeutralColor),
                    hintText: 'Enter seller profile url',
                    hintStyle: kTextStyle.copyWith(color: kSubTitleColor),
                    focusColor: kNeutralColor,
                    border: const OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: 20.0),
                FormField(
                  builder: (FormFieldState<dynamic> field) {
                    return InputDecorator(
                      decoration: InputDecoration(
                        enabledBorder: const OutlineInputBorder(
                          borderRadius: BorderRadius.all(
                            Radius.circular(8.0),
                          ),
                          borderSide: BorderSide(color: kBorderColorTextField, width: 2),
                        ),
                        contentPadding: const EdgeInsets.all(7.0),
                        floatingLabelBehavior: FloatingLabelBehavior.always,
                        labelText: 'Why do you want to report?',
                        labelStyle: kTextStyle.copyWith(color: kNeutralColor),
                      ),
                      child: DropdownButtonHideUnderline(child: getReportType()),
                    );
                  },
                ),
                const SizedBox(height: 20.0),
                TextFormField(
                  keyboardType: TextInputType.name,
                  cursorColor: kNeutralColor,
                  textInputAction: TextInputAction.next,
                  decoration: kInputDecoration.copyWith(
                    labelText: 'URL of original content',
                    labelStyle: kTextStyle.copyWith(color: kNeutralColor),
                    hintText: 'Enter post url',
                    hintStyle: kTextStyle.copyWith(color: kSubTitleColor),
                    focusColor: kNeutralColor,
                    border: const OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: 20.0),
                TextFormField(
                  keyboardType: TextInputType.multiline,
                  maxLines: 3,
                  cursorColor: kNeutralColor,
                  textInputAction: TextInputAction.next,
                  decoration: kInputDecoration.copyWith(
                    labelText: 'Additional information',
                    labelStyle: kTextStyle.copyWith(color: kNeutralColor),
                    hintText: 'Enter information...',
                    hintStyle: kTextStyle.copyWith(color: kSubTitleColor),
                    focusColor: kNeutralColor,
                    floatingLabelBehavior: FloatingLabelBehavior.always,
                    border: const OutlineInputBorder(),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
