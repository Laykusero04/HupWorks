import 'package:flutter/material.dart';
import 'package:freelancer/screen/widgets/constant.dart';
import 'package:freelancer/services/auth_service.dart';

import '../app_config/app_config.dart';
import '../client screen/client home/client_home.dart';
import '../seller screen/seller home/seller_home.dart';
import 'onboard.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  @override
  void initState() {
    super.initState();
    init();
  }

  Future<void> init() async {
    await Future.delayed(const Duration(seconds: 2));
    if (!mounted) return;

    if (AuthService.isLoggedIn) {
      // User is already logged in — check role and go to correct home
      try {
        final role = await AuthService.getUserRole();
        if (!mounted) return;

        if (role == 'seller') {
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(builder: (context) => const SellerHome()),
          );
        } else {
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(builder: (context) => const ClientHome()),
          );
        }
      } catch (_) {
        // If role fetch fails, go to onboard
        if (mounted) {
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(builder: (context) => const OnBoard()),
          );
        }
      }
    } else {
      // Not logged in — go to onboarding
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (context) => const OnBoard()),
      );
    }
  }

  @override
  void setState(fn) {
    if (mounted) super.setState(fn);
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Scaffold(
        backgroundColor: kPrimaryColor,
        body: Stack(
          alignment: Alignment.center,
          children: [
            Padding(
              padding: const EdgeInsets.only(bottom: 40.0),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  const Spacer(),
                  Container(
                    height: 180,
                    width: 180,
                    decoration: const BoxDecoration(
                      image: DecorationImage(
                        image: AssetImage(AppInfo.splashLogo),
                        fit: BoxFit.cover,
                      ),
                    ),
                  ),
                  const Spacer(),
                  Column(
                    children: [
                      Text(
                        'Version',
                        style: kTextStyle.copyWith(color: kWhite),
                      ),
                      Text(
                        AppInfo.appVersion,
                        style: kTextStyle.copyWith(color: kWhite, fontWeight: FontWeight.bold),
                      ),
                    ],
                  )
                ],
              ),
            ),
            Container(
              height: 630,
              decoration: const BoxDecoration(
                image: DecorationImage(
                  image: AssetImage('images/bg.png'),
                ),
              ),
            )
          ],
        ),
      ),
    );
  }
}
