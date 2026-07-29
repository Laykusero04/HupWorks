import 'package:flutter/material.dart';
import 'package:freelancer/core/utils/attendance_format.dart';
import 'package:freelancer/data/models/attendance_punch_model.dart';
import 'package:freelancer/l10n/l10n.dart';

import 'constant.dart';

/// One punch row for [AttendancePunchCells].
class AttendancePunchCellItem {
  final String punchType;
  final DateTime punchedAt;
  final String? sellerName;

  const AttendancePunchCellItem({
    required this.punchType,
    required this.punchedAt,
    this.sellerName,
  });

  factory AttendancePunchCellItem.fromMap(Map<String, dynamic> row) {
    final profiles = row['profiles'];
    String? name;
    if (profiles is Map) {
      name = profiles['name'] as String?;
    }
    return AttendancePunchCellItem(
      punchType: row['punch_type'] as String? ?? '',
      punchedAt:
          DateTime.tryParse(row['punched_at'] as String? ?? '') ?? DateTime.now(),
      sellerName: name,
    );
  }

  factory AttendancePunchCellItem.fromSummary(AttendancePunchSummary s) =>
      AttendancePunchCellItem(
        punchType: s.punchType,
        punchedAt: s.punchedAt,
      );
}

/// iOS-style grouped cells: Time in / Time out summary + punch list.
class AttendancePunchCells extends StatelessWidget {
  final List<AttendancePunchCellItem> punches;
  final bool isLoading;
  final bool showSellerName;
  final String emptyMessage;

  const AttendancePunchCells({
    super.key,
    required this.punches,
    this.isLoading = false,
    this.showSellerName = false,
    this.emptyMessage = 'No punches today',
  });

  static ({DateTime? timeIn, DateTime? timeOut, double minutes}) summarizeToday(
    List<AttendancePunchCellItem> items,
  ) {
    final sorted = [...items]..sort((a, b) => a.punchedAt.compareTo(b.punchedAt));
    DateTime? timeIn;
    DateTime? lastOut;
    double minutes = 0;
    DateTime? openIn;

    for (final p in sorted) {
      if (p.punchType == 'in') {
        timeIn ??= p.punchedAt;
        openIn = p.punchedAt;
      } else if (p.punchType == 'out') {
        lastOut = p.punchedAt;
        if (openIn != null) {
          minutes += p.punchedAt.difference(openIn).inMinutes;
          openIn = null;
        }
      }
    }

    return (timeIn: timeIn, timeOut: lastOut, minutes: minutes);
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final locale = Localizations.localeOf(context).toString();
    if (isLoading) {
      return const Padding(
        padding: EdgeInsets.symmetric(vertical: 12),
        child: Center(
          child: SizedBox(
            width: 22,
            height: 22,
            child: CircularProgressIndicator(strokeWidth: 2, color: kPrimaryColor),
          ),
        ),
      );
    }

    final summary = summarizeToday(punches);

    return Container(
      decoration: BoxDecoration(
        color: kWhite,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: kBorderColorTextField),
      ),
      clipBehavior: Clip.antiAlias,
      child: Column(
        children: [
          IntrinsicHeight(
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Expanded(
                  child: _MetricCell(
                    label: l10n.attendanceTimeIn,
                    value: summary.timeIn != null
                        ? AttendanceFormat.timeOfDay(summary.timeIn!, locale)
                        : '—',
                    accent: const Color(0xFF2E7D32),
                  ),
                ),
                Container(width: 1, color: kBorderColorTextField),
                Expanded(
                  child: _MetricCell(
                    label: l10n.attendanceTimeOut,
                    value: summary.timeOut != null
                        ? AttendanceFormat.timeOfDay(summary.timeOut!, locale)
                        : '—',
                    accent: Colors.orange,
                  ),
                ),
              ],
            ),
          ),
          if (summary.minutes > 0)
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              decoration: BoxDecoration(
                color: kDarkWhite,
                border: Border(top: BorderSide(color: kBorderColorTextField)),
              ),
              child: Text(
                l10n.attendanceWorkedToday(
                  AttendanceFormat.minutesLabel(summary.minutes, l10n),
                ),
                style: kTextStyle.copyWith(
                  color: kSubTitleColor,
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          if (punches.isEmpty)
            Padding(
              padding: const EdgeInsets.all(12),
              child: Text(
                emptyMessage,
                style: kTextStyle.copyWith(color: kLightNeutralColor, fontSize: 12),
              ),
            )
          else ...[
            Container(height: 1, color: kBorderColorTextField),
            ...punches.asMap().entries.map((e) {
              final p = e.value;
              final isLast = e.key == punches.length - 1;
              return Column(
                children: [
                  _PunchRowCell(
                    punchType: p.punchType,
                    punchedAt: p.punchedAt,
                    sellerName: showSellerName ? p.sellerName : null,
                    locale: locale,
                  ),
                  if (!isLast)
                    Container(
                      margin: const EdgeInsets.only(left: 44),
                      height: 1,
                      color: kBorderColorTextField,
                    ),
                ],
              );
            }),
          ],
        ],
      ),
    );
  }
}

class _MetricCell extends StatelessWidget {
  final String label;
  final String value;
  final Color accent;

  const _MetricCell({
    required this.label,
    required this.value,
    required this.accent,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: kTextStyle.copyWith(color: kSubTitleColor, fontSize: 11),
          ),
          const SizedBox(height: 4),
          Text(
            value,
            style: kTextStyle.copyWith(
              color: accent,
              fontWeight: FontWeight.w700,
              fontSize: 15,
            ),
          ),
        ],
      ),
    );
  }
}

class _PunchRowCell extends StatelessWidget {
  final String punchType;
  final DateTime punchedAt;
  final String? sellerName;
  final String locale;

  const _PunchRowCell({
    required this.punchType,
    required this.punchedAt,
    this.sellerName,
    required this.locale,
  });

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final isIn = punchType == 'in';
    final punchLabel = AttendanceFormat.punchLabel(punchType, l10n);
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      child: Row(
        children: [
          Icon(
            isIn ? Icons.login_rounded : Icons.logout_rounded,
            size: 20,
            color: isIn ? const Color(0xFF2E7D32) : Colors.orange,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  sellerName != null && sellerName!.isNotEmpty
                      ? '$sellerName • $punchLabel'
                      : punchLabel,
                  style: kTextStyle.copyWith(
                    color: kNeutralColor,
                    fontWeight: FontWeight.w600,
                    fontSize: 13,
                  ),
                ),
                Text(
                  AttendanceFormat.timeOfDay(punchedAt, locale),
                  style: kTextStyle.copyWith(color: kSubTitleColor, fontSize: 12),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
