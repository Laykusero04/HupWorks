import 'package:flutter/material.dart';
import 'package:freelancer/core/utils/support_chat_navigation.dart';
import 'package:freelancer/l10n/l10n.dart';
import 'package:freelancer/router/route_names.dart';
import 'package:freelancer/screen/widgets/verification_status_badge.dart';
import 'package:freelancer/services/auth_service.dart';
import 'package:freelancer/services/employer_verification_service.dart';
import 'package:freelancer/services/profile_service.dart';
import 'package:go_router/go_router.dart';
import 'package:nb_utils/nb_utils.dart';

import '../../widgets/constant.dart';
import '../../widgets/profile_menu_list_tile.dart';
import '../../widgets/profile_skeleton.dart';
import '../../widgets/shell_drawer_header.dart';
import '../../widgets/shell_tab_header.dart';
import '../client dashboard/client_dashboard.dart';
import '../client favourite/client_favourite_list.dart';
import '../client invite/client_invite.dart';
import '../client_setting/client_setting.dart';
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
      if (mounted) {
        setState(() => _isLoading = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(context.l10n.errorWithDetail('$e'))),
        );
      }
    }
  }

  Future<void> _handleLogout() async {
    final l10n = context.l10n;
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(l10n.logOutConfirmTitle),
        content: Text(l10n.logOutConfirmBody),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: Text(l10n.cancel,
                style: kTextStyle.copyWith(color: kSubTitleColor)),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: Text(l10n.logOut,
                style: kTextStyle.copyWith(
                    color: Colors.red, fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
    if (confirmed != true || !mounted) return;
    await AuthService.signOut();
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const ProfileTabSkeleton(persona: ShellPersona.client);
    }

    final l10n = context.l10n;
    final name = _profile?['name'] ?? l10n.userName;
    final profileImageUrl = _profile?['profile_image_url'] as String?;
    final rating = (_profile?['rating'] as num?)?.toDouble() ?? 0;
    final reviewCount = (_profile?['review_count'] as num?)?.toInt() ?? 0;
    final verificationStatus =
        EmployerVerificationService.statusFromProfile(_profile);

    return Material(
      color: kWhite,
      child: Column(
        children: [
          ShellDrawerHeader(
            persona: ShellPersona.client,
            name: name,
            imageUrl: profileImageUrl,
            rating: rating,
            reviewCount: reviewCount,
            verificationBadge: Padding(
              padding: const EdgeInsets.only(top: 6),
              child: VerificationStatusBadge(
                status: verificationStatus,
                score:
                    EmployerVerificationService.scoreFromProfile(_profile),
                compact: true,
                onTap: () async {
                  Navigator.pop(context);
                  await context.push(AppRoutes.clientProfileVerify);
                  if (mounted) _loadProfile(forceRefresh: true);
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
                    await const ClientProfileDetails().launch(context);
                    _loadProfile(forceRefresh: true);
                  },
                ),
                ProfileMenuListTile(
                  icon: Icons.verified_user_outlined,
                  title: l10n.employerVerification,
                  subtitle: l10n.trustScoreSubtitle(
                    EmployerVerificationService.scoreFromProfile(_profile)
                        .total,
                  ),
                  onTap: () async {
                    Navigator.pop(context);
                    await context.push(AppRoutes.clientProfileVerify);
                    if (mounted) _loadProfile(forceRefresh: true);
                  },
                ),
                ProfileMenuListTile(
                  icon: Icons.dashboard_outlined,
                  title: l10n.dashboard,
                  onTap: () => const ClientDashBoard().launch(context),
                ),
                ProfileMenuListTile(
                  icon: Icons.bookmark_border,
                  title: l10n.favourites,
                  onTap: () => const ClientFavList().launch(context),
                ),
                ProfileMenuListTile(
                  icon: Icons.assignment_outlined,
                  title: l10n.applications,
                  onTap: () {
                    Navigator.pop(context);
                    context.push(AppRoutes.clientApplications);
                  },
                ),
                ProfileMenuListTile(
                  icon: Icons.settings_outlined,
                  title: l10n.settings,
                  onTap: () async {
                    await const ClientSetting().launch(context);
                    _loadProfile(forceRefresh: true);
                  },
                ),
                ProfileMenuListTile(
                  icon: Icons.person_add_outlined,
                  title: l10n.inviteFriends,
                  onTap: () => const ClientInvite().launch(context),
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
