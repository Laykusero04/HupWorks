import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:freelancer/core/guide/guide_anchor.dart';
import 'package:freelancer/core/guide/guide_host.dart';
import 'package:freelancer/core/guide/guide_info_button.dart';
import 'package:freelancer/core/guide/guide_service.dart';
import 'package:freelancer/core/guide/guide_session.dart';
import 'package:freelancer/core/guide/guide_step.dart';
import 'package:freelancer/l10n/app_localizations.dart';
import 'package:freelancer/screen/widgets/button_global.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:showcaseview/showcaseview.dart';

/// Screen with a core guide (A, B), a renderable section "more" (C, D), a
/// section "hidden" with only one rendered target (E; F not built) and a tall
/// scroll body with a target far below the fold (Z).
class _Sec extends StatefulWidget {
  const _Sec({
    super.key,
    this.screenId = 'sec_screen',
    this.autoScrollZ = false,
    this.withExtras = true,
    this.nearBottomFlag = false,
  });
  final String screenId;
  final bool autoScrollZ;
  final bool withExtras;
  final bool nearBottomFlag;
  @override
  State<_Sec> createState() => _SecState();
}

class _SecState extends State<_Sec> with GuideHost<_Sec> {
  final a = GlobalKey(), b = GlobalKey(), c = GlobalKey(), d = GlobalKey();
  final e = GlobalKey(), f = GlobalKey(), z = GlobalKey();
  bool ready = true;
  final scroll = ScrollController();

  void setReady(bool v) => setState(() => ready = v);

  @override
  String get guideScreenId => widget.screenId;
  @override
  String get guideRole => 'client';
  @override
  int get guideVersion => 1;
  @override
  bool get guideDataReady => ready;
  @override
  String? get guideUid => 'u1';
  @override
  String get guideSkipLabel => 'Skip';
  @override
  String get guideNextLabel => 'Next';
  @override
  String get guideDoneLabel => 'Done';

  @override
  List<GuideStep> buildGuideSteps(BuildContext ctx) => [
        GuideStep(key: a, title: 'A', description: 'a'),
        GuideStep(key: b, title: 'B', description: 'b'),
        if (widget.autoScrollZ)
          GuideStep(
              key: z, title: 'Z', description: 'z', enableAutoScroll: true),
        if (widget.nearBottomFlag)
          GuideStep(key: z, title: 'Z', description: 'z'),
      ];

  @override
  List<GuideSection> buildGuideExtraSections(BuildContext ctx) => [
        GuideSection(id: 'more', title: 'More tips', steps: [
          GuideStep(key: c, title: 'C', description: 'c'),
          GuideStep(key: d, title: 'D', description: 'd'),
        ]),
        GuideSection(id: 'hidden', title: 'Hidden tips', steps: [
          GuideStep(key: e, title: 'E', description: 'e'),
          GuideStep(key: f, title: 'F', description: 'f'), // never built
        ]),
      ];

  Widget _t(GlobalKey k, String t) => Showcase(
      key: k,
      scope: guideScope,
      title: t,
      description: t.toLowerCase(),
      child: Text('target $t'));

  @override
  Widget build(BuildContext context) => Scaffold(
        appBar: AppBar(actions: [GuideInfoButton(host: this)]),
        body: !ready
            ? const Center(child: Text('loading'))
            : SingleChildScrollView(
                controller: scroll,
                child: Column(children: [
                  _t(a, 'A'),
                  _t(b, 'B'),
                  if (widget.withExtras) ...[
                    _t(c, 'C'),
                    _t(d, 'D'),
                    _t(e, 'E')
                  ],
                  if (widget.autoScrollZ || widget.nearBottomFlag) ...[
                    const SizedBox(height: 1500),
                    _t(z, 'Z'),
                    const SizedBox(height: 600),
                  ],
                ]),
              ),
      );
}

Future<void> _app(WidgetTester t, Widget home) async {
  await t.pumpWidget(MaterialApp(
    localizationsDelegates: const [
      AppLocalizations.delegate,
      GlobalMaterialLocalizations.delegate,
      GlobalWidgetsLocalizations.delegate,
      GlobalCupertinoLocalizations.delegate,
    ],
    supportedLocales: AppLocalizations.supportedLocales,
    home: home,
  ));
  await t.pump();
  await t.pump(const Duration(milliseconds: 50));
  await t.pump(const Duration(milliseconds: 600));
}

Future<void> _settle(WidgetTester t) async {
  await t.pump(const Duration(milliseconds: 600));
  await t.pump(const Duration(milliseconds: 400));
}

Future<void> _next(WidgetTester t) async {
  await t.tap(find.text('Next'));
  for (var i = 0; i < 6; i++) {
    await t.pump(const Duration(milliseconds: 150));
  }
}

Future<bool> _seen([String id = 'sec_screen']) =>
    GuideService.hasSeen(uid: 'u1', role: 'client', screenId: id, version: 1);

Future<void> _skipCore(WidgetTester t) async {
  expect(find.text('Skip'), findsOneWidget);
  await t.tap(find.text('Skip'));
  await _settle(t);
  await t.pump(const Duration(milliseconds: 300));
}

void main() {
  setUp(() {
    SharedPreferences.setMockInitialValues({});
    GuideSession.instance.resetForTest();
  });

  testWidgets(
      'sections never auto-run; a section runs alone and does not '
      'touch the seen flag', (t) async {
    final key = GlobalKey<_SecState>();
    await _app(t, _Sec(key: key));
    // Core auto-runs once (steps A, B), not the sections.
    expect(find.text('A'), findsWidgets);
    expect(find.text('C'), findsNothing);
    await _skipCore(t);
    expect(await _seen(), true);

    await GuideService.reset(uid: 'u1', role: 'client', screenId: 'sec_screen');
    expect(key.currentState!.replayGuide(sectionId: 'more'), true);
    await t.pump();
    await t.pump(const Duration(milliseconds: 100));
    await t.pump(const Duration(milliseconds: 600));
    expect(find.text('C'), findsWidgets); // section step title
    expect(find.text('Skip'), findsOneWidget);
    await t.tap(find.text('Skip'));
    await _settle(t);
    expect(await _seen(), false, reason: 'section must not mark seen');
    // Unknown id is rejected.
    expect(key.currentState!.replayGuide(sectionId: 'nope'), false);
  });

  testWidgets('section with <2 rendered targets aborts quietly', (t) async {
    final key = GlobalKey<_SecState>();
    await _app(t, _Sec(key: key));
    await _skipCore(t);
    key.currentState!.replayGuide(sectionId: 'hidden');
    await t.pump();
    await t.pump(const Duration(milliseconds: 100));
    await t.pump(const Duration(milliseconds: 400)); // retry
    await t.pump(const Duration(milliseconds: 400));
    await t.pump(const Duration(milliseconds: 600));
    expect(find.text('Skip'), findsNothing);
    expect(GuideSession.instance.isBusy, false);
    expect(t.takeException(), isNull);
  });

  testWidgets(
      'chooser lists Main tips + only renderable sections, closes '
      'before the section starts', (t) async {
    final key = GlobalKey<_SecState>();
    await _app(t, _Sec(key: key));
    await _skipCore(t);
    await t.tap(find.byIcon(Icons.info_outline));
    await t.pumpAndSettle();
    expect(find.text('Tips for this screen'), findsOneWidget);
    expect(find.text('Main tips'), findsOneWidget);
    expect(find.text('More tips'), findsOneWidget);
    expect(find.text('Hidden tips'), findsNothing);

    await t.tap(find.text('More tips'));
    await t.pump(); // sheet popping
    expect(find.text('Skip'), findsNothing); // not started under the sheet
    await t.pump(const Duration(milliseconds: 400));
    await t.pump(const Duration(milliseconds: 600));
    expect(find.text('Tips for this screen'), findsNothing); // sheet closed
    expect(find.text('Skip'), findsOneWidget); // section guide on screen
    await t.tap(find.text('Skip'));
    await _settle(t);
  });

  testWidgets('chooser "Main tips" replays the core guide', (t) async {
    final key = GlobalKey<_SecState>();
    await _app(t, _Sec(key: key));
    await _skipCore(t);
    await t.tap(find.byIcon(Icons.info_outline));
    await t.pumpAndSettle();
    await t.tap(find.text('Main tips'));
    await t.pump();
    await t.pump(const Duration(milliseconds: 400));
    await t.pump(const Duration(milliseconds: 700));
    expect(find.text('Skip'), findsOneWidget);
    await t.tap(find.text('Skip'));
    await _settle(t);
  });

  testWidgets('no renderable extra sections: (i) runs core directly, no sheet',
      (t) async {
    await _app(t, const _Sec(withExtras: false));
    await _skipCore(t);
    await t.tap(find.byIcon(Icons.info_outline));
    await t.pump();
    await t.pump(const Duration(milliseconds: 100));
    await t.pump(const Duration(milliseconds: 600));
    expect(find.text('Tips for this screen'), findsNothing);
    expect(find.text('Skip'), findsOneWidget);
    await t.tap(find.text('Skip'));
    await _settle(t);
  });

  testWidgets(
      'info hint snackbar: once after the first automatic run, never '
      'again (global per user and role)', (t) async {
    await _app(t, const _Sec());
    await _skipCore(t);
    await t.pump(const Duration(milliseconds: 300));
    expect(find.text('Tap the (i) anytime to see these tips again'),
        findsOneWidget);
    // A second screen's first automatic run shows no hint.
    ScaffoldMessenger.of(t.element(find.byType(Scaffold).first))
        .removeCurrentSnackBar();
    await t.pump();
    await _app(t, const _Sec(key: ValueKey('two'), screenId: 'second'));
    await _skipCore(t);
    await t.pump(const Duration(milliseconds: 300));
    expect(
        find.text('Tap the (i) anytime to see these tips again'), findsNothing);
    // And a replay never shows it.
  });

  testWidgets(
      'reload tear-down: guide cancelled, not marked seen, restarts '
      'when ready again', (t) async {
    final key = GlobalKey<_SecState>();
    await _app(t, _Sec(key: key));
    expect(find.text('Skip'), findsOneWidget);
    key.currentState!.setReady(false); // body swapped, targets disappear
    await t.pump();
    await t.pump(const Duration(milliseconds: 700));
    expect(find.text('Skip'), findsNothing);
    expect(find.text('loading'), findsOneWidget);
    expect(await _seen(), false);
    expect(GuideSession.instance.isBusy, false);
    expect(t.takeException(), isNull);

    key.currentState!.setReady(true);
    await t.pump();
    await t.pump(const Duration(milliseconds: 100));
    await t.pump(const Duration(milliseconds: 700));
    expect(find.text('Skip'), findsOneWidget); // restarted
    await _skipCore(t);
    expect(await _seen(), true);
  });

  testWidgets(
      'autoscroll: flagged step scrolls a below-the-fold target into '
      'view; unflagged steps do not move the page', (t) async {
    final key = GlobalKey<_SecState>();
    await _app(t, _Sec(key: key, autoScrollZ: true));
    final sc = key.currentState!.scroll;
    expect(sc.offset, 0); // steps A and B: no scrolling
    await _next(t);
    expect(sc.offset, 0);
    await _next(t); // to Z (flagged)
    for (var i = 0; i < 20; i++) {
      await t.pump(const Duration(milliseconds: 150));
    }
    expect(sc.offset, greaterThan(500));
    await t.tap(find.text('Skip'));
    await _settle(t);
  });

  testWidgets(
      'skip pill moves to the top for a bottom-half target even '
      'without the flag', (t) async {
    final key = GlobalKey<_SecState>();
    await _app(t, _Sec(key: key, nearBottomFlag: true));
    // A and B are at the top (pill at bottom). Go to Z, which is below the
    // fold and not scrolled to (no autoscroll): its centre is off-screen
    // bottom half -> pill at top.
    final h = t.view.physicalSize.height / t.view.devicePixelRatio;
    expect(t.getCenter(find.text('Skip')).dy, greaterThan(h / 2));
    await _next(t);
    await _next(t);
    expect(t.getCenter(find.text('Skip')).dy, lessThan(h / 2));
    await t.tap(find.text('Skip'));
    await _settle(t);
  });

  testWidgets(
      'GuideAnchor: no key and no Showcase unless a screen passes one '
      '(no duplicate GlobalKeys)', (t) async {
    final k = GlobalKey();
    await _app(t, Builder(builder: (c) => const _AnchorHost()));
    expect(find.byType(Showcase), findsOneWidget);
    expect(find.text('plain'), findsOneWidget);
    expect(find.text('anchored'), findsOneWidget);
    expect(t.takeException(), isNull);
    expect(k, isNotNull);
  });
}

class _AnchorHost extends StatefulWidget {
  const _AnchorHost();
  @override
  State<_AnchorHost> createState() => _AnchorHostState();
}

class _AnchorHostState extends State<_AnchorHost> with GuideHost<_AnchorHost> {
  final key = GlobalKey();
  @override
  String get guideScreenId => 'anchor_host';
  @override
  String get guideRole => 'client';
  @override
  int get guideVersion => 1;
  @override
  bool get guideDataReady => false;
  @override
  bool get guideEnabled => false;
  @override
  String get guideSkipLabel => 'Skip';
  @override
  String get guideNextLabel => 'Next';
  @override
  String get guideDoneLabel => 'Done';
  @override
  List<GuideStep> buildGuideSteps(BuildContext c) => [];

  @override
  Widget build(BuildContext context) => Column(children: [
        // Same shared widget used twice; only one screen call passes an anchor.
        ButtonGlobalWithoutIcon(
            buttontext: 'plain',
            buttonDecoration: const BoxDecoration(),
            onPressed: () {},
            buttonTextColor: Colors.black),
        ButtonGlobalWithoutIcon(
            buttontext: 'anchored',
            buttonDecoration: const BoxDecoration(),
            onPressed: () {},
            buttonTextColor: Colors.black,
            guideAnchor: GuideAnchor(
                key: key, scope: guideScope, title: 't', description: 'd')),
      ]);
}
