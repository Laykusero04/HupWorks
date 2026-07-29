import 'package:flutter/material.dart';
import 'package:freelancer/core/utils/attendance_mode.dart';
import 'package:freelancer/l10n/l10n.dart';

import 'constant.dart';

/// Client-facing picker for on-site job attendance policy.
class AttendanceModePicker extends StatelessWidget {
  final String value;
  final ValueChanged<String> onChanged;
  final bool enabled;

  const AttendanceModePicker({
    super.key,
    required this.value,
    required this.onChanged,
    this.enabled = true,
  });

  static const _options = [
    AttendanceMode.qrInOut,
    AttendanceMode.qrOnce,
    AttendanceMode.selfReport,
    AttendanceMode.disabled,
  ];

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final selected = AttendanceMode.normalize(value);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          l10n.attendanceTracking,
          style: kTextStyle.copyWith(
            color: kNeutralColor,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 6),
        Text(
          l10n.attendanceTrackingHint,
          style: kTextStyle.copyWith(color: kSubTitleColor, fontSize: 12),
        ),
        const SizedBox(height: 10),
        ..._options.map((mode) {
          final isSelected = selected == mode;
          return Padding(
            padding: const EdgeInsets.only(bottom: 8),
            child: Material(
              color: isSelected
                  ? kPrimaryColor.withValues(alpha: 0.08)
                  : kWhite,
              borderRadius: BorderRadius.circular(10),
              child: InkWell(
                onTap: enabled ? () => onChanged(mode) : null,
                borderRadius: BorderRadius.circular(10),
                child: Container(
                  width: double.infinity,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 10,
                  ),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(
                      color: isSelected ? kPrimaryColor : kBorderColorTextField,
                    ),
                  ),
                  child: Row(
                    children: [
                      Icon(
                        isSelected
                            ? Icons.radio_button_checked
                            : Icons.radio_button_off,
                        color: isSelected ? kPrimaryColor : kLightNeutralColor,
                        size: 20,
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              AttendanceMode.label(mode, l10n),
                              style: kTextStyle.copyWith(
                                color: kNeutralColor,
                                fontWeight: FontWeight.w600,
                                fontSize: 14,
                              ),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              AttendanceMode.clientHint(mode, l10n),
                              style: kTextStyle.copyWith(
                                color: kSubTitleColor,
                                fontSize: 12,
                                height: 1.3,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          );
        }),
      ],
    );
  }
}
