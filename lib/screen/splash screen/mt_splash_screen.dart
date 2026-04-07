import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:freelancer/screen/widgets/constant.dart';

import '../app_config/app_config.dart';
import '../model/purchase_model/purchase_model.dart';
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
    await Future.delayed(const Duration(seconds: 2)).then((value) => checkUser());
  }

  checkUser() async {
    await PurchaseModel().isActiveBuyer().then((value) {
      if (value) {
        Navigator.push(context, MaterialPageRoute(builder: (context) => const OnBoard()));
      } else {
        showDialog(
          context: context,
          builder: (context) => AlertDialog(
            title: Text("Not Active User"),
            content: Text("Please use the valid purchase code to use the app."),
            actions: [
              TextButton(
                onPressed: () {
                  //Exit app
                  if (Platform.isAndroid) {
                    SystemNavigator.pop();
                  } else {
                    exit(0);
                  }
                },
                child: Text("OK"),
              ),
            ],
          ),
        );
      }
    });
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
