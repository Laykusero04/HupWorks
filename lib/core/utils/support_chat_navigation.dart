import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:freelancer/core/constants/support_contact.dart';
import 'package:freelancer/l10n/l10n.dart';
import 'package:freelancer/screen/widgets/support_chat_screen.dart';
import 'package:nb_utils/nb_utils.dart';
import 'package:url_launcher/url_launcher.dart';

Future<void> openSupportChat(BuildContext context) async {
  await const SupportChatScreen().launch(context);
}

/// Opens the device mail app to [SupportContact.email], or copies the address
/// if no mail client is available.
Future<void> openSupportEmail(BuildContext context) async {
  final l10n = context.l10n;
  final uri = SupportContact.mailtoUri;
  try {
    final launched = await launchUrl(uri, mode: LaunchMode.externalApplication);
    if (launched) return;
  } catch (_) {
    // Fall through to clipboard.
  }

  await Clipboard.setData(const ClipboardData(text: SupportContact.email));
  if (!context.mounted) return;
  ScaffoldMessenger.of(context).showSnackBar(
    SnackBar(content: Text(l10n.supportEmailOpenFailed)),
  );
}
