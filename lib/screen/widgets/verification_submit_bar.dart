import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import 'constant.dart';

/// Bottom "Submit for review" bar of the verification screens.
///
/// Sizes to its content (never fills the Scaffold's bottom slot): one
/// full-width button, min 48 tall, label capped at text scale 1.3, up to 2
/// lines. Disabled = light grey fill + dark grey text, enabled = [enabledColor]
/// fill + white text.
class VerificationSubmitBar extends StatelessWidget {
  const VerificationSubmitBar({
    super.key,
    required this.label,
    required this.enabled,
    required this.onPressed,
    required this.enabledColor,
  });

  final String label;
  final bool enabled;
  final VoidCallback? onPressed;
  final Color enabledColor;

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      top: false,
      child: MediaQuery.withClampedTextScaling(
        maxScaleFactor: 1.3,
        child: TextButton(
          onPressed: enabled ? onPressed : null,
          child: Container(
            width: double.infinity,
            constraints: const BoxConstraints(minHeight: 48),
            padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 12),
            decoration: kButtonDecoration.copyWith(
              color: enabled ? enabledColor : const Color(0xFFE5E7EB),
              borderRadius: BorderRadius.circular(30),
            ),
            child: Center(
              heightFactor: 1,
              child: Text(
                label,
                maxLines: 2,
                textAlign: TextAlign.center,
                overflow: TextOverflow.ellipsis,
                style: GoogleFonts.jost(
                  fontSize: 20.0,
                  color: enabled ? kWhite : const Color(0xFF4B5563),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
