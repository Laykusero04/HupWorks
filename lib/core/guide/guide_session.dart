import 'package:flutter/foundation.dart';

/// App-wide "one guide at a time" rule (showcaseview has a single shared
/// overlay) plus the home-then-shell ordering.
///
/// * [tryAcquire] / [release]: only one guide may run at once.
/// * [homeSettled]: the Home guide (chain leader) is done for this session:
///   seen before, finished, skipped, or given up. The shell guide waits for it
///   so Home always runs first.
///
/// Listeners (the [GuideHost] mixin) are notified on every change so a guide
/// that was waiting can re-schedule itself.
class GuideSession extends ChangeNotifier {
  GuideSession._();

  static final GuideSession instance = GuideSession._();

  /// Fired by Settings "Replay guides" after the seen flags were cleared.
  /// Mounted [GuideHost]s listen and re-arm their guide (screens that stay
  /// mounted, like Home and the shell, would otherwise never re-check).
  static final ValueNotifier<int> replayRequested = ValueNotifier<int>(0);

  /// Call after [GuideService.resetAll].
  static void requestReplay() {
    instance.resetHome(); // Home runs first again, then the shell.
    replayRequested.value++;
  }

  /// True while the shell's Scaffold drawer is open. A drawer is not a route,
  /// so TickerMode/ModalRoute cannot see it; the shell sets this from
  /// `Scaffold.onDrawerChanged`. Guides never run while it is true.
  static final ValueNotifier<bool> drawerOpen = ValueNotifier<bool>(false);

  /// True while ANY guide is on screen. Root-level Back blockers (PopScope)
  /// depend on this, not on one host: with Android predictive back the
  /// framework only keeps Back when the root navigator's route says
  /// canPop=false, so a nested (shell branch) guide must be visible there too.
  static final ValueNotifier<bool> anyRunning = ValueNotifier<bool>(false);

  static Object? _runningOwner;
  static VoidCallback? _dismissRunning;

  /// A host's guide became visible. [dismiss] closes it as a Skip.
  static void beginRunning(Object owner, VoidCallback dismiss) {
    _runningOwner = owner;
    _dismissRunning = dismiss;
    anyRunning.value = true;
  }

  /// No-op unless [owner] is the running guide's host.
  static void endRunning(Object owner) {
    if (!identical(_runningOwner, owner)) return;
    _runningOwner = null;
    _dismissRunning = null;
    anyRunning.value = false;
  }

  /// System Back: closes the running guide (as Skip). Returns whether one ran.
  static bool dismissRunning() {
    final d = _dismissRunning;
    if (d == null) return false;
    d();
    return true;
  }

  Object? _holder;
  bool _homeSettled = false;

  bool get isBusy => _holder != null;
  bool get homeSettled => _homeSettled;

  /// True if [owner] now holds the session (or already did).
  bool tryAcquire(Object owner) {
    if (_holder != null && !identical(_holder, owner)) return false;
    _holder = owner;
    return true;
  }

  /// No-op unless [owner] holds the session.
  void release(Object owner) {
    if (!identical(_holder, owner)) return;
    _holder = null;
    notifyListeners();
  }

  void markHomeSettled() {
    if (_homeSettled) return;
    _homeSettled = true;
    notifyListeners();
  }

  /// A new Home chain leader was created (new screen instance / sign-in).
  void resetHome() {
    if (!_homeSettled) return;
    _homeSettled = false;
    notifyListeners();
  }

  @visibleForTesting
  void resetForTest() {
    drawerOpen.value = false;
    _runningOwner = null;
    _dismissRunning = null;
    anyRunning.value = false;
    _holder = null;
    _homeSettled = false;
  }
}
