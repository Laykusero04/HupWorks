import 'package:flutter/material.dart';
import 'package:freelancer/screen/widgets/auth/otp_verification_screen.dart';

/// After client signup — ask user to confirm email before logging in.
class ClientOtpVerification extends StatelessWidget {
  final String email;
  final String role;
  const ClientOtpVerification({
    Key? key,
    required this.email,
    this.role = 'client',
  }) : super(key: key);

  @override
  Widget build(BuildContext context) =>
      OtpVerificationScreen(email: email, role: role);
}
