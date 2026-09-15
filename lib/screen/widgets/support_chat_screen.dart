import 'package:flutter/material.dart';
import 'package:flutter_tawkto/flutter_tawk.dart';
import 'package:freelancer/core/config/tawk_config.dart';
import 'package:freelancer/core/constants/support_contact.dart';
import 'package:freelancer/core/constants/support_presets.dart';
import 'package:freelancer/core/utils/app_logger.dart';
import 'package:freelancer/core/utils/support_chat_navigation.dart';
import 'package:freelancer/data/models/support_preset_model.dart';
import 'package:freelancer/services/auth_service.dart';
import 'package:freelancer/l10n/l10n.dart';
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
    } catch (e, st) {
      AppLogger.error('SupportChat.loadProfile', e, st);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(context.l10n.supportProfileLoadFailed),
          ),
        );
      }
    }
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
    final role = _userRole();

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

  /// Prefer [profiles.role] (cache / loaded profile), not JWT metadata.
  String? _userRole() {
    final fromProfile = (_profile?['role'] as String?)?.trim() ??
        (ProfileService.peekCachedProfile()?['role'] as String?)?.trim();
    if (fromProfile != null && fromProfile.isNotEmpty) {
      return fromProfile.toLowerCase();
    }
    return AuthService.cachedRole;
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final lang = Localizations.localeOf(context).languageCode;
    final link = TawkConfig.directChatLinkFor(lang);
    final chatConfigured = link != null;

    return Scaffold(
      backgroundColor: kDarkWhite,
      // Tawk WebView owns the keyboard; Scaffold resize double-lifts the page.
      resizeToAvoidBottomInset: false,
      appBar: AppBar(
        backgroundColor: kDarkWhite,
        elevation: 0,
        iconTheme: const IconThemeData(color: kNeutralColor),
        title: Text(
          l10n.helpSupport,
          style: kTextStyle.copyWith(
            color: kNeutralColor,
            fontWeight: FontWeight.bold,
          ),
        ),
        centerTitle: true,
        actions: [
          IconButton(
            tooltip: l10n.supportEmail,
            onPressed: () => openSupportEmail(context),
            icon: const Icon(Icons.email_outlined),
          ),
        ],
        bottom: TabBar(
          controller: _tabController,
          labelColor: kPrimaryColor,
          unselectedLabelColor: kSubTitleColor,
          indicatorColor: kPrimaryColor,
          tabs: [
            Tab(text: l10n.supportCommonQuestions),
            Tab(text: l10n.supportLiveChat),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _SupportFaqTab(
            presets: SupportPresets.forRole(l10n, _userRole()),
            onChatTap: chatConfigured ? () => _tabController.animateTo(1) : null,
          ),
          chatConfigured ? _buildChat(link, lang) : _buildMissingConfig(),
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
              context.l10n.supportLiveChatNotConfigured,
              textAlign: TextAlign.center,
              style: kTextStyle.copyWith(
                color: kNeutralColor,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              context.l10n.supportTawkEnvHint,
              textAlign: TextAlign.center,
              style: kTextStyle.copyWith(color: kSubTitleColor),
            ),
            const SizedBox(height: 20),
            OutlinedButton.icon(
              onPressed: () => openSupportEmail(context),
              icon: const Icon(Icons.email_outlined),
              label: Text(SupportContact.email),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildChat(String link, String languageCode) {
    // Clear the system nav/gesture bar when the keyboard is closed. When the
    // keyboard is open, leave 0 — Tawk already lifts its composer; padding
    // here would show as a second empty bar ("two screens").
    final mq = MediaQuery.of(context);
    final keyboardOpen = mq.viewInsets.bottom > 0;
    final bottomInset = keyboardOpen ? 0.0 : mq.viewPadding.bottom;

    return Padding(
      padding: EdgeInsets.only(bottom: bottomInset),
      child: Tawk(
        // Reload WebView when app language changes (each link = its own widget).
        key: ValueKey('$languageCode|$link'),
        directChatLink: link,
        visitor: _buildVisitor(),
        placeholder: const Center(
          child: CircularProgressIndicator(color: kPrimaryColor),
        ),
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
    final l10n = context.l10n;
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
          child: Material(
            color: kWhite,
            borderRadius: BorderRadius.circular(12),
            child: ListTile(
              onTap: () => openSupportEmail(context),
              leading: const Icon(Icons.email_outlined, color: kPrimaryColor),
              title: Text(
                l10n.supportEmail,
                style: kTextStyle.copyWith(
                  color: kNeutralColor,
                  fontWeight: FontWeight.w600,
                ),
              ),
              subtitle: Text(
                l10n.supportEmailSubtitle(SupportContact.email),
                style: kTextStyle.copyWith(color: kSubTitleColor, fontSize: 13),
              ),
              trailing: const Icon(Icons.open_in_new, size: 18, color: kLightNeutralColor),
            ),
          ),
        ),
        Expanded(
          child: presets.isEmpty
              ? Center(
                  child: Text(
                    l10n.supportNoQuestionsYet,
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
                    l10n.supportStillNeedHelp,
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
