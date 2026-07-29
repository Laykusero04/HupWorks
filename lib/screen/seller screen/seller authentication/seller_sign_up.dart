import 'package:flutter/material.dart';
import 'package:freelancer/screen/widgets/auth/sign_up_screen.dart';
import 'package:freelancer/screen/widgets/constant.dart';

import '../../app_config/app_config.dart';
import 'verification.dart';

// Thin wrapper — delegates to SignUpScreen with seller-specific parameters.
class SellerSignUp extends StatelessWidget {
  const SellerSignUp({super.key});

  @override
  Widget build(BuildContext context) => SignUpScreen(
        role: 'seller',
        accentColor: kSecondaryColor,
        heroImage: AppInfo.onBoard3,
        subtitle: (l10n) => l10n.authJoinAsFreelancer,
        roleLabel: (l10n) => l10n.authRoleFreelancer,
        otpScreenBuilder: (email) => OtpVerification(email: email),
      );
}
