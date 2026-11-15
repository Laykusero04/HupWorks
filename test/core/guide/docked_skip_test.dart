import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:freelancer/core/guide/guide_host.dart';
import 'package:freelancer/core/guide/guide_step.dart';
import 'package:freelancer/core/guide/showcase_guide_runner.dart';
import 'package:freelancer/router/app_router.dart';
import 'package:showcaseview/showcaseview.dart';
import 'package:shared_preferences/shared_preferences.dart';

String _skipLabel = 'Skip';
String _nextLabel = 'Next';

/// Step 1 target fills the screen (every pill slot collides -> docked), step 2
/// is tiny (free slot), step 3 is the last step.
class _Screen extends StatefulWidget {
  const _Screen();
  @override
  State<_Screen> createState() => _ScreenState();
}

class _ScreenState extends State<_Screen> with GuideHost<_Screen> {
  final _a = GlobalKey(), _b = GlobalKey(), _c = GlobalKey();
  @override
  String get guideScreenId => 'docked_screen';
  @override
  String get guideRole => 'client';
  @override
  int get guideVersion => 1;
  @override
  bool get guideDataReady => true;
  @override
  String? get guideUid => 'u1';
  @override
  String get guideSkipLabel => _skipLabel;
  @override
  String get guideNextLabel => _nextLabel;
  @override
  String get guideDoneLabel => 'Done';
  @override
  List<GuideStep> buildGuideSteps(BuildContext c) => [
        GuideStep(key: _a, title: 'A', description: 'a'),
        GuideStep(key: _b, title: 'B', description: 'b'),
        GuideStep(key: _c, title: 'C', description: 'c'),
      ];

  @override
  void initState() {
    super.initState();
    scheduleGuide();
  }

  @override
  Widget build(BuildContext context) => guideBackScope(Scaffold(
        appBar: AppBar(title: const Text('Short')),
        body: Stack(children: [
          Showcase(
              key: _a,
              scope: guideScope,
              title: 'A',
              description: 'a',
              child: const SizedBox.expand()),
          Positioned(
            left: 20,
            top: 300,
            child: Showcase(
                key: _b,
                scope: guideScope,
                title: 'B',
                description: 'b',
                child: const SizedBox(width: 40, height: 20)),
          ),
          Positioned(
            left: 20,
            top: 400,
            child: Showcase(
                key: _c,
                scope: guideScope,
                title: 'C',
                description: 'c',
                child: const SizedBox(width: 40, height: 20)),
          ),
        ]),
      ));
}

Future<void> _settle(WidgetTester t) async {
  await t.pump(const Duration(milliseconds: 100));
  await t.pump(const Duration(milliseconds: 700));
  for (var i = 0; i < 20; i++) {
    await t.pump(const Duration(milliseconds: 100));
  }
}

Future<void> _start(WidgetTester t) async {
  await t.pumpWidget(const MaterialApp(home: _Screen()));
  await t.pump();
  await t.pump(const Duration(milliseconds: 50));
  await t.pump(const Duration(milliseconds: 600));
}

void main() {
  setUp(() {
    SharedPreferences.setMockInitialValues({});
    _skipLabel = 'Skip';
    _nextLabel = 'Next';
  });

  final docked = find.byKey(const ValueKey('guide_skip_docked'));
  final pill = find.byKey(const ValueKey('guide_skip_pill'));

  testWidgets(
      'docked step: card Skip shown, floating pill hidden; tap dismisses',
      (t) async {
    await _start(t);
    expect(t.takeException(), isNull);
    expect(docked, findsOneWidget);
    expect(pill, findsNothing);
    expect(t.getSize(docked).height, greaterThanOrEqualTo(48));

    await t.tap(docked);
    await _settle(t);
    expect(docked, findsNothing);
    expect(pill, findsNothing);
    expect(find.text('Next'), findsNothing);
  });

  testWidgets('Dutch labels at text scale 2.0: no overflow, stacked, in card',
      (t) async {
    _skipLabel = 'Tour overslaan';
    _nextLabel = 'Volgende';
    t.view.devicePixelRatio = 1;
    addTearDown(t.view.resetDevicePixelRatio);
    addTearDown(t.view.resetPhysicalSize);
    t.view.physicalSize = const Size(375, 800);
    await t.pumpWidget(MediaQuery(
      data: const MediaQueryData(
          size: Size(375, 800), textScaler: TextScaler.linear(2.0)),
      child: const MaterialApp(home: _Screen()),
    ));
    await t.pump();
    await t.pump(const Duration(milliseconds: 50));
    await t.pump(const Duration(milliseconds: 600));
    expect(t.takeException(), isNull);
    expect(docked, findsOneWidget);
    final next = t.getRect(find.text('Volgende'));
    final skip = t.getRect(find.byKey(const ValueKey('guide_skip_docked')));
    expect(next.right, lessThanOrEqualTo(375));
    expect(skip.right, lessThanOrEqualTo(375));
    expect(skip.height, greaterThanOrEqualTo(48));
    expect(skip.top, greaterThanOrEqualTo(next.bottom));
    await t.tap(find.text('Volgende'));
    await _settle(t);
    expect(t.takeException(), isNull);
  });

  testWidgets('free step shows only the pill; last step has no card Skip',
      (t) async {
    await _start(t);
    await t.tap(find.text('Next')); // A (docked) -> B (free)
    await _settle(t);
    expect(docked, findsNothing);
    expect(pill, findsOneWidget);

    await t.tap(find.text('Next')); // B -> C (last)
    await _settle(t);
    expect(find.text('Done'), findsOneWidget);
    expect(docked, findsNothing);
    expect(pill, findsOneWidget);
  });

  testWidgets('never two Skip controls or none while stepping', (t) async {
    await _start(t);
    int controls() => docked.evaluate().length + pill.evaluate().length;
    expect(controls(), 1);
    await t.tap(find.text('Next'));
    for (var i = 0; i < 12; i++) {
      await t.pump(const Duration(milliseconds: 50));
      expect(controls(), lessThanOrEqualTo(1));
    }
    expect(controls(), 1);
  });

  testWidgets('appBarRects uses the painted title width, not the title box',
      (t) async {
    await t.pumpWidget(MaterialApp(
      home: Scaffold(
        appBar: AppBar(title: const Text('Hi')),
        body: const SizedBox(),
      ),
    ));
    final rects = ShowcaseGuideRunner.appBarRects();
    expect(rects, isNotEmpty);
    final textRect = t.getRect(find.text('Hi'));
    final titleRect = rects.firstWhere((r) => r.overlaps(textRect));
    // Painted text (+4 inflate each side), far narrower than the toolbar.
    expect(titleRect.width, lessThan(textRect.width + 12));
    expect(titleRect.width, lessThan(t.view.physicalSize.width / 4));
  });

  testWidgets('appBarRects skips offstage and covered routes', (t) async {
    await t.pumpWidget(MaterialApp(
      home: Scaffold(
        appBar: AppBar(title: const Text('Under')),
        body: const SizedBox(),
      ),
    ));
    expect(ShowcaseGuideRunner.appBarRects(), isNotEmpty);

    final nav = Navigator.of(t.element(find.byType(Scaffold)));
    nav.push(MaterialPageRoute<void>(
        builder: (_) => const Scaffold(body: Text('top'))));
    await t.pumpAndSettle();
    // Covering route has no AppBar; the one underneath must not count.
    expect(ShowcaseGuideRunner.appBarRects(), isEmpty);
    nav.pop();
    await t.pumpAndSettle();

    await t.pumpWidget(MaterialApp(
      home: Scaffold(
        body: Offstage(
          child: Scaffold(appBar: AppBar(title: const Text('Hidden'))),
        ),
      ),
    ));
    expect(ShowcaseGuideRunner.appBarRects(), isEmpty);
  });

  testWidgets('scale 1.0, wide screen: Skip and Next side by side (Skip first)',
      (t) async {
    await _start(t);
    expect(t.takeException(), isNull);
    final skip = t.getRect(docked);
    final next = t.getRect(find.text('Next'));
    expect((skip.center.dy - next.center.dy).abs(), lessThan(6));
    expect(skip.right, lessThan(next.left));
    expect(skip.height, greaterThanOrEqualTo(48));
  });

  test('fitsSideBySide: measured at the effective scale', () {
    bool f(double w, double sc) => _GuideActionsProbe.fits(w, sc);
    expect(f(375, 1.0), isTrue);
    expect(f(375, 2.0), isFalse);
    expect(f(800, 2.0), isTrue);
  });

  testWidgets('nav labels: one uniform scale, never hidden (Overeenkomsten)',
      (t) async {
    t.view.devicePixelRatio = 1;
    addTearDown(t.view.resetDevicePixelRatio);
    addTearDown(t.view.resetPhysicalSize);
    const labels = ['Home', 'Chat', 'Talent', 'Jobs', 'Overeenkomsten'];
    Future<void> pumpAt(double scale, double width) async {
      t.view.physicalSize = Size(width, 800);
      await t.pumpWidget(MaterialApp(
        home: MediaQuery(
          data: MediaQueryData(
              size: Size(width, 800), textScaler: TextScaler.linear(scale)),
          child: Scaffold(
            body: const SizedBox(),
            bottomNavigationBar:
                debugShellBottomNav(currentIndex: 0, labels: labels),
          ),
        ),
      ));
    }

    double? scalerOf(String l) =>
        t.widget<Text>(find.text(l)).textScaler?.scale(1.0);

    // Plenty of room: every label at the ambient scale.
    await pumpAt(1.0, 1000);
    for (final l in labels) {
      expect(find.text(l), findsOneWidget);
      expect(scalerOf(l), 1.0);
    }

    // 375 wide, default + XL: all five visible, exactly the same scale on
    // every label, >= 0.8, label on one line.
    for (final sc in [1.0, 1.25, 2.0]) {
      await pumpAt(sc, 375);
      expect(t.takeException(), isNull);
      final scales = {for (final l in labels) scalerOf(l)};
      expect(scales.length, 1, reason: 'scale $sc');
      expect(scales.first!, greaterThanOrEqualTo(0.8));
      expect(scales.first!, lessThanOrEqualTo(1.25));
      for (final l in labels) {
        expect(find.text(l), findsOneWidget);
        expect(t.getSize(find.text(l)).height, lessThan(30)); // single line
      }
    }

    // Very narrow: still never hidden, no overflow.
    await pumpAt(2.0, 300);
    expect(t.takeException(), isNull);
    expect(find.text('Overeenkomsten'), findsOneWidget);
  });

  test('navLabelScale: fits the longest label, floor 0.8, never above ambient',
      () {
    double f(double tile, double amb) => navLabelScale(
        labels: const ['Home', 'Overeenkomsten'],
        tileWidth: tile,
        ambientScale: amb,
        textDirection: TextDirection.ltr);
    expect(f(400, 1.0), 1.0);
    expect(f(400, 1.25), 1.25);
    final tight = f(72, 1.25);
    expect(tight, lessThan(1.0));
    expect(tight, greaterThanOrEqualTo(0.8));
    expect(f(30, 1.25), 0.8);
  });
}

class _GuideActionsProbe {
  static bool fits(double width, double scale) =>
      ShowcaseGuideRunner.debugFitsSideBySide(
        avail: width - 64,
        skipLabel: 'Skip',
        actionLabel: 'Next',
        scale: scale,
      );
}
