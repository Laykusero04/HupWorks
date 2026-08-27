import 'package:flutter/material.dart';
import 'package:freelancer/l10n/l10n.dart';
import 'package:freelancer/screen/widgets/constant.dart';
import 'package:go_router/go_router.dart';

import '../app_config/app_config.dart';

class WelcomeScreen extends StatefulWidget {
  const WelcomeScreen({super.key});

  @override
  State<WelcomeScreen> createState() => _WelcomeScreenState();
}

class _WelcomeScreenState extends State<WelcomeScreen> {
  bool _isFreelancer = false;

  void _goToSignUp() {
    if (_isFreelancer) {
      context.push('/auth/seller/signup');
    } else {
      context.push('/auth/client/signup');
    }
  }

  void _goToLogin() {
    context.push('/auth/seller/login');
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final bottom = MediaQuery.paddingOf(context).bottom;

    return Scaffold(
      backgroundColor: kDarkWhite,
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: EdgeInsets.fromLTRB(24, 16, 24, 16 + bottom),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                ClipRRect(
                  borderRadius: BorderRadius.circular(24),
                  child: ColoredBox(
                    color: Colors.black,
                    child: Image.asset(
                      AppInfo.logo,
                      height: 140,
                      width: 140,
                      fit: BoxFit.contain,
                    ),
                  ),
                ),
                const SizedBox(height: 28),
                Container(
                  width: double.infinity,
                  constraints: const BoxConstraints(maxWidth: 400),
                  padding: const EdgeInsets.fromLTRB(24, 28, 24, 24),
                  decoration: BoxDecoration(
                    color: kWhite,
                    borderRadius: BorderRadius.circular(28),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.06),
                        blurRadius: 24,
                        offset: const Offset(0, 8),
                      ),
                    ],
                  ),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Text(
                        l10n.authWelcomeHowToUse,
                        textAlign: TextAlign.center,
                        style: kTextStyle.copyWith(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 24),
                      Row(
                        children: [
                          Expanded(
                            child: _ChoiceCard(
                              label: l10n.authRoleClient,
                              hint: l10n.authRoleClientSubtitle,
                              icon: Icons.person_outline_rounded,
                              color: kPrimaryColor,
                              selected: !_isFreelancer,
                              onTap: () =>
                                  setState(() => _isFreelancer = false),
                            ),
                          ),
                          const SizedBox(width: 14),
                          Expanded(
                            child: _ChoiceCard(
                              label: l10n.authRoleFreelancer,
                              hint: l10n.authRoleFreelancerSubtitle,
                              icon: Icons.work_outline_rounded,
                              color: kSecondaryColor,
                              selected: _isFreelancer,
                              onTap: () =>
                                  setState(() => _isFreelancer = true),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 28),
                      SizedBox(
                        width: double.infinity,
                        height: 52,
                        child: FilledButton(
                          onPressed: _goToSignUp,
                          style: FilledButton.styleFrom(
                            backgroundColor: kPrimaryColor,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(14),
                            ),
                          ),
                          child: Text(
                            _isFreelancer
                                ? l10n.authContinueAsFreelancer
                                : l10n.authContinueAsClient,
                            style: kTextStyle.copyWith(
                              color: kWhite,
                              fontWeight: FontWeight.w600,
                              fontSize: 16,
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(height: 12),
                      SizedBox(
                        width: double.infinity,
                        height: 52,
                        child: OutlinedButton(
                          onPressed: _goToLogin,
                          style: OutlinedButton.styleFrom(
                            foregroundColor: kNeutralColor,
                            side: const BorderSide(color: kBorderColorTextField),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(14),
                            ),
                          ),
                          child: Text(
                            l10n.authAlreadyHaveAccount,
                            style: kTextStyle.copyWith(
                              fontWeight: FontWeight.w600,
                              fontSize: 15,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _ChoiceCard extends StatelessWidget {
  const _ChoiceCard({
    required this.label,
    required this.hint,
    required this.icon,
    required this.color,
    required this.selected,
    required this.onTap,
  });

  final String label;
  final String hint;
  final IconData icon;
  final Color color;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          padding: const EdgeInsets.symmetric(vertical: 24, horizontal: 12),
          decoration: BoxDecoration(
            color: selected ? color.withValues(alpha: 0.1) : kWhite,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: selected ? color : kBorderColorTextField,
              width: selected ? 2 : 1,
            ),
          ),
          child: Column(
            children: [
              Icon(
                icon,
                size: 36,
                color: selected ? color : kLightNeutralColor,
              ),
              const SizedBox(height: 12),
              Text(
                label,
                style: kTextStyle.copyWith(
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                  color: selected ? color : kNeutralColor,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                hint,
                textAlign: TextAlign.center,
                style: kTextStyle.copyWith(
                  fontSize: 12,
                  color: kSubTitleColor,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
