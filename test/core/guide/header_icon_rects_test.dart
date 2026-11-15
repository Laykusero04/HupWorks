import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:freelancer/core/guide/guide_session.dart';
import 'package:freelancer/core/guide/showcase_guide_runner.dart';

Widget _page(List<Widget> actions) => Scaffold(
      appBar: AppBar(title: const Text('t'), actions: actions),
      body: const SizedBox(),
    );

void main() {
  testWidgets('header rects: IconButton and InkWell+Icon actions are found',
      (t) async {
    await t.pumpWidget(MaterialApp(
      home: _page([
        IconButton(icon: const Icon(Icons.help), onPressed: () {}),
        InkWell(onTap: () {}, child: const Icon(Icons.notifications_none)),
      ]),
    ));
    expect(ShowcaseGuideRunner.headerIconRects(0, 1).length, 2);
  });

  testWidgets('header rects ignore covered (non-current) routes', (t) async {
    final nav = GlobalKey<NavigatorState>();
    await t.pumpWidget(MaterialApp(
      navigatorKey: nav,
      home: _page([IconButton(icon: const Icon(Icons.help), onPressed: () {})]),
    ));
    expect(ShowcaseGuideRunner.headerIconRects(0, 1).length, 1);
    nav.currentState!.push(MaterialPageRoute<void>(
        maintainState: true, builder: (_) => _page(const [])));
    await t.pumpAndSettle();
    // Only the top route's own back button (left); the covered route's
    // action at the right edge no longer counts.
    final rects = ShowcaseGuideRunner.headerIconRects(0, 1);
    expect(rects.length, 1);
    expect(rects.single.left, lessThan(100));
  });

  testWidgets('header rects skip ticker-disabled (inactive tab) subtrees',
      (t) async {
    await t.pumpWidget(MaterialApp(
      home: TickerMode(
        enabled: false,
        child:
            _page([IconButton(icon: const Icon(Icons.help), onPressed: () {})]),
      ),
    ));
    expect(ShowcaseGuideRunner.headerIconRects(0, 1), isEmpty);
  });

  test('shell suppression can be cleared when landing on Home again', () {
    final s = GuideSession.instance..resetForTest();
    s.suppressShellGuide();
    expect(s.shellSuppressed, true);
    s.clearShellSuppression();
    expect(s.shellSuppressed, false);
    s.resetForTest();
  });
}
