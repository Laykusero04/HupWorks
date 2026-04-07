import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_feather_icons/flutter_feather_icons.dart';
import 'package:flutter_iconly/flutter_iconly.dart';
import 'package:freelancer/screen/seller%20screen/seller%20popUp/seller_popup.dart';
import 'package:freelancer/screen/widgets/button_global.dart';
import 'package:nb_utils/nb_utils.dart';
import 'package:step_progress_indicator/step_progress_indicator.dart';
import 'package:textfield_tags/textfield_tags.dart';

import '../../widgets/constant.dart';
import 'create_service.dart';

class CreateNewService extends StatefulWidget {
  const CreateNewService({Key? key}) : super(key: key);

  @override
  State<CreateNewService> createState() => _CreateNewServiceState();
}

class _CreateNewServiceState extends State<CreateNewService> {
  PageController pageController = PageController(initialPage: 0);
  int currentIndexPage = 0;
  double percent = 33.3;

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

  //__________SubCategory____________________________________________________________
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

  //__________ServiceType____________________________________________________________
  DropdownButton<String> getServiceType() {
    List<DropdownMenuItem<String>> dropDownItems = [];
    for (String des in serviceType) {
      var item = DropdownMenuItem(
        value: des,
        child: Text(des),
      );
      dropDownItems.add(item);
    }
    return DropdownButton(
      icon: const Icon(FeatherIcons.chevronDown),
      items: dropDownItems,
      value: selectedServiceType,
      style: kTextStyle.copyWith(color: kSubTitleColor),
      onChanged: (value) {
        setState(() {
          selectedServiceType = value!;
        });
      },
    );
  }

  //__________DeliveryTime____________________________________________________________
  DropdownButton<String> getDeliveryTime() {
    List<DropdownMenuItem<String>> dropDownItems = [];
    for (String des in deliveryTime) {
      var item = DropdownMenuItem(
        value: des,
        child: Text(des),
      );
      dropDownItems.add(item);
    }
    return DropdownButton(
      icon: const Icon(
        FeatherIcons.chevronDown,
        color: kLightNeutralColor,
        size: 18,
      ),
      items: dropDownItems,
      value: selectedDeliveryTime,
      style: kTextStyle.copyWith(color: kSubTitleColor),
      onChanged: (value) {
        setState(() {
          selectedDeliveryTime = value!;
        });
      },
    );
  }

  //__________totalScreen____________________________________________________________
  DropdownButton<String> getTotalScreen() {
    List<DropdownMenuItem<String>> dropDownItems = [];
    for (String des in pageCount) {
      var item = DropdownMenuItem(
        value: des,
        child: Text(des),
      );
      dropDownItems.add(item);
    }
    return DropdownButton(
      icon: const Icon(
        FeatherIcons.chevronDown,
        color: kLightNeutralColor,
        size: 18,
      ),
      items: dropDownItems,
      value: selectedPageCount,
      style: kTextStyle.copyWith(color: kSubTitleColor),
      onChanged: (value) {
        setState(() {
          selectedPageCount = value!;
        });
      },
    );
  }

  List<String> serviceTags = const ['UI UX Design', 'Flutter', 'Java', 'Graphic', 'language'];

  //__________Create_FAQ_PopUP________________________________________________
  void showAddFAQPopUp() {
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
              child: const AddFAQPopUp(),
            );
          },
        );
      },
    );
  }

  bool isSelected = true;

  late double _distanceToField;
  late StringTagController _stringTagController;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _distanceToField = MediaQuery.of(context).size.width;
  }

  @override
  void initState() {
    super.initState();
    _stringTagController = StringTagController();
  }

  @override
  void dispose() {
    super.dispose();
    _stringTagController.dispose();
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
          'Create New Service',
          style: kTextStyle.copyWith(color: kNeutralColor, fontWeight: FontWeight.bold),
        ),
        centerTitle: true,
      ),
      body: PageView.builder(
        itemCount: 3,
        physics: const NeverScrollableScrollPhysics(),
        controller: pageController,
        onPageChanged: (int index) => setState(() => currentIndexPage = index),
        itemBuilder: (_, i) {
          return Padding(
            padding: const EdgeInsets.only(top: 10.0),
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
                    Column(
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
                          inputFormatters: [
                            LengthLimitingTextInputFormatter(60),
                          ],
                          maxLength: 60,
                          decoration: kInputDecoration.copyWith(
                            labelText: 'Service Title',
                            labelStyle: kTextStyle.copyWith(color: kNeutralColor),
                            hintText: 'Enter service title',
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
                                labelText: 'Category',
                                labelStyle: kTextStyle.copyWith(color: kNeutralColor, fontWeight: FontWeight.bold),
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
                                labelText: 'Subcategory',
                                labelStyle: kTextStyle.copyWith(color: kNeutralColor, fontWeight: FontWeight.bold),
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
                                labelText: 'Service Type',
                                labelStyle: kTextStyle.copyWith(color: kNeutralColor, fontWeight: FontWeight.bold),
                              ),
                              child: DropdownButtonHideUnderline(child: getServiceType()),
                            );
                          },
                        ),
                        const SizedBox(height: 20.0),
                        TextFormField(
                          keyboardType: TextInputType.multiline,
                          cursorColor: kNeutralColor,
                          textInputAction: TextInputAction.next,
                          maxLines: 5,
                          inputFormatters: [
                            LengthLimitingTextInputFormatter(80),
                          ],
                          maxLength: 800,
                          decoration: kInputDecoration.copyWith(
                            labelText: 'Service Description',
                            labelStyle: kTextStyle.copyWith(color: kNeutralColor),
                            hintText: 'Briefly describe your service...',
                            hintStyle: kTextStyle.copyWith(color: kSubTitleColor),
                            focusColor: kNeutralColor,
                            floatingLabelBehavior: FloatingLabelBehavior.always,
                            border: const OutlineInputBorder(),
                          ),
                        ),
                        const SizedBox(height: 20.0),
                        Text(
                          'Service tags',
                          style: kTextStyle.copyWith(color: kNeutralColor, fontWeight: FontWeight.bold),
                        ),
                        const SizedBox(height: 15.0),
                        TextFieldTags<String>(
                          textfieldTagsController: _stringTagController,
                          initialTags: const ['User 1', 'User 2'],
                          textSeparators: const [' ', ','],
                          letterCase: LetterCase.normal,
                          validator: (String tag) {
                            if (tag == 'php') {
                              return 'No, please just no';
                            } else if (_stringTagController.getTags!.contains(tag)) {
                              return 'You\'ve already entered that';
                            }
                            return null;
                          },
                          inputFieldBuilder: (context, inputFieldValues) {
                            return Padding(
                              padding: const EdgeInsets.symmetric(horizontal: 10.0),
                              child: TextField(
                                onTap: () {
                                  _stringTagController.getFocusNode?.requestFocus();
                                },
                                controller: inputFieldValues.textEditingController,
                                focusNode: inputFieldValues.focusNode,
                                decoration: kInputDecoration.copyWith(
                                  isDense: true,
                                  helperText: 'Enter language...',
                                  helperStyle: const TextStyle(
                                    color: Color.fromARGB(255, 74, 137, 92),
                                  ),
                                  hintText: inputFieldValues.tags.isNotEmpty ? '' : "Enter tag...",
                                  errorText: inputFieldValues.error,
                                  prefixIconConstraints: BoxConstraints(maxWidth: _distanceToField * 0.8),
                                  prefixIcon: inputFieldValues.tags.isNotEmpty
                                      ? SingleChildScrollView(
                                          controller: inputFieldValues.tagScrollController,
                                          scrollDirection: Axis.horizontal,
                                          child: Padding(
                                            padding: const EdgeInsets.only(
                                              top: 8,
                                              bottom: 8,
                                              left: 8,
                                            ),
                                            child: Wrap(
                                                runSpacing: 4.0,
                                                spacing: 4.0,
                                                children: inputFieldValues.tags.map((String tag) {
                                                  return Container(
                                                    decoration: const BoxDecoration(
                                                      borderRadius: BorderRadius.all(
                                                        Radius.circular(20.0),
                                                      ),
                                                      color: kPrimaryColor,
                                                    ),
                                                    margin: const EdgeInsets.symmetric(horizontal: 5.0),
                                                    padding: const EdgeInsets.symmetric(horizontal: 10.0, vertical: 5.0),
                                                    child: Row(
                                                      mainAxisAlignment: MainAxisAlignment.start,
                                                      mainAxisSize: MainAxisSize.min,
                                                      children: [
                                                        InkWell(
                                                          child: Text(
                                                            '#$tag',
                                                            style: const TextStyle(color: Colors.white),
                                                          ),
                                                          onTap: () {
                                                            //print("$tag selected");
                                                          },
                                                        ),
                                                        const SizedBox(width: 4.0),
                                                        InkWell(
                                                          child: const Icon(
                                                            Icons.cancel,
                                                            size: 14.0,
                                                            color: Color.fromARGB(255, 233, 233, 233),
                                                          ),
                                                          onTap: () {
                                                            inputFieldValues.onTagRemoved(tag);
                                                          },
                                                        )
                                                      ],
                                                    ),
                                                  );
                                                }).toList()),
                                          ),
                                        )
                                      : null,
                                ),
                                onChanged: inputFieldValues.onTagChanged,
                                onSubmitted: inputFieldValues.onTagSubmitted,
                              ),
                            );
                          },
                        ),
                        const SizedBox(height: 5.0),
                        Text(
                          '5 tags maximum.',
                          style: kTextStyle.copyWith(color: kLightNeutralColor),
                        ),
                        const SizedBox(height: 20.0),
                        Row(
                          children: [
                            Text(
                              'Frequently Asked Question',
                              style: kTextStyle.copyWith(color: kNeutralColor, fontWeight: FontWeight.bold),
                            ),
                            const Spacer(),
                            GestureDetector(
                              onTap: () {
                                showAddFAQPopUp();
                              },
                              child: Text(
                                'Add FAQ',
                                style: kTextStyle.copyWith(color: kLightNeutralColor),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 10.0),
                        Theme(
                          data: Theme.of(context).copyWith(dividerColor: Colors.transparent),
                          child: ExpansionTile(
                            tilePadding: EdgeInsets.zero,
                            childrenPadding: EdgeInsets.zero,
                            iconColor: kLightNeutralColor,
                            collapsedIconColor: kLightNeutralColor,
                            title: Text(
                              'What software is used to create the design?',
                              style: kTextStyle.copyWith(color: kSubTitleColor, fontSize: 14.0),
                            ),
                            children: [
                              Text(
                                'I can use Figma , Adobe XD or Framer , whatever app your comfortable working with',
                                style: kTextStyle.copyWith(color: kLightNeutralColor),
                              )
                            ],
                          ),
                        ),
                        const Divider(thickness: 1.0, color: kBorderColorTextField),
                        Theme(
                          data: Theme.of(context).copyWith(dividerColor: Colors.transparent),
                          child: ExpansionTile(
                            tilePadding: EdgeInsets.zero,
                            childrenPadding: EdgeInsets.zero,
                            iconColor: kLightNeutralColor,
                            collapsedIconColor: kLightNeutralColor,
                            title: Text(
                              'What software is used to create the design?',
                              style: kTextStyle.copyWith(color: kSubTitleColor, fontSize: 14.0),
                            ),
                            children: [
                              Text(
                                'I can use Figma , Adobe XD or Framer , whatever app your comfortable working with',
                                style: kTextStyle.copyWith(color: kLightNeutralColor),
                              )
                            ],
                          ),
                        ),
                        const Divider(thickness: 1.0, color: kBorderColorTextField)
                      ],
                    ).visible(currentIndexPage == 0),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const SizedBox(height: 20.0),
                        Text(
                          'Pricing Package',
                          style: kTextStyle.copyWith(color: kNeutralColor, fontWeight: FontWeight.bold),
                        ),
                        const SizedBox(height: 15.0),
                        Container(
                          decoration: BoxDecoration(borderRadius: BorderRadius.circular(16.0), border: Border.all(color: kBorderColorTextField)),
                          padding: const EdgeInsets.all(10.0),
                          child: Theme(
                            data: Theme.of(context).copyWith(dividerColor: Colors.transparent),
                            child: ExpansionTile(
                              initiallyExpanded: true,
                              tilePadding: EdgeInsets.zero,
                              childrenPadding: EdgeInsets.zero,
                              iconColor: kLightNeutralColor,
                              collapsedIconColor: kLightNeutralColor,
                              title: Text(
                                'Basic Package',
                                style: kTextStyle.copyWith(color: kNeutralColor, fontWeight: FontWeight.bold),
                              ),
                              children: [
                                ListTile(
                                  visualDensity: const VisualDensity(vertical: -4),
                                  contentPadding: EdgeInsets.zero,
                                  title: Text(
                                    'Price',
                                    style: kTextStyle.copyWith(color: kSubTitleColor),
                                  ),
                                  trailing: Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      Text(
                                        '5.00',
                                        style: kTextStyle.copyWith(color: kSubTitleColor),
                                      ),
                                      const SizedBox(
                                        width: 30,
                                      ),
                                      Text(
                                        currencySign,
                                        style: kTextStyle.copyWith(color: kNeutralColor, fontWeight: FontWeight.bold),
                                      ),
                                    ],
                                  ),
                                ),
                                const Divider(
                                  height: 0.0,
                                  thickness: 1.0,
                                  color: kBorderColorTextField,
                                ),
                                ListTile(
                                  visualDensity: const VisualDensity(vertical: -4),
                                  contentPadding: EdgeInsets.zero,
                                  title: Text(
                                    'Delivery Time',
                                    style: kTextStyle.copyWith(color: kSubTitleColor),
                                  ),
                                  trailing: DropdownButtonHideUnderline(child: getDeliveryTime()),
                                ),
                                const Divider(
                                  height: 0.0,
                                  thickness: 1.0,
                                  color: kBorderColorTextField,
                                ),
                                ListTile(
                                  visualDensity: const VisualDensity(vertical: -4),
                                  contentPadding: EdgeInsets.zero,
                                  title: Text(
                                    'Page/Screen',
                                    style: kTextStyle.copyWith(color: kSubTitleColor),
                                  ),
                                  trailing: DropdownButtonHideUnderline(child: getTotalScreen()),
                                ),
                                const Divider(
                                  height: 0.0,
                                  thickness: 1.0,
                                  color: kBorderColorTextField,
                                ),
                                ListView.builder(
                                  shrinkWrap: true,
                                  itemCount: list.length,
                                  physics: const NeverScrollableScrollPhysics(),
                                  itemBuilder: (BuildContext context, int index) {
                                    // return item
                                    return Column(
                                      children: [
                                        titleList(
                                          list[index].title,
                                          list[index].isSelected,
                                          index,
                                        ),
                                        const Divider(
                                          height: 0.0,
                                          thickness: 1.0,
                                          color: kBorderColorTextField,
                                        )
                                      ],
                                    );
                                  },
                                )
                              ],
                            ),
                          ),
                        ),
                        const SizedBox(height: 15.0),
                        Container(
                          decoration: BoxDecoration(borderRadius: BorderRadius.circular(16.0), border: Border.all(color: kBorderColorTextField)),
                          padding: const EdgeInsets.all(10.0),
                          child: Theme(
                            data: Theme.of(context).copyWith(dividerColor: Colors.transparent),
                            child: ExpansionTile(
                              initiallyExpanded: false,
                              tilePadding: EdgeInsets.zero,
                              childrenPadding: EdgeInsets.zero,
                              iconColor: kLightNeutralColor,
                              collapsedIconColor: kLightNeutralColor,
                              title: Text(
                                'Standard Package',
                                style: kTextStyle.copyWith(color: kNeutralColor, fontWeight: FontWeight.bold),
                              ),
                              children: [
                                ListTile(
                                  visualDensity: const VisualDensity(vertical: -4),
                                  contentPadding: EdgeInsets.zero,
                                  title: Text(
                                    'Price',
                                    style: kTextStyle.copyWith(color: kSubTitleColor),
                                  ),
                                  trailing: Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      Text(
                                        '30.00',
                                        style: kTextStyle.copyWith(color: kSubTitleColor),
                                      ),
                                      const SizedBox(
                                        width: 30,
                                      ),
                                      Text(
                                        currencySign,
                                        style: kTextStyle.copyWith(color: kNeutralColor, fontWeight: FontWeight.bold),
                                      ),
                                    ],
                                  ),
                                ),
                                const Divider(
                                  height: 0.0,
                                  thickness: 1.0,
                                  color: kBorderColorTextField,
                                ),
                                ListTile(
                                  visualDensity: const VisualDensity(vertical: -4),
                                  contentPadding: EdgeInsets.zero,
                                  title: Text(
                                    'Delivery Time',
                                    style: kTextStyle.copyWith(color: kSubTitleColor),
                                  ),
                                  trailing: DropdownButtonHideUnderline(child: getDeliveryTime()),
                                ),
                                const Divider(
                                  height: 0.0,
                                  thickness: 1.0,
                                  color: kBorderColorTextField,
                                ),
                                ListTile(
                                  visualDensity: const VisualDensity(vertical: -4),
                                  contentPadding: EdgeInsets.zero,
                                  title: Text(
                                    'Page/Screen',
                                    style: kTextStyle.copyWith(color: kSubTitleColor),
                                  ),
                                  trailing: DropdownButtonHideUnderline(child: getTotalScreen()),
                                ),
                                const Divider(
                                  height: 0.0,
                                  thickness: 1.0,
                                  color: kBorderColorTextField,
                                ),
                                ListView.builder(
                                  shrinkWrap: true,
                                  itemCount: list.length,
                                  physics: const NeverScrollableScrollPhysics(),
                                  itemBuilder: (BuildContext context, int index) {
                                    // return item
                                    return Column(
                                      children: [
                                        titleList(
                                          list[index].title,
                                          list[index].isSelected,
                                          index,
                                        ),
                                        const Divider(
                                          height: 0.0,
                                          thickness: 1.0,
                                          color: kBorderColorTextField,
                                        )
                                      ],
                                    );
                                  },
                                )
                              ],
                            ),
                          ),
                        ),
                        const SizedBox(height: 15.0),
                        Container(
                          decoration: BoxDecoration(borderRadius: BorderRadius.circular(16.0), border: Border.all(color: kBorderColorTextField)),
                          padding: const EdgeInsets.all(10.0),
                          child: Theme(
                            data: Theme.of(context).copyWith(dividerColor: Colors.transparent),
                            child: ExpansionTile(
                              initiallyExpanded: false,
                              tilePadding: EdgeInsets.zero,
                              childrenPadding: EdgeInsets.zero,
                              iconColor: kLightNeutralColor,
                              collapsedIconColor: kLightNeutralColor,
                              title: Text(
                                'Premium Package',
                                style: kTextStyle.copyWith(color: kNeutralColor, fontWeight: FontWeight.bold),
                              ),
                              children: [
                                ListTile(
                                  visualDensity: const VisualDensity(vertical: -4),
                                  contentPadding: EdgeInsets.zero,
                                  title: Text(
                                    'Price',
                                    style: kTextStyle.copyWith(color: kSubTitleColor),
                                  ),
                                  trailing: Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      Text(
                                        '60.00',
                                        style: kTextStyle.copyWith(color: kSubTitleColor),
                                      ),
                                      const SizedBox(
                                        width: 30,
                                      ),
                                      Text(
                                        currencySign,
                                        style: kTextStyle.copyWith(color: kNeutralColor, fontWeight: FontWeight.bold),
                                      ),
                                    ],
                                  ),
                                ),
                                const Divider(
                                  height: 0.0,
                                  thickness: 1.0,
                                  color: kBorderColorTextField,
                                ),
                                ListTile(
                                  visualDensity: const VisualDensity(vertical: -4),
                                  contentPadding: EdgeInsets.zero,
                                  title: Text(
                                    'Delivery Time',
                                    style: kTextStyle.copyWith(color: kSubTitleColor),
                                  ),
                                  trailing: DropdownButtonHideUnderline(child: getDeliveryTime()),
                                ),
                                const Divider(
                                  height: 0.0,
                                  thickness: 1.0,
                                  color: kBorderColorTextField,
                                ),
                                ListTile(
                                  visualDensity: const VisualDensity(vertical: -4),
                                  contentPadding: EdgeInsets.zero,
                                  title: Text(
                                    'Page/Screen',
                                    style: kTextStyle.copyWith(color: kSubTitleColor),
                                  ),
                                  trailing: DropdownButtonHideUnderline(child: getTotalScreen()),
                                ),
                                const Divider(
                                  height: 0.0,
                                  thickness: 1.0,
                                  color: kBorderColorTextField,
                                ),
                                ListView.builder(
                                  shrinkWrap: true,
                                  itemCount: list.length,
                                  physics: const NeverScrollableScrollPhysics(),
                                  itemBuilder: (BuildContext context, int index) {
                                    // return item
                                    return Column(
                                      children: [
                                        titleList(
                                          list[index].title,
                                          list[index].isSelected,
                                          index,
                                        ),
                                        const Divider(
                                          height: 0.0,
                                          thickness: 1.0,
                                          color: kBorderColorTextField,
                                        )
                                      ],
                                    );
                                  },
                                )
                              ],
                            ),
                          ),
                        ),
                      ],
                    ).visible(currentIndexPage == 1),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const SizedBox(height: 20.0),
                        Text(
                          'Image (Up to 3)',
                          style: kTextStyle.copyWith(color: kNeutralColor, fontWeight: FontWeight.bold),
                        ),
                        const SizedBox(height: 15.0),
                        ListView.builder(
                            padding: EdgeInsets.zero,
                            shrinkWrap: true,
                            itemCount: 3,
                            physics: const NeverScrollableScrollPhysics(),
                            itemBuilder: (_, i) {
                              return Padding(
                                padding: const EdgeInsets.only(bottom: 10.0),
                                child: Container(
                                  width: context.width(),
                                  decoration: BoxDecoration(
                                    borderRadius: BorderRadius.circular(10.0),
                                    border: Border.all(color: kBorderColorTextField),
                                  ),
                                  padding: const EdgeInsets.all(30.0),
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.center,
                                    children: [
                                      const Icon(
                                        IconlyBold.image,
                                        color: kLightNeutralColor,
                                        size: 50,
                                      ),
                                      const SizedBox(height: 10.0),
                                      Text(
                                        'Upload Image',
                                        style: kTextStyle.copyWith(color: kSubTitleColor),
                                      ),
                                    ],
                                  ),
                                ),
                              );
                            })
                      ],
                    ).visible(currentIndexPage == 2),
                  ],
                ),
              ),
            ),
          );
        },
      ),
      bottomNavigationBar: ButtonGlobalWithoutIcon(
          buttontext: 'Next',
          buttonDecoration: kButtonDecoration.copyWith(
            color: kPrimaryColor,
            borderRadius: BorderRadius.circular(30.0),
          ),
          onPressed: () {
            currentIndexPage < 2;
            currentIndexPage < 2 ? pageController.nextPage(duration: const Duration(microseconds: 3000), curve: Curves.bounceInOut) : const CreateService().launch(context);
          },
          buttonTextColor: kWhite),
    );
  }

  Widget titleList(String name, bool isSelected, int index) {
    return ListTile(
      contentPadding: EdgeInsets.zero,
      title: Text(name, style: kTextStyle.copyWith(color: kSubTitleColor)),
      trailing: isSelected
          ? const Icon(
              Icons.radio_button_checked_outlined,
              color: kPrimaryColor,
            )
          : const Icon(
              Icons.radio_button_off_outlined,
              color: Colors.grey,
            ),
      onTap: () {
        setState(() {
          list[index].isSelected = !list[index].isSelected;
        });
      },
    );
  }
}
