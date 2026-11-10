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
  });

  /// Key attached to the target widget (wrapped by a [Showcase] in the screen).
  final GlobalKey key;
  final String title;
  final String description;

  /// True when the target is in the bottom half of the screen (e.g. the
  /// bottom nav bar). The Skip pill then moves to the top (end side) so it
  /// never covers the target; otherwise it sits at the bottom.
  final bool targetNearBottom;
}
