import 'package:flutter/material.dart';
import 'package:freelancer/screen/widgets/constant.dart';

import '../app_config/app_config.dart';

class SplashScreen extends StatelessWidget {
  const SplashScreen({super.key});

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
