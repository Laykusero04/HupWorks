import 'package:flutter/material.dart';
import 'package:freelancer/l10n/l10n.dart';
import 'package:freelancer/screen/widgets/constant.dart';
import 'package:freelancer/services/auth_service.dart';
import 'package:go_router/go_router.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../core/onboarding/onboarding_prefs.dart';
import '../app_config/app_config.dart';
import 'rubik_logo_loader.dart';

/// Boot splash — stays until the Rubik tile intro finishes (and auth is ready).
class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  static const _maxRoleRetries = 8;

  bool _navigating = false;
  bool _animationDone = false;
  bool _authReady = false;
  bool _roleFailed = false;
  int _roleRetries = 0;

  @override
  void initState() {
    super.initState();
    _warmAuth();
  }

  Future<void> _warmAuth() async {
    if (AuthService.isLoggedIn) {
      try {
        await AuthService.getUserRole();
      } catch (_) {
        // Next screen / retry can recover.
      }
    }
    if (!mounted) return;
    _authReady = true;
    _tryGoNext();
  }

  void _onAnimationCompleted() {
    if (!mounted) return;
    _animationDone = true;
    _tryGoNext();
  }

  void _tryGoNext() {
    if (!_animationDone || !_authReady) return;
    _goNext();
  }

  void _goNext() {
    if (_navigating || !mounted) return;
    _navigating = true;

    final session = Supabase.instance.client.auth.currentSession;
    if (session == null) {
      final seen = OnboardingPrefs.hasSeen;
      context.go(seen ? '/welcome' : '/onboard');
      return;
    }

    final role = AuthService.cachedRole;
    if (role == null) {
      _navigating = false;
      _roleRetries++;
      if (_roleRetries >= _maxRoleRetries) {
        setState(() => _roleFailed = true);
        return;
      }
      Future<void>.delayed(const Duration(milliseconds: 350), () {
        if (mounted) _goNext();
      });
      return;
    }

    context.go(AuthService.homePathForRole(role));
  }

  Future<void> _retryRole() async {
    setState(() {
      _roleFailed = false;
      _roleRetries = 0;
      _authReady = false;
    });
    await _warmAuth();
  }

  Future<void> _signOut() async {
    await AuthService.signOut();
    if (!mounted) return;
    context.go('/welcome');
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    return Scaffold(
      backgroundColor: kWhite,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.only(bottom: 40),
          child: Column(
            children: [
              const Spacer(flex: 3),
              Center(
                child: RubikLogoLoader(
                  size: 228,
                  scrambleMoves: 5,
                  onCompleted: _onAnimationCompleted,
                ),
              ),
              const SizedBox(height: 28),
              Text(
                'HupWorks',
                style: kTextStyle.copyWith(
                  color: kNeutralColor,
                  fontSize: 22,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 0.6,
                ),
              ),
              const SizedBox(height: 8),
              if (_roleFailed) ...[
                Text(
                  l10n.somethingWentWrong,
                  textAlign: TextAlign.center,
                  style: kTextStyle.copyWith(
                    color: kNeutralColor,
                    fontSize: 15,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 16),
                FilledButton(
                  onPressed: _retryRole,
                  style: FilledButton.styleFrom(
                    backgroundColor: kPrimaryColor,
                    foregroundColor: kWhite,
                  ),
                  child: Text(l10n.retry),
                ),
                TextButton(
                  onPressed: _signOut,
                  child: Text(
                    l10n.logOut,
                    style: kTextStyle.copyWith(color: kSubTitleColor),
                  ),
                ),
              ] else
                Text(
                  l10n.splashGettingReady,
                  style: kTextStyle.copyWith(
                    color: kSubTitleColor,
                    fontSize: 13,
                  ),
                ),
              const Spacer(flex: 2),
              Column(
                children: [
                  Text(
                    l10n.splashVersionLabel,
                    style: kTextStyle.copyWith(color: kLightNeutralColor),
                  ),
                  Text(
                    AppInfo.appVersion,
                    style: kTextStyle.copyWith(
                      color: kNeutralColor,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
