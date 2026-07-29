import 'package:flutter/material.dart';
import 'package:freelancer/l10n/l10n.dart';
import 'package:freelancer/screen/widgets/button_global.dart';
import 'package:pinput/pinput.dart';

import '../../widgets/constant.dart';

class OtpVerificationScreen extends StatefulWidget {
  final String email;
  final Widget Function() nextScreenBuilder;

  const OtpVerificationScreen({
    Key? key,
    required this.email,
    required this.nextScreenBuilder,
  }) : super(key: key);

  @override
  State<OtpVerificationScreen> createState() => _OtpVerificationScreenState();
}

class _OtpVerificationScreenState extends State<OtpVerificationScreen> {
  final defaultPinTheme = const PinTheme(
    width: 56,
    height: 56,
    textStyle: TextStyle(fontSize: 20, color: kNeutralColor, fontWeight: FontWeight.w600),
  );

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
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
          l10n.authVerification,
          style: kTextStyle.copyWith(color: kNeutralColor, fontWeight: FontWeight.bold),
        ),
      ),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(20.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            mainAxisAlignment: MainAxisAlignment.start,
            children: [
              Text(
                l10n.authCodeSentToEmail,
                style: kTextStyle.copyWith(color: kSubTitleColor),
              ),
              Text(
                widget.email,
                style: kTextStyle.copyWith(color: kNeutralColor, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 20.0),
              Pinput(
                defaultPinTheme: defaultPinTheme.copyWith(
                  decoration: BoxDecoration(
                    border: Border.all(color: kBorderColorTextField),
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
                focusedPinTheme: defaultPinTheme.copyWith(
                  decoration: BoxDecoration(
                    border: Border.all(color: kNeutralColor),
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
                pinputAutovalidateMode: PinputAutovalidateMode.onSubmit,
                showCursor: true,
              ),
              const SizedBox(height: 20.0),
              Text(
                '00:56',
                style: kTextStyle.copyWith(color: kNeutralColor, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 10.0),
              RichText(
                text: TextSpan(
                  text: '${l10n.authDidntReceiveCode} ',
                  style: kTextStyle.copyWith(color: kSubTitleColor),
                  children: [
                    TextSpan(
                      text: l10n.authResendCode,
                      style: kTextStyle.copyWith(color: kPrimaryColor),
                    ),
                  ],
                ),
              ),
              const Spacer(),
              ButtonGlobalWithoutIcon(
                buttontext: l10n.send,
                buttonDecoration: kButtonDecoration.copyWith(
                  color: kPrimaryColor,
                  borderRadius: BorderRadius.circular(30.0),
                ),
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => widget.nextScreenBuilder(),
                    ),
                  );
                },
                buttonTextColor: kWhite,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
