import 'package:flutter/material.dart';
import 'package:freelancer/core/utils/attendance_format.dart';
import 'package:freelancer/core/utils/attendance_mode.dart';
import 'package:freelancer/data/models/attendance_punch_model.dart';
import 'package:freelancer/l10n/l10n.dart';
import 'package:freelancer/services/attendance_service.dart';

import '../widgets/button_global.dart';
import '../widgets/constant.dart';

class AttendanceConfirmScreen extends StatefulWidget {
  final String token;
  final AttendanceResolveResult resolve;

  const AttendanceConfirmScreen({
    super.key,
    required this.token,
    required this.resolve,
  });

  @override
  State<AttendanceConfirmScreen> createState() =>
      _AttendanceConfirmScreenState();
}

class _AttendanceConfirmScreenState extends State<AttendanceConfirmScreen> {
  late String _selectedPunchType;
  bool _isSubmitting = false;

  @override
  void initState() {
    super.initState();
    _selectedPunchType = widget.resolve.suggestedAction;
  }

  Future<void> _submit() async {
    final l10n = context.l10n;
    setState(() => _isSubmitting = true);
    try {
      final result = await AttendanceService.recordAttendancePunch(
        token: widget.token,
        punchType: _selectedPunchType,
      );
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            l10n.attendancePunchRecorded(
              AttendanceFormat.punchLabel(result.punchType, l10n),
              AttendanceFormat.minutesLabel(result.minutesWorkedToday, l10n),
            ),
          ),
        ),
      );
      Navigator.of(context).pop(true);
    } catch (e) {
      if (mounted) {
        setState(() => _isSubmitting = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(l10n.errorWithDetail('$e'))),
        );
      }
    }
  }

  String _statusText(AppLocalizations l10n, String locale) {
    final r = widget.resolve;
    if (AttendanceMode.normalize(r.attendanceMode) == AttendanceMode.qrOnce) {
      if (r.checkedInToday) return l10n.alreadyCheckedInToday;
      return l10n.readyForDailyCheckIn;
    }
    if (r.isClockedIn && r.lastPunchedAt != null) {
      return l10n.clockedInAt(
        AttendanceFormat.timeOfDay(r.lastPunchedAt!, locale),
      );
    }
    return l10n.notClockedInToday;
  }

  bool get _isQrOnceMode =>
      AttendanceMode.normalize(widget.resolve.attendanceMode) ==
      AttendanceMode.qrOnce;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final locale = Localizations.localeOf(context).toString();
    final r = widget.resolve;
    final primaryIsIn = _selectedPunchType == 'in';

    return Scaffold(
      backgroundColor: kDarkWhite,
      appBar: AppBar(
        backgroundColor: kDarkWhite,
        elevation: 0,
        iconTheme: const IconThemeData(color: kNeutralColor),
        title: Text(
          l10n.confirmAttendance,
          style: kTextStyle.copyWith(
            color: kNeutralColor,
            fontWeight: FontWeight.bold,
          ),
        ),
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: kWhite,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: kBorderColorTextField),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    r.title,
                    style: kTextStyle.copyWith(
                      color: kNeutralColor,
                      fontWeight: FontWeight.bold,
                      fontSize: 18,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    r.clientName,
                    style: kTextStyle.copyWith(color: kSubTitleColor),
                  ),
                  if (r.location != null && r.location!.isNotEmpty) ...[
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        const Icon(Icons.location_on_outlined,
                            size: 18, color: kPrimaryColor),
                        const SizedBox(width: 6),
                        Expanded(
                          child: Text(
                            r.location!,
                            style: kTextStyle.copyWith(color: kSubTitleColor),
                          ),
                        ),
                      ],
                    ),
                  ],
                  const SizedBox(height: 16),
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: r.isClockedIn
                          ? const Color(0xFFE8F5E9)
                          : kDarkWhite,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      _statusText(l10n, locale),
                      style: kTextStyle.copyWith(
                        fontWeight: FontWeight.w600,
                        color: r.isClockedIn
                            ? const Color(0xFF2E7D32)
                            : kNeutralColor,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            if (r.todayPunches.isNotEmpty) ...[
              const SizedBox(height: 20),
              Text(
                l10n.calendarToday,
                style: kTextStyle.copyWith(
                  fontWeight: FontWeight.bold,
                  color: kNeutralColor,
                ),
              ),
              const SizedBox(height: 8),
              ...r.todayPunches.map((p) => Padding(
                    padding: const EdgeInsets.only(bottom: 6),
                    child: Row(
                      children: [
                        Icon(
                          p.isClockIn ? Icons.login : Icons.logout,
                          size: 16,
                          color: p.isClockIn
                              ? const Color(0xFF2E7D32)
                              : Colors.orange,
                        ),
                        const SizedBox(width: 8),
                        Text(
                          '${AttendanceFormat.punchLabel(p.punchType, l10n)} • ${AttendanceFormat.timeOfDay(p.punchedAt, locale)}',
                          style: kTextStyle.copyWith(
                            color: kSubTitleColor,
                            fontSize: 13,
                          ),
                        ),
                      ],
                    ),
                  )),
            ],
            const SizedBox(height: 24),
            Text(
              l10n.recordLabel,
              style: kTextStyle.copyWith(
                fontWeight: FontWeight.bold,
                color: kNeutralColor,
              ),
            ),
            const SizedBox(height: 12),
            if (_isQrOnceMode) ...[
              if (r.checkedInToday)
                Text(
                  l10n.alreadyCheckedInTodayMessage,
                  style: kTextStyle.copyWith(color: kSubTitleColor, height: 1.35),
                )
              else
                Text(
                  l10n.attendanceQrOnceDailyHint,
                  style: kTextStyle.copyWith(color: kSubTitleColor, height: 1.35),
                ),
            ] else ...[
              Row(
                children: [
                  Expanded(
                    child: _PunchTypeChip(
                      label: l10n.clockIn,
                      selected: primaryIsIn,
                      color: const Color(0xFF2E7D32),
                      onTap: () => setState(() => _selectedPunchType = 'in'),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: _PunchTypeChip(
                      label: l10n.clockOut,
                      selected: !primaryIsIn,
                      color: Colors.orange,
                      onTap: () => setState(() => _selectedPunchType = 'out'),
                    ),
                  ),
                ],
              ),
            ],
            const SizedBox(height: 24),
            if (_isSubmitting)
              const Center(child: CircularProgressIndicator(color: kPrimaryColor))
            else
              ButtonGlobalWithoutIcon(
                buttontext: _isQrOnceMode
                    ? l10n.checkInForToday
                    : AttendanceFormat.punchLabel(_selectedPunchType, l10n),
                buttonDecoration: kButtonDecoration.copyWith(
                  color: primaryIsIn ? const Color(0xFF2E7D32) : Colors.orange,
                ),
                buttonTextColor: kWhite,
                onPressed: (r.checkedInToday && _isQrOnceMode) ? () {} : _submit,
              ),
            if (!_isQrOnceMode &&
                r.suggestClockIn != (_selectedPunchType == 'in')) ...[
              const SizedBox(height: 12),
              Center(
                child: TextButton(
                  onPressed: () => setState(() {
                    _selectedPunchType = r.suggestedAction;
                  }),
                  child: Text(
                    l10n.useSuggestedPunch(
                      AttendanceFormat.punchLabel(r.suggestedAction, l10n),
                    ),
                    style: kTextStyle.copyWith(color: kPrimaryColor),
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _PunchTypeChip extends StatelessWidget {
  final String label;
  final bool selected;
  final Color color;
  final VoidCallback onTap;

  const _PunchTypeChip({
    required this.label,
    required this.selected,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: selected ? color.withOpacity(0.15) : kWhite,
      borderRadius: BorderRadius.circular(8),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(8),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 14),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(8),
            border: Border.all(
              color: selected ? color : kBorderColorTextField,
              width: selected ? 2 : 1,
            ),
          ),
          child: Center(
            child: Text(
              label,
              style: kTextStyle.copyWith(
                color: selected ? color : kSubTitleColor,
                fontWeight: selected ? FontWeight.bold : FontWeight.normal,
              ),
            ),
          ),
        ),
      ),
    );
  }
}
