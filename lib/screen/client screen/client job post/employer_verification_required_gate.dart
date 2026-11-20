import 'package:flutter/material.dart';
import 'package:freelancer/core/utils/employer_verification_gate.dart';
import 'package:freelancer/l10n/l10n.dart';
import 'package:freelancer/screen/widgets/button_global.dart';

import '../../widgets/constant.dart';

/// Shown instead of the "post a job" form while the employer's verification is
/// not approved (T-0171). Pending = "under review"; otherwise "required".
class EmployerVerificationRequiredGate extends StatelessWidget {
  const EmployerVerificationRequiredGate({
    super.key,
    required this.access,
    required this.onVerify,
  });

  final EmployerPostAccess access;
  final Future<void> Function() onVerify;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final pending = access == EmployerPostAccess.pending;
    final title = pending
        ? l10n.employerVerifyPendingTitle
        : l10n.employerVerifyRequiredTitle;
    final body = switch (access) {
      EmployerPostAccess.pending => l10n.employerVerifyPendingBody,
      EmployerPostAccess.rejected => l10n.employerVerifyRejectedBody,
      _ => l10n.employerVerifyRequiredBody,
    };
    return Scaffold(
      backgroundColor: kDarkWhite,
      appBar: AppBar(
        backgroundColor: kDarkWhite,
        elevation: 0,
        iconTheme: const IconThemeData(color: kNeutralColor),
        title: Text(
          l10n.postAJob,
          style: kTextStyle.copyWith(
            color: kNeutralColor,
            fontWeight: FontWeight.bold,
          ),
        ),
        centerTitle: true,
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.only(top: 15),
          child: Container(
            width: double.infinity,
            padding: const EdgeInsets.all(24),
            decoration: const BoxDecoration(
              color: kWhite,
              borderRadius: BorderRadius.vertical(top: Radius.circular(30)),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: SingleChildScrollView(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Icon(
                          pending
                              ? Icons.hourglass_top_rounded
                              : Icons.verified_user_outlined,
                          size: 48,
                          color: kPrimaryColor,
                        ),
                        const SizedBox(height: 16),
                        Text(
                          title,
                          key: const Key('employerVerifyGateTitle'),
                          style: kTextStyle.copyWith(
                            color: kNeutralColor,
                            fontWeight: FontWeight.bold,
                            fontSize: 20,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          body,
                          key: const Key('employerVerifyGateBody'),
                          style: kTextStyle.copyWith(color: kSubTitleColor),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 12),
                ButtonGlobalWithoutIcon(
                  buttontext: pending
                      ? l10n.employerVerifyViewStatusButton
                      : l10n.employerVerifyStartButton,
                  buttonDecoration: kButtonDecoration.copyWith(
                    color: kPrimaryFill,
                    borderRadius: BorderRadius.circular(30),
                  ),
                  onPressed: onVerify,
                  buttonTextColor: kWhite,
                ),
                const SizedBox(height: 12),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// Shown when the verification status could not be loaded (network or server
/// error). Not the "verification required" screen: the employer may well be
/// verified. The server stays the authority on the actual insert.
class EmployerVerificationCheckFailed extends StatelessWidget {
  const EmployerVerificationCheckFailed({super.key, required this.onRetry});

  final Future<void> Function() onRetry;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    return Scaffold(
      backgroundColor: kDarkWhite,
      appBar: AppBar(
        backgroundColor: kDarkWhite,
        elevation: 0,
        iconTheme: const IconThemeData(color: kNeutralColor),
        title: Text(
          l10n.postAJob,
          style: kTextStyle.copyWith(
            color: kNeutralColor,
            fontWeight: FontWeight.bold,
          ),
        ),
        centerTitle: true,
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.only(top: 15),
          child: Container(
            width: double.infinity,
            padding: const EdgeInsets.all(24),
            decoration: const BoxDecoration(
              color: kWhite,
              borderRadius: BorderRadius.vertical(top: Radius.circular(30)),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: SingleChildScrollView(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Icon(Icons.cloud_off_rounded,
                            size: 48, color: kPrimaryColor),
                        const SizedBox(height: 16),
                        Text(
                          l10n.employerVerifyCheckFailedTitle,
                          key: const Key('employerVerifyCheckFailedTitle'),
                          style: kTextStyle.copyWith(
                            color: kNeutralColor,
                            fontWeight: FontWeight.bold,
                            fontSize: 20,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          l10n.employerVerifyCheckFailedBody,
                          style: kTextStyle.copyWith(color: kSubTitleColor),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 12),
                ButtonGlobalWithoutIcon(
                  buttontext: l10n.retry,
                  buttonDecoration: kButtonDecoration.copyWith(
                    color: kPrimaryFill,
                    borderRadius: BorderRadius.circular(30),
                  ),
                  onPressed: onRetry,
                  buttonTextColor: kWhite,
                ),
                const SizedBox(height: 12),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
