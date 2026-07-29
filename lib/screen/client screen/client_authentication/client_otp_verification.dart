import 'package:flutter/material.dart';
import 'package:freelancer/screen/widgets/auth/otp_verification_screen.dart';
import 'client_create_profile.dart';

// Thin wrapper — delegates to OtpVerificationScreen, wiring the next screen
// to ClientCreateProfile.
class ClientOtpVerification extends StatelessWidget {
  final String email;
  const ClientOtpVerification({Key? key, required this.email}) : super(key: key);

  @override
  Widget build(BuildContext context) => OtpVerificationScreen(
        email: email,
        nextScreenBuilder: () => const ClientCreateProfile(),
      );
}
