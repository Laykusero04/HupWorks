import 'package:freelancer/core/version/app_build.dart';

class AppInfo {
  ///------------------------app_version--------------------------
  /// Comes from kAppVersionName, which a test keeps equal to pubspec.yaml.
  static const String appVersion = kAppVersionName;

  ///------------------------legal--------------------------------
  /// Public Terms of Service page (NL + EN on the page itself). Single source
  /// for every "Terms" link in the app.
  static const String termsUrl = 'https://hupworks-web.vercel.app/terms.html';

  /// Public Privacy Policy page; the consent text version below refers to it.
  static const String privacyUrl =
      'https://hupworks-web.vercel.app/privacy.html';

  /// Version of the privacy/consent wording shown on the personal-details
  /// step. Bump it when the wording or the linked policy changes materially;
  /// users with an older stored version are asked again (T-0172).
  static const String privacyConsentVersion = 'privacy-2026-11';

  ///------------------------Splash_screen_logo-------------------
  static const String splashLogo = 'images/HupWorks.png';

  ///------------------------logo-------------------
  static const String logo = 'images/HupWorks.png';

  ///------------------------Onboard_Images-----------------------
  /// Hero art still used on login and signup.
  static const String onBoard1 = 'images/onboard1.png';
  static const String onBoard2 = 'images/onboard2.png';
  static const String onBoard3 = 'images/onboard3.png';

  /// One illustration per platform-journey step (signup through ownership).
  static const String onBoardStep1 = 'images/onboarding/onboard1.jpg';
  static const String onBoardStep2 = 'images/onboarding/onboard2.jpg';
  static const String onBoardStep3 = 'images/onboarding/onboard3.jpg';
  static const String onBoardStep4 = 'images/onboarding/onboard4.jpg';
  static const String onBoardStep5 = 'images/onboarding/onboard5.jpg';
  static const String onBoardStep6 = 'images/onboarding/onboard6.jpg';
  static const String onBoardStep7 = 'images/onboarding/onboard7.jpg';
  static const String onBoardStep8 = 'images/onboarding/onboard8.jpg';
  static const String onBoardStep9 = 'images/onboarding/onboard9.jpg';
}

String purchaseCode = '1b9160aa-ecd3-414b-b19c-f40332aacd26';
