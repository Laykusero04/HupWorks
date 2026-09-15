import 'package:flutter/material.dart';

/// Favicon / Rubik-tile palette for the painted attendance QR.
///
/// Sourced from `images/rubik_tiles` + splash cube accents. Module colors are
/// darkened enough to stay scannable on a light background.
class BrandQrPalette {
  BrandQrPalette._();

  /// Soft paper wash behind the code.
  static const background = Color(0xFFFFFBF2);

  /// Decorative wash blobs (low opacity).
  static const washGreen = Color(0xFF22B26D);
  static const washPink = Color(0xFFF37B9E);
  static const washYellow = Color(0xFFFAD125);
  static const washCyan = Color(0xFF47BFFF);
  static const washOrange = Color(0xFFF97316);

  /// Dark outline like favicon tile strokes.
  static const outline = Color(0xFF1A2B24);

  /// Finder-eye frame (favicon green).
  static const eyeOuter = Color(0xFF0E7A4A);

  /// Finder-eye pupil (favicon pink).
  static const eyeInner = Color(0xFFC2185B);

  /// Data-module mosaic — scannable darks of favicon hues.
  static const modules = <Color>[
    Color(0xFF0E7A4A), // green
    Color(0xFFC2185B), // pink
    Color(0xFF0E7490), // cyan / teal
    Color(0xFFC2410C), // orange
    Color(0xFF1D4ED8), // blue
    Color(0xFFA16207), // amber (from yellow)
    Color(0xFF15803D), // lime green
    Color(0xFF9D174D), // magenta
  ];

  static Color moduleAt(int x, int y) {
    // Diagonal “brush stroke” banding so neighboring modules feel painted.
    final band = ((x + y * 2) ~/ 3 + (x * 5 + y * 3)) % modules.length;
    return modules[band];
  }
}
