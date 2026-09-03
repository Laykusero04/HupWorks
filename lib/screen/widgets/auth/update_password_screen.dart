import 'package:flutter/material.dart';
import 'package:freelancer/l10n/l10n.dart';
import 'package:freelancer/services/auth_service.dart';
import 'package:go_router/go_router.dart';

import '../../widgets/constant.dart';
import 'auth_ui.dart';

/// Shown after the user opens the password-reset email deep link.
class UpdatePasswordScreen extends StatefulWidget {
  const UpdatePasswordScreen({super.key});

  @override
  State<UpdatePasswordScreen> createState() => _UpdatePasswordScreenState();
}

class _UpdatePasswordScreenState extends State<UpdatePasswordScreen> {
  final _passwordController = TextEditingController();
  final _confirmController = TextEditingController();
  bool _hidePassword = true;
  bool _hideConfirm = true;
  bool _isLoading = false;

  @override
  void dispose() {
    _passwordController.dispose();
    _confirmController.dispose();
    super.dispose();
  }

  Future<void> _handleSave() async {
    final l10n = context.l10n;
    final password = _passwordController.text;
    final confirm = _confirmController.text;

    if (password.length < 6) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(l10n.authPasswordMinLength)),
      );
      return;
    }
    if (password != confirm) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(l10n.authPasswordsDoNotMatch)),
      );
      return;
    }

    setState(() => _isLoading = true);
    try {
      await AuthService.updatePassword(password: password);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(l10n.authPasswordUpdated)),
      );
      final role = await AuthService.getUserRole(forceRefresh: true);
      if (!mounted) return;
      context.go(AuthService.homePathForRole(role));
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(l10n.errorWithDetail(e.toString()))),
      );
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    return Scaffold(
      backgroundColor: kWhite,
      appBar: AppBar(
        elevation: 0,
        automaticallyImplyLeading: false,
        backgroundColor: kDarkWhite,
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.only(
            bottomLeft: Radius.circular(50.0),
            bottomRight: Radius.circular(50.0),
          ),
        ),
        toolbarHeight: 80,
        centerTitle: true,
        title: Text(
          l10n.authUpdatePasswordTitle,
          style: kTextStyle.copyWith(
            color: kNeutralColor,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
      body: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          children: [
            Text(
              l10n.authUpdatePasswordBody,
              style: kTextStyle.copyWith(color: kLightNeutralColor),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24.0),
            AuthTextField(
              controller: _passwordController,
              label: l10n.authNewPassword,
              hint: l10n.authPasswordHint,
              obscureText: _hidePassword,
              textInputAction: TextInputAction.next,
              suffixIcon: IconButton(
                onPressed: () =>
                    setState(() => _hidePassword = !_hidePassword),
                icon: Icon(
                  _hidePassword
                      ? Icons.visibility_off_outlined
                      : Icons.visibility_outlined,
                  color: kLightNeutralColor,
                ),
              ),
            ),
            const SizedBox(height: 16.0),
            AuthTextField(
              controller: _confirmController,
              label: l10n.authConfirmPassword,
              hint: l10n.authPasswordHint,
              obscureText: _hideConfirm,
              textInputAction: TextInputAction.done,
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
            const Spacer(),
            AuthPrimaryButton(
              label: l10n.authSavePassword,
              onPressed: _handleSave,
              accentColor: kPrimaryColor,
              isLoading: _isLoading,
            ),
          ],
        ),
      ),
    );
  }
}
