import 'package:flutter/material.dart';
import 'package:freelancer/l10n/l10n.dart';

import '../constant.dart';

/// Shared auth layout — matches welcome screen (illustration + white sheet).
class AuthScaffold extends StatelessWidget {
  const AuthScaffold({
    super.key,
    required this.title,
    required this.accentColor,
    required this.heroImage,
    required this.onBack,
    required this.child,
    this.subtitle,
    this.roleLabel,
  });

  final String title;
  final String? subtitle;
  final String? roleLabel;
  final Color accentColor;
  final String heroImage;
  final VoidCallback onBack;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: kDarkWhite,
      body: Column(
        children: [
          SafeArea(
            bottom: false,
            child: Padding(
              padding: const EdgeInsets.fromLTRB(8, 8, 16, 0),
              child: Column(
                children: [
                  Align(
                    alignment: Alignment.centerLeft,
                    child: IconButton(
                      onPressed: onBack,
                      icon: const Icon(Icons.arrow_back_rounded),
                      color: kNeutralColor,
                    ),
                  ),
                  if (roleLabel != null) ...[
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 6,
                      ),
                      decoration: BoxDecoration(
                        color: accentColor.withValues(alpha: 0.12),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Text(
                        roleLabel!,
                        style: kTextStyle.copyWith(
                          color: accentColor,
                          fontWeight: FontWeight.w600,
                          fontSize: 13,
                        ),
                      ),
                    ),
                    const SizedBox(height: 8),
                  ],
                  Image.asset(
                    heroImage,
                    height: 140,
                    fit: BoxFit.contain,
                  ),
                ],
              ),
            ),
          ),
          Expanded(
            child: Container(
              width: double.infinity,
              decoration: const BoxDecoration(
                color: kWhite,
                borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
                boxShadow: [
                  BoxShadow(
                    color: Color(0x14000000),
                    blurRadius: 20,
                    offset: Offset(0, -4),
                  ),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Padding(
                    padding: const EdgeInsets.fromLTRB(24, 24, 24, 0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          title,
                          style: kTextStyle.copyWith(
                            fontSize: 22,
                            fontWeight: FontWeight.bold,
                            color: kNeutralColor,
                          ),
                        ),
                        if (subtitle != null) ...[
                          const SizedBox(height: 6),
                          Text(
                            subtitle!,
                            style: kTextStyle.copyWith(
                              fontSize: 14,
                              color: kSubTitleColor,
                              height: 1.4,
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                  Expanded(
                    child: SingleChildScrollView(
                      physics: const BouncingScrollPhysics(),
                      padding: EdgeInsets.fromLTRB(
                        24,
                        20,
                        24,
                        24 + MediaQuery.paddingOf(context).bottom,
                      ),
                      child: child,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

InputDecoration authInputDecoration({
  required String label,
  required String hint,
  Widget? suffixIcon,
}) {
  return InputDecoration(
    labelText: label,
    hintText: hint,
    labelStyle: kTextStyle.copyWith(color: kNeutralColor, fontSize: 14),
    hintStyle: kTextStyle.copyWith(color: kLightNeutralColor, fontSize: 14),
    filled: true,
    fillColor: const Color(0xFFF8FAF9),
    contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
    enabledBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(12),
      borderSide: const BorderSide(color: kBorderColorTextField),
    ),
    focusedBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(12),
      borderSide: const BorderSide(color: kPrimaryColor, width: 1.5),
    ),
    suffixIcon: suffixIcon,
  );
}

class AuthTextField extends StatelessWidget {
  const AuthTextField({
    super.key,
    required this.controller,
    required this.label,
    required this.hint,
    this.keyboardType,
    this.obscureText = false,
    this.textInputAction,
    this.suffixIcon,
    this.focusedBorderColor = kPrimaryColor,
  });

  final TextEditingController controller;
  final String label;
  final String hint;
  final TextInputType? keyboardType;
  final bool obscureText;
  final TextInputAction? textInputAction;
  final Widget? suffixIcon;
  final Color focusedBorderColor;

  @override
  Widget build(BuildContext context) {
    return TextFormField(
      controller: controller,
      keyboardType: keyboardType,
      obscureText: obscureText,
      textInputAction: textInputAction,
      cursorColor: focusedBorderColor,
      style: kTextStyle.copyWith(fontSize: 15),
      decoration: authInputDecoration(
        label: label,
        hint: hint,
        suffixIcon: suffixIcon,
      ).copyWith(
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: focusedBorderColor, width: 1.5),
        ),
      ),
    );
  }
}

class AuthPrimaryButton extends StatelessWidget {
  const AuthPrimaryButton({
    super.key,
    required this.label,
    required this.onPressed,
    required this.accentColor,
    this.isLoading = false,
  });

  final String label;
  final VoidCallback? onPressed;
  final Color accentColor;
  final bool isLoading;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      height: 52,
      child: FilledButton(
        onPressed: isLoading ? null : onPressed,
        style: FilledButton.styleFrom(
          backgroundColor: isLoading ? kLightNeutralColor : accentColor,
          disabledBackgroundColor: kLightNeutralColor,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(14),
          ),
        ),
        child: isLoading
            ? SizedBox(
                height: 22,
                width: 22,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  color: kWhite.withValues(alpha: 0.9),
                ),
              )
            : Text(
                label,
                style: kTextStyle.copyWith(
                  color: kWhite,
                  fontWeight: FontWeight.w600,
                  fontSize: 16,
                ),
              ),
      ),
    );
  }
}

class AuthFooterLink extends StatelessWidget {
  const AuthFooterLink({
    super.key,
    required this.prefix,
    required this.action,
    required this.onTap,
    required this.accentColor,
  });

  final String prefix;
  final String action;
  final VoidCallback onTap;
  final Color accentColor;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: GestureDetector(
        onTap: onTap,
        child: RichText(
          text: TextSpan(
            text: prefix,
            style: kTextStyle.copyWith(color: kSubTitleColor, fontSize: 15),
            children: [
              TextSpan(
                text: action,
                style: kTextStyle.copyWith(
                  color: accentColor,
                  fontWeight: FontWeight.bold,
                  fontSize: 15,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class AuthTermsRow extends StatelessWidget {
  const AuthTermsRow({
    super.key,
    required this.checked,
    required this.onChanged,
    required this.accentColor,
  });

  final bool checked;
  final ValueChanged<bool?> onChanged;
  final Color accentColor;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(
          height: 24,
          width: 24,
          child: Checkbox(
            value: checked,
            onChanged: onChanged,
            activeColor: accentColor,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(4),
            ),
            materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: Padding(
            padding: const EdgeInsets.only(top: 2),
            child: RichText(
              text: TextSpan(
                text: l10n.authAgreeToThe,
                style: kTextStyle.copyWith(
                  color: kSubTitleColor,
                  fontSize: 13,
                  height: 1.4,
                ),
                children: [
                  TextSpan(
                    text: l10n.authTermsOfService,
                    style: kTextStyle.copyWith(
                      color: accentColor,
                      fontWeight: FontWeight.bold,
                      fontSize: 13,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }
}

/// Two name fields in one row for sign-up forms.
class AuthNameRow extends StatelessWidget {
  const AuthNameRow({
    super.key,
    required this.firstController,
    required this.lastController,
    this.focusedBorderColor = kPrimaryColor,
  });

  final TextEditingController firstController;
  final TextEditingController lastController;
  final Color focusedBorderColor;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(
          child: AuthTextField(
            controller: firstController,
            label: l10n.authFirstName,
            hint: l10n.authFirstNameHint,
            textInputAction: TextInputAction.next,
            focusedBorderColor: focusedBorderColor,
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: AuthTextField(
            controller: lastController,
            label: l10n.authLastName,
            hint: l10n.authLastNameHint,
            textInputAction: TextInputAction.next,
            focusedBorderColor: focusedBorderColor,
          ),
        ),
      ],
    );
  }
}
