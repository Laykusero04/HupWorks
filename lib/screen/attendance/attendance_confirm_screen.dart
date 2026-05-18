import 'package:flutter/material.dart';
import 'package:freelancer/core/utils/attendance_format.dart';
import 'package:freelancer/data/models/attendance_punch_model.dart';
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
            '${AttendanceFormat.punchLabel(result.punchType)} recorded. '
            'Today: ${AttendanceFormat.minutesLabel(result.minutesWorkedToday)} worked.',
          ),
        ),
      );
      Navigator.of(context).pop(true);
    } catch (e) {
      if (mounted) {
        setState(() => _isSubmitting = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('$e')),
        );
      }
    }
  }

  String get _statusText {
    final r = widget.resolve;
    if (r.isClockedIn && r.lastPunchedAt != null) {
      return 'Clocked in at ${AttendanceFormat.timeOfDay(r.lastPunchedAt!)}';
    }
    return 'Not clocked in today';
  }

  @override
  Widget build(BuildContext context) {
    final r = widget.resolve;
    final primaryIsIn = _selectedPunchType == 'in';

    return Scaffold(
      backgroundColor: kDarkWhite,
      appBar: AppBar(
        backgroundColor: kDarkWhite,
        elevation: 0,
        iconTheme: const IconThemeData(color: kNeutralColor),
        title: Text(
          'Confirm attendance',
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
                      _statusText,
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
                'Today',
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
                          '${AttendanceFormat.punchLabel(p.punchType)} • ${AttendanceFormat.timeOfDay(p.punchedAt)}',
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
              'Record',
              style: kTextStyle.copyWith(
                fontWeight: FontWeight.bold,
                color: kNeutralColor,
              ),
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: _PunchTypeChip(
                    label: 'Clock in',
                    selected: primaryIsIn,
                    color: const Color(0xFF2E7D32),
                    onTap: () => setState(() => _selectedPunchType = 'in'),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _PunchTypeChip(
                    label: 'Clock out',
                    selected: !primaryIsIn,
                    color: Colors.orange,
                    onTap: () => setState(() => _selectedPunchType = 'out'),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 24),
            if (_isSubmitting)
              const Center(child: CircularProgressIndicator(color: kPrimaryColor))
            else
              ButtonGlobalWithoutIcon(
                buttontext: AttendanceFormat.punchLabel(_selectedPunchType),
                buttonDecoration: kButtonDecoration.copyWith(
                  color: primaryIsIn ? const Color(0xFF2E7D32) : Colors.orange,
                ),
                buttonTextColor: kWhite,
                onPressed: _submit,
              ),
            if (r.suggestClockIn != (_selectedPunchType == 'in')) ...[
              const SizedBox(height: 12),
              Center(
                child: TextButton(
                  onPressed: () => setState(() {
                    _selectedPunchType = r.suggestedAction;
                  }),
                  child: Text(
                    'Use suggested: ${AttendanceFormat.punchLabel(r.suggestedAction)}',
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
