import 'package:flutter/material.dart';
import 'package:freelancer/screen/client%20screen/client_authentication/client_log_in.dart';
import 'package:freelancer/screen/seller%20screen/seller%20authentication/seller_log_in.dart';
import 'package:freelancer/screen/widgets/constant.dart';

import '../app_config/app_config.dart';
import '../client screen/client_authentication/client_sign_up.dart';
import '../seller screen/seller authentication/seller_sign_up.dart';
import '../widgets/button_global.dart';

class WelcomeScreen extends StatefulWidget {
  const WelcomeScreen({Key? key}) : super(key: key);

  @override
  State<WelcomeScreen> createState() => _WelcomeScreenState();
}

class _WelcomeScreenState extends State<WelcomeScreen> {
  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Scaffold(
        backgroundColor: kWhite,
        appBar: AppBar(
          elevation: 0,
          automaticallyImplyLeading: false,
          backgroundColor: kDarkWhite,
          shape: const RoundedRectangleBorder(
            borderRadius: BorderRadius.only(
              bottomLeft: Radius.circular(50.0),
              bottomRight: Radius.circular(50.0),
            ),
          ),
          toolbarHeight: 250,
          flexibleSpace: Padding(
            padding: const EdgeInsets.only(top: 20.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.center,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Container(
                  height: 150,
                  width: 150,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(30.0),
                    image: const DecorationImage(image: AssetImage(AppInfo.logo), fit: BoxFit.cover),
                  ),
                )
              ],
            ),
          ),
        ),
        body: Padding(
          padding: const EdgeInsets.all(20.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: Text(
                  'Join as a Client or Freelancer',
                  style: kTextStyle.copyWith(color: kNeutralColor, fontWeight: FontWeight.bold, fontSize: 18.0),
                ),
              ),
              const SizedBox(height: 20.0),
              Card(
                elevation: 1.0,
                shadowColor: kDarkWhite,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8.0),
                ),
                child: Container(
                  padding: const EdgeInsets.only(left: 10.0),
                  decoration: BoxDecoration(
                    color: kWhite,
                    borderRadius: BorderRadius.circular(8.0),
                    boxShadow: const [
                      BoxShadow(
                        color: kBorderColorTextField,
                        spreadRadius: 1.0,
                        blurRadius: 1.0,
                        offset: Offset(0, 0),
                      ),
                    ],
                  ),
                  child: CheckboxListTile(
                    visualDensity: const VisualDensity(vertical: -2),
                    checkboxShape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(30.0),
                    ),
                    contentPadding: EdgeInsets.zero,
                    title: Text(
                      'I\'m a client',
                      style: kTextStyle.copyWith(color: kNeutralColor, fontWeight: FontWeight.bold),
                    ),
                    subtitle: Text(
                      'Looking for help with a project.',
                      style: kTextStyle.copyWith(color: kSubTitleColor),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    secondary: Container(
                      height: 45,
                      width: 45,
                      decoration: BoxDecoration(
                        color: const Color(0xFFCCF2E3),
                        borderRadius: BorderRadius.circular(3.0),
                        image: const DecorationImage(image: AssetImage('images/profile1.png'), fit: BoxFit.cover),
                      ),
                    ),
                    autofocus: false,
                    activeColor: Colors.green,
                    checkColor: Colors.white,
                    selected: !isFreelancer,
                    value: !isFreelancer,
                    onChanged: (value) {
                      setState(() {
                        isFreelancer = !isFreelancer;
                      });
                    },
                  ),
                ),
              ),
              const SizedBox(height: 10.0),
              Card(
                elevation: 1.0,
                shadowColor: kDarkWhite,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8.0),
                ),
                child: Container(
                  padding: const EdgeInsets.only(left: 10.0),
                  decoration: BoxDecoration(
                    color: kWhite,
                    borderRadius: BorderRadius.circular(8.0),
                    boxShadow: const [
                      BoxShadow(
                        color: kBorderColorTextField,
                        spreadRadius: 1.0,
                        blurRadius: 1.0,
                        offset: Offset(0, 0),
                      ),
                    ],
                  ),
                  child: CheckboxListTile(
                    visualDensity: const VisualDensity(vertical: -2),
                    checkboxShape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(30.0),
                    ),
                    contentPadding: EdgeInsets.zero,
                    title: Text(
                      'I\'m a freelancer',
                      style: kTextStyle.copyWith(color: kNeutralColor, fontWeight: FontWeight.bold),
                    ),
                    subtitle: Text(
                      'Looking for my favorite work ',
                      style: kTextStyle.copyWith(color: kSubTitleColor),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    secondary: Container(
                      height: 45,
                      width: 45,
                      decoration: BoxDecoration(
                        color: const Color(0xFFCCF2E3),
                        borderRadius: BorderRadius.circular(3.0),
                        image: const DecorationImage(image: AssetImage('images/profile2.png'), fit: BoxFit.cover),
                      ),
                    ),
                    autofocus: false,
                    activeColor: Colors.green,
                    checkColor: Colors.white,
                    selected: isFreelancer,
                    value: isFreelancer,
                    onChanged: (value) {
                      setState(() {
                        isFreelancer = value!;
                      });
                    },
                  ),
                ),
              ),
              const SizedBox(height: 15.0),
              ButtonGlobalWithoutIcon(
                buttontext: 'Create a Account',
                buttonDecoration: kButtonDecoration.copyWith(
                  color: kPrimaryColor,
                  borderRadius: BorderRadius.circular(30.0),
                ),
                onPressed: () {
                  isFreelancer
                      ? Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => const SellerSignUp(),
                          ),
                        )
                      : Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => const ClientSignUp(),
                          ),
                        );
                },
                buttonTextColor: kWhite,
              ),
              const SizedBox(height: 15.0),
              Center(
                child: GestureDetector(
                  onTap: () {
                    setState(() {
                      isFreelancer
                          ? Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) => const SellerLogIn(),
                              ),
                            )
                          : Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) => const ClientLogIn(),
                              ),
                            );
                    });
                  },
                  child: RichText(
                    text: TextSpan(
                      text: 'Already have an account? ',
                      style: kTextStyle.copyWith(color: kSubTitleColor),
                      children: [
                        TextSpan(
                          text: 'Log In',
                          style: kTextStyle.copyWith(color: kPrimaryColor, fontWeight: FontWeight.bold),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
