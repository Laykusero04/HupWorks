import 'package:flutter/material.dart';
import 'package:freelancer/screen/widgets/auth/otp_verification_screen.dart';
import '../setup seller profile/setup_profile.dart';

// Thin wrapper — delegates to OtpVerificationScreen, wiring the next screen
// to SetupSellerProfile.
class OtpVerification extends StatelessWidget {
  final String email;
  const OtpVerification({Key? key, required this.email}) : super(key: key);

  @override
  Widget build(BuildContext context) => OtpVerificationScreen(
        email: email,
        nextScreenBuilder: () => const SetupSellerProfile(),
      );
}
