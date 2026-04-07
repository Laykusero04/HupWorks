import 'package:flutter/material.dart';
import 'package:freelancer/screen/widgets/button_global.dart';
import 'package:nb_utils/nb_utils.dart';

import '../../widgets/constant.dart';
import 'client_otp_verification.dart';

class ClientForgotPassword extends StatefulWidget {
  const ClientForgotPassword({Key? key}) : super(key: key);

  @override
  State<ClientForgotPassword> createState() => _ClientForgotPasswordState();
}

class _ClientForgotPasswordState extends State<ClientForgotPassword> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: kWhite,
      appBar: AppBar(
        elevation: 0,
        automaticallyImplyLeading: true,
        iconTheme: const IconThemeData(color: kNeutralColor),
        backgroundColor: kDarkWhite,
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.only(
            bottomLeft: Radius.circular(50.0),
            bottomRight: Radius.circular(50.0),
          ),
        ),
        toolbarHeight: 80,
        centerTitle: true,
        title: Text(
          'Forgot Password?',
          style: kTextStyle.copyWith(color: kNeutralColor, fontWeight: FontWeight.bold),
        ),
      ),
      body: Padding(
        padding: const EdgeInsets.all(10.0),
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.all(20.0),
              child: Text(
                'Enter you email address and we will send you code',
                style: kTextStyle.copyWith(color: kLightNeutralColor),
                textAlign: TextAlign.center,
              ),
            ),
            const SizedBox(height: 20.0),
            TextFormField(
              keyboardType: TextInputType.name,
              cursorColor: kNeutralColor,
              textInputAction: TextInputAction.next,
              decoration: kInputDecoration.copyWith(
                labelText: 'Email',
                labelStyle: kTextStyle.copyWith(color: kNeutralColor),
                hintText: 'Enter your email',
                hintStyle: kTextStyle.copyWith(color: kLightNeutralColor),
                focusColor: kNeutralColor,
                border: const OutlineInputBorder(),
              ),
            ),
            const Spacer(),
            ButtonGlobalWithoutIcon(
              buttontext: 'Reset Password',
              buttonDecoration: kButtonDecoration.copyWith(color: kPrimaryColor),
              onPressed: () {
                const ClientOtpVerification().launch(context);
              },
              buttonTextColor: kWhite,
            ),
          ],
        ),
      ),
    );
  }
}
