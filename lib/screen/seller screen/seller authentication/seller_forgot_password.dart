import 'package:flutter/material.dart';
import 'package:freelancer/screen/widgets/button_global.dart';
import 'package:freelancer/services/auth_service.dart';

import '../../widgets/constant.dart';

class SellerForgotPassword extends StatefulWidget {
  const SellerForgotPassword({Key? key}) : super(key: key);

  @override
  State<SellerForgotPassword> createState() => _SellerForgotPasswordState();
}

class _SellerForgotPasswordState extends State<SellerForgotPassword> {
  final _emailController = TextEditingController();
  bool isLoading = false;

  @override
  void dispose() {
    _emailController.dispose();
    super.dispose();
  }

  Future<void> _handleResetPassword() async {
    final email = _emailController.text.trim();

    if (email.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter your email')),
      );
      return;
    }

    setState(() => isLoading = true);

    try {
      await AuthService.resetPassword(email: email);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Password reset email sent! Check your inbox.')),
        );
        Navigator.pop(context);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(e.toString())),
        );
      }
    } finally {
      if (mounted) setState(() => isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: kWhite,
      appBar: AppBar(
        elevation: 0,
        automaticallyImplyLeading: true,
        iconTheme: const IconThemeData(color: kNeutralColor),
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
          'Forgot Password?',
          style: kTextStyle.copyWith(color: kNeutralColor, fontWeight: FontWeight.bold),
        ),
      ),
      body: Padding(
        padding: const EdgeInsets.all(10.0),
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.all(20.0),
              child: Text(
                'Enter your email address and we will send you a reset link',
                style: kTextStyle.copyWith(color: kLightNeutralColor),
                textAlign: TextAlign.center,
              ),
            ),
            const SizedBox(height: 20.0),
            TextFormField(
              controller: _emailController,
              keyboardType: TextInputType.emailAddress,
              cursorColor: kNeutralColor,
              textInputAction: TextInputAction.done,
              decoration: kInputDecoration.copyWith(
                labelText: 'Email',
                labelStyle: kTextStyle.copyWith(color: kNeutralColor),
                hintText: 'Enter your email',
                hintStyle: kTextStyle.copyWith(color: kLightNeutralColor),
                focusColor: kNeutralColor,
                border: const OutlineInputBorder(),
              ),
            ),
            const Spacer(),
            ButtonGlobalWithoutIcon(
              buttontext: isLoading ? 'Sending...' : 'Reset Password',
              buttonDecoration: kButtonDecoration.copyWith(
                color: isLoading ? kLightNeutralColor : kPrimaryColor,
              ),
              onPressed: isLoading ? null : _handleResetPassword,
              buttonTextColor: kWhite,
            ),
          ],
        ),
      ),
    );
  }
}
