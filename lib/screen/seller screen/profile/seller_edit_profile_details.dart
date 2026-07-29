import 'package:flutter/material.dart';
import 'package:flutter_feather_icons/flutter_feather_icons.dart';
import 'package:freelancer/core/utils/seller_skills_validation.dart';
import 'package:freelancer/data/models/seller_skill_model.dart';
import 'package:freelancer/l10n/l10n.dart';
import 'package:freelancer/l10n/l10n_labels.dart';
import 'package:freelancer/screen/widgets/button_global.dart';
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

  String _selectedGender = 'Male';
  DateTime? _dateOfBirth;
  List<SellerSkill> _skills = [];
  bool _isLoading = true;
  bool _isSaving = false;

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
          _selectedGender = profile['gender'] ?? 'Male';
          _jobTitleController.text = ProfileService.sellerJobTitleFromProfile(profile) ?? '';
          _aboutController.text = ProfileService.sellerAboutFromProfile(profile) ?? '';
          _skills = ProfileService.sellerSkillsFromProfile(profile);
          _dateOfBirth = ProfileService.sellerDateOfBirthFromProfile(profile);
          _isLoading = false;
        });
      } else {
        setState(() => _isLoading = false);
      }
    } catch (e) {
      if (mounted) setState(() => _isLoading = false);
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

  String _formatDobPickerLabel(DateTime? dob) {
    if (dob == null) return 'Tap to set your birth date';
    final age = ProfileService.ageFromDateOfBirth(dob.toIso8601String());
    if (age != null) return 'Age $age (birth date is hidden on profile)';
    return 'Birth date saved';
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
          'Edit Profile',
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
            buttontext: _isSaving ? 'Updating...' : 'Update Profile',
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
                  const SizedBox(height: 30.0),
                  _sectionTitle('Basic info'),
                  _field(_nameController, 'Full Name', 'Enter your name'),
                  const SizedBox(height: 20.0),
                  _field(_phoneController, 'Phone No.', 'Enter Phone No.', type: TextInputType.phone),
                  const SizedBox(height: 20.0),
                  TextFormField(
                    controller: _addressController,
                    keyboardType: TextInputType.multiline,
                    maxLines: 3,
                    cursorColor: kNeutralColor,
                    textInputAction: TextInputAction.newline,
                    decoration: kInputDecoration.copyWith(
                      labelText: 'Address',
                      hintText: 'Enter your full address',
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
                        labelText: 'Select Gender',
                        labelStyle: kTextStyle.copyWith(color: kNeutralColor),
                      ),
                      child: DropdownButtonHideUnderline(
                        child: DropdownButton<String>(
                          icon: const Icon(FeatherIcons.chevronDown),
                          value: gender.contains(_selectedGender) ? _selectedGender : gender.first,
                          style: kTextStyle.copyWith(color: kSubTitleColor),
                          items: gender.map((g) => DropdownMenuItem(value: g, child: Text(g))).toList(),
                          onChanged: (v) => setState(() => _selectedGender = v!),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 20.0),
                  Text(
                    'Age',
                    style: kTextStyle.copyWith(color: kNeutralColor, fontWeight: FontWeight.bold, fontSize: 14),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Your age is shown on your profile. Your birth date is never displayed.',
                    style: kTextStyle.copyWith(color: kLightNeutralColor, fontSize: 12),
                  ),
                  const SizedBox(height: 8),
                  InkWell(
                    onTap: _pickDateOfBirth,
                    child: InputDecorator(
                      decoration: kInputDecoration.copyWith(
                        labelText: 'Date of birth',
                        border: const OutlineInputBorder(),
                      ),
                      child: Text(
                        _formatDobPickerLabel(_dateOfBirth),
                        style: kTextStyle.copyWith(color: kSubTitleColor),
                      ),
                    ),
                  ),
                  const SizedBox(height: 32.0),
                  _sectionTitle('Professional'),
                  _field(_jobTitleController, 'Job title', 'e.g. Factory Worker'),
                  const SizedBox(height: 20.0),
                  TextFormField(
                    controller: _aboutController,
                    keyboardType: TextInputType.multiline,
                    maxLines: 6,
                    cursorColor: kNeutralColor,
                    decoration: kInputDecoration.copyWith(
                      labelText: 'Profile description',
                      hintText: 'Write a brief description about you…',
                      alignLabelWithHint: true,
                      border: const OutlineInputBorder(),
                    ),
                  ),
                  const SizedBox(height: 32.0),
                  Text(
                    'Your skills',
                    style: kTextStyle.copyWith(color: kNeutralColor, fontWeight: FontWeight.bold, fontSize: 16),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Optional — add skills to help clients find you.',
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
