import 'package:flutter/material.dart';
import 'package:freelancer/services/attendance_service.dart';
import 'package:nb_utils/nb_utils.dart';
import 'package:qr_flutter/qr_flutter.dart';
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
          SnackBar(content: Text('Error: $e')),
        );
      }
    }
  }

  Future<void> _regenerate() async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Regenerate QR?'),
        content: const Text(
          'The old printed QR will stop working. Print and post the new code at your site.',
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Cancel')),
          TextButton(onPressed: () => Navigator.pop(ctx, true), child: const Text('Regenerate')),
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
          const SnackBar(content: Text('New attendance QR ready')),
        );
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isRegenerating = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e')),
        );
      }
    }
  }

  Future<void> _share() async {
    if (_qrPayload == null) return;
    await SharePlus.instance.share(
      ShareParams(
        text: 'HupWorks attendance QR for "${widget.jobTitle}":\n$_qrPayload\n\n'
            'Post this code at the job site. Freelancers scan it to clock in and out.',
        subject: 'HupWorks attendance QR',
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: kDarkWhite,
      appBar: AppBar(
        backgroundColor: kDarkWhite,
        elevation: 0,
        iconTheme: const IconThemeData(color: kNeutralColor),
        title: Text(
          'Attendance QR',
          style: kTextStyle.copyWith(
            color: kNeutralColor,
            fontWeight: FontWeight.bold,
          ),
        ),
        centerTitle: true,
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator(color: kPrimaryColor))
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
                    'Print this QR and post it where workers check in.',
                    textAlign: TextAlign.center,
                    style: kTextStyle.copyWith(color: kSubTitleColor),
                  ),
                  const SizedBox(height: 24),
                  if (_qrPayload != null)
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: kWhite,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: kBorderColorTextField),
                      ),
                      child: QrImageView(
                        data: _qrPayload!,
                        version: QrVersions.auto,
                        size: 240,
                        backgroundColor: Colors.white,
                      ),
                    )
                  else
                    Text(
                      'Could not load QR',
                      style: kTextStyle.copyWith(color: kSubTitleColor),
                    ),
                  const SizedBox(height: 24),
                  if (_isRegenerating)
                    const CircularProgressIndicator(color: kPrimaryColor)
                  else ...[
                    ButtonGlobalWithoutIcon(
                      buttontext: 'Share / Print instructions',
                      buttonDecoration:
                          kButtonDecoration.copyWith(color: kPrimaryColor),
                      buttonTextColor: kWhite,
                      onPressed: _qrPayload == null ? () {} : _share,
                    ),
                    const SizedBox(height: 12),
                    ButtonGlobalWithoutIcon(
                      buttontext: 'Regenerate QR',
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
                          'How it works',
                          style: kTextStyle.copyWith(
                            fontWeight: FontWeight.bold,
                            color: const Color(0xFF2E7D32),
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          '1. Print and tape this QR at the workplace.\n'
                          '2. Hired freelancers open HupWorks and scan it.\n'
                          '3. They confirm clock in or clock out on their phone.\n'
                          '4. You can view today\'s attendance on the job details screen.',
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
