import 'package:flutter/material.dart';
import 'package:freelancer/core/guide/guide_anchor.dart';
import 'package:freelancer/core/guide/guide_host.dart';
import 'package:freelancer/core/guide/guide_info_button.dart';
import 'package:freelancer/core/guide/guide_step.dart';
import 'package:freelancer/core/utils/app_logger.dart';
import 'package:freelancer/core/utils/attendance_location.dart';
import 'package:freelancer/l10n/l10n.dart';
import 'package:freelancer/services/attendance_service.dart';
import 'package:freelancer/services/job_posts_service.dart';
import 'package:go_router/go_router.dart';
import 'package:mobile_scanner/mobile_scanner.dart';

import '../widgets/constant.dart';
import 'attendance_confirm_screen.dart';

class AttendanceScanScreen extends StatefulWidget {
  final String? hintJobPostId;

  const AttendanceScanScreen({super.key, this.hintJobPostId});

  @override
  State<AttendanceScanScreen> createState() => _AttendanceScanScreenState();
}

class _AttendanceScanScreenState extends State<AttendanceScanScreen>
    with GuideHost<AttendanceScanScreen> {
  String? _hintTitle;
  final MobileScannerController _controller = MobileScannerController(
    detectionSpeed: DetectionSpeed.noDuplicates,
    facing: CameraFacing.back,
  );
  bool _isProcessing = false;
  bool _holdingBadCode = false;

  // Guide: only the stable UI. Never started while the permission dialog or
  // camera init is pending (controller not running), during a scan, or after
  // a scan went to the confirm screen (not resumed on pop-back).
  final GlobalKey _guideFrameKey = GlobalKey();
  final GlobalKey _guideListKey = GlobalKey();
  bool _scanStarted = false;
  bool _camRunning = false;

  @override
  String get guideScreenId => 'seller_attendance_scan';
  @override
  String get guideRole => 'seller';
  @override
  int get guideVersion => 1;
  @override
  bool get guideDataReady =>
      !_scanStarted &&
      !_isProcessing &&
      !_holdingBadCode &&
      _controller.value.isRunning &&
      _controller.value.error == null;
  @override
  String get guideSkipLabel => context.l10n.guideSkip;
  @override
  String get guideNextLabel => context.l10n.guideNext;
  @override
  String get guideDoneLabel => context.l10n.guideDone;

  void _onCameraChanged() {
    if (!mounted) return;
    final running = _controller.value.isRunning;
    final changed = running != _camRunning;
    _camRunning = running;
    if (!changed) return;
    guideDataChanged(); // camera stopped: tear a running guide down
    if (running) scheduleGuide(); // camera is up (permission granted)
  }

  @override
  List<GuideStep> buildGuideSteps(BuildContext context) {
    final l10n = context.l10n;
    return [
      GuideStep(
          key: _guideFrameKey,
          title: l10n.guideAttScanFrameTitle,
          description: l10n.guideAttScanFrameDesc),
      GuideStep(
          key: _guideListKey,
          title: l10n.guideAttScanListTitle,
          description: l10n.guideAttScanListDesc,
          targetNearBottom: true),
    ];
  }

  @override
  void initState() {
    super.initState();
    _controller.addListener(_onCameraChanged);
    _loadHint();
  }

  Future<void> _loadHint() async {
    final id = widget.hintJobPostId;
    if (id == null || id.isEmpty) return;
    try {
      final post = await JobPostsService.getJobPostDetails(id);
      if (mounted) {
        setState(() => _hintTitle = post['title'] as String?);
      }
    } catch (e, st) {
      AppLogger.error('AttendanceScan.loadHint', e, st);
      // Hint title is optional — scanner still works without it.
    }
  }

  @override
  void dispose() {
    _controller.removeListener(_onCameraChanged);
    _controller.dispose();
    super.dispose();
  }

  Future<void> _rejectUnreadableCode() async {
    _holdingBadCode = true;
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(context.l10n.notAnAttendanceCode)),
      );
    }
    try {
      await _controller.stop();
    } catch (_) {}
    await Future<void>.delayed(const Duration(milliseconds: 1200));
    if (!mounted) return;
    try {
      await _controller.start();
    } catch (_) {}
    _holdingBadCode = false;
  }

  Future<void> _onDetect(BarcodeCapture capture) async {
    if (_isProcessing || _holdingBadCode) return;
    final barcode = capture.barcodes.firstOrNull;
    final raw = barcode?.rawValue;
    if (raw == null || raw.isEmpty) return;

    final token = AttendanceService.parseTokenFromPayload(raw);
    if (token == null) {
      await _rejectUnreadableCode();
      return;
    }

    _scanStarted = true;
    setState(() => _isProcessing = true);
    await _controller.stop();

    if (!mounted) return;

    try {
      final resolve = await AttendanceService.resolveAttendanceToken(token);
      if (!mounted) return;
      final result = await Navigator.of(context).push<bool>(
        MaterialPageRoute(
          builder: (_) => AttendanceConfirmScreen(
            token: token,
            resolve: resolve,
          ),
        ),
      );
      if (mounted) {
        setState(() => _isProcessing = false);
        if (result == true) {
          Navigator.of(context).pop(true);
        } else {
          await _controller.start();
        }
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isProcessing = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(attendanceRpcMessage(context.l10n, e))),
        );
        await _controller.start();
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    return guideBackScope(Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.black,
        foregroundColor: kWhite,
        title: Text(l10n.scanAttendanceQr),
        centerTitle: true,
        actions: [GuideInfoButton(host: this)],
      ),
      body: Stack(
        fit: StackFit.expand,
        children: [
          GuideAnchor.wrap(
            GuideAnchor(
              key: _guideFrameKey,
              scope: guideScope,
              title: l10n.guideAttScanFrameTitle,
              description: l10n.guideAttScanFrameDesc,
            ),
            MobileScanner(
              controller: _controller,
              onDetect: _onDetect,
            ),
          ),
          Positioned(
            left: 24,
            right: 24,
            bottom: 32,
            child: GuideAnchor.wrap(
              GuideAnchor(
                key: _guideListKey,
                scope: guideScope,
                title: l10n.guideAttScanListTitle,
                description: l10n.guideAttScanListDesc,
                borderRadius: BorderRadius.circular(12),
              ),
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.black54,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    if (_hintTitle != null) ...[
                      Text(
                        l10n.attendanceScanningForJob(_hintTitle!),
                        textAlign: TextAlign.center,
                        style: kTextStyle.copyWith(
                          color: kWhite,
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(height: 8),
                    ],
                    Text(
                      _isProcessing
                          ? l10n.attendanceScanLoadingDetails
                          : l10n.attendanceScanCameraHint,
                      textAlign: TextAlign.center,
                      style: kTextStyle.copyWith(color: kWhite, fontSize: 14),
                    ),
                    const SizedBox(height: 12),
                    TextButton(
                      onPressed: _isProcessing
                          ? null
                          : () => context.push('/seller/attendance'),
                      child: Text(
                        l10n.viewMyOnsiteJobs,
                        style: kTextStyle.copyWith(
                          color: kWhite,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
          if (_isProcessing)
            const ColoredBox(
              color: Colors.black45,
              child: Center(
                child: CircularProgressIndicator(color: kWhite),
              ),
            ),
        ],
      ),
    ));
  }
}
