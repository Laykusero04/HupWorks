import 'package:flutter_dotenv/flutter_dotenv.dart';

/// Tawk.to live support configuration loaded from [.env].
///
/// Widget UI language is configured **per widget** in the Tawk dashboard
/// (Administration → Chat Widget → Widget Content → Language). To match the
/// app locale, create one widget per language and set the matching direct link
/// below (e.g. Nederlands widget → [TAWK_DIRECT_CHAT_LINK_NL]).
class TawkConfig {
  TawkConfig._();

  static const _directChatLinkKey = 'TAWK_DIRECT_CHAT_LINK';
  static const _directChatLinkNlKey = 'TAWK_DIRECT_CHAT_LINK_NL';
  static const _directChatLinkBnKey = 'TAWK_DIRECT_CHAT_LINK_BN';

  /// Default / English widget direct link.
  static String? get directChatLink {
    final value = dotenv.env[_directChatLinkKey]?.trim();
    if (value == null || value.isEmpty) return null;
    return value;
  }

  /// Resolves the direct chat link for [languageCode] (`en`, `nl`, `bn`).
  /// Falls back to [directChatLink] when no locale-specific link is set.
  static String? directChatLinkFor(String languageCode) {
    final code = languageCode.toLowerCase();
    final envKey = switch (code) {
      'nl' => _directChatLinkNlKey,
      'bn' => _directChatLinkBnKey,
      _ => _directChatLinkKey,
    };

    if (envKey != _directChatLinkKey) {
      final localized = dotenv.env[envKey]?.trim();
      if (localized != null && localized.isNotEmpty) return localized;
    }

    return directChatLink;
  }

  static bool get isConfigured {
    for (final key in [
      _directChatLinkKey,
      _directChatLinkNlKey,
      _directChatLinkBnKey,
    ]) {
      final value = dotenv.env[key]?.trim();
      if (value != null && value.isNotEmpty) return true;
    }
    return false;
  }

  static bool isConfiguredFor(String languageCode) =>
      directChatLinkFor(languageCode) != null;
}
