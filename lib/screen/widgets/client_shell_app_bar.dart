import 'package:flutter/material.dart';

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
  });

  final String title;
  final ShellPersona persona;
  final List<Widget>? actions;

  Color get _backgroundColor =>
      persona == ShellPersona.client ? kPrimaryColor : kSellerPrimary;

  void _openDrawer() {
    if (persona == ShellPersona.client) {
      clientShellScaffoldKey.currentState?.openDrawer();
    } else {
      sellerShellScaffoldKey.currentState?.openDrawer();
    }
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
      leading: IconButton(
        icon: const Icon(Icons.menu),
        tooltip: 'Menu',
        onPressed: _openDrawer,
      ),
      title: Text(
        title,
        style: kTextStyle.copyWith(
          color: kWhite,
          fontWeight: FontWeight.w600,
          fontSize: 18,
        ),
      ),
      actions: actions,
    );
  }
}
