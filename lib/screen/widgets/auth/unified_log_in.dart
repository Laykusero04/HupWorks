import 'package:flutter/material.dart';
import 'package:freelancer/core/auth_navigation.dart';
import 'package:freelancer/screen/client%20screen/client_authentication/client_forgot_password.dart';
import 'package:freelancer/screen/welcome%20screen/welcome_screen.dart';
import 'package:freelancer/screen/widgets/auth/auth_ui.dart';
import 'package:freelancer/screen/widgets/constant.dart';
import 'package:freelancer/services/auth_service.dart';
import 'package:go_router/go_router.dart';
import 'package:nb_utils/nb_utils.dart';

import '../../app_config/app_config.dart';

/// Single login screen for both clients and freelancers.
class UnifiedLogIn extends StatefulWidget {
  const UnifiedLogIn({super.key});

  @override
  State<UnifiedLogIn> createState() => _UnifiedLogInState();
}

class _UnifiedLogInState extends State<UnifiedLogIn> {
  bool _hidePassword = true;
  bool _isLoading = false;

  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _handleLogin() async {
    final email = _emailController.text.trim();
    final password = _passwordController.text;

    if (email.isEmpty || password.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please fill in all fields')),
      );
      return;
    }

    setState(() => _isLoading = true);

    try {
      await AuthService.signIn(email: email, password: password);
      if (mounted) {
        await AuthNavigation.goToHomeAfterAuth(context);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(e.toString())),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return AuthScaffold(
      title: 'Welcome back',
      subtitle: 'Sign in to continue to HupWorks.',
      accentColor: kPrimaryColor,
      heroImage: AppInfo.onBoard1,
      onBack: () => Navigator.of(context).maybePop(),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          AuthTextField(
            controller: _emailController,
            label: 'Email',
            hint: 'you@email.com',
            keyboardType: TextInputType.emailAddress,
            textInputAction: TextInputAction.next,
          ),
          const SizedBox(height: 16),
          AuthTextField(
            controller: _passwordController,
            label: 'Password',
            hint: 'Enter your password',
            obscureText: _hidePassword,
            textInputAction: TextInputAction.done,
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
          Align(
            alignment: Alignment.centerRight,
            child: TextButton(
              onPressed: () => const ClientForgotPassword().launch(context),
              child: Text(
                'Forgot password?',
                style: kTextStyle.copyWith(
                  color: kPrimaryColor,
                  fontWeight: FontWeight.w600,
                  fontSize: 14,
                ),
              ),
            ),
          ),
          const SizedBox(height: 8),
          AuthPrimaryButton(
            label: 'Log In',
            accentColor: kPrimaryColor,
            isLoading: _isLoading,
            onPressed: _handleLogin,
          ),
          const SizedBox(height: 24),
          const AuthSocialSection(),
          const SizedBox(height: 24),
          AuthFooterLink(
            prefix: "Don't have an account? ",
            action: 'Sign up',
            accentColor: kPrimaryColor,
            onTap: () => const WelcomeScreen().launch(context),
          ),
        ],
      ),
    );
  }
}
