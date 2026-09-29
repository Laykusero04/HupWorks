import 'dart:io';
import 'dart:ui' as ui;

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:freelancer/core/utils/attendance_location.dart';
import 'package:freelancer/core/widgets/loading_widget.dart';
import 'package:freelancer/l10n/l10n.dart';
import 'package:freelancer/screen/widgets/brand_painting_qr.dart';
import 'package:freelancer/services/attendance_service.dart';
import 'package:nb_utils/nb_utils.dart';
import 'package:share_plus/share_plus.dart';

import '../widgets/button_global.dart';
import '../widgets/constant.dart';

class AttendanceQrDisplayScreen extends StatefulWidget {
  final String jobPostId;
  final String jobTitle;

  const AttendanceQrDisplayScreen({
    super.key,
    required this.jobPostId,
    required this.jobTitle,
  });

  @override
  State<AttendanceQrDisplayScreen> createState() =>
      _AttendanceQrDisplayScreenState();
}

class _AttendanceQrDisplayScreenState extends State<AttendanceQrDisplayScreen> {
  String? _qrPayload;
  bool _isLoading = true;
  bool _isRegenerating = false;
  bool _isSharing = false;

  @override
  void initState() {
    super.initState();
    _loadToken();
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
          SnackBar(content: Text(attendanceRpcMessage(context.l10n, e))),
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
          SnackBar(content: Text(attendanceRpcMessage(context.l10n, e))),
        );
      }
    }
  }

  Future<void> _share() async {
    final payload = _qrPayload;
    if (payload == null || _isSharing) return;

    final l10n = context.l10n;
    final box = context.findRenderObject() as RenderBox?;
    final origin = box == null || !box.hasSize
        ? null
        : box.localToGlobal(Offset.zero) & box.size;

    setState(() => _isSharing = true);
    ui.Image? image;
    File? file;
    try {
      image = await BrandPaintingQr.posterImage(
        data: payload,
        title: widget.jobTitle,
        caption: l10n.attendanceShareQrCaption,
      );
      final bytes = await image.toByteData(format: ui.ImageByteFormat.png);
      if (bytes == null) {
        throw StateError('Could not encode attendance QR');
      }
      final png = bytes.buffer.asUint8List();
      // Instructions only. The token stays inside the image, not the message.
      final message = l10n.attendanceShareQrMessage(widget.jobTitle);

      if (kIsWeb) {
        await SharePlus.instance.share(
          ShareParams(
            files: [
              XFile.fromData(
                png,
                mimeType: 'image/png',
                name: 'hupworks-attendance-qr.png',
              ),
            ],
            text: message,
            subject: l10n.attendanceShareQrSubject,
            sharePositionOrigin: origin,
          ),
        );
      } else {
        file = File(
          '${Directory.systemTemp.path}/hupworks-attendance-qr-${DateTime.now().millisecondsSinceEpoch}.png',
        );
        await file.writeAsBytes(png, flush: true);
        await SharePlus.instance.share(
          ShareParams(
            files: [
              XFile(
                file.path,
                mimeType: 'image/png',
                name: 'hupworks-attendance-qr.png',
              ),
            ],
            text: message,
            subject: l10n.attendanceShareQrSubject,
            sharePositionOrigin: origin,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(context.l10n.errorWithDetail('$e'))),
        );
      }
    } finally {
      image?.dispose();
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
      body: _isLoading
          ? const LoadingWidget()
          : SingleChildScrollView(
              padding: const EdgeInsets.all(20),
              child: Column(
                children: [
                  Text(
                    widget.jobTitle,
                    textAlign: TextAlign.center,
                    style: kTextStyle.copyWith(
                      color: kNeutralColor,
                      fontWeight: FontWeight.bold,
                      fontSize: 18,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    l10n.attendancePrintQrAtSite,
                    textAlign: TextAlign.center,
                    style: kTextStyle.copyWith(color: kSubTitleColor),
                  ),
                  const SizedBox(height: 24),
                  if (_qrPayload != null)
                    BrandPaintingQr(
                      data: _qrPayload!,
                      size: 260,
                    )
                  else
                    Text(
                      l10n.attendanceCouldNotLoadQr,
                      style: kTextStyle.copyWith(color: kSubTitleColor),
                    ),
                  const SizedBox(height: 24),
                  if (_isRegenerating)
                    const CircularProgressIndicator(color: kPrimaryColor)
                  else ...[
                    ButtonGlobalWithoutIcon(
                      buttontext: l10n.attendanceSharePrintInstructions,
                      buttonDecoration:
                          kButtonDecoration.copyWith(color: kPrimaryColor),
                      buttonTextColor: kWhite,
                      onPressed: _qrPayload == null || _isSharing ? null : _share,
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
