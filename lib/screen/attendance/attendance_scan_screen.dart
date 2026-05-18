import 'package:flutter/material.dart';
import 'package:freelancer/services/attendance_service.dart';
import 'package:mobile_scanner/mobile_scanner.dart';

import '../widgets/constant.dart';
import 'attendance_confirm_screen.dart';

class AttendanceScanScreen extends StatefulWidget {
  const AttendanceScanScreen({super.key});

  @override
  State<AttendanceScanScreen> createState() => _AttendanceScanScreenState();
}

class _AttendanceScanScreenState extends State<AttendanceScanScreen> {
  final MobileScannerController _controller = MobileScannerController(
    detectionSpeed: DetectionSpeed.noDuplicates,
    facing: CameraFacing.back,
  );
  bool _isProcessing = false;

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Future<void> _onDetect(BarcodeCapture capture) async {
    if (_isProcessing) return;
    final barcode = capture.barcodes.firstOrNull;
    final raw = barcode?.rawValue;
    if (raw == null || raw.isEmpty) return;

    final token = AttendanceService.parseTokenFromPayload(raw);
    if (token == null) return;

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
          SnackBar(content: Text('$e')),
        );
        await _controller.start();
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.black,
        foregroundColor: kWhite,
        title: const Text('Scan attendance QR'),
        centerTitle: true,
      ),
      body: Stack(
        fit: StackFit.expand,
        children: [
          MobileScanner(
            controller: _controller,
            onDetect: _onDetect,
          ),
          Positioned(
            left: 24,
            right: 24,
            bottom: 32,
            child: Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.black54,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Text(
                _isProcessing
                    ? 'Loading job details…'
                    : 'Point your camera at the attendance QR posted at the job site.',
                textAlign: TextAlign.center,
                style: kTextStyle.copyWith(color: kWhite, fontSize: 14),
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
    );
  }
}
