import 'package:flutter/material.dart';

// ── Brand palette (60 / 20 / 20) ─────────────────────────────────────────────
// 60% Dark grey — surfaces, text, borders (dominant neutral base)
// 20% Orange   — primary actions, client shell, main CTAs
// 20% Cyan     — secondary accent, seller shell, links & highlights

// Orange — primary (20%)
const kPrimaryColor = Color(0xFFF97316);

/// Accessible orange (WCAG AA): 5.18:1 with white text / on white. Use for
/// filled buttons with white text and orange text/links. Keep [kPrimaryColor]
/// (2.8:1) for decoration only (gradients, icons on tint, large shapes).
const kPrimaryDark = Color(0xFFC2410C);

/// Light orange tint + dark orange text (6.38:1) for selected chips/segments.
const kPrimaryTint = Color(0xFFFFEDD5);
const kPrimaryOnTint = Color(0xFF9A3412);

// ── One-orange rule (T-0152) ─────────────────────────────────────────────────
/// Fill that carries text (buttons, FAB, selected chip, message bar, tooltip
/// Next). Always pair with WHITE text (5.18:1). Never dark text on orange.
const kPrimaryFill = kPrimaryDark;

/// Orange used AS text / link on white or light grey (5.18:1 on white).
/// On orange tints (#FFEDD5, #FFF7F0) use [kPrimaryOnTint] (6.38:1).
const kPrimaryText = kPrimaryDark;

/// Bright brand orange for NON-text decoration only: header gradient, icons
/// 24dp+, badges without text, selected-tab tint, tour spotlight. 2.8:1.
const kPrimaryDecor = kPrimaryColor;

const kAccentColor = Color(0xFFFB923C);

// Cyan — secondary (20%)
const kSecondaryColor = Color(0xFF06B6D4);

// ── Seller cyan AA rule (T-0156) ─────────────────────────────────────────────
// Same idea as the one-orange rule. Bright cyan (#06B6D4 / #0891B2) is only
// 2.4:1 / 3.7:1 with white, so it is DECORATION ONLY (gradients, icons 24dp+,
// borders, tints). Anything that carries text uses the tokens below.
/// Seller fill that carries WHITE text (buttons, selected chip, tour Next).
/// #0E7490: 5.36:1 with white.
const kSecondaryFill = Color(0xFF0E7490);

/// Seller cyan used AS text / active icon on white or light grey (5.36:1).
/// On cyan tints use [kSecondaryOnTint].
const kSecondaryText = Color(0xFF0E7490);

/// Dark teal for text on cyan tints (#E0F7FA-ish): #155E75, 7.1:1 on white.
const kSecondaryOnTint = Color(0xFF155E75);

// Dark grey — neutral base (60%)
const kNeutralColor = Color(0xFF2D3436);
const kSubTitleColor = Color(0xFF636E72);
const kLightNeutralColor = Color(0xFF95A5A6);
const kDarkWhite = Color(0xFFF4F4F5);
const kWhite = Color(0xFFFFFFFF);
const kBorderColorTextField = Color(0xFFD1D5DB);
const ratingBarColor = Color(0xFFFBBF24);

// Seller shell — cyan brand
const kSellerPrimary = Color(0xFF0891B2);
const kSellerPrimaryDeep = Color(0xFF0E7490);
const kSellerAccent = Color(0xFF22D3EE);
const kSellerSurface = Color(0xFFF4F4F5);

// Gradients
const kClientShellGradient = [
  Color(0xFFEA580C),
  Color(0xFFF97316),
  Color(0xFFFB923C),
];

const kSellerShellGradient = [
  kSellerPrimaryDeep,
  kSellerPrimary,
  kSellerAccent,
];

/// Outgoing chat bubbles — orange
const kChatBubbleGradient = [
  Color(0xFFEA580C),
  Color(0xFFF97316),
];

/// Incoming chat bubbles — cyan
const kChatReceivedBubbleGradient = [
  kSellerPrimaryDeep,
  kSellerPrimary,
];

List<Color> colorList = [
  kPrimaryColor,
  kSecondaryColor,
  kNeutralColor,
];
