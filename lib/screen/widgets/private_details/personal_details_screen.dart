import 'package:flutter/material.dart';
import 'package:freelancer/core/utils/dob_input.dart';
import 'package:freelancer/core/utils/terms_link.dart';
import 'package:freelancer/data/models/user_private_details.dart';
import 'package:freelancer/l10n/l10n.dart';
import 'package:freelancer/screen/app_config/app_config.dart';
import 'package:freelancer/screen/widgets/auth/auth_ui.dart';
import 'package:freelancer/screen/widgets/constant.dart';
import 'package:freelancer/screen/widgets/private_details/dob_field.dart';
import 'package:freelancer/screen/widgets/private_details/private_details_errors.dart';
import 'package:freelancer/screen/widgets/private_details/privacy_consent_row.dart';
import 'package:freelancer/services/personal_details_gate.dart';
import 'package:freelancer/services/user_private_details_service.dart';

typedef PrivateDetailsLoader = Future<UserPrivateDetails?> Function();
typedef PrivateDetailsSaver = Future<void> Function({
  DateTime? dateOfBirth,
  String? consentVersion,
});

/// Date of birth + versioned privacy consent (T-0172).
///
/// Two uses: the first-sign-in step ([fromTrust] false, skippable, no back
/// arrow) and the screen opened from the "Personal details" trust item
/// ([fromTrust] true, back arrow, no skip). Nothing is saved when the user is
/// under 16.
class PersonalDetailsScreen extends StatefulWidget {
  const PersonalDetailsScreen({
    super.key,
    required this.accent,
    required this.onDone,
    this.fromTrust = false,
    this.onSkip,
    this.onSignOut,
    this.loader = UserPrivateDetailsService.getMine,
    this.fallbackDobLoader,
    this.saver = _defaultSaver,
    this.launcher = defaultTermsLauncher,
    this.now,
  });

  /// Role colour: client orange or seller cyan (mapped to AA tokens inside).
  final Color accent;
  final bool fromTrust;

  /// Called after a successful save and after skip (navigation lives with the
  /// caller so the screen stays testable).
  final VoidCallback onDone;
  final Future<void> Function()? onSkip;
  final Future<void> Function()? onSignOut;
  final PrivateDetailsLoader loader;

  /// Old freelancer date of birth, used as a read-only prefill when the new row
  /// has none. Pressing Continue is the user's save of the shown date.
  final Future<DateTime?> Function()? fallbackDobLoader;
  final PrivateDetailsSaver saver;
  final TermsLauncher launcher;

  /// UTC "today" override for tests.
  final DateTime? now;

  static Future<void> _defaultSaver({
    DateTime? dateOfBirth,
    String? consentVersion,
  }) =>
      UserPrivateDetailsService.upsertMine(
        dateOfBirth: dateOfBirth,
        consentVersion: consentVersion,
      );

  @override
  State<PersonalDetailsScreen> createState() => _PersonalDetailsScreenState();
}

class _PersonalDetailsScreenState extends State<PersonalDetailsScreen> {
  final _dob = DobController();
  bool _consent = false;
  bool _loading = true;
  // The first read failed: never show an empty form that could overwrite a
  // stored date; offer a retry instead.
  bool _loadFailed = false;
  bool _saving = false;
  DobError? _dobError;
  bool _consentError = false;
  Object? _saveError;

  @override
  void initState() {
    super.initState();
    _load();
  }

  @override
  void dispose() {
    _dob.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _loadFailed = false;
    });
    var failed = false;
    try {
      final row = await widget.loader();
      if (row?.dateOfBirth != null) {
        _dob.setDate(row!.dateOfBirth!);
      } else if (widget.fallbackDobLoader != null) {
        // A failed fallback read just means no prefill.
        final old = await widget.fallbackDobLoader!().catchError((_) => null);
        if (old != null) _dob.setDate(old);
      }
    } catch (_) {
      failed = true;
    }
    if (mounted) {
      setState(() {
        _loading = false;
        _loadFailed = failed;
      });
    }
  }

  Future<void> _submit() async {
    final result = _dob.validate(now: widget.now);
    setState(() {
      _dobError = result.error;
      _consentError = !_consent;
      _saveError = null;
    });
    if (!result.isValid || !_consent) return;

    setState(() => _saving = true);
    try {
      await widget.saver(
        dateOfBirth: result.date,
        consentVersion: AppInfo.privacyConsentVersion,
      );
      PersonalDetailsGate.markSaved();
      if (!mounted) return;
      widget.onDone();
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _saving = false;
        if (e is PrivateDetailsValidationException &&
            e.field == PrivateDetailsField.dateOfBirth) {
          _dobError = DobError.under16;
        } else {
          _saveError = e;
        }
      });
    }
  }

  Future<void> _skip() async {
    await (widget.onSkip ?? PersonalDetailsGate.markSkipped)();
    if (mounted) widget.onDone();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final accent = widget.accent;
    final accentText = authAccentText(accent);

    return PopScope(
      // First sign-in: back must not drop the user into the shell unprompted.
      canPop: widget.fromTrust,
      child: Scaffold(
        backgroundColor: kWhite,
        appBar: AppBar(
          backgroundColor: kWhite,
          elevation: 0,
          scrolledUnderElevation: 0,
          automaticallyImplyLeading: widget.fromTrust,
          iconTheme: const IconThemeData(color: kNeutralColor),
          centerTitle: true,
          title: Image.asset(AppInfo.logo, height: 28),
        ),
        body: _loading
            ? Center(child: CircularProgressIndicator(color: accentText))
            : SafeArea(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.fromLTRB(20, 8, 20, 24),
                  child: Center(
                    child: ConstrainedBox(
                      constraints: const BoxConstraints(maxWidth: 480),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          Text(
                            l10n.pdTitle,
                            style: kTextStyle.copyWith(
                              fontSize: 22,
                              fontWeight: FontWeight.bold,
                              color: kNeutralColor,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            l10n.pdLead,
                            style: kTextStyle.copyWith(
                              fontSize: 14,
                              color: kSubTitleColor,
                              height: 1.4,
                            ),
                          ),
                          if (_saveError != null) ...[
                            const SizedBox(height: 16),
                            _ErrorBanner(
                              text:
                                  privateDetailsErrorMessage(l10n, _saveError!),
                            ),
                          ],
                          const SizedBox(height: 20),
                          if (_loadFailed)
                            _ErrorBanner(text: l10n.pdLoadError)
                          else ...[
                            DobField(
                              controller: _dob,
                              accent: accent,
                              enabled: !_saving,
                              errorText: _dobError == null
                                  ? null
                                  : dobErrorText(l10n, _dobError!),
                              onChanged: () {
                                if (_dobError != null) {
                                  setState(() => _dobError = null);
                                }
                              },
                            ),
                            if (_dobError == DobError.under16 &&
                                widget.onSignOut != null)
                              Align(
                                alignment: AlignmentDirectional.centerStart,
                                child: TextButton(
                                  onPressed: widget.onSignOut,
                                  style: TextButton.styleFrom(
                                    minimumSize: const Size(48, 48),
                                    foregroundColor: accentText,
                                  ),
                                  child: Text(l10n.logOut),
                                ),
                              ),
                            const SizedBox(height: 16),
                            PrivacyConsentRow(
                              checked: _consent,
                              accent: accent,
                              enabled: !_saving,
                              launcher: widget.launcher,
                              errorText:
                                  _consentError ? l10n.pdConsentRequired : null,
                              onChanged: (v) => setState(() {
                                _consent = v;
                                if (v) _consentError = false;
                              }),
                            ),
                          ],
                          if (!widget.fromTrust) ...[
                            const SizedBox(height: 12),
                            Text(
                              l10n.pdSkipHint,
                              style: kTextStyle.copyWith(
                                fontSize: 12,
                                color: kSubTitleColor,
                                height: 1.4,
                              ),
                            ),
                          ],
                        ],
                      ),
                    ),
                  ),
                ),
              ),
        bottomNavigationBar: _loading
            ? null
            : SafeArea(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Center(
                    heightFactor: 1,
                    child: ConstrainedBox(
                      constraints: const BoxConstraints(maxWidth: 480),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          _ActionButton(
                            label: _saving
                                ? l10n.saving
                                : (_saveError != null || _loadFailed)
                                    ? l10n.pdTryAgain
                                    : l10n.continueLabel,
                            busy: _saving,
                            filled: true,
                            accent: accent,
                            onPressed: _saving
                                ? null
                                : (_loadFailed ? _load : _submit),
                          ),
                          if (!widget.fromTrust) ...[
                            const SizedBox(height: 8),
                            _ActionButton(
                              label: l10n.skipForNow,
                              filled: false,
                              accent: accent,
                              onPressed: _saving ? null : _skip,
                            ),
                          ],
                        ],
                      ),
                    ),
                  ),
                ),
              ),
      ),
    );
  }
}

class _ActionButton extends StatelessWidget {
  const _ActionButton({
    required this.label,
    required this.filled,
    required this.accent,
    required this.onPressed,
    this.busy = false,
  });

  final String label;
  final bool filled;
  final bool busy;
  final Color accent;
  final VoidCallback? onPressed;

  @override
  Widget build(BuildContext context) {
    final fill = authAccentFill(accent);
    final text = authAccentText(accent);
    // Label scale capped at 1.3, wraps to two lines, never ellipsised.
    final child = MediaQuery.withClampedTextScaling(
      maxScaleFactor: 1.3,
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        mainAxisSize: MainAxisSize.min,
        children: [
          if (busy) ...[
            const SizedBox(
              height: 18,
              width: 18,
              child: CircularProgressIndicator(
                strokeWidth: 2,
                color: kWhite,
              ),
            ),
            const SizedBox(width: 10),
          ],
          Flexible(
            child: Text(
              label,
              maxLines: 2,
              textAlign: TextAlign.center,
              style: kTextStyle.copyWith(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: filled ? kWhite : text,
              ),
            ),
          ),
        ],
      ),
    );
    const shape = RoundedRectangleBorder(
      borderRadius: BorderRadius.all(Radius.circular(14)),
    );
    const size = Size.fromHeight(48);
    return filled
        ? FilledButton(
            onPressed: onPressed,
            style: FilledButton.styleFrom(
              minimumSize: size,
              backgroundColor: busy ? kSubTitleColor : fill,
              disabledBackgroundColor: kSubTitleColor,
              shape: shape,
            ),
            child: child,
          )
        : OutlinedButton(
            onPressed: onPressed,
            style: OutlinedButton.styleFrom(
              minimumSize: size,
              side: BorderSide(color: text, width: 1.5),
              shape: shape,
            ),
            child: child,
          );
  }
}

class _ErrorBanner extends StatelessWidget {
  const _ErrorBanner({required this.text});
  final String text;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      liveRegion: true,
      container: true,
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: const Color(0xFFFDECEA),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: kPdErrorColor),
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const ExcludeSemantics(
              child: Icon(Icons.error_outline, size: 20, color: kPdErrorColor),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                text,
                style: kTextStyle.copyWith(
                  color: kPdErrorColor,
                  fontSize: 13,
                  height: 1.4,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
