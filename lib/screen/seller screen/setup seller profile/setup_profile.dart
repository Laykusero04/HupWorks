import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_feather_icons/flutter_feather_icons.dart';
import 'package:flutter_iconly/flutter_iconly.dart';
import 'package:freelancer/core/utils/seller_skills_validation.dart';
import 'package:freelancer/data/models/seller_skill_model.dart';
import 'package:freelancer/l10n/l10n.dart';
import 'package:freelancer/l10n/l10n_labels.dart';
import 'package:freelancer/screen/widgets/button_global.dart';
import 'package:freelancer/screen/widgets/seller_skills_editor.dart';
import 'package:freelancer/services/profile_service.dart';
import 'package:image_picker/image_picker.dart';
import 'package:step_progress_indicator/step_progress_indicator.dart';

import '../../widgets/constant.dart';
import '../../widgets/profile_location_fields.dart';
import '../seller popUp/seller_popup.dart';

class SetupSellerProfile extends StatefulWidget {
  const SetupSellerProfile({Key? key}) : super(key: key);

  @override
  State<SetupSellerProfile> createState() => _SetupSellerProfileState();
}

class _SetupSellerProfileState extends State<SetupSellerProfile> {
  final PageController pageController = PageController(initialPage: 0);
  int currentIndexPage = 0;

  final _nameController = TextEditingController();
  final _phoneController = TextEditingController();
  final _jobTitleController = TextEditingController();
  final _countryController = TextEditingController();
  final _streetController = TextEditingController();
  final _cityController = TextEditingController();
  final _stateController = TextEditingController();
  final _postalController = TextEditingController();

  double? _latitude;
  double? _longitude;
  final _aboutController = TextEditingController();

  String _selectedGender = L10nLabels.genderMale;
  List<String> _languages = [];
  List<SellerSkill> _skills = [];
  bool _isSaving = false;
  File? _pickedImage;
  String? _uploadedImageUrl;

  @override
  void dispose() {
    pageController.dispose();
    _nameController.dispose();
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

  Future<void> _pickImage(ImageSource source) async {
    final picker = ImagePicker();
    final file = await picker.pickImage(source: source, imageQuality: 85);
    if (file == null || !mounted) return;
    setState(() {
      _pickedImage = File(file.path);
      _uploadedImageUrl = null;
    });
  }

  void _showImportProfilePopUp() {
    final l10n = context.l10n;
    showDialog(
      barrierDismissible: true,
      context: context,
      builder: (dialogContext) {
        return Dialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8.0)),
          child: Padding(
            padding: const EdgeInsets.all(15.0),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Text(
                      l10n.selectProfileImage,
                      style: kTextStyle.copyWith(
                        color: kNeutralColor,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const Spacer(),
                    GestureDetector(
                      onTap: () => Navigator.pop(dialogContext),
                      child: const Icon(FeatherIcons.x, color: kSubTitleColor),
                    ),
                  ],
                ),
                const SizedBox(height: 30.0),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    GestureDetector(
                      onTap: () async {
                        Navigator.pop(dialogContext);
                        await _pickImage(ImageSource.gallery);
                      },
                      child: Column(
                        children: [
                          Icon(Icons.photo_library, color: kPrimaryColor, size: 40),
                          const SizedBox(height: 10.0),
                          Text(l10n.photoGallery, style: kTextStyle.copyWith(color: kPrimaryColor)),
                        ],
                      ),
                    ),
                    GestureDetector(
                      onTap: () async {
                        Navigator.pop(dialogContext);
                        await _pickImage(ImageSource.camera);
                      },
                      child: Column(
                        children: [
                          Icon(Icons.photo_camera, color: kLightNeutralColor, size: 40),
                          const SizedBox(height: 10.0),
                          Text(l10n.takePhoto, style: kTextStyle.copyWith(color: kLightNeutralColor)),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 10.0),
              ],
            ),
          ),
        );
      },
    );
  }

  Future<void> _showAddLanguageDialog() async {
    final l10n = context.l10n;
    String? picked = language.first;
    final result = await showDialog<String>(
      context: context,
      builder: (dialogContext) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            return AlertDialog(
              title: Text(l10n.addLanguage, style: kTextStyle.copyWith(fontWeight: FontWeight.bold)),
              content: DropdownButtonFormField<String>(
                value: picked,
                items: language
                    .map((l) => DropdownMenuItem(value: l, child: Text(l)))
                    .toList(),
                onChanged: (v) => setDialogState(() => picked = v),
                decoration: const InputDecoration(border: OutlineInputBorder()),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(dialogContext),
                  child: Text(l10n.cancel),
                ),
                TextButton(
                  onPressed: () => Navigator.pop(dialogContext, picked),
                  child: Text(l10n.add),
                ),
              ],
            );
          },
        );
      },
    );
    if (result == null) return;
    if (_languages.any((l) => l.toLowerCase() == result.toLowerCase())) return;
    setState(() => _languages = [..._languages, result]);
  }

  void _saveProfilePopUp() {
    showDialog(
      barrierDismissible: false,
      context: context,
      builder: (BuildContext context) {
        return Dialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20.0)),
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

  Future<void> _handleSave() async {
    final l10n = context.l10n;
    final name = _nameController.text.trim();
    if (name.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(l10n.pleaseEnterName)),
      );
      pageController.jumpToPage(0);
      setState(() => currentIndexPage = 0);
      return;
    }

    final skillError = SellerSkillsValidation.validate(_skills);
    if (skillError != null) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(skillError)));
      pageController.jumpToPage(1);
      setState(() => currentIndexPage = 1);
      return;
    }

    setState(() => _isSaving = true);
    try {
      if (_pickedImage != null && _uploadedImageUrl == null) {
        _uploadedImageUrl = await ProfileService.uploadProfileImage(_pickedImage!);
      }

      await ProfileService.updateProfile({
        'name': name,
        'phone': _phoneController.text.trim(),
        'gender': _selectedGender,
        'country': _countryController.text.trim().isEmpty
            ? null
            : _countryController.text.trim(),
        'city': _cityController.text.trim().isEmpty ? null : _cityController.text.trim(),
        if (_latitude != null) 'latitude': _latitude,
        if (_longitude != null) 'longitude': _longitude,
      });

      await ProfileService.updateSellerProfile(
        jobTitle: _jobTitleController.text.trim(),
        about: _aboutController.text.trim(),
        skills: _skills,
        address: _publicAddress(),
        languages: _languages,
        streetAddress: _streetController.text.trim(),
        state: _stateController.text.trim(),
        postalCode: _postalController.text.trim(),
        clearPublicCountryCity: false,
      );

      if (!mounted) return;
      _saveProfilePopUp();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(l10n.errorWithDetail(e.toString()))),
        );
      }
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  void _onContinue() {
    if (currentIndexPage < 2) {
      pageController.nextPage(
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
      );
      return;
    }
    _handleSave();
  }

  ImageProvider get _avatarImage {
    if (_pickedImage != null) return FileImage(_pickedImage!);
    if (_uploadedImageUrl != null) return NetworkImage(_uploadedImageUrl!);
    return const AssetImage('images/profile3.png');
  }

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
          l10n.setupProfile,
          style: kTextStyle.copyWith(color: kNeutralColor, fontWeight: FontWeight.bold),
        ),
      ),
      body: PageView(
        physics: const NeverScrollableScrollPhysics(),
        controller: pageController,
        onPageChanged: (int index) => setState(() => currentIndexPage = index),
        children: [
          _stepScaffold(child: _buildStepBasics(l10n)),
          _stepScaffold(child: _buildStepSkills(l10n)),
          _stepScaffold(child: _buildStepAbout(l10n)),
        ],
      ),
      bottomNavigationBar: ButtonGlobalWithoutIcon(
        buttontext: _isSaving
            ? l10n.saving
            : currentIndexPage < 2
                ? l10n.continueLabel
                : l10n.saveProfile,
        buttonDecoration: kButtonDecoration.copyWith(
          color: _isSaving ? kLightNeutralColor : kPrimaryColor,
          borderRadius: BorderRadius.circular(30.0),
        ),
        onPressed: _isSaving ? null : _onContinue,
        buttonTextColor: kWhite,
      ),
    );
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
                  l10n.stepOf(currentIndexPage + 1, 3),
                  style: kTextStyle.copyWith(color: kNeutralColor),
                ),
                const SizedBox(width: 10.0),
                Expanded(
                  child: StepProgressIndicator(
                    totalSteps: 3,
                    currentStep: currentIndexPage + 1,
                    size: 8,
                    padding: 0,
                    selectedColor: kPrimaryColor,
                    unselectedColor: kPrimaryColor.withOpacity(0.2),
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

  Widget _buildStepBasics(AppLocalizations l10n) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          l10n.uploadYourPhoto,
          style: kTextStyle.copyWith(color: kNeutralColor, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 10.0),
        Center(
          child: Stack(
            alignment: Alignment.bottomRight,
            children: [
              Container(
                height: 120,
                width: 120,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(color: kPrimaryColor),
                  image: (_pickedImage != null || _uploadedImageUrl != null)
                      ? DecorationImage(image: _avatarImage, fit: BoxFit.cover)
                      : null,
                ),
                child: _pickedImage == null && _uploadedImageUrl == null
                    ? const Icon(IconlyBold.profile, color: kBorderColorTextField, size: 68)
                    : null,
              ),
              GestureDetector(
                onTap: _showImportProfilePopUp,
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
        const SizedBox(height: 30.0),
        _field(_nameController, l10n.userName, l10n.userName),
        const SizedBox(height: 20.0),
        _field(_jobTitleController, l10n.jobTitle, l10n.jobTitle),
        const SizedBox(height: 20.0),
        _field(_phoneController, l10n.phone, l10n.phone, type: TextInputType.phone),
        const SizedBox(height: 20.0),
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
        const SizedBox(height: 20.0),
        FormField(
          builder: (FormFieldState<dynamic> field) {
            return InputDecorator(
              decoration: kInputDecoration.copyWith(
                enabledBorder: const OutlineInputBorder(
                  borderRadius: BorderRadius.all(Radius.circular(8.0)),
                  borderSide: BorderSide(color: kBorderColorTextField, width: 2),
                ),
                contentPadding: const EdgeInsets.all(7.0),
                floatingLabelBehavior: FloatingLabelBehavior.always,
                labelText: l10n.selectGender,
                labelStyle: kTextStyle.copyWith(color: kNeutralColor, fontWeight: FontWeight.bold),
              ),
              child: DropdownButtonHideUnderline(child: _genderDropdown(l10n)),
            );
          },
        ),
      ],
    );
  }

  Widget _buildStepSkills(AppLocalizations l10n) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        GestureDetector(
          onTap: _showAddLanguageDialog,
          child: Row(
            children: [
              Text(
                l10n.language,
                style: kTextStyle.copyWith(color: kNeutralColor, fontWeight: FontWeight.bold),
              ),
              const Spacer(),
              const Icon(FeatherIcons.plusCircle, color: kSubTitleColor, size: 18.0),
              const SizedBox(width: 5.0),
              Text(l10n.addNew, style: kTextStyle.copyWith(color: kSubTitleColor)),
            ],
          ),
        ),
        const SizedBox(height: 12.0),
        if (_languages.isEmpty)
          Text(
            l10n.noLanguagesYet,
            style: kTextStyle.copyWith(color: kLightNeutralColor),
          )
        else
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: _languages
                .map(
                  (lang) => Chip(
                    label: Text(lang),
                    onDeleted: () {
                      setState(() => _languages = _languages.where((l) => l != lang).toList());
                    },
                  ),
                )
                .toList(),
          ),
        const SizedBox(height: 28.0),
        Text(
          l10n.skills,
          style: kTextStyle.copyWith(color: kNeutralColor, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 12.0),
        SellerSkillsEditor(
          skills: _skills,
          onChanged: (skills) => setState(() => _skills = skills),
        ),
      ],
    );
  }

  Widget _buildStepAbout(AppLocalizations l10n) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          l10n.aboutYou,
          style: kTextStyle.copyWith(color: kNeutralColor, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 15.0),
        TextFormField(
          controller: _aboutController,
          keyboardType: TextInputType.multiline,
          maxLines: 8,
          cursorColor: kNeutralColor,
          textInputAction: TextInputAction.newline,
          decoration: kInputDecoration.copyWith(
            hintText: l10n.aboutYouHint,
            hintStyle: kTextStyle.copyWith(color: kLightNeutralColor),
            focusColor: kNeutralColor,
            border: const OutlineInputBorder(),
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
