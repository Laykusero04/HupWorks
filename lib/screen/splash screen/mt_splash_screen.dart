import 'package:flutter/material.dart';
import 'package:freelancer/screen/widgets/constant.dart';

import '../app_config/app_config.dart';

class SplashScreen extends StatelessWidget {
  const SplashScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Scaffold(
        backgroundColor: Colors.black,
        body: Padding(
          padding: const EdgeInsets.only(bottom: 40.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              const Spacer(),
              Image.asset(
                AppInfo.splashLogo,
                height: 220,
                width: 220,
                fit: BoxFit.contain,
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
      ),
    );
  }
}
