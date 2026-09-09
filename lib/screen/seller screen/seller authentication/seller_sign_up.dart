import 'package:flutter/material.dart';
import 'package:freelancer/screen/widgets/auth/sign_up_screen.dart';
import 'package:freelancer/screen/widgets/constant.dart';

import '../../app_config/app_config.dart';
import 'verification.dart';

/// Freelancer signup → confirm email, then log in → setup profile.
class SellerSignUp extends StatelessWidget {
  const SellerSignUp({super.key});

  @override
  Widget build(BuildContext context) => SignUpScreen(
        role: 'seller',
        accentColor: kSecondaryColor,
        heroImage: AppInfo.onBoard3,
        subtitle: (l10n) => l10n.authJoinAsFreelancer,
        roleLabel: (l10n) => l10n.authRoleFreelancer,
        onSignedUp: (context, email) async {
          if (!context.mounted) return;
          await Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => OtpVerification(email: email),
            ),
          );
        },
      );
}
