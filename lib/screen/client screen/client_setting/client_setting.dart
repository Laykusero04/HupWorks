import 'package:flutter/material.dart';
import 'package:freelancer/screen/widgets/settings_screen.dart';

import 'client_about.dart';
import 'client_language.dart';
import 'client_policy.dart';

// Thin wrapper — delegates to SettingsScreen with client-specific child pages.
class ClientSetting extends StatelessWidget {
  const ClientSetting({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) => const SettingsScreen(
        languagePage: ClientLanguage(),
        policyPage: ClientPolicy(),
        aboutPage: ClientAbout(),
      );
}
