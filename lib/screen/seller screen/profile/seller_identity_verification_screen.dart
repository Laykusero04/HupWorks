import 'dart:io';

import 'package:flutter/material.dart';
import 'package:freelancer/core/utils/profile_avatar_picker.dart';
import 'package:freelancer/l10n/l10n.dart';
import 'package:freelancer/screen/widgets/button_global.dart';
import 'package:freelancer/screen/widgets/constant.dart';
import 'package:freelancer/screen/widgets/verification_guideline_examples.dart';
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
    extends State<SellerIdentityVerificationScreen> {
  String _status = 'unverified';
  String? _rejectionReason;
  String? _submittedSelfieUrl;
  Map<String, dynamic>? _profile;
  File? _pickedSelfie;
  bool _loading = true;
  bool _submitting = false;

  @override
  void initState() {
    super.initState();
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
      });
    } catch (e) {
      if (mounted) {
        setState(() => _loading = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(context.l10n.errorWithDetail('$e'))),
        );
      }
    }
  }

  Future<void> _pickSelfie() async {
    final file = await ProfileAvatarPicker.pickImage(context);
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
        body: Center(child: CircularProgressIndicator(color: kPrimaryColor)),
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
                VerificationScoreCard(score: score, accent: kPrimaryColor),
                const SizedBox(height: 16),
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
                const SizedBox(height: 16),
                VerificationGuidelineExamples(
                  doAsset: 'images/verification/id_face_do.png',
                  dontAsset: 'images/verification/id_face_dont.png',
                  doLabel: l10n.idDoLabel,
                  dontLabel: l10n.idDontLabel,
                  tips: [
                    l10n.idTipHoldNextToFace,
                    l10n.idTipGoodLighting,
                    l10n.idTipFourCorners,
                    l10n.idTipNoAccessories,
                  ],
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
                GestureDetector(
                  onTap: _submitting ? null : _pickSelfie,
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
                ),
              ],
            ),
          ),
        ),
      ),
      bottomNavigationBar: ButtonGlobalWithoutIcon(
        buttontext: submitLabel,
        buttonDecoration: kButtonDecoration.copyWith(
          color: (_submitting || !hasNewPick) ? kLightNeutralColor : kPrimaryColor,
          borderRadius: BorderRadius.circular(30),
        ),
        onPressed: (_submitting || !hasNewPick) ? null : _submit,
        buttonTextColor: kWhite,
      ),
    );
  }
}
