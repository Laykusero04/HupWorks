import 'package:flutter/material.dart';

import '../constants/colors.dart';

/// Central switches for per-screen guides.
class GuideConfig {
  GuideConfig._();

  /// Kill switch. Set to false to disable every guide in the app
  /// (nothing starts, nothing is marked seen).
  static const bool enabled = true;

  /// true = taps on the dimmed area outside the target do nothing, so a stray
  /// tap can never skip required steps. The bottom tab bar stays usable via
  /// per-tab hit zones the runner draws over it (see `GuideNavBridge`): a tab
  /// tap ends the tour like Skip (marked seen) and switches tab in one tap.
  static const bool disableBarrierInteraction = true;

  // ── Tooltip look (T-0150 F6) ───────────────────────────────────────────
  // Pass these to every `Showcase(...)`: the package default has 8dp vertical
  // padding only (text flush to the card edge), centred-looking titles and
  // unbounded text scaling.

  /// 16dp on all sides so title/body never touch the card edge.
  static const EdgeInsets tooltipPadding = EdgeInsets.all(16);

  /// Title and body start-aligned (package default is centre).
  static const AlignmentGeometry tooltipTextAlignment =
      AlignmentDirectional.centerStart;

  /// Text scale the tooltip text is capped at (the overlay applies the system
  /// scale on top of the font size, so the font size is divided by the excess).
  static const double tooltipMaxTextScale = 1.3;

  static TextScaler _systemScaler() {
    final views = WidgetsBinding.instance.platformDispatcher.views;
    if (views.isEmpty) return TextScaler.noScaling;
    return MediaQueryData.fromView(views.first).textScaler;
  }

  /// Font size to give a tooltip [TextStyle] so the text RENDERS at the system
  /// scale capped at [tooltipMaxTextScale] and never below [size]. The overlay
  /// applies its own (captured) text scaler on top of the font size, so the
  /// size is solved against that scaler instead of being divided by a single
  /// factor (which also works for non-linear scalers). [ambientCap] is the
  /// text scale cap of the widget the Showcase sits in (e.g. 1.25 in the nav).
  @visibleForTesting
  static double fitSize(double size, {TextScaler? scaler, double? ambientCap}) {
    var sc = scaler ?? _systemScaler();
    if (ambientCap != null) sc = sc.clamp(maxScaleFactor: ambientCap);
    final max = size * tooltipMaxTextScale;
    final rendered = sc.scale(size);
    if (rendered <= max) return size;
    // Solve sc.scale(f) == max for f (monotonic): bisection.
    var lo = size * 0.2, hi = size;
    for (var i = 0; i < 24; i++) {
      final mid = (lo + hi) / 2;
      if (sc.scale(mid) > max) {
        hi = mid;
      } else {
        lo = mid;
      }
    }
    return lo;
  }

  /// Left-aligned 18pt bold title.
  static TextStyle titleStyle({double? ambientCap}) => TextStyle(
        color: kNeutralColor,
        fontSize: fitSize(18, ambientCap: ambientCap),
        fontWeight: FontWeight.w700,
        height: 1.25,
      );

  /// 15pt body in the subtitle grey (5.9:1 on white).
  static TextStyle descStyle({double? ambientCap}) => TextStyle(
        color: kSubTitleColor,
        fontSize: fitSize(15, ambientCap: ambientCap),
        height: 1.35,
      );
}
