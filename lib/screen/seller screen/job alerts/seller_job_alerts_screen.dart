import 'package:flutter/material.dart';
import 'package:flutter_feather_icons/flutter_feather_icons.dart';
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

class _SellerJobAlertsScreenState extends State<SellerJobAlertsScreen> {
  List<SellerJobAlertRule> _rules = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() => _loading = true);
    try {
      final rules = await SellerJobAlertService.listMyRules();
      if (mounted) setState(() => _rules = rules);
    } finally {
      if (mounted) setState(() => _loading = false);
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

    return Scaffold(
      backgroundColor: kDarkWhite,
      appBar: AppBar(
        backgroundColor: kSellerPrimary,
        foregroundColor: kWhite,
        title: Text(l10n.jobAlertsTitle),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _openEditor(),
        backgroundColor: primary,
        icon: const Icon(Icons.add),
        label: Text(l10n.jobAlertNew),
      ),
      body: _loading
          ? Center(child: CircularProgressIndicator(color: primary))
          : RefreshIndicator(
              color: primary,
              onRefresh: _load,
              child: _rules.isEmpty
                  ? ListView(
                      physics: const AlwaysScrollableScrollPhysics(),
                      children: [
                        const SizedBox(height: 80),
                        Icon(FeatherIcons.bell, size: 48, color: kLightNeutralColor),
                        const SizedBox(height: 16),
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 32),
                          child: Text(
                            l10n.jobAlertsEmpty,
                            textAlign: TextAlign.center,
                            style: kTextStyle.copyWith(color: kLightNeutralColor),
                          ),
                        ),
                      ],
                    )
                  : ListView.separated(
                      padding: const EdgeInsets.fromLTRB(16, 16, 16, 88),
                      itemCount: _rules.length,
                      separatorBuilder: (_, __) => const SizedBox(height: 12),
                      itemBuilder: (_, i) {
                        final rule = _rules[i];
                        return Material(
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
                                      Switch(
                                        value: rule.enabled,
                                        onChanged: (v) => _toggle(rule, v),
                                        activeThumbColor: primary,
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
                                      onPressed: () => _delete(rule),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        );
                      },
                    ),
            ),
    );
  }
}
