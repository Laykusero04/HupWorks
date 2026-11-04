import 'package:flutter/material.dart';
import 'package:freelancer/core/auth/login_credentials_prefs.dart';
import 'package:freelancer/core/auth_navigation.dart';
import 'package:freelancer/l10n/l10n.dart';
import 'package:freelancer/screen/client%20screen/client_authentication/client_forgot_password.dart';
import 'package:freelancer/screen/welcome%20screen/welcome_screen.dart';
import 'package:freelancer/screen/widgets/auth/auth_ui.dart';
import 'package:freelancer/screen/widgets/constant.dart';
import 'package:freelancer/services/auth_service.dart';
import 'package:nb_utils/nb_utils.dart';

import '../../app_config/app_config.dart';

/// Shared login screen. [role] is `client` (employer, orange) or `seller` (freelancer, cyan).
class UnifiedLogIn extends StatefulWidget {
  const UnifiedLogIn({super.key, this.role = 'client'});

  final String role;

  @override
  State<UnifiedLogIn> createState() => _UnifiedLogInState();
}

class _UnifiedLogInState extends State<UnifiedLogIn> {
  bool _hidePassword = true;
  bool _isLoading = false;
  bool _savePassword = false;

  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _loadSavedCredentials();
  }

  Future<void> _loadSavedCredentials() async {
    final saved = await LoginCredentialsPrefs.load();
    if (!mounted) return;
    if (!saved.remember) return;
    setState(() {
      _savePassword = true;
      _emailController.text = saved.email;
      _passwordController.text = saved.password;
    });
  }

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _handleLogin() async {
    final l10n = context.l10n;
    final email = _emailController.text.trim();
    final password = _passwordController.text;

    if (email.isEmpty || password.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(l10n.pleaseFillAllFields)),
      );
      return;
    }

    setState(() => _isLoading = true);

    try {
      await AuthService.signIn(email: email, password: password);
      if (_savePassword) {
        await LoginCredentialsPrefs.save(email: email, password: password);
      } else {
        await LoginCredentialsPrefs.clear();
      }
      if (mounted) {
        await AuthNavigation.goToHomeAfterAuth(context);
      }
    } catch (e) {
      if (mounted) {
        final message = AuthService.isAccountBlockedError(e)
            ? l10n.accountBlocked
            : l10n.errorWithDetail(e.toString());
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(message)),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final freelancer = widget.role == 'seller';
    final accent = freelancer ? kSellerPrimary : kPrimaryColor;
    return AuthScaffold(
      title: l10n.authWelcomeBack,
      subtitle: l10n.authSignInSubtitle,
      roleLabel: freelancer ? l10n.authRoleFreelancer : l10n.authRoleClient,
      accentColor: accent,
      heroImage: AppInfo.onBoard1,
      onBack: () => Navigator.of(context).maybePop(),
      child: AutofillGroup(
        child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          AuthTextField(
            controller: _emailController,
            label: l10n.authEmail,
            hint: l10n.authEmailHint,
            keyboardType: TextInputType.emailAddress,
            textInputAction: TextInputAction.next,
            autofillHints: const [AutofillHints.email],
            focusedBorderColor: accent,
          ),
          const SizedBox(height: 16),
          AuthTextField(
            controller: _passwordController,
            label: l10n.authPassword,
            hint: l10n.authPasswordHint,
            obscureText: _hidePassword,
            textInputAction: TextInputAction.done,
            autofillHints: const [AutofillHints.password],
            focusedBorderColor: accent,
            onFieldSubmitted: (_) => _handleLogin(),
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
          const SizedBox(height: 8),
          SizedBox(
            height: 44,
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Expanded(
                  child: InkWell(
                    onTap: () => setState(() => _savePassword = !_savePassword),
                    child: Row(
                      children: [
                        Checkbox(
                          value: _savePassword,
                          onChanged: (v) =>
                              setState(() => _savePassword = v ?? false),
                          activeColor: accent,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(3),
                          ),
                          materialTapTargetSize:
                              MaterialTapTargetSize.shrinkWrap,
                          visualDensity: VisualDensity.compact,
                        ),
                        const SizedBox(width: 6),
                        Expanded(
                          child: Text(
                            l10n.authSavePassword,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: kTextStyle.copyWith(
                              color: kSubTitleColor,
                              fontSize: 13,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                Flexible(
                  child: Align(
                    alignment: Alignment.centerRight,
                    child: TextButton(
                      onPressed: () =>
                          const ClientForgotPassword().launch(context),
                      style: TextButton.styleFrom(
                        padding: const EdgeInsets.symmetric(horizontal: 8),
                        minimumSize: const Size(44, 44),
                        tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                      ),
                      child: Text(
                        l10n.authForgotPassword,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: kTextStyle.copyWith(
                          color: accent,
                          fontWeight: FontWeight.w600,
                          fontSize: 11,
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          AuthPrimaryButton(
            label: l10n.authLogIn,
            accentColor: accent,
            isLoading: _isLoading,
            onPressed: _handleLogin,
          ),
          const SizedBox(height: 24),
          AuthFooterLink(
            prefix: '${l10n.authDontHaveAccount} ',
            action: l10n.authSignUp,
            accentColor: accent,
            onTap: () => const WelcomeScreen().launch(context),
          ),
        ],
        ),
      ),
    );
  }
}
