import 'package:flutter/widgets.dart';

/// Package-neutral description of one guide step.
///
/// Text is resolved from l10n by the caller at start time (never cached).
class GuideStep {
  const GuideStep({
    required this.key,
    required this.title,
    required this.description,
    this.targetNearBottom = false,
    this.enableAutoScroll = false,
  });

  /// Key attached to the target widget (wrapped by a [Showcase] in the screen).
  final GlobalKey key;
  final String title;
  final String description;

  /// True when the target is in the bottom half of the screen (e.g. the
  /// bottom nav bar). The Skip pill then moves to the top (end side) so it
  /// never covers the target; otherwise it sits at the bottom.
  final bool targetNearBottom;

  /// True when the target may be below the fold of a scrollable. The runner
  /// then scrolls it into view (centered, via the package's
  /// `Scrollable.ensureVisible`) before showing this step. Off by default: a
  /// visible target should not make the page jump. Targets that were never
  /// built (lazy list items off-screen) cannot be scrolled to; they are
  /// dropped like any unrendered target.
  final bool enableAutoScroll;
}

/// One guide of a screen: the core guide (auto-runs once) or an on-demand
/// section (only runs from the (i) chooser, never marks seen).
class GuideSection {
  const GuideSection({
    required this.id,
    required this.title,
    required this.steps,
  });

  /// Stable id, unique per screen; never [coreId].
  final String id;

  /// Localized chooser label (resolve from l10n when building).
  final String title;
  final List<GuideStep> steps;

  /// Id of the core section (the one `buildGuideSteps` returns).
  static const coreId = 'core';
}
