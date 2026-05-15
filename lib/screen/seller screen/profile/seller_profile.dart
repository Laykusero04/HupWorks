import 'package:flutter/material.dart';
import 'package:flutter_feather_icons/flutter_feather_icons.dart';
import 'package:flutter_iconly/flutter_iconly.dart';
import 'package:freelancer/screen/seller%20screen/profile/seller_profile_details.dart';
import 'package:freelancer/services/auth_service.dart';
import 'package:freelancer/services/profile_service.dart';
import 'package:nb_utils/nb_utils.dart';

import '../../widgets/app_header.dart';
import '../../widgets/constant.dart';
import '../../widgets/shell_tab_header.dart';
import '../../widgets/profile_menu_list_tile.dart';
import '../../widgets/profile_rating_summary.dart';
import '../../widgets/profile_skeleton.dart';
import '../add payment method/seller_add_payment_method.dart';
import '../applications/seller_applications.dart';
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
    _loadProfile();
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
      return const ProfileTabSkeleton();
    }

    final name = _profile?['name'] ?? 'Seller';
    final balance = _profile?['balance'] ?? 0;
    final profileImageUrl = _profile?['profile_image_url'];
    final rating = (_profile?['rating'] as num?)?.toDouble() ?? 0;
    final reviewCount = (_profile?['review_count'] as num?)?.toInt() ?? 0;

    final sheetTint = Theme.of(context).scaffoldBackgroundColor;
    final brandGlow = Theme.of(context).colorScheme.primary.withValues(alpha: 0.08);
    final primary = Theme.of(context).colorScheme.primary;

    return Scaffold(
      backgroundColor: sheetTint,
      body: Column(
        children: [
            ShellTabHeader(
              persona: ShellPersona.seller,
              title: name,
              leading: AppHeaderAvatar(
                imageUrl: profileImageUrl as String?,
                fallbackAsset: 'images/profile1.png',
                onBrandGradient: true,
                size: 48,
              ),
              subtitle: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  RichText(
                    text: TextSpan(
                      text: 'Balance: ',
                      style: kTextStyle.copyWith(
                        color: Colors.white.withValues(alpha: 0.88),
                        fontSize: 12,
                      ),
                      children: [
                        TextSpan(
                          text: '$currencySign $balance',
                          style: kTextStyle.copyWith(
                            color: const Color(0xFFB8D4FF),
                            fontWeight: FontWeight.w700,
                            fontSize: 12,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 4),
                  ProfileRatingSummary(
                    rating: rating,
                    reviewCount: reviewCount,
                    compact: true,
                    onBrandGradient: true,
                  ),
                ],
              ),
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
                      color: brandGlow,
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
                          await const SellerProfileDetails().launch(context);
                          _loadProfile(forceRefresh: true);
                        },
                      ),
                      ProfileMenuListTile(
                        icon: IconlyBold.paper,
                        title: 'My Applications',
                        accent: ProfileMenuAccent.secondary,
                        onTap: () => const SellerApplications().launch(context),
                      ),
                      ProfileMenuListTile(
                        icon: IconlyBold.wallet,
                        title: 'Payment Methods',
                        accent: ProfileMenuAccent.secondary,
                        onTap: () => const SellerAddPaymentMethod().launch(context),
                      ),
                      Theme(
                        data: ThemeData(dividerColor: Colors.transparent),
                        child: Container(
                          margin: const EdgeInsets.only(bottom: 10),
                          decoration: BoxDecoration(
                            color: kDarkWhite,
                            borderRadius: BorderRadius.circular(14),
                            border: Border.all(color: primary.withValues(alpha: 0.22)),
                          ),
                          child: ExpansionTile(
                            childrenPadding: EdgeInsets.zero,
                            tilePadding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                            collapsedIconColor: primary,
                            iconColor: primary,
                            title: Text(
                              'Withdrawals',
                              style: kTextStyle.copyWith(color: kNeutralColor, fontWeight: FontWeight.w600),
                            ),
                            leading: Container(
                              padding: const EdgeInsets.all(10.0),
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                color: primary.withValues(alpha: 0.14),
                              ),
                              child: Icon(IconlyBold.download, color: primary),
                            ),
                            trailing: const Icon(FeatherIcons.chevronDown, color: kLightNeutralColor),
                            children: [
                              ListTile(
                                visualDensity: const VisualDensity(vertical: -3),
                                contentPadding: const EdgeInsets.only(left: 56, right: 12),
                                title: Text('Withdraw Money', style: kTextStyle.copyWith(color: kNeutralColor)),
                                trailing: const Icon(FeatherIcons.chevronRight, color: kLightNeutralColor),
                                onTap: () => const SellerWithdrawMoney().launch(context),
                              ),
                              ListTile(
                                visualDensity: const VisualDensity(vertical: -3),
                                contentPadding: const EdgeInsets.only(left: 56, right: 12),
                                title: Text('Withdraw History', style: kTextStyle.copyWith(color: kNeutralColor)),
                                trailing: const Icon(FeatherIcons.chevronRight, color: kLightNeutralColor),
                                onTap: () => const SellerWithDrawHistory().launch(context),
                              ),
                            ],
                          ),
                        ),
                      ),
                      ProfileMenuListTile(
                        icon: IconlyBold.heart,
                        title: 'Favorite',
                        accent: ProfileMenuAccent.secondary,
                        onTap: () => const SellerFavList().launch(context),
                      ),
                      ProfileMenuListTile(
                        icon: IconlyBold.ticketStar,
                        title: 'Transaction',
                        accent: ProfileMenuAccent.accent,
                        onTap: () => const SellerTransaction().launch(context),
                      ),
                      ProfileMenuListTile(
                        icon: IconlyBold.document,
                        title: 'Report',
                        accent: ProfileMenuAccent.secondary,
                        onTap: () => const SellerReport().launch(context),
                      ),
                      ProfileMenuListTile(
                        icon: IconlyBold.setting,
                        title: 'Setting',
                        accent: ProfileMenuAccent.secondary,
                        onTap: () => const SellerSetting().launch(context),
                      ),
                      ProfileMenuListTile(
                        icon: IconlyBold.addUser,
                        title: 'Invite Friends',
                        accent: ProfileMenuAccent.primary,
                        onTap: () => const SellerInvite().launch(context),
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
    );
  }
}
