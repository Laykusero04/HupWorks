import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_feather_icons/flutter_feather_icons.dart';
import 'package:flutter_iconly/flutter_iconly.dart';
import 'package:freelancer/features/auth/bloc/auth_bloc.dart';
import 'package:freelancer/features/auth/bloc/auth_event.dart';
import 'package:freelancer/services/profile_service.dart';
import 'package:nb_utils/nb_utils.dart';

import '../../widgets/constant.dart';
import '../client dashboard/client_dashboard.dart';
import '../client favourite/client_favourite_list.dart';
import '../client invite/client_invite.dart';
import '../client report/client_report.dart';
import '../client_setting/client_setting.dart';
import '../deposit/add_deposit.dart';
import '../deposit/deposit_history.dart';
import '../transaction/transaction.dart';
import 'client_profile_details.dart';

class ClientProfile extends StatefulWidget {
  const ClientProfile({Key? key}) : super(key: key);

  @override
  State<ClientProfile> createState() => _ClientProfileState();
}

class _ClientProfileState extends State<ClientProfile> {
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

  void _handleLogout() {
    context.read<AuthBloc>().add(AuthLogoutRequested());
  }

  @override
  Widget build(BuildContext context) {
    final name = _profile?['name'] ?? 'User';
    final balance = _profile?['balance'] ?? 0;
    final profileImageUrl = _profile?['profile_image_url'];

    return Scaffold(
      backgroundColor: kDarkWhite,
      appBar: AppBar(
        backgroundColor: kDarkWhite,
        elevation: 0,
        iconTheme: const IconThemeData(color: kNeutralColor),
        titleSpacing: 0,
        title: _isLoading
            ? const SizedBox()
            : ListTile(
                visualDensity: const VisualDensity(vertical: -4),
                contentPadding: EdgeInsets.zero,
                leading: Container(
                  height: 45,
                  width: 45,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: kDarkWhite,
                    image: DecorationImage(
                      image: profileImageUrl != null
                          ? NetworkImage(profileImageUrl) as ImageProvider
                          : const AssetImage('images/profile1.png'),
                      fit: BoxFit.cover,
                    ),
                  ),
                ),
                title: Text(
                  name,
                  overflow: TextOverflow.ellipsis,
                  maxLines: 1,
                  style: kTextStyle.copyWith(color: kNeutralColor),
                ),
                subtitle: RichText(
                  text: TextSpan(
                    text: 'Deposit Balance: ',
                    style: kTextStyle.copyWith(color: kLightNeutralColor),
                    children: [
                      TextSpan(
                        text: '$currencySign $balance',
                        style: kTextStyle.copyWith(color: kNeutralColor),
                      ),
                    ],
                  ),
                ),
              ),
        centerTitle: true,
      ),
      body: Padding(
        padding: const EdgeInsets.only(top: 30.0),
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
              children: [
                const SizedBox(height: 20.0),
                _buildMenuItem(
                  icon: IconlyBold.profile,
                  iconColor: kPrimaryColor,
                  bgColor: const Color(0xFFE2EED8),
                  title: 'My Profile',
                  onTap: () async {
                    await const ClientProfileDetails().launch(context);
                    _loadProfile();
                  },
                ),
                _buildMenuItem(
                  icon: IconlyBold.chart,
                  iconColor: const Color(0xFF144BD6),
                  bgColor: const Color(0xFFE3EDFF),
                  title: 'Dashboard',
                  onTap: () => const ClientDashBoard().launch(context),
                ),
                Theme(
                  data: ThemeData(dividerColor: Colors.transparent),
                  child: ExpansionTile(
                    childrenPadding: EdgeInsets.zero,
                    tilePadding: const EdgeInsets.only(bottom: 10),
                    collapsedIconColor: kLightNeutralColor,
                    iconColor: kLightNeutralColor,
                    title: Text('Deposit', style: kTextStyle.copyWith(color: kNeutralColor)),
                    leading: Container(
                      padding: const EdgeInsets.all(10.0),
                      decoration: const BoxDecoration(shape: BoxShape.circle, color: Color(0xFFFFEFE0)),
                      child: const Icon(IconlyBold.wallet, color: Color(0xFFFF7A00)),
                    ),
                    trailing: const Icon(FeatherIcons.chevronDown, color: kLightNeutralColor),
                    children: [
                      ListTile(
                        visualDensity: const VisualDensity(vertical: -3),
                        contentPadding: const EdgeInsets.only(left: 60),
                        title: Text('Add Deposit', style: kTextStyle.copyWith(color: kNeutralColor)),
                        trailing: const Icon(FeatherIcons.chevronRight, color: kLightNeutralColor),
                        onTap: () => const AddDeposit().launch(context),
                      ),
                      ListTile(
                        visualDensity: const VisualDensity(vertical: -3),
                        contentPadding: const EdgeInsets.only(left: 60),
                        title: Text('Deposit History', style: kTextStyle.copyWith(color: kNeutralColor)),
                        trailing: const Icon(FeatherIcons.chevronRight, color: kLightNeutralColor),
                        onTap: () => const DepositHistory().launch(context),
                      ),
                    ],
                  ),
                ),
                _buildMenuItem(
                  icon: IconlyBold.ticketStar,
                  iconColor: const Color(0xFFFF3B30),
                  bgColor: const Color(0xFFFFE5E3),
                  title: 'Transaction',
                  onTap: () => const ClientTransaction().launch(context),
                ),
                _buildMenuItem(
                  icon: IconlyBold.heart,
                  iconColor: const Color(0xFF7E5BFF),
                  bgColor: const Color(0xFFE8E1FF),
                  title: 'Favorite',
                  onTap: () => const ClientFavList().launch(context),
                ),
                _buildMenuItem(
                  icon: IconlyBold.document,
                  iconColor: const Color(0xFF06AEF3),
                  bgColor: const Color(0xFFD0F1FF),
                  title: 'Seller Report',
                  onTap: () => const ClientReport().launch(context),
                ),
                _buildMenuItem(
                  icon: IconlyBold.setting,
                  iconColor: const Color(0xFFFF298C),
                  bgColor: const Color(0xFFFFDDED),
                  title: 'Setting',
                  onTap: () => const ClientSetting().launch(context),
                ),
                _buildMenuItem(
                  icon: IconlyBold.addUser,
                  iconColor: kPrimaryColor,
                  bgColor: const Color(0xFFE2EED8),
                  title: 'Invite Friends',
                  onTap: () => const ClientInvite().launch(context),
                ),
                _buildMenuItem(
                  icon: IconlyBold.danger,
                  iconColor: const Color(0xFF144BD6),
                  bgColor: const Color(0xFFE3EDFF),
                  title: 'Help & Support',
                  onTap: () {},
                ),
                _buildMenuItem(
                  icon: IconlyBold.logout,
                  iconColor: const Color(0xFFFF7A00),
                  bgColor: const Color(0xFFFFEFE0),
                  title: 'Log Out',
                  onTap: _handleLogout,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildMenuItem({
    required IconData icon,
    required Color iconColor,
    required Color bgColor,
    required String title,
    required VoidCallback onTap,
  }) {
    return ListTile(
      onTap: onTap,
      visualDensity: const VisualDensity(vertical: -3),
      horizontalTitleGap: 10,
      contentPadding: const EdgeInsets.only(bottom: 15),
      leading: Container(
        padding: const EdgeInsets.all(10.0),
        decoration: BoxDecoration(shape: BoxShape.circle, color: bgColor),
        child: Icon(icon, color: iconColor),
      ),
      title: Text(title, overflow: TextOverflow.ellipsis, maxLines: 1, style: kTextStyle.copyWith(color: kNeutralColor)),
      trailing: const Icon(FeatherIcons.chevronRight, color: kLightNeutralColor),
    );
  }
}
