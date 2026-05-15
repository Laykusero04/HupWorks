import 'package:flutter/material.dart';

import 'constant.dart';

/// Shared visuals for client & seller “My profile” detail screens.
///
/// Pass [accent] for seller flows so panels and headings follow the shell blue
/// primary; omit [accent] to keep the default client green ([kPrimaryColor]).
abstract final class ProfileDetailTheme {
  static const Color scaffoldBg = kDarkWhite;

  static BoxDecoration avatarDecoration(
    ImageProvider image, {
    Color? accent,
  }) {
    final c = accent ?? kPrimaryColor;
    return BoxDecoration(
      shape: BoxShape.circle,
      border: Border.all(color: c.withValues(alpha: 0.4), width: 2.5),
      image: DecorationImage(image: image, fit: BoxFit.cover),
    );
  }

  static BoxDecoration statsPanel({Color? accent}) {
    final c = accent ?? kPrimaryColor;
    return BoxDecoration(
      color: c.withValues(alpha: 0.07),
      borderRadius: BorderRadius.circular(16),
      border: Border.all(color: c.withValues(alpha: 0.14)),
    );
  }

  /// Thin brand gradient bar between sections.
  static Widget sectionDivider({Color? gradientStart, Color? gradientEnd}) {
    final a = gradientStart ?? kPrimaryColor;
    final b = gradientEnd ?? kSecondaryColor;
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 48, vertical: 4),
      child: Container(
        height: 3,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(2),
          gradient: LinearGradient(
            colors: [
              a.withValues(alpha: 0.85),
              b.withValues(alpha: 0.85),
            ],
          ),
        ),
      ),
    );
  }

  static ButtonStyle editProfileOutlinedStyle({Color? accent}) {
    final c = accent ?? kPrimaryColor;
    return OutlinedButton.styleFrom(
      foregroundColor: c,
      side: BorderSide(color: c.withValues(alpha: 0.45), width: 1.5),
      padding: const EdgeInsets.symmetric(vertical: 14),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
    );
  }

  static BoxDecoration cardOnPage({Color? accent}) {
    final c = accent ?? kPrimaryColor;
    return BoxDecoration(
      color: kWhite,
      borderRadius: BorderRadius.circular(14),
      border: Border.all(color: c.withValues(alpha: 0.1)),
      boxShadow: [
        BoxShadow(
          color: c.withValues(alpha: 0.06),
          blurRadius: 10,
          offset: const Offset(0, 2),
        ),
      ],
    );
  }
}
