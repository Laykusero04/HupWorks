import 'package:flutter/material.dart';
import 'package:freelancer/core/utils/attendance_format.dart';
import 'package:freelancer/services/attendance_service.dart';

import '../widgets/constant.dart';

class AttendancePunchLogSection extends StatefulWidget {
  final String jobPostId;

  const AttendancePunchLogSection({super.key, required this.jobPostId});

  @override
  State<AttendancePunchLogSection> createState() =>
      _AttendancePunchLogSectionState();
}

class _AttendancePunchLogSectionState extends State<AttendancePunchLogSection> {
  List<Map<String, dynamic>> _punches = [];
  bool _isLoading = true;
  bool _expanded = false;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    try {
      final rows = await AttendanceService.getPunchesForJobPost(
        widget.jobPostId,
        day: DateTime.now(),
      );
      if (mounted) {
        setState(() {
          _punches = rows;
          _isLoading = false;
        });
      }
    } catch (_) {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  String _sellerName(Map<String, dynamic> row) {
    final profiles = row['profiles'];
    if (profiles is Map) {
      return (profiles['name'] as String?) ?? 'Freelancer';
    }
    return 'Freelancer';
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Padding(
        padding: EdgeInsets.symmetric(vertical: 8),
        child: Center(
          child: SizedBox(
            width: 24,
            height: 24,
            child: CircularProgressIndicator(strokeWidth: 2, color: kPrimaryColor),
          ),
        ),
      );
    }

    if (_punches.isEmpty) {
      return Padding(
        padding: const EdgeInsets.only(top: 4),
        child: Text(
          'No attendance recorded today.',
          style: kTextStyle.copyWith(color: kLightNeutralColor, fontSize: 13),
        ),
      );
    }

    final visible = _expanded ? _punches : _punches.take(5).toList();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        ...visible.map((row) {
          final type = row['punch_type'] as String? ?? '';
          final at = DateTime.tryParse(row['punched_at'] as String? ?? '');
          final isIn = type == 'in';
          return Padding(
            padding: const EdgeInsets.only(bottom: 8),
            child: Row(
              children: [
                Icon(
                  isIn ? Icons.login : Icons.logout,
                  size: 18,
                  color: isIn ? const Color(0xFF2E7D32) : Colors.orange,
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        '${_sellerName(row)} • ${AttendanceFormat.punchLabel(type)}',
                        style: kTextStyle.copyWith(
                          color: kNeutralColor,
                          fontWeight: FontWeight.w600,
                          fontSize: 13,
                        ),
                      ),
                      if (at != null)
                        Text(
                          AttendanceFormat.timeOfDay(at),
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
          );
        }),
        if (_punches.length > 5)
          TextButton(
            onPressed: () => setState(() => _expanded = !_expanded),
            child: Text(_expanded ? 'Show less' : 'Show all (${_punches.length})'),
          ),
      ],
    );
  }
}
