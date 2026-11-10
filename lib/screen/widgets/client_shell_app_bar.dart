import 'package:flutter/material.dart';
import 'package:freelancer/core/notifications/notification_scope.dart';
import 'package:freelancer/l10n/l10n.dart';
import 'package:freelancer/router/route_names.dart';
import 'package:go_router/go_router.dart';
import 'package:showcaseview/showcaseview.dart';

import '../../core/constants/colors.dart';
import '../../router/app_router.dart';
import 'constant.dart';
import 'shell_tab_header.dart';

/// Plain app bar for bottom-nav tabs: green for client, blue for freelancer/seller.
class ClientShellAppBar extends StatelessWidget implements PreferredSizeWidget {
  const ClientShellAppBar({
    super.key,
    required this.title,
    this.persona = ShellPersona.client,
    this.actions,
    this.menuShowcaseKey,
    this.menuShowcaseScope,
    this.menuShowcaseTitle,
    this.menuShowcaseDescription,
    this.bellShowcaseKey,
    this.bellShowcaseTitle,
    this.bellShowcaseDescription,
  });

  final String title;
  final ShellPersona persona;
  final List<Widget>? actions;

  /// Guide target for the menu button. Tabs stay mounted, so a GlobalKey here
  /// would be duplicated: ONLY the Home screens pass these (guide host scope).
  final GlobalKey? menuShowcaseKey;
  final String? menuShowcaseScope;
  final String? menuShowcaseTitle;
  final String? menuShowcaseDescription;

  /// Guide target for the notifications bell (same rule as the menu: only the
  /// Home screens pass a key; uses [menuShowcaseScope]).
  final GlobalKey? bellShowcaseKey;
  final String? bellShowcaseTitle;
  final String? bellShowcaseDescription;

  Color get _backgroundColor =>
      persona == ShellPersona.client ? kPrimaryColor : kSellerPrimary;

  void _openDrawer() {
    if (persona == ShellPersona.client) {
      clientShellScaffoldKey.currentState?.openDrawer();
    } else {
      sellerShellScaffoldKey.currentState?.openDrawer();
    }
  }

  Widget _leading() {
    final button = IconButton(
      icon: const Icon(Icons.menu),
      tooltip: 'Menu',
      onPressed: _openDrawer,
    );
    final key = menuShowcaseKey;
    if (key == null) return button;
    return Showcase(
      key: key,
      scope: menuShowcaseScope,
      title: menuShowcaseTitle,
      description: menuShowcaseDescription,
      child: button,
    );
  }

  Widget _bell() {
    final bell = _UnreadNotificationsButton(persona: persona);
    final key = bellShowcaseKey;
    if (key == null) return bell;
    return Showcase(
      key: key,
      scope: menuShowcaseScope,
      title: bellShowcaseTitle,
      description: bellShowcaseDescription,
      child: bell,
    );
  }

  @override
  Size get preferredSize => const Size.fromHeight(kToolbarHeight);

  @override
  Widget build(BuildContext context) {
    return AppBar(
      backgroundColor: _backgroundColor,
      surfaceTintColor: Colors.transparent,
      elevation: 0,
      scrolledUnderElevation: 0,
      foregroundColor: kWhite,
      iconTheme: const IconThemeData(color: kWhite),
      actionsIconTheme: const IconThemeData(color: kWhite),
      centerTitle: false,
      leading: _leading(),
      title: Text(
        title,
        style: kTextStyle.copyWith(
          color: kWhite,
          fontWeight: FontWeight.w600,
          fontSize: 18,
        ),
      ),
      actions: [
        ...?actions,
        _bell(),
      ],
    );
  }
}

class _UnreadNotificationsButton extends StatelessWidget {
  const _UnreadNotificationsButton({required this.persona});

  final ShellPersona persona;

  @override
  Widget build(BuildContext context) {
    final notifications = NotificationScope.of(context);
    final route = persona == ShellPersona.seller
        ? AppRoutes.sellerNotifications
        : AppRoutes.clientNotifications;
    return ListenableBuilder(
      listenable: notifications,
      builder: (context, _) {
        final count = notifications.unreadCount;
        return IconButton(
          tooltip: context.l10n.notifications,
          onPressed: () async {
            await context.push(route);
            if (context.mounted) {
              await notifications.refreshUnreadCount();
            }
          },
          icon: count > 0
              ? Badge(
                  label: Text(
                    count > 9 ? '9+' : '$count',
                    style: const TextStyle(fontSize: 10),
                  ),
                  child: const Icon(Icons.notifications_outlined),
                )
              : const Icon(Icons.notifications_outlined),
        );
      },
    );
  }
}
