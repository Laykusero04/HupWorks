// import 'package:country_code_picker/country_code_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter_feather_icons/flutter_feather_icons.dart';
import 'package:flutter_iconly/flutter_iconly.dart';
import 'package:freelancer/screen/widgets/button_global.dart';
import 'package:nb_utils/nb_utils.dart';
import 'package:step_progress_indicator/step_progress_indicator.dart';

import '../../widgets/constant.dart';
import '../../widgets/data.dart';
import '../seller popUp/seller_popup.dart';

class SetupSellerProfile extends StatefulWidget {
  const SetupSellerProfile({Key? key}) : super(key: key);

  @override
  State<SetupSellerProfile> createState() => _SetupSellerProfileState();
}

class _SetupSellerProfileState extends State<SetupSellerProfile> {
  PageController pageController = PageController(initialPage: 0);
  int currentIndexPage = 0;
  double percent = 33.3;

  //__________Language List_____________________________________________________
  DropdownButton<String> getLanguage() {
    List<DropdownMenuItem<String>> dropDownItems = [];
    for (String des in language) {
      var item = DropdownMenuItem(
        value: des,
        child: Text(des),
      );
      dropDownItems.add(item);
    }
    return DropdownButton(
      icon: const Icon(FeatherIcons.chevronDown),
      items: dropDownItems,
      value: selectedLanguage,
      style: kTextStyle.copyWith(color: kSubTitleColor),
      onChanged: (value) {
        setState(() {
          selectedLanguage = value!;
        });
      },
    );
  }

  //__________gender____________________________________________________________
  DropdownButton<String> getGender() {
    List<DropdownMenuItem<String>> dropDownItems = [];
    for (String des in gender) {
      var item = DropdownMenuItem(
        value: des,
        child: Text(des),
      );
      dropDownItems.add(item);
    }
    return DropdownButton(
      icon: const Icon(FeatherIcons.chevronDown),
      items: dropDownItems,
      value: selectedGender,
      style: kTextStyle.copyWith(color: kSubTitleColor),
      onChanged: (value) {
        setState(() {
          selectedGender = value!;
        });
      },
    );
  }

  //__________language level___________________________________________________
  DropdownButton<String> getLevel() {
    List<DropdownMenuItem<String>> dropDownItems = [];
    for (String des in languageLevel) {
      var item = DropdownMenuItem(
        value: des,
        child: Text(des),
      );
      dropDownItems.add(item);
    }
    return DropdownButton(
      icon: const Icon(FeatherIcons.chevronDown),
      items: dropDownItems,
      value: selectedLanguageLevel,
      style: kTextStyle.copyWith(color: kSubTitleColor),
      onChanged: (value) {
        setState(() {
          selectedLanguageLevel = value!;
        });
      },
    );
  }

  //__________Add_Language popup________________________________________________
  void showLanguagePopUp() {
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
              child: const SellerAddLanguagePopUp(),
            );
          },
        );
      },
    );
  }

  //__________Add_Skill popup________________________________________________
  void showSkillPopUp() {
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
              child: const SellerAddSkillPopUp(),
            );
          },
        );
      },
    );
  }

  //__________Import_Profile_picture_popup________________________________________________
  void showImportProfilePopUp() {
    showDialog(
      barrierDismissible: false,
      context: context,
      builder: (BuildContext context) {
        return StatefulBuilder(
          builder: (BuildContext context, void Function(void Function()) setState) {
            return Dialog(
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8.0),
              ),
              child: const ImportImagePopUp(),
            );
          },
        );
      },
    );
  }

  //__________Save_Profile_success_popup________________________________________________
  void saveProfilePopUp() {
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
              child: const SaveProfilePopUp(),
            );
          },
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: kWhite,
      appBar: AppBar(
        elevation: 0,
        automaticallyImplyLeading: true,
        iconTheme: const IconThemeData(color: kNeutralColor),
        backgroundColor: kDarkWhite,
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.only(
            bottomLeft: Radius.circular(50.0),
            bottomRight: Radius.circular(50.0),
          ),
        ),
        toolbarHeight: 80,
        centerTitle: true,
        title: Text(
          'Setup Profile',
          style: kTextStyle.copyWith(color: kNeutralColor, fontWeight: FontWeight.bold),
        ),
      ),
      body: PageView.builder(
        itemCount: 3,
        physics: const PageScrollPhysics(),
        controller: pageController,
        onPageChanged: (int index) => setState(() => currentIndexPage = index),
        itemBuilder: (_, i) {
          return Padding(
            padding: const EdgeInsets.all(20.0),
            child: SingleChildScrollView(
              physics: const BouncingScrollPhysics(),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        currentIndexPage == 0
                            ? 'Step 1 of 3'
                            : currentIndexPage == 1
                                ? 'Step 2 of 3'
                                : 'Step 3 of 3',
                        style: kTextStyle.copyWith(color: kNeutralColor),
                      ),
                      const SizedBox(width: 10.0),
                      Expanded(
                        child: StepProgressIndicator(
                          totalSteps: 3,
                          currentStep: currentIndexPage + 1,
                          size: 8,
                          padding: 0,
                          selectedColor: kPrimaryColor,
                          unselectedColor: kPrimaryColor.withOpacity(0.2),
                          roundedEdges: const Radius.circular(10),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 20.0),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Uplaod Your Photo',
                        style: kTextStyle.copyWith(color: kNeutralColor, fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(height: 10.0),
                      Center(
                        child: Stack(
                          alignment: Alignment.bottomRight,
                          children: [
                            Container(
                              height: 120,
                              width: 120,
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                border: Border.all(color: kPrimaryColor),
                              ),
                              child: const Icon(IconlyBold.profile, color: kBorderColorTextField, size: 68),
                            ),
                            GestureDetector(
                              onTap: () {
                                showImportProfilePopUp();
                              },
                              child: Container(
                                padding: const EdgeInsets.all(5),
                                decoration: BoxDecoration(
                                  color: kWhite,
                                  shape: BoxShape.circle,
                                  border: Border.all(color: kPrimaryColor),
                                ),
                                child: const Icon(
                                  IconlyBold.camera,
                                  color: kPrimaryColor,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 30.0),
                      TextFormField(
                        keyboardType: TextInputType.name,
                        cursorColor: kNeutralColor,
                        textInputAction: TextInputAction.next,
                        decoration: kInputDecoration.copyWith(
                          labelText: 'User Name',
                          labelStyle: kTextStyle.copyWith(color: kNeutralColor),
                          hintText: 'Enter user name',
                          hintStyle: kTextStyle.copyWith(color: kSubTitleColor),
                          focusColor: kNeutralColor,
                          border: const OutlineInputBorder(),
                        ),
                      ),
                      const SizedBox(height: 20.0),
                      TextFormField(
                        keyboardType: TextInputType.emailAddress,
                        cursorColor: kNeutralColor,
                        textInputAction: TextInputAction.next,
                        decoration: kInputDecoration.copyWith(
                          hintText: 'Enter Phone No.',
                          hintStyle: kTextStyle.copyWith(color: kSubTitleColor),
                          focusColor: kNeutralColor,
                          border: const OutlineInputBorder(),
                          // prefixIcon: CountryCodePicker(
                          //   padding: EdgeInsets.zero,
                          //   onChanged: print,
                          //   initialSelection: 'BD',
                          //   showFlag: true,
                          //   showDropDownButton: true,
                          //   alignLeft: false,
                          // ),
                        ),
                      ),
                      const SizedBox(height: 20.0),
                      TextFormField(
                        keyboardType: TextInputType.name,
                        cursorColor: kNeutralColor,
                        textInputAction: TextInputAction.next,
                        decoration: kInputDecoration.copyWith(
                          labelText: 'Country',
                          labelStyle: kTextStyle.copyWith(color: kNeutralColor),
                          hintText: 'Enter Country Name',
                          hintStyle: kTextStyle.copyWith(color: kSubTitleColor),
                          focusColor: kNeutralColor,
                          border: const OutlineInputBorder(),
                        ),
                      ),
                      const SizedBox(height: 20.0),
                      TextFormField(
                        keyboardType: TextInputType.name,
                        cursorColor: kNeutralColor,
                        textInputAction: TextInputAction.next,
                        decoration: kInputDecoration.copyWith(
                          labelText: 'Street Address (won’t show on profile)',
                          labelStyle: kTextStyle.copyWith(color: kNeutralColor),
                          hintText: 'Enter street address',
                          hintStyle: kTextStyle.copyWith(color: kSubTitleColor),
                          focusColor: kNeutralColor,
                          border: const OutlineInputBorder(),
                        ),
                      ),
                      const SizedBox(height: 20.0),
                      TextFormField(
                        keyboardType: TextInputType.name,
                        cursorColor: kNeutralColor,
                        textInputAction: TextInputAction.next,
                        decoration: kInputDecoration.copyWith(
                          labelText: 'City',
                          labelStyle: kTextStyle.copyWith(color: kNeutralColor),
                          hintText: 'Enter city',
                          hintStyle: kTextStyle.copyWith(color: kSubTitleColor),
                          focusColor: kNeutralColor,
                          border: const OutlineInputBorder(),
                        ),
                      ),
                      const SizedBox(height: 20.0),
                      TextFormField(
                        keyboardType: TextInputType.name,
                        cursorColor: kNeutralColor,
                        textInputAction: TextInputAction.next,
                        decoration: kInputDecoration.copyWith(
                          labelText: 'State',
                          labelStyle: kTextStyle.copyWith(color: kNeutralColor),
                          hintText: 'Enter state',
                          hintStyle: kTextStyle.copyWith(color: kSubTitleColor),
                          focusColor: kNeutralColor,
                          border: const OutlineInputBorder(),
                        ),
                      ),
                      const SizedBox(height: 20.0),
                      TextFormField(
                        keyboardType: TextInputType.name,
                        cursorColor: kNeutralColor,
                        textInputAction: TextInputAction.next,
                        decoration: kInputDecoration.copyWith(
                          labelText: 'ZIP/Postal Code',
                          labelStyle: kTextStyle.copyWith(color: kNeutralColor),
                          hintText: 'Enter zip/post code',
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
                              labelText: 'Select Language',
                              labelStyle: kTextStyle.copyWith(color: kNeutralColor, fontWeight: FontWeight.bold),
                            ),
                            child: DropdownButtonHideUnderline(child: getLanguage()),
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
                              labelText: 'Select Gender',
                              labelStyle: kTextStyle.copyWith(color: kNeutralColor, fontWeight: FontWeight.bold),
                            ),
                            child: DropdownButtonHideUnderline(child: getGender()),
                          );
                        },
                      ),
                    ],
                  ).visible(currentIndexPage == 0),
                  Column(
                    children: [
                      GestureDetector(
                        onTap: () {
                          setState(() {
                            showLanguagePopUp();
                          });
                        },
                        child: Row(
                          children: [
                            Text(
                              'Languages',
                              style: kTextStyle.copyWith(color: kNeutralColor, fontWeight: FontWeight.bold),
                            ),
                            const Spacer(),
                            const Icon(FeatherIcons.plusCircle, color: kSubTitleColor, size: 18.0),
                            const SizedBox(width: 5.0),
                            Text(
                              'Add New',
                              style: kTextStyle.copyWith(color: kSubTitleColor),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 20.0),
                      const InfoShowCase(
                        title: 'English',
                        subTitle: 'Fluent',
                      ),
                      const SizedBox(height: 20.0),
                      const InfoShowCase(
                        title: 'Bengali',
                        subTitle: 'Fluent',
                      ),
                      const SizedBox(height: 30.0),
                      Row(
                        children: [
                          Text(
                            'Skills',
                            style: kTextStyle.copyWith(color: kNeutralColor, fontWeight: FontWeight.bold),
                          ),
                          const Spacer(),
                          const Icon(FeatherIcons.plusCircle, color: kSubTitleColor, size: 18.0),
                          const SizedBox(width: 5.0),
                          GestureDetector(
                            onTap: () {
                              setState(() {
                                showSkillPopUp();
                              });
                            },
                            child: Text(
                              'Add New',
                              style: kTextStyle.copyWith(color: kSubTitleColor),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 20.0),
                      const InfoShowCase(
                        title: 'Ui Design',
                        subTitle: 'Expert',
                      ),
                      const SizedBox(height: 20.0),
                      const InfoShowCase(
                        title: 'Visual Design',
                        subTitle: 'Expert',
                      ),
                      const SizedBox(height: 30.0),
                      Row(
                        children: [
                          Text(
                            'Education',
                            style: kTextStyle.copyWith(color: kNeutralColor, fontWeight: FontWeight.bold),
                          ),
                          const Spacer(),
                          const Icon(FeatherIcons.plusCircle, color: kSubTitleColor, size: 18.0),
                          const SizedBox(width: 5.0),
                          Text(
                            'Add Education',
                            style: kTextStyle.copyWith(color: kSubTitleColor),
                          ),
                        ],
                      ),
                      const SizedBox(height: 20.0),
                      const InfoShowCase2(
                        title: 'B.Sc. - grapich design',
                        subTitle: 'Khilgaon model university, Bangladesh,, Bangladesh, Graduated 2018',
                      ),
                      const SizedBox(height: 30.0),
                      Row(
                        children: [
                          Text(
                            'Certification',
                            style: kTextStyle.copyWith(color: kNeutralColor, fontWeight: FontWeight.bold),
                          ),
                          const Spacer(),
                          const Icon(FeatherIcons.plusCircle, color: kSubTitleColor, size: 18.0),
                          const SizedBox(width: 5.0),
                          Text(
                            'Add Certification',
                            style: kTextStyle.copyWith(color: kSubTitleColor),
                          ),
                        ],
                      ),
                      const SizedBox(height: 20.0),
                      const InfoShowCase2(
                        title: 'UI/UX Design',
                        subTitle: 'Shikhbe Shobai Institute 2018',
                      ),
                    ],
                  ).visible(currentIndexPage == 1),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'About Us',
                        style: kTextStyle.copyWith(color: kNeutralColor, fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(height: 15.0),
                      TextFormField(
                        keyboardType: TextInputType.multiline,
                        maxLines: 8,
                        cursorColor: kNeutralColor,
                        textInputAction: TextInputAction.next,
                        decoration: kInputDecoration.copyWith(
                          hintText: 'Write a brief description about you..',
                          hintStyle: kTextStyle.copyWith(color: kLightNeutralColor),
                          focusColor: kNeutralColor,
                          border: const OutlineInputBorder(),
                        ),
                      ),
                    ],
                  ).visible(currentIndexPage == 2),
                ],
              ),
            ),
          );
        },
      ),
      bottomNavigationBar: ButtonGlobalWithoutIcon(
          buttontext: currentIndexPage < 2 ? 'Continue' : 'Save Profile',
          buttonDecoration: kButtonDecoration.copyWith(
            color: kPrimaryColor,
            borderRadius: BorderRadius.circular(30.0),
          ),
          onPressed: () {
            currentIndexPage < 2;
            currentIndexPage < 2 ? pageController.nextPage(duration: const Duration(microseconds: 3000), curve: Curves.bounceInOut) : saveProfilePopUp();
          },
          buttonTextColor: kWhite),
    );
  }
}
