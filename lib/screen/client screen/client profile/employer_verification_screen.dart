import 'dart:io';
import 'package:freelancer/core/widgets/empty_state_widget.dart';
import 'package:freelancer/core/widgets/loading_widget.dart';

import 'package:flutter/material.dart';
import 'package:freelancer/core/guide/guide_anchor.dart';
import 'package:freelancer/core/guide/guide_host.dart';
import 'package:freelancer/core/guide/guide_info_button.dart';
import 'package:freelancer/core/guide/guide_step.dart';
import 'package:freelancer/core/utils/employer_standing.dart';
import 'package:freelancer/core/utils/profile_avatar_picker.dart';
import 'package:freelancer/l10n/l10n.dart';
import 'package:freelancer/screen/widgets/button_global.dart';
import 'package:freelancer/screen/widgets/constant.dart';
import 'package:freelancer/screen/widgets/verification_score_card.dart';
import 'package:freelancer/screen/widgets/verification_status_badge.dart';
import 'package:freelancer/services/employer_verification_service.dart';
import 'package:freelancer/services/profile_service.dart';
import 'package:freelancer/services/verification_service.dart';
import 'package:nb_utils/nb_utils.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

/// Employer verification: score card + choose personal ID or company docs.
class EmployerVerificationScreen extends StatefulWidget {
  const EmployerVerificationScreen({super.key});

  @override
  State<EmployerVerificationScreen> createState() =>
      _EmployerVerificationScreenState();
}

class _EmployerVerificationScreenState extends State<EmployerVerificationScreen>
    with GuideHost<EmployerVerificationScreen> {
  String _upgradeType = EmployerVerificationService.verifyTypePersonalId;
  String? _storedVerifyType;
  String _status = 'unverified';
  String? _rejectionReason;
  String? _submittedDocUrl;
  Map<String, dynamic>? _profile;
  File? _pickedFile;
  bool _loading = true;
  bool _loadFailed = false;
  bool _submitting = false;
  int _completedPaidHires = 0;

  final GlobalKey _guideScoreKey = GlobalKey();
  final GlobalKey _guideHistoryKey = GlobalKey();
  final GlobalKey _guidePathKey = GlobalKey();
  final GlobalKey _guideUploadKey = GlobalKey();
  final GlobalKey _guideSubmitKey = GlobalKey();

  @override
  String get guideScreenId => 'client_employer_verification';
  @override
  String get guideRole => 'client';
  @override
  int get guideVersion => 1;

  /// False while loading, after a failed load (no content) and while submitting.
  @override
  bool get guideDataReady =>
      _routeSettled && !_loading && !_loadFailed && !_submitting;

  @override
  String get guideSkipLabel => context.l10n.guideSkip;
  @override
  String get guideNextLabel => context.l10n.guideNext;
  @override
  String get guideDoneLabel => context.l10n.guideDone;

  /// True once the push animation finished: targets are at their final place.
  bool _routeSettled = false;

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

  bool get _isCompanyPath =>
      _upgradeType == EmployerVerificationService.verifyTypeCompany;

  @override
  List<GuideStep> buildGuideSteps(BuildContext context) {
    final l10n = context.l10n;
    return [
      GuideStep(
          key: _guideScoreKey,
          title: l10n.guideEmpVerifScoreTitle,
          description: l10n.guideEmpVerifScoreDesc),
      GuideStep(
          key: _guideHistoryKey,
          title: l10n.guideEmpVerifHistoryTitle,
          description: l10n.guideEmpVerifHistoryDesc),
      GuideStep(
          key: _guidePathKey,
          title: l10n.guideEmpVerifPathTitle,
          description: l10n.guideEmpVerifPathDesc),
      GuideStep(
          key: _guideUploadKey,
          title: _isCompanyPath
              ? l10n.guideEmpVerifUploadCompanyTitle
              : l10n.guideEmpVerifUploadPersonalTitle,
          description: _isCompanyPath
              ? l10n.guideEmpVerifUploadCompanyDesc
              : l10n.guideEmpVerifUploadPersonalDesc,
          enableAutoScroll: true),
      GuideStep(
          key: _guideSubmitKey,
          title: l10n.guideEmpVerifSubmitTitle,
          description: l10n.guideEmpVerifSubmitDesc,
          targetNearBottom: true),
    ];
  }

  final _companyNameController = TextEditingController();
  final _registrationController = TextEditingController();
  final _websiteController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _load();
    WidgetsBinding.instance.addPostFrameCallback((_) => _awaitRouteSettled());
  }

  @override
  void dispose() {
    _companyNameController.dispose();
    _registrationController.dispose();
    _websiteController.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    try {
      final profile = await ProfileService.getProfile(forceRefresh: true);
      final row = await EmployerVerificationService.getOwnVerification();
      String? signedUrl;
      if (row != null) {
        try {
          signedUrl = await EmployerVerificationService.createOwnDocSignedUrl();
        } catch (_) {
          signedUrl = null;
        }
      }

      var paidHires = 0;
      final uid = Supabase.instance.client.auth.currentUser?.id;
      if (uid != null) {
        try {
          final rows = await Supabase.instance.client
              .from('orders')
              .select('id')
              .eq('client_id', uid)
              .eq('status', 'completed')
              .not('payment_received_at', 'is', null);
          paidHires = (rows as List).length;
        } catch (_) {
          paidHires = 0;
        }
      }

      if (!mounted) return;
      setState(() {
        _profile = profile;
        _status = VerificationService.identityStatusFromProfile(profile);
        _rejectionReason =
            profile?['verification_rejection_reason'] as String? ??
                row?['rejection_reason'] as String?;
        _submittedDocUrl = signedUrl;
        _completedPaidHires = paidHires;
        _loadFailed = false;
        if (row != null) {
          _storedVerifyType = (row['verify_type'] as String?) ??
              EmployerVerificationService.verifyTypePersonalId;
          _upgradeType = _storedVerifyType!;
          _companyNameController.text = (row['company_name'] as String?) ??
              (profile?['company_name'] as String?) ??
              '';
          _registrationController.text =
              (row['company_registration_number'] as String?) ??
                  (profile?['company_registration_number'] as String?) ??
                  '';
          _websiteController.text = (row['company_website'] as String?) ??
              (profile?['company_website'] as String?) ??
              '';
        } else {
          _storedVerifyType = null;
          _companyNameController.text =
              (profile?['company_name'] as String?) ?? '';
          _registrationController.text =
              (profile?['company_registration_number'] as String?) ?? '';
          _websiteController.text =
              (profile?['company_website'] as String?) ?? '';
        }
        _loading = false;
      });
      scheduleGuide();
    } catch (_) {
      if (mounted) {
        setState(() {
          _loading = false;
          _loadFailed = true;
        });
      }
    }
  }

  Future<void> _pickFile() async {
    final file = await ProfileAvatarPicker.pickImage(context);
    if (file == null || !mounted) return;
    setState(() => _pickedFile = file);
  }

  Future<void> _submit() async {
    final l10n = context.l10n;
    if (_pickedFile == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            _upgradeType == EmployerVerificationService.verifyTypeCompany
                ? l10n.pleaseUploadCompanyDoc
                : l10n.pleaseUploadIdSelfie,
          ),
        ),
      );
      return;
    }

    if (_upgradeType == EmployerVerificationService.verifyTypeCompany &&
        _companyNameController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(l10n.pleaseEnterCompanyName)),
      );
      return;
    }

    setState(() => _submitting = true);
    try {
      if (_upgradeType == EmployerVerificationService.verifyTypeCompany) {
        await EmployerVerificationService.submitCompanyDoc(
          imageFile: _pickedFile!,
          companyName: _companyNameController.text,
          registrationNumber: _registrationController.text,
          website: _websiteController.text,
        );
      } else {
        await EmployerVerificationService.submitPersonalId(_pickedFile!);
      }
      await ProfileService.getProfile(forceRefresh: true);
      String? signedUrl;
      try {
        signedUrl = await EmployerVerificationService.createOwnDocSignedUrl();
      } catch (_) {}
      if (!mounted) return;
      setState(() {
        _status = 'pending';
        _submitting = false;
        _pickedFile = null;
        _submittedDocUrl = signedUrl;
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
    if (_pickedFile != null) return FileImage(_pickedFile!);
    final stored = _storedVerifyType;
    if (stored == null || stored != _upgradeType) return null;
    final url = _submittedDocUrl;
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
            l10n.employerVerification,
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
    final hasSubmitted = _submittedDocUrl != null;
    final hasNewPick = _pickedFile != null;
    final score = EmployerVerificationService.scoreFromProfile(_profile);
    final badgeStatus = EmployerVerificationService.statusFromProfile(_profile);
    final standing = EmployerStandingResolver.resolve(
      completedPaidHires: _completedPaidHires,
    );
    final isCompany =
        _upgradeType == EmployerVerificationService.verifyTypeCompany;
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
          l10n.employerVerification,
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
                  guideAnchor: _anchor(
                      _guideScoreKey,
                      l10n.guideEmpVerifScoreTitle,
                      l10n.guideEmpVerifScoreDesc),
                ),
                const SizedBox(height: 16),
                Center(child: VerificationStatusBadge(status: badgeStatus)),
                const SizedBox(height: 12),
                GuideAnchor.wrap(
                  _anchor(_guideHistoryKey, l10n.guideEmpVerifHistoryTitle,
                      l10n.guideEmpVerifHistoryDesc),
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: kDarkWhite,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: kBorderColorTextField),
                    ),
                    child: Row(
                      children: [
                        const Icon(Icons.handshake_outlined,
                            color: kPrimaryColor),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                standing.label(l10n),
                                style: kTextStyle.copyWith(
                                  fontWeight: FontWeight.w700,
                                  color: kNeutralColor,
                                ),
                              ),
                              Text(
                                l10n.employerStandingHint(_completedPaidHires),
                                style: kTextStyle.copyWith(
                                  color: kSubTitleColor,
                                  fontSize: 12,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                if (_status == 'rejected' &&
                    (_rejectionReason?.trim().isNotEmpty ?? false)) ...[
                  const SizedBox(height: 12),
                  Text(
                    _rejectionReason!,
                    style: kTextStyle.copyWith(color: kSubTitleColor),
                  ),
                ],
                const SizedBox(height: 16),
                Text(
                  l10n.employerVerifyUpgradeHint,
                  style: kTextStyle.copyWith(
                    color: kSubTitleColor,
                    fontSize: 13,
                  ),
                ),
                const SizedBox(height: 16),
                Text(
                  l10n.chooseVerificationPath,
                  style: kTextStyle.copyWith(
                    color: kNeutralColor,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 10),
                GuideAnchor.wrap(
                  _anchor(_guidePathKey, l10n.guideEmpVerifPathTitle,
                      l10n.guideEmpVerifPathDesc),
                  SegmentedButton<String>(
                    segments: [
                      ButtonSegment(
                        value: EmployerVerificationService.verifyTypePersonalId,
                        label: Text(l10n.personalIdPath),
                        icon: const Icon(Icons.badge_outlined, size: 18),
                      ),
                      ButtonSegment(
                        value: EmployerVerificationService.verifyTypeCompany,
                        label: Text(l10n.companyDocPath),
                        icon: const Icon(Icons.business_outlined, size: 18),
                      ),
                    ],
                    selected: {_upgradeType},
                    onSelectionChanged: _submitting
                        ? null
                        : (s) => setState(() {
                              _upgradeType = s.first;
                              _pickedFile = null;
                            }),
                  ),
                ),
                const SizedBox(height: 20),
                if (isCompany) ...[
                  Text(
                    l10n.companyDetails,
                    style: kTextStyle.copyWith(
                      color: kNeutralColor,
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                    ),
                  ),
                  const SizedBox(height: 10),
                  AppTextField(
                    textFieldType: TextFieldType.NAME,
                    controller: _companyNameController,
                    decoration: kInputDecoration.copyWith(
                      labelText: l10n.companyName,
                      hintText: l10n.companyNameHint,
                    ),
                  ),
                  const SizedBox(height: 12),
                  AppTextField(
                    textFieldType: TextFieldType.NAME,
                    controller: _registrationController,
                    decoration: kInputDecoration.copyWith(
                      labelText: l10n.companyRegistrationOptional,
                      hintText: l10n.companyRegistrationHint,
                    ),
                  ),
                  const SizedBox(height: 12),
                  AppTextField(
                    textFieldType: TextFieldType.NAME,
                    controller: _websiteController,
                    decoration: kInputDecoration.copyWith(
                      labelText: l10n.companyWebsiteOptional,
                      hintText: 'https://',
                    ),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    l10n.companyDocUploadTitle,
                    style: kTextStyle.copyWith(
                      color: kNeutralColor,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    l10n.companyDocUploadHint,
                    style: kTextStyle.copyWith(
                      color: kSubTitleColor,
                      fontSize: 13,
                    ),
                  ),
                ] else ...[
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
                    style: kTextStyle.copyWith(
                      color: kSubTitleColor,
                      fontSize: 13,
                    ),
                  ),
                ],
                const SizedBox(height: 24),
                Text(
                  hasSubmitted
                      ? l10n.yourSubmittedPhoto
                      : (isCompany
                          ? l10n.uploadCompanyDoc
                          : l10n.uploadIdFaceSelfie),
                  style: kTextStyle.copyWith(
                    color: kNeutralColor,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 10),
                GuideAnchor.wrap(
                  _anchor(
                      _guideUploadKey,
                      isCompany
                          ? l10n.guideEmpVerifUploadCompanyTitle
                          : l10n.guideEmpVerifUploadPersonalTitle,
                      isCompany
                          ? l10n.guideEmpVerifUploadCompanyDesc
                          : l10n.guideEmpVerifUploadPersonalDesc),
                  GestureDetector(
                    onTap: _submitting ? null : _pickFile,
                    child: Container(
                      height: 220,
                      width: double.infinity,
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(12),
                        border:
                            Border.all(color: kBorderColorTextField, width: 2),
                        color: kDarkWhite,
                        image: preview != null
                            ? DecorationImage(image: preview, fit: BoxFit.cover)
                            : null,
                      ),
                      child: preview == null
                          ? Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(
                                  isCompany
                                      ? Icons.upload_file_outlined
                                      : Icons.add_a_photo_outlined,
                                  size: 40,
                                  color: kPrimaryColor,
                                ),
                                const SizedBox(height: 8),
                                Text(
                                  isCompany
                                      ? l10n.uploadCompanyDoc
                                      : l10n.uploadIdFaceSelfie,
                                  style:
                                      kTextStyle.copyWith(color: kPrimaryColor),
                                ),
                              ],
                            )
                          : Align(
                              alignment: Alignment.bottomCenter,
                              child: Container(
                                width: double.infinity,
                                padding:
                                    const EdgeInsets.symmetric(vertical: 10),
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
                ),
                const SizedBox(height: 24),
              ],
            ),
          ),
        ),
      ),
      bottomNavigationBar: ButtonGlobalWithoutIcon(
        guideAnchor: _anchor(_guideSubmitKey, l10n.guideEmpVerifSubmitTitle,
            l10n.guideEmpVerifSubmitDesc),
        buttontext: submitLabel,
        buttonDecoration: kButtonDecoration.copyWith(
          color:
              (_submitting || !hasNewPick) ? kLightNeutralColor : kPrimaryColor,
          borderRadius: BorderRadius.circular(30),
        ),
        onPressed: (_submitting || !hasNewPick) ? null : _submit,
        buttonTextColor: kWhite,
      ),
    ));
  }
}
