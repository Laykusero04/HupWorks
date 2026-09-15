import 'package:flutter/material.dart';
import 'package:freelancer/core/utils/dashboard_period.dart';
import 'package:freelancer/l10n/l10n.dart';

import 'constant.dart';

/// Day | Week | Month control for dashboards.
class DashboardPeriodSelector extends StatelessWidget {
  const DashboardPeriodSelector({
    super.key,
    required this.value,
    required this.onChanged,
  });

  final DashboardPeriod value;
  final ValueChanged<DashboardPeriod> onChanged;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    return SizedBox(
      width: double.infinity,
      child: SegmentedButton<DashboardPeriod>(
        segments: [
          ButtonSegment(
            value: DashboardPeriod.day,
            label: Text(l10n.periodDay),
          ),
          ButtonSegment(
            value: DashboardPeriod.week,
            label: Text(l10n.periodWeek),
          ),
          ButtonSegment(
            value: DashboardPeriod.month,
            label: Text(l10n.periodMonth),
          ),
        ],
        selected: {value},
        onSelectionChanged: (s) => onChanged(s.first),
        style: ButtonStyle(
          visualDensity: VisualDensity.compact,
          textStyle: WidgetStatePropertyAll(
            kTextStyle.copyWith(fontSize: 13, fontWeight: FontWeight.w600),
          ),
        ),
        showSelectedIcon: false,
      ),
    );
  }
}
