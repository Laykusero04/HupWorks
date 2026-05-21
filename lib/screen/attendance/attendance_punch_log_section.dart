import 'package:flutter/material.dart';
import 'package:freelancer/screen/widgets/attendance_punch_cells.dart';
import 'package:freelancer/services/attendance_service.dart';

class AttendancePunchLogSection extends StatefulWidget {
  final String jobPostId;
  final bool showSellerName;

  const AttendancePunchLogSection({
    super.key,
    required this.jobPostId,
    this.showSellerName = true,
  });

  @override
  State<AttendancePunchLogSection> createState() =>
      _AttendancePunchLogSectionState();
}

class _AttendancePunchLogSectionState extends State<AttendancePunchLogSection> {
  List<AttendancePunchCellItem> _punches = [];
  bool _isLoading = true;

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
          _punches = rows
              .map((e) => AttendancePunchCellItem.fromMap(
                    Map<String, dynamic>.from(e),
                  ))
              .toList()
            ..sort((a, b) => a.punchedAt.compareTo(b.punchedAt));
          _isLoading = false;
        });
      }
    } catch (_) {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return AttendancePunchCells(
      punches: _punches,
      isLoading: _isLoading,
      showSellerName: widget.showSellerName,
      emptyMessage: 'No attendance recorded today.',
    );
  }
}
