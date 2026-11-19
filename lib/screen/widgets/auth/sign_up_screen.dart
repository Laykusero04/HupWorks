import 'package:freelancer/core/utils/auth_error_message.dart';
import 'package:freelancer/core/utils/password_strength.dart';
import 'package:flutter/material.dart';
import 'package:freelancer/l10n/l10n.dart';
import 'package:freelancer/screen/widgets/auth/auth_ui.dart';
import 'package:freelancer/screen/widgets/constant.dart';
import 'package:freelancer/services/auth_service.dart';
import 'package:go_router/go_router.dart';

class SignUpScreen extends StatefulWidget {
  final String role;
  final Color accentColor;
  final String heroImage;
  final String Function(AppLocalizations) subtitle;
  final String Function(AppLocalizations) roleLabel;

  /// Called after successful signup. Prefer GoRouter navigation for sellers.
  final Future<void> Function(BuildContext context, String email) onSignedUp;

  const SignUpScreen({
    super.key,
    required this.role,
    required this.accentColor,
    required this.heroImage,
    required this.subtitle,
    required this.roleLabel,
    required this.onSignedUp,
  });

  @override
  State<SignUpScreen> createState() => _SignUpScreenState();
}

class _SignUpScreenState extends State<SignUpScreen> {
  bool _hidePassword = true;
  bool _hideConfirm = true;
  bool _isCheck = false;
  bool _isLoading = false;

  final _firstNameController = TextEditingController();
  final _lastNameController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmController = TextEditingController();

  @override
  void dispose() {
    _firstNameController.dispose();
    _lastNameController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    _confirmController.dispose();
    super.dispose();
  }

  Future<void> _handleSignUp() async {
    final l10n = context.l10n;
    final firstName = _firstNameController.text.trim();
    final lastName = _lastNameController.text.trim();
    final email = _emailController.text.trim();
    final password = _passwordController.text;

    if (firstName.isEmpty ||
        lastName.isEmpty ||
        email.isEmpty ||
        password.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(l10n.pleaseFillAllFields)),
      );
      return;
    }

    if (password.length < 6) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(l10n.authPasswordMinLength)),
      );
      return;
    }

    if (password != _confirmController.text) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(l10n.authPasswordsDoNotMatch)),
      );
      return;
    }

    if (!_isCheck) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(l10n.authMustAgreeTerms)),
      );
      return;
    }

    setState(() => _isLoading = true);

    try {
      await AuthService.signUp(
        email: email,
        password: password,
        name: '$firstName $lastName',
        role: widget.role,
      );

      if (mounted) {
        await widget.onSignedUp(context, email);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(authErrorMessage(l10n, e))),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final accent = widget.accentColor;
    return AuthScaffold(
      title: l10n.authCreateAccount,
      subtitle: widget.subtitle(l10n),
      roleLabel: widget.roleLabel(l10n),
      accentColor: accent,
      heroImage: widget.heroImage,
      onBack: () => Navigator.pop(context),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          AuthNameRow(
            firstController: _firstNameController,
            lastController: _lastNameController,
            focusedBorderColor: accent,
          ),
          const SizedBox(height: 16),
          AuthTextField(
            controller: _emailController,
            label: l10n.authEmail,
            hint: l10n.authEmailHint,
            keyboardType: TextInputType.emailAddress,
            textInputAction: TextInputAction.next,
            focusedBorderColor: accent,
          ),
          const SizedBox(height: 16),
          AuthTextField(
            controller: _passwordController,
            label: l10n.authPassword,
            hint: l10n.authPasswordHint,
            obscureText: _hidePassword,
            textInputAction: TextInputAction.next,
            focusedBorderColor: accent,
            onChanged: (_) => setState(() {}),
            suffixIcon: IconButton(
              onPressed: () => setState(() => _hidePassword = !_hidePassword),
              icon: Icon(
                _hidePassword
                    ? Icons.visibility_off_outlined
                    : Icons.visibility_outlined,
                color: kLightNeutralColor,
              ),
            ),
          ),
          _PasswordStrengthHint(password: _passwordController.text),
          const SizedBox(height: 16),
          AuthTextField(
            controller: _confirmController,
            label: l10n.authConfirmPassword,
            hint: l10n.authPasswordHint,
            obscureText: _hideConfirm,
            textInputAction: TextInputAction.done,
            focusedBorderColor: accent,
            onChanged: (_) => setState(() {}),
            errorText: _confirmController.text.isNotEmpty &&
                    _confirmController.text != _passwordController.text
                ? l10n.authPasswordsDoNotMatch
                : null,
            suffixIcon: IconButton(
              onPressed: () => setState(() => _hideConfirm = !_hideConfirm),
              icon: Icon(
                _hideConfirm
                    ? Icons.visibility_off_outlined
                    : Icons.visibility_outlined,
                color: kLightNeutralColor,
              ),
            ),
          ),
          const SizedBox(height: 16),
          AuthTermsRow(
            checked: _isCheck,
            accentColor: accent,
            onChanged: (v) => setState(() => _isCheck = v ?? false),
          ),
          const SizedBox(height: 20),
          AuthPrimaryButton(
            label: l10n.authSignUpButton,
            accentColor: accent,
            isLoading: _isLoading,
            onPressed: _handleSignUp,
          ),
          const SizedBox(height: 24),
          AuthFooterLink(
            prefix: '${l10n.authAlreadyHaveAccountShort} ',
            action: l10n.authLogIn,
            accentColor: accent,
            onTap: () => context.go(
              widget.role == 'seller'
                  ? '/auth/seller/login'
                  : '/auth/client/login',
            ),
          ),
        ],
      ),
    );
  }
}

class _PasswordStrengthHint extends StatelessWidget {
  const _PasswordStrengthHint({required this.password});

  final String password;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final strength = passwordStrength(password);
    final (label, color, filled) = switch (strength) {
      PasswordStrength.empty => (null, kLightNeutralColor, 0),
      PasswordStrength.weak => (
          l10n.authPasswordStrengthWeak,
          const Color(0xFFD32F2F),
          1
        ),
      PasswordStrength.medium => (
          l10n.authPasswordStrengthMedium,
          const Color(0xFFF9A825),
          2
        ),
      PasswordStrength.strong => (
          l10n.authPasswordStrengthStrong,
          const Color(0xFF2E7D32),
          3
        ),
    };
    // Bars may use the bright amber; label text needs WCAG AA (4.5:1) on white,
    // so Medium text uses a darker amber (#8A6100, ~7:1).
    final labelColor = strength == PasswordStrength.medium
        ? const Color(0xFF8A6100)
        : color;
    return Padding(
      padding: const EdgeInsets.only(top: 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (label != null) ...[
            Row(
              children: [
                for (var i = 0; i < 3; i++)
                  Expanded(
                    child: Container(
                      key: ValueKey('strength-bar-$i'),
                      height: 4,
                      margin: EdgeInsets.only(right: i < 2 ? 4 : 0),
                      decoration: BoxDecoration(
                        color: i < filled ? color : kBorderColorTextField,
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 6),
            Text(
              label,
              style: kTextStyle.copyWith(
                  color: labelColor, fontSize: 12, fontWeight: FontWeight.w600),
            ),
            const SizedBox(height: 2),
          ],
          Text(
            l10n.authPasswordStrengthHint,
            style: kTextStyle.copyWith(color: kNeutralColor, fontSize: 12),
          ),
        ],
      ),
    );
  }
}
