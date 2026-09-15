import 'package:flutter/material.dart';

import '../constants/colors.dart';

/// Maps [categories.icon] from Supabase to Material icons / photo assets.
abstract final class CategoryIcons {
  /// Photo tiles shipped under `images/categories/<icon>.png`.
  static const photoIcons = <String>{
    'logistics',
    'gardening',
    'sailing',
  };

  static String? assetPath(String? icon) {
    final key = icon?.trim().toLowerCase();
    if (key == null || key.isEmpty || !photoIcons.contains(key)) return null;
    return 'images/categories/$key.png';
  }

  static bool hasPhoto(String? icon) => assetPath(icon) != null;

  static IconData iconData(String? icon) {
    return switch (icon) {
      'cleaning' => Icons.cleaning_services_outlined,
      'factory' => Icons.factory_outlined,
      'trades' => Icons.handyman_outlined,
      'beauty' => Icons.content_cut_outlined,
      'food' => Icons.restaurant_outlined,
      'retail' => Icons.storefront_outlined,
      'delivery' => Icons.local_shipping_outlined,
      'labor' => Icons.engineering_outlined,
      'logistics' => Icons.inventory_2_outlined,
      'gardening' => Icons.yard_outlined,
      'sailing' => Icons.sailing_outlined,
      'custom' => Icons.label_outline,
      'hospitality' => Icons.room_service_outlined,
      // legacy icons (old seed data)
      'design' => Icons.palette_outlined,
      'video' => Icons.videocam_outlined,
      'marketing' => Icons.campaign_outlined,
      'business' => Icons.business_center_outlined,
      'writing' => Icons.edit_note_outlined,
      'code' => Icons.code_outlined,
      'lifestyle' => Icons.spa_outlined,
      _ => Icons.work_outline,
    };
  }

  static Color tintColor(int index) {
    const colors = [
      kPrimaryColor,
      kSecondaryColor,
      kNeutralColor,
      kAccentColor,
      kSellerAccent,
      kSubTitleColor,
      kSellerPrimary,
      kLightNeutralColor,
    ];
    return colors[index % colors.length];
  }
}

/// Rounded category visual: photo when available, otherwise tinted Material icon.
class CategoryVisual extends StatelessWidget {
  const CategoryVisual({
    super.key,
    required this.iconKey,
    required this.tint,
    required this.iconColor,
    this.size = 48,
    this.radius = 14,
    this.iconSize,
  });

  final String? iconKey;
  final Color tint;
  final Color iconColor;
  final double size;
  final double radius;
  final double? iconSize;

  @override
  Widget build(BuildContext context) {
    final asset = CategoryIcons.assetPath(iconKey);
    return SizedBox(
      width: size,
      height: size,
      child: DecoratedBox(
        decoration: BoxDecoration(
          color: asset == null ? tint : null,
          borderRadius: BorderRadius.circular(radius),
          border: Border.all(color: iconColor.withValues(alpha: 0.15)),
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(radius - 0.5),
          child: asset != null
              ? Image.asset(
                  asset,
                  fit: BoxFit.cover,
                  errorBuilder: (_, __, ___) => _fallbackIcon(),
                )
              : _fallbackIcon(),
        ),
      ),
    );
  }

  Widget _fallbackIcon() {
    return ColoredBox(
      color: tint,
      child: Icon(
        CategoryIcons.iconData(iconKey),
        size: iconSize ?? size * 0.5,
        color: iconColor,
      ),
    );
  }
}
