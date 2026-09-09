import 'package:flutter/material.dart';
import 'package:freelancer/screen/widgets/auth/otp_verification_screen.dart';

/// After freelancer signup — ask user to confirm email before logging in.
class OtpVerification extends StatelessWidget {
  final String email;
  const OtpVerification({Key? key, required this.email}) : super(key: key);

  @override
  Widget build(BuildContext context) => OtpVerificationScreen(email: email);
}
