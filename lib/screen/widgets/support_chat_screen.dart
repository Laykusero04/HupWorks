import 'package:flutter/material.dart';
import 'package:flutter_tawkto/flutter_tawk.dart';
import 'package:freelancer/core/config/tawk_config.dart';
import 'package:freelancer/core/constants/support_presets.dart';
import 'package:freelancer/data/models/support_preset_model.dart';
import 'package:freelancer/services/auth_service.dart';
import 'package:freelancer/services/profile_service.dart';

import 'constant.dart';

class SupportChatScreen extends StatefulWidget {
  const SupportChatScreen({super.key});

  @override
  State<SupportChatScreen> createState() => _SupportChatScreenState();
}

class _SupportChatScreenState extends State<SupportChatScreen>
    with SingleTickerProviderStateMixin {
  late final TabController _tabController;
  Map<String, dynamic>? _profile;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _profile = ProfileService.peekCachedProfile();
    _loadProfile();
  }

  Future<void> _loadProfile() async {
    try {
      final profile = await ProfileService.getProfile();
      if (mounted && profile != null) {
        setState(() => _profile = profile);
      }
    } catch (_) {}
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  TawkVisitor? _buildVisitor() {
    final user = AuthService.currentUser;
    if (user == null) return null;

    final profile = _profile ?? ProfileService.peekCachedProfile();
    final rawName = (profile?['name'] as String?)?.trim() ??
        (user.userMetadata?['name'] as String?)?.trim();
    final role = (user.userMetadata?['role'] as String?)?.trim();

    String? displayName;
    if (rawName != null && rawName.isNotEmpty) {
      displayName = role != null && role.isNotEmpty ? '$rawName ($role)' : rawName;
    } else if (role != null && role.isNotEmpty) {
      displayName = role;
    }

    final email = user.email?.trim();

    if ((displayName == null || displayName.isEmpty) &&
        (email == null || email.isEmpty)) {
      return null;
    }

    return TawkVisitor(
      name: displayName,
      email: email,
    );
  }

  String? _userRole() {
    return AuthService.currentUser?.userMetadata?['role'] as String?;
  }

  @override
  Widget build(BuildContext context) {
    final link = TawkConfig.directChatLink;
    final chatConfigured = link != null;

    return Scaffold(
      backgroundColor: kDarkWhite,
      appBar: AppBar(
        backgroundColor: kDarkWhite,
        elevation: 0,
        iconTheme: const IconThemeData(color: kNeutralColor),
        title: Text(
          'Help & Support',
          style: kTextStyle.copyWith(
            color: kNeutralColor,
            fontWeight: FontWeight.bold,
          ),
        ),
        centerTitle: true,
        bottom: TabBar(
          controller: _tabController,
          labelColor: kPrimaryColor,
          unselectedLabelColor: kSubTitleColor,
          indicatorColor: kPrimaryColor,
          tabs: const [
            Tab(text: 'Common Questions'),
            Tab(text: 'Live Chat'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _SupportFaqTab(
            presets: SupportPresets.forRole(_userRole()),
            onChatTap: chatConfigured ? () => _tabController.animateTo(1) : null,
          ),
          chatConfigured ? _buildChat(link) : _buildMissingConfig(),
        ],
      ),
    );
  }

  Widget _buildMissingConfig() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.support_agent_outlined, size: 48, color: kSubTitleColor),
            const SizedBox(height: 16),
            Text(
              'Live chat is not configured yet.',
              textAlign: TextAlign.center,
              style: kTextStyle.copyWith(
                color: kNeutralColor,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Add TAWK_DIRECT_CHAT_LINK to your .env file '
              '(see .env.example). FAQ answers are still available in the first tab.',
              textAlign: TextAlign.center,
              style: kTextStyle.copyWith(color: kSubTitleColor),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildChat(String link) {
    return Tawk(
      directChatLink: link,
      visitor: _buildVisitor(),
      placeholder: const Center(
        child: CircularProgressIndicator(color: kPrimaryColor),
      ),
    );
  }
}

class _SupportFaqTab extends StatelessWidget {
  final List<SupportPreset> presets;
  final VoidCallback? onChatTap;

  const _SupportFaqTab({
    required this.presets,
    this.onChatTap,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Expanded(
          child: presets.isEmpty
              ? Center(
                  child: Text(
                    'No questions available yet.',
                    style: kTextStyle.copyWith(color: kSubTitleColor),
                  ),
                )
              : ListView.separated(
                  padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
                  itemCount: presets.length,
                  separatorBuilder: (_, __) => const SizedBox(height: 8),
                  itemBuilder: (context, index) {
                    final preset = presets[index];
                    return _FaqTile(preset: preset);
                  },
                ),
        ),
        if (onChatTap != null)
          SafeArea(
            top: false,
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
              child: SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: onChatTap,
                  icon: const Icon(Icons.chat_bubble_outline, color: kWhite),
                  label: Text(
                    'Still need help? Chat with us',
                    style: kTextStyle.copyWith(
                      color: kWhite,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: kPrimaryColor,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(40),
                    ),
                  ),
                ),
              ),
            ),
          ),
      ],
    );
  }
}

class _FaqTile extends StatelessWidget {
  final SupportPreset preset;

  const _FaqTile({required this.preset});

  @override
  Widget build(BuildContext context) {
    return Material(
      color: kWhite,
      borderRadius: BorderRadius.circular(12),
      clipBehavior: Clip.antiAlias,
      child: Theme(
        data: Theme.of(context).copyWith(dividerColor: Colors.transparent),
        child: ExpansionTile(
          tilePadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
          childrenPadding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
          iconColor: kPrimaryColor,
          collapsedIconColor: kSubTitleColor,
          title: Text(
            preset.question,
            style: kTextStyle.copyWith(
              color: kNeutralColor,
              fontWeight: FontWeight.w600,
              fontSize: 14,
            ),
          ),
          children: [
            Align(
              alignment: Alignment.centerLeft,
              child: Text(
                preset.answer,
                style: kTextStyle.copyWith(
                  color: kLightNeutralColor,
                  fontSize: 14,
                  height: 1.45,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
