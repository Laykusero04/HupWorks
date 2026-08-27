// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Dutch Flemish (`nl`).
class AppLocalizationsNl extends AppLocalizations {
  AppLocalizationsNl([String locale = 'nl']) : super(locale);

  @override
  String get appTitle => 'HupWorks';

  @override
  String get language => 'Taal';

  @override
  String get languageEnglish => 'Engels';

  @override
  String get languageBengali => 'Bengaals';

  @override
  String get languageDutch => 'Nederlands';

  @override
  String get languageChanged => 'Taal bijgewerkt';

  @override
  String get cancel => 'Annuleren';

  @override
  String get save => 'Opslaan';

  @override
  String get send => 'Versturen';

  @override
  String get share => 'Delen';

  @override
  String get retry => 'Opnieuw';

  @override
  String get done => 'Klaar';

  @override
  String get back => 'Terug';

  @override
  String get add => 'Toevoegen';

  @override
  String get seeAll => 'Alles bekijken';

  @override
  String get viewAll => 'Alles bekijken';

  @override
  String get explore => 'Ontdekken';

  @override
  String get other => 'Overig';

  @override
  String get unknown => 'Onbekend';

  @override
  String get notSpecified => 'Niet opgegeven';

  @override
  String get aboutUs => 'Over ons';

  @override
  String get privacyPolicy => 'Privacybeleid';

  @override
  String get invite => 'Uitnodigen';

  @override
  String get inviteFriends => 'Vrienden uitnodigen';

  @override
  String get inviteBody =>
      'Deel je persoonlijke uitnodigingscode zodat vrienden HupWorks kunnen gebruiken. Referral-beloningen zijn nog niet beschikbaar.';

  @override
  String get inviteCodeCopied => 'Uitnodigingscode gekopieerd';

  @override
  String get inviteSignInRequired =>
      'Log in om je uitnodigingscode te krijgen.';

  @override
  String get shareInvite => 'Uitnodiging delen';

  @override
  String get report => 'Melden';

  @override
  String get reportSubmitted => 'Melding verzonden. Bedankt.';

  @override
  String get searchHint => 'Zoek diensten of freelancers';

  @override
  String get popularServices => 'Populaire diensten';

  @override
  String get topFreelancers => 'Top freelancers';

  @override
  String get services => 'Diensten';

  @override
  String get freelancers => 'Freelancers';

  @override
  String noSearchResults(String query) {
    return 'Geen diensten of freelancers voor \"$query\"';
  }

  @override
  String get noPopularResults => 'Nog geen populaire resultaten';

  @override
  String get couldNotLoadResults => 'Resultaten konden niet worden geladen';

  @override
  String get home => 'Home';

  @override
  String get settings => 'Instellingen';

  @override
  String get helpSupport => 'Help & ondersteuning';

  @override
  String get logOut => 'Uitloggen';

  @override
  String get sellerReport => 'Verkoper melden';

  @override
  String get favorite => 'Opslaan';

  @override
  String get transaction => 'Transactie';

  @override
  String get saving => 'Opslaan...';

  @override
  String get sending => 'Versturen...';

  @override
  String get profileUpdated => 'Profiel succesvol bijgewerkt!';

  @override
  String get pleaseEnterName => 'Vul je naam in';

  @override
  String get createProfile => 'Profiel aanmaken';

  @override
  String get setupProfile => 'Profiel instellen';

  @override
  String get saveProfile => 'Profiel opslaan';

  @override
  String get continueLabel => 'Doorgaan';

  @override
  String get errorGeneric => 'Er ging iets mis. Probeer het opnieuw.';

  @override
  String errorWithDetail(String message) {
    return 'Fout: $message';
  }

  @override
  String get errorLoading => 'Gegevens konden niet worden geladen';

  @override
  String get couldNotOpenChat => 'Chat kon niet worden geopend';

  @override
  String get pleaseFillAllFields => 'Vul alle velden in';

  @override
  String get pushNotifications => 'Pushmeldingen';

  @override
  String get notifications => 'Meldingen';

  @override
  String get message => 'Bericht';

  @override
  String get contracts => 'Contracten';

  @override
  String get findJobs => 'Vacatures';

  @override
  String get myJobs => 'Mijn jobs';

  @override
  String get talent => 'Talent';

  @override
  String get justNow => 'Zojuist';

  @override
  String get readAll => 'Alles gelezen';

  @override
  String get noNotifications => 'Geen meldingen';

  @override
  String minutesAgo(int count) {
    return '${count}m geleden';
  }

  @override
  String hoursAgo(int count) {
    return '${count}u geleden';
  }

  @override
  String daysAgo(int count) {
    return '${count}d geleden';
  }

  @override
  String get orderStatusActive => 'Actief';

  @override
  String get orderStatusPending => 'In afwachting';

  @override
  String get orderStatusCompleted => 'Voltooid';

  @override
  String get orderStatusCancelled => 'Geannuleerd';

  @override
  String get orderStatusDelivered => 'Opgeleverd';

  @override
  String get orderStatusCancellationPending => 'Annulering in behandeling';

  @override
  String get reportReasonNonOriginal => 'Niet-originele inhoud';

  @override
  String get reportReasonTrademark => 'Merkschendingen';

  @override
  String get reportReasonCopyright => 'Auteursrechtsschendingen';

  @override
  String get reportReasonOther => 'Andere redenen';

  @override
  String get reportReasonHarassment => 'Intimidatie of ongepast gedrag';

  @override
  String get reportReasonFakeJob => 'Nep of misleidende job';

  @override
  String get reportReasonNoShow => 'Niet komen opdagen of onvoltooid werk';

  @override
  String get reportReasonPaymentDispute => 'Betalings- of contractgeschil';

  @override
  String get reportReasonSpam => 'Spam of oplichting';

  @override
  String get reportDetailsTooShort =>
      'Beschrijf het probleem (minstens 10 tekens).';

  @override
  String get reportDetailsHelp =>
      'Vermeld wat er gebeurde, wanneer, en berichten of jobdetails die helpen bij de beoordeling.';

  @override
  String get reportOpenFromContextHint =>
      'Tip: open Rapport vanuit een chat, job of contract om de andere persoon automatisch te koppelen.';

  @override
  String reportReportingUser(String name) {
    return 'Rapportage van: $name';
  }

  @override
  String reportReportingJob(String title) {
    return 'Job: $title';
  }

  @override
  String get reportReportingContract => 'Gekoppeld aan dit contract';

  @override
  String get cancelReasonScheduleConflict => 'Planningconflict';

  @override
  String get cancelReasonScopeMismatch =>
      'Scope komt niet overeen met afspraak';

  @override
  String get cancelReasonSiteOrSafety => 'Locatie- of veiligheidsprobleem';

  @override
  String get cancelReasonPersonalEmergency => 'Persoonlijke noodsituatie';

  @override
  String get cancelReasonClientIssue => 'Probleem met klant / communicatie';

  @override
  String get cancelReasonOther => 'Overig';

  @override
  String get attendanceModeQrInOut => 'QR in- en uitklokken';

  @override
  String get attendanceModeQrOnce => 'QR check-in (Ã©Ã©n keer per dag)';

  @override
  String get attendanceModeSelfReport => 'Zelf melden in de app';

  @override
  String get attendanceModeDisabled => 'Aanwezigheid uit';

  @override
  String get attendanceClientHintQrInOut =>
      'Plaats een QR op locatie. Werknemers scannen om in en uit te klokken.';

  @override
  String get attendanceClientHintQrOnce =>
      'Plaats een QR op locatie. Werknemers scannen Ã©Ã©n keer per dag om in te checken.';

  @override
  String get attendanceClientHintSelfReport =>
      'Werknemers klokken in en uit in de app â€” geen QR nodig.';

  @override
  String get attendanceClientHintDisabled =>
      'Aanwezigheidsregistratie staat uit voor deze job.';

  @override
  String get attendanceFreelancerHintQrInOut =>
      'Scan de QR op locatie om in en uit te klokken.';

  @override
  String get attendanceFreelancerHintQrOnce =>
      'Scan de QR Ã©Ã©n keer bij aankomst.';

  @override
  String get attendanceFreelancerHintSelfReport =>
      'Tik op inklokken bij start en uitklokken bij vertrek.';

  @override
  String get attendanceFreelancerHintDisabled =>
      'Je klant heeft aanwezigheid niet ingeschakeld voor deze job.';

  @override
  String get attendanceOnboardingQrInOut =>
      'Open Aanwezigheid in HupWorks en scan de QR-code op de werklocatie om in te klokken bij aankomst en uit te klokken bij vertrek.';

  @override
  String get attendanceOnboardingQrOnce =>
      'Bij aankomst open je Aanwezigheid in HupWorks en scan je de QR-code op locatie. Je hoeft maar Ã©Ã©n keer per dag in te checken.';

  @override
  String get attendanceOnboardingSelfReport =>
      'Open Aanwezigheid in HupWorks op dit contract en tik op Inklokken bij start en Uitklokken bij vertrek. Geen QR-scan nodig.';

  @override
  String get attendanceOnboardingDisabled =>
      'Aanwezigheid wordt niet bijgehouden in de app voor deze job. Volg de instructies van je supervisor op locatie.';

  @override
  String get attendanceTracking => 'Aanwezigheidsregistratie';

  @override
  String get attendanceTrackingHint =>
      'Hoe werknemers tijd op locatie registreren.';

  @override
  String get genderMale => 'Man';

  @override
  String get genderFemale => 'Vrouw';

  @override
  String get aboutHupWorksTitle => 'Over HupWorks';

  @override
  String get aboutHupWorksBody =>
      'HupWorks is een marktplaats die klanten verbindt met freelancers en lokale werknemers voor jobs en diensten. We helpen mensen werk te plaatsen, talent in te huren, aanwezigheid op locatie te volgen en orders van begin tot eind te beheren.\n\nOns doel is huren en gehuurd worden eenvoudiger, duidelijker en betrouwbaarder te makenâ€”of je nu geschoolde hulp nodig hebt of je freelancebedrijf wilt laten groeien.';

  @override
  String get privacySectionCollectTitle => 'Gegevens die we verzamelen';

  @override
  String get privacySectionCollectBody =>
      'We verzamelen accountgegevens die je verstrekt (zoals naam, e-mail, telefoon en profielinformatie), content die je plaatst (jobs, berichten, reviews) en technische gegevens die nodig zijn om de app te laten werken (apparaat- en gebruiksgegevens). Betalingsgegevens worden verwerkt door onze betalingsproviders wanneer die functies zijn ingeschakeld.';

  @override
  String get privacySectionUseTitle => 'Hoe we informatie gebruiken';

  @override
  String get privacySectionUseBody =>
      'We gebruiken je gegevens om je account te beheren, relevante jobs en profielen te tonen, berichten en orderworkflows mogelijk te maken, veiligheid en betrouwbaarheid te verbeteren en belangrijke service-updates te communiceren. We verkopen je persoonlijke gegevens niet.';

  @override
  String get privacySectionShareTitle => 'Delen van informatie';

  @override
  String get privacySectionShareBody =>
      'We delen informatie met andere gebruikers alleen voor zover nodig voor de marktplaats (bijvoorbeeld je openbare profiel en berichten die je stuurt). We kunnen gegevens delen met dienstverleners die HupWorks helpen draaien, of wanneer wettelijk vereist, om rechten en veiligheid te beschermen, of om fraude of misbruik te onderzoeken.';

  @override
  String get privacySectionChoicesTitle => 'Jouw keuzes';

  @override
  String get privacySectionChoicesBody =>
      'Je kunt profielgegevens in de app bijwerken en support contacteren voor accountwijzigingen. Afhankelijk van je locatie kun je extra rechten hebben om persoonsgegevens in te zien, te corrigeren of te verwijderen.';

  @override
  String get privacySectionContactTitle => 'Contact';

  @override
  String get privacySectionContactBody =>
      'Heb je vragen over dit beleid of je gegevens? Neem contact op via Help & ondersteuning in de app.';

  @override
  String get authWelcomeHowToUse => 'Hoe wil je HupWorks gebruiken?';

  @override
  String get authRoleClient => 'Klant';

  @override
  String get authRoleClientSubtitle => 'Talent inhuren';

  @override
  String get authRoleFreelancer => 'Freelancer';

  @override
  String get authRoleFreelancerSubtitle => 'Werk vinden';

  @override
  String get authContinueAsClient => 'Doorgaan als klant';

  @override
  String get authContinueAsFreelancer => 'Doorgaan als freelancer';

  @override
  String get authAlreadyHaveAccount => 'Ik heb al een account';

  @override
  String get authWelcomeBack => 'Welkom terug';

  @override
  String get authSignInSubtitle => 'Log in om door te gaan naar HupWorks.';

  @override
  String get authEmail => 'E-mail';

  @override
  String get authEmailHint => 'jij@email.com';

  @override
  String get authPassword => 'Wachtwoord';

  @override
  String get authPasswordHint => 'Voer je wachtwoord in';

  @override
  String get authForgotPassword => 'Wachtwoord vergeten?';

  @override
  String get authLogIn => 'Inloggen';

  @override
  String get authDontHaveAccount => 'Nog geen account?';

  @override
  String get authSignUp => 'Registreren';

  @override
  String get authOrContinueWith => 'Of ga verder met';

  @override
  String get authAgreeToThe => 'Ik ga akkoord met de ';

  @override
  String get authTermsOfService => 'Servicevoorwaarden';

  @override
  String get authFirstName => 'Voornaam';

  @override
  String get authFirstNameHint => 'Voornaam';

  @override
  String get authLastName => 'Achternaam';

  @override
  String get authLastNameHint => 'Achternaam';

  @override
  String get authCreateAccount => 'Maak je account aan';

  @override
  String get authJoinAsClient => 'Word klant om freelancers in te huren.';

  @override
  String get authJoinAsFreelancer => 'Word freelancer om werk te vinden.';

  @override
  String get authPhone => 'Telefoon';

  @override
  String get authPhoneHint => 'Telefoonnummer';

  @override
  String get authSignUpButton => 'Registreren';

  @override
  String get authOrSignUpWith => 'Of registreer met';

  @override
  String get authAlreadyHaveAccountShort => 'Heb je al een account?';

  @override
  String get authPasswordMinLength => 'Wachtwoord moet minstens 6 tekens zijn';

  @override
  String get authMustAgreeTerms => 'Ga akkoord met de Servicevoorwaarden';

  @override
  String get authForgotPasswordTitle => 'Wachtwoord vergeten?';

  @override
  String get authForgotPasswordBody =>
      'Vul je e-mail in en we sturen een link om je wachtwoord te resetten.';

  @override
  String get authResetPassword => 'Wachtwoord resetten';

  @override
  String get authEnterEmail => 'Vul je e-mail in';

  @override
  String get authResetLinkSent => 'Resetlink verzonden. Controleer je e-mail.';

  @override
  String get authVerification => 'Verificatie';

  @override
  String get authCodeSentToEmail =>
      'We hebben de code naar je e-mail gestuurd-';

  @override
  String get authDidntReceiveCode => 'Code niet ontvangen?';

  @override
  String get authResendCode => 'Code opnieuw sturen';

  @override
  String get selectProfileImage => 'Selecteer profielfoto';

  @override
  String get photoGallery => 'Fotogalerij';

  @override
  String get takePhoto => 'Foto maken';

  @override
  String get uploadYourPhoto => 'Upload je foto';

  @override
  String get userName => 'Gebruikersnaam';

  @override
  String get phone => 'Telefoon';

  @override
  String get country => 'Land';

  @override
  String get streetAddress => 'Straatadres';

  @override
  String get city => 'Stad';

  @override
  String get state => 'Provincie';

  @override
  String get zipCode => 'Postcode';

  @override
  String get selectLanguage => 'Selecteer taal';

  @override
  String get selectGender => 'Selecteer geslacht';

  @override
  String get addLanguage => 'Taal toevoegen';

  @override
  String get addNew => 'Nieuw toevoegen';

  @override
  String get noLanguagesYet => 'Nog geen talen toegevoegd.';

  @override
  String get jobTitle => 'Functietitel';

  @override
  String get skills => 'Vaardigheden';

  @override
  String get aboutYou => 'Over jou';

  @override
  String get aboutYouHint => 'Vertel klanten over jezelf';

  @override
  String stepOf(int current, int total) {
    return 'Stap $current van $total';
  }

  @override
  String get browseCategories => 'Blader door categorieÃ«n';

  @override
  String get yourRecentJobs => 'Je recente jobs';

  @override
  String get postJob => 'Job plaatsen';

  @override
  String get findTalent => 'Talent vinden';

  @override
  String get categories => 'CategorieÃ«n';

  @override
  String get hireTopRated => 'Huurtop freelancers in';

  @override
  String get postAJobBanner => 'Plaats een job en ontvang offertes';

  @override
  String get postNow => 'Nu plaatsen';

  @override
  String get browse => 'Bladeren';

  @override
  String get noCategoriesYet => 'Nog geen categorieÃ«n';

  @override
  String get noJobsYet => 'Nog geen jobs';

  @override
  String get noFreelancersYet => 'Nog geen freelancers';

  @override
  String get open => 'Open';

  @override
  String get closed => 'Gesloten';

  @override
  String get fullTime => 'Fulltime';

  @override
  String get partTime => 'Parttime';

  @override
  String get viewProfile => 'Profiel bekijken';

  @override
  String get verifiedFreelancer => 'Geverifieerde freelancer';

  @override
  String get allCategories => 'Alle categorieÃ«n';

  @override
  String get searchCategories => 'Zoek categorieÃ«n';

  @override
  String get noCategoriesMatch => 'Geen overeenkomende categorieÃ«n';

  @override
  String get searchFreelancers => 'Zoek freelancers...';

  @override
  String get noFreelancersMatch => 'Geen overeenkomende freelancers';

  @override
  String get findYourNextJob => 'Vind je volgende job';

  @override
  String get findYourNextJobSubtitle =>
      'Bekijk openstaande rollen en solliciteer in minuten.';

  @override
  String get myApplications => 'Mijn sollicitaties';

  @override
  String get browseJobs => 'Jobs bekijken';

  @override
  String get statusAccepted => 'Geaccepteerd';

  @override
  String get statusRejected => 'Afgewezen';

  @override
  String get statusPending => 'In afwachting';

  @override
  String get yourWork => 'Jouw werk';

  @override
  String get activeContracts => 'Actieve contracten';

  @override
  String get wallet => 'Portemonnee';

  @override
  String get needsAttention => 'Aandacht nodig';

  @override
  String attentionItems(int count) {
    return '$count items vragen aandacht';
  }

  @override
  String get messages => 'Berichten';

  @override
  String get applications => 'Sollicitaties';

  @override
  String get attendance => 'Aanwezigheid';

  @override
  String get shortcutFindJobs => 'Vacatures';

  @override
  String get shortcutFindJobsSub => 'Bekijk openstaande rollen';

  @override
  String get shortcutMessages => 'Berichten';

  @override
  String get shortcutMessagesSub => 'Chat met klanten';

  @override
  String get shortcutContracts => 'Contracten';

  @override
  String get shortcutContractsSub => 'Actief werk';

  @override
  String get shortcutApplications => 'Sollicitaties';

  @override
  String get shortcutApplicationsSub => 'Volg status';

  @override
  String get shortcutAttendance => 'Aanwezigheid';

  @override
  String get shortcutAttendanceSub => 'In- en uitklokken';

  @override
  String get balance => 'Saldo';

  @override
  String get totalSpent => 'Totaal uitgegeven';

  @override
  String get earned => 'Verdiend';

  @override
  String sayHelloTo(String name) {
    return 'Zeg hallo tegen $name';
  }

  @override
  String get block => 'Blokkeren';

  @override
  String get noMessagesYet => 'Nog geen berichten';

  @override
  String get searchChats => 'Zoek chats';

  @override
  String get typeAMessage => 'Typ een bericht';

  @override
  String get cancellationRequestTitle => 'Annulering aanvragen';

  @override
  String get cancellationRequestBody =>
      'Je klant heeft 48 uur om goed te keuren of het contract te behouden.';

  @override
  String get cancellationReason => 'Reden';

  @override
  String get cancellationExplain => 'Leg kort uit';

  @override
  String get cancellationSubmit => 'Aanvraag indienen';

  @override
  String cancellationMinChars(int count) {
    return 'Schrijf minstens $count tekens';
  }

  @override
  String get keepContract => 'Contract behouden';

  @override
  String get approveCancellation => 'Annulering goedkeuren';

  @override
  String get withdrawCancelRequest => 'Aanvraag intrekken';

  @override
  String get waitingForClientCancel =>
      'Wachten tot de klant je annuleringsverzoek beoordeelt';

  @override
  String get cancellationRequested => 'Annulering aangevraagd';

  @override
  String get awaitingYourApproval => 'Wacht op jouw goedkeuring';

  @override
  String get inProgress => 'Bezig';

  @override
  String get markComplete => 'Markeer als voltooid';

  @override
  String get deliverWork => 'Werk opleveren';

  @override
  String get clockIn => 'Inklokken';

  @override
  String get clockOut => 'Uitklokken';

  @override
  String get scanAttendanceQr => 'Scan aanwezigheids-QR';

  @override
  String get editProfile => 'Profiel bewerken';

  @override
  String get profileDetails => 'Profielgegevens';

  @override
  String get favourites => 'Opgeslagen';

  @override
  String get reviews => 'Reviews';

  @override
  String get noFavouritesYet => 'Nog geen opgeslagen jobs';

  @override
  String get noReviewsYet => 'Nog geen reviews';

  @override
  String get mapPickLocation => 'Kies locatie';

  @override
  String get mapConfirmLocation => 'Bevestig locatie';

  @override
  String get mapSearchPlace => 'Zoek plaats';

  @override
  String get deposit => 'Storten';

  @override
  String get withdraw => 'Opnemen';

  @override
  String get addPaymentMethod => 'Betaalmethode toevoegen';

  @override
  String get amount => 'Bedrag';

  @override
  String get history => 'Geschiedenis';

  @override
  String get noTransactionsYet => 'Nog geen transacties';

  @override
  String get supportChat => 'Supportchat';

  @override
  String get typeSupportMessage => 'Typ je bericht';

  @override
  String get clientReport => 'Klant melden';

  @override
  String get selectReason => 'Selecteer reden';

  @override
  String get describeIssue => 'Beschrijf het probleem';

  @override
  String get submitReport => 'Melding indienen';

  @override
  String get cancellationSheetTitle => 'Contract annuleren aanvragen';

  @override
  String get cancellationSheetBody =>
      'Je klant wordt op de hoogte gesteld en kan binnen 48 uur goedkeuren of afwijzen. Het contract blijft actief tot ze reageren.';

  @override
  String get cancellationExplainHint =>
      'Wat is er gebeurd? Dit helpt je klant je verzoek te begrijpen.';

  @override
  String cancellationCharCount(int current, int min) {
    return '$current / $min tekens minimum';
  }

  @override
  String cancellationReasonLine(String reason) {
    return 'Reden: $reason';
  }

  @override
  String get reportWhyQuestion => 'Waarom rapporteer je?';

  @override
  String get reportSellerProfileUrl => 'Verkopersprofiel-URL';

  @override
  String get reportEnterSellerProfileUrl => 'Voer verkopersprofiel-url in';

  @override
  String get reportOriginalContentUrl => 'URL van originele inhoud';

  @override
  String get reportEnterPostUrl => 'Voer post-url in';

  @override
  String get reportAdditionalInfo => 'Wat is er gebeurd?';

  @override
  String get reportEnterInformation => 'Beschrijf het probleem…';

  @override
  String get promoVerifiedTalentSubtitle =>
      'Geverifieerd talent voor elk project';

  @override
  String get promoProposalsSubtitle =>
      'Ontvang binnen enkele minuten voorstellen';

  @override
  String get promoNicheServicesSubtitle => 'Vind diensten in elke niche';

  @override
  String get jobTypeGig => 'Gig';

  @override
  String get recentJobsEmptyHint =>
      'Tik op \"Vacature plaatsen\" om te beginnen';

  @override
  String get postJobShort => 'Plaatsen';

  @override
  String get untitled => 'Zonder titel';

  @override
  String get untitledJob => 'Vacature zonder titel';

  @override
  String get categoryGeneral => 'Algemeen';

  @override
  String get proBadge => 'Pro';

  @override
  String get noApplicationsYet => 'Nog geen sollicitaties';

  @override
  String get noApplicationsYetHint =>
      'Blader door open vacatures en stuur een duidelijk voorstel.';

  @override
  String get pendingApplications => 'Openstaande sollicitaties';

  @override
  String get completedThisMonth => 'Deze maand afgerond';

  @override
  String get yourRating => 'Jouw beoordeling';

  @override
  String reviewCount(int count) {
    return '$count beoordelingen';
  }

  @override
  String openJobsToBrowse(int count) {
    return '$count open vacatures om te bekijken';
  }

  @override
  String get periodLive => 'Live';

  @override
  String get periodThisMonth => 'Deze maand';

  @override
  String get shortcuts => 'Snelkoppelingen';

  @override
  String get attentionContractDeliveredOne =>
      '1 contract geleverd â€” wacht op goedkeuring klant';

  @override
  String attentionContractDeliveredMany(int count) {
    return '$count contracten geleverd â€” wacht op goedkeuring klant';
  }

  @override
  String get attentionOnsiteOne =>
      '1 contract op locatie â€” inchecken via Aanwezigheid';

  @override
  String attentionOnsiteMany(int count) {
    return '$count contracten op locatie â€” gebruik Aanwezigheid';
  }

  @override
  String get attendanceOffForJob => 'Aanwezigheid staat uit voor deze job.';

  @override
  String get checkedIn => 'Ingecheckt';

  @override
  String get checkIn => 'Inchecken';

  @override
  String get noPunchesToday => 'Nog geen stempels vandaag.';

  @override
  String get noAttendanceRecordedToday =>
      'Vandaag geen aanwezigheid geregistreerd.';

  @override
  String get confirmAttendance => 'Aanwezigheid bevestigen';

  @override
  String get alreadyCheckedInToday => 'Vandaag al ingecheckt';

  @override
  String get readyForDailyCheckIn => 'Klaar voor dagelijkse check-in';

  @override
  String clockedInAt(String time) {
    return 'Ingeklokt om $time';
  }

  @override
  String get notClockedInToday => 'Vandaag niet ingeklokt';

  @override
  String get calendarToday => 'Vandaag';

  @override
  String get recordLabel => 'Registreren';

  @override
  String get alreadyCheckedInTodayMessage =>
      'Je hebt vandaag al ingecheckt voor deze job.';

  @override
  String get attendanceQrOnceDailyHint =>
      'Deze job gebruikt Ã©Ã©n check-in scan per dag (geen uitklok-scan).';

  @override
  String get checkInForToday => 'Vandaag inchecken';

  @override
  String attendancePunchRecorded(String punch, String minutes) {
    return '$punch geregistreerd. Vandaag: $minutes gewerkt.';
  }

  @override
  String useSuggestedPunch(String punch) {
    return 'Gebruik suggestie: $punch';
  }

  @override
  String get attendanceScanCameraHint =>
      'Richt je camera op de aanwezigheids-QR op de werklocatie.';

  @override
  String get attendanceScanLoadingDetails => 'Vacaturegegevens ladenâ€¦';

  @override
  String attendanceScanningForJob(String title) {
    return 'Scannen voor: $title';
  }

  @override
  String get viewMyOnsiteJobs => 'Mijn jobs op locatie bekijken';

  @override
  String get attendanceQrScreenTitle => 'Aanwezigheids-QR';

  @override
  String get attendancePrintQrAtSite =>
      'Print deze QR en hang hem op waar werknemers inchecken.';

  @override
  String get attendanceCouldNotLoadQr => 'QR kon niet worden geladen';

  @override
  String get attendanceSharePrintInstructions => 'Delen / printinstructies';

  @override
  String get regenerateQr => 'QR opnieuw genereren';

  @override
  String get regenerateQrConfirmTitle => 'QR opnieuw genereren?';

  @override
  String get regenerateQrConfirmBody =>
      'De oude geprinte QR werkt niet meer. Print en hang de nieuwe code op locatie op.';

  @override
  String get regenerate => 'Opnieuw genereren';

  @override
  String get attendanceNewQrReady => 'Nieuwe aanwezigheids-QR klaar';

  @override
  String get attendanceHowItWorks => 'Hoe het werkt';

  @override
  String get attendanceHowItWorksBody =>
      '1. Print en plak deze QR op de werkplek.\n2. Ingehuurde freelancers openen HupWorks en scannen.\n3. Ze bevestigen in- of uitklokken op hun telefoon.\n4. Bekijk de aanwezigheid van vandaag op het vacaturedetailscherm.';

  @override
  String get noOnsiteJobsYet => 'Nog geen jobs op locatie';

  @override
  String get noOnsiteJobsBody =>
      'Je hebt een geaccepteerd contract op locatie nodig. Je klant kiest bij het plaatsen hoe aanwezigheid werkt (QR of zelf melden).';

  @override
  String get findOnsiteJobs => 'Jobs op locatie zoeken';

  @override
  String get selectedJob => 'Geselecteerde job';

  @override
  String get openContract => 'Contract openen';

  @override
  String get attendanceTimeIn => 'Tijd in';

  @override
  String get attendanceTimeOut => 'Tijd uit';

  @override
  String attendanceWorkedToday(String duration) {
    return 'Vandaag gewerkt: $duration';
  }

  @override
  String attendancePunchTodaySummary(String punch, String duration) {
    return '$punch â€¢ $duration vandaag';
  }

  @override
  String get attendanceLessThanOneMin => 'Minder dan 1 min';

  @override
  String attendanceMinutesOnly(int count) {
    return '$count min';
  }

  @override
  String attendanceHoursOnly(int count) {
    return '${count}u';
  }

  @override
  String attendanceHoursMinutes(int hours, int minutes) {
    return '${hours}u ${minutes}m';
  }

  @override
  String get firstDayInstructions => 'Instructies eerste dag';

  @override
  String get instructionsNotAvailable => 'Instructies nog niet beschikbaar.';

  @override
  String get onboardingUseScanQrHint =>
      'Gebruik bij aankomst op locatie Scan aanwezigheids-QR op het contractscherm.';

  @override
  String get noSectionDetails => 'Geen sectiedetails opgegeven.';

  @override
  String get pleaseWaitEllipsis => 'Even geduldâ€¦';

  @override
  String get onboardingAcknowledgedLabel =>
      'Je hebt deze instructies bevestigd';

  @override
  String get onboardingReadUnderstood => 'Ik heb gelezen en begrepen';

  @override
  String get onboardingEditorLead =>
      'Deel locatiegegevens, toegang en contacten zodat je hire weet wat te doen op dag Ã©Ã©n.';

  @override
  String get onboardingResendNotice =>
      'Al verzonden. Opnieuw opslaan en publiceren stuurt een melding naar de freelancer.';

  @override
  String get addDetailsHint => 'Details toevoegenâ€¦';

  @override
  String get draftSaved => 'Concept opgeslagen';

  @override
  String get instructionsSentToFreelancer =>
      'Instructies naar freelancer gestuurd';

  @override
  String get saveDraft => 'Concept opslaan';

  @override
  String get publishToFreelancer => 'Publiceren naar freelancer';

  @override
  String get startConversationFirstMessage =>
      'Start een gesprek door je eerste bericht te sturen';

  @override
  String get chatSendFailed => 'Bericht kon niet worden verzonden';

  @override
  String get failedTapToRetry => 'Mislukt â€” tik om opnieuw te proberen';

  @override
  String get chatAttachment => 'Bijlage';

  @override
  String get calendarYesterday => 'Gisteren';

  @override
  String get noConversationsYet => 'Nog geen gesprekken';

  @override
  String get noConversationsHint =>
      'Start een chat vanaf een freelancer- of klantprofiel';

  @override
  String get noChatMatches => 'Geen resultaten';

  @override
  String get tryDifferentSearch => 'Probeer een andere naam of trefwoord';

  @override
  String get myProfile => 'Mijn profiel';

  @override
  String get dashboard => 'Dashboard';

  @override
  String get addDeposit => 'Storting toevoegen';

  @override
  String get depositHistory => 'Stortingsgeschiedenis';

  @override
  String get paymentMethods => 'Betaalmethoden';

  @override
  String get withdrawals => 'Opnames';

  @override
  String get withdrawMoney => 'Geld opnemen';

  @override
  String get withdrawHistory => 'Opnamegeschiedenis';

  @override
  String balanceWithAmount(String amount) {
    return 'Saldo: $amount';
  }

  @override
  String get editProfileSubtitle => 'Bewerk je profielgegevens';

  @override
  String get fullName => 'Volledige naam';

  @override
  String get enterYourName => 'Voer je naam in';

  @override
  String get phoneNo => 'Telefoonnr.';

  @override
  String get enterPhoneNo => 'Voer telefoonnr. in';

  @override
  String get aboutYourCompany => 'Over je bedrijf';

  @override
  String get aboutCompanyHint =>
      'Korte intro voor freelancers die je vacatures bekijken…';

  @override
  String get updating => 'Bijwerken...';

  @override
  String get updateProfile => 'Profiel bijwerken';

  @override
  String get basicInfo => 'Basisinfo';

  @override
  String get professional => 'Professioneel';

  @override
  String get address => 'Adres';

  @override
  String get enterFullAddress => 'Voer je volledige adres in';

  @override
  String get tapSetBirthDate => 'Tik om je geboortedatum in te stellen';

  @override
  String ageHiddenOnProfile(int age) {
    return 'Leeftijd $age (geboortedatum verborgen op profiel)';
  }

  @override
  String get birthDateSaved => 'Geboortedatum opgeslagen';

  @override
  String get ageLabel => 'Leeftijd';

  @override
  String get agePrivacyHint =>
      'Je leeftijd wordt op je profiel getoond. Je geboortedatum wordt nooit weergegeven.';

  @override
  String get dateOfBirth => 'Geboortedatum';

  @override
  String get profileDescription => 'Profielbeschrijving';

  @override
  String get profileDescriptionHint =>
      'Schrijf een korte beschrijving over jezelf…';

  @override
  String get yourSkills => 'Je vaardigheden';

  @override
  String get skillsOptionalHint =>
      'Optioneel — voeg vaardigheden toe zodat klanten je vinden.';

  @override
  String get jobTitleHint => 'bijv. Fabrieksarbeider';

  @override
  String get statPosted => 'Geplaatst';

  @override
  String get myJobPosts => 'Mijn vacatures';

  @override
  String countTotal(int count) {
    return '$count totaal';
  }

  @override
  String get noJobsPostedYet => 'Nog geen vacatures geplaatst';

  @override
  String get postAJob => 'Vacature plaatsen';

  @override
  String get avgRating => 'Gem. beoordeling';

  @override
  String get about => 'Over';

  @override
  String get email => 'E-mail';

  @override
  String ageYearsOld(int age) {
    return '$age jaar';
  }

  @override
  String get reviewsFromClientsHint =>
      'Beoordelingen van klanten verschijnen hier na voltooide orders.';

  @override
  String get clientProfile => 'Klantprofiel';

  @override
  String get clientNotFound => 'Klant niet gevonden';

  @override
  String get freelancerProfile => 'Freelancerprofiel';

  @override
  String get freelancerNotFound => 'Freelancer niet gevonden';

  @override
  String couldNotLoadProfile(String message) {
    return 'Profiel laden mislukt: $message';
  }

  @override
  String get jobsPosted => 'Vacatures geplaatst';

  @override
  String get memberSince => 'Lid sinds';

  @override
  String get noneYet => 'Nog geen';

  @override
  String get noReviewsForClientYet => 'Nog geen beoordelingen voor deze klant.';

  @override
  String get viewServices => 'Diensten bekijken';

  @override
  String get noActiveServiceListing => 'Nog geen actieve dienstvermelding.';

  @override
  String get favouriteList => 'Opgeslagen jobs';

  @override
  String get removedFromFavourites => 'Verwijderd uit opgeslagen';

  @override
  String get addedToFavourites => 'Job opgeslagen';

  @override
  String get priceColon => 'Prijs: ';

  @override
  String get service => 'Dienst';

  @override
  String get serviceDetails => 'Dienstdetails';

  @override
  String get orderNow => 'Nu bestellen';

  @override
  String errorLoadingService(String message) {
    return 'Dienst laden mislukt: $message';
  }

  @override
  String get noDescriptionAvailable => 'Geen beschrijving beschikbaar.';

  @override
  String get deliveryDays => 'Leverdagen';

  @override
  String get revisions => 'Revisies';

  @override
  String get unlimited => 'Onbeperkt';

  @override
  String totalReviewsCount(int count) {
    return 'Totaal $count beoordelingen';
  }

  @override
  String get anonymous => 'Anoniem';

  @override
  String get orderPlacedSuccess => 'Bestelling geplaatst!';

  @override
  String errorPlacingOrder(String message) {
    return 'Bestelling plaatsen mislukt: $message';
  }

  @override
  String get writeReview => 'Schrijf een review';

  @override
  String get publishing => 'Publiceren…';

  @override
  String get publishReview => 'Review publiceren';

  @override
  String get pleaseChooseStarRating => 'Kies eerst een sterrenbeoordeling.';

  @override
  String get reviewYourExperience => 'Beoordeel je ervaring';

  @override
  String get rateOverallExperience =>
      'Hoe beoordeel je je algehele ervaring met deze verkoper?';

  @override
  String get freelancerForContract => 'Freelancer voor dit contract';

  @override
  String get selectRating => 'Selecteer beoordeling';

  @override
  String get yourFeedback => 'Je feedback';

  @override
  String get feedbackHint => 'Deel wat goed ging of wat beter kan…';

  @override
  String get uploadImageOptional => 'Afbeelding uploaden (optioneel)';

  @override
  String get tapToAdd => 'Tik om toe te voegen';

  @override
  String get removePhoto => 'Foto verwijderen';

  @override
  String get reviewAlreadySubmitted =>
      'Je hebt al een review ingediend voor deze order.';

  @override
  String couldNotPublishReview(String message) {
    return 'Review publiceren mislukt: $message';
  }

  @override
  String couldNotOpenPicker(String message) {
    return 'Keuzescherm openen mislukt: $message';
  }

  @override
  String get mapMovePinJob =>
      'Verplaats de kaart zodat de pin de werkplek markeert.';

  @override
  String get mapMovePinProfile =>
      'Verplaats de kaart zodat de pin je locatie markeert.';

  @override
  String get mapUseThisLocation => 'Deze locatie gebruiken';

  @override
  String mapAddressLookupFailed(String message) {
    return 'Adres opzoeken mislukt: $message';
  }

  @override
  String get mapNoAddressForPoint =>
      'Geen adres voor dit punt. Probeer de kaart te verplaatsen.';

  @override
  String get mapNoCityCountryFound =>
      'Geen stad of land gevonden. Zoom verder in.';

  @override
  String get pickLocationOnMap => 'Locatie op kaart kiezen';

  @override
  String get mapPinConfirmHint => 'Centreer de pin op je plek en bevestig.';

  @override
  String get mapOrType => 'Kaart of typen';

  @override
  String get supportCommonQuestions => 'Veelgestelde vragen';

  @override
  String get supportLiveChat => 'Live chat';

  @override
  String get supportProfileLoadFailed =>
      'Profiel laden voor supportchat mislukt.';

  @override
  String get supportLiveChatNotConfigured =>
      'Live chat is nog niet geconfigureerd.';

  @override
  String get supportTawkEnvHint =>
      'Voeg TAWK_DIRECT_CHAT_LINK toe aan je .env (zie .env.example). FAQ blijft beschikbaar in het eerste tabblad.';

  @override
  String get supportNoQuestionsYet => 'Nog geen vragen beschikbaar.';

  @override
  String get supportStillNeedHelp => 'Nog hulp nodig? Chat met ons';

  @override
  String get pleaseEnterValidAmount => 'Voer een geldig bedrag in';

  @override
  String get depositSubmittedSuccess => 'Storting ingediend!';

  @override
  String get submitting => 'Indienen...';

  @override
  String get submit => 'Indienen';

  @override
  String get noDepositHistory => 'Geen stortingsgeschiedenis';

  @override
  String get withdrawalRequestSubmitted => 'Opnameverzoek ingediend!';

  @override
  String get withdrawMethod => 'Opnamemethode';

  @override
  String get enterAmount => 'Voer bedrag in';

  @override
  String get creditOrDebitCard => 'Credit- of debetkaart';

  @override
  String get txnTypeDeposit => 'Storting';

  @override
  String get txnTypeWithdrawal => 'Opname';

  @override
  String get txnTypeEarning => 'Verdienste';

  @override
  String get txnTypePayment => 'Betaling';

  @override
  String get processingOrder => 'We verwerken\nje bestelling';

  @override
  String get stayTuned => 'Even geduld...';

  @override
  String get chooseYourAction => 'Kies je actie';

  @override
  String get openGallery => 'Galerij openen';

  @override
  String get openFile => 'Bestand openen';

  @override
  String get congratulations => 'Gefeliciteerd!';

  @override
  String get profileSetupCompleteBody =>
      'Je profiel is voltooid. Je kunt later nog wijzigingen maken.';

  @override
  String get cancelJobConfirmTitle =>
      'Weet je zeker dat je je\nvacature wilt annuleren!';

  @override
  String get noLabel => 'Nee';

  @override
  String get yesLabel => 'Ja';

  @override
  String get cancelOrderWhy => 'Waarom annuleer je de order?';

  @override
  String get enterReason => 'Voer reden in';

  @override
  String get confirm => 'Bevestigen';

  @override
  String get reviewSuccessTitle => 'Gelukt';

  @override
  String get reviewSuccessBody => 'Bedankt, je review is gepubliceerd';

  @override
  String get gotIt => 'Begrepen!';

  @override
  String get withdrawAmount => 'Opnamebedrag';

  @override
  String get reviewWithdrawalDetails => 'Controleer je opnamegegevens';

  @override
  String get transferTo => 'Overmaken naar';

  @override
  String get account => 'Account';

  @override
  String get withdrawalCompleted => 'Opname voltooid';

  @override
  String get orderCompleted => 'Order voltooid';

  @override
  String get detailsLabel => 'Details';

  @override
  String get profileUpdatedShort => 'Profiel bijgewerkt!';

  @override
  String get filterAll => 'Alles';

  @override
  String get refreshTooltip => 'Vernieuwen';

  @override
  String get noContractsYet => 'Nog geen contracten';

  @override
  String noFilteredContracts(String status) {
    return 'Geen $status contracten';
  }

  @override
  String get contractOverdue => 'Te laat';

  @override
  String deadlineDaysHoursLeft(int days, int hours) {
    return '${days}d ${hours}u resterend';
  }

  @override
  String deadlineHoursMinutesLeft(int hours, int minutes) {
    return '${hours}u ${minutes}m resterend';
  }

  @override
  String deadlineMinutesLeft(int minutes) {
    return '${minutes}m resterend';
  }

  @override
  String contractStartedOn(String date) {
    return 'Gestart $date';
  }

  @override
  String get amountCaps => 'BEDRAG';

  @override
  String get orderDetailsTitle => 'Orderdetails';

  @override
  String orderIdHash(String id) {
    return 'Order-ID #$id';
  }

  @override
  String get sellerColon => 'Verkoper:';

  @override
  String get clientColon => 'Klant:';

  @override
  String get labelTitle => 'Titel';

  @override
  String get labelServiceInfo => 'Service-info';

  @override
  String get labelDuration => 'Duur';

  @override
  String get labelStatus => 'Status';

  @override
  String get labelRevisions => 'Revisies';

  @override
  String get orderSummary => 'Ordersamenvatting';

  @override
  String get subtotal => 'Subtotaal';

  @override
  String get labelTotal => 'Totaal';

  @override
  String get deliveryDate => 'Leverdatum';

  @override
  String get readMoreSuffix => '..Lees meer';

  @override
  String get readLessSuffix => '..Lees minder';

  @override
  String get closeAction => 'Sluiten';

  @override
  String get contractCancelledSnack => 'Contract geannuleerd';

  @override
  String get contractKeptActive => 'Contract actief gehouden';

  @override
  String get markJobComplete => 'Job als voltooid markeren';

  @override
  String get completingEllipsis => 'Voltooien…';

  @override
  String get markJobCompleteTitle => 'Deze job als voltooid markeren?';

  @override
  String markJobCompleteDeliveredBody(String seller) {
    return 'Je bevestigt dat je het werk van $seller via hun levering hebt ontvangen. Het contract sluit als voltooid en je kunt daarna een review achterlaten.';
  }

  @override
  String markJobCompleteManualBody(String seller) {
    return 'Je staat op het punt dit contract als afgerond te sluiten. Gebruik dit wanneer je de deliverables van $seller hebt ontvangen (via chat of bestanden), ook als ze nog geen levering hebben ingediend.';
  }

  @override
  String get notYet => 'Nog niet';

  @override
  String get yesCompleteJob => 'Ja, job voltooien';

  @override
  String get jobMarkedCompleteThanks => 'Job gemarkeerd als voltooid. Bedankt!';

  @override
  String get leaveReviewTitle => 'Review achterlaten?';

  @override
  String get leaveReviewBody =>
      'Reviews helpen andere klanten en belonen goed werk.';

  @override
  String get later => 'Later';

  @override
  String couldNotCompleteJob(String message) {
    return 'Job kon niet worden voltooid: $message';
  }

  @override
  String get couldNotOpenReviewMissingSeller =>
      'Review kon niet worden geopend (verkoper ontbreekt).';

  @override
  String get sellerSubmittedDelivery => 'Verkoper heeft levering ingediend';

  @override
  String get yourDelivery => 'Jouw levering';

  @override
  String get deliveredCalloutBody =>
      'Bekijk wat ze hebben gestuurd. Als je tevreden bent, tik hieronder op Job voltooien om de order te sluiten. Chat met de verkoper via het ⋮-menu bovenaan.';

  @override
  String get openContractCalloutBody =>
      'Je freelancer moet de levering indienen voordat je dit contract kunt voltooien. Bericht de verkoper via het ⋮-menu bovenaan.';

  @override
  String cancellationRequestBannerBody(String seller) {
    return '$seller vroeg om dit contract te annuleren. Je kunt goedkeuren of het actief houden. Reageer je niet binnen 48 uur, dan blijft het contract actief.';
  }

  @override
  String get respondUsingBanner => 'Reageer via de banner hierboven.';

  @override
  String get reviewSubmittedForOrder =>
      'Je hebt een review ingediend voor deze order.';

  @override
  String errorLoadingOrder(String message) {
    return 'Fout bij laden order: $message';
  }

  @override
  String errorLoadingOrders(String message) {
    return 'Fout bij laden orders: $message';
  }

  @override
  String get onboardingNotSet => 'Niet ingesteld';

  @override
  String get onboardingAcknowledgedShort => 'Bevestigd';

  @override
  String get onboardingAwaitingAck => 'Wacht op bevestiging';

  @override
  String get theSeller => 'de verkoper';

  @override
  String get roleSeller => 'Verkoper';

  @override
  String get roleClient => 'Klant';

  @override
  String get cancellationRequestSent48h =>
      'Annuleringsverzoek verzonden. Wacht op reactie klant (48u).';

  @override
  String get cancellationRequestWithdrawn => 'Annuleringsverzoek ingetrokken';

  @override
  String get orderMarkedComplete => 'Order gemarkeerd als voltooid';

  @override
  String get withdrawingEllipsis => 'Intrekken…';

  @override
  String get requestCancel => 'Annuleren aanvragen';

  @override
  String get completeOrder => 'Order voltooien';

  @override
  String get waitingForClientApproval => 'Wacht op goedkeuring van de klant';

  @override
  String get waitingForDelivery => 'Wacht op levering';

  @override
  String get waitingForClientResponse => 'Wacht op reactie klant';

  @override
  String get sellerCancellationPendingBody =>
      'Je annuleringsverzoek is verzonden. De klant heeft tot 48 uur om goed te keuren of het contract actief te houden.';

  @override
  String get contractCancelledTitle => 'Contract geannuleerd';

  @override
  String get viewFirstDayInstructions => 'Instructies eerste dag bekijken';

  @override
  String get readFirstDayInstructions => 'Instructies eerste dag lezen';

  @override
  String get firstDayInstructionsSharedBody =>
      'Je klant deelde locatie, toegang en contacten voor deze job.';

  @override
  String get openInstructions => 'Instructies openen';

  @override
  String errorLoadingApplications(String message) {
    return 'Fout bij laden sollicitaties: $message';
  }

  @override
  String get messageClientTooltip => 'Bericht klant';

  @override
  String get openAttendance => 'Aanwezigheid openen';

  @override
  String get instructionsReadyTap => 'Instructies klaar — tik om te lezen';

  @override
  String get rateExperienceWithClient =>
      'Hoe beoordeel je je ervaring met deze klant?';

  @override
  String get postedThisContract => 'Plaatste dit contract';

  @override
  String errorLoadingJobPosts(String message) {
    return 'Fout bij laden vacatures: $message';
  }

  @override
  String get jobPostClosed => 'Vacature gesloten';

  @override
  String get addFirstDayInstructionsTitle =>
      'Instructies eerste dag toevoegen?';

  @override
  String get addFirstDayInstructionsBody =>
      'Deel kantoorlocatie, toegang en regels zodat je nieuwe hire weet wat te doen vóór dag één.';

  @override
  String get addInstructionsNow => 'Nu instructies toevoegen';

  @override
  String get sendLater => 'Later versturen';

  @override
  String get contractNotFoundForHire =>
      'Geen contract gevonden voor deze hire.';

  @override
  String get applicationRejected => 'Sollicitatie afgewezen';

  @override
  String get hireFreelancerTitle => 'Freelancer inhuren?';

  @override
  String get hireAction => 'Inhuren';

  @override
  String get closeJob => 'Vacature sluiten';

  @override
  String get attendanceSettingsUpdated =>
      'Aanwezigheidsinstellingen bijgewerkt';

  @override
  String get jobPostedSuccess => 'Vacature succesvol geplaatst!';

  @override
  String get pleaseEnterJobTitle => 'Voer een vacaturetitel in';

  @override
  String get pleaseSelectCategory => 'Selecteer een categorie';

  @override
  String get enterValidCategory => 'Voer een geldige categorie in';

  @override
  String get pleaseEnterDescription => 'Voer een beschrijving in';

  @override
  String get pleaseEnterLocation => 'Voer een locatie in';

  @override
  String get createJobStepBasics => 'Basis';

  @override
  String get createJobStepDetails => 'Details';

  @override
  String get createJobStepLocation => 'Locatie';

  @override
  String get createJobStepBudget => 'Budget';

  @override
  String get createJobPostTitle => 'Vacature plaatsen';

  @override
  String get shortJobTitleHint => 'Korte titel voor het werk';

  @override
  String get categoryNameLabel => 'Categorienaam';

  @override
  String get categoryNameHint => 'bijv. Schoonmaker, Bakker';

  @override
  String get describeJobLabel => 'Beschrijf de vacature';

  @override
  String get describeJobHint => 'Scope, planning, vaardigheden';

  @override
  String get workersNeeded => 'Benodigde werkers';

  @override
  String get limitHiresToCount => 'Beperk hires tot dit aantal';

  @override
  String get budgetMinLabel => 'Min';

  @override
  String get budgetMaxLabel => 'Max';

  @override
  String get budgetMinHint => 'Min (optioneel)';

  @override
  String get budgetMaxHint => 'Max (optioneel)';

  @override
  String get rateTypeLabel => 'Tarieftype';

  @override
  String get budgetBasisFixed => 'Vast — totaal project';

  @override
  String get budgetBasisPerHour => 'Per uur';

  @override
  String get budgetBasisPerDay => 'Per dag';

  @override
  String get budgetBasisPerMonth => 'Per maand';

  @override
  String get postingEllipsis => 'Plaatsen…';

  @override
  String get reviewAndPost => 'Controleren & plaatsen';

  @override
  String get nextStep => 'Volgende';

  @override
  String totalJobPostCount(int count) {
    return 'Totaal vacatures ($count)';
  }

  @override
  String get applicationsSection => 'Sollicitaties';

  @override
  String get rejectApplication => 'Afwijzen';

  @override
  String get freelancerDefault => 'Freelancer';

  @override
  String get submitOfferTitle => 'Sollicitatie indienen';

  @override
  String get applyAtClientRate => 'Solliciteer tegen klanttarief';

  @override
  String get agreeToClientRate => 'Akkoord met\nklanttarief';

  @override
  String get customBid => 'Eigen\nbod';

  @override
  String get offerNoPostedRateWarning =>
      'Deze vacature heeft geen gepubliceerd tarief. Voer een eigen bedrag in.';

  @override
  String get offerSentAtPostedRate =>
      'Sollicitatie verzonden tegen klanttarief';

  @override
  String get offerSentSuccess => 'Je sollicitatie is verzonden';

  @override
  String get successTitle => 'Gelukt';

  @override
  String get headsUp => 'Let op';

  @override
  String get applyWithoutCounterBody =>
      'Je solliciteert tegen het tarief van de klant. Zij zien je sollicitatie tegen dat tarief.';

  @override
  String get clientPostedRate => 'Gepubliceerd tarief klant';

  @override
  String yourApplicationAmount(String amount) {
    return 'Je sollicitatie: $amount';
  }

  @override
  String get customBidIntroWithBudget =>
      'Voer je eigen bedrag in als je anders wilt bieden dan het budget van de klant.';

  @override
  String get customBidIntroNoBudget =>
      'Deze vacature heeft geen budget — voer het bedrag in dat je vraagt.';

  @override
  String clientPostedPrefix(String amount) {
    return 'Klant plaatste: $amount';
  }

  @override
  String get yourOfferAmount => 'Jouw sollicitatiebedrag';

  @override
  String get enterYourBid => 'Voer je bod in';

  @override
  String get quoteAsLabel => 'Offreren als';

  @override
  String get quoteTotal => 'Totaal';

  @override
  String get quotePerHour => '/ uur';

  @override
  String get quotePerDay => '/ dag';

  @override
  String get quotePerMonth => '/ maand';

  @override
  String get offerMessageOptional => 'Bericht (optioneel)';

  @override
  String get offerMessageHint => 'Optionele notitie voor de klant…';

  @override
  String get findJobsTitle => 'Vacatures zoeken';

  @override
  String get couldNotLoadSkillsFilter =>
      'Vaardighedenfilter kon niet worden geladen. Trek later om te vernieuwen.';

  @override
  String get buyerRequestDetailsTitle => 'Vacaturedetails';

  @override
  String get submitOfferAction => 'Sollicitatie indienen';

  @override
  String get cannotSubmitApplication => 'Kan niet solliciteren';

  @override
  String get applicationsReceived => 'Sollicitaties';

  @override
  String offersCount(int count) {
    return '$count sollicitaties';
  }

  @override
  String get locationLabel => 'Locatie';

  @override
  String get ellipsisBusy => '…';

  @override
  String couldNotOpenChatWithDetail(String message) {
    return 'Kon chat niet openen: $message';
  }

  @override
  String get chooseFromGallery => 'Kies uit galerij';

  @override
  String get filterClear => 'Wis';

  @override
  String get filterApply => 'Toepassen';

  @override
  String get clearFilters => 'Filters wissen';

  @override
  String get deliverOrderTitle => 'Bestelling afleveren';

  @override
  String get pleaseDescribeDelivery => 'Beschrijf uw levering';

  @override
  String get orderDeliveredSuccess => 'Bestelling succesvol afgeleverd!';

  @override
  String get maxSize1Gb => 'Max. grootte 1 GB';

  @override
  String get addCustomSkill => 'Vaardigheid toevoegen';

  @override
  String skillAlreadyAdded(String skill) {
    return 'U heeft \"$skill\" al toegevoegd';
  }

  @override
  String get noWithdrawalHistory => 'Geen opnamegeschiedenis';

  @override
  String get paymentPayPal => 'PayPal';

  @override
  String get paymentCreditCard => 'Creditcard';

  @override
  String get paymentBkash => 'Bkash';

  @override
  String get bidOfferLabel => 'Bod aanbieding';

  @override
  String get counterOfferLabel => 'Tegenbod';

  @override
  String get counterOfferAction => 'Tegenbod';

  @override
  String get counterOfferTitle => 'Tegenbod sturen';

  @override
  String get counterOfferBody =>
      'Stel een ander tarief voor. Dit werkt het aanbiedingsbedrag bij voordat je inhuurt.';

  @override
  String get counterOfferAmountHint => 'Voorgesteld bedrag';

  @override
  String get counterOfferNoteHint => 'Optionele notitie voor de freelancer';

  @override
  String get counterOfferSent => 'Tegenbod verzonden';

  @override
  String get threadContextTitle => 'Gerelateerd werk';

  @override
  String get threadContextSubtitle =>
      'Actieve jobs en contracten met deze persoon';

  @override
  String threadContextRelatedCount(int count) {
    return '$count gerelateerde items';
  }

  @override
  String get threadContextLoading => 'Gerelateerd werk laden…';

  @override
  String get chatFilterApplications => 'Sollicitaties';

  @override
  String get chatFilterActive => 'Actief';

  @override
  String get chatFilterPast => 'Verleden';

  @override
  String get chatTagApplication => 'Sollicitatie';

  @override
  String get chatTagActive => 'Actief';

  @override
  String get chatTagPast => 'Verleden';

  @override
  String get noChatsInFilter => 'Geen chats in dit filter';

  @override
  String get noChatsInFilterHint =>
      'Probeer een ander filter of start een chat vanaf een profiel';

  @override
  String get proposalCaps => 'VOORSTEL';

  @override
  String get labelColon => ':';

  @override
  String get requiredFieldMark => '*';

  @override
  String get writeReviewAction => 'Beoordeling schrijven';

  @override
  String deliveryDaysCount(int count) {
    return '$count Dagen';
  }

  @override
  String get delete => 'Verwijderen';

  @override
  String get jobAlertsTitle => 'Vacaturemeldingen';

  @override
  String get jobAlertNew => 'Nieuwe melding';

  @override
  String get jobAlertEdit => 'Melding bewerken';

  @override
  String get jobAlertsEmpty =>
      'Sla regels op voor vaardigheden en afstand. We sturen een melding bij passende vacatures.';

  @override
  String get jobAlertUntitled => 'Vacaturemelding';

  @override
  String get jobAlertDeleteTitle => 'Melding verwijderen?';

  @override
  String get jobAlertDeleteMessage =>
      'Je ontvangt geen meldingen meer voor deze regel.';

  @override
  String get jobAlertMatchesAllJobs => 'Alle open vacatures';

  @override
  String get jobAlertAnyDistance => 'Elke afstand';

  @override
  String get jobAlertIncludesRemote => 'Inclusief remote';

  @override
  String jobAlertWithinKm(int km) {
    return 'Binnen $km km';
  }

  @override
  String jobAlertCategoriesCount(int count) {
    return '$count categorieën';
  }

  @override
  String get jobAlertNameLabel => 'Naam melding (optioneel)';

  @override
  String get jobAlertNameHint => 'bijv. Loodgieter in de buurt';

  @override
  String get jobAlertEnabled => 'Meldingen aan';

  @override
  String get jobAlertSkillsSection => 'Vaardigheden';

  @override
  String get jobAlertAddSkill => 'Vaardigheid toevoegen';

  @override
  String get jobAlertCategoriesSection => 'Categorieën';

  @override
  String get jobAlertAnyCategory => 'Elke categorie';

  @override
  String get jobAlertPickCategories => 'Kies categorieën';

  @override
  String get jobAlertJobTypeSection => 'Type vacature';

  @override
  String get jobAlertLocationSection => 'Jouw locatie';

  @override
  String get jobAlertLocationSet => 'Locatie opgeslagen voor afstand';

  @override
  String get jobAlertLocationMissing =>
      'Kies je locatie op de kaart voor afstandsmeldingen.';

  @override
  String get jobAlertLimitDistance => 'Alleen vacatures in de buurt';

  @override
  String get jobAlertIncludeRemote => 'Remote vacatures meenemen';

  @override
  String get jobAlertNeedProfileLocation =>
      'Kies eerst je locatie op de kaart voordat je een afstand instelt.';

  @override
  String get jobAlertSaveFromFilter => 'Opslaan als vacaturemelding';

  @override
  String get jobAlertsAppBarTooltip => 'Vacaturemeldingen';

  @override
  String get workTrustSectionTitle => 'Geverifieerd werk';

  @override
  String get workTrustSectionSubtitle =>
      'Gebaseerd op voltooide on-site contracten en aanwezigheidsregistraties op HupWorks—geen betaalde badges.';

  @override
  String get workTrustStatCompletedOnsite => 'On-site voltooid';

  @override
  String get workTrustStatVerifiedCheckins => 'Geverifieerde check-ins';

  @override
  String get workTrustStatVerifiedDays => 'Geverifieerde dagen';

  @override
  String get workTrustHighlightsTitle => 'Recent on-site werk';

  @override
  String get workTrustAttendanceVerifiedTooltip =>
      'Aanwezigheid geregistreerd voor deze vacature';

  @override
  String workTrustCompletedMonthLabel(String month, int year) {
    return '$month $year';
  }
}
