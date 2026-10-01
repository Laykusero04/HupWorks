import 'package:freelancer/l10n/app_localizations.dart';

/// Who may start a **new** conversation with this user.
/// Existing threads are always allowed; soft block/report is a separate hard stop.
class MessageContactPreference {
  MessageContactPreference._();

  static const everyone = 'everyone';
  static const hiredOnly = 'hired_only';
  static const nobody = 'nobody';

  static const values = [everyone, hiredOnly, nobody];

  static String parse(dynamic raw) {
    final v = (raw as String?)?.trim().toLowerCase();
    if (v == hiredOnly || v == nobody) return v!;
    return everyone;
  }

  static String label(AppLocalizations l10n, String value) {
    switch (parse(value)) {
      case hiredOnly:
        return l10n.messagingPreferenceHiredOnly;
      case nobody:
        return l10n.messagingPreferenceNobody;
      default:
        return l10n.messagingPreferenceEveryone;
    }
  }

  static String description(AppLocalizations l10n, String value) {
    switch (parse(value)) {
      case hiredOnly:
        return l10n.messagingPreferenceHiredOnlyDesc;
      case nobody:
        return l10n.messagingPreferenceNobodyDesc;
      default:
        return l10n.messagingPreferenceEveryoneDesc;
    }
  }

  /// Maps ChatService / DB errors to a short user-facing string.
  static String openChatErrorMessage(AppLocalizations l10n, Object error) {
    final s = '$error';
    if (s.contains('Contact blocked')) return l10n.contactBlocked;
    if (s.contains('MESSAGING_PREFERENCE_DENIED:nobody') ||
        s.contains('Messaging preference denied: nobody')) {
      return l10n.messagingPreferenceNobodyDenied;
    }
    if (s.contains('MESSAGING_PREFERENCE_DENIED:hired_only') ||
        s.contains('Messaging preference denied: hired_only')) {
      return l10n.messagingPreferenceHiredOnlyDenied;
    }
    return l10n.couldNotOpenChatWithDetail(s);
  }
}
