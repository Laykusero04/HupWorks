import 'package:freelancer/l10n/app_localizations.dart';

/// Who is allowed to start a new chat with a profile.
abstract final class ChatContactPolicy {
  static const anyone = 'anyone';
  static const verified = 'verified';
  static const connections = 'connections';
  static const nobody = 'nobody';

  static const values = <String>[anyone, verified, connections, nobody];

  static String normalize(String? raw) {
    final value = raw?.trim().toLowerCase();
    if (values.contains(value)) return value!;
    return anyone;
  }

  static String label(AppLocalizations l10n, String policy) {
    switch (normalize(policy)) {
      case verified:
        return l10n.chatPrivacyVerified;
      case connections:
        return l10n.chatPrivacyConnections;
      case nobody:
        return l10n.chatPrivacyNobody;
      default:
        return l10n.chatPrivacyAnyone;
    }
  }

  static String hint(AppLocalizations l10n, String policy) {
    switch (normalize(policy)) {
      case verified:
        return l10n.chatPrivacyVerifiedHint;
      case connections:
        return l10n.chatPrivacyConnectionsHint;
      case nobody:
        return l10n.chatPrivacyNobodyHint;
      default:
        return l10n.chatPrivacyAnyoneHint;
    }
  }
}

/// Thrown when the other profile's messaging filter refuses a new chat.
class ChatPrivacyException implements Exception {
  ChatPrivacyException(this.reason);

  final String reason;

  @override
  String toString() => 'Chat privacy: $reason';
}

/// Snackbar copy for a failed attempt to open or start a chat.
String messageForChatStartFailure(AppLocalizations l10n, Object error) {
  final text = '$error';
  if (text.contains('Contact blocked')) return l10n.contactBlocked;
  if (text.contains('Chat privacy: nobody')) return l10n.chatPrivacyDeniedNobody;
  if (text.contains('Chat privacy: verified')) {
    return l10n.chatPrivacyDeniedVerified;
  }
  if (text.contains('Chat privacy: connections')) {
    return l10n.chatPrivacyDeniedConnections;
  }
  if (text.contains('Chat privacy:')) return l10n.chatPrivacyDeniedNobody;
  return l10n.couldNotOpenChatWithDetail(text);
}
