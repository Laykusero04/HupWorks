import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_feather_icons/flutter_feather_icons.dart';
import 'package:flutter_iconly/flutter_iconly.dart';
import 'package:freelancer/core/guide/guide_anchor.dart';
import 'package:freelancer/core/guide/guide_host.dart';
import 'package:freelancer/core/guide/guide_info_button.dart';
import 'package:freelancer/core/guide/guide_service.dart';
import 'package:freelancer/core/guide/guide_step.dart';
import 'package:freelancer/core/utils/profile_avatar_picker.dart';
import 'package:freelancer/core/utils/seller_skills_validation.dart';
import 'package:freelancer/data/models/seller_skill_model.dart';
import 'package:freelancer/l10n/l10n.dart';
import 'package:freelancer/l10n/l10n_labels.dart';
import 'package:freelancer/screen/widgets/button_global.dart';
import 'package:freelancer/screen/widgets/seller_skills_editor.dart';
import 'package:freelancer/services/auth_service.dart';
import 'package:freelancer/services/profile_service.dart';
import 'package:freelancer/services/verification_service.dart';
import 'package:go_router/go_router.dart';
import 'package:step_progress_indicator/step_progress_indicator.dart';

import '../../widgets/constant.dart';
import '../../widgets/profile_location_fields.dart';
import '../seller popUp/seller_popup.dart';

class SetupSellerProfile extends StatefulWidget {
  const SetupSellerProfile({Key? key}) : super(key: key);

  @override
  State<SetupSellerProfile> createState() => _SetupSellerProfileState();
}

class _SetupSellerProfileState extends State<SetupSellerProfile>
    with GuideHost<SetupSellerProfile> {
  static const _totalSteps = 4;

  // Each wizard page is its own guide (own id, own seen flag). One host serves
  // all four: [guideScreenId] follows the current page, so targets in the
  // shared app bar / bottom bar use the same scope. Keys are unique per page.
  static const _pageGuideIds = [
    'seller_setup',
    'seller_setup_details',
    'seller_setup_photo',
    'seller_setup_id',
  ];
  final GlobalKey _gReqKey = GlobalKey();
  final GlobalKey _gContinueKey = GlobalKey();
  final GlobalKey _gLogoutKey = GlobalKey();
  final GlobalKey _gWhereKey = GlobalKey();
  final GlobalKey _gSkillsKey = GlobalKey();
  final GlobalKey _gAboutKey = GlobalKey();
  final GlobalKey _gBestKey = GlobalKey();
  final GlobalKey _gLearningKey = GlobalKey();
  final GlobalKey _gAddSkillKey = GlobalKey();
  final GlobalKey _gPhotoKey = GlobalKey();
  final GlobalKey _gPickKey = GlobalKey();
  final GlobalKey _gWhyKey = GlobalKey();
  final GlobalKey _gSelfieKey = GlobalKey();
  final GlobalKey _gSaveKey = GlobalKey();

  @override
  String get guideScreenId => _pageGuideIds[currentIndexPage];
  @override
  String get guideRole => 'seller';
  @override
  int get guideVersion => 1;

  /// Never part of the Home chain: ready as soon as the wizard is on screen
  /// (after the push animation).
  @override
  bool get guideDataReady => _routeSettled && !_isSaving;

  /// True once the route's push animation finished (targets are in place).
  bool _routeSettled = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _awaitRouteSettled());
  }

  void _awaitRouteSettled() {
    if (!mounted) return;
    final anim = ModalRoute.of(context)?.animation;
    if (anim == null || anim.isCompleted) {
      _settleRoute();
      return;
    }
    void listener(AnimationStatus st) {
      if (st == AnimationStatus.completed) {
        anim.removeStatusListener(listener);
        _settleRoute();
      }
    }

    anim.addStatusListener(listener);
  }

  void _settleRoute() {
    if (!mounted) return;
    setState(() => _routeSettled = true);
    scheduleGuide();
  }
  @override
  String get guideSkipLabel => context.l10n.guideSkip;
  @override
  String get guideNextLabel => context.l10n.guideNext;
  @override
  String get guideDoneLabel => context.l10n.guideDone;

  GuideAnchor _anchor(GlobalKey key, String title, String desc) => GuideAnchor(
        key: key,
        scope: guideScope,
        title: title,
        description: desc,
      );

  GuideStep _step(GlobalKey key, String title, String desc,
          {bool scroll = false, bool bottom = false}) =>
      GuideStep(
          key: key,
          title: title,
          description: desc,
          enableAutoScroll: scroll,
          targetNearBottom: bottom);

  // Page 0: 3, page 1: 3, page 2: 2, page 3: 3 steps (+3 in the skills
  // section). Keys of other pages are not built, so they are never rendered.
  @override
  List<GuideStep> buildGuideSteps(BuildContext context) {
    final l10n = context.l10n;
    switch (currentIndexPage) {
      case 0:
        return [
          _step(_gReqKey, l10n.guideSetupReqTitle, l10n.guideSetupReqDesc),
          _step(_gContinueKey, l10n.guideSetupContinueTitle,
              l10n.guideSetupContinueDesc,
              bottom: true),
          _step(_gLogoutKey, l10n.guideSetupLogoutTitle,
              l10n.guideSetupLogoutDesc),
        ];
      case 1:
        return [
          _step(_gWhereKey, l10n.guideSetupWhereTitle, l10n.guideSetupWhereDesc,
              scroll: true),
          _step(_gSkillsKey, l10n.guideSetupSkillsTitle,
              l10n.guideSetupSkillsDesc,
              scroll: true),
          _step(_gAboutKey, l10n.guideSetupAboutTitle, l10n.guideSetupAboutDesc,
              scroll: true),
        ];
      case 2:
        return [
          _step(
              _gPhotoKey, l10n.guideSetupPhotoTitle, l10n.guideSetupPhotoDesc),
          _step(_gPickKey, l10n.guideSetupPickTitle, l10n.guideSetupPickDesc),
        ];
      default:
        return [
          _step(_gWhyKey, l10n.guideSetupWhyTitle, l10n.guideSetupWhyDesc),
          _step(_gSelfieKey, l10n.guideSetupSelfieTitle,
              l10n.guideSetupSelfieDesc),
          _step(_gSaveKey, l10n.guideSetupSaveTitle, l10n.guideSetupSaveDesc,
              bottom: true),
        ];
    }
  }

  /// Only page 1 has an extra section ("Your skills"); the (i) on the other
  /// pages replays that page's tip directly.
  @override
  List<GuideSection> buildGuideExtraSections(BuildContext context) {
    if (currentIndexPage != 1) return const [];
    final l10n = context.l10n;
    return [
      GuideSection(
        id: 'skills',
        title: l10n.guideSetupSectionSkills,
        steps: [
          _step(_gBestKey, l10n.guideSetupBestTitle, l10n.guideSetupBestDesc,
              scroll: true),
          _step(_gLearningKey, l10n.guideSetupLearningTitle,
              l10n.guideSetupLearningDesc,
              scroll: true),
          _step(_gAddSkillKey, l10n.guideSetupAddTitle, l10n.guideSetupAddDesc,
              scroll: true),
        ],
      ),
    ];
  }

  /// Page 0 is started by the host itself. Later pages: once per page, after
  /// the page animation, unless that page's tip was already seen. Skip or the
  /// overlay never block Continue: the guide is only an overlay.
  Future<void> _autoGuideForPage(int page) async {
    await Future<void>.delayed(const Duration(milliseconds: 400));
    if (!mounted || currentIndexPage != page || !guideEnabled) return;
    final uid = guideUid;
    if (uid == null) return;
    try {
      final seen = await GuideService.hasSeen(
        uid: uid,
        role: guideRole,
        screenId: _pageGuideIds[page],
        version: guideVersion,
      );
      if (seen || !mounted || currentIndexPage != page) return;
      replayGuide();
    } catch (e) {
      debugPrint('Setup page guide check failed: $e');
    }
  }

  final PageController pageController = PageController(initialPage: 0);
  int currentIndexPage = 0;

  final _phoneController = TextEditingController();
  final _jobTitleController = TextEditingController();
  final _countryController = TextEditingController();
  final _streetController = TextEditingController();
  final _cityController = TextEditingController();
  final _stateController = TextEditingController();
  final _postalController = TextEditingController();
  final _aboutController = TextEditingController();

  double? _latitude;
  double? _longitude;
  DateTime? _dateOfBirth;

  String _selectedGender = L10nLabels.genderMale;
  List<String> _languages = [];
  List<SellerSkill> _skills = [];
  bool _isSaving = false;

  File? _pickedImage;
  String? _uploadedImageUrl;
  File? _idSelfie;

  @override
  void dispose() {
    pageController.dispose();
    _phoneController.dispose();
    _jobTitleController.dispose();
    _countryController.dispose();
    _streetController.dispose();
    _cityController.dispose();
    _stateController.dispose();
    _postalController.dispose();
    _aboutController.dispose();
    super.dispose();
  }

  Future<void> _pickProfilePhoto() async {
    final file = await ProfileAvatarPicker.pickAndCrop(context);
    if (file == null || !mounted) return;
    setState(() {
      _pickedImage = file;
      _uploadedImageUrl = null;
    });
  }

  Future<void> _pickIdSelfie() async {
    final file = await ProfileAvatarPicker.pickImage(context);
    if (file == null || !mounted) return;
    setState(() => _idSelfie = file);
  }

  Future<void> _pickDateOfBirth() async {
    final now = DateTime.now();
    final initial = _dateOfBirth ?? DateTime(now.year - 25);
    final picked = await showDatePicker(
      context: context,
      initialDate: initial,
      firstDate: DateTime(1920),
      lastDate: now,
    );
    if (picked != null && mounted) {
      setState(() => _dateOfBirth = picked);
    }
  }

  String _dobLabel(AppLocalizations l10n) {
    if (_dateOfBirth == null) return l10n.tapSetBirthDateRequired;
    final age =
        ProfileService.ageFromDateOfBirth(_dateOfBirth!.toIso8601String());
    if (age != null) return l10n.ageBirthDateStaysPrivate(age);
    return l10n.birthDateSaved;
  }

  void _showAddLanguageDialog() {
    final controller = TextEditingController();
    showDialog<void>(
      context: context,
      builder: (ctx) {
        return AlertDialog(
          title: Text(context.l10n.addLanguage),
          content: TextField(
            controller: controller,
            autofocus: true,
            decoration: InputDecoration(hintText: context.l10n.language),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: Text(context.l10n.cancel),
            ),
            TextButton(
              onPressed: () {
                final result = controller.text.trim();
                Navigator.pop(ctx);
                if (result.isEmpty) return;
                if (_languages
                    .any((l) => l.toLowerCase() == result.toLowerCase())) {
                  return;
                }
                setState(() => _languages = [..._languages, result]);
              },
              child: Text(context.l10n.addNew),
            ),
          ],
        );
      },
    );
  }

  Future<void> _saveProfilePopUp() async {
    await showDialog<void>(
      barrierDismissible: false,
      context: context,
      builder: (BuildContext context) {
        return Dialog(
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(20.0)),
          child: const SaveProfilePopUp(),
        );
      },
    );
  }

  String _publicAddress() {
    final parts = [
      _streetController.text.trim(),
      _cityController.text.trim(),
      _stateController.text.trim(),
      _postalController.text.trim(),
      _countryController.text.trim(),
    ].where((p) => p.isNotEmpty).toList();
    return parts.join(', ');
  }

  void _snack(String msg) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg)));
  }

  bool _validateStep0() {
    final l10n = context.l10n;
    if (_jobTitleController.text.trim().isEmpty) {
      _snack(l10n.pleaseEnterJobTitle);
      return false;
    }
    if (_dateOfBirth == null) {
      _snack(l10n.pleaseSetDateOfBirth);
      return false;
    }
    final age =
        ProfileService.ageFromDateOfBirth(_dateOfBirth!.toIso8601String());
    if (age == null || age < 18) {
      _snack(l10n.mustBeAtLeast18);
      return false;
    }
    return true;
  }

  bool _validateStep1() {
    final skillError = SellerSkillsValidation.validate(_skills, context.l10n);
    if (skillError != null) {
      _snack(skillError);
      return false;
    }
    return true;
  }

  bool _validateStep2() {
    if (_pickedImage == null && _uploadedImageUrl == null) {
      _snack(context.l10n.pleaseUploadClearProfilePhoto);
      return false;
    }
    return true;
  }

  bool _validateStep3() {
    if (_idSelfie == null) {
      _snack(context.l10n.pleaseUploadIdSelfie);
      return false;
    }
    return true;
  }

  Future<void> _handleFinish() async {
    if (!_validateStep3()) return;

    setState(() => _isSaving = true);
    final l10n = context.l10n;
    try {
      if (_pickedImage != null && _uploadedImageUrl == null) {
        _uploadedImageUrl =
            await ProfileService.uploadProfileImage(_pickedImage!);
      }

      await ProfileService.updateProfile({
        'phone': _phoneController.text.trim(),
        'gender': _selectedGender,
        'country': _countryController.text.trim().isEmpty
            ? null
            : _countryController.text.trim(),
        'city': _cityController.text.trim().isEmpty
            ? null
            : _cityController.text.trim(),
        if (_latitude != null) 'latitude': _latitude,
        if (_longitude != null) 'longitude': _longitude,
      });

      await ProfileService.updateSellerProfile(
        jobTitle: _jobTitleController.text.trim(),
        about: _aboutController.text.trim(),
        skills: _skills,
        dateOfBirth: _dateOfBirth,
        address: _publicAddress(),
        languages: _languages,
        streetAddress: _streetController.text.trim(),
        state: _stateController.text.trim(),
        postalCode: _postalController.text.trim(),
        clearPublicCountryCity: false,
      );

      await VerificationService.submitIdSelfie(_idSelfie!);
      await AuthService.completeSellerOnboarding();

      if (!mounted) return;
      await _saveProfilePopUp();
    } catch (e) {
      if (mounted) {
        _snack(l10n.errorWithDetail(e.toString()));
      }
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  void _onContinue() {
    if (currentIndexPage == 0 && !_validateStep0()) return;
    if (currentIndexPage == 1 && !_validateStep1()) return;
    if (currentIndexPage == 2 && !_validateStep2()) return;

    if (currentIndexPage < _totalSteps - 1) {
      pageController.nextPage(
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
      );
      return;
    }
    _handleFinish();
  }

  Future<void> _backToLogin() async {
    final l10n = context.l10n;
    final leave = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(l10n.leaveSetupTitle),
        content: Text(l10n.leaveSetupMessage),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: Text(l10n.cancel),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: Text(l10n.logOut),
          ),
        ],
      ),
    );
    if (leave != true || !mounted) return;

    await AuthService.signOut();
    if (!mounted) return;
    context.go('/auth/seller/login');
  }

  void _goPreviousStep() {
    if (currentIndexPage <= 0 || _isSaving) return;
    pageController.previousPage(
      duration: const Duration(milliseconds: 300),
      curve: Curves.easeInOut,
    );
  }

  DropdownButton<String> _genderDropdown(AppLocalizations l10n) {
    return DropdownButton<String>(
      icon: const Icon(FeatherIcons.chevronDown),
      items: L10nLabels.genderValues
          .map(
            (des) => DropdownMenuItem(
              value: des,
              child: Text(L10nLabels.gender(l10n, des)),
            ),
          )
          .toList(),
      value: _selectedGender,
      style: kTextStyle.copyWith(color: kSubTitleColor),
      onChanged: (value) {
        if (value == null) return;
        setState(() => _selectedGender = value);
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    return guideBackScope(Scaffold(
      backgroundColor: kWhite,
      appBar: AppBar(
        elevation: 0,
        automaticallyImplyLeading: false,
        leading: currentIndexPage > 0
            ? IconButton(
                icon: const Icon(Icons.arrow_back_ios_new, size: 20),
                onPressed: _isSaving ? null : _goPreviousStep,
              )
            : null,
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
          l10n.setupProfile,
          style: kTextStyle.copyWith(
              color: kNeutralColor, fontWeight: FontWeight.bold),
        ),
        actions: [
          GuideInfoButton(host: this),
          GuideAnchor.wrap(
            currentIndexPage == 0
                ? _anchor(_gLogoutKey, l10n.guideSetupLogoutTitle,
                    l10n.guideSetupLogoutDesc)
                : null,
            TextButton(
              onPressed: _isSaving ? null : _backToLogin,
              child: Text(
                l10n.logOut,
                style: kTextStyle.copyWith(
                  color: kSecondaryColor,
                  fontWeight: FontWeight.w600,
                  fontSize: 13,
                ),
              ),
            ),
          ),
        ],
      ),
      body: PageView(
        physics: const NeverScrollableScrollPhysics(),
        controller: pageController,
        onPageChanged: (int index) {
          setState(() => currentIndexPage = index);
          _autoGuideForPage(index);
        },
        children: [
          _stepScaffold(child: _buildStepRequired(l10n)),
          _stepScaffold(child: _buildStepOptional(l10n)),
          _stepScaffold(child: _buildStepProfilePhoto(l10n)),
          _stepScaffold(child: _buildStepIdVerification(l10n)),
        ],
      ),
      bottomNavigationBar: ButtonGlobalWithoutIcon(
        guideAnchor: switch (currentIndexPage) {
          0 => _anchor(_gContinueKey, l10n.guideSetupContinueTitle,
              l10n.guideSetupContinueDesc),
          3 => _anchor(
              _gSaveKey, l10n.guideSetupSaveTitle, l10n.guideSetupSaveDesc),
          _ => null,
        },
        buttontext: _isSaving
            ? l10n.saving
            : currentIndexPage < _totalSteps - 1
                ? l10n.continueLabel
                : l10n.saveProfile,
        buttonDecoration: kButtonDecoration.copyWith(
          color: _isSaving ? kLightNeutralColor : kPrimaryColor,
          borderRadius: BorderRadius.circular(30.0),
        ),
        onPressed: _isSaving ? null : _onContinue,
        buttonTextColor: kWhite,
      ),
    ));
  }

  Widget _stepScaffold({required Widget child}) {
    final l10n = context.l10n;
    return Padding(
      padding: const EdgeInsets.all(20.0),
      child: SingleChildScrollView(
        physics: const BouncingScrollPhysics(),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  l10n.stepOf(currentIndexPage + 1, _totalSteps),
                  style: kTextStyle.copyWith(color: kNeutralColor),
                ),
                const SizedBox(width: 10.0),
                Expanded(
                  child: StepProgressIndicator(
                    totalSteps: _totalSteps,
                    currentStep: currentIndexPage + 1,
                    size: 8,
                    padding: 0,
                    selectedColor: kPrimaryColor,
                    unselectedColor: kPrimaryColor.withValues(alpha: 0.2),
                    roundedEdges: const Radius.circular(10),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20.0),
            child,
          ],
        ),
      ),
    );
  }

  Widget _buildStepRequired(AppLocalizations l10n) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          l10n.requiredDetails,
          style: kTextStyle.copyWith(
              color: kNeutralColor, fontWeight: FontWeight.bold, fontSize: 16),
        ),
        const SizedBox(height: 6),
        Text(
          l10n.requiredDetailsHint,
          style: kTextStyle.copyWith(color: kSubTitleColor, fontSize: 13),
        ),
        const SizedBox(height: 20),
        GuideAnchor.wrap(
          _anchor(_gReqKey, l10n.guideSetupReqTitle, l10n.guideSetupReqDesc),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _field(_jobTitleController, l10n.jobTitle, l10n.jobTitle),
              const SizedBox(height: 20.0),
              Text(
                l10n.ageDateOfBirth,
                style: kTextStyle.copyWith(
                    color: kNeutralColor, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 4),
              Text(
                l10n.ageShownBirthPrivate,
                style: kTextStyle.copyWith(
                    color: kLightNeutralColor, fontSize: 12),
              ),
              const SizedBox(height: 8),
              InkWell(
                onTap: _pickDateOfBirth,
                borderRadius: BorderRadius.circular(8),
                child: InputDecorator(
                  decoration: kInputDecoration.copyWith(
                    border: const OutlineInputBorder(),
                    labelText: l10n.dateOfBirth,
                  ),
                  child: Text(
                    _dobLabel(l10n),
                    style: kTextStyle.copyWith(
                      color:
                          _dateOfBirth == null ? kSubTitleColor : kNeutralColor,
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 20.0),
              _field(_phoneController, l10n.phone, l10n.phone,
                  type: TextInputType.phone),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildStepOptional(AppLocalizations l10n) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          l10n.optionalDetails,
          style: kTextStyle.copyWith(
              color: kNeutralColor, fontWeight: FontWeight.bold, fontSize: 16),
        ),
        const SizedBox(height: 6),
        Text(
          l10n.optionalDetailsHint,
          style: kTextStyle.copyWith(color: kSubTitleColor, fontSize: 13),
        ),
        const SizedBox(height: 20),
        FormField(
          builder: (FormFieldState<dynamic> field) {
            return InputDecorator(
              decoration: kInputDecoration.copyWith(
                enabledBorder: const OutlineInputBorder(
                  borderRadius: BorderRadius.all(Radius.circular(8.0)),
                  borderSide:
                      BorderSide(color: kBorderColorTextField, width: 2),
                ),
                contentPadding: const EdgeInsets.all(7.0),
                floatingLabelBehavior: FloatingLabelBehavior.always,
                labelText: l10n.selectGender,
                labelStyle: kTextStyle.copyWith(
                    color: kNeutralColor, fontWeight: FontWeight.bold),
              ),
              child: DropdownButtonHideUnderline(child: _genderDropdown(l10n)),
            );
          },
        ),
        const SizedBox(height: 20.0),
        GuideAnchor.wrap(
          _anchor(
              _gWhereKey, l10n.guideSetupWhereTitle, l10n.guideSetupWhereDesc),
          ProfileLocationFields(
            countryController: _countryController,
            cityController: _cityController,
            accentColor: kPrimaryColor,
            initialLatitude: _latitude,
            initialLongitude: _longitude,
            onCoordinatesChanged: (lat, lng) {
              setState(() {
                _latitude = lat;
                _longitude = lng;
              });
            },
          ),
        ),
        const SizedBox(height: 20.0),
        _field(
          _streetController,
          l10n.streetAddress,
          l10n.streetAddress,
          type: TextInputType.streetAddress,
        ),
        const SizedBox(height: 20.0),
        _field(_stateController, l10n.state, l10n.state),
        const SizedBox(height: 20.0),
        _field(_postalController, l10n.zipCode, l10n.zipCode),
        const SizedBox(height: 28.0),
        GestureDetector(
          onTap: _showAddLanguageDialog,
          child: Row(
            children: [
              Text(
                l10n.language,
                style: kTextStyle.copyWith(
                    color: kNeutralColor, fontWeight: FontWeight.bold),
              ),
              const Spacer(),
              const Icon(FeatherIcons.plusCircle,
                  color: kSubTitleColor, size: 18.0),
              const SizedBox(width: 5.0),
              Text(l10n.addNew,
                  style: kTextStyle.copyWith(color: kSubTitleColor)),
            ],
          ),
        ),
        const SizedBox(height: 12.0),
        if (_languages.isEmpty)
          Text(l10n.noLanguagesYet,
              style: kTextStyle.copyWith(color: kLightNeutralColor))
        else
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: _languages
                .map(
                  (lang) => Chip(
                    label: Text(lang),
                    onDeleted: () {
                      setState(() => _languages =
                          _languages.where((l) => l != lang).toList());
                    },
                  ),
                )
                .toList(),
          ),
        const SizedBox(height: 28.0),
        GuideAnchor.wrap(
          _anchor(_gSkillsKey, l10n.guideSetupSkillsTitle,
              l10n.guideSetupSkillsDesc),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                l10n.skills,
                style: kTextStyle.copyWith(
                    color: kNeutralColor, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 12.0),
              SellerSkillsEditor(
                skills: _skills,
                onChanged: (skills) => setState(() => _skills = skills),
                tierAnchor: _anchor(_gBestKey, l10n.guideSetupBestTitle,
                    l10n.guideSetupBestDesc),
                lowTierAnchor: _anchor(_gLearningKey,
                    l10n.guideSetupLearningTitle, l10n.guideSetupLearningDesc),
                addAnchor: _anchor(_gAddSkillKey, l10n.guideSetupAddTitle,
                    l10n.guideSetupAddDesc),
              ),
            ],
          ),
        ),
        const SizedBox(height: 28.0),
        Text(
          l10n.aboutYou,
          style: kTextStyle.copyWith(
              color: kNeutralColor, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 12.0),
        GuideAnchor.wrap(
          _anchor(
              _gAboutKey, l10n.guideSetupAboutTitle, l10n.guideSetupAboutDesc),
          TextFormField(
            controller: _aboutController,
            keyboardType: TextInputType.multiline,
            maxLines: 6,
            cursorColor: kNeutralColor,
            textInputAction: TextInputAction.newline,
            decoration: kInputDecoration.copyWith(
              hintText: l10n.aboutYouHint,
              hintStyle: kTextStyle.copyWith(color: kLightNeutralColor),
              focusColor: kNeutralColor,
              border: const OutlineInputBorder(),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildStepProfilePhoto(AppLocalizations l10n) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          l10n.uploadYourPhoto,
          style: kTextStyle.copyWith(
              color: kNeutralColor, fontWeight: FontWeight.bold, fontSize: 16),
        ),
        const SizedBox(height: 6),
        Text(
          l10n.profilePhotoGuidelineHint,
          style: kTextStyle.copyWith(color: kSubTitleColor, fontSize: 13),
        ),
        const SizedBox(height: 24),
        Center(
          child: GuideAnchor.wrap(
            _anchor(_gPhotoKey, l10n.guideSetupPhotoTitle,
                l10n.guideSetupPhotoDesc),
            Stack(
              alignment: Alignment.bottomRight,
              children: [
                Container(
                  height: 120,
                  width: 120,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    border: Border.all(color: kPrimaryColor),
                    image: (_pickedImage != null || _uploadedImageUrl != null)
                        ? DecorationImage(
                            image: _pickedImage != null
                                ? FileImage(_pickedImage!)
                                : NetworkImage(_uploadedImageUrl!)
                                    as ImageProvider,
                            fit: BoxFit.cover,
                          )
                        : null,
                  ),
                  child: _pickedImage == null && _uploadedImageUrl == null
                      ? const Icon(IconlyBold.profile,
                          color: kBorderColorTextField, size: 68)
                      : null,
                ),
                GestureDetector(
                  onTap: _pickProfilePhoto,
                  child: Container(
                    padding: const EdgeInsets.all(5),
                    decoration: BoxDecoration(
                      color: kWhite,
                      shape: BoxShape.circle,
                      border: Border.all(color: kPrimaryColor),
                    ),
                    child: const Icon(IconlyBold.camera, color: kPrimaryColor),
                  ),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 12),
        Center(
          child: GuideAnchor.wrap(
            _anchor(
                _gPickKey, l10n.guideSetupPickTitle, l10n.guideSetupPickDesc),
            TextButton.icon(
              onPressed: _pickProfilePhoto,
              icon: const Icon(Icons.add_a_photo_outlined),
              label: Text(l10n.selectProfileImage),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildStepIdVerification(AppLocalizations l10n) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          l10n.identityVerification,
          style: kTextStyle.copyWith(
              color: kNeutralColor, fontWeight: FontWeight.bold, fontSize: 16),
        ),
        const SizedBox(height: 6),
        GuideAnchor.wrap(
          _anchor(_gWhyKey, l10n.guideSetupWhyTitle, l10n.guideSetupWhyDesc),
          Text(
            l10n.identityVerificationSetupHint,
            style: kTextStyle.copyWith(color: kSubTitleColor, fontSize: 13),
          ),
        ),
        const SizedBox(height: 24),
        GuideAnchor.wrap(
          _anchor(_gSelfieKey, l10n.guideSetupSelfieTitle,
              l10n.guideSetupSelfieDesc),
          GestureDetector(
            onTap: _pickIdSelfie,
            child: Container(
              height: 200,
              width: double.infinity,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: kBorderColorTextField, width: 2),
                color: kDarkWhite,
                image: _idSelfie != null
                    ? DecorationImage(
                        image: FileImage(_idSelfie!), fit: BoxFit.cover)
                    : null,
              ),
              child: _idSelfie == null
                  ? Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(Icons.badge_outlined,
                            size: 42, color: kPrimaryColor),
                        const SizedBox(height: 8),
                        Text(
                          l10n.uploadIdFaceSelfie,
                          style: kTextStyle.copyWith(
                              color: kPrimaryColor,
                              fontWeight: FontWeight.w600),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          '${l10n.photoGallery} / ${l10n.takePhoto}',
                          style: kTextStyle.copyWith(
                              color: kSubTitleColor, fontSize: 12),
                        ),
                      ],
                    )
                  : Align(
                      alignment: Alignment.bottomRight,
                      child: Padding(
                        padding: const EdgeInsets.all(8),
                        child: FloatingActionButton.small(
                          heroTag: 'retake_id',
                          onPressed: _pickIdSelfie,
                          backgroundColor: kWhite,
                          child:
                              const Icon(Icons.refresh, color: kPrimaryColor),
                        ),
                      ),
                    ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _field(
    TextEditingController controller,
    String label,
    String hint, {
    TextInputType type = TextInputType.name,
  }) {
    return TextFormField(
      controller: controller,
      keyboardType: type,
      cursorColor: kNeutralColor,
      textInputAction: TextInputAction.next,
      decoration: kInputDecoration.copyWith(
        labelText: label,
        labelStyle: kTextStyle.copyWith(color: kNeutralColor),
        hintText: hint,
        hintStyle: kTextStyle.copyWith(color: kSubTitleColor),
        focusColor: kNeutralColor,
        border: const OutlineInputBorder(),
      ),
    );
  }
}
