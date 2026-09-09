import 'package:flutter/material.dart';
import 'package:flutter_feather_icons/flutter_feather_icons.dart';
import 'package:freelancer/core/utils/profile_avatar_picker.dart';
import 'package:freelancer/core/utils/profile_image.dart';
import 'package:freelancer/core/utils/seller_skills_validation.dart';
import 'package:freelancer/data/models/seller_skill_model.dart';
import 'package:freelancer/l10n/l10n.dart';
import 'package:freelancer/l10n/l10n_labels.dart';
import 'package:freelancer/screen/widgets/button_global.dart';
import 'package:freelancer/screen/widgets/editable_profile_avatar.dart';
import 'package:freelancer/screen/widgets/seller_skills_editor.dart';
import 'package:freelancer/services/profile_service.dart';
import 'package:nb_utils/nb_utils.dart';

import '../../widgets/constant.dart';

class SellerEditProfile extends StatefulWidget {
  const SellerEditProfile({Key? key}) : super(key: key);

  @override
  State<SellerEditProfile> createState() => _SellerEditProfileState();
}

class _SellerEditProfileState extends State<SellerEditProfile> {
  final _nameController = TextEditingController();
  final _phoneController = TextEditingController();
  final _addressController = TextEditingController();
  final _jobTitleController = TextEditingController();
  final _aboutController = TextEditingController();

  String _selectedGender = L10nLabels.genderMale;
  DateTime? _dateOfBirth;
  List<SellerSkill> _skills = [];
  bool _isLoading = true;
  bool _isSaving = false;
  String? _profileImageUrl;
  bool _uploadingPhoto = false;

  @override
  void initState() {
    super.initState();
    _loadProfile();
  }

  @override
  void dispose() {
    _nameController.dispose();
    _phoneController.dispose();
    _addressController.dispose();
    _jobTitleController.dispose();
    _aboutController.dispose();
    super.dispose();
  }

  Future<void> _loadProfile() async {
    try {
      final profile = await ProfileService.getSellerProfileForEdit();
      if (!mounted) return;
      if (profile != null) {
        setState(() {
          _nameController.text = profile['name'] ?? '';
          _phoneController.text = profile['phone'] ?? '';
          _addressController.text = ProfileService.sellerAddressFromProfile(profile) ?? '';
          _selectedGender = profile['gender'] ?? L10nLabels.genderMale;
          _jobTitleController.text = ProfileService.sellerJobTitleFromProfile(profile) ?? '';
          _aboutController.text = ProfileService.sellerAboutFromProfile(profile) ?? '';
          _skills = ProfileService.sellerSkillsFromProfile(profile);
          _dateOfBirth = ProfileService.sellerDateOfBirthFromProfile(profile);
          _profileImageUrl =
              ProfileImage.normalize(profile['profile_image_url'] as String?);
          _isLoading = false;
        });
      } else {
        setState(() => _isLoading = false);
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(context.l10n.errorWithDetail('$e'))),
        );
      }
    }
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

  String _formatDobPickerLabel(DateTime? dob, AppLocalizations l10n) {
    if (dob == null) return l10n.tapSetBirthDate;
    final age = ProfileService.ageFromDateOfBirth(dob.toIso8601String());
    if (age != null) return l10n.ageHiddenOnProfile(age);
    return l10n.birthDateSaved;
  }

  Future<void> _changePhoto() async {
    final file = await ProfileAvatarPicker.pickAndCrop(context);
    if (file == null || !mounted) return;
    setState(() => _uploadingPhoto = true);
    try {
      final url = await ProfileService.uploadProfileImage(file);
      if (!mounted) return;
      setState(() {
        _profileImageUrl = url;
        _uploadingPhoto = false;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(context.l10n.profileUpdatedShort)),
      );
    } catch (e) {
      if (!mounted) return;
      setState(() => _uploadingPhoto = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(context.l10n.errorWithDetail('$e'))),
      );
    }
  }

  Future<void> _handleSave() async {
    final skillError = SellerSkillsValidation.validate(_skills);
    if (skillError != null) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(skillError)));
      return;
    }

    setState(() => _isSaving = true);
    try {
      await ProfileService.updateProfile({
        'name': _nameController.text.trim(),
        'phone': _phoneController.text.trim(),
        'gender': _selectedGender,
        'country': null,
        'city': null,
      });
      await ProfileService.updateSellerProfile(
        jobTitle: _jobTitleController.text.trim(),
        about: _aboutController.text.trim(),
        skills: _skills,
        dateOfBirth: _dateOfBirth,
        address: _addressController.text.trim(),
      );
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(context.l10n.profileUpdatedShort)));
        Navigator.pop(context);
      }
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(context.l10n.errorWithDetail('$e'))));
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  Widget _sectionTitle(String title) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Text(
        title,
        style: kTextStyle.copyWith(color: kNeutralColor, fontWeight: FontWeight.bold, fontSize: 16),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    if (_isLoading) {
      return const Scaffold(
        backgroundColor: kDarkWhite,
        body: SafeArea(
          child: Center(child: CircularProgressIndicator(color: kPrimaryColor)),
        ),
      );
    }

    return Scaffold(
      backgroundColor: kDarkWhite,
      appBar: AppBar(
        backgroundColor: kDarkWhite,
        elevation: 0,
        iconTheme: const IconThemeData(color: kNeutralColor),
        title: Text(
          l10n.editProfile,
          style: kTextStyle.copyWith(color: kNeutralColor, fontWeight: FontWeight.bold),
        ),
        centerTitle: true,
      ),
      bottomNavigationBar: SafeArea(
        top: false,
        child: Container(
          decoration: const BoxDecoration(color: kWhite),
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
          child: ButtonGlobalWithoutIcon(
            buttontext: _isSaving ? l10n.updating : l10n.updateProfile,
            buttonTextColor: kWhite,
            buttonDecoration: kButtonDecoration.copyWith(
              color: _isSaving ? kLightNeutralColor : kPrimaryColor,
              borderRadius: BorderRadius.circular(30.0),
            ),
            onPressed: _isSaving ? null : _handleSave,
          ),
        ),
      ),
      body: SafeArea(
        top: false,
        child: Padding(
          padding: const EdgeInsets.only(top: 20.0),
          child: Container(
            padding: const EdgeInsets.only(left: 20.0, right: 20.0),
            width: context.width(),
            decoration: const BoxDecoration(
              color: kWhite,
              borderRadius: BorderRadius.only(topLeft: Radius.circular(30.0), topRight: Radius.circular(30.0)),
            ),
            child: SingleChildScrollView(
              physics: const BouncingScrollPhysics(),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const SizedBox(height: 24.0),
                  Center(
                    child: EditableProfileAvatar(
                      imageUrl: _profileImageUrl,
                      size: 96,
                      uploading: _uploadingPhoto,
                      onTap: _changePhoto,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Center(
                    child: Text(
                      l10n.selectProfileImage,
                      style: kTextStyle.copyWith(color: kSubTitleColor, fontSize: 13),
                    ),
                  ),
                  const SizedBox(height: 24.0),
                  _sectionTitle(l10n.basicInfo),
                  _field(_nameController, l10n.fullName, l10n.enterYourName),
                  const SizedBox(height: 20.0),
                  _field(_phoneController, l10n.phoneNo, l10n.enterPhoneNo, type: TextInputType.phone),
                  const SizedBox(height: 20.0),
                  TextFormField(
                    controller: _addressController,
                    keyboardType: TextInputType.multiline,
                    maxLines: 3,
                    cursorColor: kNeutralColor,
                    textInputAction: TextInputAction.newline,
                    decoration: kInputDecoration.copyWith(
                      labelText: l10n.address,
                      hintText: l10n.enterFullAddress,
                      alignLabelWithHint: true,
                      border: const OutlineInputBorder(),
                    ),
                  ),
                  const SizedBox(height: 20.0),
                  FormField(
                    builder: (FormFieldState<dynamic> field) => InputDecorator(
                      decoration: InputDecoration(
                        enabledBorder: const OutlineInputBorder(
                          borderRadius: BorderRadius.all(Radius.circular(8.0)),
                          borderSide: BorderSide(color: kBorderColorTextField, width: 2),
                        ),
                        contentPadding: const EdgeInsets.all(7.0),
                        floatingLabelBehavior: FloatingLabelBehavior.always,
                        labelText: l10n.selectGender,
                        labelStyle: kTextStyle.copyWith(color: kNeutralColor),
                      ),
                      child: DropdownButtonHideUnderline(
                        child: DropdownButton<String>(
                          icon: const Icon(FeatherIcons.chevronDown),
                          value: L10nLabels.genderValues.contains(_selectedGender)
                              ? _selectedGender
                              : L10nLabels.genderMale,
                          style: kTextStyle.copyWith(color: kSubTitleColor),
                          items: L10nLabels.genderValues
                              .map((g) => DropdownMenuItem(
                                    value: g,
                                    child: Text(L10nLabels.gender(l10n, g)),
                                  ))
                              .toList(),
                          onChanged: (v) => setState(() => _selectedGender = v!),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 20.0),
                  Text(
                    l10n.ageLabel,
                    style: kTextStyle.copyWith(color: kNeutralColor, fontWeight: FontWeight.bold, fontSize: 14),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    l10n.agePrivacyHint,
                    style: kTextStyle.copyWith(color: kLightNeutralColor, fontSize: 12),
                  ),
                  const SizedBox(height: 8),
                  InkWell(
                    onTap: _pickDateOfBirth,
                    child: InputDecorator(
                      decoration: kInputDecoration.copyWith(
                        labelText: l10n.dateOfBirth,
                        border: const OutlineInputBorder(),
                      ),
                      child: Text(
                        _formatDobPickerLabel(_dateOfBirth, l10n),
                        style: kTextStyle.copyWith(color: kSubTitleColor),
                      ),
                    ),
                  ),
                  const SizedBox(height: 32.0),
                  _sectionTitle(l10n.professional),
                  _field(_jobTitleController, l10n.jobTitle, l10n.jobTitleHint),
                  const SizedBox(height: 20.0),
                  TextFormField(
                    controller: _aboutController,
                    keyboardType: TextInputType.multiline,
                    maxLines: 6,
                    cursorColor: kNeutralColor,
                    decoration: kInputDecoration.copyWith(
                      labelText: l10n.profileDescription,
                      hintText: l10n.profileDescriptionHint,
                      alignLabelWithHint: true,
                      border: const OutlineInputBorder(),
                    ),
                  ),
                  const SizedBox(height: 32.0),
                  Text(
                    l10n.yourSkills,
                    style: kTextStyle.copyWith(color: kNeutralColor, fontWeight: FontWeight.bold, fontSize: 16),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    l10n.skillsOptionalHint,
                    style: kTextStyle.copyWith(color: kLightNeutralColor, fontSize: 12),
                  ),
                  const SizedBox(height: 12),
                  SellerSkillsEditor(
                    skills: _skills,
                    onChanged: (skills) => setState(() => _skills = skills),
                  ),
                  const SizedBox(height: 24.0),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _field(TextEditingController c, String label, String hint, {TextInputType type = TextInputType.name}) {
    return TextFormField(
      controller: c,
      keyboardType: type,
      cursorColor: kNeutralColor,
      textInputAction: TextInputAction.next,
      decoration: kInputDecoration.copyWith(
        labelText: label,
        labelStyle: kTextStyle.copyWith(color: kNeutralColor),
        hintText: hint,
        hintStyle: kTextStyle.copyWith(color: kSubTitleColor),
        border: const OutlineInputBorder(),
      ),
    );
  }
}
