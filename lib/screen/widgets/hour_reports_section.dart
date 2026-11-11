import 'package:flutter/material.dart';
import 'package:freelancer/core/utils/attendance_format.dart';
import 'package:freelancer/data/models/hour_report_model.dart';
import 'package:freelancer/l10n/l10n.dart';
import 'package:freelancer/services/hour_reports_service.dart';

import 'constant.dart';
import 'package:freelancer/core/guide/guide_anchor.dart';

/// Lists hour reports for an order. Employer can accept/decline pending ones.
class HourReportsSection extends StatefulWidget {
  final String orderId;
  final bool isEmployer;
  final VoidCallback? onChanged;

  const HourReportsSection({
    super.key,
    required this.orderId,
    required this.isEmployer,
    this.onChanged,
    this.guideAnchor,
  });

  /// Optional guide target around this widget; see [GuideAnchor].
  final GuideAnchor? guideAnchor;

  @override
  State<HourReportsSection> createState() => _HourReportsSectionState();
}

class _HourReportsSectionState extends State<HourReportsSection> {
  List<HourReport> _reports = const [];
  bool _loading = true;
  String? _error;
  String? _busyId;

  @override
  void initState() {
    super.initState();
    _load();
  }

  @override
  void didUpdateWidget(covariant HourReportsSection oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.orderId != widget.orderId) {
      _load();
    }
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final list = await HourReportsService.listForOrder(widget.orderId);
      if (!mounted) return;
      setState(() {
        _reports = list;
        _loading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _error = '$e';
        _loading = false;
      });
    }
  }

  Future<void> _accept(HourReport report) async {
    setState(() => _busyId = report.id);
    try {
      await HourReportsService.accept(report.id);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(context.l10n.hoursAcceptedSnack)),
      );
      await _load();
      widget.onChanged?.call();
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(context.l10n.hoursAcceptFailed('$e'))),
      );
    } finally {
      if (mounted) setState(() => _busyId = null);
    }
  }

  Future<void> _decline(HourReport report) async {
    final reasonController = TextEditingController();
    final reason = await showDialog<String?>(
      context: context,
      builder: (ctx) {
        return AlertDialog(
          title: Text(ctx.l10n.hoursDeclineTitle),
          content: TextField(
            controller: reasonController,
            maxLines: 3,
            maxLength: 500,
            decoration: InputDecoration(
              hintText: ctx.l10n.hoursDeclineReasonHint,
              border: const OutlineInputBorder(),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: Text(ctx.l10n.cancel),
            ),
            TextButton(
              onPressed: () => Navigator.pop(ctx, reasonController.text.trim()),
              child: Text(ctx.l10n.declineAction),
            ),
          ],
        );
      },
    );
    reasonController.dispose();
    if (reason == null || !mounted) return;

    setState(() => _busyId = report.id);
    try {
      await HourReportsService.decline(
        report.id,
        reason: reason.isEmpty ? null : reason,
      );
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(context.l10n.hoursDeclinedSnack)),
      );
      await _load();
      widget.onChanged?.call();
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(context.l10n.hoursDeclineFailed('$e'))),
      );
    } finally {
      if (mounted) setState(() => _busyId = null);
    }
  }

  Color _statusColor(String status) {
    switch (status) {
      case HourReport.accepted:
        return Colors.green.shade700;
      case HourReport.declined:
        return Colors.red.shade700;
      default:
        return kPrimaryColor;
    }
  }

  @override
  Widget build(BuildContext context) {
    // Nothing to show: no guide target either (a zero-size Showcase would
    // count as rendered).
    if (_reports.isEmpty) return const SizedBox.shrink();
    return GuideAnchor.wrap(widget.guideAnchor, _buildContent(context));
  }

  Widget _buildContent(BuildContext context) {
    if (_loading && _reports.isEmpty) {
      return const SizedBox.shrink();
    }

    if (_error != null && _reports.isEmpty) {
      return const SizedBox.shrink();
    }

    if (_reports.isEmpty) {
      return const SizedBox.shrink();
    }

    return Container(
      width: double.infinity,
      margin: const EdgeInsets.only(bottom: 4),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: kDarkWhite,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: kBorderColorTextField),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            context.l10n.hourReportsTitle,
            style: kTextStyle.copyWith(
              color: kNeutralColor,
              fontWeight: FontWeight.w700,
              fontSize: 13,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            widget.isEmployer
                ? context.l10n.hourReportsEmployerHint
                : context.l10n.hourReportsFreelancerHint,
            style: kTextStyle.copyWith(color: kSubTitleColor, fontSize: 11, height: 1.3),
          ),
          const SizedBox(height: 10),
          ..._reports.map(_buildRow),
        ],
      ),
    );
  }

  Widget _buildRow(HourReport report) {
    final busy = _busyId == report.id;
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(10),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: kBorderColorTextField),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    '${report.workDateLabel} · ${AttendanceFormat.minutesLabel(report.minutes)}',
                    style: kTextStyle.copyWith(
                      color: kNeutralColor,
                      fontWeight: FontWeight.w700,
                      fontSize: 13,
                    ),
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                  decoration: BoxDecoration(
                    color: _statusColor(report.status).withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    switch (report.status) {
                      HourReport.accepted => context.l10n.statusAccepted,
                      HourReport.declined => context.l10n.statusRejected,
                      _ => context.l10n.statusPending,
                    },
                    style: kTextStyle.copyWith(
                      color: _statusColor(report.status),
                      fontSize: 11,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
              ],
            ),
            if (widget.isEmployer &&
                (report.sellerName != null && report.sellerName!.isNotEmpty)) ...[
              const SizedBox(height: 4),
              Text(
                report.sellerName!,
                style: kTextStyle.copyWith(color: kSubTitleColor, fontSize: 12),
              ),
            ],
            if (report.isDeclined &&
                report.declineReason != null &&
                report.declineReason!.isNotEmpty) ...[
              const SizedBox(height: 6),
              Text(
                report.declineReason!,
                style: kTextStyle.copyWith(color: kSubTitleColor, fontSize: 12),
              ),
            ],
            if (widget.isEmployer && report.isPending) ...[
              const SizedBox(height: 10),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: busy ? null : () => _decline(report),
                      child: busy
                          ? const SizedBox(
                              height: 16,
                              width: 16,
                              child: CircularProgressIndicator(strokeWidth: 2),
                            )
                          : Text(context.l10n.declineAction),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: ElevatedButton(
                      onPressed: busy ? null : () => _accept(report),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: kPrimaryColor,
                        foregroundColor: Colors.white,
                      ),
                      child: busy
                          ? const SizedBox(
                              height: 16,
                              width: 16,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                color: Colors.white,
                              ),
                            )
                          : Text(context.l10n.acceptAction),
                    ),
                  ),
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }
}
