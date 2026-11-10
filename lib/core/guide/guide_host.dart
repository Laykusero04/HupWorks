import 'package:flutter/material.dart';

import '../../services/auth_service.dart';
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
    _releaseSession();
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
    super.dispose();
  }

  /// Call after the screen's data has loaded (success or failure).
  void scheduleGuide() {
    if (!guideEnabled || !mounted) return;
    if (!guideDataReady || _guideResolved) return;
    _guidePending = true;
    WidgetsBinding.instance.addPostFrameCallback((_) => _tryStartGuide());
    // A post-frame callback alone does not schedule a frame (idle screen).
    WidgetsBinding.instance.ensureVisualUpdate();
  }

  Future<void> _tryStartGuide() async {
    if (!mounted || !_guidePending || _guideBusy || !guideDataReady) return;
    if (!_isVisibleTab || !_isTopRoute || _guideRunner.isRunning) return;
    if (GuideSession.drawerOpen.value) return; // stays pending
    final uid = guideUid;
    if (uid == null) return;
    _guideBusy = true;
    try {
      final seen = await GuideService.hasSeen(
        uid: uid,
        role: guideRole,
        screenId: guideScreenId,
        version: guideVersion,
      );
      if (!mounted) return;
      if (seen) {
        _guidePending = false;
        _guideResolved = true;
        _settleLeader();
        return;
      }
      // State may have changed while awaiting.
      if (!guideDataReady || !_isVisibleTab || !_isTopRoute) return;
      if (GuideSession.drawerOpen.value) return;
      // One guide at a time (single shared overlay). Stays pending; the
      // session listener re-schedules when the running guide ends.
      if (!_session.tryAcquire(this)) return;
      final started = _guideRunner.start(
        context: context,
        steps: buildGuideSteps(context),
        skipLabel: guideSkipLabel,
        nextLabel: guideNextLabel,
        doneLabel: guideDoneLabel,
        onEnd: (_) async {
          // Finish and skip both mark seen.
          _guideResolved = true;
          // Let the overlay finish closing before the next guide may start.
          Future.delayed(const Duration(milliseconds: 300), () {
            _releaseSession();
            _settleLeader();
          });
          try {
            await GuideService.markSeen(
              uid: uid,
              role: guideRole,
              screenId: guideScreenId,
              version: guideVersion,
            );
          } catch (e) {
            debugPrint('Guide markSeen failed: $e');
          }
        },
      );
      if (started) {
        _guidePending = false;
      } else if (!_guideRetried) {
        _releaseSession();
        // Targets may not be laid out yet: one retry, never marked seen.
        _guideRetried = true;
        Future.delayed(const Duration(milliseconds: 300), () {
          if (mounted) scheduleGuide();
        });
      } else {
        _guidePending = false; // < 2 steps: give up, not marked seen
        _releaseSession();
        _settleLeader();
      }
    } catch (e, st) {
      debugPrint('Guide failed ($guideScreenId): $e\n$st');
      _guidePending = false;
      _releaseSession();
      _settleLeader();
    } finally {
      _guideBusy = false;
    }
  }
}
