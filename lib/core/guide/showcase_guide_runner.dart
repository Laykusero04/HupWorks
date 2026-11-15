import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart' show RenderParagraph;
import 'package:showcaseview/showcaseview.dart';

import '../constants/colors.dart';
import 'guide_config.dart';
import 'guide_nav_bridge.dart';
import 'guide_session.dart';
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

  /// Gap between the Skip pill and whatever is below it (nav bar / inset).
  static const double _pillGap = 8;

  @visibleForTesting
  static bool debugFitsSideBySide({
    required double avail,
    required String skipLabel,
    required String actionLabel,
    required double scale,
  }) =>
      _GuideActions.fitsSideBySide(
        avail: avail,
        skipLabel: skipLabel,
        actionLabel: actionLabel,
        scaler: TextScaler.linear(scale),
        direction: TextDirection.ltr,
      );

  static const TextStyle _pillTextStyle = TextStyle(
    color: Colors.black87,
    fontSize: 14,
    fontWeight: FontWeight.w600,
  );

  /// Rough tooltip height at text scale 1; scaled by the text scaler when
  /// deciding whether the tooltip could reach the pill.
  static const double _tooltipEstimate = 170;

  /// Chooses where the Skip pill goes so it never covers the current target.
  ///
  /// Order of preference: bottom-start (above the nav), top-end, top-start,
  /// bottom-end. A slot is rejected when its (text-scale aware) pill rect
  /// intersects the target rect inflated by 8dp. Bottom-start is also rejected
  /// when the target is flagged/lower-half or the target + estimated tooltip
  /// reaches the pill band. If every slot collides, [PillSlot.docked] is
  /// returned: Skip is shown inside the tooltip card next to Next instead of
  /// floating. Pure function: unit tested.
  static PillSlot pickPillSlot({
    required Rect? target,
    required Size screen,
    required double topInset,
    required double bottomOffset,
    required double scale,
    required bool rtl,
    required bool targetNearBottom,
    required double tooltipEstimate,
    double? pillWidth,
    List<Rect> keepOut = const [],
  }) {
    final s = scale > 1 ? scale : 1.0;
    final pillH = 48.0 * s;
    // Measured pill width when known (label + padding), else a generous guess.
    final pillW = pillWidth ?? 150.0 * s;
    const margin = 12.0;
    final topY = topInset + 8;
    final bottomY = screen.height - bottomOffset - pillH;
    Rect rect(PillSlot slot) {
      final atEnd = slot == PillSlot.topEnd || slot == PillSlot.bottomEnd;
      final isTop = slot == PillSlot.topEnd || slot == PillSlot.topStart;
      // Logical end is the right edge in LTR, the left edge in RTL.
      final right = atEnd != rtl;
      final x = right ? screen.width - margin - pillW : margin;
      return Rect.fromLTWH(x, isTop ? topY : bottomY, pillW, pillH);
    }

    // Header action icons (help, bell, menu...) are keep-out areas too: a
    // slot is rejected when the pill would cover one (T-0156 B5).
    bool hits(PillSlot slot) {
      final r = rect(slot);
      if (target != null && r.overlaps(target.inflate(8))) return true;
      for (final k in keepOut) {
        if (r.overlaps(k)) return true;
      }
      return false;
    }

    var bottomOk = !hits(PillSlot.bottomStart) && !targetNearBottom;
    if (target != null) {
      if (target.center.dy > screen.height / 2) bottomOk = false;
      if (target.bottom + tooltipEstimate * s > bottomY) bottomOk = false;
    }
    if (bottomOk) return PillSlot.bottomStart;
    for (final slot in const [
      PillSlot.topEnd,
      PillSlot.topStart,
      PillSlot.bottomEnd,
    ]) {
      if (!hits(slot)) return slot;
    }
    // No free slot at all: dock Skip inside the tooltip card (T-0158 B1).
    return PillSlot.docked;
  }

  /// Rects of tappable header actions (IconButton, PopupMenuButton, or an
  /// InkWell / GestureDetector wrapping an Icon) in the header band (below the
  /// status bar, within one toolbar height). Best effort: walks the live
  /// element tree of the VISIBLE screen only; Offstage, ticker-disabled
  /// (inactive tab) and non-current route subtrees are skipped (T-0156 M1).
  static List<Rect> headerIconRects(double topInset, double scale) {
    final out = <Rect>[];
    final root = WidgetsBinding.instance.rootElement;
    if (root == null) return out;
    final s = scale > 1 ? scale : 1.0;
    final bandBottom = topInset + 64.0 * s;
    final maxSide = 100.0 * s;

    bool hasIcon(Element e) {
      var found = false;
      void v(Element c) {
        if (found) return;
        if (c.widget is Icon || c.widget is ImageIcon) {
          found = true;
          return;
        }
        c.visitChildren(v);
      }

      e.visitChildren(v);
      return found;
    }

    bool tappable(Element e) {
      final w = e.widget;
      if (w is IconButton || w is PopupMenuButton) return true;
      if (w is InkWell) return w.onTap != null && hasIcon(e);
      if (w is GestureDetector) return w.onTap != null && hasIcon(e);
      return false;
    }

    void visit(Element e) {
      final w = e.widget;
      if (w is Offstage && w.offstage) return;
      if (w is TickerMode && !w.enabled) return;
      if (w is Scaffold && ModalRoute.of(e)?.isCurrent == false) return;
      if (tappable(e)) {
        final ro = e.renderObject;
        if (ro is RenderBox && ro.attached && ro.hasSize) {
          try {
            final r = ro.localToGlobal(Offset.zero) & ro.size;
            final inBand = r.bottom <= bandBottom && r.bottom > topInset;
            if (inBand && r.width <= maxSide && r.height <= maxSide) {
              out.add(r.inflate(4));
              return; // do not descend into the button
            }
          } catch (_) {}
        }
      }
      e.visitChildren(visit);
    }

    try {
      root.visitChildren(visit);
    } catch (_) {}
    return out;
  }

  /// Rects of the AppBar title, leading and action widgets of the visible
  /// screen's AppBar (found by widget identity inside the AppBar subtree).
  /// Complements [headerIconRects] for headers whose icons are not plain
  /// IconButtons, and keeps the pill off the screen title (T-0158 B1).
  /// The AppBar title box is usually as wide as the free toolbar span; use the
  /// union of the painted paragraphs inside it instead, so top slots stay
  /// usable. Null when the title paints no text (caller falls back to the box).
  static Rect? _paintedTitleRect(Element title) {
    Rect? out;
    void v(Element e) {
      final ro = e.renderObject;
      if (ro is RenderParagraph && ro.attached && ro.hasSize) {
        final r = ro.localToGlobal(Offset.zero) & ro.size;
        out = out == null ? r : out!.expandToInclude(r);
      }
      e.visitChildren(v);
    }

    v(title);
    return out;
  }

  static List<Rect> appBarRects() {
    final out = <Rect>[];
    final root = WidgetsBinding.instance.rootElement;
    if (root == null) return out;

    void collect(Element bar, AppBar w) {
      final wanted = <Widget>[
        if (w.title != null) w.title!,
        if (w.leading != null) w.leading!,
        ...?w.actions,
      ];
      void v(Element c) {
        for (final t in wanted) {
          if (identical(c.widget, t)) {
            final ro = c.renderObject;
            if (ro is RenderBox && ro.attached && ro.hasSize) {
              try {
                final box = ro.localToGlobal(Offset.zero) & ro.size;
                final painted =
                    identical(t, w.title) ? _paintedTitleRect(c) : null;
                out.add((painted ?? box).inflate(4));
              } catch (_) {}
            }
            return;
          }
        }
        c.visitChildren(v);
      }

      bar.visitChildren(v);
    }

    void visit(Element e) {
      final w = e.widget;
      if (w is Offstage && w.offstage) return;
      if (w is TickerMode && !w.enabled) return;
      if (w is Scaffold && ModalRoute.of(e)?.isCurrent == false) return;
      if (w is AppBar) {
        collect(e, w);
        return;
      }
      e.visitChildren(visit);
    }

    try {
      root.visitChildren(visit);
    } catch (_) {}
    return out;
  }

  /// Rects of wide primary action buttons (Elevated/Filled/Text/Outlined
  /// buttons at least 55% of the screen width) in the lower 35% of the
  /// screen, e.g. a "Submit" bar. The Skip pill keeps out of them, also when
  /// they are disabled (T-0157 N5). Same visibility rules as [headerIconRects].
  static List<Rect> bottomButtonRects(Size screen) {
    final out = <Rect>[];
    final root = WidgetsBinding.instance.rootElement;
    if (root == null) return out;
    final minTop = screen.height * 0.65;
    void visit(Element e) {
      final w = e.widget;
      if (w is Offstage && w.offstage) return;
      if (w is TickerMode && !w.enabled) return;
      if (w is Scaffold && ModalRoute.of(e)?.isCurrent == false) return;
      if (w is ButtonStyleButton) {
        final ro = e.renderObject;
        if (ro is RenderBox && ro.attached && ro.hasSize) {
          try {
            final r = ro.localToGlobal(Offset.zero) & ro.size;
            if (r.width >= screen.width * 0.55 && r.top >= minTop) {
              out.add(r);
              return;
            }
          } catch (_) {}
        }
      }
      e.visitChildren(visit);
    }

    try {
      root.visitChildren(visit);
    } catch (_) {}
    return out;
  }

  // Header rects per tour step (keyed by the step's Showcase key): computed
  // once per step, not on every overlay rebuild.
  final Map<GlobalKey, List<Rect>> _headerCache = {};
  static final GlobalKey _noStepKey = GlobalKey();

  /// True when the current step has no free floating slot and Skip is shown
  /// inside the tooltip card (see [PillSlot.docked]).
  @visibleForTesting
  final ValueNotifier<bool> skipDocked = ValueNotifier<bool>(false);

  ShowcaseView? _view;
  void Function(bool finished)? _onEnd;
  bool _ended = false;

  /// Set by [start]: a tab tap ends the Home tour, so the chained shell
  /// guide is suppressed (only for the chain leader, T-0156 M2).
  bool _suppressShellOnTab = false;

  bool get isRunning => _view?.isShowcaseRunning ?? false;

  void attach() {
    if (_view != null) return;
    _view = ShowcaseView.register(
      scope: scope,
      // No inter-action gap: the docked Skip carries its own end padding, so a
      // hidden Skip leaves no gap before Next.
      globalTooltipActionConfig: const TooltipActionConfig(actionGap: 0),
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
    _headerCache.clear();
    skipDocked.value = false;
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
    Color actionColor = kPrimaryFill,
    bool suppressShellOnTabTap = false,
  }) {
    final view = _view;
    if (!GuideConfig.enabled || view == null || !context.mounted) return false;
    // Showcase 5.x does not attach its GlobalKey to an element (it only uses it
    // as an id), so key.currentContext is always null. Use the package check.
    final live = steps.where((s) => view.isTargetRendered(s.key)).toList();
    if (live.length < 2) return false;
    try {
      _ended = false;
      _headerCache.clear();
      _suppressShellOnTab = suppressShellOnTabTap;
      _onEnd = onEnd;
      _order = live.map((s) => s.key).toList();
      _autoScroll = {for (final s in live) s.key: s.enableAutoScroll};
      view.enableAutoScroll = live.first.enableAutoScroll;
      final lastKey = live.last.key;
      final others = live.take(live.length - 1).map((s) => s.key).toList();
      view.globalTooltipActions = [
        TooltipActionButton.custom(
          button: _GuideActions(
            docked: skipDocked,
            skipLabel: skipLabel,
            actionLabel: nextLabel,
            color: actionColor,
            onSkip: () => _view?.dismiss(),
            onNext: () => _view?.next(),
          ),
          hideActionWidgetForShowcase: [lastKey],
        ),
        TooltipActionButton.custom(
          button: _GuideActions(
            docked: skipDocked,
            skipLabel: skipLabel,
            actionLabel: doneLabel,
            color: actionColor,
            showSkip: false,
            onSkip: () => _view?.dismiss(),
            onNext: () => _view?.next(),
          ),
          hideActionWidgetForShowcase: others,
        ),
      ];
      final nearBottom = {for (final s in live) s.key: s.targetNearBottom};
      view.globalFloatingActionWidget = (ctx) => _overlayChrome(
            ctx,
            skipLabel: skipLabel,
            nearBottom: nearBottom,
          );
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

  /// Skip pill + transparent tab hit zones, drawn in the overlay.
  ///
  /// Pill: bottom-start above the MEASURED nav bar (or the safe-area inset
  /// when no nav is visible); moves to the top-end when the target is in the
  /// bottom half or the target + tooltip could reach the pill band.
  /// Tab zones: see [GuideNavBridge]; one tap ends the tour and switches tab.
  FloatingActionWidget _overlayChrome(
    BuildContext ctx, {
    required String skipLabel,
    required Map<GlobalKey, bool> nearBottom,
  }) {
    // Overlay context reports 0 padding; use the view's real insets.
    final v = View.of(ctx);
    final pad = MediaQueryData.fromView(v).padding;
    final screenH = v.physicalSize.height / v.devicePixelRatio;
    final screenW = v.physicalSize.width / v.devicePixelRatio;
    final scale = MediaQueryData.fromView(v).textScaler.scale(1.0);
    final dir = Directionality.of(ctx);

    final nav = GuideNavBridge.barRect();
    final bottomOffset =
        (nav != null ? screenH - nav.top : pad.bottom) + _pillGap;

    final w = ctx.widget;
    final flaggedNearBottom =
        (w is Showcase ? nearBottom[w.showcaseKey] : null) ?? false;
    Rect? target;
    try {
      final ro = ctx.findRenderObject();
      if (ro is RenderBox && ro.attached && ro.hasSize) {
        target = ro.localToGlobal(Offset.zero) & ro.size;
      }
    } catch (_) {}
    // Floating pill text is capped at 1.3 like the docked buttons (N7).
    final pillScaler =
        MediaQueryData.fromView(v).textScaler.clamp(maxScaleFactor: 1.3);
    final painter = TextPainter(
      text: TextSpan(text: skipLabel, style: _pillTextStyle),
      textScaler: pillScaler,
      maxLines: 1,
      textDirection: dir,
    )..layout();
    final measuredW = painter.width + 40; // 20dp padding each side
    painter.dispose();
    final slot = pickPillSlot(
      pillWidth: measuredW,
      target: target,
      screen: Size(screenW, screenH),
      topInset: pad.top,
      bottomOffset: bottomOffset,
      scale: scale,
      rtl: dir == TextDirection.rtl,
      targetNearBottom: flaggedNearBottom,
      tooltipEstimate: _tooltipEstimate,
      keepOut: _headerCache.putIfAbsent(
        w is Showcase ? w.showcaseKey : _noStepKey,
        () => [
          ...headerIconRects(pad.top, scale),
          ...appBarRects(),
          ...bottomButtonRects(Size(screenW, screenH)),
        ],
      ),
    );
    final docked = slot == PillSlot.docked;
    if (skipDocked.value != docked) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (skipDocked.value != docked) skipDocked.value = docked;
      });
    }
    // The floating pill and the docked card button are both driven by the
    // single [skipDocked] value (see ValueListenableBuilder below), so exactly
    // one Skip control is visible per frame. While the notifier still lags a
    // freshly computed "docked" result the pill sits at bottom-start.
    final shown = docked ? PillSlot.bottomStart : slot;
    final top = shown == PillSlot.topEnd || shown == PillSlot.topStart;
    final atEnd = shown == PillSlot.topEnd || shown == PillSlot.bottomEnd;

    final pill = Material(
      color: Colors.white,
      shape: const StadiumBorder(),
      elevation: 2,
      child: Semantics(
        button: true,
        container: true,
        label: skipLabel,
        excludeSemantics: true,
        onTap: () => _view?.dismiss(),
        child: InkWell(
          key: const ValueKey('guide_skip_pill'),
          customBorder: const StadiumBorder(),
          onTap: () => _view?.dismiss(),
          child: ConstrainedBox(
            constraints: const BoxConstraints(minHeight: 48, minWidth: 48),
            child: Center(
              widthFactor: 1,
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: Text(
                  skipLabel,
                  textScaler: pillScaler,
                  style: _pillTextStyle,
                ),
              ),
            ),
          ),
        ),
      ),
    );

    final handle = GuideNavBridge.handle;
    final count = handle?.tabCount() ?? 0;
    return FloatingActionWidget(
      left: 0,
      right: 0,
      top: 0,
      bottom: 0,
      child: Stack(
        children: [
          if (nav != null && handle != null && count > 0)
            Positioned(
              left: nav.left + 6,
              width: nav.width - 12,
              top: nav.top,
              height: nav.height,
              child: Row(
                children: [
                  for (var i = 0; i < count; i++)
                    Expanded(
                      child: GestureDetector(
                        key: ValueKey('guide_nav_zone_$i'),
                        behavior: HitTestBehavior.opaque,
                        onTap: () {
                          // Same as Skip (marks the guide seen), then switch.
                          // The user chose a destination: the shell "Your
                          // tabs" guide must not chain after this one.
                          if (_suppressShellOnTab) {
                            GuideSession.instance.suppressShellGuide();
                          }
                          _view?.dismiss();
                          handle.onTab(i);
                        },
                      ),
                    ),
                ],
              ),
            ),
          ValueListenableBuilder<bool>(
            valueListenable: skipDocked,
            builder: (_, isDocked, __) => isDocked
                ? const SizedBox.shrink()
                : Positioned.directional(
                    textDirection: dir,
                    start: atEnd ? null : 12,
                    end: atEnd ? 12 : null,
                    top: top ? pad.top + 8 : null,
                    bottom: top ? null : bottomOffset,
                    child: pill,
                  ),
          ),
        ],
      ),
    );
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

/// Where the Skip pill sits. Start/end are logical (flip in RTL).
/// [docked] = no free slot: Skip is shown inside the tooltip card.
enum PillSlot { bottomStart, topEnd, topStart, bottomEnd, docked }

/// Action row of the tooltip card: Next / Done, plus a docked "Skip tour"
/// when the floating pill has no free slot ([docked]). Text scale capped at
/// 1.3. Side by side (Skip start, Next end) when it fits, otherwise stacked
/// (Next on top, Skip below, both full width, >= 48 tall). Nothing is clipped.
class _GuideActions extends StatelessWidget {
  const _GuideActions({
    required this.docked,
    required this.skipLabel,
    required this.actionLabel,
    required this.color,
    required this.onSkip,
    required this.onNext,
    this.showSkip = true,
  });

  final ValueListenable<bool> docked;
  final String skipLabel;
  final String actionLabel;
  final Color color;
  final VoidCallback onSkip;
  final VoidCallback onNext;
  final bool showSkip;

  static const TextStyle _nextStyle = TextStyle(
    color: kWhite,
    fontWeight: FontWeight.w700,
    fontSize: 15,
  );
  static const _nextPad = EdgeInsets.symmetric(horizontal: 20, vertical: 10);
  static const _skipPad = EdgeInsets.symmetric(horizontal: 12);

  /// True when Skip and Next fit side by side in [avail] with a 16dp gap, each
  /// in a half-width button. Measured with the REAL labels at the effective
  /// (capped) text scale, not a screen-width guess.
  @visibleForTesting
  static bool fitsSideBySide({
    required double avail,
    required String skipLabel,
    required String actionLabel,
    required TextScaler scaler,
    required TextDirection direction,
  }) {
    double w(String t, TextStyle st) {
      final tp = TextPainter(
        text: TextSpan(text: t, style: st),
        textDirection: direction,
        textScaler: scaler,
        maxLines: 1,
      )..layout();
      final r = tp.width;
      tp.dispose();
      return r;
    }

    final half = (avail - 16) / 2;
    return w(skipLabel, ShowcaseGuideRunner._pillTextStyle) +
                _skipPad.horizontal <=
            half &&
        w(actionLabel, _nextStyle) + _nextPad.horizontal <= half;
  }

  // The tooltip lays its actions out with a dry-layout pass, so no
  // LayoutBuilder here: the width is the screen minus the tooltip margin
  // (2 x 14) and card padding (2 x 16), a few dp short on purpose. Skip/Next/
  // Done always fill that width.
  @override
  Widget build(BuildContext context) {
    final scaler = MediaQuery.textScalerOf(context).clamp(maxScaleFactor: 1.3);
    final dir = Directionality.of(context);
    final avail = (MediaQuery.sizeOf(context).width - 64).clamp(120.0, 600.0);
    return MediaQuery.withClampedTextScaling(
      maxScaleFactor: 1.3,
      child: ValueListenableBuilder<bool>(
        valueListenable: docked,
        builder: (context, on, _) {
          final withSkip = on && showSkip;
          if (!withSkip) return SizedBox(width: avail, child: _next());
          if (fitsSideBySide(
            avail: avail,
            skipLabel: skipLabel,
            actionLabel: actionLabel,
            scaler: scaler,
            direction: dir,
          )) {
            // Skip (secondary) at the start, Next (primary) at the end.
            return SizedBox(
              width: avail,
              child: Row(
                children: [
                  Expanded(child: _skip()),
                  const SizedBox(width: 16),
                  Expanded(child: _next()),
                ],
              ),
            );
          }
          // Stacked: Next on top, Skip below, full width, 8dp gap.
          return SizedBox(
            width: avail,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [_next(), const SizedBox(height: 8), _skip()],
            ),
          );
        },
      ),
    );
  }

  Widget _next() => Semantics(
        button: true,
        liveRegion: true,
        child: GestureDetector(
          onTap: onNext,
          child: Container(
            constraints: const BoxConstraints(minHeight: 48),
            alignment: Alignment.center,
            padding: _nextPad,
            decoration: BoxDecoration(
              color: color,
              borderRadius: BorderRadius.circular(50),
            ),
            child: Text(
              actionLabel,
              textAlign: TextAlign.center,
              style: _nextStyle,
            ),
          ),
        ),
      );

  Widget _skip() => Semantics(
        button: true,
        container: true,
        label: skipLabel,
        excludeSemantics: true,
        onTap: onSkip,
        child: OutlinedButton(
          key: const ValueKey('guide_skip_docked'),
          onPressed: onSkip,
          style: OutlinedButton.styleFrom(
            minimumSize: const Size(48, 48),
            foregroundColor: Colors.black87,
            side: BorderSide(color: color, width: 1.5),
            shape: const StadiumBorder(),
            padding: _skipPad,
          ),
          child: Text(
            skipLabel,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            textAlign: TextAlign.center,
            style: ShowcaseGuideRunner._pillTextStyle,
          ),
        ),
      );
}
