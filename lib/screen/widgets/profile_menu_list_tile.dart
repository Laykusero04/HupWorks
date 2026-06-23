import 'package:flutter/material.dart';

import 'constant.dart';

/// Plain drawer / profile menu row.
class ProfileMenuListTile extends StatelessWidget {
  const ProfileMenuListTile({
    super.key,
    required this.icon,
    required this.title,
    required this.onTap,
  });

  final IconData icon;
  final String title;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return ListTile(
      dense: true,
      contentPadding: const EdgeInsets.symmetric(horizontal: 8),
      leading: Icon(icon, color: kNeutralColor, size: 22),
      title: Text(
        title,
        style: kTextStyle.copyWith(color: kNeutralColor, fontSize: 15),
      ),
      trailing: const Icon(Icons.chevron_right, color: kLightNeutralColor, size: 20),
      onTap: onTap,
    );
  }
}
