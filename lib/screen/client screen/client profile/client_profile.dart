import 'package:flutter/material.dart';
import 'package:freelancer/core/utils/support_chat_navigation.dart';
import 'package:freelancer/l10n/l10n.dart';
import 'package:freelancer/services/auth_service.dart';
import 'package:freelancer/services/profile_service.dart';
import 'package:nb_utils/nb_utils.dart';

import '../../widgets/constant.dart';
import '../../widgets/profile_menu_list_tile.dart';
import '../../widgets/profile_skeleton.dart';
import '../../widgets/shell_drawer_header.dart';
import '../../widgets/shell_tab_header.dart';
import '../client dashboard/client_dashboard.dart';
import '../client invite/client_invite.dart';
import '../client report/client_report.dart';
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
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _handleLogout() async {
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
                  icon: Icons.dashboard_outlined,
                  title: l10n.dashboard,
                  onTap: () => const ClientDashBoard().launch(context),
                ),
                ProfileMenuListTile(
                  icon: Icons.description_outlined,
                  title: l10n.sellerReport,
                  onTap: () => const ClientReport().launch(context),
                ),
                ProfileMenuListTile(
                  icon: Icons.settings_outlined,
                  title: l10n.settings,
                  onTap: () => const ClientSetting().launch(context),
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
