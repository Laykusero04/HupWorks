import 'package:flutter/material.dart';

/// Single source of truth for profile avatars across seller / client / talent UIs.
class ProfileImage {
  ProfileImage._();

  /// Shared placeholder when [profile_image_url] is missing.
  /// (Avoid mixing profile1 / profile3 / dev1 — that looked like “3 photos”.)
  static const fallbackAsset = 'images/profile3.png';

  /// Treat null / blank / whitespace as “no photo”.
  static String? normalize(String? url) {
    if (url == null) return null;
    final trimmed = url.trim();
    return trimmed.isEmpty ? null : trimmed;
  }

  /// Network image when URL is valid; otherwise the shared asset fallback.
  static ImageProvider provider(String? url, {String? fallback}) {
    final normalized = normalize(url);
    if (normalized != null) {
      return NetworkImage(normalized);
    }
    return AssetImage(fallback ?? fallbackAsset);
  }

  /// Appends/replaces a cache-buster so upserted avatars refresh in [ImageCache].
  static String withCacheBuster(String url) {
    final base = url.split('?').first;
    return '$base?v=${DateTime.now().millisecondsSinceEpoch}';
  }
}
