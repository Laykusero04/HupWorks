import 'package:flutter/material.dart';
import 'package:freelancer/l10n/l10n.dart';
import 'package:freelancer/screen/app_config/app_config.dart';
import 'package:url_launcher/url_launcher.dart';

/// Opens [uri]; returns whether it could be opened.
typedef TermsLauncher = Future<bool> Function(Uri uri);

Future<bool> defaultTermsLauncher(Uri uri) =>
    launchUrl(uri, mode: LaunchMode.externalApplication);

/// Opens the Terms of Service page ([AppInfo.termsUrl]) in the browser.
/// Shows a snackbar if it cannot be opened.
Future<void> openTermsOfService(
  BuildContext context, {
  TermsLauncher launcher = defaultTermsLauncher,
}) async {
  final messenger = ScaffoldMessenger.of(context);
  final message = context.l10n.authTermsOpenFailed;
  var opened = false;
  try {
    opened = await launcher(Uri.parse(AppInfo.termsUrl));
  } catch (_) {
    opened = false;
  }
  if (opened) return;
  messenger.showSnackBar(SnackBar(content: Text(message)));
}
