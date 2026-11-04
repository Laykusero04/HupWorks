import 'dart:async';

import 'package:flutter/material.dart';
import 'package:freelancer/l10n/l10n.dart';
import 'package:freelancer/screen/widgets/button_global.dart';
import 'package:freelancer/services/auth_service.dart';
import 'package:go_router/go_router.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../widgets/constant.dart';

/// Shown after signup when Supabase "Confirm email" is enabled.
/// User must open the link in their email before they can sign in.
class OtpVerificationScreen extends StatefulWidget {
  final String email;
  final String role;

  const OtpVerificationScreen({
    Key? key,
    required this.email,
    required this.role,
  }) : super(key: key);

  @override
  State<OtpVerificationScreen> createState() => _OtpVerificationScreenState();
}

class _OtpVerificationScreenState extends State<OtpVerificationScreen> {
  bool _isResending = false;
  int _cooldown = 0;
  Timer? _cooldownTimer;

  @override
  void dispose() {
    _cooldownTimer?.cancel();
    super.dispose();
  }

  void _startCooldown() {
    _cooldownTimer?.cancel();
    setState(() => _cooldown = 60);
    _cooldownTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (!mounted) {
        timer.cancel();
        return;
      }
      if (_cooldown <= 1) {
        timer.cancel();
        setState(() => _cooldown = 0);
      } else {
        setState(() => _cooldown -= 1);
      }
    });
  }

  Future<void> _resend() async {
    if (_isResending || _cooldown > 0) return;
    setState(() => _isResending = true);
    final l10n = context.l10n;
    try {
      await AuthService.resendSignupConfirmation(email: widget.email);
      if (!mounted) return;
      _startCooldown();
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

  Future<void> _openEmailApp() async {
    final opened = await launchUrl(
      Uri.parse('mailto:'),
      mode: LaunchMode.externalApplication,
    );
    if (!opened && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(context.l10n.somethingWentWrong)),
      );
    }
  }

  void _backToLogin() {
    final route = widget.role == 'seller'
        ? '/auth/seller/login'
        : '/auth/client/login';
    context.go(route);
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
              Text(
                l10n.authDidntReceiveEmail,
                textAlign: TextAlign.center,
                style: kTextStyle.copyWith(color: kSubTitleColor),
              ),
              TextButton(
                onPressed: (_isResending || _cooldown > 0) ? null : _resend,
                child: Text(
                  _isResending
                      ? l10n.sending
                      : _cooldown > 0
                          ? l10n.authResendIn(_cooldown)
                          : l10n.authResendEmail,
                  style: kTextStyle.copyWith(
                    color: (_isResending || _cooldown > 0)
                        ? kLightNeutralColor
                        : kPrimaryColor,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
              const Spacer(),
              ButtonGlobalWithoutIcon(
                buttontext: l10n.openEmailApp,
                buttonDecoration: kButtonDecoration.copyWith(
                  color: kWhite,
                  border: Border.all(color: kPrimaryColor),
                  borderRadius: BorderRadius.circular(30.0),
                ),
                onPressed: _openEmailApp,
                buttonTextColor: kPrimaryColor,
              ),
              const SizedBox(height: 12.0),
              ButtonGlobalWithoutIcon(
                buttontext: l10n.authBackToLogIn,
                buttonDecoration: kButtonDecoration.copyWith(
                  color: kPrimaryColor,
                  borderRadius: BorderRadius.circular(30.0),
                ),
                onPressed: _backToLogin,
                buttonTextColor: kWhite,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
