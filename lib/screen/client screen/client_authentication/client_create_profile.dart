import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_feather_icons/flutter_feather_icons.dart';
import 'package:flutter_iconly/flutter_iconly.dart';
import 'package:freelancer/l10n/l10n.dart';
import 'package:freelancer/l10n/l10n_labels.dart';
import 'package:freelancer/screen/widgets/button_global.dart';
import 'package:freelancer/services/profile_service.dart';
import 'package:image_picker/image_picker.dart';

import '../../seller screen/seller popUp/seller_popup.dart';
import '../../widgets/constant.dart';

class ClientCreateProfile extends StatefulWidget {
  const ClientCreateProfile({Key? key}) : super(key: key);

  @override
  State<ClientCreateProfile> createState() => _ClientCreateProfileState();
}

class _ClientCreateProfileState extends State<ClientCreateProfile> {
  final _nameController = TextEditingController();
  final _phoneController = TextEditingController();
  final _countryController = TextEditingController();
  final _cityController = TextEditingController();
  final _streetController = TextEditingController();
  final _stateController = TextEditingController();
  final _postalController = TextEditingController();

  String _selectedGender = L10nLabels.genderMale;
  String _selectedLanguage = 'English';
  bool _isSaving = false;
  File? _pickedImage;
  String? _uploadedImageUrl;

  @override
  void dispose() {
    _nameController.dispose();
    _phoneController.dispose();
    _countryController.dispose();
    _cityController.dispose();
    _streetController.dispose();
    _stateController.dispose();
    _postalController.dispose();
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

  DropdownButton<String> _languageDropdown() {
    return DropdownButton<String>(
      icon: const Icon(FeatherIcons.chevronDown),
      items: language
          .map((des) => DropdownMenuItem(value: des, child: Text(des)))
          .toList(),
      value: _selectedLanguage,
      style: kTextStyle.copyWith(color: kSubTitleColor),
      onChanged: (value) {
        if (value == null) return;
        setState(() => _selectedLanguage = value);
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

  Future<void> _handleSave() async {
    final l10n = context.l10n;
    final name = _nameController.text.trim();
    if (name.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(l10n.pleaseEnterName)),
      );
      return;
    }

    setState(() => _isSaving = true);
    try {
      if (_pickedImage != null && _uploadedImageUrl == null) {
        _uploadedImageUrl = await ProfileService.uploadProfileImage(_pickedImage!);
      }

      // Street/state/zip have no client profile columns — keep city/country only.
      await ProfileService.updateProfile({
        'name': name,
        'phone': _phoneController.text.trim(),
        'country': _countryController.text.trim(),
        'city': _cityController.text.trim(),
        'gender': _selectedGender,
      });

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
          l10n.createProfile,
          style: kTextStyle.copyWith(color: kNeutralColor, fontWeight: FontWeight.bold),
        ),
      ),
      body: Padding(
        padding: const EdgeInsets.only(left: 20.0, right: 20.0),
        child: SingleChildScrollView(
          physics: const BouncingScrollPhysics(),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 20.0),
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
              TextFormField(
                controller: _nameController,
                keyboardType: TextInputType.name,
                cursorColor: kNeutralColor,
                textInputAction: TextInputAction.next,
                decoration: kInputDecoration.copyWith(
                  labelText: l10n.userName,
                  labelStyle: kTextStyle.copyWith(color: kNeutralColor),
                  hintText: l10n.userName,
                  hintStyle: kTextStyle.copyWith(color: kSubTitleColor),
                  focusColor: kNeutralColor,
                  border: const OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 20.0),
              TextFormField(
                controller: _phoneController,
                keyboardType: TextInputType.phone,
                cursorColor: kNeutralColor,
                textInputAction: TextInputAction.next,
                decoration: kInputDecoration.copyWith(
                  labelText: l10n.phone,
                  hintText: l10n.phone,
                  hintStyle: kTextStyle.copyWith(color: kSubTitleColor),
                  focusColor: kNeutralColor,
                  border: const OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 20.0),
              TextFormField(
                controller: _countryController,
                keyboardType: TextInputType.name,
                cursorColor: kNeutralColor,
                textInputAction: TextInputAction.next,
                decoration: kInputDecoration.copyWith(
                  labelText: l10n.country,
                  labelStyle: kTextStyle.copyWith(color: kNeutralColor),
                  hintText: l10n.country,
                  hintStyle: kTextStyle.copyWith(color: kSubTitleColor),
                  focusColor: kNeutralColor,
                  border: const OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 20.0),
              TextFormField(
                controller: _streetController,
                keyboardType: TextInputType.streetAddress,
                cursorColor: kNeutralColor,
                textInputAction: TextInputAction.next,
                decoration: kInputDecoration.copyWith(
                  labelText: l10n.streetAddress,
                  labelStyle: kTextStyle.copyWith(color: kNeutralColor),
                  hintText: l10n.streetAddress,
                  hintStyle: kTextStyle.copyWith(color: kSubTitleColor),
                  focusColor: kNeutralColor,
                  border: const OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 20.0),
              TextFormField(
                controller: _cityController,
                keyboardType: TextInputType.name,
                cursorColor: kNeutralColor,
                textInputAction: TextInputAction.next,
                decoration: kInputDecoration.copyWith(
                  labelText: l10n.city,
                  labelStyle: kTextStyle.copyWith(color: kNeutralColor),
                  hintText: l10n.city,
                  hintStyle: kTextStyle.copyWith(color: kSubTitleColor),
                  focusColor: kNeutralColor,
                  border: const OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 20.0),
              TextFormField(
                controller: _stateController,
                keyboardType: TextInputType.name,
                cursorColor: kNeutralColor,
                textInputAction: TextInputAction.next,
                decoration: kInputDecoration.copyWith(
                  labelText: l10n.state,
                  labelStyle: kTextStyle.copyWith(color: kNeutralColor),
                  hintText: l10n.state,
                  hintStyle: kTextStyle.copyWith(color: kSubTitleColor),
                  focusColor: kNeutralColor,
                  border: const OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 20.0),
              TextFormField(
                controller: _postalController,
                keyboardType: TextInputType.text,
                cursorColor: kNeutralColor,
                textInputAction: TextInputAction.next,
                decoration: kInputDecoration.copyWith(
                  labelText: l10n.zipCode,
                  labelStyle: kTextStyle.copyWith(color: kNeutralColor),
                  hintText: l10n.zipCode,
                  hintStyle: kTextStyle.copyWith(color: kSubTitleColor),
                  focusColor: kNeutralColor,
                  border: const OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 20.0),
              FormField(
                builder: (FormFieldState<dynamic> field) {
                  return InputDecorator(
                    decoration: InputDecoration(
                      enabledBorder: const OutlineInputBorder(
                        borderRadius: BorderRadius.all(Radius.circular(8.0)),
                        borderSide: BorderSide(color: kBorderColorTextField, width: 2),
                      ),
                      contentPadding: const EdgeInsets.all(7.0),
                      floatingLabelBehavior: FloatingLabelBehavior.always,
                      labelText: l10n.selectLanguage,
                      labelStyle: kTextStyle.copyWith(color: kNeutralColor),
                    ),
                    child: DropdownButtonHideUnderline(child: _languageDropdown()),
                  );
                },
              ),
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
                      labelStyle: kTextStyle.copyWith(color: kNeutralColor),
                    ),
                    child: DropdownButtonHideUnderline(child: _genderDropdown(l10n)),
                  );
                },
              ),
              const SizedBox(height: 24.0),
            ],
          ),
        ),
      ),
      bottomNavigationBar: ButtonGlobalWithoutIcon(
        buttontext: _isSaving ? l10n.saving : l10n.saveProfile,
        buttonDecoration: kButtonDecoration.copyWith(
          color: _isSaving ? kLightNeutralColor : kPrimaryColor,
          borderRadius: BorderRadius.circular(30.0),
        ),
        onPressed: _isSaving ? null : _handleSave,
        buttonTextColor: kWhite,
      ),
    );
  }
}
