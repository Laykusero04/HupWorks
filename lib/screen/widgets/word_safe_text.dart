import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';

/// Text that only ever wraps BETWEEN words. When the longest word does not fit
/// on one line at the current size, the whole text is scaled down (never
/// below [minScale]) instead of breaking the word ("Beoordeli/ng"). If it
/// still does not fit, the last resort is the normal ellipsis.
class WordSafeText extends StatelessWidget {
  const WordSafeText(
    this.text, {
    super.key,
    this.style,
    this.maxLines = 2,
    this.textAlign,
    this.minScale = 0.7,
  });

  final String text;
  final TextStyle? style;
  final int maxLines;
  final TextAlign? textAlign;
  final double minScale;

  /// Scale (minScale..1) at which the longest word of [text] fits [maxWidth].
  static double wordScale({
    required String text,
    required TextStyle style,
    required TextScaler scaler,
    required TextDirection direction,
    required double maxWidth,
    double minScale = 0.7,
  }) {
    var widest = 0.0;
    for (final w in text.split(RegExp(r'\s+'))) {
      if (w.isEmpty) continue;
      final tp = TextPainter(
        text: TextSpan(text: w, style: style),
        textScaler: scaler,
        textDirection: direction,
        maxLines: 1,
      )..layout();
      if (tp.width > widest) widest = tp.width;
      tp.dispose();
    }
    if (widest <= maxWidth || widest == 0) return 1.0;
    final f = maxWidth / widest * 0.97; // small safety margin
    return f < minScale ? minScale : f;
  }

  @override
  Widget build(BuildContext context) {
    final base = DefaultTextStyle.of(context).style.merge(style);
    final scaler = MediaQuery.textScalerOf(context);
    final dir = Directionality.of(context);
    final measure = _WordSafeMeasure(
      text: text,
      base: base,
      scaler: scaler,
      direction: dir,
      maxLines: maxLines,
      minScale: minScale,
    );
    return _IntrinsicSafe(
      measure: measure,
      child: LayoutBuilder(builder: (context, c) {
      final f = c.maxWidth.isFinite
          ? wordScale(
              text: text,
              style: base,
              scaler: scaler,
              direction: dir,
              maxWidth: c.maxWidth,
              minScale: minScale,
            )
          : 1.0;
      return Text(
        text,
        maxLines: maxLines,
        overflow: TextOverflow.ellipsis,
        textAlign: textAlign,
        style: f < 1.0
            ? base.copyWith(fontSize: (base.fontSize ?? 14) * f)
            : style,
      );
      }),
    );
  }
}

/// Measures the text without a LayoutBuilder so the widget can answer
/// intrinsic / dry-layout queries (IntrinsicHeight, IntrinsicWidth, ...).
class _WordSafeMeasure {
  _WordSafeMeasure({
    required this.text,
    required this.base,
    required this.scaler,
    required this.direction,
    required this.maxLines,
    required this.minScale,
  });

  final String text;
  final TextStyle base;
  final TextScaler scaler;
  final TextDirection direction;
  final int maxLines;
  final double minScale;

  Size size(double maxWidth) {
    final w = maxWidth.isFinite ? maxWidth : double.infinity;
    final f = w.isFinite
        ? WordSafeText.wordScale(
            text: text,
            style: base,
            scaler: scaler,
            direction: direction,
            maxWidth: w,
            minScale: minScale,
          )
        : 1.0;
    final tp = TextPainter(
      text: TextSpan(
        text: text,
        style: f < 1.0
            ? base.copyWith(fontSize: (base.fontSize ?? 14) * f)
            : base,
      ),
      textScaler: scaler,
      textDirection: direction,
      maxLines: maxLines,
      ellipsis: '\u2026',
    )..layout(maxWidth: w);
    final r = tp.size;
    tp.dispose();
    return r;
  }

  double minWidth() {
    var widest = 0.0;
    for (final w in text.split(RegExp(r'\s+'))) {
      if (w.isEmpty) continue;
      final tp = TextPainter(
        text: TextSpan(text: w, style: base),
        textScaler: scaler,
        textDirection: direction,
        maxLines: 1,
      )..layout();
      if (tp.width > widest) widest = tp.width;
      tp.dispose();
    }
    return widest * minScale;
  }
}

class _IntrinsicSafe extends SingleChildRenderObjectWidget {
  const _IntrinsicSafe({required this.measure, required super.child});

  final _WordSafeMeasure measure;

  @override
  RenderObject createRenderObject(BuildContext context) =>
      _RenderIntrinsicSafe(measure);

  @override
  void updateRenderObject(BuildContext context, _RenderIntrinsicSafe r) {
    r.measure = measure;
  }
}

class _RenderIntrinsicSafe extends RenderProxyBox {
  _RenderIntrinsicSafe(this._measure);

  _WordSafeMeasure _measure;
  set measure(_WordSafeMeasure v) {
    _measure = v;
    markNeedsLayout();
  }

  @override
  double computeMinIntrinsicWidth(double height) => _measure.minWidth();

  @override
  double computeMaxIntrinsicWidth(double height) =>
      _measure.size(double.infinity).width;

  @override
  double computeMinIntrinsicHeight(double width) => _measure.size(width).height;

  @override
  double computeMaxIntrinsicHeight(double width) => _measure.size(width).height;

  @override
  Size computeDryLayout(BoxConstraints constraints) =>
      constraints.constrain(_measure.size(constraints.maxWidth));

  @override
  double? computeDryBaseline(
          BoxConstraints constraints, TextBaseline baseline) =>
      null;
}
