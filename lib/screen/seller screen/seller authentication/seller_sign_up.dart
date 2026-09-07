import 'package:flutter/material.dart';
import 'package:freelancer/router/route_names.dart';
import 'package:freelancer/screen/widgets/auth/sign_up_screen.dart';
import 'package:freelancer/screen/widgets/constant.dart';
import 'package:go_router/go_router.dart';

import '../../app_config/app_config.dart';

/// Freelancer signup → account onboarding (setup profile).
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
          // Use GoRouter so redirect does not yank away from an imperative stack.
          if (!context.mounted) return;
          context.go(AppRoutes.sellerSetupProfile);
        },
      );
}
