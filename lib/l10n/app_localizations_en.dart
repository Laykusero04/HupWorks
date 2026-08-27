// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for English (`en`).
class AppLocalizationsEn extends AppLocalizations {
  AppLocalizationsEn([String locale = 'en']) : super(locale);

  @override
  String get appTitle => 'HupWorks';

  @override
  String get language => 'Language';

  @override
  String get languageEnglish => 'English';

  @override
  String get languageBengali => 'Bengali';

  @override
  String get languageDutch => 'Dutch';

  @override
  String get languageChanged => 'Language updated';

  @override
  String get cancel => 'Cancel';

  @override
  String get save => 'Save';

  @override
  String get send => 'Send';

  @override
  String get share => 'Share';

  @override
  String get retry => 'Retry';

  @override
  String get done => 'Done';

  @override
  String get back => 'Back';

  @override
  String get add => 'Add';

  @override
  String get seeAll => 'See all';

  @override
  String get viewAll => 'View all';

  @override
  String get explore => 'Explore';

  @override
  String get other => 'Other';

  @override
  String get unknown => 'Unknown';

  @override
  String get notSpecified => 'Not specified';

  @override
  String get aboutUs => 'About Us';

  @override
  String get privacyPolicy => 'Privacy Policy';

  @override
  String get invite => 'Invite';

  @override
  String get inviteFriends => 'Invite friends';

  @override
  String get inviteBody =>
      'Share your personal invite code so friends can join HupWorks. Referral rewards are not available yet.';

  @override
  String get inviteCodeCopied => 'Invite code copied';

  @override
  String get inviteSignInRequired => 'Sign in to get your invite code.';

  @override
  String get shareInvite => 'Share invite';

  @override
  String get report => 'Report';

  @override
  String get reportSubmitted => 'Report submitted. Thank you.';

  @override
  String get searchHint => 'Search services or freelancers';

  @override
  String get popularServices => 'Popular services';

  @override
  String get topFreelancers => 'Top freelancers';

  @override
  String get services => 'Services';

  @override
  String get freelancers => 'Freelancers';

  @override
  String noSearchResults(String query) {
    return 'No services or freelancers match \"$query\"';
  }

  @override
  String get noPopularResults => 'No popular results yet';

  @override
  String get couldNotLoadResults => 'Could not load results';

  @override
  String get home => 'Home';

  @override
  String get settings => 'Setting';

  @override
  String get helpSupport => 'Help & Support';

  @override
  String get logOut => 'Log Out';

  @override
  String get sellerReport => 'Seller Report';

  @override
  String get favorite => 'Save';

  @override
  String get transaction => 'Transaction';

  @override
  String get saving => 'Saving...';

  @override
  String get sending => 'Sending...';

  @override
  String get profileUpdated => 'Profile updated successfully!';

  @override
  String get pleaseEnterName => 'Please enter your name';

  @override
  String get createProfile => 'Create Profile';

  @override
  String get setupProfile => 'Setup Profile';

  @override
  String get saveProfile => 'Save Profile';

  @override
  String get continueLabel => 'Continue';

  @override
  String get errorGeneric => 'Something went wrong. Please try again.';

  @override
  String errorWithDetail(String message) {
    return 'Error: $message';
  }

  @override
  String get errorLoading => 'Could not load data';

  @override
  String get couldNotOpenChat => 'Could not open chat';

  @override
  String get pleaseFillAllFields => 'Please fill in all fields';

  @override
  String get pushNotifications => 'Push Notifications';

  @override
  String get notifications => 'Notifications';

  @override
  String get message => 'Message';

  @override
  String get contracts => 'Contracts';

  @override
  String get findJobs => 'Find Jobs';

  @override
  String get myJobs => 'My Jobs';

  @override
  String get talent => 'Talent';

  @override
  String get justNow => 'Just now';

  @override
  String get readAll => 'Read All';

  @override
  String get noNotifications => 'No notifications';

  @override
  String minutesAgo(int count) {
    return '${count}m ago';
  }

  @override
  String hoursAgo(int count) {
    return '${count}h ago';
  }

  @override
  String daysAgo(int count) {
    return '${count}d ago';
  }

  @override
  String get orderStatusActive => 'Active';

  @override
  String get orderStatusPending => 'Pending';

  @override
  String get orderStatusCompleted => 'Completed';

  @override
  String get orderStatusCancelled => 'Cancelled';

  @override
  String get orderStatusDelivered => 'Delivered';

  @override
  String get orderStatusCancellationPending => 'Cancellation pending';

  @override
  String get reportReasonNonOriginal => 'Non original content';

  @override
  String get reportReasonTrademark => 'Trademark Violations';

  @override
  String get reportReasonCopyright => 'Copyright Violations';

  @override
  String get reportReasonOther => 'Other reasons';

  @override
  String get reportReasonHarassment => 'Harassment or inappropriate behavior';

  @override
  String get reportReasonFakeJob => 'Fake or misleading job';

  @override
  String get reportReasonNoShow => 'No-show or incomplete work';

  @override
  String get reportReasonPaymentDispute => 'Payment or contract dispute';

  @override
  String get reportReasonSpam => 'Spam or scam';

  @override
  String get reportDetailsTooShort =>
      'Please describe the issue (at least 10 characters).';

  @override
  String get reportDetailsHelp =>
      'Include what happened, when, and any messages or job details that help us review.';

  @override
  String get reportOpenFromContextHint =>
      'Tip: open Report from a chat, job, or contract to link the other person automatically.';

  @override
  String reportReportingUser(String name) {
    return 'Reporting: $name';
  }

  @override
  String reportReportingJob(String title) {
    return 'Job: $title';
  }

  @override
  String get reportReportingContract => 'Linked to this contract';

  @override
  String get cancelReasonScheduleConflict => 'Schedule conflict';

  @override
  String get cancelReasonScopeMismatch => 'Scope does not match agreement';

  @override
  String get cancelReasonSiteOrSafety => 'Site or safety concern';

  @override
  String get cancelReasonPersonalEmergency => 'Personal emergency';

  @override
  String get cancelReasonClientIssue => 'Issue with client / communication';

  @override
  String get cancelReasonOther => 'Other';

  @override
  String get attendanceModeQrInOut => 'QR clock in & out';

  @override
  String get attendanceModeQrOnce => 'QR check-in (once per day)';

  @override
  String get attendanceModeSelfReport => 'Self-report in app';

  @override
  String get attendanceModeDisabled => 'Attendance off';

  @override
  String get attendanceClientHintQrInOut =>
      'Post a QR at the site. Workers scan to clock in and clock out.';

  @override
  String get attendanceClientHintQrOnce =>
      'Post a QR at the site. Workers scan once per day to check in.';

  @override
  String get attendanceClientHintSelfReport =>
      'Workers clock in and out in the app — no QR needed.';

  @override
  String get attendanceClientHintDisabled =>
      'Attendance tracking is turned off for this job.';

  @override
  String get attendanceFreelancerHintQrInOut =>
      'Scan the site QR to clock in and clock out.';

  @override
  String get attendanceFreelancerHintQrOnce =>
      'Scan the site QR once when you arrive.';

  @override
  String get attendanceFreelancerHintSelfReport =>
      'Tap clock in when you start and clock out when you leave.';

  @override
  String get attendanceFreelancerHintDisabled =>
      'Your client has not enabled attendance for this job.';

  @override
  String get attendanceOnboardingQrInOut =>
      'Open Attendance in HupWorks and scan the QR code at the job site to clock in when you arrive and clock out when you leave.';

  @override
  String get attendanceOnboardingQrOnce =>
      'When you arrive, open Attendance in HupWorks and scan the QR code posted on site. You only need to check in once per day.';

  @override
  String get attendanceOnboardingSelfReport =>
      'Open Attendance in HupWorks on this contract and tap Clock in when you start and Clock out when you leave. No QR scan is required.';

  @override
  String get attendanceOnboardingDisabled =>
      'Attendance is not tracked in the app for this job. Follow your supervisor\'s instructions on site.';

  @override
  String get attendanceTracking => 'Attendance tracking';

  @override
  String get attendanceTrackingHint => 'How workers record time on site.';

  @override
  String get genderMale => 'Male';

  @override
  String get genderFemale => 'Female';

  @override
  String get aboutHupWorksTitle => 'About HupWorks';

  @override
  String get aboutHupWorksBody =>
      'HupWorks is a marketplace that connects clients with freelancers and local workers for jobs and services. We help people post work, hire talent, track attendance on-site, and manage orders from start to finish.\n\nOur goal is to make hiring and getting hired simpler, clearer, and more reliable—whether you need skilled help for a project or want to grow your freelance business.';

  @override
  String get privacySectionCollectTitle => 'Information We Collect';

  @override
  String get privacySectionCollectBody =>
      'We collect account details you provide (such as name, email, phone, and profile information), content you post (jobs, messages, reviews), and technical data needed to operate the app (device and usage information). Payment-related data is processed by our payment providers when those features are enabled.';

  @override
  String get privacySectionUseTitle => 'How We Use Information';

  @override
  String get privacySectionUseBody =>
      'We use your information to create and manage your account, show relevant jobs and profiles, enable messaging and order workflows, improve safety and reliability, and communicate important service updates. We do not sell your personal information.';

  @override
  String get privacySectionShareTitle => 'Sharing of Information';

  @override
  String get privacySectionShareBody =>
      'We share information with other users only as needed for the marketplace (for example, your public profile and messages you send). We may share data with service providers who help us run HupWorks, or when required by law, to protect rights and safety, or to investigate fraud or abuse.';

  @override
  String get privacySectionChoicesTitle => 'Your Choices';

  @override
  String get privacySectionChoicesBody =>
      'You can update profile details in the app and contact support to request account changes. Depending on your location, you may have additional rights to access, correct, or delete personal data.';

  @override
  String get privacySectionContactTitle => 'Contact';

  @override
  String get privacySectionContactBody =>
      'If you have questions about this policy or your data, reach us through Help & Support in the app.';

  @override
  String get authWelcomeHowToUse => 'How will you use HupWorks?';

  @override
  String get authRoleClient => 'Client';

  @override
  String get authRoleClientSubtitle => 'Hire talent';

  @override
  String get authRoleFreelancer => 'Freelancer';

  @override
  String get authRoleFreelancerSubtitle => 'Find work';

  @override
  String get authContinueAsClient => 'Continue as Client';

  @override
  String get authContinueAsFreelancer => 'Continue as Freelancer';

  @override
  String get authAlreadyHaveAccount => 'I already have an account';

  @override
  String get authWelcomeBack => 'Welcome back';

  @override
  String get authSignInSubtitle => 'Sign in to continue to HupWorks.';

  @override
  String get authEmail => 'Email';

  @override
  String get authEmailHint => 'you@email.com';

  @override
  String get authPassword => 'Password';

  @override
  String get authPasswordHint => 'Enter your password';

  @override
  String get authForgotPassword => 'Forgot password?';

  @override
  String get authLogIn => 'Log In';

  @override
  String get authDontHaveAccount => 'Don\'t have an account?';

  @override
  String get authSignUp => 'Sign up';

  @override
  String get authOrContinueWith => 'Or continue with';

  @override
  String get authAgreeToThe => 'I agree to the ';

  @override
  String get authTermsOfService => 'Terms of Service';

  @override
  String get authFirstName => 'First name';

  @override
  String get authFirstNameHint => 'First';

  @override
  String get authLastName => 'Last name';

  @override
  String get authLastNameHint => 'Last';

  @override
  String get authCreateAccount => 'Create your account';

  @override
  String get authJoinAsClient => 'Join as a client to hire freelancers.';

  @override
  String get authJoinAsFreelancer => 'Join as a freelancer to find work.';

  @override
  String get authPhone => 'Phone';

  @override
  String get authPhoneHint => 'Phone number';

  @override
  String get authSignUpButton => 'Sign Up';

  @override
  String get authOrSignUpWith => 'Or sign up with';

  @override
  String get authAlreadyHaveAccountShort => 'Already have an account?';

  @override
  String get authPasswordMinLength => 'Password must be at least 6 characters';

  @override
  String get authMustAgreeTerms => 'Please agree to the Terms of Service';

  @override
  String get authForgotPasswordTitle => 'Forgot Password?';

  @override
  String get authForgotPasswordBody =>
      'Enter your email and we\'ll send you a link to reset your password.';

  @override
  String get authResetPassword => 'Reset Password';

  @override
  String get authEnterEmail => 'Please enter your email';

  @override
  String get authResetLinkSent => 'Password reset link sent. Check your email.';

  @override
  String get authVerification => 'Verification';

  @override
  String get authCodeSentToEmail => 'We\'ve sent the code to your email-';

  @override
  String get authDidntReceiveCode => 'Didn\'t receive code?';

  @override
  String get authResendCode => 'Resend Code';

  @override
  String get selectProfileImage => 'Select Profile Image';

  @override
  String get photoGallery => 'Photo Gallery';

  @override
  String get takePhoto => 'Take Photo';

  @override
  String get uploadYourPhoto => 'Upload Your Photo';

  @override
  String get userName => 'User Name';

  @override
  String get phone => 'Phone';

  @override
  String get country => 'Country';

  @override
  String get streetAddress => 'Street Address';

  @override
  String get city => 'City';

  @override
  String get state => 'State';

  @override
  String get zipCode => 'ZIP Code';

  @override
  String get selectLanguage => 'Select Language';

  @override
  String get selectGender => 'Select Gender';

  @override
  String get addLanguage => 'Add Language';

  @override
  String get addNew => 'Add New';

  @override
  String get noLanguagesYet => 'No languages added yet.';

  @override
  String get jobTitle => 'Job Title';

  @override
  String get skills => 'Skills';

  @override
  String get aboutYou => 'About You';

  @override
  String get aboutYouHint => 'Tell clients about yourself';

  @override
  String stepOf(int current, int total) {
    return 'Step $current of $total';
  }

  @override
  String get browseCategories => 'Browse Categories';

  @override
  String get yourRecentJobs => 'Your Recent Jobs';

  @override
  String get postJob => 'Post Job';

  @override
  String get findTalent => 'Find Talent';

  @override
  String get categories => 'Categories';

  @override
  String get hireTopRated => 'Hire top-rated freelancers';

  @override
  String get postAJobBanner => 'Post a job and get offers';

  @override
  String get postNow => 'Post Now';

  @override
  String get browse => 'Browse';

  @override
  String get noCategoriesYet => 'No categories yet';

  @override
  String get noJobsYet => 'No jobs yet';

  @override
  String get noFreelancersYet => 'No freelancers yet';

  @override
  String get open => 'Open';

  @override
  String get closed => 'Closed';

  @override
  String get fullTime => 'Full-time';

  @override
  String get partTime => 'Part-time';

  @override
  String get viewProfile => 'View Profile';

  @override
  String get verifiedFreelancer => 'Verified Freelancer';

  @override
  String get allCategories => 'All Categories';

  @override
  String get searchCategories => 'Search categories';

  @override
  String get noCategoriesMatch => 'No matching categories';

  @override
  String get searchFreelancers => 'Search freelancers...';

  @override
  String get noFreelancersMatch => 'No matching freelancers';

  @override
  String get findYourNextJob => 'Find your next job';

  @override
  String get findYourNextJobSubtitle =>
      'Browse open roles and apply in minutes.';

  @override
  String get myApplications => 'My Applications';

  @override
  String get browseJobs => 'Browse jobs';

  @override
  String get statusAccepted => 'Accepted';

  @override
  String get statusRejected => 'Rejected';

  @override
  String get statusPending => 'Pending';

  @override
  String get yourWork => 'Your work';

  @override
  String get activeContracts => 'Active contracts';

  @override
  String get wallet => 'Wallet';

  @override
  String get needsAttention => 'Needs attention';

  @override
  String attentionItems(int count) {
    return '$count items need attention';
  }

  @override
  String get messages => 'Messages';

  @override
  String get applications => 'Applications';

  @override
  String get attendance => 'Attendance';

  @override
  String get shortcutFindJobs => 'Find jobs';

  @override
  String get shortcutFindJobsSub => 'Browse open roles';

  @override
  String get shortcutMessages => 'Messages';

  @override
  String get shortcutMessagesSub => 'Chat with clients';

  @override
  String get shortcutContracts => 'Contracts';

  @override
  String get shortcutContractsSub => 'Active work';

  @override
  String get shortcutApplications => 'Applications';

  @override
  String get shortcutApplicationsSub => 'Track status';

  @override
  String get shortcutAttendance => 'Attendance';

  @override
  String get shortcutAttendanceSub => 'Clock in & out';

  @override
  String get balance => 'Balance';

  @override
  String get totalSpent => 'Total spent';

  @override
  String get earned => 'Earned';

  @override
  String sayHelloTo(String name) {
    return 'Say hello to $name';
  }

  @override
  String get block => 'Block';

  @override
  String get noMessagesYet => 'No messages yet';

  @override
  String get searchChats => 'Search chats';

  @override
  String get typeAMessage => 'Type a message';

  @override
  String get cancellationRequestTitle => 'Request to cancel';

  @override
  String get cancellationRequestBody =>
      'Your client has 48 hours to approve or keep the contract.';

  @override
  String get cancellationReason => 'Reason';

  @override
  String get cancellationExplain => 'Explain briefly';

  @override
  String get cancellationSubmit => 'Submit request';

  @override
  String cancellationMinChars(int count) {
    return 'Please write at least $count characters';
  }

  @override
  String get keepContract => 'Keep contract';

  @override
  String get approveCancellation => 'Approve cancellation';

  @override
  String get withdrawCancelRequest => 'Withdraw request';

  @override
  String get waitingForClientCancel =>
      'Waiting for client to review your cancellation request';

  @override
  String get cancellationRequested => 'Cancellation requested';

  @override
  String get awaitingYourApproval => 'Awaiting your approval';

  @override
  String get inProgress => 'In progress';

  @override
  String get markComplete => 'Mark complete';

  @override
  String get deliverWork => 'Deliver work';

  @override
  String get clockIn => 'Clock in';

  @override
  String get clockOut => 'Clock out';

  @override
  String get scanAttendanceQr => 'Scan attendance QR';

  @override
  String get editProfile => 'Edit Profile';

  @override
  String get profileDetails => 'Profile Details';

  @override
  String get favourites => 'Saved';

  @override
  String get reviews => 'Reviews';

  @override
  String get noFavouritesYet => 'No saved jobs yet';

  @override
  String get noReviewsYet => 'No reviews yet';

  @override
  String get mapPickLocation => 'Pick location';

  @override
  String get mapConfirmLocation => 'Confirm location';

  @override
  String get mapSearchPlace => 'Search place';

  @override
  String get deposit => 'Deposit';

  @override
  String get withdraw => 'Withdraw';

  @override
  String get addPaymentMethod => 'Add payment method';

  @override
  String get amount => 'Amount';

  @override
  String get history => 'History';

  @override
  String get noTransactionsYet => 'No transactions yet';

  @override
  String get supportChat => 'Support chat';

  @override
  String get typeSupportMessage => 'Type your message';

  @override
  String get clientReport => 'Client Report';

  @override
  String get selectReason => 'Select reason';

  @override
  String get describeIssue => 'Describe the issue';

  @override
  String get submitReport => 'Submit report';

  @override
  String get cancellationSheetTitle => 'Request to cancel contract';

  @override
  String get cancellationSheetBody =>
      'Your client will be notified and can approve or decline within 48 hours. The contract stays active until they respond.';

  @override
  String get cancellationExplainHint =>
      'What happened? This helps your client understand your request.';

  @override
  String cancellationCharCount(int current, int min) {
    return '$current / $min characters minimum';
  }

  @override
  String cancellationReasonLine(String reason) {
    return 'Reason: $reason';
  }

  @override
  String get reportWhyQuestion => 'Why are you reporting?';

  @override
  String get reportSellerProfileUrl => 'Seller Profile URL';

  @override
  String get reportEnterSellerProfileUrl => 'Enter seller profile url';

  @override
  String get reportOriginalContentUrl => 'URL of original content';

  @override
  String get reportEnterPostUrl => 'Enter post url';

  @override
  String get reportAdditionalInfo => 'What happened?';

  @override
  String get reportEnterInformation => 'Describe the issue…';

  @override
  String get promoVerifiedTalentSubtitle => 'Verified talent for every project';

  @override
  String get promoProposalsSubtitle => 'Get proposals within minutes';

  @override
  String get promoNicheServicesSubtitle => 'Find services across every niche';

  @override
  String get jobTypeGig => 'Gig';

  @override
  String get recentJobsEmptyHint => 'Tap \"Post Job\" to get started';

  @override
  String get postJobShort => 'Post';

  @override
  String get untitled => 'Untitled';

  @override
  String get untitledJob => 'Untitled job';

  @override
  String get categoryGeneral => 'General';

  @override
  String get proBadge => 'Pro';

  @override
  String get noApplicationsYet => 'No applications yet';

  @override
  String get noApplicationsYetHint =>
      'Browse open jobs and send a clear offer to stand out.';

  @override
  String get pendingApplications => 'Pending applications';

  @override
  String get completedThisMonth => 'Completed this month';

  @override
  String get yourRating => 'Your rating';

  @override
  String reviewCount(int count) {
    return '$count reviews';
  }

  @override
  String openJobsToBrowse(int count) {
    return '$count open jobs to browse';
  }

  @override
  String get periodLive => 'Live';

  @override
  String get periodThisMonth => 'This month';

  @override
  String get shortcuts => 'Shortcuts';

  @override
  String get attentionContractDeliveredOne =>
      '1 contract delivered — waiting for client approval';

  @override
  String attentionContractDeliveredMany(int count) {
    return '$count contracts delivered — waiting for client approval';
  }

  @override
  String get attentionOnsiteOne =>
      '1 on-site contract — clock in via Attendance';

  @override
  String attentionOnsiteMany(int count) {
    return '$count on-site contracts — use Attendance';
  }

  @override
  String get attendanceOffForJob => 'Attendance is off for this job.';

  @override
  String get checkedIn => 'Checked in';

  @override
  String get checkIn => 'Check in';

  @override
  String get noPunchesToday => 'No punches yet today.';

  @override
  String get noAttendanceRecordedToday => 'No attendance recorded today.';

  @override
  String get confirmAttendance => 'Confirm attendance';

  @override
  String get alreadyCheckedInToday => 'Already checked in today';

  @override
  String get readyForDailyCheckIn => 'Ready for daily check-in';

  @override
  String clockedInAt(String time) {
    return 'Clocked in at $time';
  }

  @override
  String get notClockedInToday => 'Not clocked in today';

  @override
  String get calendarToday => 'Today';

  @override
  String get recordLabel => 'Record';

  @override
  String get alreadyCheckedInTodayMessage =>
      'You have already checked in today for this job.';

  @override
  String get attendanceQrOnceDailyHint =>
      'This job uses one check-in scan per day (no clock-out scan).';

  @override
  String get checkInForToday => 'Check in for today';

  @override
  String attendancePunchRecorded(String punch, String minutes) {
    return '$punch recorded. Today: $minutes worked.';
  }

  @override
  String useSuggestedPunch(String punch) {
    return 'Use suggested: $punch';
  }

  @override
  String get attendanceScanCameraHint =>
      'Point your camera at the attendance QR posted at the job site.';

  @override
  String get attendanceScanLoadingDetails => 'Loading job details…';

  @override
  String attendanceScanningForJob(String title) {
    return 'Scanning for: $title';
  }

  @override
  String get viewMyOnsiteJobs => 'View my on-site jobs';

  @override
  String get attendanceQrScreenTitle => 'Attendance QR';

  @override
  String get attendancePrintQrAtSite =>
      'Print this QR and post it where workers check in.';

  @override
  String get attendanceCouldNotLoadQr => 'Could not load QR';

  @override
  String get attendanceSharePrintInstructions => 'Share / Print instructions';

  @override
  String get regenerateQr => 'Regenerate QR';

  @override
  String get regenerateQrConfirmTitle => 'Regenerate QR?';

  @override
  String get regenerateQrConfirmBody =>
      'The old printed QR will stop working. Print and post the new code at your site.';

  @override
  String get regenerate => 'Regenerate';

  @override
  String get attendanceNewQrReady => 'New attendance QR ready';

  @override
  String get attendanceHowItWorks => 'How it works';

  @override
  String get attendanceHowItWorksBody =>
      '1. Print and tape this QR at the workplace.\n2. Hired freelancers open HupWorks and scan it.\n3. They confirm clock in or clock out on their phone.\n4. You can view today\'s attendance on the job details screen.';

  @override
  String get noOnsiteJobsYet => 'No on-site jobs yet';

  @override
  String get noOnsiteJobsBody =>
      'You need an accepted on-site contract. Your client chooses how attendance works (QR scan or self-report) when they post the job.';

  @override
  String get findOnsiteJobs => 'Find on-site jobs';

  @override
  String get selectedJob => 'Selected job';

  @override
  String get openContract => 'Open contract';

  @override
  String get attendanceTimeIn => 'Time in';

  @override
  String get attendanceTimeOut => 'Time out';

  @override
  String attendanceWorkedToday(String duration) {
    return 'Worked today: $duration';
  }

  @override
  String attendancePunchTodaySummary(String punch, String duration) {
    return '$punch • $duration today';
  }

  @override
  String get attendanceLessThanOneMin => 'Less than 1 min';

  @override
  String attendanceMinutesOnly(int count) {
    return '$count min';
  }

  @override
  String attendanceHoursOnly(int count) {
    return '${count}h';
  }

  @override
  String attendanceHoursMinutes(int hours, int minutes) {
    return '${hours}h ${minutes}m';
  }

  @override
  String get firstDayInstructions => 'First-day instructions';

  @override
  String get instructionsNotAvailable => 'Instructions not available yet.';

  @override
  String get onboardingUseScanQrHint =>
      'When you arrive on site, use Scan attendance QR on the contract screen.';

  @override
  String get noSectionDetails => 'No section details were provided.';

  @override
  String get pleaseWaitEllipsis => 'Please wait…';

  @override
  String get onboardingAcknowledgedLabel =>
      'You acknowledged these instructions';

  @override
  String get onboardingReadUnderstood => 'I have read and understood';

  @override
  String get onboardingEditorLead =>
      'Share site details, access, and contacts so your hire knows what to do on day one.';

  @override
  String get onboardingResendNotice =>
      'Already sent. Saving and publishing again will notify the freelancer.';

  @override
  String get addDetailsHint => 'Add details…';

  @override
  String get draftSaved => 'Draft saved';

  @override
  String get instructionsSentToFreelancer => 'Instructions sent to freelancer';

  @override
  String get saveDraft => 'Save draft';

  @override
  String get publishToFreelancer => 'Publish to freelancer';

  @override
  String get startConversationFirstMessage =>
      'Start a conversation by sending your first message';

  @override
  String get chatSendFailed => 'Message failed to send';

  @override
  String get failedTapToRetry => 'Failed — Tap to retry';

  @override
  String get chatAttachment => 'Attachment';

  @override
  String get calendarYesterday => 'Yesterday';

  @override
  String get noConversationsYet => 'No conversations yet';

  @override
  String get noConversationsHint =>
      'Start a chat from a freelancer or client profile';

  @override
  String get noChatMatches => 'No matches found';

  @override
  String get tryDifferentSearch => 'Try a different name or keyword';

  @override
  String get myProfile => 'My Profile';

  @override
  String get dashboard => 'Dashboard';

  @override
  String get addDeposit => 'Add Deposit';

  @override
  String get depositHistory => 'Deposit History';

  @override
  String get paymentMethods => 'Payment Methods';

  @override
  String get withdrawals => 'Withdrawals';

  @override
  String get withdrawMoney => 'Withdraw Money';

  @override
  String get withdrawHistory => 'Withdraw History';

  @override
  String balanceWithAmount(String amount) {
    return 'Balance: $amount';
  }

  @override
  String get editProfileSubtitle => 'Edit your profile details';

  @override
  String get fullName => 'Full Name';

  @override
  String get enterYourName => 'Enter your name';

  @override
  String get phoneNo => 'Phone No.';

  @override
  String get enterPhoneNo => 'Enter Phone No.';

  @override
  String get aboutYourCompany => 'About your company';

  @override
  String get aboutCompanyHint =>
      'Short intro for freelancers viewing your jobs…';

  @override
  String get updating => 'Updating...';

  @override
  String get updateProfile => 'Update Profile';

  @override
  String get basicInfo => 'Basic info';

  @override
  String get professional => 'Professional';

  @override
  String get address => 'Address';

  @override
  String get enterFullAddress => 'Enter your full address';

  @override
  String get tapSetBirthDate => 'Tap to set your birth date';

  @override
  String ageHiddenOnProfile(int age) {
    return 'Age $age (birth date is hidden on profile)';
  }

  @override
  String get birthDateSaved => 'Birth date saved';

  @override
  String get ageLabel => 'Age';

  @override
  String get agePrivacyHint =>
      'Your age is shown on your profile. Your birth date is never displayed.';

  @override
  String get dateOfBirth => 'Date of birth';

  @override
  String get profileDescription => 'Profile description';

  @override
  String get profileDescriptionHint => 'Write a brief description about you…';

  @override
  String get yourSkills => 'Your skills';

  @override
  String get skillsOptionalHint =>
      'Optional — add skills to help clients find you.';

  @override
  String get jobTitleHint => 'e.g. Factory Worker';

  @override
  String get statPosted => 'Posted';

  @override
  String get myJobPosts => 'My Job Posts';

  @override
  String countTotal(int count) {
    return '$count total';
  }

  @override
  String get noJobsPostedYet => 'No jobs posted yet';

  @override
  String get postAJob => 'Post a job';

  @override
  String get avgRating => 'Avg rating';

  @override
  String get about => 'About';

  @override
  String get email => 'Email';

  @override
  String ageYearsOld(int age) {
    return '$age years old';
  }

  @override
  String get reviewsFromClientsHint =>
      'Reviews from clients appear here after completed orders.';

  @override
  String get clientProfile => 'Client profile';

  @override
  String get clientNotFound => 'Client not found';

  @override
  String get freelancerProfile => 'Freelancer profile';

  @override
  String get freelancerNotFound => 'Freelancer not found';

  @override
  String couldNotLoadProfile(String message) {
    return 'Could not load profile: $message';
  }

  @override
  String get jobsPosted => 'Jobs posted';

  @override
  String get memberSince => 'Member since';

  @override
  String get noneYet => 'None yet';

  @override
  String get noReviewsForClientYet => 'No reviews for this client yet.';

  @override
  String get viewServices => 'View services';

  @override
  String get noActiveServiceListing => 'No active service listing yet.';

  @override
  String get favouriteList => 'Saved jobs';

  @override
  String get removedFromFavourites => 'Removed from saved';

  @override
  String get addedToFavourites => 'Job saved';

  @override
  String get priceColon => 'Price: ';

  @override
  String get service => 'Service';

  @override
  String get serviceDetails => 'Service Details';

  @override
  String get orderNow => 'Order Now';

  @override
  String errorLoadingService(String message) {
    return 'Could not load service: $message';
  }

  @override
  String get noDescriptionAvailable => 'No description available.';

  @override
  String get deliveryDays => 'Delivery days';

  @override
  String get revisions => 'Revisions';

  @override
  String get unlimited => 'Unlimited';

  @override
  String totalReviewsCount(int count) {
    return 'Total $count Reviews';
  }

  @override
  String get anonymous => 'Anonymous';

  @override
  String get orderPlacedSuccess => 'Order placed successfully!';

  @override
  String errorPlacingOrder(String message) {
    return 'Could not place order: $message';
  }

  @override
  String get writeReview => 'Write a review';

  @override
  String get publishing => 'Publishing…';

  @override
  String get publishReview => 'Publish review';

  @override
  String get pleaseChooseStarRating => 'Please choose a star rating first.';

  @override
  String get reviewYourExperience => 'Review your experience';

  @override
  String get rateOverallExperience =>
      'How would you rate your overall experience with this seller?';

  @override
  String get freelancerForContract => 'Freelancer for this contract';

  @override
  String get selectRating => 'Select rating';

  @override
  String get yourFeedback => 'Your feedback';

  @override
  String get feedbackHint => 'Share what went well or what could improve…';

  @override
  String get uploadImageOptional => 'Upload image (optional)';

  @override
  String get tapToAdd => 'Tap to add';

  @override
  String get removePhoto => 'Remove photo';

  @override
  String get reviewAlreadySubmitted =>
      'You already submitted a review for this order.';

  @override
  String couldNotPublishReview(String message) {
    return 'Could not publish review: $message';
  }

  @override
  String couldNotOpenPicker(String message) {
    return 'Could not open picker: $message';
  }

  @override
  String get mapMovePinJob => 'Move the map so the pin marks the job site.';

  @override
  String get mapMovePinProfile => 'Move the map so the pin marks your spot.';

  @override
  String get mapUseThisLocation => 'Use this location';

  @override
  String mapAddressLookupFailed(String message) {
    return 'Address lookup failed: $message';
  }

  @override
  String get mapNoAddressForPoint =>
      'Could not read an address for this point. Try moving the map.';

  @override
  String get mapNoCityCountryFound =>
      'No city or country found. Try zooming in closer.';

  @override
  String get pickLocationOnMap => 'Pick location on map';

  @override
  String get mapPinConfirmHint => 'Center the pin on your spot, then confirm.';

  @override
  String get mapOrType => 'Map or type';

  @override
  String get supportCommonQuestions => 'Common Questions';

  @override
  String get supportLiveChat => 'Live Chat';

  @override
  String get supportProfileLoadFailed =>
      'Could not load your profile for support chat.';

  @override
  String get supportLiveChatNotConfigured => 'Live chat is not configured yet.';

  @override
  String get supportTawkEnvHint =>
      'Add TAWK_DIRECT_CHAT_LINK to your .env file (see .env.example). FAQ answers are still available in the first tab.';

  @override
  String get supportNoQuestionsYet => 'No questions available yet.';

  @override
  String get supportStillNeedHelp => 'Still need help? Chat with us';

  @override
  String get pleaseEnterValidAmount => 'Please enter a valid amount';

  @override
  String get depositSubmittedSuccess => 'Deposit submitted successfully!';

  @override
  String get submitting => 'Submitting...';

  @override
  String get submit => 'Submit';

  @override
  String get noDepositHistory => 'No deposit history';

  @override
  String get withdrawalRequestSubmitted => 'Withdrawal request submitted!';

  @override
  String get withdrawMethod => 'Withdraw method';

  @override
  String get enterAmount => 'Enter amount';

  @override
  String get creditOrDebitCard => 'Credit or Debit Card';

  @override
  String get txnTypeDeposit => 'Deposit';

  @override
  String get txnTypeWithdrawal => 'Withdrawal';

  @override
  String get txnTypeEarning => 'Earning';

  @override
  String get txnTypePayment => 'Payment';

  @override
  String get processingOrder => 'We\'re processing\nyour Order';

  @override
  String get stayTuned => 'Stay tuned...';

  @override
  String get chooseYourAction => 'Choose your Action';

  @override
  String get openGallery => 'Open Gallery';

  @override
  String get openFile => 'Open File';

  @override
  String get congratulations => 'Congratulations!';

  @override
  String get profileSetupCompleteBody =>
      'Your profile is successfully completed. You can make more changes after it\'s live.';

  @override
  String get cancelJobConfirmTitle => 'Are You Sure Cancel Your\nJob Post!';

  @override
  String get noLabel => 'No';

  @override
  String get yesLabel => 'Yes';

  @override
  String get cancelOrderWhy => 'Why are you Cancel Order?';

  @override
  String get enterReason => 'Enter Reason';

  @override
  String get confirm => 'Confirm';

  @override
  String get reviewSuccessTitle => 'Successfully';

  @override
  String get reviewSuccessBody =>
      'Thank you so much you\'ve just publish your review';

  @override
  String get gotIt => 'Got it!';

  @override
  String get withdrawAmount => 'Withdraw Amount';

  @override
  String get reviewWithdrawalDetails => 'Review your withdrawal details';

  @override
  String get transferTo => 'Transfer To';

  @override
  String get account => 'Account';

  @override
  String get withdrawalCompleted => 'Withdrawal Completed';

  @override
  String get orderCompleted => 'Order Completed';

  @override
  String get detailsLabel => 'Details';

  @override
  String get profileUpdatedShort => 'Profile updated!';

  @override
  String get filterAll => 'All';

  @override
  String get refreshTooltip => 'Refresh';

  @override
  String get noContractsYet => 'No contracts yet';

  @override
  String noFilteredContracts(String status) {
    return 'No $status contracts';
  }

  @override
  String get contractOverdue => 'Overdue';

  @override
  String deadlineDaysHoursLeft(int days, int hours) {
    return '${days}d ${hours}h left';
  }

  @override
  String deadlineHoursMinutesLeft(int hours, int minutes) {
    return '${hours}h ${minutes}m left';
  }

  @override
  String deadlineMinutesLeft(int minutes) {
    return '${minutes}m left';
  }

  @override
  String contractStartedOn(String date) {
    return 'Started $date';
  }

  @override
  String get amountCaps => 'AMOUNT';

  @override
  String get orderDetailsTitle => 'Order Details';

  @override
  String orderIdHash(String id) {
    return 'Order ID #$id';
  }

  @override
  String get sellerColon => 'Seller:';

  @override
  String get clientColon => 'Client:';

  @override
  String get labelTitle => 'Title';

  @override
  String get labelServiceInfo => 'Service Info';

  @override
  String get labelDuration => 'Duration';

  @override
  String get labelStatus => 'Status';

  @override
  String get labelRevisions => 'Revisions';

  @override
  String get orderSummary => 'Order Summary';

  @override
  String get subtotal => 'Subtotal';

  @override
  String get labelTotal => 'Total';

  @override
  String get deliveryDate => 'Delivery date';

  @override
  String get readMoreSuffix => '..Read more';

  @override
  String get readLessSuffix => '..Read less';

  @override
  String get closeAction => 'Close';

  @override
  String get contractCancelledSnack => 'Contract cancelled';

  @override
  String get contractKeptActive => 'Contract kept active';

  @override
  String get markJobComplete => 'Mark job complete';

  @override
  String get completingEllipsis => 'Completing…';

  @override
  String get markJobCompleteTitle => 'Mark this job complete?';

  @override
  String markJobCompleteDeliveredBody(String seller) {
    return 'You are confirming you received the work from $seller through their delivery submission. The contract will close as completed and you can leave a review next.';
  }

  @override
  String markJobCompleteManualBody(String seller) {
    return 'You are about to close this contract as finished. Use this when you have received the deliverables from $seller (for example via chat or files), even if they have not pressed \"Submit delivery\" yet.';
  }

  @override
  String get notYet => 'Not yet';

  @override
  String get yesCompleteJob => 'Yes, complete job';

  @override
  String get jobMarkedCompleteThanks => 'Job marked complete. Thank you!';

  @override
  String get leaveReviewTitle => 'Leave a review?';

  @override
  String get leaveReviewBody =>
      'Reviews help other clients and reward great work.';

  @override
  String get later => 'Later';

  @override
  String couldNotCompleteJob(String message) {
    return 'Could not complete job: $message';
  }

  @override
  String get couldNotOpenReviewMissingSeller =>
      'Could not open review (missing seller).';

  @override
  String get sellerSubmittedDelivery => 'Seller submitted delivery';

  @override
  String get yourDelivery => 'Your delivery';

  @override
  String get deliveredCalloutBody =>
      'Review what they sent. When you are happy with the result, tap Mark job complete below to close the order. To chat with the seller, use the ⋮ menu at the top.';

  @override
  String get openContractCalloutBody =>
      'Your freelancer must submit delivery before you can complete this contract. You can message the seller from the ⋮ menu at the top.';

  @override
  String cancellationRequestBannerBody(String seller) {
    return '$seller asked to cancel this contract. You can approve or keep it active. If you do not respond within 48 hours, the contract stays active.';
  }

  @override
  String get respondUsingBanner => 'Respond using the banner above.';

  @override
  String get reviewSubmittedForOrder =>
      'You submitted a review for this order.';

  @override
  String errorLoadingOrder(String message) {
    return 'Error loading order: $message';
  }

  @override
  String errorLoadingOrders(String message) {
    return 'Error loading orders: $message';
  }

  @override
  String get onboardingNotSet => 'Not set';

  @override
  String get onboardingAcknowledgedShort => 'Acknowledged';

  @override
  String get onboardingAwaitingAck => 'Awaiting ack';

  @override
  String get theSeller => 'the seller';

  @override
  String get roleSeller => 'Seller';

  @override
  String get roleClient => 'Client';

  @override
  String get cancellationRequestSent48h =>
      'Cancellation request sent. Waiting for client response (48h).';

  @override
  String get cancellationRequestWithdrawn => 'Cancellation request withdrawn';

  @override
  String get orderMarkedComplete => 'Order marked complete';

  @override
  String get withdrawingEllipsis => 'Withdrawing…';

  @override
  String get requestCancel => 'Request cancel';

  @override
  String get completeOrder => 'Complete Order';

  @override
  String get waitingForClientApproval => 'Waiting for client approval';

  @override
  String get waitingForDelivery => 'Waiting for delivery';

  @override
  String get waitingForClientResponse => 'Waiting for client response';

  @override
  String get sellerCancellationPendingBody =>
      'Your cancellation request was sent. The client has up to 48 hours to approve or keep the contract active.';

  @override
  String get contractCancelledTitle => 'Contract cancelled';

  @override
  String get viewFirstDayInstructions => 'View first-day instructions';

  @override
  String get readFirstDayInstructions => 'Read first-day instructions';

  @override
  String get firstDayInstructionsSharedBody =>
      'Your client shared site details, access, and contacts for this job.';

  @override
  String get openInstructions => 'Open instructions';

  @override
  String errorLoadingApplications(String message) {
    return 'Error loading applications: $message';
  }

  @override
  String get messageClientTooltip => 'Message client';

  @override
  String get openAttendance => 'Open attendance';

  @override
  String get instructionsReadyTap => 'Instructions ready — tap to read';

  @override
  String get rateExperienceWithClient =>
      'How would you rate your overall experience with this client?';

  @override
  String get postedThisContract => 'Posted this contract';

  @override
  String errorLoadingJobPosts(String message) {
    return 'Error loading job posts: $message';
  }

  @override
  String get jobPostClosed => 'Job post closed';

  @override
  String get addFirstDayInstructionsTitle => 'Add first-day instructions?';

  @override
  String get addFirstDayInstructionsBody =>
      'Share office location, building access, and site rules so your new hire knows what to do before day one.';

  @override
  String get addInstructionsNow => 'Add instructions now';

  @override
  String get sendLater => 'Send later';

  @override
  String get contractNotFoundForHire => 'Contract not found for this hire.';

  @override
  String get applicationRejected => 'Application rejected';

  @override
  String get hireFreelancerTitle => 'Hire freelancer?';

  @override
  String get hireAction => 'Hire';

  @override
  String get closeJob => 'Close Job';

  @override
  String get attendanceSettingsUpdated => 'Attendance settings updated';

  @override
  String get jobPostedSuccess => 'Job posted successfully!';

  @override
  String get pleaseEnterJobTitle => 'Please enter a job title';

  @override
  String get pleaseSelectCategory => 'Please select a category';

  @override
  String get enterValidCategory => 'Enter a valid category';

  @override
  String get pleaseEnterDescription => 'Please enter a description';

  @override
  String get pleaseEnterLocation => 'Please enter a location';

  @override
  String get createJobStepBasics => 'Basics';

  @override
  String get createJobStepDetails => 'Details';

  @override
  String get createJobStepLocation => 'Location';

  @override
  String get createJobStepBudget => 'Budget';

  @override
  String get createJobPostTitle => 'Create Job Post';

  @override
  String get shortJobTitleHint => 'Short title for the work';

  @override
  String get categoryNameLabel => 'Category name';

  @override
  String get categoryNameHint => 'e.g. Janitor, Baker, Waiter';

  @override
  String get describeJobLabel => 'Describe the job';

  @override
  String get describeJobHint => 'Scope, timeline, skills needed';

  @override
  String get workersNeeded => 'Workers needed';

  @override
  String get limitHiresToCount => 'Limit hires to this count';

  @override
  String get budgetMinLabel => 'Min';

  @override
  String get budgetMaxLabel => 'Max';

  @override
  String get budgetMinHint => 'Min (optional)';

  @override
  String get budgetMaxHint => 'Max (optional)';

  @override
  String get rateTypeLabel => 'Rate type';

  @override
  String get budgetBasisFixed => 'Fixed — total project';

  @override
  String get budgetBasisPerHour => 'Per hour';

  @override
  String get budgetBasisPerDay => 'Per day';

  @override
  String get budgetBasisPerMonth => 'Per month';

  @override
  String get postingEllipsis => 'Posting…';

  @override
  String get reviewAndPost => 'Review & post';

  @override
  String get nextStep => 'Next';

  @override
  String totalJobPostCount(int count) {
    return 'Total Job Post ($count)';
  }

  @override
  String get applicationsSection => 'Applications';

  @override
  String get rejectApplication => 'Reject';

  @override
  String get freelancerDefault => 'Freelancer';

  @override
  String get submitOfferTitle => 'Submit application';

  @override
  String get applyAtClientRate => 'Apply at client\'s rate';

  @override
  String get agreeToClientRate => 'Agree to\nclient\'s rate';

  @override
  String get customBid => 'Custom\nbid';

  @override
  String get offerNoPostedRateWarning =>
      'This job has no posted rate to agree to. Enter a custom amount instead.';

  @override
  String get offerSentAtPostedRate =>
      'Application sent at client\'s posted rate';

  @override
  String get offerSentSuccess => 'Your application has been sent';

  @override
  String get successTitle => 'Success';

  @override
  String get headsUp => 'Heads up';

  @override
  String get applyWithoutCounterBody =>
      'You are applying at the client\'s posted rate. They will see your application at that rate.';

  @override
  String get clientPostedRate => 'Client\'s posted rate';

  @override
  String yourApplicationAmount(String amount) {
    return 'Your application: $amount';
  }

  @override
  String get customBidIntroWithBudget =>
      'Enter your own amount if you want to bid differently from the client\'s budget.';

  @override
  String get customBidIntroNoBudget =>
      'This job has no posted budget — enter the amount you are asking for.';

  @override
  String clientPostedPrefix(String amount) {
    return 'Client posted: $amount';
  }

  @override
  String get yourOfferAmount => 'Your application amount';

  @override
  String get enterYourBid => 'Enter your bid';

  @override
  String get quoteAsLabel => 'Quote as';

  @override
  String get quoteTotal => 'Total';

  @override
  String get quotePerHour => '/ hour';

  @override
  String get quotePerDay => '/ day';

  @override
  String get quotePerMonth => '/ month';

  @override
  String get offerMessageOptional => 'Message (optional)';

  @override
  String get offerMessageHint => 'Optional note for the client…';

  @override
  String get findJobsTitle => 'Find Jobs';

  @override
  String get couldNotLoadSkillsFilter =>
      'Could not load skills filter. Pull to refresh later.';

  @override
  String get buyerRequestDetailsTitle => 'Job details';

  @override
  String get submitOfferAction => 'Submit application';

  @override
  String get cannotSubmitApplication => 'Cannot apply';

  @override
  String get applicationsReceived => 'Applications';

  @override
  String offersCount(int count) {
    return '$count applications';
  }

  @override
  String get locationLabel => 'Location';

  @override
  String get ellipsisBusy => '…';

  @override
  String couldNotOpenChatWithDetail(String message) {
    return 'Could not open chat: $message';
  }

  @override
  String get chooseFromGallery => 'Choose from gallery';

  @override
  String get filterClear => 'Clear';

  @override
  String get filterApply => 'Apply';

  @override
  String get clearFilters => 'Clear filters';

  @override
  String get deliverOrderTitle => 'Deliver Order';

  @override
  String get pleaseDescribeDelivery => 'Please describe your delivery';

  @override
  String get orderDeliveredSuccess => 'Order delivered successfully!';

  @override
  String get maxSize1Gb => 'Max size 1 GB';

  @override
  String get addCustomSkill => 'Add custom skill';

  @override
  String skillAlreadyAdded(String skill) {
    return 'You already added \"$skill\"';
  }

  @override
  String get noWithdrawalHistory => 'No withdrawal history';

  @override
  String get paymentPayPal => 'PayPal';

  @override
  String get paymentCreditCard => 'Credit Card';

  @override
  String get paymentBkash => 'Bkash';

  @override
  String get bidOfferLabel => 'Bid Offer';

  @override
  String get counterOfferLabel => 'Counter offer';

  @override
  String get counterOfferAction => 'Counter offer';

  @override
  String get counterOfferTitle => 'Send counter offer';

  @override
  String get counterOfferBody =>
      'Propose a different rate. This updates the application amount before you hire.';

  @override
  String get counterOfferAmountHint => 'Proposed amount';

  @override
  String get counterOfferNoteHint => 'Optional note for the freelancer';

  @override
  String get counterOfferSent => 'Counter offer sent';

  @override
  String get threadContextTitle => 'Related work';

  @override
  String get threadContextSubtitle =>
      'Active jobs and contracts with this person';

  @override
  String threadContextRelatedCount(int count) {
    return '$count related items';
  }

  @override
  String get threadContextLoading => 'Loading related work…';

  @override
  String get chatFilterApplications => 'Applications';

  @override
  String get chatFilterActive => 'Active';

  @override
  String get chatFilterPast => 'Past';

  @override
  String get chatTagApplication => 'Application';

  @override
  String get chatTagActive => 'Active';

  @override
  String get chatTagPast => 'Past';

  @override
  String get noChatsInFilter => 'No chats in this filter';

  @override
  String get noChatsInFilterHint =>
      'Try another filter or start a conversation from a profile';

  @override
  String get proposalCaps => 'PROPOSAL';

  @override
  String get labelColon => ':';

  @override
  String get requiredFieldMark => '*';

  @override
  String get writeReviewAction => 'Write review';

  @override
  String deliveryDaysCount(int count) {
    return '$count Days';
  }

  @override
  String get delete => 'Delete';

  @override
  String get jobAlertsTitle => 'Job alerts';

  @override
  String get jobAlertNew => 'New alert';

  @override
  String get jobAlertEdit => 'Edit alert';

  @override
  String get jobAlertsEmpty =>
      'Save rules for skills and distance. We will notify you when matching jobs are posted.';

  @override
  String get jobAlertUntitled => 'Job alert';

  @override
  String get jobAlertDeleteTitle => 'Delete alert?';

  @override
  String get jobAlertDeleteMessage =>
      'You will no longer get notifications for this rule.';

  @override
  String get jobAlertMatchesAllJobs => 'All open jobs';

  @override
  String get jobAlertAnyDistance => 'Any distance';

  @override
  String get jobAlertIncludesRemote => 'Includes remote';

  @override
  String jobAlertWithinKm(int km) {
    return 'Within $km km';
  }

  @override
  String jobAlertCategoriesCount(int count) {
    return '$count categories';
  }

  @override
  String get jobAlertNameLabel => 'Alert name (optional)';

  @override
  String get jobAlertNameHint => 'e.g. Plumber near me';

  @override
  String get jobAlertEnabled => 'Notifications on';

  @override
  String get jobAlertSkillsSection => 'Skills';

  @override
  String get jobAlertAddSkill => 'Add skill';

  @override
  String get jobAlertCategoriesSection => 'Categories';

  @override
  String get jobAlertAnyCategory => 'Any category';

  @override
  String get jobAlertPickCategories => 'Choose categories';

  @override
  String get jobAlertJobTypeSection => 'Job type';

  @override
  String get jobAlertLocationSection => 'Your location';

  @override
  String get jobAlertLocationSet => 'Location saved for distance';

  @override
  String get jobAlertLocationMissing =>
      'Pick your location on the map to use distance alerts.';

  @override
  String get jobAlertLimitDistance => 'Limit to nearby jobs';

  @override
  String get jobAlertIncludeRemote => 'Include remote jobs';

  @override
  String get jobAlertNeedProfileLocation =>
      'Pick your location on the map before using a distance limit.';

  @override
  String get jobAlertSaveFromFilter => 'Save as job alert';

  @override
  String get jobAlertsAppBarTooltip => 'Job alerts';

  @override
  String get workTrustSectionTitle => 'Verified work';

  @override
  String get workTrustSectionSubtitle =>
      'Counts come from completed on-site contracts and attendance check-ins on HupWorks—not paid badges.';

  @override
  String get workTrustStatCompletedOnsite => 'Completed on-site';

  @override
  String get workTrustStatVerifiedCheckins => 'Verified check-ins';

  @override
  String get workTrustStatVerifiedDays => 'Verified days';

  @override
  String get workTrustHighlightsTitle => 'Recent on-site work';

  @override
  String get workTrustAttendanceVerifiedTooltip =>
      'Attendance recorded for this job';

  @override
  String workTrustCompletedMonthLabel(String month, int year) {
    return '$month $year';
  }
}
