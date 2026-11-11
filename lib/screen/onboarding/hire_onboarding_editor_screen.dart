import 'package:flutter/material.dart';
import 'package:freelancer/core/guide/guide_anchor.dart';
import 'package:freelancer/core/guide/guide_host.dart';
import 'package:freelancer/core/guide/guide_info_button.dart';
import 'package:freelancer/core/guide/guide_step.dart';
import 'package:freelancer/core/widgets/empty_state_widget.dart';
import 'package:freelancer/core/widgets/loading_widget.dart';
import 'package:freelancer/data/models/hire_onboarding_packet_model.dart';
import 'package:freelancer/l10n/l10n.dart';
import 'package:freelancer/services/hire_onboarding_service.dart';

import '../widgets/button_global.dart';
import '../widgets/constant.dart';

class HireOnboardingEditorScreen extends StatefulWidget {
  final String orderId;
  final String? jobLocation;
  final String? jobLocationType;
  final String? attendanceMode;

  const HireOnboardingEditorScreen({
    super.key,
    required this.orderId,
    this.jobLocation,
    this.jobLocationType,
    this.attendanceMode,
  });

  @override
  State<HireOnboardingEditorScreen> createState() =>
      _HireOnboardingEditorScreenState();
}

class _HireOnboardingEditorScreenState extends State<HireOnboardingEditorScreen>
    with GuideHost<HireOnboardingEditorScreen> {
  HireOnboardingPacket? _packet;
  List<HireOnboardingSection> _sections =
      HireOnboardingSection.defaultSections();
  final List<TextEditingController> _controllers = [];
  bool _loading = true;
  bool _saving = false;

  final GlobalKey _guideBoxesKey = GlobalKey();
  final GlobalKey _guideDraftKey = GlobalKey();
  final GlobalKey _guidePublishKey = GlobalKey();

  @override
  String get guideScreenId => 'client_hire_onboarding_editor';
  @override
  String get guideRole => 'client';
  @override
  int get guideVersion => 1;

  /// False while loading (first load and Retry) or when the packet failed.
  @override
  bool get guideDataReady => _routeSettled && !_loading && _packet != null;

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

  @override
  List<GuideStep> buildGuideSteps(BuildContext context) {
    final l10n = context.l10n;
    return [
      GuideStep(
          key: _guideBoxesKey,
          title: l10n.guideOnbEditBoxesTitle,
          description: l10n.guideOnbEditBoxesDesc),
      GuideStep(
          key: _guideDraftKey,
          title: l10n.guideOnbEditDraftTitle,
          description: l10n.guideOnbEditDraftDesc,
          targetNearBottom: true),
      GuideStep(
          key: _guidePublishKey,
          title: l10n.guideOnbEditPublishTitle,
          description: l10n.guideOnbEditPublishDesc,
          targetNearBottom: true),
    ];
  }

  @override
  void initState() {
    super.initState();
    _load();
    WidgetsBinding.instance.addPostFrameCallback((_) => _awaitRouteSettled());
  }

  @override
  void dispose() {
    for (final c in _controllers) {
      c.dispose();
    }
    super.dispose();
  }

  Future<void> _load() async {
    try {
      await HireOnboardingService.ensureDraft(widget.orderId);
      var packet =
          await HireOnboardingService.getPacketForOrder(widget.orderId);
      if (packet != null) {
        var sections = packet.sections;
        if (!mounted) return;
        final l10n = context.l10n;
        sections = HireOnboardingService.sectionsWithLocationHint(
          sections: sections,
          location: widget.jobLocation,
          locationType: widget.jobLocationType,
          attendanceMode: widget.attendanceMode,
          l10n: l10n,
        );
        _bindSections(sections);
        setState(() {
          _packet = packet;
          _sections = sections;
          _loading = false;
        });
      } else {
        setState(() => _loading = false);
      }
      scheduleGuide();
    } catch (_) {
      if (mounted) setState(() => _loading = false);
    }
  }

  void _bindSections(List<HireOnboardingSection> sections) {
    for (final c in _controllers) {
      c.dispose();
    }
    _controllers.clear();
    for (final s in sections) {
      _controllers.add(TextEditingController(text: s.body));
    }
  }

  List<HireOnboardingSection> _sectionsFromControllers() {
    return List.generate(_sections.length, (i) {
      return _sections[i].copyWith(body: _controllers[i].text.trim());
    });
  }

  Future<void> _saveDraft() async {
    if (_packet == null) return;
    setState(() => _saving = true);
    try {
      final updated = _sectionsFromControllers();
      await HireOnboardingService.updateDraftSections(
        packetId: _packet!.id,
        sections: updated,
      );
      if (mounted) {
        setState(() {
          _sections = updated;
          _saving = false;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(context.l10n.draftSaved)),
        );
      }
    } catch (e) {
      if (mounted) {
        setState(() => _saving = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(context.l10n.errorWithDetail('$e'))),
        );
      }
    }
  }

  Future<void> _publish() async {
    if (_packet == null) return;
    setState(() => _saving = true);
    try {
      final updated = _sectionsFromControllers();
      await HireOnboardingService.updateDraftSections(
        packetId: _packet!.id,
        sections: updated,
      );
      await HireOnboardingService.publish(_packet!.id);
      if (mounted) {
        setState(() => _saving = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(context.l10n.instructionsSentToFreelancer),
          ),
        );
        Navigator.pop(context, true);
      }
    } catch (e) {
      if (mounted) {
        setState(() => _saving = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(context.l10n.errorWithDetail('$e'))),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final bottom = MediaQuery.paddingOf(context).bottom;

    return guideBackScope(Scaffold(
      backgroundColor: kDarkWhite,
      appBar: AppBar(
        backgroundColor: kDarkWhite,
        elevation: 0,
        iconTheme: const IconThemeData(color: kNeutralColor),
        title: Text(
          l10n.firstDayInstructions,
          style: kTextStyle.copyWith(
            color: kNeutralColor,
            fontWeight: FontWeight.bold,
          ),
        ),
        centerTitle: true,
        actions: [GuideInfoButton(host: this)],
      ),
      body: _loading
          ? const LoadingWidget()
          : _packet == null
              ? EmptyStateWidget(
                  message: l10n.somethingWentWrong,
                  actionLabel: l10n.retry,
                  onAction: () {
                    setState(() => _loading = true);
                    _load();
                  },
                )
              : Column(
                  children: [
                    Expanded(
                      child: SingleChildScrollView(
                        padding: const EdgeInsets.all(16),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              l10n.onboardingEditorLead,
                              style: kTextStyle.copyWith(
                                color: kSubTitleColor,
                                height: 1.35,
                              ),
                            ),
                            if (_packet?.isPublished == true) ...[
                              const SizedBox(height: 12),
                              Container(
                                width: double.infinity,
                                padding: const EdgeInsets.all(12),
                                decoration: BoxDecoration(
                                  color: kSecondaryColor.withOpacity(0.08),
                                  borderRadius: BorderRadius.circular(8),
                                  border: Border.all(
                                    color: kSecondaryColor.withOpacity(0.3),
                                  ),
                                ),
                                child: Text(
                                  l10n.onboardingResendNotice,
                                  style: kTextStyle.copyWith(
                                    color: kSubTitleColor,
                                    fontSize: 13,
                                  ),
                                ),
                              ),
                            ],
                            const SizedBox(height: 16),
                            ...List.generate(_sections.length, (i) {
                              return Padding(
                                padding: const EdgeInsets.only(bottom: 14),
                                child: GuideAnchor.wrap(
                                  i == 0
                                      ? _anchor(
                                          _guideBoxesKey,
                                          l10n.guideOnbEditBoxesTitle,
                                          l10n.guideOnbEditBoxesDesc)
                                      : null,
                                  Container(
                                    padding: const EdgeInsets.all(12),
                                    decoration: BoxDecoration(
                                      color: kWhite,
                                      borderRadius: BorderRadius.circular(8),
                                      border: Border.all(
                                        color: kBorderColorTextField,
                                      ),
                                    ),
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          _sections[i].title,
                                          style: kTextStyle.copyWith(
                                            color: kNeutralColor,
                                            fontWeight: FontWeight.bold,
                                          ),
                                        ),
                                        const SizedBox(height: 8),
                                        TextField(
                                          controller: _controllers[i],
                                          maxLines: 4,
                                          minLines: 2,
                                          decoration: InputDecoration(
                                            hintText: l10n.addDetailsHint,
                                            hintStyle: kTextStyle.copyWith(
                                              color: kLightNeutralColor,
                                            ),
                                            border: OutlineInputBorder(
                                              borderRadius:
                                                  BorderRadius.circular(8),
                                              borderSide: const BorderSide(
                                                color: kBorderColorTextField,
                                              ),
                                            ),
                                          ),
                                          style: kTextStyle.copyWith(
                                            color: kSubTitleColor,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                              );
                            }),
                          ],
                        ),
                      ),
                    ),
                    Material(
                      color: kWhite,
                      elevation: 8,
                      child: Padding(
                        padding: EdgeInsets.fromLTRB(16, 12, 16, 12 + bottom),
                        child: Column(
                          children: [
                            ButtonGlobalWithoutIcon(
                              guideAnchor: _anchor(
                                  _guideDraftKey,
                                  l10n.guideOnbEditDraftTitle,
                                  l10n.guideOnbEditDraftDesc),
                              buttontext:
                                  _saving ? l10n.saving : l10n.saveDraft,
                              buttonDecoration: kButtonDecoration.copyWith(
                                color: kWhite,
                                border: Border.all(color: kPrimaryColor),
                              ),
                              buttonTextColor: kPrimaryColor,
                              onPressed: _saving ? () {} : _saveDraft,
                            ),
                            const SizedBox(height: 10),
                            ButtonGlobalWithoutIcon(
                              guideAnchor: _anchor(
                                  _guidePublishKey,
                                  l10n.guideOnbEditPublishTitle,
                                  l10n.guideOnbEditPublishDesc),
                              buttontext: _saving
                                  ? l10n.pleaseWaitEllipsis
                                  : l10n.publishToFreelancer,
                              buttonDecoration: kButtonDecoration.copyWith(
                                color: kPrimaryColor,
                              ),
                              onPressed: _saving ? () {} : _publish,
                              buttonTextColor: kWhite,
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
    ));
  }
}
