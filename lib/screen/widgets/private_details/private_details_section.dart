import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
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
import 'package:intl/intl.dart';

typedef PrivateDetailsFullSaver = Future<void> Function({
  String? legalName,
  DateTime? dateOfBirth,
  String? streetAddress,
  String? postalCode,
  String? consentVersion,
  required Set<PrivateDetailsField> clear,
});

/// "Personal details (private)" block for both Edit profile screens (T-0172).
///
/// The parent's Save button calls [PrivateDetailsSectionState.save] (via a
/// GlobalKey) before saving the public profile; `false` means a validation or
/// server error is shown inline and the parent must stop. Values are never
/// logged or sent anywhere except the owner-only table.
class PrivateDetailsSection extends StatefulWidget {
  const PrivateDetailsSection({
    super.key,
    required this.accent,
    this.loader = UserPrivateDetailsService.getMine,
    this.saver = UserPrivateDetailsService.upsertMine,
    this.launcher = defaultTermsLauncher,
    this.now,
    this.fallbackDob,
    this.fallbackStreet,
    this.fallbackPostal,
    this.onDobChanged,
  });

  /// Old freelancer values (seller_private_details) used as read-only prefill
  /// when the new row has none. They are written only if the user edits them.
  final DateTime? fallbackDob;
  final String? fallbackStreet;
  final String? fallbackPostal;

  /// Called with the typed date of birth when it is a valid 16+ date, else
  /// null (after loading and on every change). Drives the "show age" switch.
  final ValueChanged<DateTime?>? onDobChanged;

  final Color accent;
  final Future<UserPrivateDetails?> Function() loader;
  final PrivateDetailsFullSaver saver;
  final TermsLauncher launcher;
  final DateTime? now;

  @override
  State<PrivateDetailsSection> createState() => PrivateDetailsSectionState();
}

class PrivateDetailsSectionState extends State<PrivateDetailsSection> {
  final _dob = DobController();
  final _name = TextEditingController();
  final _street = TextEditingController();
  final _postal = TextEditingController();

  UserPrivateDetails? _row;
  bool _loaded = false;
  bool _loading = true;
  bool _consent = false;

  DobError? _dobError;
  String? _nameError;
  String? _streetError;
  String? _postalError;
  bool _consentError = false;
  String? _serverError;

  bool get _hasCurrentConsent =>
      _row != null &&
      _row!.hasConsent &&
      _row!.consentVersion == AppInfo.privacyConsentVersion;

  @override
  void initState() {
    super.initState();
    _load();
  }

  @override
  void dispose() {
    _dob.dispose();
    _name.dispose();
    _street.dispose();
    _postal.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    try {
      _row = await widget.loader();
      _loaded = true;
      final r = _row;
      final dob = r?.dateOfBirth ?? widget.fallbackDob;
      if (dob != null) _dob.setDate(dob);
      _name.text = r?.legalName ?? '';
      _street.text = r?.streetAddress ?? widget.fallbackStreet ?? '';
      _postal.text = r?.postalCode ?? widget.fallbackPostal ?? '';
    } catch (_) {
      // Leave the section empty and do not save from it (could overwrite).
      _loaded = false;
    }
    if (mounted) {
      setState(() => _loading = false);
      if (_loaded) _reportDob();
    }
  }

  /// Checks the typed values and shows errors inline; writes nothing. Returns
  /// false when the parent must stop. The parent calls this BEFORE saving the
  /// public profile so a local validation error never leaves a half-saved page.
  bool validate() => _evaluate(show: true) != null;

  /// Validates, then stores the changes. Returns false when the parent must
  /// stop (the reason is shown inline). Safe to call twice.
  Future<bool> save() async {
    final plan = _evaluate(show: true);
    if (plan == null) return false;
    if (plan.nothing) return true;
    final l10n = context.l10n;
    final r = _row;
    try {
      await widget.saver(
        legalName: plan.setName,
        dateOfBirth: plan.setDob,
        streetAddress: plan.setStreet,
        postalCode: plan.setPostal,
        consentVersion: plan.consent ? AppInfo.privacyConsentVersion : null,
        clear: plan.clear,
      );
      if (plan.consent) PersonalDetailsGate.markSaved();
      final fresh = await widget.loader().catchError((_) => null);
      if (mounted) setState(() => _row = fresh ?? r);
      return true;
    } catch (e) {
      if (mounted) {
        setState(() {
          _serverError = privateDetailsErrorMessage(l10n, e);
          if (e is PrivateDetailsValidationException &&
              e.field == PrivateDetailsField.dateOfBirth) {
            _dobError = DobError.under16;
          }
        });
      }
      return false;
    }
  }

  /// Baselines: what is stored, or (read-only fallback) the old freelancer
  /// values shown as prefill. Unchanged prefill is never written.
  DateTime? get _baseDob => _row?.dateOfBirth ?? widget.fallbackDob;
  String get _baseName => _row?.legalName ?? '';
  String get _baseStreet => _row?.streetAddress ?? widget.fallbackStreet ?? '';
  String get _basePostal => _row?.postalCode ?? widget.fallbackPostal ?? '';

  _Plan? _evaluate({required bool show}) {
    // Never write over data we could not read.
    if (!_loaded) return const _Plan();
    final l10n = context.l10n;

    DobError? dobErr;
    DateTime? setDob;
    if (_dob.isEmpty) {
      if (_baseDob != null) dobErr = DobError.empty;
    } else {
      final res = _dob.validate(now: widget.now);
      final base = _baseDob;
      if (res.isValid) {
        if (base == null || !_sameDay(base, res.date!)) setDob = res.date;
      } else if (base != null && _typedEquals(base)) {
        // Unchanged stored/old value that no longer passes (for example an
        // under-16 date from before this check): do not block other saves.
      } else {
        dobErr = res.error;
      }
    }

    final name = _name.text.trim();
    final street = _street.text.trim();
    final postal = _postal.text.trim();
    String? nameErr, streetErr, postalErr;
    if (name.length > UserPrivateDetailsService.maxLegalNameLength) {
      nameErr = l10n.pdErrLegalName;
    }
    if (street.length > UserPrivateDetailsService.maxStreetLength) {
      streetErr = l10n.pdErrStreet;
    }
    final normalizedPostal = postal.isEmpty
        ? ''
        : UserPrivateDetailsService.normalizeNlPostalCode(postal);
    if (postal.isNotEmpty &&
        normalizedPostal != _basePostal &&
        !UserPrivateDetailsService.isValidNlPostalCode(postal)) {
      postalErr = l10n.pdErrPostal;
    }

    final clear = <PrivateDetailsField>{};
    String? setName, setStreet, setPostal;
    if (name != _baseName) {
      if (name.isEmpty) {
        clear.add(PrivateDetailsField.legalName);
      } else {
        setName = name;
      }
    }
    if (street != _baseStreet) {
      if (street.isEmpty) {
        clear.add(PrivateDetailsField.streetAddress);
      } else {
        setStreet = street;
      }
    }
    if (normalizedPostal != _basePostal) {
      if (postal.isEmpty) {
        clear.add(PrivateDetailsField.postalCode);
      } else {
        setPostal = postal;
      }
    }

    final changed = setDob != null ||
        setName != null ||
        setStreet != null ||
        setPostal != null ||
        clear.isNotEmpty;
    // Storing personal data needs consent to the current text first.
    final needsConsent = changed && !_hasCurrentConsent && !_consent;
    final recordConsent = !_hasCurrentConsent && _consent;

    final hasError = dobErr != null ||
        nameErr != null ||
        streetErr != null ||
        postalErr != null ||
        needsConsent;
    if (show) {
      setState(() {
        _dobError = dobErr;
        _nameError = nameErr;
        _streetError = streetErr;
        _postalError = postalErr;
        _consentError = needsConsent;
        _serverError = null;
      });
    }
    if (hasError) return null;
    return _Plan(
      setName: setName,
      setDob: setDob,
      setStreet: setStreet,
      setPostal: setPostal,
      clear: clear,
      consent: recordConsent,
      nothing: !changed && !recordConsent,
    );
  }

  bool _typedEquals(DateTime base) {
    return int.tryParse(_dob.day.text.trim()) == base.day &&
        int.tryParse(_dob.month.text.trim()) == base.month &&
        int.tryParse(_dob.year.text.trim()) == base.year;
  }

  void _reportDob() {
    final cb = widget.onDobChanged;
    if (cb == null) return;
    final res = _dob.validate(now: widget.now);
    cb(res.isValid ? res.date : null);
  }

  static bool _sameDay(DateTime a, DateTime b) =>
      a.year == b.year && a.month == b.month && a.day == b.day;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final accent = widget.accent;
    final tint = accent.withValues(alpha: 0.12);
    final onTint = authAccentOnTint(accent);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Padding(
              padding: EdgeInsets.only(top: 2),
              child: ExcludeSemantics(
                child: Icon(Icons.lock_outline, size: 20, color: kNeutralColor),
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: Semantics(
                header: true,
                child: Text(
                  l10n.pdSectionTitle,
                  style: kTextStyle.copyWith(
                    color: kNeutralColor,
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                  ),
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: tint,
            borderRadius: BorderRadius.circular(12),
          ),
          child: Text(
            l10n.pdSectionCallout,
            style: kTextStyle.copyWith(
              color: onTint,
              fontSize: 13,
              height: 1.4,
            ),
          ),
        ),
        const SizedBox(height: 16),
        if (_loading)
          Center(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: CircularProgressIndicator(
                  color: authAccentText(accent), strokeWidth: 2),
            ),
          )
        else ...[
          if (_loaded && _row == null && widget.fallbackDob == null) ...[
            Text(
              l10n.pdNotAddedYet,
              style: kTextStyle.copyWith(
                color: kSubTitleColor,
                fontSize: 13,
                fontStyle: FontStyle.italic,
                height: 1.4,
              ),
            ),
            const SizedBox(height: 12),
          ],
          if (_serverError != null) ...[
            PrivateFieldError(text: _serverError!),
            const SizedBox(height: 12),
          ],
          DobField(
            controller: _dob,
            accent: accent,
            errorText:
                _dobError == null ? null : dobErrorText(l10n, _dobError!),
            onChanged: () {
              if (_dobError != null) setState(() => _dobError = null);
              _reportDob();
            },
          ),
          const SizedBox(height: 16),
          _LabeledField(
            label: l10n.pdLegalName,
            helper: l10n.pdLegalNameHint,
            controller: _name,
            accent: accent,
            error: _nameError,
            keyboardType: TextInputType.name,
            capitalization: TextCapitalization.words,
            action: TextInputAction.next,
            onChanged: () => setState(() => _nameError = null),
          ),
          const SizedBox(height: 16),
          _LabeledField(
            label: l10n.pdStreet,
            controller: _street,
            accent: accent,
            error: _streetError,
            keyboardType: TextInputType.streetAddress,
            capitalization: TextCapitalization.words,
            action: TextInputAction.next,
            onChanged: () => setState(() => _streetError = null),
          ),
          const SizedBox(height: 16),
          _LabeledField(
            label: l10n.pdPostal,
            controller: _postal,
            accent: accent,
            error: _postalError,
            keyboardType: TextInputType.text,
            capitalization: TextCapitalization.characters,
            action: TextInputAction.done,
            formatters: [LengthLimitingTextInputFormatter(7)],
            onChanged: () => setState(() => _postalError = null),
          ),
          const SizedBox(height: 16),
          if (_hasCurrentConsent)
            _ConsentSummary(
                row: _row!, accent: accent, launcher: widget.launcher)
          else
            PrivacyConsentRow(
              checked: _consent,
              accent: accent,
              launcher: widget.launcher,
              errorText: _consentError ? l10n.pdConsentRequired : null,
              onChanged: (v) => setState(() {
                _consent = v;
                if (v) _consentError = false;
              }),
            ),
        ],
      ],
    );
  }
}

class _Plan {
  const _Plan({
    this.setName,
    this.setDob,
    this.setStreet,
    this.setPostal,
    this.clear = const {},
    this.consent = false,
    this.nothing = true,
  });

  final String? setName;
  final DateTime? setDob;
  final String? setStreet;
  final String? setPostal;
  final Set<PrivateDetailsField> clear;
  final bool consent;
  final bool nothing;
}

class _ConsentSummary extends StatelessWidget {
  const _ConsentSummary({
    required this.row,
    required this.accent,
    required this.launcher,
  });

  final UserPrivateDetails row;
  final Color accent;
  final TermsLauncher launcher;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final locale = Localizations.localeOf(context).toString();
    final date = DateFormat.yMMMd(locale).format(row.consentedAt!.toLocal());
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          l10n.pdConsentRowTitle,
          style: kTextStyle.copyWith(
            color: kNeutralColor,
            fontWeight: FontWeight.w600,
            fontSize: 14,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          l10n.pdConsentRowValue(row.consentVersion ?? '', date),
          style: kTextStyle.copyWith(color: kSubTitleColor, fontSize: 13),
        ),
        TextButton(
          onPressed: () => openPrivacyPolicy(context, launcher: launcher),
          style: TextButton.styleFrom(
            minimumSize: const Size(48, 48),
            padding: EdgeInsets.zero,
            alignment: AlignmentDirectional.centerStart,
            foregroundColor: authAccentText(accent),
          ),
          child: Text(
            l10n.privacyPolicy,
            style: const TextStyle(decoration: TextDecoration.underline),
          ),
        ),
      ],
    );
  }
}

class _LabeledField extends StatelessWidget {
  const _LabeledField({
    required this.label,
    required this.controller,
    required this.accent,
    required this.keyboardType,
    required this.capitalization,
    required this.action,
    required this.onChanged,
    this.helper,
    this.error,
    this.formatters,
  });

  final String label;
  final String? helper;
  final TextEditingController controller;
  final Color accent;
  final String? error;
  final TextInputType keyboardType;
  final TextCapitalization capitalization;
  final TextInputAction action;
  final VoidCallback onChanged;
  final List<TextInputFormatter>? formatters;

  @override
  Widget build(BuildContext context) {
    final hasError = error != null;
    OutlineInputBorder border(Color c, double w) => OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: c, width: w),
        );
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(
          label,
          style: kTextStyle.copyWith(
            color: kNeutralColor,
            fontWeight: FontWeight.w600,
            fontSize: 14,
          ),
        ),
        if (helper != null) ...[
          const SizedBox(height: 2),
          Text(
            helper!,
            style: kTextStyle.copyWith(color: kSubTitleColor, fontSize: 12),
          ),
        ],
        const SizedBox(height: 8),
        Semantics(
          label: label,
          textField: true,
          child: TextField(
            controller: controller,
            keyboardType: keyboardType,
            textCapitalization: capitalization,
            textInputAction: action,
            inputFormatters: formatters,
            cursorColor: authAccentText(accent),
            onChanged: (_) => onChanged(),
            style: kTextStyle.copyWith(fontSize: 15),
            decoration: InputDecoration(
              filled: true,
              fillColor: const Color(0xFFF8FAF9),
              contentPadding:
                  const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
              enabledBorder: border(
                  hasError ? kPdErrorColor : kBorderColorTextField,
                  hasError ? 1.5 : 1),
              focusedBorder: border(
                  hasError ? kPdErrorColor : authAccentText(accent), 1.5),
            ),
          ),
        ),
        if (hasError) PrivateFieldError(text: error!),
      ],
    );
  }
}
