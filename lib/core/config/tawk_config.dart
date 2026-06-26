import 'package:flutter_dotenv/flutter_dotenv.dart';

/// Tawk.to live support configuration loaded from [.env].
class TawkConfig {
  TawkConfig._();

  static const _directChatLinkKey = 'TAWK_DIRECT_CHAT_LINK';

  static String? get directChatLink {
    final value = dotenv.env[_directChatLinkKey]?.trim();
    if (value == null || value.isEmpty) return null;
    return value;
  }

  static bool get isConfigured => directChatLink != null;
}
