import 'package:flutter/material.dart';
import 'package:freelancer/core/guide/guide_anchor.dart';
import 'package:freelancer/core/guide/guide_host.dart';
import 'package:freelancer/core/guide/guide_info_button.dart';
import 'package:freelancer/core/guide/guide_step.dart';
import 'package:freelancer/core/widgets/rubik_refresh_indicator.dart';
import 'package:freelancer/core/widgets/loading_widget.dart';
import 'package:freelancer/core/widgets/empty_state_widget.dart';
import 'package:freelancer/data/models/seller_job_alert_rule_model.dart';
import 'package:freelancer/l10n/l10n.dart';
import 'package:freelancer/l10n/l10n_labels.dart';
import 'package:freelancer/screen/seller%20screen/job%20alerts/seller_job_alert_editor_screen.dart';
import 'package:freelancer/services/seller_job_alert_service.dart';
import 'package:nb_utils/nb_utils.dart';

import '../../widgets/constant.dart';

class SellerJobAlertsScreen extends StatefulWidget {
  const SellerJobAlertsScreen({super.key});

  @override
  State<SellerJobAlertsScreen> createState() => _SellerJobAlertsScreenState();
}

class _SellerJobAlertsScreenState extends State<SellerJobAlertsScreen>
    with GuideHost<SellerJobAlertsScreen> {
  // Guide targets (long-lived, one widget each; rule targets: first rule).
  final GlobalKey _guideRuleKey = GlobalKey();
  final GlobalKey _guideSwitchKey = GlobalKey();
  final GlobalKey _guideNewKey = GlobalKey();

  @override
  String get guideScreenId => 'seller_job_alerts';
  @override
  String get guideRole => 'seller';
  @override
  int get guideVersion => 1;

  /// False for the whole reload (first load, pull-to-refresh, after the
  /// editor or a delete) and until the push animation is over.
  @override
  bool get guideDataReady => !_loading && _routeSettled;
  @override
  String get guideSkipLabel => context.l10n.guideSkip;
  @override
  String get guideNextLabel => context.l10n.guideNext;
  @override
  String get guideDoneLabel => context.l10n.guideDone;

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
          key: _guideRuleKey,
          title: l10n.guideJobAlertsRuleTitle,
          description: l10n.guideJobAlertsRuleDesc),
      GuideStep(
          key: _guideSwitchKey,
          title: l10n.guideJobAlertsSwitchTitle,
          description: l10n.guideJobAlertsSwitchDesc),
      GuideStep(
          key: _guideNewKey,
          title: l10n.guideJobAlertsNewTitle,
          description: l10n.guideJobAlertsNewDesc,
          targetNearBottom: true),
    ];
  }
  List<SellerJobAlertRule> _rules = [];
  bool _loading = true;
  bool _loadFailed = false;
  final Set<String> _togglingIds = {};

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _awaitRouteSettled());
    _load();
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _loadFailed = false;
    });
    try {
      final rules = await SellerJobAlertService.listMyRules();
      if (mounted) {
        setState(() {
          _rules = rules;
          _loadFailed = false;
        });
      }
    } catch (_) {
      if (mounted) setState(() => _loadFailed = true);
    } finally {
      if (mounted) {
        setState(() => _loading = false);
        scheduleGuide();
      }
    }
  }

  Future<void> _openEditor({SellerJobAlertRule? rule, String? skill, String? jobType}) async {
    final changed = await SellerJobAlertEditorScreen(
      existing: rule,
      initialSkillName: skill,
      initialJobType: jobType,
    ).launch(context);
    if (changed == true) _load();
  }

  Future<void> _toggle(SellerJobAlertRule rule, bool enabled) async {
    if (_togglingIds.contains(rule.id)) return;
    setState(() => _togglingIds.add(rule.id));
    try {
      await SellerJobAlertService.setEnabled(rule.id, enabled);
      if (mounted) {
        setState(() {
          _rules = _rules
              .map((r) => r.id == rule.id ? r.copyWith(enabled: enabled) : r)
              .toList();
        });
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(context.l10n.errorWithDetail('$e'))),
        );
      }
    } finally {
      if (mounted) setState(() => _togglingIds.remove(rule.id));
    }
  }

  Future<void> _delete(SellerJobAlertRule rule) async {
    final l10n = context.l10n;
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(l10n.jobAlertDeleteTitle),
        content: Text(l10n.jobAlertDeleteMessage),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: Text(l10n.cancel)),
          TextButton(onPressed: () => Navigator.pop(ctx, true), child: Text(l10n.delete)),
        ],
      ),
    );
    if (ok != true || !mounted) return;
    try {
      await SellerJobAlertService.deleteRule(rule.id);
      _load();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(l10n.errorWithDetail('$e'))),
        );
      }
    }
  }

  String _summary(BuildContext context, SellerJobAlertRule rule) {
    final l10n = context.l10n;
    final parts = <String>[];
    if (rule.skillNames.isNotEmpty) {
      parts.add(rule.skillNames.join(', '));
    }
    if (rule.categoryIds.isNotEmpty) {
      parts.add(l10n.jobAlertCategoriesCount(rule.categoryIds.length));
    }
    if (rule.jobType != null) {
      parts.add(L10nLabels.jobType(l10n, rule.jobType));
    }
    if (rule.maxDistanceKm != null) {
      parts.add(l10n.jobAlertWithinKm(rule.maxDistanceKm!.round()));
    } else {
      parts.add(l10n.jobAlertAnyDistance);
    }
    if (rule.includeRemote) {
      parts.add(l10n.jobAlertIncludesRemote);
    }
    if (parts.isEmpty) return l10n.jobAlertMatchesAllJobs;
    return parts.join(' · ');
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final primary = Theme.of(context).colorScheme.primary;

    return guideBackScope(Scaffold(
      backgroundColor: kDarkWhite,
      appBar: AppBar(
        backgroundColor: kSellerPrimary,
        foregroundColor: kWhite,
        title: Text(l10n.jobAlertsTitle),
        actions: [GuideInfoButton(host: this)],
      ),
      floatingActionButton: _loadFailed
          ? null
          : GuideAnchor.wrap(
              _anchor(_guideNewKey, l10n.guideJobAlertsNewTitle,
                  l10n.guideJobAlertsNewDesc),
              FloatingActionButton.extended(
                onPressed: () => _openEditor(),
                backgroundColor: primary,
                icon: const Icon(Icons.add),
                label: Text(l10n.jobAlertNew),
              ),
            ),
      body: _loading
          ? const LoadingWidget()
          : _loadFailed
              ? EmptyStateWidget(
                  message: l10n.somethingWentWrong,
                  actionLabel: l10n.retry,
                  onAction: () {
                    _load();
                  },
                )
              : RubikRefreshIndicator(
              onRefresh: _load,
              child: _rules.isEmpty
                  ? ListView(
                      physics: const AlwaysScrollableScrollPhysics(
                        parent: BouncingScrollPhysics(),
                      ),
                      children: [
                        SizedBox(
                          height: MediaQuery.sizeOf(context).height * 0.12,
                        ),
                        EmptyStateWidget(
                          message: l10n.noJobAlertsYet,
                          hint: l10n.jobAlertsEmpty,
                          icon: Icons.notifications_active_outlined,
                          actionLabel: l10n.jobAlertNew,
                          onAction: () => _openEditor(),
                        ),
                      ],
                    )
                  : ListView.separated(
                      padding: const EdgeInsets.fromLTRB(16, 16, 16, 88),
                      itemCount: _rules.length,
                      separatorBuilder: (_, __) => const SizedBox(height: 12),
                      itemBuilder: (_, i) {
                        final rule = _rules[i];
                        return GuideAnchor.wrap(
                            i == 0
                                ? _anchor(
                                    _guideRuleKey,
                                    l10n.guideJobAlertsRuleTitle,
                                    l10n.guideJobAlertsRuleDesc)
                                : null,
                            Material(
                          color: kWhite,
                          borderRadius: BorderRadius.circular(12),
                          child: InkWell(
                            borderRadius: BorderRadius.circular(12),
                            onTap: () => _openEditor(rule: rule),
                            child: Padding(
                              padding: const EdgeInsets.all(16),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Row(
                                    children: [
                                      Expanded(
                                        child: Text(
                                          rule.name?.trim().isNotEmpty == true
                                              ? rule.name!
                                              : l10n.jobAlertUntitled,
                                          style: kTextStyle.copyWith(
                                            fontWeight: FontWeight.bold,
                                            color: kNeutralColor,
                                          ),
                                        ),
                                      ),
                                      GuideAnchor.wrap(
                                        i == 0
                                            ? _anchor(
                                                _guideSwitchKey,
                                                l10n.guideJobAlertsSwitchTitle,
                                                l10n.guideJobAlertsSwitchDesc)
                                            : null,
                                        Switch(
                                          value: rule.enabled,
                                          onChanged:
                                              _togglingIds.contains(rule.id)
                                                  ? null
                                                  : (v) => _toggle(rule, v),
                                          activeThumbColor: primary,
                                        ),
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 8),
                                  Text(
                                    _summary(context, rule),
                                    style: kTextStyle.copyWith(
                                      color: kSubTitleColor,
                                      fontSize: 13,
                                    ),
                                  ),
                                  const SizedBox(height: 8),
                                  Align(
                                    alignment: Alignment.centerRight,
                                    child: IconButton(
                                      icon: const Icon(Icons.delete_outline, color: Colors.red),
                                      tooltip: l10n.jobAlertDeleteTooltip,
                                      onPressed: () => _delete(rule),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ));
                      },
                    ),
            ),
    ));
  }
}
