import 'package:flutter/material.dart';

import '../constants/colors.dart';

ThemeData appTheme() {
  return ThemeData(
    fontFamily: 'Display',
    primaryColor: kPrimaryColor,
    scaffoldBackgroundColor: kWhite,
    colorScheme: ColorScheme.light(
      primary: kPrimaryColor,
      secondary: kSecondaryColor,
      tertiary: kAccentColor,
      surface: kWhite,
      surfaceContainerHighest: kDarkWhite,
      onPrimary: kWhite,
      onSecondary: kWhite,
      onSurface: kNeutralColor,
    ),
    appBarTheme: const AppBarTheme(
      backgroundColor: kWhite,
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
        backgroundColor: kPrimaryColor,
        foregroundColor: kWhite,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(30.0),
        ),
      ),
    ),
    textButtonTheme: TextButtonThemeData(
      style: TextButton.styleFrom(
        foregroundColor: kSecondaryColor,
      ),
    ),
    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: Colors.white70,
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
