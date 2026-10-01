import 'package:flutter/material.dart';
import 'package:freelancer/core/widgets/empty_state_widget.dart';
import 'package:freelancer/core/widgets/loading_widget.dart';
import 'package:freelancer/core/widgets/rubik_refresh_indicator.dart';
import 'package:freelancer/data/models/platform_contribution.dart';
import 'package:freelancer/l10n/l10n.dart';
import 'package:freelancer/services/charity_cause_service.dart';
import 'package:freelancer/services/platform_contribution_service.dart';
import 'package:nb_utils/nb_utils.dart';

import 'charity_cause_screen.dart';
import 'constant.dart';

/// Share of completed work for the signed-in freelancer or employer.
class PlatformContributionScreen extends StatefulWidget {
  const PlatformContributionScreen({super.key});

  @override
  State<PlatformContributionScreen> createState() =>
      _PlatformContributionScreenState();
}

class _PlatformContributionScreenState extends State<PlatformContributionScreen> {
  PlatformContribution? _data;
  String? _cause;
  bool _isLoading = true;
  bool _hasError = false;

  @override
  void initState() {
    super.initState();
    _load(showLoader: true);
  }

  Future<void> _load({bool showLoader = false}) async {
    if (showLoader && mounted) {
      setState(() {
        _isLoading = true;
        _hasError = false;
      });
    }
    try {
      final data = await PlatformContributionService.getMine();
      final cause = await CharityCauseService.getMine();
      if (!mounted) return;
      setState(() {
        _data = data;
        _cause = cause;
        _isLoading = false;
        _hasError = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _isLoading = false;
        if (_data == null) _hasError = true;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(context.l10n.errorWithDetail('$e'))),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;

    return Scaffold(
      backgroundColor: kDarkWhite,
      appBar: AppBar(
        backgroundColor: kDarkWhite,
        elevation: 0,
        iconTheme: const IconThemeData(color: kNeutralColor),
        title: Text(
          l10n.platformShareTitle,
          style: kTextStyle.copyWith(
            color: kNeutralColor,
            fontWeight: FontWeight.bold,
          ),
        ),
        centerTitle: true,
      ),
      body: _isLoading
          ? const LoadingWidget()
          : _hasError && _data == null
              ? EmptyStateWidget(
                  message: l10n.couldNotLoadResults,
                  hint: l10n.errorLoading,
                  icon: Icons.pie_chart_outline,
                  actionLabel: l10n.retry,
                  onAction: () => _load(showLoader: true),
                )
              : _body(context, _data ?? PlatformContribution.empty),
    );
  }

  Widget _body(BuildContext context, PlatformContribution data) {
    final l10n = context.l10n;
    final accent = data.isSeller ? kSellerPrimary : kPrimaryColor;

    return Padding(
      padding: const EdgeInsets.only(top: 20),
      child: Container(
        width: context.width(),
        padding: const EdgeInsets.symmetric(horizontal: 16),
        decoration: const BoxDecoration(
          color: kWhite,
          borderRadius: BorderRadius.only(
            topLeft: Radius.circular(30),
            topRight: Radius.circular(30),
          ),
        ),
        child: RubikRefreshIndicator(
          onRefresh: () => _load(),
          child: ListView(
            physics: const AlwaysScrollableScrollPhysics(
              parent: BouncingScrollPhysics(),
            ),
            padding: const EdgeInsets.fromLTRB(0, 20, 0, 28),
            children: [
              Text(
                l10n.platformShareHeadline,
                style: kTextStyle.copyWith(
                  color: kNeutralColor,
                  fontSize: 16,
                  height: 1.4,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 6),
              Text(
                data.isSeller
                    ? l10n.platformShareSellerNote
                    : l10n.platformShareClientNote,
                style: kTextStyle.copyWith(
                  color: kSubTitleColor,
                  fontSize: 13,
                  height: 1.4,
                ),
              ),
              const SizedBox(height: 16),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.fromLTRB(16, 18, 16, 16),
                decoration: BoxDecoration(
                  color: accent.withValues(alpha: 0.08),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      data.shareLabel,
                      style: kTextStyle.copyWith(
                        color: accent,
                        fontSize: 40,
                        fontWeight: FontWeight.bold,
                        height: 1,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      l10n.platformShareOfCompletedWork,
                      style: kTextStyle.copyWith(
                        color: kNeutralColor,
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 12),
                    ClipRRect(
                      borderRadius: BorderRadius.circular(99),
                      child: LinearProgressIndicator(
                        value: data.shareFraction,
                        minHeight: 8,
                        backgroundColor: kWhite,
                        color: accent,
                      ),
                    ),
                  ],
                ),
              ),
              if (data.shiftsCompleted == 0) ...[
                const SizedBox(height: 12),
                Text(
                  l10n.platformShareEmpty,
                  style: kTextStyle.copyWith(
                    color: kSubTitleColor,
                    fontSize: 13,
                    height: 1.4,
                  ),
                ),
              ],
              const SizedBox(height: 16),
              _StatRow(
                icon: Icons.event_available_outlined,
                label: l10n.platformShareShifts,
                value: l10n.platformShareCountOf(
                  '${data.shiftsCompleted}',
                  '${data.platformShifts}',
                ),
              ),
              const SizedBox(height: 10),
              _StatRow(
                icon: Icons.schedule_outlined,
                label: l10n.platformShareHours,
                value: l10n.platformShareCountOf(
                  data.hoursLabel,
                  data.platformHoursLabel,
                ),
              ),
              const SizedBox(height: 10),
              _StatRow(
                icon: Icons.receipt_long_outlined,
                label: l10n.platformShareValue,
                value: l10n.platformShareCountOf(
                  data.workValueLabel,
                  data.platformWorkValueLabel,
                ),
              ),
              const SizedBox(height: 10),
              _CauseLink(
                label: l10n.charityCauseShareLabel,
                value: charityCauseShareValue(l10n, _cause),
                onTap: () async {
                  final result = await Navigator.of(context).push<String>(
                    MaterialPageRoute(
                      builder: (_) => CharityCauseScreen(initialCause: _cause),
                    ),
                  );
                  if (!mounted || result == null) return;
                  setState(() => _cause = result.isEmpty ? null : result);
                },
              ),
              const SizedBox(height: 18),
              Text(
                l10n.platformShareDisclaimer,
                style: kTextStyle.copyWith(
                  color: kSubTitleColor,
                  fontSize: 12,
                  height: 1.45,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _CauseLink extends StatelessWidget {
  const _CauseLink({
    required this.label,
    required this.value,
    required this.onTap,
  });

  final String label;
  final String value;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: kDarkWhite,
      borderRadius: BorderRadius.circular(14),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(14),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
          child: Row(
            children: [
              const Icon(Icons.volunteer_activism_outlined, color: kNeutralColor, size: 20),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  label,
                  style: kTextStyle.copyWith(
                    color: kSubTitleColor,
                    fontSize: 13,
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Text(
                value,
                style: kTextStyle.copyWith(
                  color: kNeutralColor,
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const Icon(Icons.chevron_right, color: kLightNeutralColor, size: 20),
            ],
          ),
        ),
      ),
    );
  }
}

class _StatRow extends StatelessWidget {
  const _StatRow({
    required this.icon,
    required this.label,
    required this.value,
  });

  final IconData icon;
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: kDarkWhite,
        borderRadius: BorderRadius.circular(14),
      ),
      child: Row(
        children: [
          Icon(icon, color: kNeutralColor, size: 20),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              label,
              style: kTextStyle.copyWith(
                color: kSubTitleColor,
                fontSize: 13,
              ),
            ),
          ),
          const SizedBox(width: 8),
          Text(
            value,
            style: kTextStyle.copyWith(
              color: kNeutralColor,
              fontSize: 14,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}
