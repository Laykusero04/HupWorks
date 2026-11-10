import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:freelancer/core/guide/guide_host.dart';
import 'package:freelancer/core/guide/guide_service.dart';
import 'package:freelancer/core/guide/guide_session.dart';
import 'package:freelancer/core/guide/guide_step.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:showcaseview/showcaseview.dart';

class _Screen extends StatefulWidget {
  const _Screen(
      {this.enabled = true, this.ready = true, this.bottomTarget = false});
  final bool enabled;
  final bool ready;
  final bool bottomTarget;
  @override
  State<_Screen> createState() => _ScreenState();
}

class _ScreenState extends State<_Screen> with GuideHost<_Screen> {
  final _a = GlobalKey(), _b = GlobalKey();
  @override
  String get guideScreenId => 'test_screen';
  @override
  String get guideRole => 'client';
  @override
  int get guideVersion => 1;
  @override
  bool get guideDataReady => widget.ready;
  @override
  bool get guideEnabled => widget.enabled;
  @override
  String? get guideUid => 'u1';
  @override
  String get guideSkipLabel => 'Skip';
  @override
  String get guideNextLabel => 'Next';
  @override
  String get guideDoneLabel => 'Done';
  @override
  List<GuideStep> buildGuideSteps(BuildContext c) => [
        GuideStep(key: _a, title: 'A', description: 'a desc'),
        GuideStep(
            key: _b,
            title: 'B',
            description: 'b desc',
            targetNearBottom: widget.bottomTarget),
      ];

  @override
  void initState() {
    super.initState();
    scheduleGuide();
  }

  @override
  Widget build(BuildContext context) => Scaffold(
        body: Column(children: [
          Showcase(
              key: _a,
              scope: guideScope,
              title: 'A',
              description: 'a desc',
              child: const Text('target a')),
          Showcase(
              key: _b,
              scope: guideScope,
              title: 'B',
              description: 'b desc',
              child: const Text('target b')),
        ]),
      );
}

Future<bool> _seen() => GuideService.hasSeen(
    uid: 'u1', role: 'client', screenId: 'test_screen', version: 1);

Future<void> _pump(WidgetTester t, Widget w) async {
  await t.pumpWidget(MaterialApp(home: w));
  await t.pump(); // post-frame callback
  await t.pump(const Duration(milliseconds: 50)); // prefs await
  await t.pump(const Duration(milliseconds: 600)); // showcase animations
}

void main() {
  setUp(() => SharedPreferences.setMockInitialValues({}));

  testWidgets('kill switch off: builds Showcase widgets, no guide', (t) async {
    await _pump(t, const _Screen(enabled: false));
    expect(t.takeException(), isNull);
    expect(find.text('target a'), findsOneWidget);
    expect(find.text('Skip'), findsNothing);
    expect(await _seen(), false);
  });

  testWidgets('data ready: guide starts, Skip marks seen', (t) async {
    await _pump(t, const _Screen());
    expect(t.takeException(), isNull);
    expect(find.text('Skip'), findsOneWidget);
    expect(await _seen(), false);
    await t.tap(find.text('Skip'));
    await t.pump(const Duration(milliseconds: 600));
    await t.pump(const Duration(milliseconds: 100));
    expect(find.text('Skip'), findsNothing);
    expect(await _seen(), true);
  });

  testWidgets('dispose while pending/running does not throw or mark seen',
      (t) async {
    await _pump(t, const _Screen(ready: false));
    expect(find.text('Skip'), findsNothing);
    await t.pumpWidget(const MaterialApp(home: SizedBox()));
    await t.pump(const Duration(milliseconds: 400));
    expect(t.takeException(), isNull);
    expect(await _seen(), false);

    await _pump(t, const _Screen()); // running guide, then dispose
    expect(find.text('Skip'), findsOneWidget);
    await t.pumpWidget(const MaterialApp(home: SizedBox()));
    await t.pump(const Duration(milliseconds: 400));
    expect(t.takeException(), isNull);
    expect(await _seen(), false);
  });

  testWidgets('replay signal re-shows a resolved guide when visible',
      (t) async {
    await _pump(t, const _Screen());
    await t.tap(find.text('Skip'));
    await t.pump(const Duration(milliseconds: 600));
    await t.pump(const Duration(milliseconds: 400));
    expect(await _seen(), true);
    expect(find.text('Skip'), findsNothing);

    await GuideService.resetAll(uid: 'u1', role: 'client');
    GuideSession.requestReplay();
    await t.pump();
    await t.pump(const Duration(milliseconds: 50));
    await t.pump(const Duration(milliseconds: 600));
    expect(t.takeException(), isNull);
    expect(find.text('Skip'), findsOneWidget);
    expect(await _seen(), false);
  });

  testWidgets('replay does not start under a covering route, starts on return',
      (t) async {
    await _pump(t, const _Screen());
    await t.tap(find.text('Skip'));
    await t.pump(const Duration(milliseconds: 600));
    await t.pump(const Duration(milliseconds: 400));

    final nav = Navigator.of(t.element(find.byType(Scaffold)));
    nav.push(MaterialPageRoute<void>(
        builder: (_) => const Scaffold(body: Text('settings'))));
    await t.pumpAndSettle();

    await GuideService.resetAll(uid: 'u1', role: 'client');
    GuideSession.requestReplay();
    await t.pump(const Duration(milliseconds: 700));
    for (var i = 0; i < 20; i++) {
      await t.pump(const Duration(milliseconds: 100));
    }
    expect(find.text('Skip'), findsNothing);

    nav.pop();
    await t.pump();
    await t.pump(const Duration(milliseconds: 500)); // route transition
    await t.pump(const Duration(milliseconds: 600));
    expect(find.text('Skip'), findsOneWidget);
  });

  testWidgets('Skip pill: bottom by default, top for bottom targets',
      (t) async {
    await _pump(t, const _Screen(bottomTarget: true));
    final h = t.view.physicalSize.height / t.view.devicePixelRatio;
    // Step A (not bottom): pill at the bottom.
    expect(t.getCenter(find.text('Skip')).dy, greaterThan(h / 2));
    await t.tap(find.text('Next'));
    await t.pump(const Duration(milliseconds: 100));
    await t.pump(const Duration(milliseconds: 700));
    for (var i = 0; i < 20; i++) {
      await t.pump(const Duration(milliseconds: 100));
    }
    // Step B (bottom target): pill moves to the top.
    expect(t.getCenter(find.text('Skip')).dy, lessThan(h / 2));
  });

  testWidgets('drawer open: guide does not start; starts after close',
      (t) async {
    GuideSession.drawerOpen.value = true;
    addTearDown(() => GuideSession.drawerOpen.value = false);
    await _pump(t, const _Screen());
    expect(find.text('Skip'), findsNothing);
    expect(await _seen(), false);

    GuideSession.drawerOpen.value = false;
    await t.pump();
    await t.pump(const Duration(milliseconds: 50));
    await t.pump(const Duration(milliseconds: 600));
    expect(find.text('Skip'), findsOneWidget);
  });

  testWidgets('drawer opens while running: guide hidden, not marked seen',
      (t) async {
    addTearDown(() => GuideSession.drawerOpen.value = false);
    await _pump(t, const _Screen());
    expect(find.text('Skip'), findsOneWidget);
    GuideSession.drawerOpen.value = true;
    await t.pump(const Duration(milliseconds: 700));
    expect(find.text('Skip'), findsNothing);
    expect(await _seen(), false);
  });
}
