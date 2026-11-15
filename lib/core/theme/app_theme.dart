import 'package:flutter/material.dart';

import '../constants/colors.dart';

ThemeData appTheme() {
  return ThemeData(
    fontFamily: 'Display',
    primaryColor: kPrimaryColor,
    scaffoldBackgroundColor: kDarkWhite,
    colorScheme: ColorScheme.light(
      primary: kPrimaryDark,
      secondary: kSecondaryColor,
      tertiary: kAccentColor,
      surface: kWhite,
      surfaceContainerHighest: kDarkWhite,
      onPrimary: kWhite,
      onSecondary: kWhite,
      onSurface: kNeutralColor,
    ),
    appBarTheme: const AppBarTheme(
      backgroundColor: kDarkWhite,
      elevation: 0,
      iconTheme: IconThemeData(color: kNeutralColor),
      titleTextStyle: TextStyle(
        color: kNeutralColor,
        fontSize: 18,
        fontWeight: FontWeight.bold,
        fontFamily: 'Display',
      ),
    ),
    elevatedButtonTheme: ElevatedButtonThemeData(
      style: ElevatedButton.styleFrom(
        backgroundColor: kPrimaryDark,
        foregroundColor: kWhite,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(30.0),
        ),
      ),
    ),
    textButtonTheme: TextButtonThemeData(
      style: TextButton.styleFrom(
        foregroundColor: kPrimaryDark,
      ),
    ),
    segmentedButtonTheme: SegmentedButtonThemeData(
      style: ButtonStyle(
        minimumSize: const WidgetStatePropertyAll(Size(48, 48)),
        backgroundColor: WidgetStateProperty.resolveWith(
          (s) {
            if (s.contains(WidgetState.disabled)) {
              return s.contains(WidgetState.selected)
                  ? kNeutralColor.withValues(alpha: 0.12)
                  : kWhite;
            }
            return s.contains(WidgetState.selected) ? kPrimaryTint : kWhite;
          },
        ),
        foregroundColor: WidgetStateProperty.resolveWith(
          (s) {
            if (s.contains(WidgetState.disabled)) {
              return kNeutralColor.withValues(alpha: 0.38);
            }
            return s.contains(WidgetState.selected)
                ? kPrimaryOnTint
                : kNeutralColor;
          },
        ),
      ),
    ),
    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: kWhite,
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(8.0),
        borderSide: const BorderSide(color: kBorderColorTextField, width: 2),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(6.0),
        borderSide: const BorderSide(color: kPrimaryColor, width: 2),
      ),
      hintStyle: const TextStyle(color: kSubTitleColor),
    ),
  );
}
