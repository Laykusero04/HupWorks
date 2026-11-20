import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:freelancer/core/utils/terms_link.dart';
import 'package:freelancer/l10n/l10n.dart';
import 'package:freelancer/screen/app_config/app_config.dart';
import 'package:freelancer/screen/widgets/auth/auth_ui.dart';
import 'package:freelancer/screen/widgets/constant.dart';
import 'package:freelancer/screen/widgets/private_details/dob_field.dart';

/// Opens the Privacy Policy page in the browser; snackbar when it fails.
Future<void> openPrivacyPolicy(
  BuildContext context, {
  TermsLauncher launcher = defaultTermsLauncher,
}) async {
  final messenger = ScaffoldMessenger.of(context);
  final message = context.l10n.pdLinkOpenFailed;
  var opened = false;
  try {
    opened = await launcher(Uri.parse(AppInfo.privacyUrl));
  } catch (_) {
    opened = false;
  }
  if (opened) return;
  messenger.showSnackBar(SnackBar(content: Text(message)));
}

/// Versioned privacy consent: checkbox + text with two links. Tapping the
/// text toggles the box, tapping a link opens the page without toggling.
class PrivacyConsentRow extends StatefulWidget {
  const PrivacyConsentRow({
    super.key,
    required this.checked,
    required this.onChanged,
    required this.accent,
    this.errorText,
    this.enabled = true,
    this.launcher = defaultTermsLauncher,
  });

  final bool checked;
  final ValueChanged<bool> onChanged;
  final Color accent;
  final String? errorText;
  final bool enabled;
  final TermsLauncher launcher;

  @override
  State<PrivacyConsentRow> createState() => _PrivacyConsentRowState();
}

class _PrivacyConsentRowState extends State<PrivacyConsentRow> {
  late final TapGestureRecognizer _privacyTap;
  late final TapGestureRecognizer _termsTap;

  @override
  void initState() {
    super.initState();
    _privacyTap = TapGestureRecognizer()
      ..onTap = () => openPrivacyPolicy(context, launcher: widget.launcher);
    _termsTap = TapGestureRecognizer()
      ..onTap = () => openTermsOfService(context, launcher: widget.launcher);
  }

  @override
  void dispose() {
    _privacyTap.dispose();
    _termsTap.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final linkColor = authAccentText(widget.accent);
    final base = kTextStyle.copyWith(
      color: kNeutralColor,
      fontSize: 13,
      height: 1.4,
    );
    final link = base.copyWith(
      color: linkColor,
      fontWeight: FontWeight.bold,
      decoration: TextDecoration.underline,
    );
    final hasError = widget.errorText != null;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Semantics(
          container: true,
          checked: widget.checked,
          child: InkWell(
            onTap:
                widget.enabled ? () => widget.onChanged(!widget.checked) : null,
            child: ConstrainedBox(
              constraints: const BoxConstraints(minHeight: 48),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  SizedBox(
                    height: 48,
                    width: 40,
                    child: Center(
                      child: SizedBox(
                        height: 24,
                        width: 24,
                        child: Checkbox(
                          value: widget.checked,
                          onChanged: widget.enabled
                              ? (v) => widget.onChanged(v ?? false)
                              : null,
                          activeColor: authAccentFill(widget.accent),
                          side: BorderSide(
                            color: hasError ? kPdErrorColor : kNeutralColor,
                            width: hasError ? 2 : 1.5,
                          ),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(4),
                          ),
                          materialTapTargetSize:
                              MaterialTapTargetSize.shrinkWrap,
                        ),
                      ),
                    ),
                  ),
                  Expanded(
                    child: Padding(
                      padding: const EdgeInsets.symmetric(vertical: 13),
                      child: Text.rich(
                        TextSpan(
                          style: base,
                          children: [
                            TextSpan(text: l10n.pdConsentIntro),
                            TextSpan(
                              text: l10n.pdConsentPrivacy,
                              style: link,
                              recognizer: _privacyTap,
                            ),
                            TextSpan(text: l10n.pdConsentAnd),
                            TextSpan(
                              text: l10n.pdConsentTerms,
                              style: link,
                              recognizer: _termsTap,
                            ),
                            TextSpan(text: l10n.pdConsentOutro),
                          ],
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
        Padding(
          padding: const EdgeInsets.only(left: 40),
          child: Text(
            l10n.pdConsentVersionCaption(AppInfo.privacyConsentVersion),
            key: const ValueKey('consent-version'),
            style: kTextStyle.copyWith(color: kSubTitleColor, fontSize: 12),
          ),
        ),
        if (hasError)
          Padding(
            padding: const EdgeInsets.only(left: 40),
            child: PrivateFieldError(text: widget.errorText!),
          ),
      ],
    );
  }
}
