import 'package:flutter/material.dart';
import 'package:flutter_feather_icons/flutter_feather_icons.dart';
import 'package:freelancer/screen/widgets/button_global.dart';
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
  final _countryController = TextEditingController();
  final _cityController = TextEditingController();
  String _selectedGender = 'Male';
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
    _countryController.dispose();
    _cityController.dispose();
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
          _selectedGender = profile['gender'] ?? 'Male';
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
        'gender': _selectedGender,
      });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Profile updated!')));
        Navigator.pop(context);
      }
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: $e')));
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) return const Scaffold(backgroundColor: kDarkWhite, body: Center(child: CircularProgressIndicator(color: kPrimaryColor)));

    return Scaffold(
      backgroundColor: kDarkWhite,
      appBar: AppBar(backgroundColor: kDarkWhite, elevation: 0, iconTheme: const IconThemeData(color: kNeutralColor),
        title: Text('Edit Profile', style: kTextStyle.copyWith(color: kNeutralColor, fontWeight: FontWeight.bold)), centerTitle: true),
      bottomNavigationBar: Container(
        decoration: const BoxDecoration(color: kWhite),
        child: ButtonGlobalWithoutIcon(
          buttontext: _isSaving ? 'Updating...' : 'Update Profile', buttonTextColor: kWhite,
          buttonDecoration: kButtonDecoration.copyWith(color: _isSaving ? kLightNeutralColor : kPrimaryColor, borderRadius: BorderRadius.circular(30.0)),
          onPressed: _isSaving ? null : _handleSave,
        ),
      ),
      body: Padding(
        padding: const EdgeInsets.only(top: 20.0),
        child: Container(
          padding: const EdgeInsets.only(left: 20.0, right: 20.0), width: context.width(),
          decoration: const BoxDecoration(color: kWhite, borderRadius: BorderRadius.only(topLeft: Radius.circular(30.0), topRight: Radius.circular(30.0))),
          child: SingleChildScrollView(
            physics: const BouncingScrollPhysics(),
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              const SizedBox(height: 30.0),
              _field(_nameController, 'Full Name', 'Enter your name'),
              const SizedBox(height: 20.0),
              _field(_phoneController, 'Phone No.', 'Enter Phone No.', type: TextInputType.phone),
              const SizedBox(height: 20.0),
              _field(_countryController, 'Country', 'Enter Country'),
              const SizedBox(height: 20.0),
              _field(_cityController, 'City', 'Enter City'),
              const SizedBox(height: 20.0),
              FormField(
                builder: (FormFieldState<dynamic> field) => InputDecorator(
                  decoration: InputDecoration(
                    enabledBorder: const OutlineInputBorder(borderRadius: BorderRadius.all(Radius.circular(8.0)), borderSide: BorderSide(color: kBorderColorTextField, width: 2)),
                    contentPadding: const EdgeInsets.all(7.0), floatingLabelBehavior: FloatingLabelBehavior.always,
                    labelText: 'Select Gender', labelStyle: kTextStyle.copyWith(color: kNeutralColor),
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
              const SizedBox(height: 10.0),
            ]),
          ),
        ),
      ),
    );
  }

  Widget _field(TextEditingController c, String label, String hint, {TextInputType type = TextInputType.name}) {
    return TextFormField(
      controller: c, keyboardType: type, cursorColor: kNeutralColor, textInputAction: TextInputAction.next,
      decoration: kInputDecoration.copyWith(labelText: label, labelStyle: kTextStyle.copyWith(color: kNeutralColor),
        hintText: hint, hintStyle: kTextStyle.copyWith(color: kSubTitleColor), border: const OutlineInputBorder()),
    );
  }
}
