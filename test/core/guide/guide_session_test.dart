import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:freelancer/core/guide/guide_host.dart';
import 'package:freelancer/core/guide/guide_service.dart';
import 'package:freelancer/core/guide/guide_session.dart';
import 'package:freelancer/core/guide/guide_step.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:showcaseview/showcaseview.dart';

/// Guide host used twice: a chain leader (Home) and a follower (shell) that
/// waits for the leader to settle.
class _Host extends StatefulWidget {
  const _Host({required this.id, required this.leader});
  final String id;
  final bool leader;
  @override
  State<_Host> createState() => _HostState();
}

class _HostState extends State<_Host> with GuideHost<_Host> {
  final _a = GlobalKey(), _b = GlobalKey();
  @override
  String get guideScreenId => widget.id;
  @override
  String get guideRole => 'client';
  @override
  int get guideVersion => 1;
  @override
  bool get guideLeadsChain => widget.leader;
  @override
  bool get guideDataReady => widget.leader || GuideSession.instance.homeSettled;
  @override
  String? get guideUid => 'u1';
  @override
  String get guideSkipLabel => 'Skip ${widget.id}';
  @override
  String get guideNextLabel => 'Next';
  @override
  String get guideDoneLabel => 'Done';
  @override
  List<GuideStep> buildGuideSteps(BuildContext c) => [
        GuideStep(key: _a, title: 'A', description: 'a'),
        GuideStep(key: _b, title: 'B', description: 'b'),
      ];

  @override
  void initState() {
    super.initState();
    scheduleGuide();
  }

  @override
  Widget build(BuildContext context) => Column(children: [
        Showcase(
            key: _a,
            scope: guideScope,
            title: 'A',
            description: 'a',
            child: Text('${widget.id} a')),
        Showcase(
            key: _b,
            scope: guideScope,
            title: 'B',
            description: 'b',
            child: Text('${widget.id} b')),
      ]);
}

Future<void> _settle(WidgetTester t) async {
  await t.pump();
  await t.pump(const Duration(milliseconds: 50));
  await t.pump(const Duration(milliseconds: 600));
}

Widget _app() => const MaterialApp(
      home: Scaffold(
        body: Column(children: [
          _Host(id: 'shell', leader: false),
          _Host(id: 'home', leader: true),
        ]),
      ),
    );

void main() {
  setUp(() {
    SharedPreferences.setMockInitialValues({});
    GuideSession.instance.resetForTest();
  });

  group('GuideSession', () {
    test('only one holder at a time; release by non-holder is ignored', () {
      final s = GuideSession.instance;
      final a = Object(), b = Object();
      expect(s.tryAcquire(a), true);
      expect(s.tryAcquire(b), false);
      expect(s.isBusy, true);
      s.release(b);
      expect(s.isBusy, true);
      s.release(a);
      expect(s.isBusy, false);
      expect(s.tryAcquire(b), true);
      s.release(b);
    });

    test('home settled notifies once; reset clears it', () {
      final s = GuideSession.instance;
      var n = 0;
      void l() => n++;
      s.addListener(l);
      s.markHomeSettled();
      s.markHomeSettled();
      expect(s.homeSettled, true);
      expect(n, 1);
      s.resetHome();
      expect(s.homeSettled, false);
      s.removeListener(l);
    });
  });

  testWidgets('Home guide runs first, shell guide only after Home ends',
      (t) async {
    await t.pumpWidget(_app());
    await _settle(t);
    expect(t.takeException(), isNull);
    // Only Home's overlay: one Skip pill, labelled for home.
    expect(find.text('Skip home'), findsOneWidget);
    expect(find.text('Skip shell'), findsNothing);

    await t.tap(find.text('Skip home'));
    await t.pump(const Duration(milliseconds: 600));
    // Release is delayed ~300 ms so the overlay can close first.
    await t.pump(const Duration(milliseconds: 400));
    await _settle(t);
    expect(find.text('Skip home'), findsNothing);
    expect(find.text('Skip shell'), findsOneWidget);
    expect(t.takeException(), isNull);

    await t.tap(find.text('Skip shell'));
    await t.pump(const Duration(milliseconds: 600));
    await t.pump(const Duration(milliseconds: 400));
    expect(find.text('Skip shell'), findsNothing);
    expect(GuideSession.instance.isBusy, false);
    expect(
        await GuideService.hasSeen(
            uid: 'u1', role: 'client', screenId: 'home', version: 1),
        true);
    expect(
        await GuideService.hasSeen(
            uid: 'u1', role: 'client', screenId: 'shell', version: 1),
        true);
  });

  testWidgets('Home already seen: shell guide starts after the load alone',
      (t) async {
    await GuideService.markSeen(
        uid: 'u1', role: 'client', screenId: 'home', version: 1);
    await t.pumpWidget(_app());
    await _settle(t);
    await _settle(t);
    expect(find.text('Skip home'), findsNothing);
    expect(find.text('Skip shell'), findsOneWidget);
    expect(t.takeException(), isNull);
    // tear down while running
    await t.pumpWidget(const MaterialApp(home: SizedBox()));
    await t.pump(const Duration(milliseconds: 400));
    expect(GuideSession.instance.isBusy, false);
  });
}
