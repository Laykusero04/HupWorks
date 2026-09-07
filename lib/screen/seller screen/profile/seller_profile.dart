import 'package:flutter/material.dart';
import 'package:freelancer/core/utils/support_chat_navigation.dart';
import 'package:freelancer/l10n/l10n.dart';
import 'package:freelancer/screen/seller%20screen/profile/seller_identity_verification_screen.dart';
import 'package:freelancer/screen/seller%20screen/profile/seller_profile_details.dart';
import 'package:freelancer/screen/seller%20screen/seller%20dashboard/seller_dashboard.dart';
import 'package:freelancer/services/auth_service.dart';
import 'package:freelancer/services/profile_service.dart';
import 'package:freelancer/services/verification_service.dart';
import 'package:go_router/go_router.dart';
import 'package:nb_utils/nb_utils.dart';

import '../../widgets/constant.dart';
import '../../widgets/profile_menu_list_tile.dart';
import '../../widgets/profile_skeleton.dart';
import '../../widgets/shell_drawer_header.dart';
import '../../widgets/shell_tab_header.dart';
import '../../widgets/verification_status_badge.dart';
import '../favourite/seller_favourite_list.dart';
import '../report/seller_report.dart';
import '../setting/seller_invite.dart';
import '../setting/seller_setting.dart';

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

    final l10n = context.l10n;
    final name = _profile?['name'] ?? l10n.freelancerDefault;
    final profileImageUrl = _profile?['profile_image_url'] as String?;
    final rating = (_profile?['rating'] as num?)?.toDouble() ?? 0;
    final reviewCount = (_profile?['review_count'] as num?)?.toInt() ?? 0;
    final verificationStatus =
        VerificationService.statusFromProfile(_profile);

    return Material(
      color: kWhite,
      child: Column(
        children: [
          ShellDrawerHeader(
            persona: ShellPersona.seller,
            name: name,
            imageUrl: profileImageUrl,
            rating: rating,
            reviewCount: reviewCount,
            verificationBadge: Padding(
              padding: const EdgeInsets.only(top: 6),
              child: VerificationStatusBadge(
                status: verificationStatus,
                score: VerificationService.scoreFromProfile(_profile),
                compact: true,
                onTap: () async {
                  await const SellerIdentityVerificationScreen().launch(context);
                  _loadProfile(forceRefresh: true);
                },
              ),
            ),
          ),
          const Divider(height: 1),
          Expanded(
            child: ListView(
              padding: const EdgeInsets.symmetric(vertical: 8),
              children: [
                ProfileMenuListTile(
                  icon: Icons.person_outline,
                  title: l10n.myProfile,
                  onTap: () async {
                    await const SellerProfileDetails().launch(context);
                    _loadProfile(forceRefresh: true);
                  },
                ),
                ProfileMenuListTile(
                  icon: Icons.dashboard_outlined,
                  title: l10n.dashboard,
                  onTap: () => const SellerDashBoard().launch(context),
                ),
                ProfileMenuListTile(
                  icon: Icons.verified_user_outlined,
                  title: 'Identity verification',
                  subtitle: '${VerificationService.scoreFromProfile(_profile).total}/100 trust score',
                  onTap: () async {
                    await const SellerIdentityVerificationScreen().launch(context);
                    _loadProfile(forceRefresh: true);
                  },
                ),
                ProfileMenuListTile(
                  icon: Icons.schedule_outlined,
                  title: l10n.attendance,
                  onTap: () {
                    Navigator.pop(context);
                    context.push('/seller/attendance');
                  },
                ),
                ProfileMenuListTile(
                  icon: Icons.assignment_outlined,
                  title: l10n.myApplications,
                  onTap: () {
                    Navigator.pop(context);
                    context.push('/seller/applications');
                  },
                ),
                ProfileMenuListTile(
                  icon: Icons.bookmark_border,
                  title: l10n.favourites,
                  onTap: () => const SellerFavList().launch(context),
                ),
                ProfileMenuListTile(
                  icon: Icons.description_outlined,
                  title: l10n.report,
                  onTap: () => const SellerReport().launch(context),
                ),
                ProfileMenuListTile(
                  icon: Icons.settings_outlined,
                  title: l10n.settings,
                  onTap: () async {
                    await const SellerSetting().launch(context);
                    _loadProfile(forceRefresh: true);
                  },
                ),
                ProfileMenuListTile(
                  icon: Icons.person_add_outlined,
                  title: l10n.inviteFriends,
                  onTap: () => const SellerInvite().launch(context),
                ),
                ProfileMenuListTile(
                  icon: Icons.help_outline,
                  title: l10n.helpSupport,
                  onTap: () {
                    Navigator.pop(context);
                    openSupportChat(context);
                  },
                ),
                ProfileMenuListTile(
                  icon: Icons.logout,
                  title: l10n.logOut,
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
