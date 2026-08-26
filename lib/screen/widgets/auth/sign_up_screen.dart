import 'package:flutter/material.dart';
import 'package:freelancer/l10n/l10n.dart';
import 'package:freelancer/screen/widgets/auth/unified_log_in.dart';
import 'package:freelancer/screen/widgets/auth/auth_ui.dart';
import 'package:freelancer/screen/widgets/constant.dart';
import 'package:freelancer/services/auth_service.dart';
import 'package:nb_utils/nb_utils.dart';

class SignUpScreen extends StatefulWidget {
  final String role;
  final Color accentColor;
  final String heroImage;
  final String Function(AppLocalizations) subtitle;
  final String Function(AppLocalizations) roleLabel;
  final Widget Function(String email) otpScreenBuilder;

  const SignUpScreen({
    super.key,
    required this.role,
    required this.accentColor,
    required this.heroImage,
    required this.subtitle,
    required this.roleLabel,
    required this.otpScreenBuilder,
  });

  @override
  State<SignUpScreen> createState() => _SignUpScreenState();
}

class _SignUpScreenState extends State<SignUpScreen> {
  bool _hidePassword = true;
  bool _isCheck = false;
  bool _isLoading = false;

  final _firstNameController = TextEditingController();
  final _lastNameController = TextEditingController();
  final _emailController = TextEditingController();
  final _phoneController = TextEditingController();
  final _passwordController = TextEditingController();

  @override
  void dispose() {
    _firstNameController.dispose();
    _lastNameController.dispose();
    _emailController.dispose();
    _phoneController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _handleSignUp() async {
    final l10n = context.l10n;
    final firstName = _firstNameController.text.trim();
    final lastName = _lastNameController.text.trim();
    final email = _emailController.text.trim();
    final phone = _phoneController.text.trim();
    final password = _passwordController.text;

    if (firstName.isEmpty || lastName.isEmpty || email.isEmpty || password.isEmpty) {
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
        phone: phone.isNotEmpty ? phone : null,
      );

      if (mounted) {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => widget.otpScreenBuilder(email),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(l10n.errorWithDetail(e.toString()))),
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
            controller: _phoneController,
            label: l10n.authPhone,
            hint: l10n.authPhoneHint,
            keyboardType: TextInputType.phone,
            textInputAction: TextInputAction.next,
            focusedBorderColor: accent,
          ),
          const SizedBox(height: 16),
          AuthTextField(
            controller: _passwordController,
            label: l10n.authPassword,
            hint: l10n.authPasswordHint,
            obscureText: _hidePassword,
            textInputAction: TextInputAction.done,
            focusedBorderColor: accent,
            suffixIcon: IconButton(
              onPressed: () => setState(() => _hidePassword = !_hidePassword),
              icon: Icon(
                _hidePassword ? Icons.visibility_off_outlined : Icons.visibility_outlined,
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
            onTap: () => const UnifiedLogIn().launch(context),
          ),
        ],
      ),
    );
  }
}
