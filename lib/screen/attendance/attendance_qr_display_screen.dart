import 'dart:io';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:freelancer/core/constants/brand_qr_palette.dart';
import 'package:freelancer/core/widgets/loading_widget.dart';
import 'package:freelancer/l10n/l10n.dart';
import 'package:freelancer/screen/attendance/ensure_job_site_pin.dart';
import 'package:freelancer/screen/widgets/brand_painting_qr.dart';
import 'package:freelancer/services/attendance_service.dart';
import 'package:nb_utils/nb_utils.dart';
import 'package:share_plus/share_plus.dart';

import '../widgets/button_global.dart';
import '../widgets/constant.dart';

class AttendanceQrDisplayScreen extends StatefulWidget {
  final String jobPostId;
  final String jobTitle;
  /// Optional job map used to skip a fetch when pin is already known.
  final Map<String, dynamic>? jobPost;

  const AttendanceQrDisplayScreen({
    super.key,
    required this.jobPostId,
    required this.jobTitle,
    this.jobPost,
  });

  @override
  State<AttendanceQrDisplayScreen> createState() =>
      _AttendanceQrDisplayScreenState();
}

class _AttendanceQrDisplayScreenState extends State<AttendanceQrDisplayScreen> {
  final GlobalKey _posterKey = GlobalKey();

  String? _qrPayload;
  bool _isLoading = true;
  bool _isRegenerating = false;
  bool _isSharing = false;
  bool _pinReady = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _ensurePinThenLoad());
  }

  Future<void> _ensurePinThenLoad() async {
    final pinned = await ensureJobSitePinForQr(
      context: context,
      jobPostId: widget.jobPostId,
      jobPost: widget.jobPost,
    );
    if (!mounted) return;
    if (pinned == null) {
      Navigator.pop(context);
      return;
    }
    setState(() => _pinReady = true);
    await _loadToken();
  }

  Future<void> _loadToken({bool generateIfMissing = true}) async {
    setState(() => _isLoading = true);
    try {
      var result = await AttendanceService.getJobAttendanceToken(widget.jobPostId);
      if (!result.hasToken && generateIfMissing) {
        result = await AttendanceService.generateJobAttendanceToken(widget.jobPostId);
      }
      if (mounted) {
        setState(() {
          _qrPayload = result.qrPayload;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(context.l10n.errorWithDetail('$e'))),
        );
      }
    }
  }

  Future<void> _regenerate() async {
    final l10n = context.l10n;
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(l10n.regenerateQrConfirmTitle),
        content: Text(l10n.regenerateQrConfirmBody),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: Text(l10n.cancel)),
          TextButton(onPressed: () => Navigator.pop(ctx, true), child: Text(l10n.regenerate)),
        ],
      ),
    );
    if (confirm != true || !mounted) return;

    setState(() => _isRegenerating = true);
    try {
      final result =
          await AttendanceService.generateJobAttendanceToken(widget.jobPostId);
      if (mounted) {
        setState(() {
          _qrPayload = result.qrPayload;
          _isRegenerating = false;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(l10n.attendanceNewQrReady)),
        );
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isRegenerating = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(context.l10n.errorWithDetail('$e'))),
        );
      }
    }
  }

  /// Shares a poster image only — never includes the `hupworks://attendance/...` deep link.
  Future<void> _share() async {
    if (_qrPayload == null || _isSharing) return;
    final l10n = context.l10n;
    setState(() => _isSharing = true);
    try {
      // Ensure the poster has finished a paint pass before capture.
      await Future<void>.delayed(Duration.zero);
      await WidgetsBinding.instance.endOfFrame;

      final boundary =
          _posterKey.currentContext?.findRenderObject() as RenderRepaintBoundary?;
      if (boundary == null) {
        throw StateError('poster not ready');
      }

      final image = await boundary.toImage(pixelRatio: 3);
      final byteData = await image.toByteData(format: ui.ImageByteFormat.png);
      image.dispose();
      if (byteData == null) {
        throw StateError('empty poster bytes');
      }

      final file = File(
        '${Directory.systemTemp.path}/hupworks_attendance_qr_${widget.jobPostId}.png',
      );
      await file.writeAsBytes(byteData.buffer.asUint8List(), flush: true);

      // Image file only — no text/body that could leak the deep link.
      await SharePlus.instance.share(
        ShareParams(
          files: [
            XFile(
              file.path,
              mimeType: 'image/png',
              name: 'hupworks_attendance_qr.png',
            ),
          ],
        ),
      );
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              e is StateError
                  ? l10n.attendanceCouldNotShareQrPoster
                  : l10n.errorWithDetail('$e'),
            ),
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isSharing = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    return Scaffold(
      backgroundColor: kDarkWhite,
      appBar: AppBar(
        backgroundColor: kDarkWhite,
        elevation: 0,
        iconTheme: const IconThemeData(color: kNeutralColor),
        title: Text(
          l10n.attendanceQrScreenTitle,
          style: kTextStyle.copyWith(
            color: kNeutralColor,
            fontWeight: FontWeight.bold,
          ),
        ),
        centerTitle: true,
      ),
      body: (!_pinReady || _isLoading)
          ? const LoadingWidget()
          : SingleChildScrollView(
              padding: const EdgeInsets.all(20),
              child: Column(
                children: [
                  if (_qrPayload != null)
                    RepaintBoundary(
                      key: _posterKey,
                      child: _AttendanceQrPoster(
                        jobTitle: widget.jobTitle,
                        qrPayload: _qrPayload!,
                        printHint: l10n.attendancePrintAndPostAtSite,
                      ),
                    )
                  else
                    Text(
                      l10n.attendanceCouldNotLoadQr,
                      style: kTextStyle.copyWith(color: kSubTitleColor),
                    ),
                  const SizedBox(height: 24),
                  if (_isRegenerating || _isSharing)
                    const CircularProgressIndicator(color: kPrimaryColor)
                  else ...[
                    ButtonGlobalWithoutIcon(
                      buttontext: l10n.attendanceSharePrintInstructions,
                      buttonDecoration:
                          kButtonDecoration.copyWith(color: kPrimaryColor),
                      buttonTextColor: kWhite,
                      onPressed: _qrPayload == null ? () {} : _share,
                    ),
                    const SizedBox(height: 12),
                    ButtonGlobalWithoutIcon(
                      buttontext: l10n.regenerateQr,
                      buttonDecoration: kButtonDecoration.copyWith(
                        color: kWhite,
                        border: Border.all(color: kPrimaryColor),
                      ),
                      buttonTextColor: kPrimaryColor,
                      onPressed: _regenerate,
                    ),
                  ],
                  const SizedBox(height: 24),
                  Container(
                    width: context.width(),
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: const Color(0xFFE8F5E9),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          l10n.attendanceHowItWorks,
                          style: kTextStyle.copyWith(
                            fontWeight: FontWeight.bold,
                            color: const Color(0xFF2E7D32),
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          l10n.attendanceHowItWorksBody,
                          style: kTextStyle.copyWith(
                            color: const Color(0xFF2E7D32),
                            fontSize: 13,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
    );
  }
}

/// Printable poster: job title + QR + “print & post at site”.
class _AttendanceQrPoster extends StatelessWidget {
  const _AttendanceQrPoster({
    required this.jobTitle,
    required this.qrPayload,
    required this.printHint,
  });

  final String jobTitle;
  final String qrPayload;
  final String printHint;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(24, 28, 24, 24),
      decoration: BoxDecoration(
        color: BrandQrPalette.background,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: BrandQrPalette.outline.withValues(alpha: 0.12),
        ),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            'HupWorks',
            style: kTextStyle.copyWith(
              color: BrandQrPalette.eyeOuter,
              fontWeight: FontWeight.w800,
              fontSize: 13,
              letterSpacing: 0.6,
            ),
          ),
          const SizedBox(height: 10),
          Text(
            jobTitle,
            textAlign: TextAlign.center,
            style: kTextStyle.copyWith(
              color: kNeutralColor,
              fontWeight: FontWeight.bold,
              fontSize: 20,
              height: 1.25,
            ),
          ),
          const SizedBox(height: 20),
          BrandPaintingQr(
            data: qrPayload,
            size: 260,
          ),
          const SizedBox(height: 18),
          Text(
            printHint,
            textAlign: TextAlign.center,
            style: kTextStyle.copyWith(
              color: kSubTitleColor,
              fontWeight: FontWeight.w600,
              fontSize: 15,
            ),
          ),
        ],
      ),
    );
  }
}
