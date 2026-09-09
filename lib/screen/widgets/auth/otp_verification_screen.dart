import 'package:flutter/material.dart';
import 'package:freelancer/l10n/l10n.dart';
import 'package:freelancer/screen/widgets/auth/unified_log_in.dart';
import 'package:freelancer/screen/widgets/button_global.dart';
import 'package:freelancer/services/auth_service.dart';
import 'package:nb_utils/nb_utils.dart';

import '../../widgets/constant.dart';

/// Shown after signup when Supabase "Confirm email" is enabled.
/// User must open the link in their email before they can sign in.
class OtpVerificationScreen extends StatefulWidget {
  final String email;

  const OtpVerificationScreen({
    Key? key,
    required this.email,
  }) : super(key: key);

  @override
  State<OtpVerificationScreen> createState() => _OtpVerificationScreenState();
}

class _OtpVerificationScreenState extends State<OtpVerificationScreen> {
  bool _isResending = false;

  Future<void> _resend() async {
    if (_isResending) return;
    setState(() => _isResending = true);
    final l10n = context.l10n;
    try {
      await AuthService.resendSignupConfirmation(email: widget.email);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(l10n.authConfirmEmailResent)),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(l10n.errorWithDetail(e.toString()))),
      );
    } finally {
      if (mounted) setState(() => _isResending = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
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
          l10n.authVerification,
          style: kTextStyle.copyWith(color: kNeutralColor, fontWeight: FontWeight.bold),
        ),
      ),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(20.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            mainAxisAlignment: MainAxisAlignment.start,
            children: [
              const Icon(
                Icons.mark_email_unread_outlined,
                size: 64,
                color: kPrimaryColor,
              ),
              const SizedBox(height: 20.0),
              Text(
                l10n.authConfirmEmailBody,
                textAlign: TextAlign.center,
                style: kTextStyle.copyWith(color: kSubTitleColor),
              ),
              const SizedBox(height: 12.0),
              Text(
                widget.email,
                textAlign: TextAlign.center,
                style: kTextStyle.copyWith(
                  color: kNeutralColor,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 24.0),
              GestureDetector(
                onTap: _isResending ? null : _resend,
                child: RichText(
                  textAlign: TextAlign.center,
                  text: TextSpan(
                    text: '${l10n.authDidntReceiveEmail} ',
                    style: kTextStyle.copyWith(color: kSubTitleColor),
                    children: [
                      TextSpan(
                        text: _isResending
                            ? l10n.sending
                            : l10n.authResendEmail,
                        style: kTextStyle.copyWith(
                          color: kPrimaryColor,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const Spacer(),
              ButtonGlobalWithoutIcon(
                buttontext: l10n.authBackToLogIn,
                buttonDecoration: kButtonDecoration.copyWith(
                  color: kPrimaryColor,
                  borderRadius: BorderRadius.circular(30.0),
                ),
                onPressed: () => const UnifiedLogIn().launch(context),
                buttonTextColor: kWhite,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
