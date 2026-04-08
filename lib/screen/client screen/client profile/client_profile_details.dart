import 'package:flutter/material.dart';
import 'package:flutter_iconly/flutter_iconly.dart';
import 'package:freelancer/screen/widgets/button_global.dart';
import 'package:freelancer/services/profile_service.dart';
import 'package:nb_utils/nb_utils.dart';

import '../../widgets/constant.dart';
import 'client_edit_profile_details.dart';

class ClientProfileDetails extends StatefulWidget {
  const ClientProfileDetails({Key? key}) : super(key: key);

  @override
  State<ClientProfileDetails> createState() => _ClientProfileDetailsState();
}

class _ClientProfileDetailsState extends State<ClientProfileDetails> {
  Map<String, dynamic>? _profile;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadProfile();
  }

  Future<void> _loadProfile() async {
    try {
      final profile = await ProfileService.getProfile();
      if (mounted) {
        setState(() {
          _profile = profile;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Scaffold(
        backgroundColor: kDarkWhite,
        body: Center(child: CircularProgressIndicator(color: kPrimaryColor)),
      );
    }

    final name = _profile?['name'] ?? 'User';
    final email = _profile?['email'] ?? '';
    final phone = _profile?['phone'] ?? '';
    final country = _profile?['country'] ?? '';
    final city = _profile?['city'] ?? '';
    final gender = _profile?['gender'] ?? '';
    final profileImageUrl = _profile?['profile_image_url'];

    // Split name into first/last
    final nameParts = name.split(' ');
    final firstName = nameParts.isNotEmpty ? nameParts.first : '';
    final lastName = nameParts.length > 1 ? nameParts.sublist(1).join(' ') : '';

    return Scaffold(
      backgroundColor: kDarkWhite,
      appBar: AppBar(
        backgroundColor: kDarkWhite,
        elevation: 0,
        iconTheme: const IconThemeData(color: kNeutralColor),
        title: Text(
          'My Profile',
          style: kTextStyle.copyWith(color: kNeutralColor, fontWeight: FontWeight.bold),
        ),
        centerTitle: true,
      ),
      bottomNavigationBar: ButtonGlobalWithIcon(
        buttontext: 'Edit Profile',
        buttonDecoration: kButtonDecoration.copyWith(
          color: kPrimaryColor,
          borderRadius: BorderRadius.circular(30.0),
        ),
        onPressed: () async {
          await const ClientEditProfile().launch(context);
          _loadProfile();
        },
        buttonTextColor: kWhite,
        buttonIcon: IconlyBold.edit,
      ),
      body: Padding(
        padding: const EdgeInsets.only(top: 30.0),
        child: Container(
          padding: const EdgeInsets.only(left: 15.0, right: 15.0, bottom: 15.0),
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
                const SizedBox(height: 15.0),
                Row(
                  children: [
                    Container(
                      height: 80,
                      width: 80,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        image: DecorationImage(
                          image: profileImageUrl != null
                              ? NetworkImage(profileImageUrl) as ImageProvider
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
                          name,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: kTextStyle.copyWith(color: kNeutralColor, fontWeight: FontWeight.bold, fontSize: 18.0),
                        ),
                        Text(
                          email,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: kTextStyle.copyWith(color: kLightNeutralColor),
                        ),
                      ],
                    ),
                  ],
                ),
                const SizedBox(height: 20.0),
                Text(
                  'Client Information',
                  style: kTextStyle.copyWith(color: kNeutralColor, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 15.0),
                _buildRow('First Name', firstName),
                const SizedBox(height: 10.0),
                _buildRow('Last Name', lastName),
                const SizedBox(height: 10.0),
                _buildRow('Email', email),
                const SizedBox(height: 10.0),
                _buildRow('Phone Number', phone),
                const SizedBox(height: 10.0),
                _buildRow('Country', country),
                const SizedBox(height: 10.0),
                _buildRow('City', city),
                const SizedBox(height: 10.0),
                _buildRow('Gender', gender),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildRow(String label, String value) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(
          flex: 2,
          child: Text(label, style: kTextStyle.copyWith(color: kSubTitleColor)),
        ),
        Expanded(
          flex: 4,
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(':', style: kTextStyle.copyWith(color: kSubTitleColor)),
              const SizedBox(width: 10.0),
              Flexible(
                child: Text(
                  value.isEmpty ? '-' : value,
                  style: kTextStyle.copyWith(color: kSubTitleColor),
                  overflow: TextOverflow.ellipsis,
                  maxLines: 2,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
