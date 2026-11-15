import 'package:flutter/widgets.dart';

/// Lets a tour overlay leave the shell bottom nav usable (T-0148 follow-up).
///
/// The showcase overlay sits above the whole Scaffold, so it would swallow
/// taps on the tab bar. The shell registers a [GuideNavHandle]; while a tour
/// runs, the runner renders transparent per-tab hit zones over the bar inside
/// the overlay. Tapping a zone ends the tour exactly like Skip (the guide is
/// marked seen) and then switches to that tab, in one tap. Taps anywhere else
/// on the dimmed area do nothing (barrier interaction stays disabled).
class GuideNavHandle {
  GuideNavHandle({
    required this.barKey,
    required this.tabCount,
    required this.onTab,
    required this.isVisible,
  });

  /// Key on the rendered bar (used to measure its real rect).
  final GlobalKey barKey;
  final int Function() tabCount;
  final void Function(int index) onTab;

  /// False while a root route covers the shell (bar not on screen).
  final bool Function() isVisible;
}

class GuideNavBridge {
  GuideNavBridge._();

  static GuideNavHandle? _handle;
  static GuideNavHandle? get handle => _handle;

  static void register(GuideNavHandle h) => _handle = h;

  static void unregister(GuideNavHandle h) {
    if (identical(_handle, h)) _handle = null;
  }

  /// Global rect of the bar, or null when absent / covered / not laid out.
  static Rect? barRect() {
    final h = _handle;
    if (h == null || !h.isVisible()) return null;
    final ro = h.barKey.currentContext?.findRenderObject();
    if (ro is! RenderBox || !ro.attached || !ro.hasSize) return null;
    return ro.localToGlobal(Offset.zero) & ro.size;
  }
}
