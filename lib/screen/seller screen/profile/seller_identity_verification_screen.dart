import 'dart:io';
import 'package:freelancer/core/widgets/empty_state_widget.dart';
import 'package:freelancer/core/widgets/loading_widget.dart';

import 'package:flutter/material.dart';
import 'package:freelancer/core/guide/guide_anchor.dart';
import 'package:freelancer/core/guide/guide_host.dart';
import 'package:freelancer/core/guide/guide_info_button.dart';
import 'package:freelancer/core/guide/guide_step.dart';
import 'package:freelancer/core/utils/profile_avatar_picker.dart';
import 'package:freelancer/l10n/l10n.dart';
import 'package:freelancer/screen/widgets/button_global.dart';
import 'package:freelancer/screen/widgets/constant.dart';
import 'package:freelancer/screen/widgets/verification_score_card.dart';
import 'package:freelancer/screen/widgets/verification_status_badge.dart';
import 'package:freelancer/services/profile_service.dart';
import 'package:freelancer/services/verification_service.dart';
import 'package:nb_utils/nb_utils.dart';

/// View / replace identity verification selfie (seller).
class SellerIdentityVerificationScreen extends StatefulWidget {
  const SellerIdentityVerificationScreen({super.key});

  @override
  State<SellerIdentityVerificationScreen> createState() =>
      _SellerIdentityVerificationScreenState();
}

class _SellerIdentityVerificationScreenState
    extends State<SellerIdentityVerificationScreen>
    with GuideHost<SellerIdentityVerificationScreen> {
  // Guide targets (long-lived, one widget each).
  final GlobalKey _guideScoreKey = GlobalKey();
  final GlobalKey _guideStatusKey = GlobalKey();
  final GlobalKey _guideSelfieKey = GlobalKey();
  final GlobalKey _guideSubmitKey = GlobalKey();

  @override
  String get guideScreenId => 'seller_identity_verification';
  @override
  String get guideRole => 'seller';
  @override
  int get guideVersion => 1;

  /// Only the loaded form has targets (the loading and error branches have no
  /// app bar). Not ready while submitting or while the photo picker or camera
  /// is open: the guide only ever covers the stable form.
  @override
  bool get guideDataReady =>
      !_loading && !_loadFailed && _routeSettled && !_submitting && !_picking;
  @override
  String get guideSkipLabel => context.l10n.guideSkip;
  @override
  String get guideNextLabel => context.l10n.guideNext;
  @override
  String get guideDoneLabel => context.l10n.guideDone;

  bool _routeSettled = false;
  bool _picking = false;

  void _awaitRouteSettled() {
    if (!mounted) return;
    final anim = ModalRoute.of(context)?.animation;
    if (anim == null || anim.isCompleted) {
      _settleRoute();
      return;
    }
    void listener(AnimationStatus st) {
      if (st == AnimationStatus.completed) {
        anim.removeStatusListener(listener);
        _settleRoute();
      }
    }

    anim.addStatusListener(listener);
  }

  void _settleRoute() {
    if (!mounted) return;
    setState(() => _routeSettled = true);
    scheduleGuide();
  }

  GuideAnchor _anchor(GlobalKey key, String title, String desc) => GuideAnchor(
        key: key,
        scope: guideScope,
        title: title,
        description: desc,
      );

  @override
  List<GuideStep> buildGuideSteps(BuildContext context) {
    final l10n = context.l10n;
    return [
      GuideStep(
          key: _guideScoreKey,
          title: l10n.guideIdentityScoreTitle,
          description: l10n.guideIdentityScoreDesc),
      GuideStep(
          key: _guideStatusKey,
          title: l10n.guideIdentityStatusTitle,
          description: l10n.guideIdentityStatusDesc),
      GuideStep(
          key: _guideSelfieKey,
          title: l10n.guideIdentitySelfieTitle,
          description: l10n.guideIdentitySelfieDesc,
          enableAutoScroll: true),
      GuideStep(
          key: _guideSubmitKey,
          title: l10n.guideIdentitySubmitTitle,
          description: l10n.guideIdentitySubmitDesc,
          targetNearBottom: true),
    ];
  }
  String _status = 'unverified';
  String? _rejectionReason;
  String? _submittedSelfieUrl;
  Map<String, dynamic>? _profile;
  File? _pickedSelfie;
  bool _loading = true;
  bool _loadFailed = false;
  bool _submitting = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _awaitRouteSettled());
    _load();
  }

  Future<void> _load() async {
    try {
      final profile = await ProfileService.getProfile(forceRefresh: true);
      final row = await VerificationService.getOwnVerification();
      String? signedUrl;
      if (row != null) {
        try {
          signedUrl = await VerificationService.createOwnSelfieSignedUrl();
        } catch (_) {
          signedUrl = null;
        }
      }
      if (!mounted) return;
      setState(() {
        _status = VerificationService.identityStatusFromProfile(profile);
        _rejectionReason = profile?['verification_rejection_reason'] as String? ??
            row?['rejection_reason'] as String?;
        _profile = profile;
        _submittedSelfieUrl = signedUrl;
        _loading = false;
        _loadFailed = false;
      });
      scheduleGuide();
    } catch (_) {
      if (mounted) {
        setState(() {
          _loading = false;
          _loadFailed = true;
        });
        scheduleGuide();
      }
    }
  }

  Future<void> _pickSelfie() async {
    setState(() => _picking = true);
    final File? file;
    try {
      file = await ProfileAvatarPicker.pickImage(context);
    } finally {
      if (mounted) setState(() => _picking = false);
    }
    if (file == null || !mounted) return;
    setState(() => _pickedSelfie = file);
  }

  Future<void> _submit() async {
    final l10n = context.l10n;
    if (_pickedSelfie == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(l10n.pleaseUploadIdSelfie)),
      );
      return;
    }
    setState(() => _submitting = true);
    try {
      await VerificationService.submitIdSelfie(_pickedSelfie!);
      await ProfileService.getProfile(forceRefresh: true);
      String? signedUrl;
      try {
        signedUrl = await VerificationService.createOwnSelfieSignedUrl();
      } catch (_) {}
      if (!mounted) return;
      setState(() {
        _status = 'pending';
        _submitting = false;
        _pickedSelfie = null;
        _submittedSelfieUrl = signedUrl;
        _rejectionReason = null;
        _profile = {
          ...?_profile,
          'verification_status': 'pending',
          'verification_rejection_reason': null,
        };
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(l10n.submittedPendingAdminReview)),
      );
    } catch (e) {
      if (!mounted) return;
      setState(() => _submitting = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(context.l10n.errorWithDetail('$e'))),
      );
    }
  }

  ImageProvider? get _previewImage {
    if (_pickedSelfie != null) return FileImage(_pickedSelfie!);
    final url = _submittedSelfieUrl;
    if (url != null && url.isNotEmpty) return NetworkImage(url);
    return null;
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    if (_loading) {
      return const Scaffold(
        body: const LoadingWidget(),
      );
    }

    if (_loadFailed) {
      return Scaffold(
        backgroundColor: kDarkWhite,
        appBar: AppBar(
          backgroundColor: kDarkWhite,
          elevation: 0,
          iconTheme: const IconThemeData(color: kNeutralColor),
          title: Text(
            l10n.identityVerification,
            style: kTextStyle.copyWith(
              color: kNeutralColor,
              fontWeight: FontWeight.bold,
            ),
          ),
          centerTitle: true,
        ),
        body: EmptyStateWidget(
          message: l10n.somethingWentWrong,
          actionLabel: l10n.retry,
          onAction: () {
            setState(() => _loading = true);
            _load();
          },
        ),
      );
    }

    final preview = _previewImage;
    final hasSubmitted = _submittedSelfieUrl != null;
    final hasNewPick = _pickedSelfie != null;
    final score = VerificationService.scoreFromProfile(_profile);
    final badgeStatus = VerificationService.statusFromProfile(_profile);
    final submitLabel = _submitting
        ? l10n.submitting
        : (hasSubmitted || _status == 'pending' || _status == 'verified')
            ? l10n.updateAndSubmitForReview
            : l10n.submitForReview;

    return guideBackScope(Scaffold(
      backgroundColor: kDarkWhite,
      appBar: AppBar(
        backgroundColor: kDarkWhite,
        elevation: 0,
        iconTheme: const IconThemeData(color: kNeutralColor),
        title: Text(
          l10n.identityVerification,
          style: kTextStyle.copyWith(
            color: kNeutralColor,
            fontWeight: FontWeight.bold,
          ),
        ),
        centerTitle: true,
        actions: [GuideInfoButton(host: this)],
      ),
      body: Padding(
        padding: const EdgeInsets.only(top: 12),
        child: Container(
          width: context.width(),
          padding: const EdgeInsets.all(20),
          decoration: const BoxDecoration(
            color: kWhite,
            borderRadius: BorderRadius.vertical(top: Radius.circular(30)),
          ),
          child: SingleChildScrollView(
            physics: const BouncingScrollPhysics(),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                VerificationScoreCard(
                  score: score,
                  accent: kPrimaryColor,
                  guideAnchor: _anchor(_guideScoreKey,
                      l10n.guideIdentityScoreTitle, l10n.guideIdentityScoreDesc),
                ),
                const SizedBox(height: 16),
                GuideAnchor.wrap(
                  _anchor(_guideStatusKey, l10n.guideIdentityStatusTitle,
                      l10n.guideIdentityStatusDesc),
                  Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                Center(child: VerificationStatusBadge(status: badgeStatus)),
                if (_status == 'rejected' &&
                    (_rejectionReason?.trim().isNotEmpty ?? false)) ...[
                  const SizedBox(height: 12),
                  Text(
                    _rejectionReason!,
                    style: kTextStyle.copyWith(color: kSubTitleColor),
                  ),
                ],
                if (_status == 'pending') ...[
                  const SizedBox(height: 12),
                  Text(
                    l10n.faceIdPendingHint,
                    style: kTextStyle.copyWith(color: kSubTitleColor, fontSize: 13),
                  ),
                ],
                if (_status == 'verified') ...[
                  const SizedBox(height: 12),
                  Text(
                    l10n.faceIdVerifiedHint,
                    style: kTextStyle.copyWith(color: kSubTitleColor, fontSize: 13),
                  ),
                ],
                  ],
                )),
                const SizedBox(height: 20),
                Text(
                  l10n.selfieWithId,
                  style: kTextStyle.copyWith(
                    color: kNeutralColor,
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  l10n.selfieWithIdHint,
                  style: kTextStyle.copyWith(color: kSubTitleColor, fontSize: 13),
                ),
                const SizedBox(height: 24),
                Text(
                  hasSubmitted ? l10n.yourSubmittedPhoto : l10n.uploadIdFaceSelfie,
                  style: kTextStyle.copyWith(
                    color: kNeutralColor,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 10),
                GuideAnchor.wrap(
                  _anchor(_guideSelfieKey, l10n.guideIdentitySelfieTitle,
                      l10n.guideIdentitySelfieDesc),
                  GestureDetector(
                  onTap: (_submitting || _picking) ? null : _pickSelfie,
                  child: Container(
                    height: 220,
                    width: double.infinity,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: kBorderColorTextField, width: 2),
                      color: kDarkWhite,
                      image: preview != null
                          ? DecorationImage(image: preview, fit: BoxFit.cover)
                          : null,
                    ),
                    child: preview == null
                        ? Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              const Icon(Icons.add_a_photo_outlined,
                                  size: 40, color: kPrimaryColor),
                              const SizedBox(height: 8),
                              Text(
                                l10n.uploadIdFaceSelfie,
                                style: kTextStyle.copyWith(color: kPrimaryColor),
                              ),
                            ],
                          )
                        : Align(
                            alignment: Alignment.bottomCenter,
                            child: Container(
                              width: double.infinity,
                              padding: const EdgeInsets.symmetric(vertical: 10),
                              decoration: BoxDecoration(
                                color: Colors.black.withValues(alpha: 0.55),
                                borderRadius: const BorderRadius.vertical(
                                  bottom: Radius.circular(10),
                                ),
                              ),
                              child: Text(
                                hasNewPick
                                    ? l10n.newPhotoSelectedTapToChange
                                    : l10n.tapToChangePhoto,
                                textAlign: TextAlign.center,
                                style: kTextStyle.copyWith(
                                  color: kWhite,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ),
                          ),
                  ),
                )),
              ],
            ),
          ),
        ),
      ),
      bottomNavigationBar: ButtonGlobalWithoutIcon(
        guideAnchor: _anchor(_guideSubmitKey, l10n.guideIdentitySubmitTitle,
            l10n.guideIdentitySubmitDesc),
        buttontext: submitLabel,
        buttonDecoration: kButtonDecoration.copyWith(
          color: (_submitting || !hasNewPick) ? kLightNeutralColor : kPrimaryColor,
          borderRadius: BorderRadius.circular(30),
        ),
        onPressed: (_submitting || !hasNewPick) ? null : _submit,
        buttonTextColor: kWhite,
      ),
    ));
  }
}
