import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import 'constant.dart';
import 'package:freelancer/core/guide/guide_anchor.dart';

// ignore: must_be_immutable
class ButtonGlobal extends StatelessWidget {
  final String buttontext;
  final Decoration buttonDecoration;

  // ignore: prefer_typing_uninitialized_variables
  var onPressed;

  // ignore: use_key_in_widget_constructors
  ButtonGlobal(
      {required this.buttontext,
      required this.buttonDecoration,
      required this.onPressed});

  @override
  Widget build(BuildContext context) {
    return TextButton(
      onPressed: onPressed,
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.only(top: 10.0, bottom: 10.0),
        decoration: buttonDecoration,
        child: Center(
          child: Text(
            buttontext,
            style: kTextStyle.copyWith(
                fontSize: 20.0,
                color: Colors.white,
                fontWeight: FontWeight.bold),
          ),
        ),
      ),
    );
  }
}

// ignore: must_be_immutable
class ButtonGlobalWithoutIcon extends StatelessWidget {
  final String buttontext;
  final Decoration buttonDecoration;

  // ignore: prefer_typing_uninitialized_variables
  var onPressed;
  final Color buttonTextColor;

  // ignore: use_key_in_widget_constructors
  ButtonGlobalWithoutIcon({
    required this.buttontext,
    required this.buttonDecoration,
    required this.onPressed,
    required this.buttonTextColor,
    this.guideAnchor,
    this.disabledLook = false,
  });

  /// Optional guide target around this widget; see [GuideAnchor].
  final GuideAnchor? guideAnchor;

  /// Inactive state (T-0159 N1/N8): light grey fill with dark grey text
  /// (readable), instead of the caller's decoration colour and white text.
  final bool disabledLook;

  @override
  Widget build(BuildContext context) =>
      GuideAnchor.wrap(guideAnchor, _buildContent(context));

  // Same content-height pattern as VerificationSubmitBar: label capped at
  // text scale 1.3, up to 2 lines, centred, never overflows, min 48 tall.
  Widget _buildContent(BuildContext context) {
    final decoration = disabledLook
        ? kButtonDecoration.copyWith(
            color: const Color(0xFFE5E7EB),
            borderRadius: BorderRadius.circular(30.0),
          )
        : buttonDecoration;
    return MediaQuery.withClampedTextScaling(
      maxScaleFactor: 1.3,
      child: TextButton(
        onPressed: onPressed,
        child: Container(
          width: double.infinity,
          constraints: const BoxConstraints(minHeight: 48),
          padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 12),
          decoration: decoration,
          child: Center(
            heightFactor: 1,
            child: Text(
              buttontext,
              maxLines: 2,
              textAlign: TextAlign.center,
              overflow: TextOverflow.ellipsis,
              style: GoogleFonts.jost(
                fontSize: 20.0,
                color: disabledLook ? const Color(0xFF4B5563) : buttonTextColor,
              ),
            ),
          ),
        ),
      ),
    );
  }
}

// ignore: must_be_immutable
class ButtonGlobalWithIcon extends StatelessWidget {
  final String buttontext;
  final Decoration buttonDecoration;

  // ignore: prefer_typing_uninitialized_variables
  var onPressed;
  final Color buttonTextColor;
  // ignore: prefer_typing_uninitialized_variables
  final buttonIcon;

  // ignore: use_key_in_widget_constructors
  ButtonGlobalWithIcon({
    required this.buttontext,
    required this.buttonDecoration,
    required this.onPressed,
    required this.buttonTextColor,
    required this.buttonIcon,
  });

  @override
  Widget build(BuildContext context) {
    return TextButton(
      onPressed: onPressed,
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.only(top: 10.0, bottom: 10.0),
        decoration: buttonDecoration,
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              buttonIcon,
              color: buttonTextColor,
            ),
            const SizedBox(width: 5.0),
            Text(
              buttontext,
              style: GoogleFonts.jost(fontSize: 20.0, color: buttonTextColor),
            ),
          ],
        ),
      ),
    );
  }
}
