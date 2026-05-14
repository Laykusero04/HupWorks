import 'package:flutter/material.dart';
import 'package:flutter_feather_icons/flutter_feather_icons.dart';

import 'constant.dart';

/// Accent for the circular icon badge (matches app brand: primary green, secondary blue, accent orange).
enum ProfileMenuAccent {
  primary,
  secondary,
  accent,
}

extension ProfileMenuAccentColor on ProfileMenuAccent {
  Color get color => switch (this) {
        ProfileMenuAccent.secondary => kSecondaryColor,
        ProfileMenuAccent.accent => kAccentColor,
        ProfileMenuAccent.primary => kPrimaryColor,
      };
}

/// Themed list row for client/seller profile menus (green-tint surface, brand icon chip).
class ProfileMenuListTile extends StatelessWidget {
  const ProfileMenuListTile({
    super.key,
    required this.icon,
    required this.title,
    required this.onTap,
    this.accent = ProfileMenuAccent.primary,
  });

  final IconData icon;
  final String title;
  final VoidCallback onTap;
  final ProfileMenuAccent accent;

  @override
  Widget build(BuildContext context) {
    final c = accent.color;
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(14),
          onTap: onTap,
          child: Ink(
            decoration: BoxDecoration(
              color: kDarkWhite,
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: c.withValues(alpha: 0.18)),
            ),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: c.withValues(alpha: 0.14),
                    ),
                    child: Icon(icon, color: c, size: 22),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Text(
                      title,
                      overflow: TextOverflow.ellipsis,
                      maxLines: 1,
                      style: kTextStyle.copyWith(
                        color: kNeutralColor,
                        fontWeight: FontWeight.w600,
                        fontSize: 15,
                      ),
                    ),
                  ),
                  Icon(FeatherIcons.chevronRight, color: kLightNeutralColor, size: 20),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
