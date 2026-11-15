import 'package:flutter/material.dart';

import 'word_safe_text.dart';

/// "Label : value" detail row. Side by side (label column 2 : value column 4)
/// while the longest label word fits its column; otherwise (text scale above
/// 1.3, a narrow screen, a long word such as "Revisions" / "Beoordeling") the
/// label is stacked ABOVE the value so nothing breaks mid-word.
///
/// Uses a LayoutBuilder: do NOT place it under IntrinsicHeight/IntrinsicWidth
/// (the value widget is arbitrary, so intrinsics cannot be answered here).
class LabelValueRow extends StatelessWidget {
  const LabelValueRow({
    super.key,
    required this.label,
    required this.labelStyle,
    required this.colon,
    required this.value,
  });

  final String label;
  final TextStyle labelStyle;

  /// Separator shown before the value in the side-by-side layout.
  final String colon;
  final Widget value;

  /// True when the row must stack for [label] in [maxWidth] at [scaler].
  static bool shouldStack({
    required String label,
    required TextStyle style,
    required TextScaler scaler,
    required TextDirection direction,
    required double maxWidth,
  }) {
    if (scaler.scale(10) / 10 > 1.3) return true;
    if (maxWidth < 240) return true;
    final labelColumn = maxWidth * 2 / 6;
    return WordSafeText.wordScale(
          text: label,
          style: style,
          scaler: scaler,
          direction: direction,
          maxWidth: labelColumn,
          minScale: 0.0,
        ) <
        1.0;
  }

  @override
  Widget build(BuildContext context) {
    final scaler = MediaQuery.textScalerOf(context);
    final dir = Directionality.of(context);
    final style = DefaultTextStyle.of(context).style.merge(labelStyle);
    return LayoutBuilder(builder: (context, c) {
      final stack = shouldStack(
        label: label,
        style: style,
        scaler: scaler,
        direction: dir,
        maxWidth: c.maxWidth,
      );
      if (stack) {
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(label, style: labelStyle),
            const SizedBox(height: 2),
            value,
          ],
        );
      }
      return Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(flex: 2, child: Text(label, style: labelStyle)),
          Expanded(
            flex: 4,
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(colon, style: labelStyle),
                const SizedBox(width: 10.0),
                Flexible(child: value),
              ],
            ),
          ),
        ],
      );
    });
  }
}
