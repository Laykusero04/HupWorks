import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_iconly/flutter_iconly.dart';
import 'package:freelancer/core/locale/locale_controller.dart';
import 'package:freelancer/core/locale/locale_scope.dart';
import 'package:freelancer/core/utils/support_chat_navigation.dart';
import 'package:freelancer/l10n/l10n.dart';
import 'package:nb_utils/nb_utils.dart';

import 'constant.dart';

class SettingsScreen extends StatefulWidget {
  final Widget languagePage;
  final Widget policyPage;
  final Widget aboutPage;

  const SettingsScreen({
    Key? key,
    required this.languagePage,
    required this.policyPage,
    required this.aboutPage,
  }) : super(key: key);

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  bool isOn = false;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final localeController = LocaleScope.of(context);
    final currentLanguage =
        LocaleController.displayName(l10n, localeController.locale.languageCode);

    return Scaffold(
      backgroundColor: kDarkWhite,
      appBar: AppBar(
        backgroundColor: kDarkWhite,
        elevation: 0,
        iconTheme: const IconThemeData(color: kNeutralColor),
        title: Text(
          l10n.settings,
          style: kTextStyle.copyWith(color: kNeutralColor, fontWeight: FontWeight.bold),
        ),
        centerTitle: true,
      ),
      body: Padding(
        padding: const EdgeInsets.only(top: 20),
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
          child: Column(
            children: [
              const SizedBox(height: 30.0),
              ListTile(
                visualDensity: const VisualDensity(vertical: -3),
                horizontalTitleGap: 10,
                contentPadding: const EdgeInsets.only(bottom: 15),
                leading: Container(
                  padding: const EdgeInsets.all(10.0),
                  decoration: const BoxDecoration(
                    shape: BoxShape.circle,
                    color: Color(0xFFE7FFED),
                  ),
                  child: const Icon(
                    IconlyBold.notification,
                    color: kPrimaryColor,
                  ),
                ),
                title: Text(
                  l10n.pushNotifications,
                  overflow: TextOverflow.ellipsis,
                  maxLines: 1,
                  style: kTextStyle.copyWith(color: kNeutralColor),
                ),
                trailing: CupertinoSwitch(
                  value: isOn,
                  onChanged: (value) {
                    setState(() {
                      isOn = value;
                    });
                  },
                ),
              ),
              ListTile(
                onTap: () => widget.languagePage.launch(context),
                visualDensity: const VisualDensity(vertical: -3),
                horizontalTitleGap: 10,
                contentPadding: const EdgeInsets.only(bottom: 15),
                leading: Container(
                  padding: const EdgeInsets.all(10.0),
                  decoration: const BoxDecoration(
                    shape: BoxShape.circle,
                    color: Color(0xFFE3EDFF),
                  ),
                  child: const Icon(
                    Icons.translate,
                    color: kSecondaryColor,
                  ),
                ),
                title: Text(
                  l10n.language,
                  overflow: TextOverflow.ellipsis,
                  maxLines: 1,
                  style: kTextStyle.copyWith(color: kNeutralColor),
                ),
                trailing: Text(
                  currentLanguage,
                  overflow: TextOverflow.ellipsis,
                  maxLines: 1,
                  style: kTextStyle.copyWith(color: kSubTitleColor),
                ),
              ),
              ListTile(
                onTap: () => widget.policyPage.launch(context),
                visualDensity: const VisualDensity(vertical: -3),
                horizontalTitleGap: 10,
                contentPadding: const EdgeInsets.only(bottom: 15),
                leading: Container(
                  padding: const EdgeInsets.all(10.0),
                  decoration: const BoxDecoration(
                    shape: BoxShape.circle,
                    color: Color(0xFFFFEFE0),
                  ),
                  child: const Icon(
                    IconlyBold.danger,
                    color: Color(0xFFFF7A00),
                  ),
                ),
                title: Text(
                  l10n.privacyPolicy,
                  overflow: TextOverflow.ellipsis,
                  maxLines: 1,
                  style: kTextStyle.copyWith(color: kNeutralColor),
                ),
              ),
              ListTile(
                onTap: () => widget.aboutPage.launch(context),
                visualDensity: const VisualDensity(vertical: -3),
                horizontalTitleGap: 10,
                contentPadding: const EdgeInsets.only(bottom: 15),
                leading: Container(
                  padding: const EdgeInsets.all(10.0),
                  decoration: const BoxDecoration(
                    shape: BoxShape.circle,
                    color: Color(0xFFE8E1FF),
                  ),
                  child: const Icon(
                    IconlyBold.shieldDone,
                    color: Color(0xFF7E5BFF),
                  ),
                ),
                title: Text(
                  l10n.aboutUs,
                  overflow: TextOverflow.ellipsis,
                  maxLines: 1,
                  style: kTextStyle.copyWith(color: kNeutralColor),
                ),
              ),
              ListTile(
                onTap: () => openSupportChat(context),
                visualDensity: const VisualDensity(vertical: -3),
                horizontalTitleGap: 10,
                contentPadding: const EdgeInsets.only(bottom: 15),
                leading: Container(
                  padding: const EdgeInsets.all(10.0),
                  decoration: const BoxDecoration(
                    shape: BoxShape.circle,
                    color: Color(0xFFE7F5FF),
                  ),
                  child: const Icon(
                    Icons.support_agent_outlined,
                    color: Color(0xFF0B7DD6),
                  ),
                ),
                title: Text(
                  l10n.helpSupport,
                  overflow: TextOverflow.ellipsis,
                  maxLines: 1,
                  style: kTextStyle.copyWith(color: kNeutralColor),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
