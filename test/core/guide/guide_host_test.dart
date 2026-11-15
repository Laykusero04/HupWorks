import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:freelancer/core/guide/guide_host.dart';
import 'package:freelancer/core/guide/guide_info_button.dart';
import 'package:freelancer/core/guide/guide_nav_bridge.dart';
import 'package:freelancer/l10n/app_localizations.dart';
import 'package:freelancer/core/guide/guide_service.dart';
import 'package:freelancer/core/guide/guide_session.dart';
import 'package:freelancer/core/guide/guide_step.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:showcaseview/showcaseview.dart';

/// Shell-like root host: owns no guide, only a root-level back scope around a
/// nested Navigator that contains the guided screen.
class _Shell extends StatefulWidget {
  const _Shell({this.child});

  /// go_router shell child (replaces the nested Navigator).
  final Widget? child;

  @override
  State<_Shell> createState() => _ShellState();
}

class _ShellState extends State<_Shell> with GuideHost<_Shell> {
  @override
  String get guideScreenId => 'shell';
  @override
  String get guideRole => 'client';
  @override
  int get guideVersion => 1;
  @override
  bool get guideDataReady => false;
  @override
  String get guideSkipLabel => 'Skip';
  @override
  String get guideNextLabel => 'Next';
  @override
  String get guideDoneLabel => 'Done';
  @override
  List<GuideStep> buildGuideSteps(BuildContext c) => [];
  @override
  Widget build(BuildContext context) => guideBackScope(Scaffold(
        body: widget.child ??
            Navigator(
              onGenerateRoute: (_) =>
                  MaterialPageRoute(builder: (_) => const _Screen()),
            ),
      ));
}

class _Screen extends StatefulWidget {
  const _Screen(
      {this.enabled = true,
      this.ready = true,
      this.bottomTarget = false,
      this.screenId = 'test_screen',
      this.withBar = false,
      this.leads = false,
      this.openLabel,
      this.onOpen});
  final String? openLabel;
  final VoidCallback? onOpen;
  final String screenId;
  final bool withBar;
  final bool leads;
  final bool enabled;
  final bool ready;
  final bool bottomTarget;
  @override
  State<_Screen> createState() => _ScreenState();
}

class _ScreenState extends State<_Screen> with GuideHost<_Screen> {
  final _a = GlobalKey(), _b = GlobalKey();
  @override
  String get guideScreenId => widget.screenId;
  @override
  bool get guideLeadsChain => widget.leads;
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
  Widget build(BuildContext context) => guideBackScope(Scaffold(
        appBar: widget.withBar
            ? AppBar(actions: [GuideInfoButton(host: this)])
            : null,
        body: Column(children: [
          if (widget.openLabel != null)
            TextButton(
                onPressed: widget.onOpen, child: Text(widget.openLabel!)),
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
      ));
}

Future<bool> _seen() => GuideService.hasSeen(
    uid: 'u1', role: 'client', screenId: 'test_screen', version: 1);

Future<void> _pump(WidgetTester t, Widget w) async {
  await t.pumpWidget(MaterialApp(home: w));
  await t.pump(); // post-frame callback
  await t.pump(const Duration(milliseconds: 50)); // prefs await
  await t.pump(const Duration(milliseconds: 600)); // showcase animations
}

Future<void> settleGuide(WidgetTester t) async {
  await t.pump(const Duration(milliseconds: 600));
  await t.pump(const Duration(milliseconds: 100));
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

  testWidgets('screen id changing mid-guide marks the id captured at start',
      (t) async {
    Future<bool> seenId(String id) => GuideService.hasSeen(
        uid: 'u1', role: 'client', screenId: id, version: 1);
    await _pump(t, const _Screen(screenId: 'page_1'));
    expect(find.text('Skip'), findsOneWidget);
    // Same State, new id (like setup wizard pages).
    await t.pumpWidget(const MaterialApp(home: _Screen(screenId: 'page_2')));
    await t.pump();
    await t.tap(find.text('Skip'));
    await settleGuide(t);
    expect(await seenId('page_1'), true);
    expect(await seenId('page_2'), false);
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

  testWidgets(
      'Skip pill: bottom for a top target, top for a bottom-flagged target; '
      'always >= 48dp', (t) async {
    await _pump(t, const _Screen(bottomTarget: true));
    final h = t.view.physicalSize.height / t.view.devicePixelRatio;
    final pill = find.byKey(const ValueKey('guide_skip_pill'));
    expect(t.getCenter(find.text('Skip')).dy, greaterThan(h / 2));
    expect(t.getSize(pill).height, greaterThanOrEqualTo(48));
    await t.tap(find.text('Next'));
    await t.pump(const Duration(milliseconds: 100));
    await t.pump(const Duration(milliseconds: 700));
    for (var i = 0; i < 20; i++) {
      await t.pump(const Duration(milliseconds: 100));
    }
    // Step B is flagged near-bottom: the pill moves to the top.
    expect(t.getCenter(find.text('Skip')).dy, lessThan(h / 2));
    expect(t.getSize(pill).height, greaterThanOrEqualTo(48));
  });

  testWidgets('outside tap does not advance or end the tour', (t) async {
    await _pump(t, const _Screen());
    expect(find.text('a desc'), findsOneWidget);
    // Far corner of the dimmed area, away from tooltip / pill.
    await t.tapAt(const Offset(780, 300));
    await t.pump(const Duration(milliseconds: 700));
    expect(find.text('a desc'), findsOneWidget);
    expect(find.text('b desc'), findsNothing);
    expect(find.text('Skip'), findsOneWidget);
    expect(await _seen(), false);
  });

  testWidgets(
      'tab tap during a tour ends it (marks seen, like Skip) and switches '
      'tab in one tap; pill sits above the measured nav', (t) async {
    final navKey = GlobalKey();
    final tapped = <int>[];
    final handle = GuideNavHandle(
      barKey: navKey,
      tabCount: () => 3,
      onTab: tapped.add,
      isVisible: () => true,
    );
    GuideNavBridge.register(handle);
    addTearDown(() => GuideNavBridge.unregister(handle));

    await _pump(
        t,
        Scaffold(
          body: const _Screen(),
          bottomNavigationBar: SizedBox(
            key: navKey,
            height: 70,
            child: Row(children: [
              for (var i = 0; i < 3; i++)
                Expanded(child: Center(child: Text('tab$i'))),
            ]),
          ),
        ));
    expect(find.text('Skip'), findsOneWidget);
    final h = t.view.physicalSize.height / t.view.devicePixelRatio;
    final navTop = h - 70;
    expect(t.getBottomLeft(find.byKey(const ValueKey('guide_skip_pill'))).dy,
        lessThanOrEqualTo(navTop));

    await t.tapAt(t.getCenter(find.text('tab1')));
    await t.pump(const Duration(milliseconds: 600));
    await t.pump(const Duration(milliseconds: 400));
    expect(tapped, [1]);
    expect(find.text('Skip'), findsNothing);
    expect(await _seen(), true);
  });

  testWidgets(
      'tab tap during the HOME tour suppresses the chained shell guide for the '
      'session (seller shell no longer restarts a tour, T-0156 B4)', (t) async {
    GuideSession.instance.resetForTest();
    final navKey = GlobalKey();
    final handle = GuideNavHandle(
      barKey: navKey,
      tabCount: () => 3,
      onTab: (_) {},
      isVisible: () => true,
    );
    GuideNavBridge.register(handle);
    addTearDown(() {
      GuideNavBridge.unregister(handle);
      GuideSession.instance.resetForTest();
    });
    expect(GuideSession.instance.shellSuppressed, false);

    await _pump(
        t,
        Scaffold(
          body: const _Screen(leads: true),
          bottomNavigationBar: SizedBox(
            key: navKey,
            height: 70,
            child: Row(children: [
              for (var i = 0; i < 3; i++)
                Expanded(child: Center(child: Text('tab$i'))),
            ]),
          ),
        ));
    await t.tapAt(t.getCenter(find.text('tab2')));
    await t.pump(const Duration(milliseconds: 600));
    await t.pump(const Duration(milliseconds: 400));
    expect(find.text('Skip'), findsNothing);
    expect(GuideSession.instance.shellSuppressed, true);
    // Landing on Home again, or a new chain / replay, re-enables it.
    GuideSession.instance.clearShellSuppression();
    expect(GuideSession.instance.shellSuppressed, false);
    GuideSession.instance.suppressShellGuide();
    GuideSession.instance.resetHome();
    expect(GuideSession.instance.shellSuppressed, false);
  });

  testWidgets(
      'tab tap during a non-Home tour does NOT suppress the '
      'shell guide (seller shell no longer restarts a tour, T-0156 B4)',
      (t) async {
    GuideSession.instance.resetForTest();
    final navKey = GlobalKey();
    final handle = GuideNavHandle(
      barKey: navKey,
      tabCount: () => 3,
      onTab: (_) {},
      isVisible: () => true,
    );
    GuideNavBridge.register(handle);
    addTearDown(() {
      GuideNavBridge.unregister(handle);
      GuideSession.instance.resetForTest();
    });
    expect(GuideSession.instance.shellSuppressed, false);

    await _pump(
        t,
        Scaffold(
          body: const _Screen(),
          bottomNavigationBar: SizedBox(
            key: navKey,
            height: 70,
            child: Row(children: [
              for (var i = 0; i < 3; i++)
                Expanded(child: Center(child: Text('tab$i'))),
            ]),
          ),
        ));
    await t.tapAt(t.getCenter(find.text('tab2')));
    await t.pump(const Duration(milliseconds: 600));
    await t.pump(const Duration(milliseconds: 400));
    expect(find.text('Skip'), findsNothing);
    expect(GuideSession.instance.shellSuppressed, false);
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

  Future<bool> seenOf(String id) =>
      GuideService.hasSeen(uid: 'u1', role: 'client', screenId: id, version: 1);

  Future<void> settle(WidgetTester t) async {
    await t.pump(const Duration(milliseconds: 600));
    await t.pump(const Duration(milliseconds: 100));
  }

  Future<void> pumpL10n(WidgetTester t, Widget w) async {
    await t.pumpWidget(MaterialApp(
      localizationsDelegates: const [
        AppLocalizations.delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      supportedLocales: AppLocalizations.supportedLocales,
      home: w,
    ));
    await t.pump();
  }

  testWidgets('(i) replays only its own host; other host flag unchanged',
      (t) async {
    await GuideService.markSeen(
        uid: 'u1', role: 'client', screenId: 'test_screen', version: 1);
    await GuideService.markSeen(
        uid: 'u1', role: 'client', screenId: 'other_screen', version: 1);
    await pumpL10n(
        t,
        Column(children: const [
          Expanded(child: _Screen(withBar: true)),
          Expanded(child: _Screen(screenId: 'other_screen')),
        ]));
    expect(find.text('Skip'), findsNothing); // both seen
    expect(find.byTooltip('Show tips for this screen'), findsOneWidget);
    await t.tap(find.byIcon(Icons.help_outline));
    await t.pump();
    await t.pump();
    expect(find.text('Skip'), findsOneWidget);
    // Disabled while running.
    final btn = t.widget<IconButton>(find.byType(IconButton));
    expect(btn.onPressed, isNull);
    await t.tap(find.text('Skip'));
    await settle(t);
    expect(find.text('Skip'), findsNothing);
    expect(await seenOf('test_screen'), true);
    expect(await seenOf('other_screen'), true);
  });

  testWidgets('(i) hidden with kill switch', (t) async {
    await pumpL10n(t, const _Screen(enabled: false, withBar: true));
    expect(find.byIcon(Icons.help_outline), findsNothing);
  });

  testWidgets('(i) disabled while data is loading', (t) async {
    await pumpL10n(t, const _Screen(ready: false, withBar: true));
    final btn = t.widget<IconButton>(find.byType(IconButton));
    expect(btn.onPressed, isNull);
  });

  testWidgets('Back during guide closes guide and marks seen; route stays',
      (t) async {
    await t.pumpWidget(MaterialApp(
      home: Builder(
          builder: (c) => Scaffold(
                body: TextButton(
                    onPressed: () => Navigator.of(c).push(
                        MaterialPageRoute(builder: (_) => const _Screen())),
                    child: const Text('open')),
              )),
    ));
    await t.tap(find.text('open'));
    await t.pump(const Duration(milliseconds: 500)); // route transition
    await t.pump(const Duration(milliseconds: 500));
    await t.pump();
    expect(find.text('Skip'), findsOneWidget);
    await t.binding.handlePopRoute();
    await settle(t);
    expect(find.text('Skip'), findsNothing);
    expect(find.text('target a'), findsOneWidget); // still on the screen
    expect(await seenOf('test_screen'), true);
  });

  testWidgets('Back without a guide pops normally', (t) async {
    await GuideService.markSeen(
        uid: 'u1', role: 'client', screenId: 'test_screen', version: 1);
    await t.pumpWidget(MaterialApp(
      home: Builder(
          builder: (c) => Scaffold(
                body: TextButton(
                    onPressed: () => Navigator.of(c).push(
                        MaterialPageRoute(builder: (_) => const _Screen())),
                    child: const Text('open')),
              )),
    ));
    await t.tap(find.text('open'));
    await t.pumpAndSettle(const Duration(milliseconds: 100));
    expect(find.text('target a'), findsOneWidget);
    await t.binding.handlePopRoute();
    await t.pumpAndSettle(const Duration(milliseconds: 100));
    expect(find.text('target a'), findsNothing);
    expect(find.text('open'), findsOneWidget);
  });

  testWidgets('nested navigator: Back during inner guide does not pop outer',
      (t) async {
    await t.pumpWidget(MaterialApp(
      home: Builder(
          builder: (c) => Scaffold(
                body: TextButton(
                    onPressed: () => Navigator.of(c).push(
                        MaterialPageRoute(builder: (_) => const _Shell())),
                    child: const Text('open')),
              )),
    ));
    await t.tap(find.text('open'));
    await t.pump(const Duration(milliseconds: 500));
    await t.pump(const Duration(milliseconds: 500));
    await t.pump();
    expect(find.text('Skip'), findsOneWidget);
    await t.binding.handlePopRoute();
    await settle(t);
    expect(find.text('Skip'), findsNothing);
    expect(find.text('target a'), findsOneWidget); // outer route still there
    expect(await seenOf('test_screen'), true);
    // Without a guide, Back pops the outer route.
    await t.binding.handlePopRoute();
    await t.pumpAndSettle(const Duration(milliseconds: 100));
    expect(find.text('open'), findsOneWidget);
  });

  testWidgets(
      'go_router: guide on a root-pushed page above a shell; after Back closes '
      'the guide the platform still hears "framework handles Back" and the '
      'next Back pops to the shell', (t) async {
    await GuideService.markSeen(
        uid: 'u1', role: 'client', screenId: 'findjobs', version: 1);
    final handles = <bool>[];
    t.binding.defaultBinaryMessenger
        .setMockMethodCallHandler(SystemChannels.platform, (call) async {
      if (call.method == 'SystemNavigator.setFrameworkHandlesBack') {
        handles.add(call.arguments as bool);
      }
      return null;
    });
    addTearDown(() => t.binding.defaultBinaryMessenger
        .setMockMethodCallHandler(SystemChannels.platform, null));
    final rootKey = GlobalKey<NavigatorState>();
    final router = GoRouter(
      navigatorKey: rootKey,
      routes: [
        StatefulShellRoute.indexedStack(
          builder: (c, s, shell) => _Shell(child: shell),
          branches: [
            StatefulShellBranch(routes: [
              GoRoute(
                  path: '/',
                  builder: (c, s) => _Screen(
                      screenId: 'findjobs',
                      openLabel: 'open',
                      onOpen: () => c.push('/details'))),
            ]),
          ],
        ),
        GoRoute(
            path: '/details',
            parentNavigatorKey: rootKey,
            builder: (c, s) => const _Screen()),
      ],
    );
    t.binding.handleAppLifecycleStateChanged(AppLifecycleState.resumed);
    await t.pumpWidget(MaterialApp.router(routerConfig: router));
    await t.pump();
    await t.tap(find.text('open'));
    await t.pump(const Duration(milliseconds: 500));
    await t.pump(const Duration(milliseconds: 500));
    await t.pump();
    expect(find.text('Skip'), findsOneWidget);
    await t.binding.handlePopRoute(); // closes the guide
    await settle(t);
    await t.pump();
    await t.pump();
    expect(find.text('Skip'), findsNothing);
    expect(find.text('open').hitTestable(), findsNothing); // details on top
    expect(handles, isNotEmpty);
    expect(handles.last, true);
    await t.binding.handlePopRoute(); // pops to the shell
    await t.pumpAndSettle(const Duration(milliseconds: 100));
    expect(find.text('open').hitTestable(), findsOneWidget);
  });

  testWidgets('(i) within the delayed release window keeps the new guide owned',
      (t) async {
    GuideSession.instance.resetForTest();
    await pumpL10n(t, const _Screen(withBar: true));
    expect(find.text('Skip'), findsOneWidget);
    await t.tap(find.text('Skip'));
    await t.pump(const Duration(milliseconds: 50));
    await t.tap(find.byIcon(Icons.help_outline));
    await t.pump();
    await t.pump(const Duration(milliseconds: 100));
    expect(find.text('Skip'), findsOneWidget);
    await t.pump(const Duration(milliseconds: 400)); // old release timer fires
    expect(GuideSession.instance.isBusy, true);
    await t.tap(find.text('Skip'));
    await settle(t);
    expect(GuideSession.instance.isBusy, false);
  });

  testWidgets('force does not leak when replay bails (drawer open)', (t) async {
    GuideSession.instance.resetForTest();
    await GuideService.markSeen(
        uid: 'u1', role: 'client', screenId: 'test_screen', version: 1);
    await pumpL10n(t, const _Screen(withBar: true));
    GuideSession.drawerOpen.value = true;
    await t.tap(find.byIcon(Icons.help_outline));
    await t.pump();
    await t.pump();
    expect(find.text('Skip'), findsNothing);
    GuideSession.drawerOpen.value = false;
    await t.pump();
    await t.pump(const Duration(milliseconds: 100));
    expect(find.text('Skip'), findsNothing); // natural schedule honours seen
    GuideSession.instance.resetForTest();
  });
}
