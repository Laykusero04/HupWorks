import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:intl/intl.dart' as intl;

import 'app_localizations_bn.dart';
import 'app_localizations_en.dart';
import 'app_localizations_nl.dart';

// ignore_for_file: type=lint

/// Callers can lookup localized strings with an instance of AppLocalizations
/// returned by `AppLocalizations.of(context)`.
///
/// Applications need to include `AppLocalizations.delegate()` in their app's
/// `localizationDelegates` list, and the locales they support in the app's
/// `supportedLocales` list. For example:
///
/// ```dart
/// import 'l10n/app_localizations.dart';
///
/// return MaterialApp(
///   localizationsDelegates: AppLocalizations.localizationsDelegates,
///   supportedLocales: AppLocalizations.supportedLocales,
///   home: MyApplicationHome(),
/// );
/// ```
///
/// ## Update pubspec.yaml
///
/// Please make sure to update your pubspec.yaml to include the following
/// packages:
///
/// ```yaml
/// dependencies:
///   # Internationalization support.
///   flutter_localizations:
///     sdk: flutter
///   intl: any # Use the pinned version from flutter_localizations
///
///   # Rest of dependencies
/// ```
///
/// ## iOS Applications
///
/// iOS applications define key application metadata, including supported
/// locales, in an Info.plist file that is built into the application bundle.
/// To configure the locales supported by your app, you’ll need to edit this
/// file.
///
/// First, open your project’s ios/Runner.xcworkspace Xcode workspace file.
/// Then, in the Project Navigator, open the Info.plist file under the Runner
/// project’s Runner folder.
///
/// Next, select the Information Property List item, select Add Item from the
/// Editor menu, then select Localizations from the pop-up menu.
///
/// Select and expand the newly-created Localizations item then, for each
/// locale your application supports, add a new item and select the locale
/// you wish to add from the pop-up menu in the Value field. This list should
/// be consistent with the languages listed in the AppLocalizations.supportedLocales
/// property.
abstract class AppLocalizations {
  AppLocalizations(String locale)
      : localeName = intl.Intl.canonicalizedLocale(locale.toString());

  final String localeName;

  static AppLocalizations of(BuildContext context) {
    return Localizations.of<AppLocalizations>(context, AppLocalizations)!;
  }

  static const LocalizationsDelegate<AppLocalizations> delegate =
      _AppLocalizationsDelegate();

  /// A list of this localizations delegate along with the default localizations
  /// delegates.
  ///
  /// Returns a list of localizations delegates containing this delegate along with
  /// GlobalMaterialLocalizations.delegate, GlobalCupertinoLocalizations.delegate,
  /// and GlobalWidgetsLocalizations.delegate.
  ///
  /// Additional delegates can be added by appending to this list in
  /// MaterialApp. This list does not have to be used at all if a custom list
  /// of delegates is preferred or required.
  static const List<LocalizationsDelegate<dynamic>> localizationsDelegates =
      <LocalizationsDelegate<dynamic>>[
    delegate,
    GlobalMaterialLocalizations.delegate,
    GlobalCupertinoLocalizations.delegate,
    GlobalWidgetsLocalizations.delegate,
  ];

  /// A list of this localizations delegate's supported locales.
  static const List<Locale> supportedLocales = <Locale>[
    Locale('bn'),
    Locale('en'),
    Locale('nl')
  ];

  /// No description provided for @appTitle.
  ///
  /// In en, this message translates to:
  /// **'HupWorks'**
  String get appTitle;

  /// No description provided for @language.
  ///
  /// In en, this message translates to:
  /// **'Language'**
  String get language;

  /// No description provided for @languageEnglish.
  ///
  /// In en, this message translates to:
  /// **'English'**
  String get languageEnglish;

  /// No description provided for @languageBengali.
  ///
  /// In en, this message translates to:
  /// **'Bengali'**
  String get languageBengali;

  /// No description provided for @languageDutch.
  ///
  /// In en, this message translates to:
  /// **'Dutch'**
  String get languageDutch;

  /// No description provided for @languageChanged.
  ///
  /// In en, this message translates to:
  /// **'Language updated'**
  String get languageChanged;

  /// No description provided for @cancel.
  ///
  /// In en, this message translates to:
  /// **'Cancel'**
  String get cancel;

  /// No description provided for @save.
  ///
  /// In en, this message translates to:
  /// **'Save'**
  String get save;

  /// No description provided for @send.
  ///
  /// In en, this message translates to:
  /// **'Send'**
  String get send;

  /// No description provided for @share.
  ///
  /// In en, this message translates to:
  /// **'Share'**
  String get share;

  /// No description provided for @retry.
  ///
  /// In en, this message translates to:
  /// **'Retry'**
  String get retry;

  /// No description provided for @done.
  ///
  /// In en, this message translates to:
  /// **'Done'**
  String get done;

  /// No description provided for @back.
  ///
  /// In en, this message translates to:
  /// **'Back'**
  String get back;

  /// No description provided for @add.
  ///
  /// In en, this message translates to:
  /// **'Add'**
  String get add;

  /// No description provided for @seeAll.
  ///
  /// In en, this message translates to:
  /// **'See all'**
  String get seeAll;

  /// No description provided for @viewAll.
  ///
  /// In en, this message translates to:
  /// **'View all'**
  String get viewAll;

  /// No description provided for @explore.
  ///
  /// In en, this message translates to:
  /// **'Explore'**
  String get explore;

  /// No description provided for @other.
  ///
  /// In en, this message translates to:
  /// **'Other'**
  String get other;

  /// No description provided for @unknown.
  ///
  /// In en, this message translates to:
  /// **'Unknown'**
  String get unknown;

  /// No description provided for @notSpecified.
  ///
  /// In en, this message translates to:
  /// **'Not specified'**
  String get notSpecified;

  /// No description provided for @aboutUs.
  ///
  /// In en, this message translates to:
  /// **'About Us'**
  String get aboutUs;

  /// No description provided for @privacyPolicy.
  ///
  /// In en, this message translates to:
  /// **'Privacy Policy'**
  String get privacyPolicy;

  /// No description provided for @invite.
  ///
  /// In en, this message translates to:
  /// **'Invite'**
  String get invite;

  /// No description provided for @inviteFriends.
  ///
  /// In en, this message translates to:
  /// **'Invite friends'**
  String get inviteFriends;

  /// No description provided for @inviteBody.
  ///
  /// In en, this message translates to:
  /// **'Share your personal invite code so friends can join HupWorks. Referral rewards are not available yet.'**
  String get inviteBody;

  /// No description provided for @inviteCodeCopied.
  ///
  /// In en, this message translates to:
  /// **'Invite code copied'**
  String get inviteCodeCopied;

  /// No description provided for @inviteSignInRequired.
  ///
  /// In en, this message translates to:
  /// **'Sign in to get your invite code.'**
  String get inviteSignInRequired;

  /// No description provided for @shareInvite.
  ///
  /// In en, this message translates to:
  /// **'Share invite'**
  String get shareInvite;

  /// No description provided for @report.
  ///
  /// In en, this message translates to:
  /// **'Report'**
  String get report;

  /// No description provided for @reportSubmitted.
  ///
  /// In en, this message translates to:
  /// **'Report submitted. Thank you.'**
  String get reportSubmitted;

  /// No description provided for @searchHint.
  ///
  /// In en, this message translates to:
  /// **'Search services or freelancers'**
  String get searchHint;

  /// No description provided for @popularServices.
  ///
  /// In en, this message translates to:
  /// **'Popular services'**
  String get popularServices;

  /// No description provided for @topFreelancers.
  ///
  /// In en, this message translates to:
  /// **'Top freelancers'**
  String get topFreelancers;

  /// No description provided for @services.
  ///
  /// In en, this message translates to:
  /// **'Services'**
  String get services;

  /// No description provided for @freelancers.
  ///
  /// In en, this message translates to:
  /// **'Freelancers'**
  String get freelancers;

  /// No description provided for @noSearchResults.
  ///
  /// In en, this message translates to:
  /// **'No services or freelancers match \"{query}\"'**
  String noSearchResults(String query);

  /// No description provided for @noPopularResults.
  ///
  /// In en, this message translates to:
  /// **'No popular results yet'**
  String get noPopularResults;

  /// No description provided for @couldNotLoadResults.
  ///
  /// In en, this message translates to:
  /// **'Could not load results'**
  String get couldNotLoadResults;

  /// No description provided for @home.
  ///
  /// In en, this message translates to:
  /// **'Home'**
  String get home;

  /// No description provided for @settings.
  ///
  /// In en, this message translates to:
  /// **'Setting'**
  String get settings;

  /// No description provided for @helpSupport.
  ///
  /// In en, this message translates to:
  /// **'Help & Support'**
  String get helpSupport;

  /// No description provided for @logOut.
  ///
  /// In en, this message translates to:
  /// **'Log Out'**
  String get logOut;

  /// No description provided for @logOutConfirmTitle.
  ///
  /// In en, this message translates to:
  /// **'Log out?'**
  String get logOutConfirmTitle;

  /// No description provided for @logOutConfirmBody.
  ///
  /// In en, this message translates to:
  /// **'You\'ll need to sign in again to use your account.'**
  String get logOutConfirmBody;

  /// No description provided for @sellerReport.
  ///
  /// In en, this message translates to:
  /// **'Seller Report'**
  String get sellerReport;

  /// No description provided for @favorite.
  ///
  /// In en, this message translates to:
  /// **'Save'**
  String get favorite;

  /// No description provided for @transaction.
  ///
  /// In en, this message translates to:
  /// **'Transaction'**
  String get transaction;

  /// No description provided for @saving.
  ///
  /// In en, this message translates to:
  /// **'Saving...'**
  String get saving;

  /// No description provided for @sending.
  ///
  /// In en, this message translates to:
  /// **'Sending...'**
  String get sending;

  /// No description provided for @profileUpdated.
  ///
  /// In en, this message translates to:
  /// **'Profile updated successfully!'**
  String get profileUpdated;

  /// No description provided for @pleaseEnterName.
  ///
  /// In en, this message translates to:
  /// **'Please enter your name'**
  String get pleaseEnterName;

  /// No description provided for @createProfile.
  ///
  /// In en, this message translates to:
  /// **'Create Profile'**
  String get createProfile;

  /// No description provided for @completeYourProfileTitle.
  ///
  /// In en, this message translates to:
  /// **'Complete your profile'**
  String get completeYourProfileTitle;

  /// No description provided for @completeYourProfileBody.
  ///
  /// In en, this message translates to:
  /// **'Add a photo and contact details so freelancers trust your jobs.'**
  String get completeYourProfileBody;

  /// No description provided for @completeProfileAction.
  ///
  /// In en, this message translates to:
  /// **'Complete profile'**
  String get completeProfileAction;

  /// No description provided for @skipForNow.
  ///
  /// In en, this message translates to:
  /// **'Skip for now'**
  String get skipForNow;

  /// No description provided for @setupProfile.
  ///
  /// In en, this message translates to:
  /// **'Setup Profile'**
  String get setupProfile;

  /// No description provided for @saveProfile.
  ///
  /// In en, this message translates to:
  /// **'Save Profile'**
  String get saveProfile;

  /// No description provided for @continueLabel.
  ///
  /// In en, this message translates to:
  /// **'Continue'**
  String get continueLabel;

  /// No description provided for @errorGeneric.
  ///
  /// In en, this message translates to:
  /// **'Something went wrong. Please try again.'**
  String get errorGeneric;

  /// No description provided for @errorWithDetail.
  ///
  /// In en, this message translates to:
  /// **'Error: {message}'**
  String errorWithDetail(String message);

  /// No description provided for @errorLoading.
  ///
  /// In en, this message translates to:
  /// **'Could not load data'**
  String get errorLoading;

  /// No description provided for @couldNotOpenChat.
  ///
  /// In en, this message translates to:
  /// **'Could not open chat'**
  String get couldNotOpenChat;

  /// No description provided for @pleaseFillAllFields.
  ///
  /// In en, this message translates to:
  /// **'Please fill in all fields'**
  String get pleaseFillAllFields;

  /// No description provided for @pushNotifications.
  ///
  /// In en, this message translates to:
  /// **'Push Notifications'**
  String get pushNotifications;

  /// No description provided for @pushNotificationsPermissionDenied.
  ///
  /// In en, this message translates to:
  /// **'Notification permission was denied. Enable it in system settings to receive alerts.'**
  String get pushNotificationsPermissionDenied;

  /// No description provided for @notifications.
  ///
  /// In en, this message translates to:
  /// **'Notifications'**
  String get notifications;

  /// No description provided for @message.
  ///
  /// In en, this message translates to:
  /// **'Message'**
  String get message;

  /// No description provided for @contracts.
  ///
  /// In en, this message translates to:
  /// **'Contracts'**
  String get contracts;

  /// No description provided for @findJobs.
  ///
  /// In en, this message translates to:
  /// **'Find Jobs'**
  String get findJobs;

  /// No description provided for @myJobs.
  ///
  /// In en, this message translates to:
  /// **'My Jobs'**
  String get myJobs;

  /// No description provided for @talent.
  ///
  /// In en, this message translates to:
  /// **'Talent'**
  String get talent;

  /// No description provided for @justNow.
  ///
  /// In en, this message translates to:
  /// **'Just now'**
  String get justNow;

  /// No description provided for @readAll.
  ///
  /// In en, this message translates to:
  /// **'Read All'**
  String get readAll;

  /// No description provided for @noNotifications.
  ///
  /// In en, this message translates to:
  /// **'No notifications'**
  String get noNotifications;

  /// No description provided for @minutesAgo.
  ///
  /// In en, this message translates to:
  /// **'{count}m ago'**
  String minutesAgo(int count);

  /// No description provided for @hoursAgo.
  ///
  /// In en, this message translates to:
  /// **'{count}h ago'**
  String hoursAgo(int count);

  /// No description provided for @daysAgo.
  ///
  /// In en, this message translates to:
  /// **'{count}d ago'**
  String daysAgo(int count);

  /// No description provided for @orderStatusActive.
  ///
  /// In en, this message translates to:
  /// **'Active'**
  String get orderStatusActive;

  /// No description provided for @orderStatusPending.
  ///
  /// In en, this message translates to:
  /// **'Pending'**
  String get orderStatusPending;

  /// No description provided for @orderStatusCompleted.
  ///
  /// In en, this message translates to:
  /// **'Completed'**
  String get orderStatusCompleted;

  /// No description provided for @orderStatusCancelled.
  ///
  /// In en, this message translates to:
  /// **'Cancelled'**
  String get orderStatusCancelled;

  /// No description provided for @orderStatusDelivered.
  ///
  /// In en, this message translates to:
  /// **'Delivered'**
  String get orderStatusDelivered;

  /// No description provided for @orderStatusCancellationPending.
  ///
  /// In en, this message translates to:
  /// **'Cancellation pending'**
  String get orderStatusCancellationPending;

  /// No description provided for @reportReasonNonOriginal.
  ///
  /// In en, this message translates to:
  /// **'Non original content'**
  String get reportReasonNonOriginal;

  /// No description provided for @reportReasonTrademark.
  ///
  /// In en, this message translates to:
  /// **'Trademark Violations'**
  String get reportReasonTrademark;

  /// No description provided for @reportReasonCopyright.
  ///
  /// In en, this message translates to:
  /// **'Copyright Violations'**
  String get reportReasonCopyright;

  /// No description provided for @reportReasonOther.
  ///
  /// In en, this message translates to:
  /// **'Other reasons'**
  String get reportReasonOther;

  /// No description provided for @reportReasonHarassment.
  ///
  /// In en, this message translates to:
  /// **'Harassment or inappropriate behavior'**
  String get reportReasonHarassment;

  /// No description provided for @reportReasonFakeJob.
  ///
  /// In en, this message translates to:
  /// **'Fake or misleading job'**
  String get reportReasonFakeJob;

  /// No description provided for @reportReasonNoShow.
  ///
  /// In en, this message translates to:
  /// **'No-show or incomplete work'**
  String get reportReasonNoShow;

  /// No description provided for @reportReasonPaymentDispute.
  ///
  /// In en, this message translates to:
  /// **'Payment or contract dispute'**
  String get reportReasonPaymentDispute;

  /// No description provided for @reportReasonSpam.
  ///
  /// In en, this message translates to:
  /// **'Spam or scam'**
  String get reportReasonSpam;

  /// No description provided for @reportDetailsTooShort.
  ///
  /// In en, this message translates to:
  /// **'Please describe the issue (at least 10 characters).'**
  String get reportDetailsTooShort;

  /// No description provided for @reportDetailsHelp.
  ///
  /// In en, this message translates to:
  /// **'Include what happened, when, and any messages or job details that help us review.'**
  String get reportDetailsHelp;

  /// No description provided for @reportOpenFromContextHint.
  ///
  /// In en, this message translates to:
  /// **'Tip: open Report from a chat, job, or contract to link the other person automatically.'**
  String get reportOpenFromContextHint;

  /// No description provided for @reportReportingUser.
  ///
  /// In en, this message translates to:
  /// **'Reporting: {name}'**
  String reportReportingUser(String name);

  /// No description provided for @reportReportingJob.
  ///
  /// In en, this message translates to:
  /// **'Job: {title}'**
  String reportReportingJob(String title);

  /// No description provided for @reportReportingContract.
  ///
  /// In en, this message translates to:
  /// **'Linked to this contract'**
  String get reportReportingContract;

  /// No description provided for @cancelReasonScheduleConflict.
  ///
  /// In en, this message translates to:
  /// **'Schedule conflict'**
  String get cancelReasonScheduleConflict;

  /// No description provided for @cancelReasonScopeMismatch.
  ///
  /// In en, this message translates to:
  /// **'Scope does not match agreement'**
  String get cancelReasonScopeMismatch;

  /// No description provided for @cancelReasonSiteOrSafety.
  ///
  /// In en, this message translates to:
  /// **'Site or safety concern'**
  String get cancelReasonSiteOrSafety;

  /// No description provided for @cancelReasonPersonalEmergency.
  ///
  /// In en, this message translates to:
  /// **'Personal emergency'**
  String get cancelReasonPersonalEmergency;

  /// No description provided for @cancelReasonClientIssue.
  ///
  /// In en, this message translates to:
  /// **'Issue with client / communication'**
  String get cancelReasonClientIssue;

  /// No description provided for @cancelReasonOther.
  ///
  /// In en, this message translates to:
  /// **'Other'**
  String get cancelReasonOther;

  /// No description provided for @attendanceModeQrInOut.
  ///
  /// In en, this message translates to:
  /// **'QR clock in & out'**
  String get attendanceModeQrInOut;

  /// No description provided for @attendanceModeQrOnce.
  ///
  /// In en, this message translates to:
  /// **'QR check-in (once per day)'**
  String get attendanceModeQrOnce;

  /// No description provided for @attendanceModeSelfReport.
  ///
  /// In en, this message translates to:
  /// **'Self-report in app'**
  String get attendanceModeSelfReport;

  /// No description provided for @attendanceModeDisabled.
  ///
  /// In en, this message translates to:
  /// **'Attendance off'**
  String get attendanceModeDisabled;

  /// No description provided for @attendanceClientHintQrInOut.
  ///
  /// In en, this message translates to:
  /// **'Post a QR at the site. Workers scan to clock in and clock out.'**
  String get attendanceClientHintQrInOut;

  /// No description provided for @attendanceClientHintQrOnce.
  ///
  /// In en, this message translates to:
  /// **'Post a QR at the site. Workers scan once per day to check in.'**
  String get attendanceClientHintQrOnce;

  /// No description provided for @attendanceClientHintSelfReport.
  ///
  /// In en, this message translates to:
  /// **'Workers clock in and out in the app — no QR needed.'**
  String get attendanceClientHintSelfReport;

  /// No description provided for @attendanceClientHintDisabled.
  ///
  /// In en, this message translates to:
  /// **'Attendance tracking is turned off for this job.'**
  String get attendanceClientHintDisabled;

  /// No description provided for @attendanceFreelancerHintQrInOut.
  ///
  /// In en, this message translates to:
  /// **'Scan the site QR to clock in and clock out.'**
  String get attendanceFreelancerHintQrInOut;

  /// No description provided for @attendanceFreelancerHintQrOnce.
  ///
  /// In en, this message translates to:
  /// **'Scan the site QR once when you arrive.'**
  String get attendanceFreelancerHintQrOnce;

  /// No description provided for @attendanceFreelancerHintSelfReport.
  ///
  /// In en, this message translates to:
  /// **'Tap clock in when you start and clock out when you leave.'**
  String get attendanceFreelancerHintSelfReport;

  /// No description provided for @attendanceFreelancerHintDisabled.
  ///
  /// In en, this message translates to:
  /// **'Your client has not enabled attendance for this job.'**
  String get attendanceFreelancerHintDisabled;

  /// No description provided for @attendanceOnboardingQrInOut.
  ///
  /// In en, this message translates to:
  /// **'Open Attendance in HupWorks and scan the QR code at the job site to clock in when you arrive and clock out when you leave.'**
  String get attendanceOnboardingQrInOut;

  /// No description provided for @attendanceOnboardingQrOnce.
  ///
  /// In en, this message translates to:
  /// **'When you arrive, open Attendance in HupWorks and scan the QR code posted on site. You only need to check in once per day.'**
  String get attendanceOnboardingQrOnce;

  /// No description provided for @attendanceOnboardingSelfReport.
  ///
  /// In en, this message translates to:
  /// **'Open Attendance in HupWorks on this contract and tap Clock in when you start and Clock out when you leave. No QR scan is required.'**
  String get attendanceOnboardingSelfReport;

  /// No description provided for @attendanceOnboardingDisabled.
  ///
  /// In en, this message translates to:
  /// **'Attendance is not tracked in the app for this job. Follow your supervisor\'s instructions on site.'**
  String get attendanceOnboardingDisabled;

  /// No description provided for @attendanceTracking.
  ///
  /// In en, this message translates to:
  /// **'Attendance tracking'**
  String get attendanceTracking;

  /// No description provided for @attendanceTrackingHint.
  ///
  /// In en, this message translates to:
  /// **'How workers record time on site.'**
  String get attendanceTrackingHint;

  /// No description provided for @genderMale.
  ///
  /// In en, this message translates to:
  /// **'Male'**
  String get genderMale;

  /// No description provided for @genderFemale.
  ///
  /// In en, this message translates to:
  /// **'Female'**
  String get genderFemale;

  /// No description provided for @aboutHupWorksTitle.
  ///
  /// In en, this message translates to:
  /// **'About HupWorks'**
  String get aboutHupWorksTitle;

  /// No description provided for @aboutHupWorksBody.
  ///
  /// In en, this message translates to:
  /// **'HupWorks is a marketplace that connects clients with freelancers and local workers for jobs and services. We help people post work, hire talent, track attendance on-site, and manage orders from start to finish.\n\nOur goal is to make hiring and getting hired simpler, clearer, and more reliable—whether you need skilled help for a project or want to grow your freelance business.'**
  String get aboutHupWorksBody;

  /// No description provided for @privacySectionCollectTitle.
  ///
  /// In en, this message translates to:
  /// **'Information We Collect'**
  String get privacySectionCollectTitle;

  /// No description provided for @privacySectionCollectBody.
  ///
  /// In en, this message translates to:
  /// **'We collect account details you provide (such as name, email, phone, and profile information), content you post (jobs, messages, reviews), and technical data needed to operate the app (device and usage information). Payment-related data is processed by our payment providers when those features are enabled.'**
  String get privacySectionCollectBody;

  /// No description provided for @privacySectionUseTitle.
  ///
  /// In en, this message translates to:
  /// **'How We Use Information'**
  String get privacySectionUseTitle;

  /// No description provided for @privacySectionUseBody.
  ///
  /// In en, this message translates to:
  /// **'We use your information to create and manage your account, show relevant jobs and profiles, enable messaging and order workflows, improve safety and reliability, and communicate important service updates. We do not sell your personal information.'**
  String get privacySectionUseBody;

  /// No description provided for @privacySectionShareTitle.
  ///
  /// In en, this message translates to:
  /// **'Sharing of Information'**
  String get privacySectionShareTitle;

  /// No description provided for @privacySectionShareBody.
  ///
  /// In en, this message translates to:
  /// **'We share information with other users only as needed for the marketplace (for example, your public profile and messages you send). We may share data with service providers who help us run HupWorks, or when required by law, to protect rights and safety, or to investigate fraud or abuse.'**
  String get privacySectionShareBody;

  /// No description provided for @privacySectionChoicesTitle.
  ///
  /// In en, this message translates to:
  /// **'Your Choices'**
  String get privacySectionChoicesTitle;

  /// No description provided for @privacySectionChoicesBody.
  ///
  /// In en, this message translates to:
  /// **'You can update profile details in the app and contact support to request account changes. Depending on your location, you may have additional rights to access, correct, or delete personal data.'**
  String get privacySectionChoicesBody;

  /// No description provided for @privacySectionContactTitle.
  ///
  /// In en, this message translates to:
  /// **'Contact'**
  String get privacySectionContactTitle;

  /// No description provided for @privacySectionContactBody.
  ///
  /// In en, this message translates to:
  /// **'If you have questions about this policy or your data, reach us through Help & Support in the app.'**
  String get privacySectionContactBody;

  /// No description provided for @appOnboardSkip.
  ///
  /// In en, this message translates to:
  /// **'Skip'**
  String get appOnboardSkip;

  /// No description provided for @appOnboardNext.
  ///
  /// In en, this message translates to:
  /// **'Next'**
  String get appOnboardNext;

  /// No description provided for @appOnboardGetStarted.
  ///
  /// In en, this message translates to:
  /// **'Get started'**
  String get appOnboardGetStarted;

  /// No description provided for @appOnboardLanguageTitle.
  ///
  /// In en, this message translates to:
  /// **'Choose your language'**
  String get appOnboardLanguageTitle;

  /// No description provided for @appOnboardLanguageSubtitle.
  ///
  /// In en, this message translates to:
  /// **'We\'ll show the app in the language you pick. You can change it later in Settings.'**
  String get appOnboardLanguageSubtitle;

  /// No description provided for @appOnboardPage1Title.
  ///
  /// In en, this message translates to:
  /// **'Sign up and create an account'**
  String get appOnboardPage1Title;

  /// No description provided for @appOnboardPage1Body.
  ///
  /// In en, this message translates to:
  /// **'Join as an Employer or Freelancer.'**
  String get appOnboardPage1Body;

  /// No description provided for @appOnboardPage2Title.
  ///
  /// In en, this message translates to:
  /// **'Post or search'**
  String get appOnboardPage2Title;

  /// No description provided for @appOnboardPage2Body.
  ///
  /// In en, this message translates to:
  /// **'Post a job, or browse and apply.'**
  String get appOnboardPage2Body;

  /// No description provided for @appOnboardPage3Title.
  ///
  /// In en, this message translates to:
  /// **'Chat and align'**
  String get appOnboardPage3Title;

  /// No description provided for @appOnboardPage3Body.
  ///
  /// In en, this message translates to:
  /// **'Message in the app and agree on the details.'**
  String get appOnboardPage3Body;

  /// No description provided for @appOnboardPage4Title.
  ///
  /// In en, this message translates to:
  /// **'Check for shift updates'**
  String get appOnboardPage4Title;

  /// No description provided for @appOnboardPage4Body.
  ///
  /// In en, this message translates to:
  /// **'Use on-site attendance or QR.'**
  String get appOnboardPage4Body;

  /// No description provided for @appOnboardPage5Title.
  ///
  /// In en, this message translates to:
  /// **'Wrap up and leave a review'**
  String get appOnboardPage5Title;

  /// No description provided for @appOnboardPage5Body.
  ///
  /// In en, this message translates to:
  /// **'Finish the job and share your experience.'**
  String get appOnboardPage5Body;

  /// No description provided for @authWelcomeHowToUse.
  ///
  /// In en, this message translates to:
  /// **'How will you use HupWorks?'**
  String get authWelcomeHowToUse;

  /// No description provided for @authRoleClient.
  ///
  /// In en, this message translates to:
  /// **'Employer'**
  String get authRoleClient;

  /// No description provided for @authRoleClientSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Hire talent'**
  String get authRoleClientSubtitle;

  /// No description provided for @authRoleFreelancer.
  ///
  /// In en, this message translates to:
  /// **'Freelancer'**
  String get authRoleFreelancer;

  /// No description provided for @authRoleFreelancerSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Find work'**
  String get authRoleFreelancerSubtitle;

  /// No description provided for @authContinueAsClient.
  ///
  /// In en, this message translates to:
  /// **'Continue as Employer'**
  String get authContinueAsClient;

  /// No description provided for @authContinueAsFreelancer.
  ///
  /// In en, this message translates to:
  /// **'Continue as Freelancer'**
  String get authContinueAsFreelancer;

  /// No description provided for @authAlreadyHaveAccount.
  ///
  /// In en, this message translates to:
  /// **'I already have an account'**
  String get authAlreadyHaveAccount;

  /// No description provided for @authWelcomeBack.
  ///
  /// In en, this message translates to:
  /// **'Welcome back'**
  String get authWelcomeBack;

  /// No description provided for @authSignInSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Sign in to continue to HupWorks.'**
  String get authSignInSubtitle;

  /// No description provided for @authEmail.
  ///
  /// In en, this message translates to:
  /// **'Email'**
  String get authEmail;

  /// No description provided for @authEmailHint.
  ///
  /// In en, this message translates to:
  /// **'you@email.com'**
  String get authEmailHint;

  /// No description provided for @authPassword.
  ///
  /// In en, this message translates to:
  /// **'Password'**
  String get authPassword;

  /// No description provided for @authPasswordHint.
  ///
  /// In en, this message translates to:
  /// **'Enter your password'**
  String get authPasswordHint;

  /// No description provided for @authForgotPassword.
  ///
  /// In en, this message translates to:
  /// **'Forgot password?'**
  String get authForgotPassword;

  /// No description provided for @authLogIn.
  ///
  /// In en, this message translates to:
  /// **'Log In'**
  String get authLogIn;

  /// No description provided for @authDontHaveAccount.
  ///
  /// In en, this message translates to:
  /// **'Don\'t have an account?'**
  String get authDontHaveAccount;

  /// No description provided for @authSignUp.
  ///
  /// In en, this message translates to:
  /// **'Sign up'**
  String get authSignUp;

  /// No description provided for @authOrContinueWith.
  ///
  /// In en, this message translates to:
  /// **'Or continue with'**
  String get authOrContinueWith;

  /// No description provided for @authAgreeToThe.
  ///
  /// In en, this message translates to:
  /// **'I agree to the '**
  String get authAgreeToThe;

  /// No description provided for @authTermsOfService.
  ///
  /// In en, this message translates to:
  /// **'Terms of Service'**
  String get authTermsOfService;

  /// No description provided for @authFirstName.
  ///
  /// In en, this message translates to:
  /// **'First name'**
  String get authFirstName;

  /// No description provided for @authFirstNameHint.
  ///
  /// In en, this message translates to:
  /// **'First'**
  String get authFirstNameHint;

  /// No description provided for @authLastName.
  ///
  /// In en, this message translates to:
  /// **'Last name'**
  String get authLastName;

  /// No description provided for @authLastNameHint.
  ///
  /// In en, this message translates to:
  /// **'Last'**
  String get authLastNameHint;

  /// No description provided for @authCreateAccount.
  ///
  /// In en, this message translates to:
  /// **'Create your account'**
  String get authCreateAccount;

  /// No description provided for @authJoinAsClient.
  ///
  /// In en, this message translates to:
  /// **'Join as an employer to hire freelancers.'**
  String get authJoinAsClient;

  /// No description provided for @authJoinAsFreelancer.
  ///
  /// In en, this message translates to:
  /// **'Join as a freelancer to find work.'**
  String get authJoinAsFreelancer;

  /// No description provided for @authPhone.
  ///
  /// In en, this message translates to:
  /// **'Phone'**
  String get authPhone;

  /// No description provided for @authPhoneHint.
  ///
  /// In en, this message translates to:
  /// **'Phone number'**
  String get authPhoneHint;

  /// No description provided for @authSignUpButton.
  ///
  /// In en, this message translates to:
  /// **'Sign Up'**
  String get authSignUpButton;

  /// No description provided for @authOrSignUpWith.
  ///
  /// In en, this message translates to:
  /// **'Or sign up with'**
  String get authOrSignUpWith;

  /// No description provided for @authAlreadyHaveAccountShort.
  ///
  /// In en, this message translates to:
  /// **'Already have an account?'**
  String get authAlreadyHaveAccountShort;

  /// No description provided for @authPasswordMinLength.
  ///
  /// In en, this message translates to:
  /// **'Password must be at least 6 characters'**
  String get authPasswordMinLength;

  /// No description provided for @authMustAgreeTerms.
  ///
  /// In en, this message translates to:
  /// **'Please agree to the Terms of Service'**
  String get authMustAgreeTerms;

  /// No description provided for @authForgotPasswordTitle.
  ///
  /// In en, this message translates to:
  /// **'Forgot Password?'**
  String get authForgotPasswordTitle;

  /// No description provided for @authForgotPasswordBody.
  ///
  /// In en, this message translates to:
  /// **'Enter your email and we\'ll send you a link to reset your password.'**
  String get authForgotPasswordBody;

  /// No description provided for @authResetPassword.
  ///
  /// In en, this message translates to:
  /// **'Reset Password'**
  String get authResetPassword;

  /// No description provided for @authEnterEmail.
  ///
  /// In en, this message translates to:
  /// **'Please enter your email'**
  String get authEnterEmail;

  /// No description provided for @authResetLinkSent.
  ///
  /// In en, this message translates to:
  /// **'Password reset link sent. Check your email.'**
  String get authResetLinkSent;

  /// No description provided for @authUpdatePasswordTitle.
  ///
  /// In en, this message translates to:
  /// **'Set New Password'**
  String get authUpdatePasswordTitle;

  /// No description provided for @authUpdatePasswordBody.
  ///
  /// In en, this message translates to:
  /// **'Choose a new password for your account.'**
  String get authUpdatePasswordBody;

  /// No description provided for @authNewPassword.
  ///
  /// In en, this message translates to:
  /// **'New password'**
  String get authNewPassword;

  /// No description provided for @authConfirmPassword.
  ///
  /// In en, this message translates to:
  /// **'Confirm password'**
  String get authConfirmPassword;

  /// No description provided for @authPasswordsDoNotMatch.
  ///
  /// In en, this message translates to:
  /// **'Passwords do not match'**
  String get authPasswordsDoNotMatch;

  /// No description provided for @authPasswordUpdated.
  ///
  /// In en, this message translates to:
  /// **'Password updated successfully.'**
  String get authPasswordUpdated;

  /// No description provided for @authSavePassword.
  ///
  /// In en, this message translates to:
  /// **'Save Password'**
  String get authSavePassword;

  /// No description provided for @authVerification.
  ///
  /// In en, this message translates to:
  /// **'Confirm email'**
  String get authVerification;

  /// No description provided for @authConfirmEmailBody.
  ///
  /// In en, this message translates to:
  /// **'We\'ve sent a confirmation link to your email. Open the link to activate your account, then log in.'**
  String get authConfirmEmailBody;

  /// No description provided for @authDidntReceiveEmail.
  ///
  /// In en, this message translates to:
  /// **'Didn\'t get the email?'**
  String get authDidntReceiveEmail;

  /// No description provided for @authResendEmail.
  ///
  /// In en, this message translates to:
  /// **'Resend email'**
  String get authResendEmail;

  /// No description provided for @authConfirmEmailResent.
  ///
  /// In en, this message translates to:
  /// **'Confirmation email sent again. Check your inbox.'**
  String get authConfirmEmailResent;

  /// No description provided for @authBackToLogIn.
  ///
  /// In en, this message translates to:
  /// **'Back to Log In'**
  String get authBackToLogIn;

  /// No description provided for @selectProfileImage.
  ///
  /// In en, this message translates to:
  /// **'Select Profile Image'**
  String get selectProfileImage;

  /// No description provided for @photoGallery.
  ///
  /// In en, this message translates to:
  /// **'Photo Gallery'**
  String get photoGallery;

  /// No description provided for @takePhoto.
  ///
  /// In en, this message translates to:
  /// **'Take Photo'**
  String get takePhoto;

  /// No description provided for @uploadYourPhoto.
  ///
  /// In en, this message translates to:
  /// **'Upload Your Photo'**
  String get uploadYourPhoto;

  /// No description provided for @userName.
  ///
  /// In en, this message translates to:
  /// **'User Name'**
  String get userName;

  /// No description provided for @phone.
  ///
  /// In en, this message translates to:
  /// **'Phone'**
  String get phone;

  /// No description provided for @country.
  ///
  /// In en, this message translates to:
  /// **'Country'**
  String get country;

  /// No description provided for @streetAddress.
  ///
  /// In en, this message translates to:
  /// **'Street Address'**
  String get streetAddress;

  /// No description provided for @city.
  ///
  /// In en, this message translates to:
  /// **'City'**
  String get city;

  /// No description provided for @state.
  ///
  /// In en, this message translates to:
  /// **'State'**
  String get state;

  /// No description provided for @zipCode.
  ///
  /// In en, this message translates to:
  /// **'ZIP Code'**
  String get zipCode;

  /// No description provided for @selectLanguage.
  ///
  /// In en, this message translates to:
  /// **'Select Language'**
  String get selectLanguage;

  /// No description provided for @selectGender.
  ///
  /// In en, this message translates to:
  /// **'Select Gender'**
  String get selectGender;

  /// No description provided for @addLanguage.
  ///
  /// In en, this message translates to:
  /// **'Add Language'**
  String get addLanguage;

  /// No description provided for @addNew.
  ///
  /// In en, this message translates to:
  /// **'Add New'**
  String get addNew;

  /// No description provided for @noLanguagesYet.
  ///
  /// In en, this message translates to:
  /// **'No languages added yet.'**
  String get noLanguagesYet;

  /// No description provided for @jobTitle.
  ///
  /// In en, this message translates to:
  /// **'Job Title'**
  String get jobTitle;

  /// No description provided for @skills.
  ///
  /// In en, this message translates to:
  /// **'Skills'**
  String get skills;

  /// No description provided for @aboutYou.
  ///
  /// In en, this message translates to:
  /// **'About You'**
  String get aboutYou;

  /// No description provided for @aboutYouHint.
  ///
  /// In en, this message translates to:
  /// **'Tell clients about yourself'**
  String get aboutYouHint;

  /// No description provided for @stepOf.
  ///
  /// In en, this message translates to:
  /// **'Step {current} of {total}'**
  String stepOf(int current, int total);

  /// No description provided for @browseCategories.
  ///
  /// In en, this message translates to:
  /// **'Browse Categories'**
  String get browseCategories;

  /// No description provided for @yourRecentJobs.
  ///
  /// In en, this message translates to:
  /// **'Your Recent Jobs'**
  String get yourRecentJobs;

  /// No description provided for @postJob.
  ///
  /// In en, this message translates to:
  /// **'Post Job'**
  String get postJob;

  /// No description provided for @findTalent.
  ///
  /// In en, this message translates to:
  /// **'Find Talent'**
  String get findTalent;

  /// No description provided for @categories.
  ///
  /// In en, this message translates to:
  /// **'Categories'**
  String get categories;

  /// No description provided for @hireTopRated.
  ///
  /// In en, this message translates to:
  /// **'Hire top-rated freelancers'**
  String get hireTopRated;

  /// No description provided for @postAJobBanner.
  ///
  /// In en, this message translates to:
  /// **'Post a job and get offers'**
  String get postAJobBanner;

  /// No description provided for @postNow.
  ///
  /// In en, this message translates to:
  /// **'Post Now'**
  String get postNow;

  /// No description provided for @browse.
  ///
  /// In en, this message translates to:
  /// **'Browse'**
  String get browse;

  /// No description provided for @noCategoriesYet.
  ///
  /// In en, this message translates to:
  /// **'No categories yet'**
  String get noCategoriesYet;

  /// No description provided for @noJobsYet.
  ///
  /// In en, this message translates to:
  /// **'No jobs yet'**
  String get noJobsYet;

  /// No description provided for @noFreelancersYet.
  ///
  /// In en, this message translates to:
  /// **'No freelancers yet'**
  String get noFreelancersYet;

  /// No description provided for @open.
  ///
  /// In en, this message translates to:
  /// **'Open'**
  String get open;

  /// No description provided for @closed.
  ///
  /// In en, this message translates to:
  /// **'Closed'**
  String get closed;

  /// No description provided for @fullTime.
  ///
  /// In en, this message translates to:
  /// **'Full-time'**
  String get fullTime;

  /// No description provided for @partTime.
  ///
  /// In en, this message translates to:
  /// **'Part-time'**
  String get partTime;

  /// No description provided for @viewProfile.
  ///
  /// In en, this message translates to:
  /// **'View Profile'**
  String get viewProfile;

  /// No description provided for @verifiedFreelancer.
  ///
  /// In en, this message translates to:
  /// **'Verified Freelancer'**
  String get verifiedFreelancer;

  /// No description provided for @allCategories.
  ///
  /// In en, this message translates to:
  /// **'All Categories'**
  String get allCategories;

  /// No description provided for @searchCategories.
  ///
  /// In en, this message translates to:
  /// **'Search categories'**
  String get searchCategories;

  /// No description provided for @noCategoriesMatch.
  ///
  /// In en, this message translates to:
  /// **'No matching categories'**
  String get noCategoriesMatch;

  /// No description provided for @searchFreelancers.
  ///
  /// In en, this message translates to:
  /// **'Search freelancers...'**
  String get searchFreelancers;

  /// No description provided for @noFreelancersMatch.
  ///
  /// In en, this message translates to:
  /// **'No matching freelancers'**
  String get noFreelancersMatch;

  /// No description provided for @findYourNextJob.
  ///
  /// In en, this message translates to:
  /// **'Find your next job'**
  String get findYourNextJob;

  /// No description provided for @findYourNextJobSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Browse open roles and apply in minutes.'**
  String get findYourNextJobSubtitle;

  /// No description provided for @myApplications.
  ///
  /// In en, this message translates to:
  /// **'My shifts'**
  String get myApplications;

  /// No description provided for @browseJobs.
  ///
  /// In en, this message translates to:
  /// **'Browse jobs'**
  String get browseJobs;

  /// No description provided for @statusAccepted.
  ///
  /// In en, this message translates to:
  /// **'Accepted'**
  String get statusAccepted;

  /// No description provided for @statusRejected.
  ///
  /// In en, this message translates to:
  /// **'Rejected'**
  String get statusRejected;

  /// No description provided for @statusPending.
  ///
  /// In en, this message translates to:
  /// **'Pending'**
  String get statusPending;

  /// No description provided for @budgetSuffixHour.
  ///
  /// In en, this message translates to:
  /// **'/hr'**
  String get budgetSuffixHour;

  /// No description provided for @budgetSuffixDay.
  ///
  /// In en, this message translates to:
  /// **'/day'**
  String get budgetSuffixDay;

  /// No description provided for @budgetSuffixMonth.
  ///
  /// In en, this message translates to:
  /// **'/mo'**
  String get budgetSuffixMonth;

  /// No description provided for @budgetSuffixTotal.
  ///
  /// In en, this message translates to:
  /// **'total'**
  String get budgetSuffixTotal;

  /// No description provided for @yourWork.
  ///
  /// In en, this message translates to:
  /// **'Work tracker'**
  String get yourWork;

  /// No description provided for @hoursWorked.
  ///
  /// In en, this message translates to:
  /// **'Hours worked'**
  String get hoursWorked;

  /// No description provided for @agreedContractValue.
  ///
  /// In en, this message translates to:
  /// **'Agreed amount'**
  String get agreedContractValue;

  /// No description provided for @jobsCompleted.
  ///
  /// In en, this message translates to:
  /// **'Jobs completed'**
  String get jobsCompleted;

  /// No description provided for @workOverviewDisclaimer.
  ///
  /// In en, this message translates to:
  /// **'Work and amounts are tracked in HupWorks. Payment happens outside the app — mark paid here as your record.'**
  String get workOverviewDisclaimer;

  /// No description provided for @hoursWorkedFormat.
  ///
  /// In en, this message translates to:
  /// **'{hours}h'**
  String hoursWorkedFormat(String hours);

  /// No description provided for @paymentReceivedValue.
  ///
  /// In en, this message translates to:
  /// **'Marked paid (outside app)'**
  String get paymentReceivedValue;

  /// No description provided for @outstandingValue.
  ///
  /// In en, this message translates to:
  /// **'Still unpaid'**
  String get outstandingValue;

  /// No description provided for @paymentReceivedTitle.
  ///
  /// In en, this message translates to:
  /// **'Marked paid outside the app'**
  String get paymentReceivedTitle;

  /// No description provided for @paymentOutstandingTitle.
  ///
  /// In en, this message translates to:
  /// **'Payment not marked yet'**
  String get paymentOutstandingTitle;

  /// No description provided for @paymentReceivedBody.
  ///
  /// In en, this message translates to:
  /// **'This is your shared record that payment was made outside HupWorks (cash, bank, or e-wallet). The app does not move money.'**
  String get paymentReceivedBody;

  /// No description provided for @paymentOutstandingSellerBody.
  ///
  /// In en, this message translates to:
  /// **'After the employer pays you outside the app, mark it here. Hours come from sign-in; this mark is your payment proof for tracking.'**
  String get paymentOutstandingSellerBody;

  /// No description provided for @paymentOutstandingClientBody.
  ///
  /// In en, this message translates to:
  /// **'After you pay the freelancer outside the app, mark it here. Use hours from attendance as work proof and this mark as payment proof.'**
  String get paymentOutstandingClientBody;

  /// No description provided for @markPaymentReceived.
  ///
  /// In en, this message translates to:
  /// **'Mark as paid outside app'**
  String get markPaymentReceived;

  /// No description provided for @markPaymentPaid.
  ///
  /// In en, this message translates to:
  /// **'Mark as paid outside app'**
  String get markPaymentPaid;

  /// No description provided for @undoPaymentReceived.
  ///
  /// In en, this message translates to:
  /// **'Undo paid mark'**
  String get undoPaymentReceived;

  /// No description provided for @paymentReceivedMarked.
  ///
  /// In en, this message translates to:
  /// **'Marked as paid outside the app.'**
  String get paymentReceivedMarked;

  /// No description provided for @paymentReceivedCleared.
  ///
  /// In en, this message translates to:
  /// **'Paid mark cleared.'**
  String get paymentReceivedCleared;

  /// No description provided for @paymentMarkedOn.
  ///
  /// In en, this message translates to:
  /// **'Marked on {date}'**
  String paymentMarkedOn(String date);

  /// No description provided for @activeContracts.
  ///
  /// In en, this message translates to:
  /// **'Active contracts'**
  String get activeContracts;

  /// No description provided for @wallet.
  ///
  /// In en, this message translates to:
  /// **'Wallet'**
  String get wallet;

  /// No description provided for @needsAttention.
  ///
  /// In en, this message translates to:
  /// **'Needs attention'**
  String get needsAttention;

  /// No description provided for @attentionItems.
  ///
  /// In en, this message translates to:
  /// **'{count} items need attention'**
  String attentionItems(int count);

  /// No description provided for @messages.
  ///
  /// In en, this message translates to:
  /// **'Messages'**
  String get messages;

  /// No description provided for @applications.
  ///
  /// In en, this message translates to:
  /// **'Applications'**
  String get applications;

  /// No description provided for @attendance.
  ///
  /// In en, this message translates to:
  /// **'Attendance'**
  String get attendance;

  /// No description provided for @shortcutFindJobs.
  ///
  /// In en, this message translates to:
  /// **'Find jobs'**
  String get shortcutFindJobs;

  /// No description provided for @shortcutFindJobsSub.
  ///
  /// In en, this message translates to:
  /// **'Browse open roles'**
  String get shortcutFindJobsSub;

  /// No description provided for @shortcutMessages.
  ///
  /// In en, this message translates to:
  /// **'Messages'**
  String get shortcutMessages;

  /// No description provided for @shortcutMessagesSub.
  ///
  /// In en, this message translates to:
  /// **'Chat with clients'**
  String get shortcutMessagesSub;

  /// No description provided for @shortcutContracts.
  ///
  /// In en, this message translates to:
  /// **'Contracts'**
  String get shortcutContracts;

  /// No description provided for @shortcutContractsSub.
  ///
  /// In en, this message translates to:
  /// **'Active work'**
  String get shortcutContractsSub;

  /// No description provided for @shortcutApplications.
  ///
  /// In en, this message translates to:
  /// **'Applications'**
  String get shortcutApplications;

  /// No description provided for @shortcutApplicationsSub.
  ///
  /// In en, this message translates to:
  /// **'Track status'**
  String get shortcutApplicationsSub;

  /// No description provided for @shortcutAttendance.
  ///
  /// In en, this message translates to:
  /// **'Attendance'**
  String get shortcutAttendance;

  /// No description provided for @shortcutAttendanceSub.
  ///
  /// In en, this message translates to:
  /// **'Clock in & out'**
  String get shortcutAttendanceSub;

  /// No description provided for @balance.
  ///
  /// In en, this message translates to:
  /// **'Balance'**
  String get balance;

  /// No description provided for @totalSpent.
  ///
  /// In en, this message translates to:
  /// **'Total spent'**
  String get totalSpent;

  /// No description provided for @earned.
  ///
  /// In en, this message translates to:
  /// **'Earned'**
  String get earned;

  /// No description provided for @sayHelloTo.
  ///
  /// In en, this message translates to:
  /// **'Say hello to {name}'**
  String sayHelloTo(String name);

  /// No description provided for @block.
  ///
  /// In en, this message translates to:
  /// **'Block'**
  String get block;

  /// No description provided for @blockUserTitle.
  ///
  /// In en, this message translates to:
  /// **'Block this user?'**
  String get blockUserTitle;

  /// No description provided for @blockUserBody.
  ///
  /// In en, this message translates to:
  /// **'You won’t see each other for new work or messages. Existing chat history stays visible.'**
  String get blockUserBody;

  /// No description provided for @blockUserBodyOpenObligation.
  ///
  /// In en, this message translates to:
  /// **'You still have an open or unpaid job together. Blocking won’t cancel payment rights — you can both finish the job, confirm payment, and report a dispute.'**
  String get blockUserBodyOpenObligation;

  /// No description provided for @blockAlsoReportPayment.
  ///
  /// In en, this message translates to:
  /// **'Also report a payment or contract dispute'**
  String get blockAlsoReportPayment;

  /// No description provided for @blockSuccess.
  ///
  /// In en, this message translates to:
  /// **'User blocked'**
  String get blockSuccess;

  /// No description provided for @blockSuccessOpenObligation.
  ///
  /// In en, this message translates to:
  /// **'User blocked. You can still manage your open job and payment.'**
  String get blockSuccessOpenObligation;

  /// No description provided for @contactBlocked.
  ///
  /// In en, this message translates to:
  /// **'Messaging is unavailable while you are blocked. Finish or settle any open job first, or unblock to continue.'**
  String get contactBlocked;

  /// No description provided for @contactBlockedShort.
  ///
  /// In en, this message translates to:
  /// **'Contact blocked'**
  String get contactBlockedShort;

  /// No description provided for @unblock.
  ///
  /// In en, this message translates to:
  /// **'Unblock'**
  String get unblock;

  /// No description provided for @noMessagesYet.
  ///
  /// In en, this message translates to:
  /// **'No messages yet'**
  String get noMessagesYet;

  /// No description provided for @searchChats.
  ///
  /// In en, this message translates to:
  /// **'Search chats'**
  String get searchChats;

  /// No description provided for @typeAMessage.
  ///
  /// In en, this message translates to:
  /// **'Type a message'**
  String get typeAMessage;

  /// No description provided for @cancellationRequestTitle.
  ///
  /// In en, this message translates to:
  /// **'Request to cancel'**
  String get cancellationRequestTitle;

  /// No description provided for @cancellationRequestBody.
  ///
  /// In en, this message translates to:
  /// **'Your client has 48 hours to approve or keep the contract.'**
  String get cancellationRequestBody;

  /// No description provided for @cancellationReason.
  ///
  /// In en, this message translates to:
  /// **'Reason'**
  String get cancellationReason;

  /// No description provided for @cancellationExplain.
  ///
  /// In en, this message translates to:
  /// **'Explain briefly'**
  String get cancellationExplain;

  /// No description provided for @cancellationSubmit.
  ///
  /// In en, this message translates to:
  /// **'Submit request'**
  String get cancellationSubmit;

  /// No description provided for @cancellationMinChars.
  ///
  /// In en, this message translates to:
  /// **'Please write at least {count} characters'**
  String cancellationMinChars(int count);

  /// No description provided for @keepContract.
  ///
  /// In en, this message translates to:
  /// **'Keep contract'**
  String get keepContract;

  /// No description provided for @approveCancellation.
  ///
  /// In en, this message translates to:
  /// **'Approve cancellation'**
  String get approveCancellation;

  /// No description provided for @withdrawCancelRequest.
  ///
  /// In en, this message translates to:
  /// **'Withdraw request'**
  String get withdrawCancelRequest;

  /// No description provided for @waitingForClientCancel.
  ///
  /// In en, this message translates to:
  /// **'Waiting for client to review your cancellation request'**
  String get waitingForClientCancel;

  /// No description provided for @cancellationRequested.
  ///
  /// In en, this message translates to:
  /// **'Cancellation requested'**
  String get cancellationRequested;

  /// No description provided for @awaitingYourApproval.
  ///
  /// In en, this message translates to:
  /// **'Awaiting your approval'**
  String get awaitingYourApproval;

  /// No description provided for @inProgress.
  ///
  /// In en, this message translates to:
  /// **'In progress'**
  String get inProgress;

  /// No description provided for @markComplete.
  ///
  /// In en, this message translates to:
  /// **'Mark complete'**
  String get markComplete;

  /// No description provided for @deliverWork.
  ///
  /// In en, this message translates to:
  /// **'Deliver work'**
  String get deliverWork;

  /// No description provided for @clockIn.
  ///
  /// In en, this message translates to:
  /// **'Clock in'**
  String get clockIn;

  /// No description provided for @clockOut.
  ///
  /// In en, this message translates to:
  /// **'Clock out'**
  String get clockOut;

  /// No description provided for @scanAttendanceQr.
  ///
  /// In en, this message translates to:
  /// **'Scan attendance QR'**
  String get scanAttendanceQr;

  /// No description provided for @editProfile.
  ///
  /// In en, this message translates to:
  /// **'Edit Profile'**
  String get editProfile;

  /// No description provided for @profileDetails.
  ///
  /// In en, this message translates to:
  /// **'Profile Details'**
  String get profileDetails;

  /// No description provided for @favourites.
  ///
  /// In en, this message translates to:
  /// **'Saved'**
  String get favourites;

  /// No description provided for @reviews.
  ///
  /// In en, this message translates to:
  /// **'Reviews'**
  String get reviews;

  /// No description provided for @noFavouritesYet.
  ///
  /// In en, this message translates to:
  /// **'No saved jobs yet'**
  String get noFavouritesYet;

  /// No description provided for @savedTalentList.
  ///
  /// In en, this message translates to:
  /// **'Saved talent'**
  String get savedTalentList;

  /// No description provided for @noSavedTalentYet.
  ///
  /// In en, this message translates to:
  /// **'No saved talent yet'**
  String get noSavedTalentYet;

  /// No description provided for @noSavedTalentYetHint.
  ///
  /// In en, this message translates to:
  /// **'Browse freelancers and tap the bookmark to save them here.'**
  String get noSavedTalentYetHint;

  /// No description provided for @addedToSavedTalent.
  ///
  /// In en, this message translates to:
  /// **'Talent saved'**
  String get addedToSavedTalent;

  /// No description provided for @removedFromSavedTalent.
  ///
  /// In en, this message translates to:
  /// **'Removed from saved talent'**
  String get removedFromSavedTalent;

  /// No description provided for @noReviewsYet.
  ///
  /// In en, this message translates to:
  /// **'No reviews yet'**
  String get noReviewsYet;

  /// No description provided for @mapPickLocation.
  ///
  /// In en, this message translates to:
  /// **'Pick location'**
  String get mapPickLocation;

  /// No description provided for @mapConfirmLocation.
  ///
  /// In en, this message translates to:
  /// **'Confirm location'**
  String get mapConfirmLocation;

  /// No description provided for @mapSearchPlace.
  ///
  /// In en, this message translates to:
  /// **'Search place'**
  String get mapSearchPlace;

  /// No description provided for @deposit.
  ///
  /// In en, this message translates to:
  /// **'Deposit'**
  String get deposit;

  /// No description provided for @withdraw.
  ///
  /// In en, this message translates to:
  /// **'Withdraw'**
  String get withdraw;

  /// No description provided for @addPaymentMethod.
  ///
  /// In en, this message translates to:
  /// **'Add payment method'**
  String get addPaymentMethod;

  /// No description provided for @amount.
  ///
  /// In en, this message translates to:
  /// **'Amount'**
  String get amount;

  /// No description provided for @history.
  ///
  /// In en, this message translates to:
  /// **'History'**
  String get history;

  /// No description provided for @noTransactionsYet.
  ///
  /// In en, this message translates to:
  /// **'No transactions yet'**
  String get noTransactionsYet;

  /// No description provided for @supportChat.
  ///
  /// In en, this message translates to:
  /// **'Support chat'**
  String get supportChat;

  /// No description provided for @typeSupportMessage.
  ///
  /// In en, this message translates to:
  /// **'Type your message'**
  String get typeSupportMessage;

  /// No description provided for @clientReport.
  ///
  /// In en, this message translates to:
  /// **'Client Report'**
  String get clientReport;

  /// No description provided for @selectReason.
  ///
  /// In en, this message translates to:
  /// **'Select reason'**
  String get selectReason;

  /// No description provided for @describeIssue.
  ///
  /// In en, this message translates to:
  /// **'Describe the issue'**
  String get describeIssue;

  /// No description provided for @submitReport.
  ///
  /// In en, this message translates to:
  /// **'Submit report'**
  String get submitReport;

  /// No description provided for @cancellationSheetTitle.
  ///
  /// In en, this message translates to:
  /// **'Request to cancel contract'**
  String get cancellationSheetTitle;

  /// No description provided for @cancellationSheetBody.
  ///
  /// In en, this message translates to:
  /// **'Your client will be notified and can approve or decline within 48 hours. The contract stays active until they respond.'**
  String get cancellationSheetBody;

  /// No description provided for @cancellationExplainHint.
  ///
  /// In en, this message translates to:
  /// **'What happened? This helps your client understand your request.'**
  String get cancellationExplainHint;

  /// No description provided for @cancellationCharCount.
  ///
  /// In en, this message translates to:
  /// **'{current} / {min} characters minimum'**
  String cancellationCharCount(int current, int min);

  /// No description provided for @cancellationReasonLine.
  ///
  /// In en, this message translates to:
  /// **'Reason: {reason}'**
  String cancellationReasonLine(String reason);

  /// No description provided for @reportWhyQuestion.
  ///
  /// In en, this message translates to:
  /// **'Why are you reporting?'**
  String get reportWhyQuestion;

  /// No description provided for @reportSellerProfileUrl.
  ///
  /// In en, this message translates to:
  /// **'Seller Profile URL'**
  String get reportSellerProfileUrl;

  /// No description provided for @reportEnterSellerProfileUrl.
  ///
  /// In en, this message translates to:
  /// **'Enter seller profile url'**
  String get reportEnterSellerProfileUrl;

  /// No description provided for @reportOriginalContentUrl.
  ///
  /// In en, this message translates to:
  /// **'URL of original content'**
  String get reportOriginalContentUrl;

  /// No description provided for @reportEnterPostUrl.
  ///
  /// In en, this message translates to:
  /// **'Enter post url'**
  String get reportEnterPostUrl;

  /// No description provided for @reportAdditionalInfo.
  ///
  /// In en, this message translates to:
  /// **'What happened?'**
  String get reportAdditionalInfo;

  /// No description provided for @reportEnterInformation.
  ///
  /// In en, this message translates to:
  /// **'Describe the issue…'**
  String get reportEnterInformation;

  /// No description provided for @promoVerifiedTalentSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Verified talent for every project'**
  String get promoVerifiedTalentSubtitle;

  /// No description provided for @promoProposalsSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Get proposals within minutes'**
  String get promoProposalsSubtitle;

  /// No description provided for @promoNicheServicesSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Find services across every niche'**
  String get promoNicheServicesSubtitle;

  /// No description provided for @jobTypeGig.
  ///
  /// In en, this message translates to:
  /// **'Shift'**
  String get jobTypeGig;

  /// No description provided for @recentJobsEmptyHint.
  ///
  /// In en, this message translates to:
  /// **'Tap \"Post Job\" to get started'**
  String get recentJobsEmptyHint;

  /// No description provided for @postJobShort.
  ///
  /// In en, this message translates to:
  /// **'Post'**
  String get postJobShort;

  /// No description provided for @untitled.
  ///
  /// In en, this message translates to:
  /// **'Untitled'**
  String get untitled;

  /// No description provided for @untitledJob.
  ///
  /// In en, this message translates to:
  /// **'Untitled job'**
  String get untitledJob;

  /// No description provided for @categoryGeneral.
  ///
  /// In en, this message translates to:
  /// **'General'**
  String get categoryGeneral;

  /// No description provided for @proBadge.
  ///
  /// In en, this message translates to:
  /// **'Pro'**
  String get proBadge;

  /// No description provided for @standingNewcomer.
  ///
  /// In en, this message translates to:
  /// **'Newcomer'**
  String get standingNewcomer;

  /// No description provided for @standingAdvanced.
  ///
  /// In en, this message translates to:
  /// **'Advanced'**
  String get standingAdvanced;

  /// No description provided for @standingPro.
  ///
  /// In en, this message translates to:
  /// **'Pro'**
  String get standingPro;

  /// No description provided for @standingExpert.
  ///
  /// In en, this message translates to:
  /// **'Expert'**
  String get standingExpert;

  /// No description provided for @standingGolden.
  ///
  /// In en, this message translates to:
  /// **'Golden'**
  String get standingGolden;

  /// No description provided for @standingWorkhorse.
  ///
  /// In en, this message translates to:
  /// **'Workhorse'**
  String get standingWorkhorse;

  /// No description provided for @standingWorkNinja.
  ///
  /// In en, this message translates to:
  /// **'WorkNinja'**
  String get standingWorkNinja;

  /// No description provided for @standingLegend.
  ///
  /// In en, this message translates to:
  /// **'Legend'**
  String get standingLegend;

  /// No description provided for @standingHupper.
  ///
  /// In en, this message translates to:
  /// **'Hupper'**
  String get standingHupper;

  /// No description provided for @standingTitle.
  ///
  /// In en, this message translates to:
  /// **'Standing'**
  String get standingTitle;

  /// No description provided for @noApplicationsYet.
  ///
  /// In en, this message translates to:
  /// **'No applications yet'**
  String get noApplicationsYet;

  /// No description provided for @noApplicationsYetHint.
  ///
  /// In en, this message translates to:
  /// **'Browse open jobs and send a clear offer to stand out.'**
  String get noApplicationsYetHint;

  /// No description provided for @noClientApplicationsYetHint.
  ///
  /// In en, this message translates to:
  /// **'Applications to your jobs show up here. Post a job to start receiving them.'**
  String get noClientApplicationsYetHint;

  /// No description provided for @pendingApplications.
  ///
  /// In en, this message translates to:
  /// **'Pending applications'**
  String get pendingApplications;

  /// No description provided for @completedThisMonth.
  ///
  /// In en, this message translates to:
  /// **'Completed this month'**
  String get completedThisMonth;

  /// No description provided for @yourRating.
  ///
  /// In en, this message translates to:
  /// **'Your rating'**
  String get yourRating;

  /// No description provided for @reviewCount.
  ///
  /// In en, this message translates to:
  /// **'{count} reviews'**
  String reviewCount(int count);

  /// No description provided for @openJobsToBrowse.
  ///
  /// In en, this message translates to:
  /// **'{count} open jobs to browse'**
  String openJobsToBrowse(int count);

  /// No description provided for @periodLive.
  ///
  /// In en, this message translates to:
  /// **'Live'**
  String get periodLive;

  /// No description provided for @periodThisMonth.
  ///
  /// In en, this message translates to:
  /// **'This month'**
  String get periodThisMonth;

  /// No description provided for @shortcuts.
  ///
  /// In en, this message translates to:
  /// **'Shortcuts'**
  String get shortcuts;

  /// No description provided for @attentionContractDeliveredOne.
  ///
  /// In en, this message translates to:
  /// **'1 contract delivered — waiting for client approval'**
  String get attentionContractDeliveredOne;

  /// No description provided for @attentionContractDeliveredMany.
  ///
  /// In en, this message translates to:
  /// **'{count} contracts delivered — waiting for client approval'**
  String attentionContractDeliveredMany(int count);

  /// No description provided for @attentionOnsiteOne.
  ///
  /// In en, this message translates to:
  /// **'1 on-site contract — clock in via Attendance'**
  String get attentionOnsiteOne;

  /// No description provided for @attentionOnsiteMany.
  ///
  /// In en, this message translates to:
  /// **'{count} on-site contracts — use Attendance'**
  String attentionOnsiteMany(int count);

  /// No description provided for @attendanceOffForJob.
  ///
  /// In en, this message translates to:
  /// **'Attendance is off for this job.'**
  String get attendanceOffForJob;

  /// No description provided for @checkedIn.
  ///
  /// In en, this message translates to:
  /// **'Checked in'**
  String get checkedIn;

  /// No description provided for @checkIn.
  ///
  /// In en, this message translates to:
  /// **'Check in'**
  String get checkIn;

  /// No description provided for @noPunchesToday.
  ///
  /// In en, this message translates to:
  /// **'No punches yet today.'**
  String get noPunchesToday;

  /// No description provided for @noAttendanceRecordedToday.
  ///
  /// In en, this message translates to:
  /// **'No attendance recorded today.'**
  String get noAttendanceRecordedToday;

  /// No description provided for @confirmAttendance.
  ///
  /// In en, this message translates to:
  /// **'Confirm attendance'**
  String get confirmAttendance;

  /// No description provided for @alreadyCheckedInToday.
  ///
  /// In en, this message translates to:
  /// **'Already checked in today'**
  String get alreadyCheckedInToday;

  /// No description provided for @readyForDailyCheckIn.
  ///
  /// In en, this message translates to:
  /// **'Ready for daily check-in'**
  String get readyForDailyCheckIn;

  /// No description provided for @clockedInAt.
  ///
  /// In en, this message translates to:
  /// **'Clocked in at {time}'**
  String clockedInAt(String time);

  /// No description provided for @notClockedInToday.
  ///
  /// In en, this message translates to:
  /// **'Not clocked in today'**
  String get notClockedInToday;

  /// No description provided for @calendarToday.
  ///
  /// In en, this message translates to:
  /// **'Today'**
  String get calendarToday;

  /// No description provided for @recordLabel.
  ///
  /// In en, this message translates to:
  /// **'Record'**
  String get recordLabel;

  /// No description provided for @alreadyCheckedInTodayMessage.
  ///
  /// In en, this message translates to:
  /// **'You have already checked in today for this job.'**
  String get alreadyCheckedInTodayMessage;

  /// No description provided for @attendanceQrOnceDailyHint.
  ///
  /// In en, this message translates to:
  /// **'This job uses one check-in scan per day (no clock-out scan).'**
  String get attendanceQrOnceDailyHint;

  /// No description provided for @checkInForToday.
  ///
  /// In en, this message translates to:
  /// **'Check in for today'**
  String get checkInForToday;

  /// No description provided for @attendancePunchRecorded.
  ///
  /// In en, this message translates to:
  /// **'{punch} recorded. Today: {minutes} worked.'**
  String attendancePunchRecorded(String punch, String minutes);

  /// No description provided for @useSuggestedPunch.
  ///
  /// In en, this message translates to:
  /// **'Use suggested: {punch}'**
  String useSuggestedPunch(String punch);

  /// No description provided for @attendanceScanCameraHint.
  ///
  /// In en, this message translates to:
  /// **'Point your camera at the attendance QR posted at the job site.'**
  String get attendanceScanCameraHint;

  /// No description provided for @attendanceScanLoadingDetails.
  ///
  /// In en, this message translates to:
  /// **'Loading job details…'**
  String get attendanceScanLoadingDetails;

  /// No description provided for @attendanceScanningForJob.
  ///
  /// In en, this message translates to:
  /// **'Scanning for: {title}'**
  String attendanceScanningForJob(String title);

  /// No description provided for @viewMyOnsiteJobs.
  ///
  /// In en, this message translates to:
  /// **'View my on-site jobs'**
  String get viewMyOnsiteJobs;

  /// No description provided for @attendanceQrScreenTitle.
  ///
  /// In en, this message translates to:
  /// **'Attendance QR'**
  String get attendanceQrScreenTitle;

  /// No description provided for @attendancePrintQrAtSite.
  ///
  /// In en, this message translates to:
  /// **'Print this QR and post it where workers check in.'**
  String get attendancePrintQrAtSite;

  /// No description provided for @attendanceCouldNotLoadQr.
  ///
  /// In en, this message translates to:
  /// **'Could not load QR'**
  String get attendanceCouldNotLoadQr;

  /// No description provided for @attendanceSharePrintInstructions.
  ///
  /// In en, this message translates to:
  /// **'Share / Print instructions'**
  String get attendanceSharePrintInstructions;

  /// No description provided for @regenerateQr.
  ///
  /// In en, this message translates to:
  /// **'Regenerate QR'**
  String get regenerateQr;

  /// No description provided for @regenerateQrConfirmTitle.
  ///
  /// In en, this message translates to:
  /// **'Regenerate QR?'**
  String get regenerateQrConfirmTitle;

  /// No description provided for @regenerateQrConfirmBody.
  ///
  /// In en, this message translates to:
  /// **'The old printed QR will stop working. Print and post the new code at your site.'**
  String get regenerateQrConfirmBody;

  /// No description provided for @regenerate.
  ///
  /// In en, this message translates to:
  /// **'Regenerate'**
  String get regenerate;

  /// No description provided for @attendanceNewQrReady.
  ///
  /// In en, this message translates to:
  /// **'New attendance QR ready'**
  String get attendanceNewQrReady;

  /// No description provided for @attendanceHowItWorks.
  ///
  /// In en, this message translates to:
  /// **'How it works'**
  String get attendanceHowItWorks;

  /// No description provided for @attendanceHowItWorksBody.
  ///
  /// In en, this message translates to:
  /// **'1. Print and tape this QR at the workplace.\n2. Hired freelancers open HupWorks and scan it.\n3. They confirm clock in or clock out on their phone.\n4. You can view today\'s attendance on the job details screen.'**
  String get attendanceHowItWorksBody;

  /// No description provided for @noOnsiteJobsYet.
  ///
  /// In en, this message translates to:
  /// **'No on-site jobs yet'**
  String get noOnsiteJobsYet;

  /// No description provided for @noOnsiteJobsBody.
  ///
  /// In en, this message translates to:
  /// **'You need an accepted on-site contract. Your client chooses how attendance works (QR scan or self-report) when they post the job.'**
  String get noOnsiteJobsBody;

  /// No description provided for @findOnsiteJobs.
  ///
  /// In en, this message translates to:
  /// **'Find on-site jobs'**
  String get findOnsiteJobs;

  /// No description provided for @selectedJob.
  ///
  /// In en, this message translates to:
  /// **'Selected job'**
  String get selectedJob;

  /// No description provided for @openContract.
  ///
  /// In en, this message translates to:
  /// **'Open contract'**
  String get openContract;

  /// No description provided for @attendanceTimeIn.
  ///
  /// In en, this message translates to:
  /// **'Time in'**
  String get attendanceTimeIn;

  /// No description provided for @attendanceTimeOut.
  ///
  /// In en, this message translates to:
  /// **'Time out'**
  String get attendanceTimeOut;

  /// No description provided for @attendanceWorkedToday.
  ///
  /// In en, this message translates to:
  /// **'Worked today: {duration}'**
  String attendanceWorkedToday(String duration);

  /// No description provided for @attendancePunchTodaySummary.
  ///
  /// In en, this message translates to:
  /// **'{punch} • {duration} today'**
  String attendancePunchTodaySummary(String punch, String duration);

  /// No description provided for @attendanceLessThanOneMin.
  ///
  /// In en, this message translates to:
  /// **'Less than 1 min'**
  String get attendanceLessThanOneMin;

  /// No description provided for @attendanceMinutesOnly.
  ///
  /// In en, this message translates to:
  /// **'{count} min'**
  String attendanceMinutesOnly(int count);

  /// No description provided for @attendanceHoursOnly.
  ///
  /// In en, this message translates to:
  /// **'{count}h'**
  String attendanceHoursOnly(int count);

  /// No description provided for @attendanceHoursMinutes.
  ///
  /// In en, this message translates to:
  /// **'{hours}h {minutes}m'**
  String attendanceHoursMinutes(int hours, int minutes);

  /// No description provided for @firstDayInstructions.
  ///
  /// In en, this message translates to:
  /// **'First-day instructions'**
  String get firstDayInstructions;

  /// No description provided for @instructionsNotAvailable.
  ///
  /// In en, this message translates to:
  /// **'Instructions not available yet.'**
  String get instructionsNotAvailable;

  /// No description provided for @onboardingUseScanQrHint.
  ///
  /// In en, this message translates to:
  /// **'When you arrive on site, use Scan attendance QR on the contract screen.'**
  String get onboardingUseScanQrHint;

  /// No description provided for @noSectionDetails.
  ///
  /// In en, this message translates to:
  /// **'No section details were provided.'**
  String get noSectionDetails;

  /// No description provided for @pleaseWaitEllipsis.
  ///
  /// In en, this message translates to:
  /// **'Please wait…'**
  String get pleaseWaitEllipsis;

  /// No description provided for @onboardingAcknowledgedLabel.
  ///
  /// In en, this message translates to:
  /// **'You acknowledged these instructions'**
  String get onboardingAcknowledgedLabel;

  /// No description provided for @onboardingReadUnderstood.
  ///
  /// In en, this message translates to:
  /// **'I have read and understood'**
  String get onboardingReadUnderstood;

  /// No description provided for @onboardingEditorLead.
  ///
  /// In en, this message translates to:
  /// **'Share site details, access, and contacts so your hire knows what to do on day one.'**
  String get onboardingEditorLead;

  /// No description provided for @onboardingResendNotice.
  ///
  /// In en, this message translates to:
  /// **'Already sent. Saving and publishing again will notify the freelancer.'**
  String get onboardingResendNotice;

  /// No description provided for @addDetailsHint.
  ///
  /// In en, this message translates to:
  /// **'Add details…'**
  String get addDetailsHint;

  /// No description provided for @draftSaved.
  ///
  /// In en, this message translates to:
  /// **'Draft saved'**
  String get draftSaved;

  /// No description provided for @instructionsSentToFreelancer.
  ///
  /// In en, this message translates to:
  /// **'Instructions sent to freelancer'**
  String get instructionsSentToFreelancer;

  /// No description provided for @saveDraft.
  ///
  /// In en, this message translates to:
  /// **'Save draft'**
  String get saveDraft;

  /// No description provided for @publishToFreelancer.
  ///
  /// In en, this message translates to:
  /// **'Publish to freelancer'**
  String get publishToFreelancer;

  /// No description provided for @startConversationFirstMessage.
  ///
  /// In en, this message translates to:
  /// **'Start a conversation by sending your first message'**
  String get startConversationFirstMessage;

  /// No description provided for @chatSendFailed.
  ///
  /// In en, this message translates to:
  /// **'Message failed to send'**
  String get chatSendFailed;

  /// No description provided for @failedTapToRetry.
  ///
  /// In en, this message translates to:
  /// **'Failed — Tap to retry'**
  String get failedTapToRetry;

  /// No description provided for @chatAttachment.
  ///
  /// In en, this message translates to:
  /// **'Attachment'**
  String get chatAttachment;

  /// No description provided for @calendarYesterday.
  ///
  /// In en, this message translates to:
  /// **'Yesterday'**
  String get calendarYesterday;

  /// No description provided for @noConversationsYet.
  ///
  /// In en, this message translates to:
  /// **'No conversations yet'**
  String get noConversationsYet;

  /// No description provided for @noConversationsHint.
  ///
  /// In en, this message translates to:
  /// **'Start a chat from a freelancer or client profile'**
  String get noConversationsHint;

  /// No description provided for @noChatMatches.
  ///
  /// In en, this message translates to:
  /// **'No matches found'**
  String get noChatMatches;

  /// No description provided for @tryDifferentSearch.
  ///
  /// In en, this message translates to:
  /// **'Try a different name or keyword'**
  String get tryDifferentSearch;

  /// No description provided for @myProfile.
  ///
  /// In en, this message translates to:
  /// **'My Profile'**
  String get myProfile;

  /// No description provided for @dashboard.
  ///
  /// In en, this message translates to:
  /// **'Dashboard'**
  String get dashboard;

  /// No description provided for @addDeposit.
  ///
  /// In en, this message translates to:
  /// **'Add Deposit'**
  String get addDeposit;

  /// No description provided for @depositHistory.
  ///
  /// In en, this message translates to:
  /// **'Deposit History'**
  String get depositHistory;

  /// No description provided for @paymentMethods.
  ///
  /// In en, this message translates to:
  /// **'Payment Methods'**
  String get paymentMethods;

  /// No description provided for @withdrawals.
  ///
  /// In en, this message translates to:
  /// **'Withdrawals'**
  String get withdrawals;

  /// No description provided for @withdrawMoney.
  ///
  /// In en, this message translates to:
  /// **'Withdraw Money'**
  String get withdrawMoney;

  /// No description provided for @withdrawHistory.
  ///
  /// In en, this message translates to:
  /// **'Withdraw History'**
  String get withdrawHistory;

  /// No description provided for @balanceWithAmount.
  ///
  /// In en, this message translates to:
  /// **'Balance: {amount}'**
  String balanceWithAmount(String amount);

  /// No description provided for @editProfileSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Edit your profile details'**
  String get editProfileSubtitle;

  /// No description provided for @fullName.
  ///
  /// In en, this message translates to:
  /// **'Full Name'**
  String get fullName;

  /// No description provided for @enterYourName.
  ///
  /// In en, this message translates to:
  /// **'Enter your name'**
  String get enterYourName;

  /// No description provided for @phoneNo.
  ///
  /// In en, this message translates to:
  /// **'Phone No.'**
  String get phoneNo;

  /// No description provided for @enterPhoneNo.
  ///
  /// In en, this message translates to:
  /// **'Enter Phone No.'**
  String get enterPhoneNo;

  /// No description provided for @aboutYourCompany.
  ///
  /// In en, this message translates to:
  /// **'About your company'**
  String get aboutYourCompany;

  /// No description provided for @aboutCompanyHint.
  ///
  /// In en, this message translates to:
  /// **'Short intro for freelancers viewing your jobs…'**
  String get aboutCompanyHint;

  /// No description provided for @updating.
  ///
  /// In en, this message translates to:
  /// **'Updating...'**
  String get updating;

  /// No description provided for @updateProfile.
  ///
  /// In en, this message translates to:
  /// **'Update Profile'**
  String get updateProfile;

  /// No description provided for @basicInfo.
  ///
  /// In en, this message translates to:
  /// **'Basic info'**
  String get basicInfo;

  /// No description provided for @professional.
  ///
  /// In en, this message translates to:
  /// **'Professional'**
  String get professional;

  /// No description provided for @address.
  ///
  /// In en, this message translates to:
  /// **'Address'**
  String get address;

  /// No description provided for @enterFullAddress.
  ///
  /// In en, this message translates to:
  /// **'Enter your full address'**
  String get enterFullAddress;

  /// No description provided for @tapSetBirthDate.
  ///
  /// In en, this message translates to:
  /// **'Tap to set your birth date'**
  String get tapSetBirthDate;

  /// No description provided for @ageHiddenOnProfile.
  ///
  /// In en, this message translates to:
  /// **'Age {age} (birth date is hidden on profile)'**
  String ageHiddenOnProfile(int age);

  /// No description provided for @birthDateSaved.
  ///
  /// In en, this message translates to:
  /// **'Birth date saved'**
  String get birthDateSaved;

  /// No description provided for @ageLabel.
  ///
  /// In en, this message translates to:
  /// **'Age'**
  String get ageLabel;

  /// No description provided for @agePrivacyHint.
  ///
  /// In en, this message translates to:
  /// **'Your age is shown on your profile. Your birth date is never displayed.'**
  String get agePrivacyHint;

  /// No description provided for @dateOfBirth.
  ///
  /// In en, this message translates to:
  /// **'Date of birth'**
  String get dateOfBirth;

  /// No description provided for @profileDescription.
  ///
  /// In en, this message translates to:
  /// **'Profile description'**
  String get profileDescription;

  /// No description provided for @profileDescriptionHint.
  ///
  /// In en, this message translates to:
  /// **'Write a brief description about you…'**
  String get profileDescriptionHint;

  /// No description provided for @yourSkills.
  ///
  /// In en, this message translates to:
  /// **'Your skills'**
  String get yourSkills;

  /// No description provided for @skillsOptionalHint.
  ///
  /// In en, this message translates to:
  /// **'Optional — add skills to help clients find you.'**
  String get skillsOptionalHint;

  /// No description provided for @jobTitleHint.
  ///
  /// In en, this message translates to:
  /// **'e.g. Factory Worker'**
  String get jobTitleHint;

  /// No description provided for @statPosted.
  ///
  /// In en, this message translates to:
  /// **'Posted'**
  String get statPosted;

  /// No description provided for @myJobPosts.
  ///
  /// In en, this message translates to:
  /// **'My Job Posts'**
  String get myJobPosts;

  /// No description provided for @countTotal.
  ///
  /// In en, this message translates to:
  /// **'{count} total'**
  String countTotal(int count);

  /// No description provided for @noJobsPostedYet.
  ///
  /// In en, this message translates to:
  /// **'No jobs posted yet'**
  String get noJobsPostedYet;

  /// No description provided for @noJobsPostedYetHint.
  ///
  /// In en, this message translates to:
  /// **'Post a job to start receiving applications from freelancers.'**
  String get noJobsPostedYetHint;

  /// No description provided for @postAJob.
  ///
  /// In en, this message translates to:
  /// **'Post a job'**
  String get postAJob;

  /// No description provided for @avgRating.
  ///
  /// In en, this message translates to:
  /// **'Avg rating'**
  String get avgRating;

  /// No description provided for @about.
  ///
  /// In en, this message translates to:
  /// **'About'**
  String get about;

  /// No description provided for @email.
  ///
  /// In en, this message translates to:
  /// **'Email'**
  String get email;

  /// No description provided for @ageYearsOld.
  ///
  /// In en, this message translates to:
  /// **'{age} years old'**
  String ageYearsOld(int age);

  /// No description provided for @reviewsFromClientsHint.
  ///
  /// In en, this message translates to:
  /// **'Reviews from clients appear here after completed orders.'**
  String get reviewsFromClientsHint;

  /// No description provided for @clientProfile.
  ///
  /// In en, this message translates to:
  /// **'Client profile'**
  String get clientProfile;

  /// No description provided for @clientNotFound.
  ///
  /// In en, this message translates to:
  /// **'Client not found'**
  String get clientNotFound;

  /// No description provided for @freelancerProfile.
  ///
  /// In en, this message translates to:
  /// **'Freelancer profile'**
  String get freelancerProfile;

  /// No description provided for @freelancerNotFound.
  ///
  /// In en, this message translates to:
  /// **'Freelancer not found'**
  String get freelancerNotFound;

  /// No description provided for @couldNotLoadProfile.
  ///
  /// In en, this message translates to:
  /// **'Could not load profile: {message}'**
  String couldNotLoadProfile(String message);

  /// No description provided for @jobsPosted.
  ///
  /// In en, this message translates to:
  /// **'Jobs posted'**
  String get jobsPosted;

  /// No description provided for @memberSince.
  ///
  /// In en, this message translates to:
  /// **'Member since'**
  String get memberSince;

  /// No description provided for @noneYet.
  ///
  /// In en, this message translates to:
  /// **'None yet'**
  String get noneYet;

  /// No description provided for @noReviewsForClientYet.
  ///
  /// In en, this message translates to:
  /// **'No reviews for this client yet.'**
  String get noReviewsForClientYet;

  /// No description provided for @viewServices.
  ///
  /// In en, this message translates to:
  /// **'View services'**
  String get viewServices;

  /// No description provided for @noActiveServiceListing.
  ///
  /// In en, this message translates to:
  /// **'No active service listing yet.'**
  String get noActiveServiceListing;

  /// No description provided for @favouriteList.
  ///
  /// In en, this message translates to:
  /// **'Saved jobs'**
  String get favouriteList;

  /// No description provided for @removedFromFavourites.
  ///
  /// In en, this message translates to:
  /// **'Removed from saved'**
  String get removedFromFavourites;

  /// No description provided for @addedToFavourites.
  ///
  /// In en, this message translates to:
  /// **'Job saved'**
  String get addedToFavourites;

  /// No description provided for @priceColon.
  ///
  /// In en, this message translates to:
  /// **'Price: '**
  String get priceColon;

  /// No description provided for @service.
  ///
  /// In en, this message translates to:
  /// **'Service'**
  String get service;

  /// No description provided for @serviceDetails.
  ///
  /// In en, this message translates to:
  /// **'Service Details'**
  String get serviceDetails;

  /// No description provided for @orderNow.
  ///
  /// In en, this message translates to:
  /// **'Order Now'**
  String get orderNow;

  /// No description provided for @errorLoadingService.
  ///
  /// In en, this message translates to:
  /// **'Could not load service: {message}'**
  String errorLoadingService(String message);

  /// No description provided for @noDescriptionAvailable.
  ///
  /// In en, this message translates to:
  /// **'No description available.'**
  String get noDescriptionAvailable;

  /// No description provided for @deliveryDays.
  ///
  /// In en, this message translates to:
  /// **'Delivery days'**
  String get deliveryDays;

  /// No description provided for @revisions.
  ///
  /// In en, this message translates to:
  /// **'Revisions'**
  String get revisions;

  /// No description provided for @unlimited.
  ///
  /// In en, this message translates to:
  /// **'Unlimited'**
  String get unlimited;

  /// No description provided for @totalReviewsCount.
  ///
  /// In en, this message translates to:
  /// **'Total {count} Reviews'**
  String totalReviewsCount(int count);

  /// No description provided for @anonymous.
  ///
  /// In en, this message translates to:
  /// **'Anonymous'**
  String get anonymous;

  /// No description provided for @orderPlacedSuccess.
  ///
  /// In en, this message translates to:
  /// **'Order placed successfully!'**
  String get orderPlacedSuccess;

  /// No description provided for @errorPlacingOrder.
  ///
  /// In en, this message translates to:
  /// **'Could not place order: {message}'**
  String errorPlacingOrder(String message);

  /// No description provided for @writeReview.
  ///
  /// In en, this message translates to:
  /// **'Write a review'**
  String get writeReview;

  /// No description provided for @publishing.
  ///
  /// In en, this message translates to:
  /// **'Publishing…'**
  String get publishing;

  /// No description provided for @publishReview.
  ///
  /// In en, this message translates to:
  /// **'Publish review'**
  String get publishReview;

  /// No description provided for @pleaseChooseStarRating.
  ///
  /// In en, this message translates to:
  /// **'Please choose a star rating first.'**
  String get pleaseChooseStarRating;

  /// No description provided for @reviewYourExperience.
  ///
  /// In en, this message translates to:
  /// **'Review your experience'**
  String get reviewYourExperience;

  /// No description provided for @rateOverallExperience.
  ///
  /// In en, this message translates to:
  /// **'How would you rate your overall experience with this seller?'**
  String get rateOverallExperience;

  /// No description provided for @freelancerForContract.
  ///
  /// In en, this message translates to:
  /// **'Freelancer for this contract'**
  String get freelancerForContract;

  /// No description provided for @selectRating.
  ///
  /// In en, this message translates to:
  /// **'Select rating'**
  String get selectRating;

  /// No description provided for @yourFeedback.
  ///
  /// In en, this message translates to:
  /// **'Your feedback'**
  String get yourFeedback;

  /// No description provided for @feedbackHint.
  ///
  /// In en, this message translates to:
  /// **'Share what went well or what could improve…'**
  String get feedbackHint;

  /// No description provided for @uploadImageOptional.
  ///
  /// In en, this message translates to:
  /// **'Upload image (optional)'**
  String get uploadImageOptional;

  /// No description provided for @tapToAdd.
  ///
  /// In en, this message translates to:
  /// **'Tap to add'**
  String get tapToAdd;

  /// No description provided for @removePhoto.
  ///
  /// In en, this message translates to:
  /// **'Remove photo'**
  String get removePhoto;

  /// No description provided for @reviewAlreadySubmitted.
  ///
  /// In en, this message translates to:
  /// **'You already submitted a review for this order.'**
  String get reviewAlreadySubmitted;

  /// No description provided for @couldNotPublishReview.
  ///
  /// In en, this message translates to:
  /// **'Could not publish review: {message}'**
  String couldNotPublishReview(String message);

  /// No description provided for @couldNotOpenPicker.
  ///
  /// In en, this message translates to:
  /// **'Could not open picker: {message}'**
  String couldNotOpenPicker(String message);

  /// No description provided for @mapMovePinJob.
  ///
  /// In en, this message translates to:
  /// **'Move the map so the pin marks the job site.'**
  String get mapMovePinJob;

  /// No description provided for @mapMovePinProfile.
  ///
  /// In en, this message translates to:
  /// **'Move the map so the pin marks your spot.'**
  String get mapMovePinProfile;

  /// No description provided for @mapUseThisLocation.
  ///
  /// In en, this message translates to:
  /// **'Use this location'**
  String get mapUseThisLocation;

  /// No description provided for @mapAddressLookupFailed.
  ///
  /// In en, this message translates to:
  /// **'Address lookup failed: {message}'**
  String mapAddressLookupFailed(String message);

  /// No description provided for @mapNoAddressForPoint.
  ///
  /// In en, this message translates to:
  /// **'Could not read an address for this point. Try moving the map.'**
  String get mapNoAddressForPoint;

  /// No description provided for @mapNoCityCountryFound.
  ///
  /// In en, this message translates to:
  /// **'No city or country found. Try zooming in closer.'**
  String get mapNoCityCountryFound;

  /// No description provided for @pickLocationOnMap.
  ///
  /// In en, this message translates to:
  /// **'Pick location on map'**
  String get pickLocationOnMap;

  /// No description provided for @mapPinConfirmHint.
  ///
  /// In en, this message translates to:
  /// **'Center the pin on your spot, then confirm.'**
  String get mapPinConfirmHint;

  /// No description provided for @mapOrType.
  ///
  /// In en, this message translates to:
  /// **'Map or type'**
  String get mapOrType;

  /// No description provided for @supportCommonQuestions.
  ///
  /// In en, this message translates to:
  /// **'Common Questions'**
  String get supportCommonQuestions;

  /// No description provided for @supportLiveChat.
  ///
  /// In en, this message translates to:
  /// **'Live Chat'**
  String get supportLiveChat;

  /// No description provided for @supportProfileLoadFailed.
  ///
  /// In en, this message translates to:
  /// **'Could not load your profile for support chat.'**
  String get supportProfileLoadFailed;

  /// No description provided for @supportLiveChatNotConfigured.
  ///
  /// In en, this message translates to:
  /// **'Live chat is not configured yet.'**
  String get supportLiveChatNotConfigured;

  /// No description provided for @supportTawkEnvHint.
  ///
  /// In en, this message translates to:
  /// **'Add TAWK_DIRECT_CHAT_LINK to your .env file (see .env.example). FAQ answers are still available in the first tab.'**
  String get supportTawkEnvHint;

  /// No description provided for @supportNoQuestionsYet.
  ///
  /// In en, this message translates to:
  /// **'No questions available yet.'**
  String get supportNoQuestionsYet;

  /// No description provided for @supportStillNeedHelp.
  ///
  /// In en, this message translates to:
  /// **'Still need help? Chat with us'**
  String get supportStillNeedHelp;

  /// No description provided for @pleaseEnterValidAmount.
  ///
  /// In en, this message translates to:
  /// **'Please enter a valid amount'**
  String get pleaseEnterValidAmount;

  /// No description provided for @depositSubmittedSuccess.
  ///
  /// In en, this message translates to:
  /// **'Deposit submitted successfully!'**
  String get depositSubmittedSuccess;

  /// No description provided for @submitting.
  ///
  /// In en, this message translates to:
  /// **'Submitting...'**
  String get submitting;

  /// No description provided for @submit.
  ///
  /// In en, this message translates to:
  /// **'Submit'**
  String get submit;

  /// No description provided for @noDepositHistory.
  ///
  /// In en, this message translates to:
  /// **'No deposit history'**
  String get noDepositHistory;

  /// No description provided for @withdrawalRequestSubmitted.
  ///
  /// In en, this message translates to:
  /// **'Withdrawal request submitted!'**
  String get withdrawalRequestSubmitted;

  /// No description provided for @withdrawMethod.
  ///
  /// In en, this message translates to:
  /// **'Withdraw method'**
  String get withdrawMethod;

  /// No description provided for @enterAmount.
  ///
  /// In en, this message translates to:
  /// **'Enter amount'**
  String get enterAmount;

  /// No description provided for @creditOrDebitCard.
  ///
  /// In en, this message translates to:
  /// **'Credit or Debit Card'**
  String get creditOrDebitCard;

  /// No description provided for @txnTypeDeposit.
  ///
  /// In en, this message translates to:
  /// **'Deposit'**
  String get txnTypeDeposit;

  /// No description provided for @txnTypeWithdrawal.
  ///
  /// In en, this message translates to:
  /// **'Withdrawal'**
  String get txnTypeWithdrawal;

  /// No description provided for @txnTypeEarning.
  ///
  /// In en, this message translates to:
  /// **'Earning'**
  String get txnTypeEarning;

  /// No description provided for @txnTypePayment.
  ///
  /// In en, this message translates to:
  /// **'Payment'**
  String get txnTypePayment;

  /// No description provided for @processingOrder.
  ///
  /// In en, this message translates to:
  /// **'We\'re processing\nyour Order'**
  String get processingOrder;

  /// No description provided for @stayTuned.
  ///
  /// In en, this message translates to:
  /// **'Stay tuned...'**
  String get stayTuned;

  /// No description provided for @chooseYourAction.
  ///
  /// In en, this message translates to:
  /// **'Choose your Action'**
  String get chooseYourAction;

  /// No description provided for @openGallery.
  ///
  /// In en, this message translates to:
  /// **'Open Gallery'**
  String get openGallery;

  /// No description provided for @openFile.
  ///
  /// In en, this message translates to:
  /// **'Open File'**
  String get openFile;

  /// No description provided for @congratulations.
  ///
  /// In en, this message translates to:
  /// **'Congratulations!'**
  String get congratulations;

  /// No description provided for @profileSetupCompleteBody.
  ///
  /// In en, this message translates to:
  /// **'Your profile is successfully completed. You can make more changes after it\'s live.'**
  String get profileSetupCompleteBody;

  /// No description provided for @cancelJobConfirmTitle.
  ///
  /// In en, this message translates to:
  /// **'Are You Sure Cancel Your\nJob Post!'**
  String get cancelJobConfirmTitle;

  /// No description provided for @noLabel.
  ///
  /// In en, this message translates to:
  /// **'No'**
  String get noLabel;

  /// No description provided for @yesLabel.
  ///
  /// In en, this message translates to:
  /// **'Yes'**
  String get yesLabel;

  /// No description provided for @cancelOrderWhy.
  ///
  /// In en, this message translates to:
  /// **'Why are you Cancel Order?'**
  String get cancelOrderWhy;

  /// No description provided for @enterReason.
  ///
  /// In en, this message translates to:
  /// **'Enter Reason'**
  String get enterReason;

  /// No description provided for @confirm.
  ///
  /// In en, this message translates to:
  /// **'Confirm'**
  String get confirm;

  /// No description provided for @reviewSuccessTitle.
  ///
  /// In en, this message translates to:
  /// **'Successfully'**
  String get reviewSuccessTitle;

  /// No description provided for @reviewSuccessBody.
  ///
  /// In en, this message translates to:
  /// **'Thank you so much you\'ve just publish your review'**
  String get reviewSuccessBody;

  /// No description provided for @gotIt.
  ///
  /// In en, this message translates to:
  /// **'Got it!'**
  String get gotIt;

  /// No description provided for @withdrawAmount.
  ///
  /// In en, this message translates to:
  /// **'Withdraw Amount'**
  String get withdrawAmount;

  /// No description provided for @reviewWithdrawalDetails.
  ///
  /// In en, this message translates to:
  /// **'Review your withdrawal details'**
  String get reviewWithdrawalDetails;

  /// No description provided for @transferTo.
  ///
  /// In en, this message translates to:
  /// **'Transfer To'**
  String get transferTo;

  /// No description provided for @account.
  ///
  /// In en, this message translates to:
  /// **'Account'**
  String get account;

  /// No description provided for @withdrawalCompleted.
  ///
  /// In en, this message translates to:
  /// **'Withdrawal Completed'**
  String get withdrawalCompleted;

  /// No description provided for @orderCompleted.
  ///
  /// In en, this message translates to:
  /// **'Order Completed'**
  String get orderCompleted;

  /// No description provided for @detailsLabel.
  ///
  /// In en, this message translates to:
  /// **'Details'**
  String get detailsLabel;

  /// No description provided for @profileUpdatedShort.
  ///
  /// In en, this message translates to:
  /// **'Profile updated!'**
  String get profileUpdatedShort;

  /// No description provided for @filterAll.
  ///
  /// In en, this message translates to:
  /// **'All'**
  String get filterAll;

  /// No description provided for @refreshTooltip.
  ///
  /// In en, this message translates to:
  /// **'Refresh'**
  String get refreshTooltip;

  /// No description provided for @noContractsYet.
  ///
  /// In en, this message translates to:
  /// **'No contracts yet'**
  String get noContractsYet;

  /// No description provided for @noContractsYetClientHint.
  ///
  /// In en, this message translates to:
  /// **'Hire someone on a job to start a contract here.'**
  String get noContractsYetClientHint;

  /// No description provided for @noContractsYetSellerHint.
  ///
  /// In en, this message translates to:
  /// **'Apply to jobs and get hired — contracts will show up here.'**
  String get noContractsYetSellerHint;

  /// No description provided for @noFilteredContractsHint.
  ///
  /// In en, this message translates to:
  /// **'Try another status filter, or clear filters to see all contracts.'**
  String get noFilteredContractsHint;

  /// No description provided for @noFilteredContracts.
  ///
  /// In en, this message translates to:
  /// **'No {status} contracts'**
  String noFilteredContracts(String status);

  /// No description provided for @contractOverdue.
  ///
  /// In en, this message translates to:
  /// **'Overdue'**
  String get contractOverdue;

  /// No description provided for @deadlineDaysHoursLeft.
  ///
  /// In en, this message translates to:
  /// **'{days}d {hours}h left'**
  String deadlineDaysHoursLeft(int days, int hours);

  /// No description provided for @deadlineHoursMinutesLeft.
  ///
  /// In en, this message translates to:
  /// **'{hours}h {minutes}m left'**
  String deadlineHoursMinutesLeft(int hours, int minutes);

  /// No description provided for @deadlineMinutesLeft.
  ///
  /// In en, this message translates to:
  /// **'{minutes}m left'**
  String deadlineMinutesLeft(int minutes);

  /// No description provided for @contractStartedOn.
  ///
  /// In en, this message translates to:
  /// **'Started {date}'**
  String contractStartedOn(String date);

  /// No description provided for @amountCaps.
  ///
  /// In en, this message translates to:
  /// **'AMOUNT'**
  String get amountCaps;

  /// No description provided for @orderDetailsTitle.
  ///
  /// In en, this message translates to:
  /// **'Order Details'**
  String get orderDetailsTitle;

  /// No description provided for @orderIdHash.
  ///
  /// In en, this message translates to:
  /// **'Order ID #{id}'**
  String orderIdHash(String id);

  /// No description provided for @sellerColon.
  ///
  /// In en, this message translates to:
  /// **'Seller:'**
  String get sellerColon;

  /// No description provided for @clientColon.
  ///
  /// In en, this message translates to:
  /// **'Client:'**
  String get clientColon;

  /// No description provided for @labelTitle.
  ///
  /// In en, this message translates to:
  /// **'Title'**
  String get labelTitle;

  /// No description provided for @labelServiceInfo.
  ///
  /// In en, this message translates to:
  /// **'Service Info'**
  String get labelServiceInfo;

  /// No description provided for @labelDuration.
  ///
  /// In en, this message translates to:
  /// **'Duration'**
  String get labelDuration;

  /// No description provided for @labelStatus.
  ///
  /// In en, this message translates to:
  /// **'Status'**
  String get labelStatus;

  /// No description provided for @labelRevisions.
  ///
  /// In en, this message translates to:
  /// **'Revisions'**
  String get labelRevisions;

  /// No description provided for @orderSummary.
  ///
  /// In en, this message translates to:
  /// **'Order Summary'**
  String get orderSummary;

  /// No description provided for @subtotal.
  ///
  /// In en, this message translates to:
  /// **'Subtotal'**
  String get subtotal;

  /// No description provided for @labelTotal.
  ///
  /// In en, this message translates to:
  /// **'Total'**
  String get labelTotal;

  /// No description provided for @deliveryDate.
  ///
  /// In en, this message translates to:
  /// **'Delivery date'**
  String get deliveryDate;

  /// No description provided for @readMoreSuffix.
  ///
  /// In en, this message translates to:
  /// **'..Read more'**
  String get readMoreSuffix;

  /// No description provided for @readLessSuffix.
  ///
  /// In en, this message translates to:
  /// **'..Read less'**
  String get readLessSuffix;

  /// No description provided for @closeAction.
  ///
  /// In en, this message translates to:
  /// **'Close'**
  String get closeAction;

  /// No description provided for @contractCancelledSnack.
  ///
  /// In en, this message translates to:
  /// **'Contract cancelled'**
  String get contractCancelledSnack;

  /// No description provided for @contractKeptActive.
  ///
  /// In en, this message translates to:
  /// **'Contract kept active'**
  String get contractKeptActive;

  /// No description provided for @markJobComplete.
  ///
  /// In en, this message translates to:
  /// **'Mark job complete'**
  String get markJobComplete;

  /// No description provided for @completingEllipsis.
  ///
  /// In en, this message translates to:
  /// **'Completing…'**
  String get completingEllipsis;

  /// No description provided for @markJobCompleteTitle.
  ///
  /// In en, this message translates to:
  /// **'Mark this job complete?'**
  String get markJobCompleteTitle;

  /// No description provided for @markJobCompleteDeliveredBody.
  ///
  /// In en, this message translates to:
  /// **'You are confirming you received the work from {seller} through their delivery submission. The contract will close as completed and you can leave a review next.'**
  String markJobCompleteDeliveredBody(String seller);

  /// No description provided for @markJobCompleteManualBody.
  ///
  /// In en, this message translates to:
  /// **'You are about to close this contract as finished. Use this when you have received the deliverables from {seller} (for example via chat or files), even if they have not pressed \"Submit delivery\" yet.'**
  String markJobCompleteManualBody(String seller);

  /// No description provided for @notYet.
  ///
  /// In en, this message translates to:
  /// **'Not yet'**
  String get notYet;

  /// No description provided for @yesCompleteJob.
  ///
  /// In en, this message translates to:
  /// **'Yes, complete job'**
  String get yesCompleteJob;

  /// No description provided for @jobMarkedCompleteThanks.
  ///
  /// In en, this message translates to:
  /// **'Job marked complete. Thank you!'**
  String get jobMarkedCompleteThanks;

  /// No description provided for @leaveReviewTitle.
  ///
  /// In en, this message translates to:
  /// **'Leave a review?'**
  String get leaveReviewTitle;

  /// No description provided for @leaveReviewBody.
  ///
  /// In en, this message translates to:
  /// **'Reviews help other clients and reward great work.'**
  String get leaveReviewBody;

  /// No description provided for @later.
  ///
  /// In en, this message translates to:
  /// **'Later'**
  String get later;

  /// No description provided for @couldNotCompleteJob.
  ///
  /// In en, this message translates to:
  /// **'Could not complete job: {message}'**
  String couldNotCompleteJob(String message);

  /// No description provided for @couldNotOpenReviewMissingSeller.
  ///
  /// In en, this message translates to:
  /// **'Could not open review (missing seller).'**
  String get couldNotOpenReviewMissingSeller;

  /// No description provided for @sellerSubmittedDelivery.
  ///
  /// In en, this message translates to:
  /// **'Seller submitted delivery'**
  String get sellerSubmittedDelivery;

  /// No description provided for @yourDelivery.
  ///
  /// In en, this message translates to:
  /// **'Your delivery'**
  String get yourDelivery;

  /// No description provided for @deliveredCalloutBody.
  ///
  /// In en, this message translates to:
  /// **'Review what they sent. When you are happy with the result, tap Mark job complete below to close the order. To chat with the seller, use the ⋮ menu at the top.'**
  String get deliveredCalloutBody;

  /// No description provided for @openContractCalloutBody.
  ///
  /// In en, this message translates to:
  /// **'Your freelancer must submit delivery before you can complete this contract. You can message the seller from the ⋮ menu at the top.'**
  String get openContractCalloutBody;

  /// No description provided for @cancellationRequestBannerBody.
  ///
  /// In en, this message translates to:
  /// **'{seller} asked to cancel this contract. You can approve or keep it active. If you do not respond within 48 hours, the contract stays active.'**
  String cancellationRequestBannerBody(String seller);

  /// No description provided for @respondUsingBanner.
  ///
  /// In en, this message translates to:
  /// **'Respond using the banner above.'**
  String get respondUsingBanner;

  /// No description provided for @reviewSubmittedForOrder.
  ///
  /// In en, this message translates to:
  /// **'You submitted a review for this order.'**
  String get reviewSubmittedForOrder;

  /// No description provided for @errorLoadingOrder.
  ///
  /// In en, this message translates to:
  /// **'Error loading order: {message}'**
  String errorLoadingOrder(String message);

  /// No description provided for @errorLoadingOrders.
  ///
  /// In en, this message translates to:
  /// **'Error loading orders: {message}'**
  String errorLoadingOrders(String message);

  /// No description provided for @onboardingNotSet.
  ///
  /// In en, this message translates to:
  /// **'Not set'**
  String get onboardingNotSet;

  /// No description provided for @onboardingAcknowledgedShort.
  ///
  /// In en, this message translates to:
  /// **'Acknowledged'**
  String get onboardingAcknowledgedShort;

  /// No description provided for @onboardingAwaitingAck.
  ///
  /// In en, this message translates to:
  /// **'Awaiting ack'**
  String get onboardingAwaitingAck;

  /// No description provided for @theSeller.
  ///
  /// In en, this message translates to:
  /// **'the seller'**
  String get theSeller;

  /// No description provided for @roleSeller.
  ///
  /// In en, this message translates to:
  /// **'Seller'**
  String get roleSeller;

  /// No description provided for @roleClient.
  ///
  /// In en, this message translates to:
  /// **'Employer'**
  String get roleClient;

  /// No description provided for @cancellationRequestSent48h.
  ///
  /// In en, this message translates to:
  /// **'Cancellation request sent. Waiting for client response (48h).'**
  String get cancellationRequestSent48h;

  /// No description provided for @cancellationRequestWithdrawn.
  ///
  /// In en, this message translates to:
  /// **'Cancellation request withdrawn'**
  String get cancellationRequestWithdrawn;

  /// No description provided for @orderMarkedComplete.
  ///
  /// In en, this message translates to:
  /// **'Order marked complete'**
  String get orderMarkedComplete;

  /// No description provided for @withdrawingEllipsis.
  ///
  /// In en, this message translates to:
  /// **'Withdrawing…'**
  String get withdrawingEllipsis;

  /// No description provided for @requestCancel.
  ///
  /// In en, this message translates to:
  /// **'Request cancel'**
  String get requestCancel;

  /// No description provided for @completeOrder.
  ///
  /// In en, this message translates to:
  /// **'Complete Order'**
  String get completeOrder;

  /// No description provided for @waitingForClientApproval.
  ///
  /// In en, this message translates to:
  /// **'Waiting for client approval'**
  String get waitingForClientApproval;

  /// No description provided for @waitingForDelivery.
  ///
  /// In en, this message translates to:
  /// **'Waiting for delivery'**
  String get waitingForDelivery;

  /// No description provided for @waitingForClientResponse.
  ///
  /// In en, this message translates to:
  /// **'Waiting for client response'**
  String get waitingForClientResponse;

  /// No description provided for @sellerCancellationPendingBody.
  ///
  /// In en, this message translates to:
  /// **'Your cancellation request was sent. The client has up to 48 hours to approve or keep the contract active.'**
  String get sellerCancellationPendingBody;

  /// No description provided for @contractCancelledTitle.
  ///
  /// In en, this message translates to:
  /// **'Contract cancelled'**
  String get contractCancelledTitle;

  /// No description provided for @viewFirstDayInstructions.
  ///
  /// In en, this message translates to:
  /// **'View first-day instructions'**
  String get viewFirstDayInstructions;

  /// No description provided for @readFirstDayInstructions.
  ///
  /// In en, this message translates to:
  /// **'Read first-day instructions'**
  String get readFirstDayInstructions;

  /// No description provided for @firstDayInstructionsSharedBody.
  ///
  /// In en, this message translates to:
  /// **'Your client shared site details, access, and contacts for this job.'**
  String get firstDayInstructionsSharedBody;

  /// No description provided for @openInstructions.
  ///
  /// In en, this message translates to:
  /// **'Open instructions'**
  String get openInstructions;

  /// No description provided for @errorLoadingApplications.
  ///
  /// In en, this message translates to:
  /// **'Error loading applications: {message}'**
  String errorLoadingApplications(String message);

  /// No description provided for @messageClientTooltip.
  ///
  /// In en, this message translates to:
  /// **'Message client'**
  String get messageClientTooltip;

  /// No description provided for @openAttendance.
  ///
  /// In en, this message translates to:
  /// **'Open attendance'**
  String get openAttendance;

  /// No description provided for @instructionsReadyTap.
  ///
  /// In en, this message translates to:
  /// **'Instructions ready, read here'**
  String get instructionsReadyTap;

  /// No description provided for @rateExperienceWithClient.
  ///
  /// In en, this message translates to:
  /// **'How would you rate your overall experience with this client?'**
  String get rateExperienceWithClient;

  /// No description provided for @postedThisContract.
  ///
  /// In en, this message translates to:
  /// **'Posted this contract'**
  String get postedThisContract;

  /// No description provided for @errorLoadingJobPosts.
  ///
  /// In en, this message translates to:
  /// **'Error loading job posts: {message}'**
  String errorLoadingJobPosts(String message);

  /// No description provided for @jobPostClosed.
  ///
  /// In en, this message translates to:
  /// **'Job post closed'**
  String get jobPostClosed;

  /// No description provided for @addFirstDayInstructionsTitle.
  ///
  /// In en, this message translates to:
  /// **'Add first-day instructions?'**
  String get addFirstDayInstructionsTitle;

  /// No description provided for @addFirstDayInstructionsBody.
  ///
  /// In en, this message translates to:
  /// **'Share office location, building access, and site rules so your new hire knows what to do before day one.'**
  String get addFirstDayInstructionsBody;

  /// No description provided for @addInstructionsNow.
  ///
  /// In en, this message translates to:
  /// **'Add instructions now'**
  String get addInstructionsNow;

  /// No description provided for @sendLater.
  ///
  /// In en, this message translates to:
  /// **'Send later'**
  String get sendLater;

  /// No description provided for @contractNotFoundForHire.
  ///
  /// In en, this message translates to:
  /// **'Contract not found for this hire.'**
  String get contractNotFoundForHire;

  /// No description provided for @applicationRejected.
  ///
  /// In en, this message translates to:
  /// **'Application rejected'**
  String get applicationRejected;

  /// No description provided for @hireFreelancerTitle.
  ///
  /// In en, this message translates to:
  /// **'Hire freelancer?'**
  String get hireFreelancerTitle;

  /// No description provided for @hireAction.
  ///
  /// In en, this message translates to:
  /// **'Hire'**
  String get hireAction;

  /// No description provided for @rejectApplicationTitle.
  ///
  /// In en, this message translates to:
  /// **'Reject application?'**
  String get rejectApplicationTitle;

  /// No description provided for @rejectApplicationConfirmBody.
  ///
  /// In en, this message translates to:
  /// **'Reject {name}\'s application? This can\'t be undone.'**
  String rejectApplicationConfirmBody(String name);

  /// No description provided for @closeJobTitle.
  ///
  /// In en, this message translates to:
  /// **'Close this job?'**
  String get closeJobTitle;

  /// No description provided for @closeJobConfirmBody.
  ///
  /// In en, this message translates to:
  /// **'This job will close to new applicants. Existing applications stay on your list.'**
  String get closeJobConfirmBody;

  /// No description provided for @closeJob.
  ///
  /// In en, this message translates to:
  /// **'Close Job'**
  String get closeJob;

  /// No description provided for @attendanceSettingsUpdated.
  ///
  /// In en, this message translates to:
  /// **'Attendance settings updated'**
  String get attendanceSettingsUpdated;

  /// No description provided for @jobPostedSuccess.
  ///
  /// In en, this message translates to:
  /// **'Job posted successfully!'**
  String get jobPostedSuccess;

  /// No description provided for @pleaseEnterJobTitle.
  ///
  /// In en, this message translates to:
  /// **'Please enter a job title'**
  String get pleaseEnterJobTitle;

  /// No description provided for @pleaseSelectCategory.
  ///
  /// In en, this message translates to:
  /// **'Please select a category'**
  String get pleaseSelectCategory;

  /// No description provided for @enterValidCategory.
  ///
  /// In en, this message translates to:
  /// **'Enter a valid category'**
  String get enterValidCategory;

  /// No description provided for @pleaseEnterDescription.
  ///
  /// In en, this message translates to:
  /// **'Please enter a description'**
  String get pleaseEnterDescription;

  /// No description provided for @pleaseEnterLocation.
  ///
  /// In en, this message translates to:
  /// **'Please enter a location'**
  String get pleaseEnterLocation;

  /// No description provided for @createJobStepBasics.
  ///
  /// In en, this message translates to:
  /// **'Basics'**
  String get createJobStepBasics;

  /// No description provided for @createJobStepDetails.
  ///
  /// In en, this message translates to:
  /// **'Details'**
  String get createJobStepDetails;

  /// No description provided for @createJobStepLocation.
  ///
  /// In en, this message translates to:
  /// **'Location'**
  String get createJobStepLocation;

  /// No description provided for @createJobStepBudget.
  ///
  /// In en, this message translates to:
  /// **'Budget'**
  String get createJobStepBudget;

  /// No description provided for @createJobPostTitle.
  ///
  /// In en, this message translates to:
  /// **'Create Job Post'**
  String get createJobPostTitle;

  /// No description provided for @shortJobTitleHint.
  ///
  /// In en, this message translates to:
  /// **'Short title for the work'**
  String get shortJobTitleHint;

  /// No description provided for @categoryNameLabel.
  ///
  /// In en, this message translates to:
  /// **'Category name'**
  String get categoryNameLabel;

  /// No description provided for @categoryNameHint.
  ///
  /// In en, this message translates to:
  /// **'e.g. Janitor, Baker, Waiter'**
  String get categoryNameHint;

  /// No description provided for @describeJobLabel.
  ///
  /// In en, this message translates to:
  /// **'Describe the job'**
  String get describeJobLabel;

  /// No description provided for @describeJobHint.
  ///
  /// In en, this message translates to:
  /// **'Scope, timeline, skills needed'**
  String get describeJobHint;

  /// No description provided for @workersNeeded.
  ///
  /// In en, this message translates to:
  /// **'Workers needed'**
  String get workersNeeded;

  /// No description provided for @limitHiresToCount.
  ///
  /// In en, this message translates to:
  /// **'Limit hires to this count'**
  String get limitHiresToCount;

  /// No description provided for @budgetMinLabel.
  ///
  /// In en, this message translates to:
  /// **'Min'**
  String get budgetMinLabel;

  /// No description provided for @budgetMaxLabel.
  ///
  /// In en, this message translates to:
  /// **'Max'**
  String get budgetMaxLabel;

  /// No description provided for @budgetMinHint.
  ///
  /// In en, this message translates to:
  /// **'Min (optional)'**
  String get budgetMinHint;

  /// No description provided for @budgetMaxHint.
  ///
  /// In en, this message translates to:
  /// **'Max (optional)'**
  String get budgetMaxHint;

  /// No description provided for @rateTypeLabel.
  ///
  /// In en, this message translates to:
  /// **'Rate type'**
  String get rateTypeLabel;

  /// No description provided for @budgetBasisFixed.
  ///
  /// In en, this message translates to:
  /// **'Fixed — total project'**
  String get budgetBasisFixed;

  /// No description provided for @budgetBasisPerHour.
  ///
  /// In en, this message translates to:
  /// **'Per hour'**
  String get budgetBasisPerHour;

  /// No description provided for @budgetBasisPerDay.
  ///
  /// In en, this message translates to:
  /// **'Per day'**
  String get budgetBasisPerDay;

  /// No description provided for @budgetBasisPerMonth.
  ///
  /// In en, this message translates to:
  /// **'Per month'**
  String get budgetBasisPerMonth;

  /// No description provided for @postingEllipsis.
  ///
  /// In en, this message translates to:
  /// **'Posting…'**
  String get postingEllipsis;

  /// No description provided for @reviewAndPost.
  ///
  /// In en, this message translates to:
  /// **'Review & post'**
  String get reviewAndPost;

  /// No description provided for @nextStep.
  ///
  /// In en, this message translates to:
  /// **'Next'**
  String get nextStep;

  /// No description provided for @maxJobSkillsSnackbar.
  ///
  /// In en, this message translates to:
  /// **'You can add up to {max} skills.'**
  String maxJobSkillsSnackbar(int max);

  /// No description provided for @shiftTimesBothOrNeither.
  ///
  /// In en, this message translates to:
  /// **'Set both start and end time, or leave both empty.'**
  String get shiftTimesBothOrNeither;

  /// No description provided for @createJobBasicsSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Title, category, skills, and job type.'**
  String get createJobBasicsSubtitle;

  /// No description provided for @createJobDetailsSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Describe the work and how many people you need.'**
  String get createJobDetailsSubtitle;

  /// No description provided for @createJobLocationSubtitle.
  ///
  /// In en, this message translates to:
  /// **'On-site or remote, and where the work happens.'**
  String get createJobLocationSubtitle;

  /// No description provided for @createJobBudgetSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Optional pay range, then review and post.'**
  String get createJobBudgetSubtitle;

  /// No description provided for @savedAsCategory.
  ///
  /// In en, this message translates to:
  /// **'Saved as: {name}'**
  String savedAsCategory(String name);

  /// No description provided for @jobSkillsTagHint.
  ///
  /// In en, this message translates to:
  /// **'Tag skills freelancers need for this job (optional).'**
  String get jobSkillsTagHint;

  /// No description provided for @shiftSchedule.
  ///
  /// In en, this message translates to:
  /// **'Shift schedule'**
  String get shiftSchedule;

  /// No description provided for @shiftScheduleHint.
  ///
  /// In en, this message translates to:
  /// **'Optional work day and clock times (e.g. 06:00–15:00). Used later for attendance and timed chat.'**
  String get shiftScheduleHint;

  /// No description provided for @workDateLabel.
  ///
  /// In en, this message translates to:
  /// **'Work date'**
  String get workDateLabel;

  /// No description provided for @optionalLabel.
  ///
  /// In en, this message translates to:
  /// **'Optional'**
  String get optionalLabel;

  /// No description provided for @shiftStartLabel.
  ///
  /// In en, this message translates to:
  /// **'Start'**
  String get shiftStartLabel;

  /// No description provided for @shiftEndLabel.
  ///
  /// In en, this message translates to:
  /// **'End'**
  String get shiftEndLabel;

  /// No description provided for @hiringSection.
  ///
  /// In en, this message translates to:
  /// **'Hiring'**
  String get hiringSection;

  /// No description provided for @numberToHire.
  ///
  /// In en, this message translates to:
  /// **'Number to hire'**
  String get numberToHire;

  /// No description provided for @noCapUntilCloseJob.
  ///
  /// In en, this message translates to:
  /// **'No cap until you close the job'**
  String get noCapUntilCloseJob;

  /// No description provided for @budgetAppliesAs.
  ///
  /// In en, this message translates to:
  /// **'Budget applies as'**
  String get budgetAppliesAs;

  /// No description provided for @reviewSection.
  ///
  /// In en, this message translates to:
  /// **'Review'**
  String get reviewSection;

  /// No description provided for @categoryLabel.
  ///
  /// In en, this message translates to:
  /// **'Category'**
  String get categoryLabel;

  /// No description provided for @shiftLabel.
  ///
  /// In en, this message translates to:
  /// **'Shift'**
  String get shiftLabel;

  /// No description provided for @workersLabel.
  ///
  /// In en, this message translates to:
  /// **'Workers'**
  String get workersLabel;

  /// No description provided for @noLimitLabel.
  ///
  /// In en, this message translates to:
  /// **'No limit'**
  String get noLimitLabel;

  /// No description provided for @locationOnSite.
  ///
  /// In en, this message translates to:
  /// **'On-site'**
  String get locationOnSite;

  /// No description provided for @locationRemote.
  ///
  /// In en, this message translates to:
  /// **'Remote'**
  String get locationRemote;

  /// No description provided for @thisFreelancer.
  ///
  /// In en, this message translates to:
  /// **'this freelancer'**
  String get thisFreelancer;

  /// No description provided for @hireConfirmUnlimited.
  ///
  /// In en, this message translates to:
  /// **'Accept {name}\'s offer ({price})? The job stays open so you can hire more freelancers until you close it.'**
  String hireConfirmUnlimited(String name, String price);

  /// No description provided for @hireConfirmFillsAll.
  ///
  /// In en, this message translates to:
  /// **'Accept {name}\'s offer ({price})? This fills your last hire spot ({filled} of {cap}). The job will close to new applicants. Other applications stay on your list as pending — reject them only if you do not want them.'**
  String hireConfirmFillsAll(String name, String price, int filled, int cap);

  /// No description provided for @hireConfirmRemaining.
  ///
  /// In en, this message translates to:
  /// **'Accept {name}\'s offer ({price})? After this hire you will have {remaining} more open spots ({filled} of {cap} filled). Other pending applications stay open.'**
  String hireConfirmRemaining(
      String name, String price, int remaining, int filled, int cap);

  /// No description provided for @hiredJobFull.
  ///
  /// In en, this message translates to:
  /// **'Hired! This job is now full and closed to new applicants.'**
  String get hiredJobFull;

  /// No description provided for @hiredContractCreated.
  ///
  /// In en, this message translates to:
  /// **'Hired! Contract created.'**
  String get hiredContractCreated;

  /// No description provided for @jobPostFallback.
  ///
  /// In en, this message translates to:
  /// **'Job Post'**
  String get jobPostFallback;

  /// No description provided for @budgetLabel.
  ///
  /// In en, this message translates to:
  /// **'Budget'**
  String get budgetLabel;

  /// No description provided for @dateLabel.
  ///
  /// In en, this message translates to:
  /// **'Date'**
  String get dateLabel;

  /// No description provided for @areaLabel.
  ///
  /// In en, this message translates to:
  /// **'Area'**
  String get areaLabel;

  /// No description provided for @applicationsCount.
  ///
  /// In en, this message translates to:
  /// **'Applications ({count})'**
  String applicationsCount(int count);

  /// No description provided for @messageFreelancerTooltip.
  ///
  /// In en, this message translates to:
  /// **'Message freelancer'**
  String get messageFreelancerTooltip;

  /// No description provided for @attendanceQrShort.
  ///
  /// In en, this message translates to:
  /// **'QR'**
  String get attendanceQrShort;

  /// No description provided for @stepProgressWithLabel.
  ///
  /// In en, this message translates to:
  /// **'Step {current} of {total} · {label}'**
  String stepProgressWithLabel(int current, int total, String label);

  /// No description provided for @totalJobPostCount.
  ///
  /// In en, this message translates to:
  /// **'Total Job Post ({count})'**
  String totalJobPostCount(int count);

  /// No description provided for @applicationsSection.
  ///
  /// In en, this message translates to:
  /// **'Applications'**
  String get applicationsSection;

  /// No description provided for @rejectApplication.
  ///
  /// In en, this message translates to:
  /// **'Reject'**
  String get rejectApplication;

  /// No description provided for @freelancerDefault.
  ///
  /// In en, this message translates to:
  /// **'Freelancer'**
  String get freelancerDefault;

  /// No description provided for @submitOfferTitle.
  ///
  /// In en, this message translates to:
  /// **'Submit application'**
  String get submitOfferTitle;

  /// No description provided for @applyAtClientRate.
  ///
  /// In en, this message translates to:
  /// **'Apply at client\'s rate'**
  String get applyAtClientRate;

  /// No description provided for @agreeToClientRate.
  ///
  /// In en, this message translates to:
  /// **'Agree to\nclient\'s rate'**
  String get agreeToClientRate;

  /// No description provided for @customBid.
  ///
  /// In en, this message translates to:
  /// **'Custom\nbid'**
  String get customBid;

  /// No description provided for @offerNoPostedRateWarning.
  ///
  /// In en, this message translates to:
  /// **'This job has no posted rate to agree to. Enter a custom amount instead.'**
  String get offerNoPostedRateWarning;

  /// No description provided for @offerSentAtPostedRate.
  ///
  /// In en, this message translates to:
  /// **'Application sent at client\'s posted rate'**
  String get offerSentAtPostedRate;

  /// No description provided for @offerSentSuccess.
  ///
  /// In en, this message translates to:
  /// **'Your application has been sent'**
  String get offerSentSuccess;

  /// No description provided for @successTitle.
  ///
  /// In en, this message translates to:
  /// **'Success'**
  String get successTitle;

  /// No description provided for @somethingWentWrong.
  ///
  /// In en, this message translates to:
  /// **'Something went wrong'**
  String get somethingWentWrong;

  /// No description provided for @headsUp.
  ///
  /// In en, this message translates to:
  /// **'Heads up'**
  String get headsUp;

  /// No description provided for @youAreOffline.
  ///
  /// In en, this message translates to:
  /// **'You\'re offline. Some actions may not work.'**
  String get youAreOffline;

  /// No description provided for @applyWithoutCounterBody.
  ///
  /// In en, this message translates to:
  /// **'You are applying at the client\'s posted rate. They will see your application at that rate.'**
  String get applyWithoutCounterBody;

  /// No description provided for @clientPostedRate.
  ///
  /// In en, this message translates to:
  /// **'Client\'s posted rate'**
  String get clientPostedRate;

  /// No description provided for @yourApplicationAmount.
  ///
  /// In en, this message translates to:
  /// **'Your application: {amount}'**
  String yourApplicationAmount(String amount);

  /// No description provided for @customBidIntroWithBudget.
  ///
  /// In en, this message translates to:
  /// **'Enter your own amount if you want to bid differently from the client\'s budget.'**
  String get customBidIntroWithBudget;

  /// No description provided for @customBidIntroNoBudget.
  ///
  /// In en, this message translates to:
  /// **'This job has no posted budget — enter the amount you are asking for.'**
  String get customBidIntroNoBudget;

  /// No description provided for @clientPostedPrefix.
  ///
  /// In en, this message translates to:
  /// **'Client posted: {amount}'**
  String clientPostedPrefix(String amount);

  /// No description provided for @yourOfferAmount.
  ///
  /// In en, this message translates to:
  /// **'Your application amount'**
  String get yourOfferAmount;

  /// No description provided for @enterYourBid.
  ///
  /// In en, this message translates to:
  /// **'Enter your bid'**
  String get enterYourBid;

  /// No description provided for @quoteAsLabel.
  ///
  /// In en, this message translates to:
  /// **'Quote as'**
  String get quoteAsLabel;

  /// No description provided for @quoteTotal.
  ///
  /// In en, this message translates to:
  /// **'Total'**
  String get quoteTotal;

  /// No description provided for @quotePerHour.
  ///
  /// In en, this message translates to:
  /// **'/ hour'**
  String get quotePerHour;

  /// No description provided for @quotePerDay.
  ///
  /// In en, this message translates to:
  /// **'/ day'**
  String get quotePerDay;

  /// No description provided for @quotePerMonth.
  ///
  /// In en, this message translates to:
  /// **'/ month'**
  String get quotePerMonth;

  /// No description provided for @offerMessageOptional.
  ///
  /// In en, this message translates to:
  /// **'Message (optional)'**
  String get offerMessageOptional;

  /// No description provided for @offerMessageHint.
  ///
  /// In en, this message translates to:
  /// **'Optional note for the client…'**
  String get offerMessageHint;

  /// No description provided for @offerMessageMinHint.
  ///
  /// In en, this message translates to:
  /// **'If you include a message, use at least {count} characters'**
  String offerMessageMinHint(int count);

  /// No description provided for @offerMessageMinChars.
  ///
  /// In en, this message translates to:
  /// **'Please write at least {count} characters in your message'**
  String offerMessageMinChars(int count);

  /// No description provided for @offerMessageCharCount.
  ///
  /// In en, this message translates to:
  /// **'{current} / {min} characters minimum'**
  String offerMessageCharCount(int current, int min);

  /// No description provided for @findJobsTitle.
  ///
  /// In en, this message translates to:
  /// **'Find Jobs'**
  String get findJobsTitle;

  /// No description provided for @couldNotLoadSkillsFilter.
  ///
  /// In en, this message translates to:
  /// **'Could not load skills filter. Pull to refresh later.'**
  String get couldNotLoadSkillsFilter;

  /// No description provided for @buyerRequestDetailsTitle.
  ///
  /// In en, this message translates to:
  /// **'Job details'**
  String get buyerRequestDetailsTitle;

  /// No description provided for @submitOfferAction.
  ///
  /// In en, this message translates to:
  /// **'Submit application'**
  String get submitOfferAction;

  /// No description provided for @cannotSubmitApplication.
  ///
  /// In en, this message translates to:
  /// **'Cannot apply'**
  String get cannotSubmitApplication;

  /// No description provided for @applicationsReceived.
  ///
  /// In en, this message translates to:
  /// **'Applications'**
  String get applicationsReceived;

  /// No description provided for @offersCount.
  ///
  /// In en, this message translates to:
  /// **'{count} applications'**
  String offersCount(int count);

  /// No description provided for @locationLabel.
  ///
  /// In en, this message translates to:
  /// **'Location'**
  String get locationLabel;

  /// No description provided for @ellipsisBusy.
  ///
  /// In en, this message translates to:
  /// **'…'**
  String get ellipsisBusy;

  /// No description provided for @couldNotOpenChatWithDetail.
  ///
  /// In en, this message translates to:
  /// **'Could not open chat: {message}'**
  String couldNotOpenChatWithDetail(String message);

  /// No description provided for @chooseFromGallery.
  ///
  /// In en, this message translates to:
  /// **'Choose from gallery'**
  String get chooseFromGallery;

  /// No description provided for @filterClear.
  ///
  /// In en, this message translates to:
  /// **'Clear'**
  String get filterClear;

  /// No description provided for @filterApply.
  ///
  /// In en, this message translates to:
  /// **'Apply'**
  String get filterApply;

  /// No description provided for @clearFilters.
  ///
  /// In en, this message translates to:
  /// **'Clear filters'**
  String get clearFilters;

  /// No description provided for @deliverOrderTitle.
  ///
  /// In en, this message translates to:
  /// **'Deliver Order'**
  String get deliverOrderTitle;

  /// No description provided for @pleaseDescribeDelivery.
  ///
  /// In en, this message translates to:
  /// **'Please describe your delivery'**
  String get pleaseDescribeDelivery;

  /// No description provided for @orderDeliveredSuccess.
  ///
  /// In en, this message translates to:
  /// **'Order delivered successfully!'**
  String get orderDeliveredSuccess;

  /// No description provided for @maxSize1Gb.
  ///
  /// In en, this message translates to:
  /// **'Max size 1 GB'**
  String get maxSize1Gb;

  /// No description provided for @addCustomSkill.
  ///
  /// In en, this message translates to:
  /// **'Add custom skill'**
  String get addCustomSkill;

  /// No description provided for @skillAlreadyAdded.
  ///
  /// In en, this message translates to:
  /// **'You already added \"{skill}\"'**
  String skillAlreadyAdded(String skill);

  /// No description provided for @noWithdrawalHistory.
  ///
  /// In en, this message translates to:
  /// **'No withdrawal history'**
  String get noWithdrawalHistory;

  /// No description provided for @paymentPayPal.
  ///
  /// In en, this message translates to:
  /// **'PayPal'**
  String get paymentPayPal;

  /// No description provided for @paymentCreditCard.
  ///
  /// In en, this message translates to:
  /// **'Credit Card'**
  String get paymentCreditCard;

  /// No description provided for @paymentBkash.
  ///
  /// In en, this message translates to:
  /// **'Bkash'**
  String get paymentBkash;

  /// No description provided for @bidOfferLabel.
  ///
  /// In en, this message translates to:
  /// **'Bid Offer'**
  String get bidOfferLabel;

  /// No description provided for @counterOfferLabel.
  ///
  /// In en, this message translates to:
  /// **'Counter offer'**
  String get counterOfferLabel;

  /// No description provided for @counterOfferAction.
  ///
  /// In en, this message translates to:
  /// **'Counter offer'**
  String get counterOfferAction;

  /// No description provided for @counterOfferTitle.
  ///
  /// In en, this message translates to:
  /// **'Send counter offer'**
  String get counterOfferTitle;

  /// No description provided for @counterOfferBody.
  ///
  /// In en, this message translates to:
  /// **'Propose a different rate. This updates the application amount before you hire.'**
  String get counterOfferBody;

  /// No description provided for @counterOfferAmountHint.
  ///
  /// In en, this message translates to:
  /// **'Proposed amount'**
  String get counterOfferAmountHint;

  /// No description provided for @counterOfferNoteHint.
  ///
  /// In en, this message translates to:
  /// **'Optional note for the freelancer'**
  String get counterOfferNoteHint;

  /// No description provided for @counterOfferSent.
  ///
  /// In en, this message translates to:
  /// **'Counter offer sent'**
  String get counterOfferSent;

  /// No description provided for @threadContextTitle.
  ///
  /// In en, this message translates to:
  /// **'Related work'**
  String get threadContextTitle;

  /// No description provided for @threadContextSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Active jobs and contracts with this person'**
  String get threadContextSubtitle;

  /// No description provided for @threadContextRelatedCount.
  ///
  /// In en, this message translates to:
  /// **'{count} related items'**
  String threadContextRelatedCount(int count);

  /// No description provided for @threadContextLoading.
  ///
  /// In en, this message translates to:
  /// **'Loading related work…'**
  String get threadContextLoading;

  /// No description provided for @chatFilterApplications.
  ///
  /// In en, this message translates to:
  /// **'Applications'**
  String get chatFilterApplications;

  /// No description provided for @chatFilterActive.
  ///
  /// In en, this message translates to:
  /// **'Active'**
  String get chatFilterActive;

  /// No description provided for @chatFilterPast.
  ///
  /// In en, this message translates to:
  /// **'Past'**
  String get chatFilterPast;

  /// No description provided for @chatTagApplication.
  ///
  /// In en, this message translates to:
  /// **'Application'**
  String get chatTagApplication;

  /// No description provided for @chatTagActive.
  ///
  /// In en, this message translates to:
  /// **'Active'**
  String get chatTagActive;

  /// No description provided for @chatTagPast.
  ///
  /// In en, this message translates to:
  /// **'Past'**
  String get chatTagPast;

  /// No description provided for @noChatsInFilter.
  ///
  /// In en, this message translates to:
  /// **'No chats in this filter'**
  String get noChatsInFilter;

  /// No description provided for @noChatsInFilterHint.
  ///
  /// In en, this message translates to:
  /// **'Try another filter or start a conversation from a profile'**
  String get noChatsInFilterHint;

  /// No description provided for @proposalCaps.
  ///
  /// In en, this message translates to:
  /// **'PROPOSAL'**
  String get proposalCaps;

  /// No description provided for @labelColon.
  ///
  /// In en, this message translates to:
  /// **':'**
  String get labelColon;

  /// No description provided for @requiredFieldMark.
  ///
  /// In en, this message translates to:
  /// **'*'**
  String get requiredFieldMark;

  /// No description provided for @writeReviewAction.
  ///
  /// In en, this message translates to:
  /// **'Write review'**
  String get writeReviewAction;

  /// No description provided for @deliveryDaysCount.
  ///
  /// In en, this message translates to:
  /// **'{count} Days'**
  String deliveryDaysCount(int count);

  /// No description provided for @delete.
  ///
  /// In en, this message translates to:
  /// **'Delete'**
  String get delete;

  /// No description provided for @jobAlertsTitle.
  ///
  /// In en, this message translates to:
  /// **'Job alerts'**
  String get jobAlertsTitle;

  /// No description provided for @jobAlertNew.
  ///
  /// In en, this message translates to:
  /// **'New alert'**
  String get jobAlertNew;

  /// No description provided for @jobAlertEdit.
  ///
  /// In en, this message translates to:
  /// **'Edit alert'**
  String get jobAlertEdit;

  /// No description provided for @jobAlertsEmpty.
  ///
  /// In en, this message translates to:
  /// **'Save rules for skills and distance. We will notify you when matching jobs are posted.'**
  String get jobAlertsEmpty;

  /// No description provided for @jobAlertUntitled.
  ///
  /// In en, this message translates to:
  /// **'Job alert'**
  String get jobAlertUntitled;

  /// No description provided for @jobAlertDeleteTitle.
  ///
  /// In en, this message translates to:
  /// **'Delete alert?'**
  String get jobAlertDeleteTitle;

  /// No description provided for @jobAlertDeleteMessage.
  ///
  /// In en, this message translates to:
  /// **'You will no longer get notifications for this rule.'**
  String get jobAlertDeleteMessage;

  /// No description provided for @jobAlertMatchesAllJobs.
  ///
  /// In en, this message translates to:
  /// **'All open jobs'**
  String get jobAlertMatchesAllJobs;

  /// No description provided for @jobAlertAnyDistance.
  ///
  /// In en, this message translates to:
  /// **'Any distance'**
  String get jobAlertAnyDistance;

  /// No description provided for @jobAlertIncludesRemote.
  ///
  /// In en, this message translates to:
  /// **'Includes remote'**
  String get jobAlertIncludesRemote;

  /// No description provided for @jobAlertWithinKm.
  ///
  /// In en, this message translates to:
  /// **'Within {km} km'**
  String jobAlertWithinKm(int km);

  /// No description provided for @jobAlertCategoriesCount.
  ///
  /// In en, this message translates to:
  /// **'{count} categories'**
  String jobAlertCategoriesCount(int count);

  /// No description provided for @jobAlertNameLabel.
  ///
  /// In en, this message translates to:
  /// **'Alert name (optional)'**
  String get jobAlertNameLabel;

  /// No description provided for @jobAlertNameHint.
  ///
  /// In en, this message translates to:
  /// **'e.g. Plumber near me'**
  String get jobAlertNameHint;

  /// No description provided for @jobAlertEnabled.
  ///
  /// In en, this message translates to:
  /// **'Notifications on'**
  String get jobAlertEnabled;

  /// No description provided for @jobAlertSkillsSection.
  ///
  /// In en, this message translates to:
  /// **'Skills'**
  String get jobAlertSkillsSection;

  /// No description provided for @jobAlertAddSkill.
  ///
  /// In en, this message translates to:
  /// **'Add skill'**
  String get jobAlertAddSkill;

  /// No description provided for @jobAlertCategoriesSection.
  ///
  /// In en, this message translates to:
  /// **'Categories'**
  String get jobAlertCategoriesSection;

  /// No description provided for @jobAlertAnyCategory.
  ///
  /// In en, this message translates to:
  /// **'Any category'**
  String get jobAlertAnyCategory;

  /// No description provided for @jobAlertPickCategories.
  ///
  /// In en, this message translates to:
  /// **'Choose categories'**
  String get jobAlertPickCategories;

  /// No description provided for @jobAlertJobTypeSection.
  ///
  /// In en, this message translates to:
  /// **'Job type'**
  String get jobAlertJobTypeSection;

  /// No description provided for @jobAlertLocationSection.
  ///
  /// In en, this message translates to:
  /// **'Your location'**
  String get jobAlertLocationSection;

  /// No description provided for @jobAlertLocationSet.
  ///
  /// In en, this message translates to:
  /// **'Location saved for distance'**
  String get jobAlertLocationSet;

  /// No description provided for @jobAlertLocationMissing.
  ///
  /// In en, this message translates to:
  /// **'Pick your location on the map to use distance alerts.'**
  String get jobAlertLocationMissing;

  /// No description provided for @jobAlertLimitDistance.
  ///
  /// In en, this message translates to:
  /// **'Limit to nearby jobs'**
  String get jobAlertLimitDistance;

  /// No description provided for @jobAlertIncludeRemote.
  ///
  /// In en, this message translates to:
  /// **'Include remote jobs'**
  String get jobAlertIncludeRemote;

  /// No description provided for @jobAlertNeedProfileLocation.
  ///
  /// In en, this message translates to:
  /// **'Pick your location on the map before using a distance limit.'**
  String get jobAlertNeedProfileLocation;

  /// No description provided for @jobAlertSaveFromFilter.
  ///
  /// In en, this message translates to:
  /// **'Save as job alert'**
  String get jobAlertSaveFromFilter;

  /// No description provided for @jobAlertsAppBarTooltip.
  ///
  /// In en, this message translates to:
  /// **'Job alerts'**
  String get jobAlertsAppBarTooltip;

  /// No description provided for @workTrustSectionTitle.
  ///
  /// In en, this message translates to:
  /// **'Verified work'**
  String get workTrustSectionTitle;

  /// No description provided for @workTrustSectionSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Counts come from completed on-site contracts and attendance check-ins on HupWorks—not paid badges.'**
  String get workTrustSectionSubtitle;

  /// No description provided for @workTrustStatCompletedOnsite.
  ///
  /// In en, this message translates to:
  /// **'Completed on-site'**
  String get workTrustStatCompletedOnsite;

  /// No description provided for @workTrustStatVerifiedCheckins.
  ///
  /// In en, this message translates to:
  /// **'Verified check-ins'**
  String get workTrustStatVerifiedCheckins;

  /// No description provided for @workTrustStatVerifiedDays.
  ///
  /// In en, this message translates to:
  /// **'Verified days'**
  String get workTrustStatVerifiedDays;

  /// No description provided for @workTrustHighlightsTitle.
  ///
  /// In en, this message translates to:
  /// **'Recent on-site work'**
  String get workTrustHighlightsTitle;

  /// No description provided for @workTrustAttendanceVerifiedTooltip.
  ///
  /// In en, this message translates to:
  /// **'Attendance recorded for this job'**
  String get workTrustAttendanceVerifiedTooltip;

  /// No description provided for @workTrustCompletedMonthLabel.
  ///
  /// In en, this message translates to:
  /// **'{month} {year}'**
  String workTrustCompletedMonthLabel(String month, int year);

  /// No description provided for @tapSetBirthDateRequired.
  ///
  /// In en, this message translates to:
  /// **'Tap to set your birth date (required)'**
  String get tapSetBirthDateRequired;

  /// No description provided for @ageBirthDateStaysPrivate.
  ///
  /// In en, this message translates to:
  /// **'Age {age} (birth date stays private)'**
  String ageBirthDateStaysPrivate(int age);

  /// No description provided for @pleaseSetDateOfBirth.
  ///
  /// In en, this message translates to:
  /// **'Please set your date of birth'**
  String get pleaseSetDateOfBirth;

  /// No description provided for @mustBeAtLeast18.
  ///
  /// In en, this message translates to:
  /// **'You must be at least 18 years old'**
  String get mustBeAtLeast18;

  /// No description provided for @pleaseUploadClearProfilePhoto.
  ///
  /// In en, this message translates to:
  /// **'Please upload a clear profile photo'**
  String get pleaseUploadClearProfilePhoto;

  /// No description provided for @pleaseUploadIdSelfie.
  ///
  /// In en, this message translates to:
  /// **'Please upload a selfie holding your ID'**
  String get pleaseUploadIdSelfie;

  /// No description provided for @leaveSetupTitle.
  ///
  /// In en, this message translates to:
  /// **'Leave setup?'**
  String get leaveSetupTitle;

  /// No description provided for @leaveSetupMessage.
  ///
  /// In en, this message translates to:
  /// **'Log in again anytime to continue.'**
  String get leaveSetupMessage;

  /// No description provided for @requiredDetails.
  ///
  /// In en, this message translates to:
  /// **'Required details'**
  String get requiredDetails;

  /// No description provided for @requiredDetailsHint.
  ///
  /// In en, this message translates to:
  /// **'Job title and age help clients trust your profile. Your name comes from signup.'**
  String get requiredDetailsHint;

  /// No description provided for @ageDateOfBirth.
  ///
  /// In en, this message translates to:
  /// **'Age / date of birth'**
  String get ageDateOfBirth;

  /// No description provided for @ageShownBirthPrivate.
  ///
  /// In en, this message translates to:
  /// **'Your age is shown on your profile. Birth date stays private.'**
  String get ageShownBirthPrivate;

  /// No description provided for @optionalDetails.
  ///
  /// In en, this message translates to:
  /// **'Optional details'**
  String get optionalDetails;

  /// No description provided for @optionalDetailsHint.
  ///
  /// In en, this message translates to:
  /// **'You can skip these and fill them later in Edit Profile.'**
  String get optionalDetailsHint;

  /// No description provided for @profilePhotoGuidelineHint.
  ///
  /// In en, this message translates to:
  /// **'A clear front-facing photo helps verification. Prefer a plain white background.'**
  String get profilePhotoGuidelineHint;

  /// No description provided for @photoDoLabel.
  ///
  /// In en, this message translates to:
  /// **'Do: front face, clear bg'**
  String get photoDoLabel;

  /// No description provided for @photoDontLabel.
  ///
  /// In en, this message translates to:
  /// **'Don\'t: side view / shades'**
  String get photoDontLabel;

  /// No description provided for @photoTipFaceCamera.
  ///
  /// In en, this message translates to:
  /// **'Face the camera directly (not a side view)'**
  String get photoTipFaceCamera;

  /// No description provided for @photoTipBackground.
  ///
  /// In en, this message translates to:
  /// **'Plain / white background, even lighting'**
  String get photoTipBackground;

  /// No description provided for @photoTipNoAccessories.
  ///
  /// In en, this message translates to:
  /// **'No sunglasses, hat, or heavy filters'**
  String get photoTipNoAccessories;

  /// No description provided for @photoTipShoulders.
  ///
  /// In en, this message translates to:
  /// **'Shoulders visible; one person only'**
  String get photoTipShoulders;

  /// No description provided for @identityVerification.
  ///
  /// In en, this message translates to:
  /// **'Identity verification'**
  String get identityVerification;

  /// No description provided for @identityVerificationSetupHint.
  ///
  /// In en, this message translates to:
  /// **'Upload a selfie holding your government ID next to your face. An admin will review face+ID separately from your profile photo — you will see “pending” until each is accepted.'**
  String get identityVerificationSetupHint;

  /// No description provided for @idDoLabel.
  ///
  /// In en, this message translates to:
  /// **'Do: face + ID clear'**
  String get idDoLabel;

  /// No description provided for @idDontLabel.
  ///
  /// In en, this message translates to:
  /// **'Don\'t: cover ID / glare'**
  String get idDontLabel;

  /// No description provided for @idTipHoldNextToFace.
  ///
  /// In en, this message translates to:
  /// **'Hold ID next to your face — both fully visible'**
  String get idTipHoldNextToFace;

  /// No description provided for @idTipGoodLighting.
  ///
  /// In en, this message translates to:
  /// **'Good lighting; avoid glare on the ID'**
  String get idTipGoodLighting;

  /// No description provided for @idTipFourCorners.
  ///
  /// In en, this message translates to:
  /// **'All four corners of the ID visible; fingers on edges only'**
  String get idTipFourCorners;

  /// No description provided for @idTipNoAccessories.
  ///
  /// In en, this message translates to:
  /// **'No hat, sunglasses, or filters'**
  String get idTipNoAccessories;

  /// No description provided for @uploadIdFaceSelfie.
  ///
  /// In en, this message translates to:
  /// **'Upload ID + face selfie'**
  String get uploadIdFaceSelfie;

  /// No description provided for @submittedPendingAdminReview.
  ///
  /// In en, this message translates to:
  /// **'Submitted — pending admin review'**
  String get submittedPendingAdminReview;

  /// No description provided for @updateAndSubmitForReview.
  ///
  /// In en, this message translates to:
  /// **'Update & submit for review'**
  String get updateAndSubmitForReview;

  /// No description provided for @submitForReview.
  ///
  /// In en, this message translates to:
  /// **'Submit for review'**
  String get submitForReview;

  /// No description provided for @faceIdPendingHint.
  ///
  /// In en, this message translates to:
  /// **'Face+ID is submitted but not accepted yet (+50 pts after accept). Profile photo is reviewed separately.'**
  String get faceIdPendingHint;

  /// No description provided for @faceIdVerifiedHint.
  ///
  /// In en, this message translates to:
  /// **'Face+ID accepted. Replacing this selfie resets only the face+ID review.'**
  String get faceIdVerifiedHint;

  /// No description provided for @selfieWithId.
  ///
  /// In en, this message translates to:
  /// **'Selfie with ID'**
  String get selfieWithId;

  /// No description provided for @selfieWithIdHint.
  ///
  /// In en, this message translates to:
  /// **'Hold your government ID next to your face. An admin will review this later.'**
  String get selfieWithIdHint;

  /// No description provided for @yourSubmittedPhoto.
  ///
  /// In en, this message translates to:
  /// **'Your submitted photo'**
  String get yourSubmittedPhoto;

  /// No description provided for @newPhotoSelectedTapToChange.
  ///
  /// In en, this message translates to:
  /// **'New photo selected — tap to change'**
  String get newPhotoSelectedTapToChange;

  /// No description provided for @tapToChangePhoto.
  ///
  /// In en, this message translates to:
  /// **'Tap to change photo'**
  String get tapToChangePhoto;

  /// No description provided for @trustScoreSubtitle.
  ///
  /// In en, this message translates to:
  /// **'{score}/100 trust score'**
  String trustScoreSubtitle(int score);

  /// No description provided for @fullyVerified.
  ///
  /// In en, this message translates to:
  /// **'Fully verified'**
  String get fullyVerified;

  /// No description provided for @awaitingAdminReview.
  ///
  /// In en, this message translates to:
  /// **'Awaiting admin review'**
  String get awaitingAdminReview;

  /// No description provided for @completeVerification.
  ///
  /// In en, this message translates to:
  /// **'Complete verification'**
  String get completeVerification;

  /// No description provided for @verificationScoreHint.
  ///
  /// In en, this message translates to:
  /// **'Profile photo and face+ID are reviewed separately (50 pts each).'**
  String get verificationScoreHint;

  /// No description provided for @profilePhotoLabel.
  ///
  /// In en, this message translates to:
  /// **'Profile photo'**
  String get profilePhotoLabel;

  /// No description provided for @faceIdSelfieLabel.
  ///
  /// In en, this message translates to:
  /// **'Face + ID selfie'**
  String get faceIdSelfieLabel;

  /// No description provided for @acceptedByAdmin.
  ///
  /// In en, this message translates to:
  /// **'Accepted by admin'**
  String get acceptedByAdmin;

  /// No description provided for @rejectedPleaseUpdatePhoto.
  ///
  /// In en, this message translates to:
  /// **'Rejected — please update photo'**
  String get rejectedPleaseUpdatePhoto;

  /// No description provided for @rejectedPleaseUpdateSelfie.
  ///
  /// In en, this message translates to:
  /// **'Rejected — please update selfie'**
  String get rejectedPleaseUpdateSelfie;

  /// No description provided for @submittedAwaitingAdmin.
  ///
  /// In en, this message translates to:
  /// **'Submitted — awaiting admin'**
  String get submittedAwaitingAdmin;

  /// No description provided for @notUploadedYet.
  ///
  /// In en, this message translates to:
  /// **'Not uploaded yet'**
  String get notUploadedYet;

  /// No description provided for @statusVerified.
  ///
  /// In en, this message translates to:
  /// **'Verified'**
  String get statusVerified;

  /// No description provided for @notVerified.
  ///
  /// In en, this message translates to:
  /// **'Not verified'**
  String get notVerified;

  /// No description provided for @uploadFileOrImage.
  ///
  /// In en, this message translates to:
  /// **'Upload File or Image'**
  String get uploadFileOrImage;

  /// No description provided for @tapToAttachFile.
  ///
  /// In en, this message translates to:
  /// **'Tap to attach a file'**
  String get tapToAttachFile;

  /// No description provided for @describeDeliveryDetails.
  ///
  /// In en, this message translates to:
  /// **'Describe your delivery in details'**
  String get describeDeliveryDetails;

  /// No description provided for @enterDeliveryDetailsHint.
  ///
  /// In en, this message translates to:
  /// **'Enter your delivery details...'**
  String get enterDeliveryDetailsHint;

  /// No description provided for @filterJobs.
  ///
  /// In en, this message translates to:
  /// **'Filter jobs'**
  String get filterJobs;

  /// No description provided for @matchJobsWithSkills.
  ///
  /// In en, this message translates to:
  /// **'Match jobs tagged with these skills.'**
  String get matchJobsWithSkills;

  /// No description provided for @searchJobTitleHint.
  ///
  /// In en, this message translates to:
  /// **'Search job title...'**
  String get searchJobTitleHint;

  /// No description provided for @onSiteOnly.
  ///
  /// In en, this message translates to:
  /// **'On-site only'**
  String get onSiteOnly;

  /// No description provided for @clearAll.
  ///
  /// In en, this message translates to:
  /// **'Clear all'**
  String get clearAll;

  /// No description provided for @jobsCount.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =1{1 job} other{{count} jobs}}'**
  String jobsCount(int count);

  /// No description provided for @noOpenJobsRightNow.
  ///
  /// In en, this message translates to:
  /// **'No open jobs right now'**
  String get noOpenJobsRightNow;

  /// No description provided for @noOpenJobsRightNowHint.
  ///
  /// In en, this message translates to:
  /// **'Check back soon, or set a job alert to get notified when matching work is posted.'**
  String get noOpenJobsRightNowHint;

  /// No description provided for @noJobsMatchFilters.
  ///
  /// In en, this message translates to:
  /// **'No jobs match your filters'**
  String get noJobsMatchFilters;

  /// No description provided for @tryAdjustingFilters.
  ///
  /// In en, this message translates to:
  /// **'Try adjusting category, job type, distance, or remote.'**
  String get tryAdjustingFilters;

  /// No description provided for @leaveDeliveryDraftTitle.
  ///
  /// In en, this message translates to:
  /// **'Leave with draft?'**
  String get leaveDeliveryDraftTitle;

  /// No description provided for @leaveDeliveryDraftMessage.
  ///
  /// In en, this message translates to:
  /// **'Your delivery message and attachment won’t be saved if you leave.'**
  String get leaveDeliveryDraftMessage;

  /// No description provided for @leaveAnyway.
  ///
  /// In en, this message translates to:
  /// **'Leave'**
  String get leaveAnyway;

  /// No description provided for @keepEditing.
  ///
  /// In en, this message translates to:
  /// **'Keep editing'**
  String get keepEditing;

  /// No description provided for @chooseFile.
  ///
  /// In en, this message translates to:
  /// **'Choose file'**
  String get chooseFile;

  /// No description provided for @attachmentTooLarge.
  ///
  /// In en, this message translates to:
  /// **'File exceeds the 1 GB limit'**
  String get attachmentTooLarge;

  /// No description provided for @searchApplicationsHint.
  ///
  /// In en, this message translates to:
  /// **'Search by job title...'**
  String get searchApplicationsHint;

  /// No description provided for @statusWithdrawn.
  ///
  /// In en, this message translates to:
  /// **'Withdrawn'**
  String get statusWithdrawn;

  /// No description provided for @withdrawApplication.
  ///
  /// In en, this message translates to:
  /// **'Withdraw'**
  String get withdrawApplication;

  /// No description provided for @withdrawApplicationTitle.
  ///
  /// In en, this message translates to:
  /// **'Withdraw application?'**
  String get withdrawApplicationTitle;

  /// No description provided for @withdrawApplicationConfirmBody.
  ///
  /// In en, this message translates to:
  /// **'The employer will no longer see this as a pending offer. You can apply again later.'**
  String get withdrawApplicationConfirmBody;

  /// No description provided for @applicationWithdrawn.
  ///
  /// In en, this message translates to:
  /// **'Application withdrawn'**
  String get applicationWithdrawn;

  /// No description provided for @noFilteredApplications.
  ///
  /// In en, this message translates to:
  /// **'No applications match'**
  String get noFilteredApplications;

  /// No description provided for @noFilteredApplicationsHint.
  ///
  /// In en, this message translates to:
  /// **'Try another status or clear your search.'**
  String get noFilteredApplicationsHint;

  /// No description provided for @trustScoreLabel.
  ///
  /// In en, this message translates to:
  /// **'Trust'**
  String get trustScoreLabel;

  /// No description provided for @genderLabel.
  ///
  /// In en, this message translates to:
  /// **'Gender'**
  String get genderLabel;

  /// No description provided for @notificationMissingLink.
  ///
  /// In en, this message translates to:
  /// **'This notification has no linked item.'**
  String get notificationMissingLink;

  /// No description provided for @notificationUnableToOpen.
  ///
  /// In en, this message translates to:
  /// **'Unable to open this notification.'**
  String get notificationUnableToOpen;

  /// No description provided for @notificationOpenFailed.
  ///
  /// In en, this message translates to:
  /// **'Could not open: {detail}'**
  String notificationOpenFailed(String detail);

  /// No description provided for @notificationContractUnavailable.
  ///
  /// In en, this message translates to:
  /// **'Contract no longer available.'**
  String get notificationContractUnavailable;

  /// No description provided for @notificationApplicationUnavailable.
  ///
  /// In en, this message translates to:
  /// **'Application no longer available.'**
  String get notificationApplicationUnavailable;

  /// No description provided for @notificationJobNotFound.
  ///
  /// In en, this message translates to:
  /// **'Job post not found.'**
  String get notificationJobNotFound;

  /// No description provided for @noFavouritesYetHint.
  ///
  /// In en, this message translates to:
  /// **'Browse open jobs and tap the bookmark to save them here.'**
  String get noFavouritesYetHint;

  /// No description provided for @noNotificationsHint.
  ///
  /// In en, this message translates to:
  /// **'Updates about jobs, contracts, and messages will show up here.'**
  String get noNotificationsHint;

  /// No description provided for @noJobAlertsYet.
  ///
  /// In en, this message translates to:
  /// **'No job alerts yet'**
  String get noJobAlertsYet;

  /// No description provided for @totalOrders.
  ///
  /// In en, this message translates to:
  /// **'Total orders'**
  String get totalOrders;

  /// No description provided for @employerVerification.
  ///
  /// In en, this message translates to:
  /// **'Employer verification'**
  String get employerVerification;

  /// No description provided for @employerVerifyUpgradeHint.
  ///
  /// In en, this message translates to:
  /// **'Complete your profile to post jobs. Optionally verify with a personal ID or company documents for a Verified employer badge.'**
  String get employerVerifyUpgradeHint;

  /// No description provided for @chooseVerificationPath.
  ///
  /// In en, this message translates to:
  /// **'Choose how to verify'**
  String get chooseVerificationPath;

  /// No description provided for @personalIdPath.
  ///
  /// In en, this message translates to:
  /// **'Personal ID'**
  String get personalIdPath;

  /// No description provided for @companyDocPath.
  ///
  /// In en, this message translates to:
  /// **'Company'**
  String get companyDocPath;

  /// No description provided for @companyDetails.
  ///
  /// In en, this message translates to:
  /// **'Company details'**
  String get companyDetails;

  /// No description provided for @companyName.
  ///
  /// In en, this message translates to:
  /// **'Company name'**
  String get companyName;

  /// No description provided for @companyNameHint.
  ///
  /// In en, this message translates to:
  /// **'Legal or trading name'**
  String get companyNameHint;

  /// No description provided for @companyRegistrationOptional.
  ///
  /// In en, this message translates to:
  /// **'Registration number (optional)'**
  String get companyRegistrationOptional;

  /// No description provided for @companyRegistrationHint.
  ///
  /// In en, this message translates to:
  /// **'KvK / CR / tax ID'**
  String get companyRegistrationHint;

  /// No description provided for @companyWebsiteOptional.
  ///
  /// In en, this message translates to:
  /// **'Website (optional)'**
  String get companyWebsiteOptional;

  /// No description provided for @companyDocUploadTitle.
  ///
  /// In en, this message translates to:
  /// **'Company registration document'**
  String get companyDocUploadTitle;

  /// No description provided for @companyDocUploadHint.
  ///
  /// In en, this message translates to:
  /// **'Upload a clear photo of your business registration certificate.'**
  String get companyDocUploadHint;

  /// No description provided for @uploadCompanyDoc.
  ///
  /// In en, this message translates to:
  /// **'Upload company document'**
  String get uploadCompanyDoc;

  /// No description provided for @pleaseUploadCompanyDoc.
  ///
  /// In en, this message translates to:
  /// **'Please upload a company registration document'**
  String get pleaseUploadCompanyDoc;

  /// No description provided for @pleaseEnterCompanyName.
  ///
  /// In en, this message translates to:
  /// **'Please enter your company name'**
  String get pleaseEnterCompanyName;

  /// No description provided for @completeProfileToPostJob.
  ///
  /// In en, this message translates to:
  /// **'Complete your profile to post a job'**
  String get completeProfileToPostJob;

  /// No description provided for @completeProfileToPostJobHint.
  ///
  /// In en, this message translates to:
  /// **'Add these details so freelancers can trust your listing.'**
  String get completeProfileToPostJobHint;

  /// No description provided for @employerStandingNew.
  ///
  /// In en, this message translates to:
  /// **'New employer'**
  String get employerStandingNew;

  /// No description provided for @employerStandingActive.
  ///
  /// In en, this message translates to:
  /// **'Active hirer'**
  String get employerStandingActive;

  /// No description provided for @employerStandingTrusted.
  ///
  /// In en, this message translates to:
  /// **'Trusted hirer'**
  String get employerStandingTrusted;

  /// No description provided for @employerStandingEstablished.
  ///
  /// In en, this message translates to:
  /// **'Established hirer'**
  String get employerStandingEstablished;

  /// No description provided for @employerStandingHint.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =0{No completed paid hires yet} =1{1 completed paid hire} other{{count} completed paid hires}}'**
  String employerStandingHint(int count);

  /// No description provided for @verifiedEmployer.
  ///
  /// In en, this message translates to:
  /// **'Verified employer'**
  String get verifiedEmployer;
}

class _AppLocalizationsDelegate
    extends LocalizationsDelegate<AppLocalizations> {
  const _AppLocalizationsDelegate();

  @override
  Future<AppLocalizations> load(Locale locale) {
    return SynchronousFuture<AppLocalizations>(lookupAppLocalizations(locale));
  }

  @override
  bool isSupported(Locale locale) =>
      <String>['bn', 'en', 'nl'].contains(locale.languageCode);

  @override
  bool shouldReload(_AppLocalizationsDelegate old) => false;
}

AppLocalizations lookupAppLocalizations(Locale locale) {
  // Lookup logic when only language code is specified.
  switch (locale.languageCode) {
    case 'bn':
      return AppLocalizationsBn();
    case 'en':
      return AppLocalizationsEn();
    case 'nl':
      return AppLocalizationsNl();
  }

  throw FlutterError(
      'AppLocalizations.delegate failed to load unsupported locale "$locale". This is likely '
      'an issue with the localizations generation tool. Please file an issue '
      'on GitHub with a reproducible sample app and the gen-l10n configuration '
      'that was used.');
}
