import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_iconly/flutter_iconly.dart';
import 'package:freelancer/core/constants/support_contact.dart';
import 'package:freelancer/core/locale/locale_controller.dart';
import 'package:freelancer/core/locale/locale_scope.dart';
import 'package:freelancer/core/notifications/push_notification_prefs.dart';
import 'package:freelancer/core/utils/profile_avatar_picker.dart';
import 'package:freelancer/core/utils/profile_image.dart';
import 'package:freelancer/core/utils/support_chat_navigation.dart';
import 'package:freelancer/l10n/l10n.dart';
import 'package:freelancer/router/route_names.dart';
import 'package:freelancer/services/auth_service.dart';
import 'package:freelancer/services/employer_verification_service.dart';
import 'package:freelancer/services/local_notification_service.dart';
import 'package:freelancer/services/profile_service.dart';
import 'package:freelancer/services/verification_service.dart';
import 'package:go_router/go_router.dart';
import 'package:nb_utils/nb_utils.dart';

import 'constant.dart';
import 'platform_rules_screen.dart';

class SettingsScreen extends StatefulWidget {
  final Widget languagePage;
  final Widget policyPage;
  final Widget aboutPage;

  const SettingsScreen({
    Key? key,
    required this.languagePage,
    required this.policyPage,
    required this.aboutPage,
  }) : super(key: key);

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  bool _pushEnabled = PushNotificationPrefs.enabled;
  bool _pushBusy = false;
  String? _profileImageUrl;
  String? _role;
  String _photoStatus = 'unverified';
  String? _photoRejectionReason;
  String _verificationStatus = 'unverified';
  bool _uploadingPhoto = false;
  bool _deletingAccount = false;

  @override
  void initState() {
    super.initState();
    _loadProfile();
    _loadPushPref();
  }

  Future<void> _loadPushPref() async {
    final enabled = await PushNotificationPrefs.isEnabled();
    if (mounted) setState(() => _pushEnabled = enabled);
  }

  Future<void> _setPushEnabled(bool value) async {
    if (_pushBusy) return;
    setState(() {
      _pushBusy = true;
      _pushEnabled = value;
    });
    try {
      await PushNotificationPrefs.setEnabled(value);
      if (value) {
        final granted =
            await LocalNotificationService.instance.requestPermissions();
        if (!granted && mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(context.l10n.pushNotificationsPermissionDenied),
            ),
          );
        }
      } else {
        await LocalNotificationService.instance.cancelAll();
      }
    } catch (e) {
      if (mounted) {
        setState(() => _pushEnabled = !value);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(context.l10n.errorWithDetail('$e'))),
        );
      }
    } finally {
      if (mounted) setState(() => _pushBusy = false);
    }
  }

  void _applyProfile(Map<String, dynamic>? profile) {
    final role = (profile?['role'] as String?)?.trim().toLowerCase();
    final photoStatus =
        VerificationService.profilePhotoStatusFromProfile(profile);
    final verificationStatus = role == 'seller'
        ? VerificationService.statusFromProfile(profile)
        : EmployerVerificationService.statusFromProfile(profile);
    setState(() {
      _profileImageUrl =
          ProfileImage.normalize(profile?['profile_image_url'] as String?);
      _role = role ?? AuthService.cachedRole;
      _photoStatus = photoStatus;
      _photoRejectionReason =
          profile?['profile_photo_rejection_reason'] as String?;
      _verificationStatus = verificationStatus;
    });
  }

  Future<void> _loadProfile() async {
    try {
      final cached = ProfileService.peekCachedProfile();
      if (cached != null && mounted) {
        _applyProfile(cached);
      }
      final profile = await ProfileService.getProfile(forceRefresh: true);
      if (!mounted) return;
      _applyProfile(profile);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(context.l10n.errorWithDetail('$e'))),
        );
      }
    }
  }

  String _photoStatusLabel(AppLocalizations l10n) {
    switch (_photoStatus) {
      case 'pending':
        return l10n.settingsPhotoStatusPending;
      case 'rejected':
        final reason = _photoRejectionReason?.trim();
        if (reason != null && reason.isNotEmpty) {
          return '${l10n.settingsPhotoStatusRejected}: $reason';
        }
        return l10n.settingsPhotoStatusRejected;
      case 'verified':
        return l10n.settingsPhotoStatusVerified;
      default:
        return l10n.settingsPhotoStatusUnverified;
    }
  }

  String _verificationStatusLabel(AppLocalizations l10n) {
    switch (_verificationStatus) {
      case 'pending':
        return l10n.statusPending;
      case 'rejected':
        return l10n.statusRejected;
      case 'verified':
        return l10n.statusVerified;
      default:
        return l10n.settingsPhotoStatusUnverified;
    }
  }

  Future<void> _changePhoto() async {
    final file = await ProfileAvatarPicker.pickAndCrop(context);
    if (file == null || !mounted) return;
    setState(() => _uploadingPhoto = true);
    try {
      final url = await ProfileService.uploadProfileImage(file);
      if (!mounted) return;
      setState(() {
        _profileImageUrl = url;
        _photoStatus = 'pending';
        _photoRejectionReason = null;
        _uploadingPhoto = false;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(context.l10n.profileUpdatedShort)),
      );
      await _loadProfile();
    } catch (e) {
      if (!mounted) return;
      setState(() => _uploadingPhoto = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(context.l10n.errorWithDetail('$e'))),
      );
    }
  }

  Future<void> _openVerification() async {
    final role = _role ?? AuthService.cachedRole;
    final route = role == 'seller'
        ? AppRoutes.sellerProfileVerify
        : AppRoutes.clientProfileVerify;
    await context.push(route);
    if (mounted) await _loadProfile();
  }

  Future<void> _confirmDeleteAccount() async {
    if (_deletingAccount) return;
    final l10n = context.l10n;
    final controller = TextEditingController();
    final confirmed = await showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (ctx) {
        return AlertDialog(
          title: Text(l10n.deleteAccountConfirmTitle),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(l10n.deleteAccountConfirmBody),
              const SizedBox(height: 16),
              TextField(
                controller: controller,
                autofocus: true,
                decoration: InputDecoration(
                  hintText: l10n.deleteAccountConfirmHint,
                  border: const OutlineInputBorder(),
                ),
                textCapitalization: TextCapitalization.characters,
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx, false),
              child: Text(
                l10n.cancel,
                style: kTextStyle.copyWith(color: kSubTitleColor),
              ),
            ),
            TextButton(
              onPressed: () {
                if (controller.text.trim() != 'DELETE') {
                  ScaffoldMessenger.of(ctx).showSnackBar(
                    SnackBar(content: Text(l10n.deleteAccountMismatch)),
                  );
                  return;
                }
                Navigator.pop(ctx, true);
              },
              child: Text(
                l10n.deleteAccountConfirmAction,
                style: kTextStyle.copyWith(
                  color: Colors.red,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ],
        );
      },
    );
    controller.dispose();
    if (confirmed != true || !mounted) return;

    setState(() => _deletingAccount = true);
    try {
      await AuthService.deleteAccount();
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(l10n.deleteAccountSuccess)),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(l10n.errorWithDetail('$e'))),
      );
    } finally {
      if (mounted) setState(() => _deletingAccount = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final localeController = LocaleScope.of(context);
    final currentLanguage =
        LocaleController.displayName(l10n, localeController.locale.languageCode);
    final isSeller = (_role ?? AuthService.cachedRole) == 'seller';
    final verificationTitle =
        isSeller ? l10n.identityVerification : l10n.employerVerification;

    return Scaffold(
      backgroundColor: kDarkWhite,
      appBar: AppBar(
        backgroundColor: kDarkWhite,
        elevation: 0,
        iconTheme: const IconThemeData(color: kNeutralColor),
        title: Text(
          l10n.settings,
          style: kTextStyle.copyWith(color: kNeutralColor, fontWeight: FontWeight.bold),
        ),
        centerTitle: true,
      ),
      body: Padding(
        padding: const EdgeInsets.only(top: 20),
        child: Container(
          padding: const EdgeInsets.only(
            left: 15.0,
            right: 15.0,
          ),
          width: context.width(),
          decoration: const BoxDecoration(
            color: kWhite,
            borderRadius: BorderRadius.only(
              topLeft: Radius.circular(30.0),
              topRight: Radius.circular(30.0),
            ),
          ),
          child: SingleChildScrollView(
            child: Column(
              children: [
                const SizedBox(height: 24.0),
                ListTile(
                  onTap: _uploadingPhoto ? null : _changePhoto,
                  visualDensity: const VisualDensity(vertical: -2),
                  horizontalTitleGap: 12,
                  contentPadding: const EdgeInsets.only(bottom: 8),
                  leading: Stack(
                    alignment: Alignment.center,
                    children: [
                      CircleAvatar(
                        radius: 26,
                        backgroundColor: kDarkWhite,
                        backgroundImage: ProfileImage.provider(_profileImageUrl),
                      ),
                      if (_uploadingPhoto)
                        const SizedBox(
                          width: 28,
                          height: 28,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        ),
                    ],
                  ),
                  title: Text(
                    l10n.selectProfileImage,
                    overflow: TextOverflow.ellipsis,
                    maxLines: 1,
                    style: kTextStyle.copyWith(
                      color: kNeutralColor,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  subtitle: Text(
                    '${l10n.settingsProfilePhotoHint}\n${_photoStatusLabel(l10n)}',
                    maxLines: 3,
                    overflow: TextOverflow.ellipsis,
                    style: kTextStyle.copyWith(color: kSubTitleColor, fontSize: 12),
                  ),
                  isThreeLine: true,
                  trailing: const Icon(Icons.chevron_right, color: kLightNeutralColor),
                ),
                ListTile(
                  onTap: _openVerification,
                  visualDensity: const VisualDensity(vertical: -2),
                  horizontalTitleGap: 12,
                  contentPadding: const EdgeInsets.only(bottom: 12),
                  leading: Container(
                    padding: const EdgeInsets.all(10.0),
                    decoration: const BoxDecoration(
                      shape: BoxShape.circle,
                      color: Color(0xFFE8F8F0),
                    ),
                    child: const Icon(
                      Icons.verified_user_outlined,
                      color: Color(0xFF0D9488),
                    ),
                  ),
                  title: Text(
                    verificationTitle,
                    overflow: TextOverflow.ellipsis,
                    maxLines: 1,
                    style: kTextStyle.copyWith(
                      color: kNeutralColor,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  subtitle: Text(
                    '${l10n.settingsVerificationSubtitle}\n${_verificationStatusLabel(l10n)}',
                    maxLines: 3,
                    overflow: TextOverflow.ellipsis,
                    style: kTextStyle.copyWith(color: kSubTitleColor, fontSize: 12),
                  ),
                  isThreeLine: true,
                  trailing: const Icon(Icons.chevron_right, color: kLightNeutralColor),
                ),
                const Divider(height: 1),
                const SizedBox(height: 8),
                ListTile(
                  visualDensity: const VisualDensity(vertical: -3),
                  horizontalTitleGap: 10,
                  contentPadding: const EdgeInsets.only(bottom: 15),
                  leading: Container(
                    padding: const EdgeInsets.all(10.0),
                    decoration: const BoxDecoration(
                      shape: BoxShape.circle,
                      color: Color(0xFFE7FFED),
                    ),
                    child: const Icon(
                      IconlyBold.notification,
                      color: kPrimaryColor,
                    ),
                  ),
                  title: Text(
                    l10n.pushNotifications,
                    overflow: TextOverflow.ellipsis,
                    maxLines: 1,
                    style: kTextStyle.copyWith(color: kNeutralColor),
                  ),
                  trailing: CupertinoSwitch(
                    value: _pushEnabled,
                    onChanged: _pushBusy ? null : _setPushEnabled,
                  ),
                ),
                ListTile(
                  onTap: () => widget.languagePage.launch(context),
                  visualDensity: const VisualDensity(vertical: -3),
                  horizontalTitleGap: 10,
                  contentPadding: const EdgeInsets.only(bottom: 15),
                  leading: Container(
                    padding: const EdgeInsets.all(10.0),
                    decoration: const BoxDecoration(
                      shape: BoxShape.circle,
                      color: Color(0xFFE3EDFF),
                    ),
                    child: const Icon(
                      Icons.translate,
                      color: kSecondaryColor,
                    ),
                  ),
                  title: Text(
                    l10n.language,
                    overflow: TextOverflow.ellipsis,
                    maxLines: 1,
                    style: kTextStyle.copyWith(color: kNeutralColor),
                  ),
                  trailing: Text(
                    currentLanguage,
                    overflow: TextOverflow.ellipsis,
                    maxLines: 1,
                    style: kTextStyle.copyWith(color: kSubTitleColor),
                  ),
                ),
                ListTile(
                  onTap: () => widget.policyPage.launch(context),
                  visualDensity: const VisualDensity(vertical: -3),
                  horizontalTitleGap: 10,
                  contentPadding: const EdgeInsets.only(bottom: 15),
                  leading: Container(
                    padding: const EdgeInsets.all(10.0),
                    decoration: const BoxDecoration(
                      shape: BoxShape.circle,
                      color: Color(0xFFFFEFE0),
                    ),
                    child: const Icon(
                      IconlyBold.danger,
                      color: Color(0xFFFF7A00),
                    ),
                  ),
                  title: Text(
                    l10n.privacyPolicy,
                    overflow: TextOverflow.ellipsis,
                    maxLines: 1,
                    style: kTextStyle.copyWith(color: kNeutralColor),
                  ),
                ),
                ListTile(
                  onTap: () => widget.aboutPage.launch(context),
                  visualDensity: const VisualDensity(vertical: -3),
                  horizontalTitleGap: 10,
                  contentPadding: const EdgeInsets.only(bottom: 15),
                  leading: Container(
                    padding: const EdgeInsets.all(10.0),
                    decoration: const BoxDecoration(
                      shape: BoxShape.circle,
                      color: Color(0xFFE8E1FF),
                    ),
                    child: const Icon(
                      IconlyBold.shieldDone,
                      color: Color(0xFF7E5BFF),
                    ),
                  ),
                  title: Text(
                    l10n.aboutUs,
                    overflow: TextOverflow.ellipsis,
                    maxLines: 1,
                    style: kTextStyle.copyWith(color: kNeutralColor),
                  ),
                ),
                ListTile(
                  onTap: () => const PlatformRulesScreen().launch(context),
                  visualDensity: const VisualDensity(vertical: -3),
                  horizontalTitleGap: 10,
                  contentPadding: const EdgeInsets.only(bottom: 15),
                  leading: Container(
                    padding: const EdgeInsets.all(10.0),
                    decoration: const BoxDecoration(
                      shape: BoxShape.circle,
                      color: Color(0xFFE8FFF6),
                    ),
                    child: const Icon(
                      Icons.route_outlined,
                      color: Color(0xFF0D9488),
                    ),
                  ),
                  title: Text(
                    l10n.platformRulesTitle,
                    overflow: TextOverflow.ellipsis,
                    maxLines: 1,
                    style: kTextStyle.copyWith(color: kNeutralColor),
                  ),
                  subtitle: Text(
                    l10n.platformRulesSubtitle,
                    overflow: TextOverflow.ellipsis,
                    maxLines: 1,
                    style: kTextStyle.copyWith(color: kSubTitleColor, fontSize: 12),
                  ),
                ),
                ListTile(
                  onTap: () => openSupportChat(context),
                  visualDensity: const VisualDensity(vertical: -3),
                  horizontalTitleGap: 10,
                  contentPadding: const EdgeInsets.only(bottom: 15),
                  leading: Container(
                    padding: const EdgeInsets.all(10.0),
                    decoration: const BoxDecoration(
                      shape: BoxShape.circle,
                      color: Color(0xFFE7F5FF),
                    ),
                    child: const Icon(
                      Icons.support_agent_outlined,
                      color: Color(0xFF0B7DD6),
                    ),
                  ),
                  title: Text(
                    l10n.helpSupport,
                    overflow: TextOverflow.ellipsis,
                    maxLines: 1,
                    style: kTextStyle.copyWith(color: kNeutralColor),
                  ),
                ),
                ListTile(
                  onTap: () => openSupportEmail(context),
                  visualDensity: const VisualDensity(vertical: -3),
                  horizontalTitleGap: 10,
                  contentPadding: const EdgeInsets.only(bottom: 15),
                  leading: Container(
                    padding: const EdgeInsets.all(10.0),
                    decoration: const BoxDecoration(
                      shape: BoxShape.circle,
                      color: Color(0xFFFFF4E5),
                    ),
                    child: const Icon(
                      Icons.email_outlined,
                      color: Color(0xFFE67E22),
                    ),
                  ),
                  title: Text(
                    l10n.supportEmail,
                    overflow: TextOverflow.ellipsis,
                    maxLines: 1,
                    style: kTextStyle.copyWith(color: kNeutralColor),
                  ),
                  subtitle: Text(
                    SupportContact.email,
                    overflow: TextOverflow.ellipsis,
                    maxLines: 1,
                    style: kTextStyle.copyWith(color: kSubTitleColor, fontSize: 12),
                  ),
                ),
                const Divider(height: 24),
                ListTile(
                  onTap: _deletingAccount ? null : _confirmDeleteAccount,
                  visualDensity: const VisualDensity(vertical: -3),
                  horizontalTitleGap: 10,
                  contentPadding: const EdgeInsets.only(bottom: 24),
                  leading: Container(
                    padding: const EdgeInsets.all(10.0),
                    decoration: const BoxDecoration(
                      shape: BoxShape.circle,
                      color: Color(0xFFFFE8E8),
                    ),
                    child: _deletingAccount
                        ? const SizedBox(
                            width: 22,
                            height: 22,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : const Icon(
                            Icons.delete_forever_outlined,
                            color: Colors.red,
                          ),
                  ),
                  title: Text(
                    l10n.deleteAccount,
                    overflow: TextOverflow.ellipsis,
                    maxLines: 1,
                    style: kTextStyle.copyWith(
                      color: Colors.red,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  subtitle: Text(
                    l10n.deleteAccountSubtitle,
                    overflow: TextOverflow.ellipsis,
                    maxLines: 2,
                    style: kTextStyle.copyWith(color: kSubTitleColor, fontSize: 12),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
