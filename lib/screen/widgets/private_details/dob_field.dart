import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:freelancer/core/utils/dob_input.dart';
import 'package:freelancer/l10n/l10n.dart';
import 'package:freelancer/screen/widgets/auth/auth_ui.dart';
import 'package:freelancer/screen/widgets/constant.dart';

/// Error red with AA contrast on white (6.5:1). Used for text and borders of
/// the private-details fields; errors also carry an icon, never colour only.
const kPdErrorColor = Color(0xFFB3261E);

/// Owns the three text controllers of a [DobField].
class DobController {
  DobController({String day = '', String month = '', String year = ''})
      : day = TextEditingController(text: day),
        month = TextEditingController(text: month),
        year = TextEditingController(text: year);

  final TextEditingController day;
  final TextEditingController month;
  final TextEditingController year;

  /// Splits a pasted full date into the three boxes. Accepts D-M-YYYY,
  /// D/M/YYYY, D.M.YYYY (also with spaces) and YYYY-M-D. Returns false (and
  /// leaves the boxes alone) for anything else.
  bool setFromPasted(String raw) {
    final dmy = RegExp(r'^\s*(\d{1,2})[-/. ]+(\d{1,2})[-/. ]+(\d{4})\s*$');
    final ymd = RegExp(r'^\s*(\d{4})[-/. ]+(\d{1,2})[-/. ]+(\d{1,2})\s*$');
    String? d, m, y;
    final a = dmy.firstMatch(raw);
    if (a != null) {
      d = a.group(1);
      m = a.group(2);
      y = a.group(3);
    } else {
      final b = ymd.firstMatch(raw);
      if (b == null) return false;
      y = b.group(1);
      m = b.group(2);
      d = b.group(3);
    }
    day.text = d!.padLeft(2, '0');
    month.text = m!.padLeft(2, '0');
    year.text = y!;
    return true;
  }

  /// Fills the fields from a stored date.
  void setDate(DateTime d) {
    day.text = d.day.toString().padLeft(2, '0');
    month.text = d.month.toString().padLeft(2, '0');
    year.text = d.year.toString().padLeft(4, '0');
  }

  bool get isEmpty =>
      day.text.trim().isEmpty &&
      month.text.trim().isEmpty &&
      year.text.trim().isEmpty;

  DobResult validate({DateTime? now}) =>
      validateDob(day.text, month.text, year.text, now: now);

  void dispose() {
    day.dispose();
    month.dispose();
    year.dispose();
  }
}

/// Runs before the digit/length formatters: when a whole date is pasted into
/// any box it is distributed over Day / Month / Year instead of being cut.
class _DobPasteFormatter extends TextInputFormatter {
  _DobPasteFormatter(this.controller, this.onPasted, this.keep);

  final DobController controller;
  final VoidCallback? onPasted;

  /// The box this formatter belongs to (it receives its own part).
  final TextEditingController keep;

  @override
  TextEditingValue formatEditUpdate(
      TextEditingValue oldValue, TextEditingValue newValue) {
    final t = newValue.text;
    if (t.length <= 4 && !RegExp(r'[^0-9]').hasMatch(t)) return newValue;
    if (!controller.setFromPasted(t)) return newValue;
    onPasted?.call();
    return TextEditingValue(
      text: keep.text,
      selection: TextSelection.collapsed(offset: keep.text.length),
    );
  }
}

String dobErrorText(AppLocalizations l10n, DobError e) => switch (e) {
      DobError.empty => l10n.pdDobErrorEmpty,
      DobError.invalid => l10n.pdDobErrorInvalid,
      DobError.future => l10n.pdDobErrorFuture,
      DobError.under16 => l10n.pdDobErrorUnder16,
    };

/// Date of birth as three numeric fields (day / month / year) with the label
/// above each field so long Dutch words wrap. At large text scale the year
/// moves to its own row (a [Wrap], never a fixed row).
class DobField extends StatelessWidget {
  const DobField({
    super.key,
    required this.controller,
    required this.accent,
    this.errorText,
    this.enabled = true,
    this.onChanged,
    this.showLabel = true,
    this.autofill = false,
  });

  /// Offers the OS birthday autofill hints (signup, where it helps).
  final bool autofill;

  final DobController controller;
  final Color accent;
  final String? errorText;
  final bool enabled;
  final VoidCallback? onChanged;

  /// Group label ("Date of birth") above the fields.
  final bool showLabel;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final hasError = errorText != null;
    final large = MediaQuery.textScalerOf(context).scale(1.0) > 1.3;
    return Semantics(
      container: true,
      label: l10n.pdDobLabel,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          if (showLabel) ...[
            Text(
              l10n.pdDobLabel,
              style: kTextStyle.copyWith(
                color: kNeutralColor,
                fontWeight: FontWeight.w600,
                fontSize: 14,
              ),
            ),
            const SizedBox(height: 8),
          ],
          LayoutBuilder(builder: (context, c) {
            const gap = 12.0;
            final w = c.maxWidth;
            final double dayW, monthW, yearW;
            if (large) {
              dayW = monthW = (w - gap) / 2;
              yearW = dayW;
            } else {
              final unit = (w - 2 * gap) / 7;
              dayW = unit * 2;
              monthW = unit * 2;
              yearW = unit * 3;
            }
            return Wrap(
              spacing: gap,
              runSpacing: 12,
              children: [
                _part(context, dayW, l10n.pdDobDay, controller.day, 2, hasError,
                    TextInputAction.next, AutofillHints.birthdayDay),
                _part(
                    context,
                    monthW,
                    l10n.pdDobMonth,
                    controller.month,
                    2,
                    hasError,
                    TextInputAction.next,
                    AutofillHints.birthdayMonth),
                _part(context, yearW, l10n.pdDobYear, controller.year, 4,
                    hasError, TextInputAction.done, AutofillHints.birthdayYear),
              ],
            );
          }),
          if (hasError) PrivateFieldError(text: errorText!),
        ],
      ),
    );
  }

  Widget _part(
      BuildContext context,
      double width,
      String label,
      TextEditingController c,
      int maxLen,
      bool hasError,
      TextInputAction a,
      String hint) {
    final border = OutlineInputBorder(
      borderRadius: BorderRadius.circular(12),
      borderSide: BorderSide(
        color: hasError ? kPdErrorColor : kBorderColorTextField,
        width: hasError ? 1.5 : 1,
      ),
    );
    return SizedBox(
      width: width,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: kTextStyle.copyWith(color: kSubTitleColor, fontSize: 12),
          ),
          const SizedBox(height: 4),
          Semantics(
            label: '${context.l10n.pdDobLabel}, $label',
            textField: true,
            child: TextField(
              controller: c,
              enabled: enabled,
              keyboardType: TextInputType.number,
              textInputAction: a,
              cursorColor: authAccentText(accent),
              autofillHints: autofill ? [hint] : null,
              inputFormatters: [
                _DobPasteFormatter(controller, onChanged, c),
                FilteringTextInputFormatter.digitsOnly,
                LengthLimitingTextInputFormatter(maxLen),
              ],
              onChanged: (_) => onChanged?.call(),
              style: kTextStyle.copyWith(fontSize: 15),
              decoration: InputDecoration(
                filled: true,
                fillColor: const Color(0xFFF8FAF9),
                isDense: false,
                contentPadding:
                    const EdgeInsets.symmetric(horizontal: 12, vertical: 14),
                enabledBorder: border,
                disabledBorder: border,
                errorBorder: border,
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide(
                    color: hasError ? kPdErrorColor : authAccentText(accent),
                    width: 1.5,
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// Inline error: icon + text (never colour only), wraps, announced as live.
class PrivateFieldError extends StatelessWidget {
  const PrivateFieldError({super.key, required this.text});
  final String text;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(top: 6),
      child: Semantics(
        liveRegion: true,
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Padding(
              padding: EdgeInsets.only(top: 1),
              child: ExcludeSemantics(
                child:
                    Icon(Icons.error_outline, size: 16, color: kPdErrorColor),
              ),
            ),
            const SizedBox(width: 6),
            Expanded(
              child: Text(
                text,
                style: kTextStyle.copyWith(
                  color: kPdErrorColor,
                  fontSize: 12,
                  height: 1.35,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
