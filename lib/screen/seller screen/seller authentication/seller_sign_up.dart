import 'package:flutter/material.dart';
import 'package:freelancer/screen/widgets/auth/unified_log_in.dart';
import 'package:freelancer/screen/seller%20screen/seller%20authentication/verification.dart';
import 'package:freelancer/screen/widgets/auth/auth_ui.dart';
import 'package:freelancer/screen/widgets/constant.dart';
import 'package:freelancer/services/auth_service.dart';
import 'package:nb_utils/nb_utils.dart';

import '../../app_config/app_config.dart';

class SellerSignUp extends StatefulWidget {
  const SellerSignUp({super.key});

  @override
  State<SellerSignUp> createState() => _SellerSignUpState();
}

class _SellerSignUpState extends State<SellerSignUp> {
  bool _hidePassword = true;
  bool _isCheck = false;
  bool _isLoading = false;

  final _firstNameController = TextEditingController();
  final _lastNameController = TextEditingController();
  final _emailController = TextEditingController();
  final _phoneController = TextEditingController();
  final _passwordController = TextEditingController();

  static const _accent = kSecondaryColor;

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
    final firstName = _firstNameController.text.trim();
    final lastName = _lastNameController.text.trim();
    final email = _emailController.text.trim();
    final phone = _phoneController.text.trim();
    final password = _passwordController.text;

    if (firstName.isEmpty || lastName.isEmpty || email.isEmpty || password.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please fill in all required fields')),
      );
      return;
    }

    if (password.length < 6) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Password must be at least 6 characters')),
      );
      return;
    }

    if (!_isCheck) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please agree to the Terms of Service')),
      );
      return;
    }

    setState(() => _isLoading = true);

    try {
      await AuthService.signUp(
        email: email,
        password: password,
        name: '$firstName $lastName',
        role: 'seller',
        phone: phone.isNotEmpty ? phone : null,
      );

      if (mounted) {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => OtpVerification(email: email),
          ),
        );
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
      title: 'Create your account',
      subtitle: 'Join as a freelancer and start finding work.',
      roleLabel: 'Freelancer',
      accentColor: _accent,
      heroImage: AppInfo.onBoard3,
      onBack: () => Navigator.pop(context),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          AuthNameRow(
            firstController: _firstNameController,
            lastController: _lastNameController,
            focusedBorderColor: _accent,
          ),
          const SizedBox(height: 16),
          AuthTextField(
            controller: _emailController,
            label: 'Email',
            hint: 'you@email.com',
            keyboardType: TextInputType.emailAddress,
            textInputAction: TextInputAction.next,
            focusedBorderColor: _accent,
          ),
          const SizedBox(height: 16),
          AuthTextField(
            controller: _phoneController,
            label: 'Phone (optional)',
            hint: '+880 1XXX XXXXXX',
            keyboardType: TextInputType.phone,
            textInputAction: TextInputAction.next,
            focusedBorderColor: _accent,
          ),
          const SizedBox(height: 16),
          AuthTextField(
            controller: _passwordController,
            label: 'Password',
            hint: 'At least 6 characters',
            obscureText: _hidePassword,
            textInputAction: TextInputAction.done,
            focusedBorderColor: _accent,
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
            accentColor: _accent,
            onChanged: (v) => setState(() => _isCheck = v ?? false),
          ),
          const SizedBox(height: 20),
          AuthPrimaryButton(
            label: 'Sign Up',
            accentColor: _accent,
            isLoading: _isLoading,
            onPressed: _handleSignUp,
          ),
          const SizedBox(height: 24),
          const AuthSocialSection(dividerText: 'Or sign up with'),
          const SizedBox(height: 24),
          AuthFooterLink(
            prefix: 'Already have an account? ',
            action: 'Log In',
            accentColor: _accent,
            onTap: () => const UnifiedLogIn().launch(context),
          ),
        ],
      ),
    );
  }
}
