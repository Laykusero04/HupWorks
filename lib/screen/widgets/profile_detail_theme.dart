import 'package:flutter/material.dart';

import 'constant.dart';

/// Shared visuals for client & seller “My profile” detail screens (HupWorks theme).
abstract final class ProfileDetailTheme {
  static const Color scaffoldBg = kDarkWhite;

  static BoxDecoration avatarDecoration(ImageProvider image) => BoxDecoration(
        shape: BoxShape.circle,
        border: Border.all(color: kPrimaryColor.withValues(alpha: 0.4), width: 2.5),
        image: DecorationImage(image: image, fit: BoxFit.cover),
      );

  static BoxDecoration statsPanel() => BoxDecoration(
        color: kPrimaryColor.withValues(alpha: 0.07),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: kPrimaryColor.withValues(alpha: 0.14)),
      );

  /// Thin brand gradient bar between sections.
  static Widget sectionDivider() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 48, vertical: 4),
      child: Container(
        height: 3,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(2),
          gradient: LinearGradient(
            colors: [
              kPrimaryColor.withValues(alpha: 0.85),
              kSecondaryColor.withValues(alpha: 0.85),
            ],
          ),
        ),
      ),
    );
  }

  static ButtonStyle editProfileOutlinedStyle() {
    return OutlinedButton.styleFrom(
      foregroundColor: kPrimaryColor,
      side: BorderSide(color: kPrimaryColor.withValues(alpha: 0.45), width: 1.5),
      padding: const EdgeInsets.symmetric(vertical: 14),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
    );
  }

  static BoxDecoration cardOnPage() => BoxDecoration(
        color: kWhite,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: kPrimaryColor.withValues(alpha: 0.1)),
        boxShadow: [
          BoxShadow(
            color: kPrimaryColor.withValues(alpha: 0.06),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      );
}
