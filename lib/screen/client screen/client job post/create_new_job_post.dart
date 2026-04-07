import 'package:flutter/material.dart';
import 'package:flutter_feather_icons/flutter_feather_icons.dart';
import 'package:freelancer/screen/client%20screen/client%20job%20post/client_job_post.dart';
import 'package:freelancer/screen/widgets/button_global.dart';
import 'package:nb_utils/nb_utils.dart';

import '../../widgets/constant.dart';

class CreateNewJobPost extends StatefulWidget {
  const CreateNewJobPost({Key? key}) : super(key: key);

  @override
  State<CreateNewJobPost> createState() => _CreateNewJobPostState();
}

class _CreateNewJobPostState extends State<CreateNewJobPost> {
  //__________Category____________________________________________________________
  DropdownButton<String> getCategory() {
    List<DropdownMenuItem<String>> dropDownItems = [];
    for (String des in category) {
      var item = DropdownMenuItem(
        value: des,
        child: Text(des),
      );
      dropDownItems.add(item);
    }
    return DropdownButton(
      icon: const Icon(FeatherIcons.chevronDown),
      items: dropDownItems,
      value: selectedCategory,
      style: kTextStyle.copyWith(color: kSubTitleColor),
      onChanged: (value) {
        setState(() {
          selectedCategory = value!;
        });
      },
    );
  }

  //__________SubCategory_________________________________________________________
  DropdownButton<String> getSubCategory() {
    List<DropdownMenuItem<String>> dropDownItems = [];
    for (String des in subcategory) {
      var item = DropdownMenuItem(
        value: des,
        child: Text(des),
      );
      dropDownItems.add(item);
    }
    return DropdownButton(
      icon: const Icon(FeatherIcons.chevronDown),
      items: dropDownItems,
      value: selectedSubCategory,
      style: kTextStyle.copyWith(color: kSubTitleColor),
      onChanged: (value) {
        setState(() {
          selectedSubCategory = value!;
        });
      },
    );
  }

  //__________DeliveryTime________________________________________________________
  DropdownButton<String> getDeliveryTime() {
    List<DropdownMenuItem<String>> dropDownItems = [];
    for (String des in deliveryTimeList) {
      var item = DropdownMenuItem(
        value: des,
        child: Text(des),
      );
      dropDownItems.add(item);
    }
    return DropdownButton(
      icon: const Icon(FeatherIcons.chevronDown),
      items: dropDownItems,
      value: selectedDeliveryTimeList,
      style: kTextStyle.copyWith(color: kSubTitleColor),
      onChanged: (value) {
        setState(() {
          selectedDeliveryTimeList = value!;
        });
      },
    );
  }

  @override
  void initState() {
    super.initState();
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
          'Create New Job Post',
          style: kTextStyle.copyWith(color: kNeutralColor, fontWeight: FontWeight.bold),
        ),
        centerTitle: true,
      ),
      body: Padding(
        padding: const EdgeInsets.only(top: 15.0),
        child: Container(
          width: context.width(),
          padding: const EdgeInsets.only(left: 20.0, right: 20.0),
          decoration: const BoxDecoration(
            color: kWhite,
            borderRadius: BorderRadius.only(
              topRight: Radius.circular(30.0),
              topLeft: Radius.circular(30.0),
            ),
          ),
          child: SingleChildScrollView(
            physics: const BouncingScrollPhysics(),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SizedBox(height: 20.0),
                Text(
                  'Overview',
                  style: kTextStyle.copyWith(color: kNeutralColor, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 15.0),
                TextFormField(
                  keyboardType: TextInputType.name,
                  cursorColor: kNeutralColor,
                  textInputAction: TextInputAction.next,
                  decoration: kInputDecoration.copyWith(
                    labelText: 'Job Title',
                    labelStyle: kTextStyle.copyWith(color: kNeutralColor),
                    hintText: 'Enter job title',
                    hintStyle: kTextStyle.copyWith(color: kSubTitleColor),
                    focusColor: kNeutralColor,
                    border: const OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: 20.0),
                FormField(
                  builder: (FormFieldState<dynamic> field) {
                    return InputDecorator(
                      decoration: kInputDecoration.copyWith(
                        enabledBorder: const OutlineInputBorder(
                          borderRadius: BorderRadius.all(
                            Radius.circular(8.0),
                          ),
                          borderSide: BorderSide(color: kBorderColorTextField, width: 2),
                        ),
                        contentPadding: const EdgeInsets.all(7.0),
                        floatingLabelBehavior: FloatingLabelBehavior.always,
                        labelText: 'Choose a Category',
                        labelStyle: kTextStyle.copyWith(color: kNeutralColor),
                      ),
                      child: DropdownButtonHideUnderline(child: getCategory()),
                    );
                  },
                ),
                const SizedBox(height: 20.0),
                FormField(
                  builder: (FormFieldState<dynamic> field) {
                    return InputDecorator(
                      decoration: kInputDecoration.copyWith(
                        enabledBorder: const OutlineInputBorder(
                          borderRadius: BorderRadius.all(
                            Radius.circular(8.0),
                          ),
                          borderSide: BorderSide(color: kBorderColorTextField, width: 2),
                        ),
                        contentPadding: const EdgeInsets.all(7.0),
                        floatingLabelBehavior: FloatingLabelBehavior.always,
                        labelText: 'Choose a Subcategory',
                        labelStyle: kTextStyle.copyWith(color: kNeutralColor),
                      ),
                      child: DropdownButtonHideUnderline(child: getSubCategory()),
                    );
                  },
                ),
                const SizedBox(height: 20.0),
                FormField(
                  builder: (FormFieldState<dynamic> field) {
                    return InputDecorator(
                      decoration: kInputDecoration.copyWith(
                        enabledBorder: const OutlineInputBorder(
                          borderRadius: BorderRadius.all(
                            Radius.circular(8.0),
                          ),
                          borderSide: BorderSide(color: kBorderColorTextField, width: 2),
                        ),
                        contentPadding: const EdgeInsets.all(7.0),
                        floatingLabelBehavior: FloatingLabelBehavior.always,
                        labelText: 'Delivery Time',
                        labelStyle: kTextStyle.copyWith(color: kNeutralColor),
                      ),
                      child: DropdownButtonHideUnderline(child: getDeliveryTime()),
                    );
                  },
                ),
                const SizedBox(height: 20.0),
                TextFormField(
                  keyboardType: TextInputType.name,
                  cursorColor: kNeutralColor,
                  textInputAction: TextInputAction.next,
                  decoration: kInputDecoration.copyWith(
                    labelText: 'Service Price',
                    labelStyle: kTextStyle.copyWith(color: kNeutralColor),
                    hintText: '\$ 5 minimum',
                    hintStyle: kTextStyle.copyWith(color: kSubTitleColor),
                    focusColor: kNeutralColor,
                    border: const OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: 20.0),
                TextFormField(
                  keyboardType: TextInputType.multiline,
                  cursorColor: kNeutralColor,
                  textInputAction: TextInputAction.next,
                  maxLines: 3,
                  decoration: kInputDecoration.copyWith(
                    labelText: 'Describe The Service',
                    labelStyle: kTextStyle.copyWith(color: kNeutralColor),
                    hintText: 'I need a ui ux designer...',
                    hintStyle: kTextStyle.copyWith(color: kSubTitleColor),
                    focusColor: kNeutralColor,
                    floatingLabelBehavior: FloatingLabelBehavior.always,
                    border: const OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: 20.0),
                TextFormField(
                  showCursor: false,
                  readOnly: true,
                  keyboardType: TextInputType.name,
                  cursorColor: kNeutralColor,
                  textInputAction: TextInputAction.next,
                  decoration: kInputDecoration.copyWith(
                    labelText: 'Upload File & Image',
                    labelStyle: kTextStyle.copyWith(color: kNeutralColor),
                    hintText: 'Upload file and image',
                    hintStyle: kTextStyle.copyWith(color: kSubTitleColor),
                    focusColor: kNeutralColor,
                    border: const OutlineInputBorder(),
                    suffixIcon: const Icon(FeatherIcons.upload, color: kLightNeutralColor),
                  ),
                ),
                const SizedBox(height: 10.0),
              ],
            ),
          ),
        ),
      ),
      bottomNavigationBar: Container(
        decoration: const BoxDecoration(color: kWhite),
        child: ButtonGlobalWithoutIcon(
            buttontext: 'Post',
            buttonDecoration: kButtonDecoration.copyWith(
              color: kPrimaryColor,
              borderRadius: BorderRadius.circular(30.0),
            ),
            onPressed: () {
              const JobPost().launch(context);
            },
            buttonTextColor: kWhite),
      ),
    );
  }
}
