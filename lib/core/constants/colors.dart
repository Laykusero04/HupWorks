import 'package:flutter/material.dart';

// ── Brand palette (60 / 20 / 20) ─────────────────────────────────────────────
// 60% Dark grey — surfaces, text, borders (dominant neutral base)
// 20% Orange   — primary actions, client shell, main CTAs
// 20% Cyan     — secondary accent, seller shell, links & highlights

// Orange — primary (20%)
const kPrimaryColor = Color(0xFFF97316);
const kAccentColor = Color(0xFFFB923C);

// Cyan — secondary (20%)
const kSecondaryColor = Color(0xFF06B6D4);

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

/// Outgoing chat bubbles & small orange accents
const kChatBubbleGradient = [
  Color(0xFFEA580C),
  Color(0xFFF97316),
];

List<Color> colorList = [
  kPrimaryColor,
  kSecondaryColor,
  kNeutralColor,
];
