import 'package:flutter/material.dart';
import 'package:freelancer/screen/widgets/settings_screen.dart';

import 'language.dart';
import 'privacy_policy.dart';
import 'seller_about.dart';

// Thin wrapper — delegates to SettingsScreen with seller-specific child pages.
class SellerSetting extends StatelessWidget {
  const SellerSetting({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) => const SettingsScreen(
        languagePage: Language(),
        policyPage: Policy(),
        aboutPage: SellerAbout(),
      );
}
