/// Central switches for per-screen guides.
class GuideConfig {
  GuideConfig._();

  /// Kill switch. Set to false to disable every guide in the app
  /// (nothing starts, nothing is marked seen).
  static const bool enabled = true;

  /// PENDING OWNER DECISION (T-0003 plan, open question): whether taps on the
  /// dimmed barrier / highlighted target are blocked while a guide runs.
  /// true  = target is not interactive; user must use Next / Skip (plan's
  ///         recommendation, avoids navigating away mid-guide).
  /// false = target taps pass through.
  static const bool disableBarrierInteraction = true;
}
