import 'package:flutter/material.dart';
import 'package:freelancer/core/utils/attendance_format.dart';
import 'package:freelancer/core/utils/attendance_mode.dart';
import 'package:freelancer/data/models/attendance_punch_model.dart';
import 'package:freelancer/screen/widgets/attendance_punch_cells.dart';
import 'package:freelancer/services/attendance_service.dart';
import 'package:go_router/go_router.dart';

import '../widgets/constant.dart';

/// Freelancer attendance actions + today's punch cells.
class AttendanceActionsCard extends StatefulWidget {
  final String orderId;
  final String jobPostId;
  final String attendanceMode;
  final bool isClockedIn;
  final bool checkedInToday;
  final String? statusLabel;
  final VoidCallback? onChanged;
  final bool compact;

  const AttendanceActionsCard({
    super.key,
    required this.orderId,
    required this.jobPostId,
    required this.attendanceMode,
    this.isClockedIn = false,
    this.checkedInToday = false,
    this.statusLabel,
    this.onChanged,
    this.compact = false,
  });

  @override
  State<AttendanceActionsCard> createState() => _AttendanceActionsCardState();
}

class _AttendanceActionsCardState extends State<AttendanceActionsCard> {
  bool _busy = false;
  List<AttendancePunchCellItem> _todayPunches = [];
  bool _loadingPunches = true;

  @override
  void initState() {
    super.initState();
    _loadPunches();
  }

  Future<void> _loadPunches() async {
    setState(() => _loadingPunches = true);
    try {
      final punches =
          await AttendanceService.getMyPunchesForJob(widget.jobPostId);
      if (mounted) {
        setState(() {
          _todayPunches = _filterToday(punches)
              .map(AttendancePunchCellItem.fromSummary)
              .toList()
            ..sort((a, b) => a.punchedAt.compareTo(b.punchedAt));
          _loadingPunches = false;
        });
      }
    } catch (_) {
      if (mounted) setState(() => _loadingPunches = false);
    }
  }

  List<AttendancePunchSummary> _filterToday(List<AttendancePunchSummary> all) {
    final now = DateTime.now();
    return all.where((p) {
      final local = p.punchedAt.toLocal();
      return local.year == now.year &&
          local.month == now.month &&
          local.day == now.day;
    }).toList();
  }

  Future<void> _selfReport(String punchType) async {
    setState(() => _busy = true);
    try {
      final result = await AttendanceService.recordSelfReportPunch(
        orderId: widget.orderId,
        punchType: punchType,
      );
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            '${AttendanceFormat.punchLabel(result.punchType)} • '
            '${AttendanceFormat.minutesLabel(result.minutesWorkedToday)} today',
          ),
        ),
      );
      widget.onChanged?.call();
      await _loadPunches();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('$e')),
        );
      }
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  void _openScan() {
    context.push('/seller/attendance/scan?jobPostId=${widget.jobPostId}');
  }

  Widget _statusChip(String mode) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: kPrimaryColor.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(6),
      ),
      child: Text(
        AttendanceMode.label(mode),
        style: kTextStyle.copyWith(
          color: kPrimaryColor,
          fontSize: 11,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }

  Widget _actionButton({
    required String label,
    required Color color,
    required VoidCallback? onPressed,
    IconData? icon,
    bool expanded = false,
  }) {
    final btn = OutlinedButton.icon(
      onPressed: onPressed,
      icon: Icon(icon ?? Icons.touch_app_outlined, size: 18, color: color),
      label: Text(
        label,
        style: kTextStyle.copyWith(
          color: color,
          fontWeight: FontWeight.w600,
          fontSize: 13,
        ),
      ),
      style: OutlinedButton.styleFrom(
        padding: const EdgeInsets.symmetric(vertical: 10),
        side: BorderSide(color: color.withValues(alpha: 0.5)),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      ),
    );
    if (expanded) {
      return Expanded(child: btn);
    }
    return SizedBox(width: double.infinity, child: btn);
  }

  Widget _buildActions(String mode) {
    if (!AttendanceMode.isEnabled(mode)) {
      return Text(
        'Attendance is off for this job.',
        style: kTextStyle.copyWith(color: kLightNeutralColor, fontSize: 12),
      );
    }

    if (AttendanceMode.canUseQr(mode)) {
      final done = mode == AttendanceMode.qrOnce && widget.checkedInToday;
      return _actionButton(
        label: done
            ? 'Checked in'
            : (mode == AttendanceMode.qrOnce ? 'Check in' : 'Scan QR'),
        color: done ? kLightNeutralColor : const Color(0xFF2E7D32),
        icon: Icons.qr_code_scanner,
        onPressed: _busy || done ? null : _openScan,
      );
    }

    if (AttendanceMode.canSelfReport(mode)) {
      return Row(
        children: [
          _actionButton(
            label: 'In',
            color: const Color(0xFF2E7D32),
            icon: Icons.login_rounded,
            expanded: true,
            onPressed:
                _busy || widget.isClockedIn ? null : () => _selfReport('in'),
          ),
          const SizedBox(width: 8),
          _actionButton(
            label: 'Out',
            color: Colors.orange,
            icon: Icons.logout_rounded,
            expanded: true,
            onPressed:
                _busy || !widget.isClockedIn ? null : () => _selfReport('out'),
          ),
        ],
      );
    }

    return const SizedBox.shrink();
  }

  @override
  Widget build(BuildContext context) {
    final mode = AttendanceMode.normalize(widget.attendanceMode);

    return Container(
      width: double.infinity,
      padding: EdgeInsets.all(widget.compact ? 12 : 14),
      decoration: BoxDecoration(
        color: kPrimaryColor.withValues(alpha: 0.05),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: kBorderColorTextField),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text(
                'Attendance',
                style: kTextStyle.copyWith(
                  color: kNeutralColor,
                  fontWeight: FontWeight.w700,
                  fontSize: 13,
                ),
              ),
              const SizedBox(width: 8),
              _statusChip(mode),
              const Spacer(),
              if (widget.statusLabel != null)
                Text(
                  widget.statusLabel!,
                  style: kTextStyle.copyWith(
                    color: kSubTitleColor,
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                  ),
                ),
            ],
          ),
          if (!widget.compact) ...[
            const SizedBox(height: 4),
            Text(
              AttendanceMode.freelancerHint(mode),
              style: kTextStyle.copyWith(
                color: kSubTitleColor,
                fontSize: 11,
                height: 1.3,
              ),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
          ],
          const SizedBox(height: 10),
          _buildActions(mode),
          if (AttendanceMode.isEnabled(mode)) ...[
            const SizedBox(height: 10),
            AttendancePunchCells(
              punches: _todayPunches,
              isLoading: _loadingPunches,
              showSellerName: false,
              emptyMessage: 'No punches yet today.',
            ),
          ],
        ],
      ),
    );
  }
}
