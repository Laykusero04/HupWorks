import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:freelancer/core/guide/showcase_guide_runner.dart';

PillSlot pick(Rect? target,
        {double scale = 1,
        bool rtl = false,
        bool nearBottom = false,
        double? pillWidth,
        List<Rect> keepOut = const []}) =>
    ShowcaseGuideRunner.pickPillSlot(
      target: target,
      screen: const Size(375, 667),
      topInset: 20,
      bottomOffset: 90,
      scale: scale,
      rtl: rtl,
      targetNearBottom: nearBottom,
      tooltipEstimate: 170,
      pillWidth: pillWidth,
      keepOut: keepOut,
    );

void main() {
  const bell = Rect.fromLTWH(320, 24, 44, 44); // top-end header icon
  const menu = Rect.fromLTWH(4, 24, 44, 44); // top-start header icon

  test('high target in the upper area keeps the pill at bottom-start', () {
    expect(pick(const Rect.fromLTWH(20, 90, 335, 60)), PillSlot.bottomStart);
  });

  test('target in the lower half moves the pill to the top', () {
    expect(pick(const Rect.fromLTWH(20, 450, 335, 60)), PillSlot.topEnd);
  });

  test('pill never overlaps the target: bell (top-end) -> not top-end', () {
    // Old logic put the pill top-end whenever the tooltip could reach the
    // bottom band, which covered the bell at XL (T-0150 F2).
    for (final scale in [1.0, 1.5, 2.0]) {
      final slot = pick(bell, scale: scale);
      expect(slot, isNot(PillSlot.topEnd), reason: 'scale $scale');
    }
  });

  test('menu target (top-start) is never covered by a top-start pill', () {
    // Low flag forces the top slots; the menu sits under top-start.
    expect(pick(menu, scale: 2.0, nearBottom: true), PillSlot.topEnd);
    expect(pick(menu), isNot(PillSlot.topStart));
  });

  test('rtl flips which top corner is the logical end', () {
    // Target sits in the physical top-left corner.
    const topLeft = Rect.fromLTWH(4, 24, 44, 44);
    // LTR: topEnd is the right edge, free.
    expect(pick(topLeft, nearBottom: true), PillSlot.topEnd);
    // RTL: topEnd is the LEFT edge, covered -> topStart (right edge).
    expect(pick(topLeft, rtl: true, nearBottom: true), PillSlot.topStart);
  });

  test('tooltip estimate rejects bottom-start for a mid-high target', () {
    // bottomY = 667 - 90 - 48 = 529. Bottom 360 + 170 = 530 > 529.
    const t = Rect.fromLTWH(20, 300, 335, 60);
    expect(pick(t), PillSlot.topEnd);
    const ok = Rect.fromLTWH(20, 290, 335, 60); // 350 + 170 = 520 <= 529
    expect(pick(ok), PillSlot.bottomStart);
  });

  test('tooltip estimate grows with text scale', () {
    const t = Rect.fromLTWH(20, 200, 335, 60); // bottom 260
    expect(pick(t), PillSlot.bottomStart);
    expect(pick(t, scale: 2.0), isNot(PillSlot.bottomStart));
  });

  test('wide measured pill (NL label) is rejected where a narrow one fits', () {
    const t = Rect.fromLTWH(190, 24, 60, 44);
    // 100dp pill at top-end spans x 263..363, clear of target (182..258).
    expect(pick(t, nearBottom: true, pillWidth: 100), PillSlot.topEnd);
    // 190dp pill spans 173..363 and overlaps the target.
    expect(pick(t, nearBottom: true, pillWidth: 190), isNot(PillSlot.topEnd));
  });

  test('every slot colliding docks Skip in the tooltip (T-0158 B1)', () {
    const all = Rect.fromLTWH(0, 0, 375, 667);
    expect(pick(all), PillSlot.docked);
    expect(pick(all, rtl: true), PillSlot.docked);
  });

  test('title + header icons + bottom button keep-outs dock Skip', () {
    const lowTarget = Rect.fromLTWH(0, 560, 375, 40);
    const title = Rect.fromLTWH(60, 24, 200, 44);
    const help = Rect.fromLTWH(320, 24, 44, 44);
    const submit = Rect.fromLTWH(16, 590, 343, 56);
    expect(pick(lowTarget, keepOut: [title, help, submit]), PillSlot.docked);
    // XL: title wide, pill (scaled) cannot sit in the free top-start gap.
    expect(pick(lowTarget, scale: 2.0, keepOut: [title, help, submit]),
        PillSlot.docked);
    // A free slot still wins over docking.
    expect(pick(lowTarget, keepOut: [help, submit]), PillSlot.topStart);
  });

  test('header action icons are keep-out: pill avoids the help icon (B5)', () {
    const lowTarget = Rect.fromLTWH(0, 600, 375, 60);
    const help = Rect.fromLTWH(270, 24, 44, 44);
    expect(pick(lowTarget), PillSlot.topEnd);
    expect(pick(lowTarget, keepOut: [help]), PillSlot.topStart);
    const menuK = Rect.fromLTWH(4, 24, 44, 44);
    expect(pick(lowTarget, keepOut: [help, menuK]), PillSlot.bottomEnd);
  });
}
