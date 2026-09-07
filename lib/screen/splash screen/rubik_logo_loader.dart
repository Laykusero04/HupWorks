import 'dart:math' as math;

import 'package:flutter/material.dart';

/// Individual favicon tiles cut from [images/HupWorks.png].
///
/// Folder: `images/rubik_tiles/`
/// ```
/// tile_0_0  tile_0_1  tile_0_2
/// tile_1_0  tile_1_1  tile_1_2
/// tile_2_0  tile_2_1  tile_2_2
/// ```
class RubikTiles {
  RubikTiles._();

  static const folder = 'images/rubik_tiles';

  static const assets = <String>[
    '$folder/tile_0_0.png',
    '$folder/tile_0_1.png',
    '$folder/tile_0_2.png',
    '$folder/tile_1_0.png',
    '$folder/tile_1_1.png',
    '$folder/tile_1_2.png',
    '$folder/tile_2_0.png',
    '$folder/tile_2_1.png',
    '$folder/tile_2_2.png',
  ];

  static String assetFor(int index) => assets[index.clamp(0, assets.length - 1)];
}

class _RubikMove {
  const _RubikMove({
    required this.axis,
    required this.line,
    required this.direction,
  });

  final int axis; // 0 row, 1 col
  final int line;
  final int direction; // +1 or -1

  _RubikMove get reversed => _RubikMove(
        axis: axis,
        line: line,
        direction: -direction,
      );
}

/// Flat 2D Rubik intro: scramble tiles, solve back to the logo, then [onCompleted].
class RubikLogoLoader extends StatefulWidget {
  const RubikLogoLoader({
    super.key,
    this.size = 220,
    this.scrambleMoves = 5,
    this.onCompleted,
  });

  final double size;

  /// How many slides to play before reversing back to the solved logo.
  final int scrambleMoves;

  /// Fired once the solved logo is shown again (animation finished).
  final VoidCallback? onCompleted;

  @override
  State<RubikLogoLoader> createState() => _RubikLogoLoaderState();
}

class _RubikLogoLoaderState extends State<RubikLogoLoader>
    with SingleTickerProviderStateMixin {
  late List<int> _face;
  late final AnimationController _twist;

  int _axis = 0;
  int _line = 1;
  int _direction = 1;
  bool _pendingCommit = false;
  bool _finished = false;

  final _rng = math.Random();
  List<_RubikMove> _queue = [];
  int _queueIndex = 0;

  @override
  void initState() {
    super.initState();
    _face = List<int>.generate(9, (i) => i);
    _queue = _buildSequence(widget.scrambleMoves);

    _twist = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 480),
    )..addStatusListener((status) {
        if (status == AnimationStatus.completed) {
          _commitTwist();
          _twist.value = 0;
          // Short pause between slides so each move reads clearly.
          Future<void>.delayed(const Duration(milliseconds: 160), () {
            if (mounted) _playNext();
          });
        }
      });

    // Short beat so the solved logo is visible before the first slide.
    Future<void>.delayed(const Duration(milliseconds: 400), () {
      if (mounted) _playNext();
    });
  }

  List<_RubikMove> _buildSequence(int scrambleCount) {
    final scramble = <_RubikMove>[];
    for (var i = 0; i < scrambleCount; i++) {
      scramble.add(
        _RubikMove(
          axis: _rng.nextBool() ? 0 : 1,
          line: _rng.nextInt(3),
          direction: _rng.nextBool() ? 1 : -1,
        ),
      );
    }
    // Solve by undoing scramble in reverse order.
    final solve = scramble.reversed.map((m) => m.reversed).toList();
    return [...scramble, ...solve];
  }

  void _playNext() {
    if (!mounted || _finished) return;

    if (_queueIndex >= _queue.length) {
      _finish();
      return;
    }

    final move = _queue[_queueIndex++];
    setState(() {
      _axis = move.axis;
      _line = move.line;
      _direction = move.direction;
      _pendingCommit = true;
    });
    _twist.forward(from: 0);
  }

  Future<void> _finish() async {
    if (_finished) return;
    _finished = true;
    // Hold the solved logo briefly so it reads as complete.
    await Future<void>.delayed(const Duration(milliseconds: 550));
    if (!mounted) return;
    widget.onCompleted?.call();
  }

  void _commitTwist() {
    if (!_pendingCommit) return;
    _pendingCommit = false;
    final next = List<int>.from(_face);

    if (_axis == 0) {
      final row = _line;
      final a = next[row * 3];
      final b = next[row * 3 + 1];
      final c = next[row * 3 + 2];
      if (_direction > 0) {
        next[row * 3] = c;
        next[row * 3 + 1] = a;
        next[row * 3 + 2] = b;
      } else {
        next[row * 3] = b;
        next[row * 3 + 1] = c;
        next[row * 3 + 2] = a;
      }
    } else {
      final col = _line;
      final a = next[col];
      final b = next[3 + col];
      final c = next[6 + col];
      if (_direction > 0) {
        next[col] = c;
        next[3 + col] = a;
        next[6 + col] = b;
      } else {
        next[col] = b;
        next[3 + col] = c;
        next[6 + col] = a;
      }
    }

    setState(() => _face = next);
  }

  @override
  void dispose() {
    _twist.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final size = widget.size;
    final gap = size * 0.02;
    final tile = (size - gap * 2) / 3;
    final step = tile + gap;
    final span = step * 3;

    return AnimatedBuilder(
      animation: _twist,
      builder: (context, _) {
        final t = Curves.easeInOutCubic.transform(_twist.value);
        final moving = t > 0;

        return SizedBox(
          width: size,
          height: size,
          child: ClipRRect(
            borderRadius: BorderRadius.circular(size * 0.06),
            child: ColoredBox(
              color: const Color(0xFF0A0A0A),
              child: Stack(
                clipBehavior: Clip.hardEdge,
                children: [
                  for (int row = 0; row < 3; row++)
                    for (int col = 0; col < 3; col++)
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

    final asset = RubikTiles.assetFor(_face[row * 3 + col]);
    final widgets = <Widget>[_pos(dx, dy, tile, asset)];

    if (moving && onLine) {
      if (_axis == 0) {
        widgets.add(_pos(dx - span, dy, tile, asset));
        widgets.add(_pos(dx + span, dy, tile, asset));
      } else {
        widgets.add(_pos(dx, dy - span, tile, asset));
        widgets.add(_pos(dx, dy + span, tile, asset));
      }
    }

    return widgets;
  }

  Widget _pos(double left, double top, double tile, String asset) {
    return Positioned(
      left: left,
      top: top,
      width: tile,
      height: tile,
      child: Image.asset(
        asset,
        fit: BoxFit.cover,
        filterQuality: FilterQuality.high,
        gaplessPlayback: true,
      ),
    );
  }
}
