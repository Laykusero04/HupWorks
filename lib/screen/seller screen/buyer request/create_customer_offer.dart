import 'package:flutter/material.dart';
import 'package:flutter_feather_icons/flutter_feather_icons.dart';
import 'package:freelancer/screen/seller%20screen/seller%20home/seller_home.dart';
import 'package:nb_utils/nb_utils.dart';

import '../../widgets/button_global.dart';
import '../../widgets/constant.dart';

class CreateCustomerOffer extends StatefulWidget {
  const CreateCustomerOffer({Key? key}) : super(key: key);

  @override
  State<CreateCustomerOffer> createState() => _CreateCustomerOfferState();
}

class _CreateCustomerOfferState extends State<CreateCustomerOffer> {
  //__________deliveryTime___________________________________________________
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

  //__________revisionTime___________________________________________________
  DropdownButton<String> getRevisionTime() {
    List<DropdownMenuItem<String>> dropdownItems = [];
    for (String des in revisionTime) {
      var item = DropdownMenuItem(
        value: des,
        child: Text(des),
      );
      dropdownItems.add(item);
    }
    return DropdownButton(
        items: dropdownItems,
        icon: const Icon(FeatherIcons.chevronDown),
        value: selectedRevisionTime,
        style: kTextStyle.copyWith(color: kSubTitleColor),
        onChanged: (value) {
          setState(() {
            selectedRevisionTime = value!;
          });
        });
  }

  List<String> offerScopeList = [
    'Source File',
    'High Resolution',
  ];

  List<String> selectedOfferScopeList = ['Source File'];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: kDarkWhite,
      appBar: AppBar(
        backgroundColor: kDarkWhite,
        elevation: 0,
        iconTheme: const IconThemeData(color: kNeutralColor),
        title: Text(
          'Create a custom Offer',
          style: kTextStyle.copyWith(color: kNeutralColor, fontWeight: FontWeight.bold),
        ),
        centerTitle: true,
      ),
      bottomNavigationBar: Container(
        decoration: const BoxDecoration(color: kWhite),
        child: ButtonGlobalWithoutIcon(
            buttontext: 'Submit Offer',
            buttonDecoration: kButtonDecoration.copyWith(color: kPrimaryColor, borderRadius: BorderRadius.circular(30.0)),
            onPressed: () {
              const SellerHome().launch(context);
            },
            buttonTextColor: kWhite),
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
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SizedBox(height: 20.0),
                Container(
                  padding: const EdgeInsets.all(10.0),
                  decoration: BoxDecoration(
                      color: kWhite,
                      border: Border.all(color: kBorderColorTextField),
                      boxShadow: const [
                        BoxShadow(
                          color: kBorderColorTextField,
                          spreadRadius: 0.2,
                          blurRadius: 4.0,
                          offset: Offset(0, 2),
                        ),
                      ],
                      borderRadius: BorderRadius.circular(10.0)),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      ListTile(
                        contentPadding: EdgeInsets.zero,
                        leading: Container(
                          height: 44,
                          width: 44,
                          decoration: const BoxDecoration(
                            shape: BoxShape.circle,
                            image: DecorationImage(
                              image: AssetImage('images/profile1.png'),
                              fit: BoxFit.cover,
                            ),
                          ),
                        ),
                        title: Text(
                          'Shaidul Islam',
                          style: kTextStyle.copyWith(color: kNeutralColor, fontWeight: FontWeight.bold),
                        ),
                        subtitle: Text(
                          '28 Jun 2023',
                          style: kTextStyle.copyWith(color: kSubTitleColor),
                        ),
                      ),
                      const Divider(
                        height: 0,
                        thickness: 1.0,
                        color: kBorderColorTextField,
                      ),
                      const SizedBox(height: 10.0),
                      Text(
                        'I Need UI UX Designer',
                        style: kTextStyle.copyWith(color: kNeutralColor, fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(height: 5.0),
                      ReadMoreText(
                        'Lorem ipsum dolor sit amet consectetur. Elementum nulla quis nunc Lorem ipsum dolor sit amet consectetur. O rci pulvinar sit nec donec pellentesque ve nenatis nunc vel pretium. Dictumst bib en dum pharetra hendrerit tortor nisl. Nulla accumsan ',
                        style: kTextStyle.copyWith(color: kLightNeutralColor),
                        trimLines: 2,
                        colorClickableText: kPrimaryColor,
                        trimMode: TrimMode.Line,
                        trimCollapsedText: '..Read more',
                        trimExpandedText: '..Read less',
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 15.0),
                Container(
                  decoration: BoxDecoration(
                      color: kWhite,
                      border: Border.all(color: kBorderColorTextField),
                      boxShadow: const [
                        BoxShadow(
                          color: kBorderColorTextField,
                          spreadRadius: 0.2,
                          blurRadius: 4.0,
                          offset: Offset(0, 2),
                        ),
                      ],
                      borderRadius: BorderRadius.circular(10.0)),
                  child: Row(
                    children: [
                      Container(
                        height: 67,
                        width: 79,
                        decoration: const BoxDecoration(
                          borderRadius: BorderRadius.only(
                            topLeft: Radius.circular(10.0),
                            bottomLeft: Radius.circular(10.0),
                          ),
                          image: DecorationImage(image: AssetImage('images/shot2.png'), fit: BoxFit.cover),
                        ),
                      ),
                      Flexible(
                        child: Padding(
                          padding: const EdgeInsets.only(left: 5.0, right: 5.0),
                          child: Text(
                            'Mobile UI UX design or app UI UX design.',
                            maxLines: 2,
                            style: kTextStyle.copyWith(color: kNeutralColor, fontWeight: FontWeight.bold),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 20.0),
                Text(
                  'Description',
                  style: kTextStyle.copyWith(color: kNeutralColor, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 15.0),
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(10.0),
                    border: Border.all(color: kBorderColorTextField),
                  ),
                  child: Text(
                    'Hello there, This is Ibne Riead! A professional UI/UX Design experience with 2+ years in this field. I specialize in Mobile Apps and Website Design. I always try to meet the needs of my client. ',
                    style: kTextStyle.copyWith(color: kSubTitleColor),
                  ),
                ),
                const SizedBox(height: 15.0),
                TextFormField(
                  keyboardType: TextInputType.name,
                  cursorColor: kNeutralColor,
                  decoration: kInputDecoration.copyWith(
                    labelText: 'Total Offer Amount',
                    labelStyle: kTextStyle.copyWith(color: kNeutralColor),
                    hintText: 'Enter amount',
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
                        labelText: 'Delivery Time',
                        labelStyle: kTextStyle.copyWith(color: kNeutralColor),
                      ),
                      child: DropdownButtonHideUnderline(child: getDeliveryTime()),
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
                        labelText: 'Revisions (optional)',
                        labelStyle: kTextStyle.copyWith(color: kNeutralColor),
                      ),
                      child: DropdownButtonHideUnderline(child: getRevisionTime()),
                    );
                  },
                ),
                Theme(
                  data: Theme.of(context).copyWith(dividerColor: Colors.transparent),
                  child: ExpansionTile(
                    initiallyExpanded: true,
                    childrenPadding: EdgeInsets.zero,
                    tilePadding: EdgeInsets.zero,
                    iconColor: kLightNeutralColor,
                    collapsedIconColor: kLightNeutralColor,
                    trailing: const Icon(FeatherIcons.chevronDown),
                    title: Text(
                      'Define the offer scope',
                      style: kTextStyle.copyWith(color: kNeutralColor, fontWeight: FontWeight.bold, fontSize: 14),
                    ),
                    children: [
                      ListView.builder(
                        itemCount: offerScopeList.length,
                        shrinkWrap: true,
                        itemBuilder: (_, i) {
                          return Column(
                            children: [
                              ListTile(
                                onTap: () {
                                  setState(
                                    () {
                                      selectedOfferScopeList.contains(offerScopeList[i]) ? selectedOfferScopeList.remove(offerScopeList[i]) : selectedOfferScopeList.add(offerScopeList[i]);
                                    },
                                  );
                                },
                                contentPadding: EdgeInsets.zero,
                                visualDensity: const VisualDensity(vertical: -3),
                                title: Text(
                                  offerScopeList[i],
                                  style: kTextStyle.copyWith(color: kSubTitleColor),
                                ),
                                trailing: Icon(
                                  selectedOfferScopeList.contains(offerScopeList[i]) ? Icons.check_circle : Icons.circle_outlined,
                                  color: selectedOfferScopeList.contains(offerScopeList[i]) ? kPrimaryColor : kSubTitleColor,
                                ),
                              ),
                              const Divider(
                                thickness: 1.0,
                                color: kBorderColorTextField,
                                height: 1,
                              )
                            ],
                          );
                        },
                      ),
                    ],
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
