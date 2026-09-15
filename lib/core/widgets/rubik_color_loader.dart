import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../constants/brand_qr_palette.dart';

/// In-app loading: flat 4×4 color tiles with the same row/column slide
/// animation as the splash [RubikLogoLoader], but solid colors only (no images).
///
/// Loops forever until removed from the tree.
class RubikColorLoader extends StatefulWidget {
  const RubikColorLoader({
    super.key,
    this.size = 56,
    this.gapFraction = 0.04,
    this.borderRadiusFraction = 0.12,
  });

  final double size;
  final double gapFraction;
  final double borderRadiusFraction;

  /// Brand mosaic — favicon / splash accents (bright faces).
  static const colors = <Color>[
    BrandQrPalette.washGreen,
    BrandQrPalette.washPink,
    BrandQrPalette.washYellow,
    BrandQrPalette.washCyan,
    BrandQrPalette.washOrange,
    Color(0xFF1D4ED8), // blue
    Color(0xFF22D3EE), // seller accent
    Color(0xFFFB923C), // orange accent
    Color(0xFF0E7A4A), // deep green
    Color(0xFFF37B9E), // pink
    Color(0xFFFAD125), // yellow
    Color(0xFF47BFFF), // cyan
    Color(0xFFF97316), // primary orange
    Color(0xFF0891B2), // seller primary
    Color(0xFFC2185B), // magenta
    Color(0xFF15803D), // lime
  ];

  @override
  State<RubikColorLoader> createState() => _RubikColorLoaderState();
}

class _RubikColorLoaderState extends State<RubikColorLoader>
    with SingleTickerProviderStateMixin {
  static const _n = 4;

  late List<Color> _face;
  late final AnimationController _twist;

  int _axis = 0;
  int _line = 0;
  int _direction = 1;
  bool _pendingCommit = false;

  final _rng = math.Random();

  @override
  void initState() {
    super.initState();
    _face = List<Color>.from(RubikColorLoader.colors);

    _twist = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 420),
    )..addStatusListener((status) {
        if (status == AnimationStatus.completed) {
          _commitTwist();
          _twist.value = 0;
          Future<void>.delayed(const Duration(milliseconds: 120), () {
            if (mounted) _playNext();
          });
        }
      });

    Future<void>.delayed(const Duration(milliseconds: 200), () {
      if (mounted) _playNext();
    });
  }

  void _playNext() {
    if (!mounted) return;

    setState(() {
      _axis = _rng.nextBool() ? 0 : 1;
      _line = _rng.nextInt(_n);
      _direction = _rng.nextBool() ? 1 : -1;
      _pendingCommit = true;
    });
    _twist.forward(from: 0);
  }

  void _commitTwist() {
    if (!_pendingCommit) return;
    _pendingCommit = false;
    final next = List<Color>.from(_face);

    if (_axis == 0) {
      final row = _line;
      final cells = List<Color>.generate(_n, (i) => next[row * _n + i]);
      final shifted = _shift(cells, _direction);
      for (var i = 0; i < _n; i++) {
        next[row * _n + i] = shifted[i];
      }
    } else {
      final col = _line;
      final cells = List<Color>.generate(_n, (i) => next[i * _n + col]);
      final shifted = _shift(cells, _direction);
      for (var i = 0; i < _n; i++) {
        next[i * _n + col] = shifted[i];
      }
    }

    setState(() => _face = next);
  }

  /// Rotate line by one step in [direction] (+1 = toward higher index).
  List<Color> _shift(List<Color> cells, int direction) {
    if (direction > 0) {
      return [cells.last, ...cells.sublist(0, cells.length - 1)];
    }
    return [...cells.sublist(1), cells.first];
  }

  @override
  void dispose() {
    _twist.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final size = widget.size;
    final gap = size * widget.gapFraction;
    final tile = (size - gap * (_n - 1)) / _n;
    final step = tile + gap;
    final span = step * _n;

    return AnimatedBuilder(
      animation: _twist,
      builder: (context, _) {
        final t = Curves.easeInOutCubic.transform(_twist.value);
        final moving = t > 0;

        return SizedBox(
          width: size,
          height: size,
          child: ClipRRect(
            borderRadius:
                BorderRadius.circular(size * widget.borderRadiusFraction),
            child: ColoredBox(
              color: Colors.transparent,
              child: Stack(
                clipBehavior: Clip.hardEdge,
                children: [
                  for (int row = 0; row < _n; row++)
                    for (int col = 0; col < _n; col++)
                      ..._paintCell(
                        row: row,
                        col: col,
                        tile: tile,
                        step: step,
                        span: span,
                        t: t,
                        moving: moving,
                      ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  List<Widget> _paintCell({
    required int row,
    required int col,
    required double tile,
    required double step,
    required double span,
    required double t,
    required bool moving,
  }) {
    final onLine = _axis == 0 ? row == _line : col == _line;
    var dx = col * step;
    var dy = row * step;

    if (moving && onLine) {
      if (_axis == 0) {
        dx += _direction * t * step;
      } else {
        dy += _direction * t * step;
      }
    }

    final color = _face[row * _n + col];
    final widgets = <Widget>[_pos(dx, dy, tile, color)];

    if (moving && onLine) {
      if (_axis == 0) {
        widgets.add(_pos(dx - span, dy, tile, color));
        widgets.add(_pos(dx + span, dy, tile, color));
      } else {
        widgets.add(_pos(dx, dy - span, tile, color));
        widgets.add(_pos(dx, dy + span, tile, color));
      }
    }

    return widgets;
  }

  Widget _pos(double left, double top, double tile, Color color) {
    final r = tile * 0.18;
    return Positioned(
      left: left,
      top: top,
      width: tile,
      height: tile,
      child: DecoratedBox(
        decoration: BoxDecoration(
          color: color,
          borderRadius: BorderRadius.circular(r),
        ),
      ),
    );
  }
}
