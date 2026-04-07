// import 'package:country_code_picker/country_code_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter_feather_icons/flutter_feather_icons.dart';
import 'package:flutter_iconly/flutter_iconly.dart';
import 'package:freelancer/screen/widgets/button_global.dart';
import 'package:nb_utils/nb_utils.dart';

import '../../seller screen/seller popUp/seller_popup.dart';
import '../../widgets/constant.dart';
import 'client_profile_details.dart';

class ClientEditProfile extends StatefulWidget {
  const ClientEditProfile({Key? key}) : super(key: key);

  @override
  State<ClientEditProfile> createState() => _ClientEditProfileState();
}

class _ClientEditProfileState extends State<ClientEditProfile> {
  //__________Language List____________________________________________________
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

  //__________gender___________________________________________________________
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

  //__________Import_Profile_picture_popup_____________________________________
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

  //__________Save_Profile_success_popup_______________________________________
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
      backgroundColor: kDarkWhite,
      appBar: AppBar(
        backgroundColor: kDarkWhite,
        elevation: 0,
        iconTheme: const IconThemeData(color: kNeutralColor),
        title: Text(
          'Edit Profile',
          style: kTextStyle.copyWith(color: kNeutralColor, fontWeight: FontWeight.bold),
        ),
        centerTitle: true,
      ),
      body: Padding(
        padding: const EdgeInsets.only(top: 20.0),
        child: Container(
          padding: const EdgeInsets.only(left: 20.0, right: 20.0),
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
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SizedBox(height: 20.0),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const SizedBox(height: 15.0),
                    Row(
                      children: [
                        Stack(
                          alignment: Alignment.bottomRight,
                          children: [
                            Container(
                              height: 80,
                              width: 80,
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                border: Border.all(color: kPrimaryColor),
                                image: const DecorationImage(
                                  image: AssetImage('images/profile3.png'),
                                ),
                              ),
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
                                  size: 18,
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(width: 10.0),
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Shaidulislam',
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: kTextStyle.copyWith(color: kNeutralColor, fontWeight: FontWeight.bold, fontSize: 18.0),
                            ),
                            Text(
                              'shaidulislamma@gmail.com',
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: kTextStyle.copyWith(color: kSubTitleColor),
                            ),
                          ],
                        ),
                      ],
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
                            labelStyle: kTextStyle.copyWith(color: kNeutralColor),
                          ),
                          child: DropdownButtonHideUnderline(child: getLanguage()),
                        );
                      },
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
                            labelStyle: kTextStyle.copyWith(color: kNeutralColor),
                          ),
                          child: DropdownButtonHideUnderline(child: getGender()),
                        );
                      },
                    ),
                    const SizedBox(height: 10.0),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
      bottomNavigationBar: Container(
        decoration: const BoxDecoration(color: kWhite),
        child: ButtonGlobalWithoutIcon(
            buttontext: 'Update Profile',
            buttonDecoration: kButtonDecoration.copyWith(
              color: kPrimaryColor,
              borderRadius: BorderRadius.circular(30.0),
            ),
            onPressed: () {
              const ClientProfileDetails().launch(context);
            },
            buttonTextColor: kWhite),
      ),
    );
  }
}
