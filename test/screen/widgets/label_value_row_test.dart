import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:freelancer/core/guide/guide_config.dart';
import 'package:freelancer/screen/widgets/label_value_row.dart';
import 'package:freelancer/screen/widgets/word_safe_text.dart';

Widget _app(double width, double scale, Widget child) => MediaQuery(
      data: MediaQueryData(
          size: Size(width, 800), textScaler: TextScaler.linear(scale)),
      child: MaterialApp(
        home: Scaffold(
            body: Align(
                alignment: Alignment.topLeft,
                child: SizedBox(width: width, child: child))),
      ),
    );

void main() {
  const row = LabelValueRow(
    label: 'Revisions',
    labelStyle: TextStyle(fontSize: 14),
    colon: ':',
    value: Text('Per job agreement', style: TextStyle(fontSize: 14)),
  );

  testWidgets('wide + default scale: label and value side by side', (t) async {
    await t.pumpWidget(_app(900, 1.0, row));
    final l = t.getRect(find.text('Revisions'));
    final v = t.getRect(find.text('Per job agreement'));
    expect((l.center.dy - v.center.dy).abs(), lessThan(4));
    expect(v.left, greaterThan(l.right));
  });

  testWidgets('scale above 1.3: label stacked above value, no overflow',
      (t) async {
    await t.pumpWidget(_app(375, 2.0, row));
    expect(t.takeException(), isNull);
    final l = t.getRect(find.text('Revisions'));
    final v = t.getRect(find.text('Per job agreement'));
    expect(v.top, greaterThanOrEqualTo(l.bottom));
    expect(v.left, l.left);
    // Label is one line (never broken mid-word).
    expect(t.getSize(find.text('Revisions')).height, lessThan(14 * 2 * 1.5));
  });

  testWidgets('narrow width stacks even at scale 1.0', (t) async {
    await t.pumpWidget(_app(220, 1.0, row));
    expect(t.takeException(), isNull);
    final l = t.getRect(find.text('Revisions'));
    final v = t.getRect(find.text('Per job agreement'));
    expect(v.top, greaterThanOrEqualTo(l.bottom));
  });

  testWidgets('WordSafeText scales down instead of breaking a long word',
      (t) async {
    await t.pumpWidget(_app(
        150,
        1.0,
        const WordSafeText('Overeenkomsten',
            style: TextStyle(fontSize: 14), maxLines: 2)));
    final txt = t.widget<Text>(find.text('Overeenkomsten'));
    expect(txt.style!.fontSize!, lessThan(14));
    expect(t.getSize(find.text('Overeenkomsten')).height, lessThan(14 * 1.5));
  });

  test('tour text: rendered size capped at 1.3x, never below base', () {
    // 18pt title at system scale 2.0: font size solved so it renders at 23.4.
    final f = GuideConfig.fitSize(18, scaler: const TextScaler.linear(2.0));
    expect(TextScaler.linear(2.0).scale(f), closeTo(18 * 1.3, 0.01));
    // At or under the cap nothing changes.
    expect(GuideConfig.fitSize(18, scaler: const TextScaler.linear(1.2)), 18);
    expect(GuideConfig.fitSize(15, scaler: TextScaler.noScaling), 15);
    // Ambient already capped (nav tile, 1.25): base size, never smaller.
    expect(
        GuideConfig.fitSize(15,
            scaler: const TextScaler.linear(3.0), ambientCap: 1.25),
        15);
    // Rendered size is never below the base size.
    for (final s in [1.0, 1.5, 2.0, 3.0]) {
      final r = TextScaler.linear(s)
          .scale(GuideConfig.fitSize(15, scaler: TextScaler.linear(s)));
      expect(r, greaterThanOrEqualTo(15));
    }
  });
}
