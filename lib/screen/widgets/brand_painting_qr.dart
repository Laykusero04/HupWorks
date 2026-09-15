import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:freelancer/core/constants/brand_qr_palette.dart';
import 'package:qr/qr.dart';

/// Attendance QR painted in HupWorks favicon colors (mosaic “painting” modules).
class BrandPaintingQr extends StatelessWidget {
  const BrandPaintingQr({
    super.key,
    required this.data,
    this.size = 240,
    this.padding = 12,
  });

  final String data;
  final double size;
  final double padding;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size + padding * 2,
      height: size + padding * 2,
      padding: EdgeInsets.all(padding),
      decoration: BoxDecoration(
        color: BrandQrPalette.background,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: BrandQrPalette.outline.withValues(alpha: 0.18), width: 1.5),
        boxShadow: [
          BoxShadow(
            color: BrandQrPalette.washPink.withValues(alpha: 0.12),
            blurRadius: 18,
            offset: const Offset(0, 8),
          ),
          BoxShadow(
            color: BrandQrPalette.washGreen.withValues(alpha: 0.10),
            blurRadius: 14,
            offset: const Offset(-4, 4),
          ),
        ],
      ),
      child: CustomPaint(
        size: Size.square(size),
        painter: _BrandPaintingQrPainter(data: data),
      ),
    );
  }
}

class _BrandPaintingQrPainter extends CustomPainter {
  _BrandPaintingQrPainter({required this.data});

  final String data;

  static const _finder = 7;

  @override
  void paint(Canvas canvas, Size size) {
    final qrCode = QrCode.fromData(
      data: data,
      errorCorrectLevel: QrErrorCorrectLevel.H,
    );
    final qrImage = QrImage(qrCode);
    final n = qrImage.moduleCount;
    if (n <= 0) return;

    final cell = size.width / n;

    _paintWash(canvas, size);

    // Data modules (skip finder zones — drawn as styled eyes below).
    for (var y = 0; y < n; y++) {
      for (var x = 0; x < n; x++) {
        if (_inFinder(x, y, n)) continue;
        if (!qrImage.isDark(y, x)) continue;
        _paintModule(canvas, x, y, cell, BrandQrPalette.moduleAt(x, y));
      }
    }

    _paintFinderEye(canvas, 0, 0, cell);
    _paintFinderEye(canvas, n - _finder, 0, cell);
    _paintFinderEye(canvas, 0, n - _finder, cell);
  }

  void _paintWash(Canvas canvas, Size size) {
    final washes = <(Color, Offset, double)>[
      (BrandQrPalette.washGreen, Offset(size.width * 0.15, size.height * 0.2), size.width * 0.45),
      (BrandQrPalette.washPink, Offset(size.width * 0.85, size.height * 0.25), size.width * 0.4),
      (BrandQrPalette.washYellow, Offset(size.width * 0.55, size.height * 0.8), size.width * 0.42),
      (BrandQrPalette.washCyan, Offset(size.width * 0.2, size.height * 0.75), size.width * 0.35),
      (BrandQrPalette.washOrange, Offset(size.width * 0.75, size.height * 0.55), size.width * 0.3),
    ];

    for (final (color, center, radius) in washes) {
      final paint = Paint()
        ..shader = RadialGradient(
          colors: [
            color.withValues(alpha: 0.18),
            color.withValues(alpha: 0.0),
          ],
        ).createShader(Rect.fromCircle(center: center, radius: radius));
      canvas.drawCircle(center, radius, paint);
    }
  }

  void _paintModule(Canvas canvas, int x, int y, double cell, Color color) {
    final inset = cell * 0.12;
    final rect = Rect.fromLTWH(
      x * cell + inset,
      y * cell + inset,
      cell - inset * 2,
      cell - inset * 2,
    );

    // Soft “paint bead” fill.
    final fill = Paint()
      ..shader = LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        colors: [
          Color.lerp(color, Colors.white, 0.18)!,
          color,
          Color.lerp(color, Colors.black, 0.12)!,
        ],
        stops: const [0.0, 0.55, 1.0],
      ).createShader(rect);

    canvas.drawRRect(
      RRect.fromRectAndRadius(rect, Radius.circular(cell * 0.35)),
      fill,
    );

    // Favicon-style dark stroke.
    canvas.drawRRect(
      RRect.fromRectAndRadius(rect, Radius.circular(cell * 0.35)),
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = math.max(0.6, cell * 0.06)
        ..color = BrandQrPalette.outline.withValues(alpha: 0.55),
    );
  }

  void _paintFinderEye(Canvas canvas, int originX, int originY, double cell) {
    final outer = Rect.fromLTWH(
      originX * cell,
      originY * cell,
      _finder * cell,
      _finder * cell,
    );
    final radius = Radius.circular(cell * 0.9);

    // Outer green tile.
    canvas.drawRRect(
      RRect.fromRectAndRadius(outer.deflate(cell * 0.08), radius),
      Paint()
        ..shader = LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            Color.lerp(BrandQrPalette.eyeOuter, Colors.white, 0.15)!,
            BrandQrPalette.eyeOuter,
          ],
        ).createShader(outer),
    );
    canvas.drawRRect(
      RRect.fromRectAndRadius(outer.deflate(cell * 0.08), radius),
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = cell * 0.1
        ..color = BrandQrPalette.outline.withValues(alpha: 0.7),
    );

    // White ring.
    final mid = outer.deflate(cell * 1.15);
    canvas.drawRRect(
      RRect.fromRectAndRadius(mid, Radius.circular(cell * 0.55)),
      Paint()..color = BrandQrPalette.background,
    );

    // Pink pupil (favicon dots).
    final pupil = outer.deflate(cell * 2.05);
    canvas.drawRRect(
      RRect.fromRectAndRadius(pupil, Radius.circular(cell * 0.45)),
      Paint()
        ..shader = LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            Color.lerp(BrandQrPalette.eyeInner, Colors.white, 0.2)!,
            BrandQrPalette.eyeInner,
          ],
        ).createShader(pupil),
    );
    canvas.drawRRect(
      RRect.fromRectAndRadius(pupil, Radius.circular(cell * 0.45)),
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = cell * 0.08
        ..color = BrandQrPalette.outline.withValues(alpha: 0.65),
    );
  }

  bool _inFinder(int x, int y, int n) {
    final tl = x < _finder && y < _finder;
    final tr = x >= n - _finder && y < _finder;
    final bl = x < _finder && y >= n - _finder;
    return tl || tr || bl;
  }

  @override
  bool shouldRepaint(covariant _BrandPaintingQrPainter oldDelegate) =>
      oldDelegate.data != data;
}
