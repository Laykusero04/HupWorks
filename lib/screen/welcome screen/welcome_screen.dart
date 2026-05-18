import 'package:flutter/material.dart';
import 'package:freelancer/screen/widgets/auth/unified_log_in.dart';
import 'package:freelancer/screen/widgets/constant.dart';

import '../app_config/app_config.dart';
import '../client screen/client_authentication/client_sign_up.dart';
import '../seller screen/seller authentication/seller_sign_up.dart';

class WelcomeScreen extends StatefulWidget {
  const WelcomeScreen({super.key});

  @override
  State<WelcomeScreen> createState() => _WelcomeScreenState();
}

class _WelcomeScreenState extends State<WelcomeScreen> {
  void _goToSignUp() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) =>
            isFreelancer ? const SellerSignUp() : const ClientSignUp(),
      ),
    );
  }

  void _goToLogin() {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => const UnifiedLogIn()),
    );
  }

  @override
  Widget build(BuildContext context) {
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
                  child: Image.asset(
                    AppInfo.logo,
                    height: 96,
                    width: 96,
                    fit: BoxFit.cover,
                  ),
                ),
                const SizedBox(height: 12),
                Text(
                  'HupWorks',
                  style: kTextStyle.copyWith(
                    fontWeight: FontWeight.bold,
                    fontSize: 22,
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
                        'How will you use HupWorks?',
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
                              label: 'Client',
                              hint: 'Hire talent',
                              icon: Icons.person_outline_rounded,
                              color: kPrimaryColor,
                              selected: !isFreelancer,
                              onTap: () =>
                                  setState(() => isFreelancer = false),
                            ),
                          ),
                          const SizedBox(width: 14),
                          Expanded(
                            child: _ChoiceCard(
                              label: 'Freelancer',
                              hint: 'Find work',
                              icon: Icons.work_outline_rounded,
                              color: kSecondaryColor,
                              selected: isFreelancer,
                              onTap: () =>
                                  setState(() => isFreelancer = true),
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
                            isFreelancer
                                ? 'Continue as Freelancer'
                                : 'Continue as Client',
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
                            'I already have an account',
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
