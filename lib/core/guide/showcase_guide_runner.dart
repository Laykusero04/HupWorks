import 'package:flutter/material.dart';
import 'package:showcaseview/showcaseview.dart';

import 'guide_config.dart';
import 'guide_step.dart';

/// Thin adapter around showcaseview 5.x. The only file that imports it
/// (screens still need `Showcase` widgets around their targets).
///
/// One runner per screen; it owns a named scope so a leftover view can never
/// control another screen.
///
/// showcaseview 5.x requires the scope to be registered BEFORE any `Showcase`
/// widget of that scope is built (its initState looks the scope up and throws
/// otherwise). So [attach] must be called from the screen's initState; it only
/// registers, it does not start anything. [start] is called later.
class ShowcaseGuideRunner {
  ShowcaseGuideRunner(this.scope);

  final String scope;
  ShowcaseView? _view;
  void Function(bool finished)? _onEnd;
  bool _ended = false;

  bool get isRunning => _view?.isShowcaseRunning ?? false;

  void attach() {
    if (_view != null) return;
    _view = ShowcaseView.register(
      scope: scope,
      disableBarrierInteraction: GuideConfig.disableBarrierInteraction,
      onFinish: () => _end(true),
      onDismiss: (_) => _end(false),
      onStart: (index, key) => _prepareNextAutoScroll(key),
    );
  }

  List<GlobalKey> _order = const [];
  Map<GlobalKey, bool> _autoScroll = const {};

  /// The package decides per step (from the Showcase config, else the view's
  /// `enableAutoScroll`) whether to scroll the target into view. Our Showcases
  /// set no config, so the view flag decides. [start] sets it for the first
  /// step; this sets it for the step AFTER the one that just started (the guide
  /// is forward-only: Next / Skip). The package reads the flag after calling
  /// onStart, so the flag must already hold the CURRENT step's value then,
  /// which the previous step's call (or [start]) set.
  void _prepareNextAutoScroll(GlobalKey started) {
    final v = _view;
    if (v == null) return;
    final i = _order.indexOf(started);
    if (i < 0 || i + 1 >= _order.length) return;
    v.enableAutoScroll = _autoScroll[_order[i + 1]] ?? false;
  }

  /// How many of [steps] have a rendered target right now.
  int renderedCount(List<GuideStep> steps) {
    final v = _view;
    if (v == null) return 0;
    return steps.where((s) => v.isTargetRendered(s.key)).length;
  }

  void _end(bool finished) {
    if (_ended) return;
    _ended = true;
    _view?.enableAutoScroll = false;
    final cb = _onEnd;
    _onEnd = null;
    cb?.call(finished);
  }

  /// Starts the guide. Returns false (and starts nothing) when fewer than two
  /// steps have a rendered target. [onEnd] is called once with `finished`
  /// true (last step done) or false (skipped / dismissed). Never called when
  /// the guide is torn down with [stop].
  bool start({
    required BuildContext context,
    required List<GuideStep> steps,
    required String skipLabel,
    required String nextLabel,
    required String doneLabel,
    required void Function(bool finished) onEnd,
  }) {
    final view = _view;
    if (!GuideConfig.enabled || view == null || !context.mounted) return false;
    // Showcase 5.x does not attach its GlobalKey to an element (it only uses it
    // as an id), so key.currentContext is always null. Use the package check.
    final live = steps.where((s) => view.isTargetRendered(s.key)).toList();
    if (live.length < 2) return false;
    try {
      _ended = false;
      _onEnd = onEnd;
      _order = live.map((s) => s.key).toList();
      _autoScroll = {for (final s in live) s.key: s.enableAutoScroll};
      view.enableAutoScroll = live.first.enableAutoScroll;
      final lastKey = live.last.key;
      final others = live.take(live.length - 1).map((s) => s.key).toList();
      view.globalTooltipActions = [
        TooltipActionButton(
          type: TooltipDefaultActionType.next,
          name: nextLabel,
          hideActionWidgetForShowcase: [lastKey],
        ),
        TooltipActionButton(
          type: TooltipDefaultActionType.next,
          name: doneLabel,
          hideActionWidgetForShowcase: others,
        ),
      ];
      final nearBottom = {
        for (final s in live) s.key: s.targetNearBottom,
      };
      view.globalFloatingActionWidget = (ctx) {
        // showcaseview 5.1.0 exposes no public target rect, so the position
        // depends on the step's [GuideStep.targetNearBottom] flag.
        // ctx is the target's own Showcase context (built per controller), so
        // resolve the key from it rather than from the (timing-dependent)
        // active key.
        final w = ctx.widget;
        final flagged =
            (w is Showcase ? nearBottom[w.showcaseKey] : null) ?? false;
        // Automatic check: the target's centre is in the bottom half of the
        // screen. ctx is the target's Showcase element, so its render box is
        // the target. Falls back to the flag when not laid out yet.
        var topPlacement = flagged;
        try {
          final ro = ctx.findRenderObject();
          if (ro is RenderBox && ro.attached && ro.hasSize) {
            final view0 = View.of(ctx);
            final screenH = view0.physicalSize.height / view0.devicePixelRatio;
            final cy = ro.localToGlobal(ro.size.center(Offset.zero)).dy;
            if (cy > screenH / 2) topPlacement = true;
          }
        } catch (_) {}
        // Overlay context reports 0 padding; use the view's real insets so
        // the pill clears the status bar / home indicator (taps there are
        // swallowed on iOS).
        final pad = MediaQueryData.fromView(View.of(ctx)).padding;
        final dir = Directionality.of(ctx);
        return FloatingActionWidget.directional(
          textDirection: dir,
          start: topPlacement ? null : 12,
          end: topPlacement ? 12 : null,
          top: topPlacement ? pad.top + 8 : null,
          bottom: topPlacement ? null : pad.bottom + 16,
          child: Material(
            color: Colors.white,
            shape: const StadiumBorder(),
            elevation: 2,
            child: Semantics(
              button: true,
              label: skipLabel,
              child: InkWell(
                customBorder: const StadiumBorder(),
                onTap: () {
                  _view?.dismiss();
                },
                child: Padding(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                  child: Text(
                    skipLabel,
                    style: const TextStyle(
                      color: Colors.black87,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ),
            ),
          ),
        );
      };
      view.startShowCase(live.map((s) => s.key).toList());
      return true;
    } catch (e, st) {
      debugPrint('Guide start failed ($scope): $e\n$st');
      _onEnd = null;
      try {
        view.dismiss();
      } catch (_) {}
      return false;
    }
  }

  /// Closes a running guide as a dismiss (fires [onEnd] with finished=false,
  /// i.e. counts as Skip). Used by system Back.
  void dismiss() {
    final v = _view;
    if (v == null || !v.isShowcaseRunning) return;
    try {
      v.dismiss();
    } catch (e) {
      debugPrint('Guide dismiss failed ($scope): $e');
    }
  }

  /// Hides a running guide WITHOUT firing callbacks (nothing is marked seen);
  /// the runner stays usable. For tab deselect / route covered.
  void cancel() {
    final v = _view;
    if (v == null || !v.isShowcaseRunning) return;
    _onEnd = null;
    try {
      v.dismiss();
    } catch (e) {
      debugPrint('Guide cancel failed ($scope): $e');
    }
  }

  /// Tears the guide down WITHOUT firing finish/dismiss callbacks, so nothing
  /// is marked seen. Call from dispose and on tab deselect. After this the
  /// runner must not be reused.
  void stop() {
    final v = _view;
    _view = null;
    _onEnd = null;
    if (v == null) return;
    try {
      v.unregister();
    } catch (e) {
      debugPrint('Guide stop failed ($scope): $e');
    }
  }
}
