import 'package:flutter/material.dart';
import 'package:flutter_feather_icons/flutter_feather_icons.dart';
import 'package:flutter_iconly/flutter_iconly.dart';
import 'package:freelancer/services/profile_service.dart';
import 'package:nb_utils/nb_utils.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../widgets/app_header.dart';
import '../../widgets/constant.dart';
import '../../widgets/profile_menu_list_tile.dart';
import '../../widgets/profile_rating_summary.dart';
import '../../widgets/profile_skeleton.dart';
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

  Future<void> _handleLogout() async {
    await Supabase.instance.client.auth.signOut();
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const ProfileTabSkeleton();
    }

    final name = _profile?['name'] ?? 'User';
    final balance = _profile?['balance'] ?? 0;
    final profileImageUrl = _profile?['profile_image_url'];
    final rating = (_profile?['rating'] as num?)?.toDouble() ?? 0;
    final reviewCount = (_profile?['review_count'] as num?)?.toInt() ?? 0;

    return Scaffold(
      backgroundColor: kDarkWhite,
      body: SafeArea(
        bottom: false,
        child: Column(
          children: [
            AppHeader(
              title: name,
              subtitle: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  RichText(
                    text: TextSpan(
                      text: 'Deposit Balance: ',
                      style: kTextStyle.copyWith(color: kLightNeutralColor, fontSize: 12),
                      children: [
                        TextSpan(
                          text: '$currencySign $balance',
                          style: kTextStyle.copyWith(color: kPrimaryColor, fontWeight: FontWeight.w700, fontSize: 12),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 4),
                  ProfileRatingSummary(
                    rating: rating,
                    reviewCount: reviewCount,
                    compact: true,
                  ),
                ],
              ),
              leading: AppHeaderAvatar(imageUrl: profileImageUrl as String?),
            ),
            Expanded(
              child: Container(
                padding: const EdgeInsets.only(left: 16.0, right: 16.0, top: 8),
                width: context.width(),
                decoration: BoxDecoration(
                  color: kWhite,
                  borderRadius: const BorderRadius.only(
                    topLeft: Radius.circular(28.0),
                    topRight: Radius.circular(28.0),
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: kPrimaryColor.withValues(alpha: 0.08),
                      blurRadius: 24,
                      offset: const Offset(0, -6),
                    ),
                  ],
                ),
                child: SingleChildScrollView(
                  physics: const BouncingScrollPhysics(),
                  child: Column(
                    children: [
                      const SizedBox(height: 16.0),
                      ProfileMenuListTile(
                        icon: IconlyBold.profile,
                        title: 'My Profile',
                        accent: ProfileMenuAccent.primary,
                        onTap: () async {
                          await const ClientProfileDetails().launch(context);
                          _loadProfile();
                        },
                      ),
                      ProfileMenuListTile(
                        icon: IconlyBold.chart,
                        title: 'Dashboard',
                        accent: ProfileMenuAccent.secondary,
                        onTap: () => const ClientDashBoard().launch(context),
                      ),
                      Theme(
                        data: ThemeData(dividerColor: Colors.transparent),
                        child: Container(
                          margin: const EdgeInsets.only(bottom: 10),
                          decoration: BoxDecoration(
                            color: kDarkWhite,
                            borderRadius: BorderRadius.circular(14),
                            border: Border.all(color: kSecondaryColor.withValues(alpha: 0.2)),
                          ),
                          child: ExpansionTile(
                            childrenPadding: EdgeInsets.zero,
                            tilePadding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                            collapsedIconColor: kSecondaryColor,
                            iconColor: kSecondaryColor,
                            title: Text('Deposit', style: kTextStyle.copyWith(color: kNeutralColor, fontWeight: FontWeight.w600)),
                            leading: Container(
                              padding: const EdgeInsets.all(10.0),
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                color: kSecondaryColor.withValues(alpha: 0.14),
                              ),
                              child: const Icon(IconlyBold.wallet, color: kSecondaryColor),
                            ),
                            trailing: const Icon(FeatherIcons.chevronDown, color: kLightNeutralColor),
                            children: [
                              ListTile(
                                visualDensity: const VisualDensity(vertical: -3),
                                contentPadding: const EdgeInsets.only(left: 56, right: 12),
                                title: Text('Add Deposit', style: kTextStyle.copyWith(color: kNeutralColor)),
                                trailing: const Icon(FeatherIcons.chevronRight, color: kLightNeutralColor),
                                onTap: () => const AddDeposit().launch(context),
                              ),
                              ListTile(
                                visualDensity: const VisualDensity(vertical: -3),
                                contentPadding: const EdgeInsets.only(left: 56, right: 12),
                                title: Text('Deposit History', style: kTextStyle.copyWith(color: kNeutralColor)),
                                trailing: const Icon(FeatherIcons.chevronRight, color: kLightNeutralColor),
                                onTap: () => const DepositHistory().launch(context),
                              ),
                            ],
                          ),
                        ),
                      ),
                      ProfileMenuListTile(
                        icon: IconlyBold.ticketStar,
                        title: 'Transaction',
                        accent: ProfileMenuAccent.accent,
                        onTap: () => const ClientTransaction().launch(context),
                      ),
                      ProfileMenuListTile(
                        icon: IconlyBold.heart,
                        title: 'Favorite',
                        accent: ProfileMenuAccent.secondary,
                        onTap: () => const ClientFavList().launch(context),
                      ),
                      ProfileMenuListTile(
                        icon: IconlyBold.document,
                        title: 'Seller Report',
                        accent: ProfileMenuAccent.secondary,
                        onTap: () => const ClientReport().launch(context),
                      ),
                      ProfileMenuListTile(
                        icon: IconlyBold.setting,
                        title: 'Setting',
                        accent: ProfileMenuAccent.secondary,
                        onTap: () => const ClientSetting().launch(context),
                      ),
                      ProfileMenuListTile(
                        icon: IconlyBold.addUser,
                        title: 'Invite Friends',
                        accent: ProfileMenuAccent.primary,
                        onTap: () => const ClientInvite().launch(context),
                      ),
                      ProfileMenuListTile(
                        icon: IconlyBold.danger,
                        title: 'Help & Support',
                        accent: ProfileMenuAccent.secondary,
                        onTap: () {},
                      ),
                      ProfileMenuListTile(
                        icon: IconlyBold.logout,
                        title: 'Log Out',
                        accent: ProfileMenuAccent.accent,
                        onTap: _handleLogout,
                      ),
                      const SizedBox(height: 16),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
