import 'package:flutter/material.dart';
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
  bool _navigating = false;
  bool _animationDone = false;
  bool _authReady = false;

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
      // Role still loading — keep splash until it arrives.
      _navigating = false;
      Future<void>.delayed(const Duration(milliseconds: 350), () {
        if (mounted) _goNext();
      });
      return;
    }

    context.go(AuthService.homePathForRole(role));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
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
                  color: kWhite,
                  fontSize: 22,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 0.6,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'Getting things ready…',
                style: kTextStyle.copyWith(
                  color: kWhite.withValues(alpha: 0.55),
                  fontSize: 13,
                ),
              ),
              const Spacer(flex: 2),
              Column(
                children: [
                  Text(
                    'Version',
                    style: kTextStyle.copyWith(color: kWhite.withValues(alpha: 0.7)),
                  ),
                  Text(
                    AppInfo.appVersion,
                    style: kTextStyle.copyWith(
                      color: kWhite,
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
