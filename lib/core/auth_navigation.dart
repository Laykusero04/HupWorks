import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../router/app_router.dart';
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

    // Capture router before any await — dialog contexts unmount after pop.
    final router = GoRouter.of(context);

    final role = await AuthService.getUserRole(forceRefresh: true);
    final path = AuthService.homePathForRole(role);

    final nav = rootNavigatorKey.currentState;
    if (nav != null) {
      while (nav.canPop()) {
        nav.pop();
      }
    }

    router.go(path);
  }
}
