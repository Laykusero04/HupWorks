import 'package:flutter/widgets.dart';
import 'package:showcaseview/showcaseview.dart';

/// Everything a screen needs to attach a guide target to a SHARED widget.
///
/// Shared widgets take an optional `GuideAnchor? guideAnchor` (default null)
/// and wrap their output with [GuideAnchor.wrap]. Only the screen that owns
/// the guide passes one, so a [GlobalKey] is only ever attached where a single
/// screen supplies it (no duplicate keys when the widget is used elsewhere).
///
/// ```dart
/// VerificationScoreCard(
///   score: s,
///   guideAnchor: GuideAnchor(
///     key: _scoreKey, scope: guideScope,
///     title: l10n.guideXTitle, description: l10n.guideXDesc),
/// )
/// ```
/// The same [key] may be listed in a [GuideStep]; the step then reads the
/// title/description from the same call site.
class GuideAnchor {
  const GuideAnchor({
    required this.key,
    required this.scope,
    required this.title,
    required this.description,
    this.borderRadius,
  });

  final GlobalKey key;

  /// `GuideHost.guideScope` of the owning screen.
  final String scope;
  final String title;
  final String description;
  final BorderRadius? borderRadius;

  /// Wraps [child] in a [Showcase] when [anchor] is set, else returns [child]
  /// untouched (no extra widget, no key).
  static Widget wrap(GuideAnchor? anchor, Widget child) {
    if (anchor == null) return child;
    return Showcase(
      key: anchor.key,
      scope: anchor.scope,
      title: anchor.title,
      description: anchor.description,
      targetBorderRadius: anchor.borderRadius ?? BorderRadius.zero,
      child: child,
    );
  }
}
