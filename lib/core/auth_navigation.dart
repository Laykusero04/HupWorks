import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../services/auth_service.dart';

/// Clears imperative [Navigator] pushes and navigates to the role home via GoRouter.
///
/// Required because auth screens are often opened with [Navigator.push] while
/// [GoRouter] also redirects on session change — mixing both causes framework
/// lifecycle assertions on seller/client shells.
class AuthNavigation {
  AuthNavigation._();

  static Future<void> goToHomeAfterAuth(BuildContext context) async {
    if (!context.mounted) return;

    final role = await AuthService.getUserRole();
    if (!context.mounted) return;

    final path = role == 'seller' ? '/seller' : '/client';

    final navigator = Navigator.of(context, rootNavigator: true);
    while (navigator.canPop()) {
      navigator.pop();
    }

    if (!context.mounted) return;
    GoRouter.of(context).go(path);
  }
}
