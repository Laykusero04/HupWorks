import 'package:flutter/material.dart';
import 'package:freelancer/l10n/l10n.dart';

import '../../services/auth_service.dart';
import 'guide_info_button.dart';
import 'guide_config.dart';
import 'guide_service.dart';
import 'guide_session.dart';
import 'guide_step.dart';
import 'showcase_guide_runner.dart';

/// Wires a screen's [State] to the guide infrastructure.
///
/// The screen provides identity ([guideScreenId], [guideRole], [guideVersion]),
/// the steps ([buildGuideSteps], resolved from l10n at start time) and labels.
/// The mixin handles: scope registration (initState), tab/route visibility,
/// the seen flag, async mounted checks, one retry, and abort when < 2 steps.
///
/// Usage:
/// ```dart
/// class _MyState extends State<My> with GuideHost<My> {
///   final _a = GlobalKey(), _b = GlobalKey();
///   @override String get guideScreenId => 'client_home';
///   @override String get guideRole => 'client';
///   @override int get guideVersion => 1;
///   @override bool get guideDataReady => !_isLoading;
///   @override List<GuideStep> buildGuideSteps(BuildContext c) => [...];
///   @override String get guideSkipLabel => context.l10n.guideSkip; // etc.
///   // wrap targets: Showcase(key: _a, scope: guideScope, ...)
///   // after data load: scheduleGuide();
/// }
/// ```
/// `initState`/`dispose`/`didChangeDependencies` are handled by the mixin
/// (it calls super), so screens need not override them for the guide.
///
/// ### Recipe: add the (i) "Show tips for this screen" button to a screen
/// 1. The screen's State already `with GuideHost<...>` (above).
/// 2. Put [GuideInfoButton] FIRST in the AppBar actions (left of other icons):
/// ```dart
/// AppBar(actions: [GuideInfoButton(host: this), ...otherActions])
/// // shared shell app bar: ClientShellAppBar(actions: [GuideInfoButton(host: this)])
/// ```
/// Only the screen that owns the guide passes it (tabs that stay mounted must
/// not show an (i) that does nothing). The AppBar must rebuild when data
/// loading ends (a normal `setState` does this): the button is disabled while
/// [guideDataReady] is false or this guide is running. Do not give the button
/// a GlobalKey.
/// 3. Wrap the screen's Scaffold in [guideBackScope] so Android Back closes a
/// running guide (counts as Skip) instead of leaving the screen:
/// `return guideBackScope(Scaffold(...));`
/// 4. [replayGuide] re-arms only this screen's guide (never the others).
///
/// ### Recipe: screens with extra on-demand sections + (i) chooser
/// 1. Core guide = [buildGuideSteps] (3 to 5 steps, auto-runs once, owns the
///    seen flag). Extra guides = [buildGuideExtraSections] (at most 3, 3 to 6
///    steps each, titles from l10n). Sections never auto-run and never mark
///    seen:
/// ```dart
/// @override
/// List<GuideSection> buildGuideExtraSections(BuildContext c) => [
///   GuideSection(id: 'filters', title: c.l10n.guideXSectionFilters,
///       steps: [GuideStep(key: _f1, ...), GuideStep(key: _f2, ...)]),
/// ];
/// ```
/// 2. Section targets are normal `Showcase(scope: guideScope)` widgets with
///    their own GlobalKeys (a key may only be in ONE widget at a time; a key
///    reused by two sections must be on the same widget and so shares its
///    text). A section whose targets are not built (fewer than 2 render) is
///    hidden from the chooser by [availableGuideSections] and aborts if run.
/// 3. The same [GuideInfoButton] does the rest: with at least one renderable
///    extra section a tap opens a bottom sheet ("Main tips" + sections),
///    which is CLOSED before the guide starts; otherwise it runs the core
///    guide directly. Run one yourself with `replayGuide(sectionId: 'filters')`.
/// 4. A step below the fold: `GuideStep(enableAutoScroll: true)` (the runner
///    scrolls it into view; the target must be built, so use a non-lazy
///    scroll body or `SingleChildScrollView`/`shrinkWrap`). Bottom-half
///    targets move the Skip pill to the top automatically; keep
///    `targetNearBottom: true` for targets not laid out yet.
/// 5. Reload tear-down: when [guideDataReady] flips to false while the guide
///    runs (a loading flag swaps the body and the targets vanish), the guide
///    is cancelled WITHOUT marking seen and restarts when it is ready again.
///    A normal `setState` already triggers this check (the mixin overrides
///    [setState]); if the flag changes without setState, call
///    [guideDataChanged]. Make `guideDataReady` return false for the whole
///    reload.
/// 6. First automatic run on a screen that shows a [GuideInfoButton]: a
///    one-time snackbar "Tap the (i) anytime..." (global flag per user+role).
/// 7. Shared widgets: pass `guideAnchor: GuideAnchor(key:, scope: guideScope,
///    title:, description:)`; only the owning screen passes it.
mixin GuideHost<T extends StatefulWidget> on State<T> {
  static int _scopeCounter = 0;

  String get guideScreenId;
  String get guideRole;
  int get guideVersion;

  /// True once the screen's data is loaded and targets can be laid out.
  bool get guideDataReady;

  /// Build steps with fresh l10n text. Targets not rendered are dropped.
  List<GuideStep> buildGuideSteps(BuildContext context);

  /// Kill switch hook (override in tests; const in [GuideConfig]).
  bool get guideEnabled => GuideConfig.enabled;

  /// Current user id; override in tests. Default: AuthService.
  String? get guideUid => AuthService.currentUser?.id;

  /// True for the Home screen of a shell: the first guide of the session.
  /// Other guides that wait for it (shell navigation) read
  /// `GuideSession.instance.homeSettled` in their [guideDataReady].
  bool get guideLeadsChain => false;

  String get guideSkipLabel;
  String get guideNextLabel;
  String get guideDoneLabel;

  /// Per-instance scope: a recreated screen never shares or unregisters the
  /// scope of the instance it replaces. Use for `Showcase(scope: guideScope)`.
  late final String guideScope = '${guideScreenId}_${_scopeCounter++}';
  late final ShowcaseGuideRunner _guideRunner = ShowcaseGuideRunner(guideScope);

  bool _guidePending = false;
  bool _guideBusy = false;
  bool _guideRetried = false;
  bool _guideResolved = false;
  bool _guideWasHidden = false;
  bool _guideForce = false;
  int _guideGen = 0; // bumps per started guide; stale delayed releases skip
  String? _guideSection; // pending on-demand section id (null = core)
  bool _runForce = false; // the running guide's force flag / section, kept
  String? _runSection; // so a reload tear-down can re-run the same guide
  bool _guideTornDown = false;
  int _infoButtons = 0;

  /// Extra on-demand sections of this screen (3 to 6 steps each, at most 3
  /// per screen). Never auto-run, never mark the seen flag. Override to
  /// declare them; the core guide stays [buildGuideSteps]. Resolve titles
  /// from l10n here (called at tap/start time). Section ids must be unique and
  /// not [GuideSection.coreId].
  List<GuideSection> buildGuideExtraSections(BuildContext context) => const [];

  /// Extra sections that can run right now: at least two of their targets are
  /// rendered. The (i) chooser lists exactly these ("Main tips" is always
  /// added by the chooser). Empty means the (i) replays the core guide
  /// directly.
  List<GuideSection> availableGuideSections(BuildContext context) {
    if (!guideEnabled || !mounted) return const [];
    return buildGuideExtraSections(context)
        .where((s) => _guideRunner.renderedCount(s.steps) >= 2)
        .toList();
  }

  /// Whether enough core-guide targets are on screen for it to run now.
  bool get canRunCoreGuide =>
      guideEnabled &&
      mounted &&
      _guideRunner.renderedCount(buildGuideSteps(context)) >= 2;

  /// Called by [GuideInfoButton] while mounted. The one-time "tap the (i)"
  /// snackbar is only shown on screens that actually have the button.
  void attachInfoButton() => _infoButtons++;
  void detachInfoButton() => _infoButtons--;

  /// True while this host's guide is on screen. Drives [GuideInfoButton] and
  /// [guideBackScope].
  final ValueNotifier<bool> guideRunning = ValueNotifier<bool>(false);

  GuideSession get _session => GuideSession.instance;
  void _onSessionChanged() {
    // scheduleGuide itself checks enabled/ready/resolved.
    if (mounted) scheduleGuide();
  }

  void _onReplayRequested() {
    if (!mounted) return;
    // Re-arm. Visibility rules still apply in _tryStartGuide, so nothing
    // starts on top of Settings; it starts when this screen is visible again
    // (didChangeDependencies re-schedules on return).
    _guideResolved = false;
    _guideRetried = false;
    _guidePending = false;
    scheduleGuide();
  }

  /// Re-arms ONLY this screen's guide, ignoring the seen flag ("Show tips for
  /// this screen"). Does not touch other hosts or [GuideSession.requestReplay].
  /// Still honours one-guide-at-a-time (waits, pending, if another guide is
  /// running), the drawer gate and visibility. Ignored while this guide is
  /// already running. Returns whether it was armed.
  ///
  /// [sectionId] null or [GuideSection.coreId]: the core guide (marks seen
  /// when it ends). Otherwise the id of one of [buildGuideExtraSections]: runs
  /// only that section and never touches the seen flag. If fewer than 2 of its
  /// targets render, it retries once and then gives up silently (still
  /// returns true: it was armed). An unknown id returns false.
  bool replayGuide({String? sectionId}) {
    if (!guideEnabled || !mounted) return false;
    final section = sectionId == GuideSection.coreId ? null : sectionId;
    if (section != null &&
        !buildGuideExtraSections(context).any((s) => s.id == section)) {
      return false;
    }
    if (_guideRunner.isRunning) return false;
    _guideForce = true;
    _guideSection = section;
    if (section == null) _guideResolved = false;
    _guideRetried = false;
    _guidePending = false;
    scheduleGuide();
    if (!_guidePending) _clearForce(); // scheduleGuide bailed: not armed
    return _guidePending;
  }

  void _clearForce() {
    _guideForce = false;
    _guideSection = null;
  }

  /// Reload tear-down hook. Call (or just use `setState`, which calls it) when
  /// [guideDataReady] may have changed. If it went NOT ready while this
  /// guide runs (a reload swaps the body and the targets disappear), the guide
  /// is cancelled WITHOUT marking seen and re-armed; it starts again, from the
  /// first step, once [guideDataReady] is true and this is called again
  /// (setState after the load does it). Does nothing otherwise.
  void guideDataChanged() {
    if (!mounted || !guideEnabled) return;
    if (!guideDataReady) {
      if (_guideRunner.isRunning) {
        final force = _runForce, section = _runSection;
        cancelGuide();
        _guideTornDown = true;
        _guidePending = true;
        _guideRetried = false;
        _guideForce = force;
        _guideSection = section;
      }
    } else if (_guideTornDown) {
      _guideTornDown = false;
      scheduleGuide();
    }
  }

  @override
  void setState(VoidCallback fn) {
    super.setState(fn);
    if (mounted) guideDataChanged();
  }

  /// Wrap the screen's Scaffold: while this guide runs, system Back closes the
  /// guide (as Skip: marked seen) instead of popping the route. With no guide
  /// running Back behaves normally.
  ///
  /// Depends on [GuideSession.anyRunning] (not only this host): a guide in a
  /// nested navigator (shell tab) must also block the ROOT route, otherwise
  /// Android predictive back finishes the activity. Wrap both the shell and
  /// the tab screens; closing is idempotent.
  Widget guideBackScope(Widget child) => _GuideBackScope(child: child);

  void _onDrawerChanged() {
    if (!mounted || !guideEnabled) return;
    if (GuideSession.drawerOpen.value) {
      // Hide without marking seen; it restarts when the drawer closes.
      if (_guideRunner.isRunning) {
        _guideRetried = false;
        cancelGuide();
      }
    } else {
      scheduleGuide();
    }
  }

  void _releaseSession() => _session.release(this);

  /// Ends this chain-leader's turn so waiting guides may run.
  void _settleLeader() {
    if (guideLeadsChain) _session.markHomeSettled();
  }

  /// Hides a running guide without marking it seen (e.g. a target is about to
  /// disappear). It may start again later.
  void cancelGuide() {
    _guideRunner.cancel();
    guideRunning.value = false;
    GuideSession.endRunning(this);
    _releaseSession();
  }

  /// One-time snackbar after a screen's first AUTOMATIC run (global flag per
  /// user and role, so it is not repeated on every screen). Only on screens
  /// that have a [GuideInfoButton], and only while the screen is visible.
  Future<void> _maybeShowInfoHint(String uid) async {
    try {
      if (!mounted || _infoButtons <= 0 || !_isVisibleTab || !_isTopRoute) {
        return;
      }
      if (await GuideService.hasShownInfoHint(uid: uid, role: guideRole)) {
        return;
      }
      if (!mounted) return;
      final messenger = ScaffoldMessenger.maybeOf(context);
      if (messenger == null) return;
      await GuideService.markInfoHintShown(uid: uid, role: guideRole);
      if (!mounted) return;
      messenger
          .showSnackBar(SnackBar(content: Text(context.l10n.guideInfoHint)));
    } catch (e) {
      debugPrint('Guide info hint failed: $e');
    }
  }

  bool get _isVisibleTab => TickerMode.valuesOf(context).enabled;
  bool get _isTopRoute => ModalRoute.of(context)?.isCurrent ?? true;

  @override
  void initState() {
    super.initState();
    // Must be registered before any Showcase widget of this scope builds.
    // Always register, even with the kill switch off: Showcase widgets in the
    // screen look the scope up in their initState and throw if missing.
    _guideRunner.attach();
    if (guideLeadsChain) _session.resetHome();
    _session.addListener(_onSessionChanged);
    GuideSession.replayRequested.addListener(_onReplayRequested);
    GuideSession.drawerOpen.addListener(_onDrawerChanged);
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (!guideEnabled) return;
    if (!_isVisibleTab || !_isTopRoute) {
      _guideWasHidden = true;
      // Hidden: hide guide, do not mark seen. Deferred: dismiss() updates the
      // overlay, which must not happen during build.
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted) return;
        if (!_isVisibleTab || !_isTopRoute) cancelGuide();
      });
    } else {
      if (_guideWasHidden) {
        _guideWasHidden = false;
        _guideRetried = false; // fresh retry budget when visible again
      }
      scheduleGuide();
    }
  }

  @override
  void dispose() {
    _guidePending = false;
    _session.removeListener(_onSessionChanged);
    GuideSession.replayRequested.removeListener(_onReplayRequested);
    GuideSession.drawerOpen.removeListener(_onDrawerChanged);
    _guideRunner.stop(); // no callbacks, nothing marked seen
    _releaseSession();
    GuideSession.endRunning(this);
    guideRunning.dispose();
    super.dispose();
  }

  /// Call after the screen's data has loaded (success or failure).
  void scheduleGuide() {
    if (!guideEnabled || !mounted) return;
    if (!guideDataReady || (_guideResolved && _guideSection == null)) return;
    _guidePending = true;
    WidgetsBinding.instance.addPostFrameCallback((_) => _tryStartGuide());
    // A post-frame callback alone does not schedule a frame (idle screen).
    WidgetsBinding.instance.ensureVisualUpdate();
  }

  Future<void> _tryStartGuide() async {
    if (!mounted || !_guidePending || _guideBusy || !guideDataReady) return;
    if (!_isVisibleTab || !_isTopRoute || _guideRunner.isRunning) {
      _clearForce(); // force is only for an immediate replay
      return;
    }
    if (GuideSession.drawerOpen.value) {
      _clearForce();
      return; // stays pending
    }
    final uid = guideUid;
    if (uid == null) return;
    // Captured now: a screen whose id changes while the guide runs (setup
    // wizard pages) must never mark another page as seen.
    final screenId = guideScreenId;
    final role = guideRole;
    final version = guideVersion;
    _guideBusy = true;
    try {
      final seen = _guideForce
          ? false
          : await GuideService.hasSeen(
              uid: uid,
              role: role,
              screenId: screenId,
              version: version,
            );
      if (!mounted) return;
      if (seen) {
        _guidePending = false;
        _guideResolved = true;
        _settleLeader();
        return;
      }
      // State may have changed while awaiting.
      if (!guideDataReady ||
          !_isVisibleTab ||
          !_isTopRoute ||
          GuideSession.drawerOpen.value) {
        _clearForce();
        return;
      }
      // One guide at a time (single shared overlay). Stays pending; the
      // session listener re-schedules when the running guide ends.
      if (!_session.tryAcquire(this)) return;
      final section = _guideSection;
      final force = _guideForce;
      final List<GuideStep>? steps;
      if (section == null) {
        steps = buildGuideSteps(context);
      } else {
        steps = buildGuideExtraSections(context)
            .where((s) => s.id == section)
            .firstOrNull
            ?.steps;
      }
      if (steps == null) {
        // Section no longer declared: nothing to run.
        _guidePending = false;
        _clearForce();
        _releaseSession();
        return;
      }
      final automatic = section == null && !force;
      final gen = ++_guideGen;
      final started = _guideRunner.start(
        context: context,
        steps: steps,
        skipLabel: guideSkipLabel,
        nextLabel: guideNextLabel,
        doneLabel: guideDoneLabel,
        onEnd: (_) async {
          // Core: finish and skip both mark seen. Sections never do.
          if (section == null) _guideResolved = true;
          guideRunning.value = false;
          GuideSession.endRunning(this);
          // Let the overlay finish closing before the next guide may start.
          Future.delayed(const Duration(milliseconds: 300), () {
            // A newer guide of this host (replay) now owns the session.
            if (gen == _guideGen) _releaseSession();
            _settleLeader();
            if (automatic) _maybeShowInfoHint(uid);
          });
          if (section != null) return;
          try {
            await GuideService.markSeen(
              uid: uid,
              role: role,
              screenId: screenId,
              version: version,
            );
          } catch (e) {
            debugPrint('Guide markSeen failed: $e');
          }
        },
      );
      if (started) {
        _guidePending = false;
        _runForce = force;
        _runSection = section;
        _clearForce();
        guideRunning.value = true;
        GuideSession.beginRunning(this, _guideRunner.dismiss);
      } else if (!_guideRetried) {
        _releaseSession();
        // Targets may not be laid out yet: one retry, never marked seen.
        _guideRetried = true;
        Future.delayed(const Duration(milliseconds: 300), () {
          if (mounted) scheduleGuide();
        });
      } else {
        _guidePending = false; // < 2 steps: give up, not marked seen
        _clearForce();
        _releaseSession();
        _settleLeader();
      }
    } catch (e, st) {
      debugPrint('Guide failed ($guideScreenId): $e\n$st');
      _guidePending = false;
      _clearForce();
      _releaseSession();
      _settleLeader();
    } finally {
      _guideBusy = false;
    }
  }
}

/// Root/nested Back blocker used by [GuideHost.guideBackScope].
///
/// A [PopScope] whose `canPop` toggles makes its route dispatch a
/// [NavigationNotification] each time. When the scope's route is the ROOT
/// route (a shell) while the page that can still pop lives in a NESTED
/// navigator, the "guide ended" notification (`canHandlePop: false`) is sent
/// from above the nested navigator, so nothing corrects it and the platform is
/// told the framework no longer handles Back (Android predictive back then
/// closes the whole app on the next Back). After a guide ends this scope
/// re-sends the true value (does the navigator below, else the one above, have
/// something to pop) once the PopScope's own notification is out, so Back
/// returns to exactly its normal state.
class _GuideBackScope extends StatefulWidget {
  const _GuideBackScope({required this.child});
  final Widget child;

  @override
  State<_GuideBackScope> createState() => _GuideBackScopeState();
}

class _GuideBackScopeState extends State<_GuideBackScope> {
  bool _wasRunning = GuideSession.anyRunning.value;

  @override
  void initState() {
    super.initState();
    GuideSession.anyRunning.addListener(_onChanged);
  }

  @override
  void dispose() {
    GuideSession.anyRunning.removeListener(_onChanged);
    super.dispose();
  }

  void _onChanged() {
    final running = GuideSession.anyRunning.value;
    if (running == _wasRunning) return;
    _wasRunning = running;
    if (!running) _resyncBackState();
    if (mounted) setState(() {});
  }

  /// The PopScope's own notification goes out in a post-frame callback of the
  /// frame that applies the new `canPop`; ours must come after it, so it runs
  /// one frame later.
  void _resyncBackState() {
    final binding = WidgetsBinding.instance;
    binding.addPostFrameCallback((_) {
      binding.addPostFrameCallback((_) {
        if (!mounted) return;
        NavigationNotification(canHandlePop: _someNavigatorCanPop(context))
            .dispatch(context);
      });
      binding.scheduleFrame();
    });
    binding.scheduleFrame();
  }

  /// True when the nearest navigator below [context] (a shell's nested
  /// navigator) can pop; with none below, the enclosing navigator decides.
  static bool _someNavigatorCanPop(BuildContext context) {
    NavigatorState? below;
    void visit(Element e) {
      if (below != null) return;
      if (e is StatefulElement &&
          e.state is NavigatorState &&
          TickerMode.valuesOf(e).enabled) {
        // Skips hidden shell branches (IndexedStack turns their tickers off).
        below = e.state as NavigatorState;
        return;
      }
      e.visitChildren(visit);
    }

    context.visitChildElements(visit);
    return (below ?? Navigator.maybeOf(context))?.canPop() ?? false;
  }

  @override
  Widget build(BuildContext context) {
    final running = GuideSession.anyRunning.value;
    return PopScope(
      canPop: !running,
      onPopInvokedWithResult: (didPop, _) {
        if (!didPop) GuideSession.dismissRunning();
      },
      child: widget.child,
    );
  }
}
