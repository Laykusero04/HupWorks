import 'package:flutter/material.dart';
import 'package:freelancer/core/utils/support_chat_navigation.dart';
import 'package:freelancer/screen/seller%20screen/profile/seller_profile_details.dart';
import 'package:freelancer/services/auth_service.dart';
import 'package:freelancer/services/profile_service.dart';
import 'package:go_router/go_router.dart';
import 'package:nb_utils/nb_utils.dart';

import '../../widgets/constant.dart';
import '../../widgets/profile_menu_list_tile.dart';
import '../../widgets/profile_skeleton.dart';
import '../../widgets/shell_drawer_header.dart';
import '../../widgets/shell_tab_header.dart';
import '../add payment method/seller_add_payment_method.dart';
import '../favourite/seller_favourite_list.dart';
import '../report/seller_report.dart';
import '../setting/seller_invite.dart';
import '../setting/seller_setting.dart';
import '../transaction/seller_transaction.dart';
import '../withdraw_money/seller_withdraw_history.dart';
import '../withdraw_money/seller_withdraw_money.dart';

class SellerProfile extends StatefulWidget {
  const SellerProfile({Key? key}) : super(key: key);

  @override
  State<SellerProfile> createState() => _SellerProfileState();
}

class _SellerProfileState extends State<SellerProfile> {
  Map<String, dynamic>? _profile;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    final cached = ProfileService.peekCachedProfile();
    if (cached != null) {
      _profile = cached;
      _isLoading = false;
    }
    _loadProfile(forceRefresh: true);
  }

  Future<void> _loadProfile({bool forceRefresh = false}) async {
    try {
      final profile = await ProfileService.getProfile(forceRefresh: forceRefresh);
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
    await AuthService.signOut();
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const ProfileTabSkeleton(persona: ShellPersona.seller);
    }

    final name = _profile?['name'] ?? 'Seller';
    final balance = _profile?['balance'] ?? 0;
    final profileImageUrl = _profile?['profile_image_url'] as String?;
    final rating = (_profile?['rating'] as num?)?.toDouble() ?? 0;
    final reviewCount = (_profile?['review_count'] as num?)?.toInt() ?? 0;

    return Material(
      color: kWhite,
      child: Column(
        children: [
          ShellDrawerHeader(
            persona: ShellPersona.seller,
            name: name,
            imageUrl: profileImageUrl,
            fallbackAsset: 'images/profile1.png',
            balanceLabel: 'Balance: $currencySign$balance',
            rating: rating,
            reviewCount: reviewCount,
          ),
          const Divider(height: 1),
          Expanded(
            child: ListView(
              padding: const EdgeInsets.symmetric(vertical: 8),
              children: [
                ProfileMenuListTile(
                  icon: Icons.person_outline,
                  title: 'My Profile',
                  onTap: () async {
                    await const SellerProfileDetails().launch(context);
                    _loadProfile(forceRefresh: true);
                  },
                ),
                ProfileMenuListTile(
                  icon: Icons.schedule_outlined,
                  title: 'Attendance',
                  onTap: () {
                    Navigator.pop(context);
                    context.push('/seller/attendance');
                  },
                ),
                ProfileMenuListTile(
                  icon: Icons.assignment_outlined,
                  title: 'My Applications',
                  onTap: () {
                    Navigator.pop(context);
                    context.push('/seller/applications');
                  },
                ),
                ProfileMenuListTile(
                  icon: Icons.payment_outlined,
                  title: 'Payment Methods',
                  onTap: () => const SellerAddPaymentMethod().launch(context),
                ),
                ExpansionTile(
                  leading: const Icon(Icons.download_outlined, color: kNeutralColor),
                  title: Text('Withdrawals', style: kTextStyle.copyWith(color: kNeutralColor)),
                  children: [
                    ListTile(
                      title: Text('Withdraw Money', style: kTextStyle.copyWith(color: kNeutralColor)),
                      onTap: () => const SellerWithdrawMoney().launch(context),
                    ),
                    ListTile(
                      title: Text('Withdraw History', style: kTextStyle.copyWith(color: kNeutralColor)),
                      onTap: () => const SellerWithDrawHistory().launch(context),
                    ),
                  ],
                ),
                ProfileMenuListTile(
                  icon: Icons.favorite_border,
                  title: 'Favorite',
                  onTap: () => const SellerFavList().launch(context),
                ),
                ProfileMenuListTile(
                  icon: Icons.receipt_long_outlined,
                  title: 'Transaction',
                  onTap: () => const SellerTransaction().launch(context),
                ),
                ProfileMenuListTile(
                  icon: Icons.description_outlined,
                  title: 'Report',
                  onTap: () => const SellerReport().launch(context),
                ),
                ProfileMenuListTile(
                  icon: Icons.settings_outlined,
                  title: 'Setting',
                  onTap: () => const SellerSetting().launch(context),
                ),
                ProfileMenuListTile(
                  icon: Icons.person_add_outlined,
                  title: 'Invite Friends',
                  onTap: () => const SellerInvite().launch(context),
                ),
                ProfileMenuListTile(
                  icon: Icons.help_outline,
                  title: 'Help & Support',
                  onTap: () {
                    Navigator.pop(context);
                    openSupportChat(context);
                  },
                ),
                ProfileMenuListTile(
                  icon: Icons.logout,
                  title: 'Log Out',
                  onTap: _handleLogout,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
