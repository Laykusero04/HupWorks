import 'package:freelancer/data/models/notification_model.dart';
import 'package:freelancer/l10n/app_localizations.dart';

/// Localized body for [n].
///
/// Message notifications are written by the database trigger
/// (migrations/0024_message_notifications.sql) in English only, and the row
/// carries no structured job title. So for `type == 'message'` we recognise
/// that trigger's exact templates and re-render them in the app language.
/// Anything that does not match is returned unchanged (stored body).
String? localizedNotificationBody(AppLocalizations l10n, AppNotification n) {
  final body = n.body;
  if (body == null || n.type != 'message') return body;

  const attachmentPreview = 'Sent an attachment';
  String preview(String p) =>
      p == attachmentPreview ? l10n.notificationSentAttachment : p;

  if (body == 'You have a new message.') return l10n.notificationNewMessage;

  final about = RegExp(
    r'^You have a new message about "(.+?)"\.(?: "(.*)")?$',
    dotAll: true,
  ).firstMatch(body);
  if (about != null) {
    final text = l10n.notificationNewMessageAbout(about.group(1)!);
    final p = about.group(2);
    return (p == null || p.isEmpty) ? text : '$text "${preview(p)}"';
  }

  // Preview-only body (no job context).
  if (body == attachmentPreview) return l10n.notificationSentAttachment;
  return body;
}
