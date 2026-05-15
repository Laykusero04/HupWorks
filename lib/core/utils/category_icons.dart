import 'package:flutter/material.dart';

/// Maps [categories.icon] from Supabase to Material icons for the home grid.
abstract final class CategoryIcons {
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
      Color(0xFF16A34A),
      Color(0xFF2563EB),
      Color(0xFFF97316),
      Color(0xFF8B5CF6),
      Color(0xFFEF4444),
      Color(0xFF06B6D4),
      Color(0xFFEAB308),
      Color(0xFFEC4899),
    ];
    return colors[index % colors.length];
  }
}
