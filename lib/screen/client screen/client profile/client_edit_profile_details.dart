import 'package:flutter/material.dart';
import 'package:flutter_feather_icons/flutter_feather_icons.dart';
import 'package:freelancer/l10n/l10n.dart';
import 'package:freelancer/l10n/l10n_labels.dart';
import 'package:freelancer/screen/widgets/button_global.dart';
import 'package:freelancer/services/profile_service.dart';
import 'package:nb_utils/nb_utils.dart';

import '../../widgets/constant.dart';
import '../../widgets/profile_location_fields.dart';

class ClientEditProfile extends StatefulWidget {
  const ClientEditProfile({Key? key}) : super(key: key);

  @override
  State<ClientEditProfile> createState() => _ClientEditProfileState();
}

class _ClientEditProfileState extends State<ClientEditProfile> {
  final _nameController = TextEditingController();
  final _phoneController = TextEditingController();
  final _countryController = TextEditingController();
  final _cityController = TextEditingController();
  final _bioController = TextEditingController();

  String _selectedGender = 'Male';
  bool _isLoading = true;
  bool _isSaving = false;
  String? _profileImageUrl;

  @override
  void initState() {
    super.initState();
    _loadProfile();
  }

  @override
  void dispose() {
    _nameController.dispose();
    _phoneController.dispose();
    _countryController.dispose();
    _cityController.dispose();
    _bioController.dispose();
    super.dispose();
  }

  Future<void> _loadProfile() async {
    try {
      final profile = await ProfileService.getProfile();
      if (mounted && profile != null) {
        setState(() {
          _nameController.text = profile['name'] ?? '';
          _phoneController.text = profile['phone'] ?? '';
          _countryController.text = profile['country'] ?? '';
          _cityController.text = profile['city'] ?? '';
          _bioController.text = profile['bio'] ?? '';
          _selectedGender = profile['gender'] ?? 'Male';
          _profileImageUrl = profile['profile_image_url'];
          _isLoading = false;
        });
      } else {
        if (mounted) setState(() => _isLoading = false);
      }
    } catch (e) {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _handleSave() async {
    setState(() => _isSaving = true);

    try {
      await ProfileService.updateProfile({
        'name': _nameController.text.trim(),
        'phone': _phoneController.text.trim(),
        'country': _countryController.text.trim(),
        'city': _cityController.text.trim(),
        'bio': _bioController.text.trim(),
        'gender': _selectedGender,
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(context.l10n.profileUpdated)),
        );
        Navigator.pop(context);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(context.l10n.errorWithDetail('$e'))),
        );
      }
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    if (_isLoading) {
      return const Scaffold(
        backgroundColor: kDarkWhite,
        body: Center(child: CircularProgressIndicator(color: kPrimaryColor)),
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
      body: Padding(
        padding: const EdgeInsets.only(top: 20.0),
        child: Container(
          padding: const EdgeInsets.only(left: 20.0, right: 20.0),
          width: context.width(),
          decoration: const BoxDecoration(
            color: kWhite,
            borderRadius: BorderRadius.only(
              topLeft: Radius.circular(30.0),
              topRight: Radius.circular(30.0),
            ),
          ),
          child: SingleChildScrollView(
            physics: const BouncingScrollPhysics(),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SizedBox(height: 20.0),
                const SizedBox(height: 15.0),

                // Profile image
                Row(
                  children: [
                    Container(
                      height: 80,
                      width: 80,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        border: Border.all(color: kPrimaryColor),
                        image: DecorationImage(
                          image: _profileImageUrl != null
                              ? NetworkImage(_profileImageUrl!) as ImageProvider
                              : const AssetImage('images/profile3.png'),
                          fit: BoxFit.cover,
                        ),
                      ),
                    ),
                    const SizedBox(width: 10.0),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          _nameController.text.isEmpty ? l10n.userName : _nameController.text,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: kTextStyle.copyWith(color: kNeutralColor, fontWeight: FontWeight.bold, fontSize: 18.0),
                        ),
                        Text(
                          l10n.editProfileSubtitle,
                          style: kTextStyle.copyWith(color: kSubTitleColor),
                        ),
                      ],
                    ),
                  ],
                ),
                const SizedBox(height: 30.0),

                TextFormField(
                  controller: _nameController,
                  keyboardType: TextInputType.name,
                  cursorColor: kNeutralColor,
                  textInputAction: TextInputAction.next,
                  decoration: kInputDecoration.copyWith(
                    labelText: l10n.fullName,
                    labelStyle: kTextStyle.copyWith(color: kNeutralColor),
                    hintText: l10n.enterYourName,
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
                    labelText: l10n.phoneNo,
                    hintText: l10n.enterPhoneNo,
                    hintStyle: kTextStyle.copyWith(color: kSubTitleColor),
                    focusColor: kNeutralColor,
                    border: const OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: 20.0),
                ProfileLocationFields(
                  countryController: _countryController,
                  cityController: _cityController,
                ),
                const SizedBox(height: 20.0),
                TextFormField(
                  controller: _bioController,
                  keyboardType: TextInputType.multiline,
                  maxLines: 4,
                  cursorColor: kNeutralColor,
                  decoration: kInputDecoration.copyWith(
                    labelText: l10n.aboutYourCompany,
                    labelStyle: kTextStyle.copyWith(color: kNeutralColor),
                    hintText: l10n.aboutCompanyHint,
                    hintStyle: kTextStyle.copyWith(color: kSubTitleColor),
                    alignLabelWithHint: true,
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
                        labelText: l10n.selectGender,
                        labelStyle: kTextStyle.copyWith(color: kNeutralColor),
                      ),
                      child: DropdownButtonHideUnderline(
                        child: DropdownButton<String>(
                          icon: const Icon(FeatherIcons.chevronDown),
                          value: gender.contains(_selectedGender) ? _selectedGender : gender.first,
                          style: kTextStyle.copyWith(color: kSubTitleColor),
                          items: gender
                              .map(
                                (g) => DropdownMenuItem(
                                  value: g,
                                  child: Text(L10nLabels.gender(l10n, g)),
                                ),
                              )
                              .toList(),
                          onChanged: (value) {
                            setState(() => _selectedGender = value!);
                          },
                        ),
                      ),
                    );
                  },
                ),
                const SizedBox(height: 10.0),
              ],
            ),
          ),
        ),
      ),
      bottomNavigationBar: Container(
        decoration: const BoxDecoration(color: kWhite),
        child: ButtonGlobalWithoutIcon(
          buttontext: _isSaving ? l10n.updating : l10n.updateProfile,
          buttonDecoration: kButtonDecoration.copyWith(
            color: _isSaving ? kLightNeutralColor : kPrimaryColor,
            borderRadius: BorderRadius.circular(30.0),
          ),
          onPressed: _isSaving ? null : _handleSave,
          buttonTextColor: kWhite,
        ),
      ),
    );
  }
}
