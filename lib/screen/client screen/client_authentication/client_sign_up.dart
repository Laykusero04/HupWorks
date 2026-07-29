import 'package:flutter/material.dart';
import 'package:freelancer/screen/widgets/auth/sign_up_screen.dart';
import 'package:freelancer/screen/widgets/constant.dart';

import '../../app_config/app_config.dart';
import 'client_otp_verification.dart';

// Thin wrapper — delegates to SignUpScreen with client-specific parameters.
class ClientSignUp extends StatelessWidget {
  const ClientSignUp({super.key});

  @override
  Widget build(BuildContext context) => SignUpScreen(
        role: 'client',
        accentColor: kPrimaryColor,
        heroImage: AppInfo.onBoard2,
        subtitle: (l10n) => l10n.authJoinAsClient,
        roleLabel: (l10n) => l10n.authRoleClient,
        otpScreenBuilder: (email) => ClientOtpVerification(email: email),
      );
}
