import 'package:flutter/material.dart';
import 'package:freelancer/l10n/l10n.dart';

import 'guide_host.dart';
import 'guide_step.dart';

/// The (i) AppBar action: replays THIS screen's guide only.
///
/// Place it as the first AppBar action. Hidden when the guide kill switch is
/// off; disabled while the screen's data is loading or its guide is running.
/// Icon colour comes from the AppBar's icon theme. Do not give it a GlobalKey.
///
/// If the screen declares extra sections that can run right now
/// ([GuideHost.availableGuideSections]), a tap opens a small bottom sheet
/// ("Main tips" + each section). The sheet is closed BEFORE the guide starts
/// (the guide machinery cancels under a covering route). With no extra
/// sections the tap replays the core guide directly.
/// See the recipe in [GuideHost].
class GuideInfoButton extends StatefulWidget {
  const GuideInfoButton({super.key, required this.host});

  final GuideHost<StatefulWidget> host;

  @override
  State<GuideInfoButton> createState() => _GuideInfoButtonState();
}

class _GuideInfoButtonState extends State<GuideInfoButton> {
  @override
  void initState() {
    super.initState();
    widget.host.attachInfoButton();
  }

  @override
  void dispose() {
    widget.host.detachInfoButton();
    super.dispose();
  }

  Future<void> _onTap() async {
    final host = widget.host;
    final sections = host.availableGuideSections(context);
    if (sections.isEmpty) {
      _replayCore();
      return;
    }
    final picked = await showGuideChooser(context, sections);
    if (picked == null || !mounted || !host.mounted) return;
    // Let the sheet's exit animation finish so the route is really gone.
    await Future<void>.delayed(const Duration(milliseconds: 250));
    if (!mounted || !host.mounted) return;
    if (picked == GuideSection.coreId) {
      _replayCore();
      return;
    }
    host.replayGuide(sectionId: picked);
  }

  /// Runs the core guide, or says so when too few of its targets are on
  /// screen (for example an empty list); a tap must never fail silently.
  void _replayCore() {
    final host = widget.host;
    if (host.canRunCoreGuide) {
      host.replayGuide();
      return;
    }
    ScaffoldMessenger.maybeOf(context)?.showSnackBar(
      SnackBar(content: Text(context.l10n.guideNothingToShow)),
    );
  }

  @override
  Widget build(BuildContext context) {
    final host = widget.host;
    if (!host.guideEnabled) return const SizedBox.shrink();
    return ValueListenableBuilder<bool>(
      valueListenable: host.guideRunning,
      builder: (context, running, _) => IconButton(
        icon: const Icon(Icons.info_outline),
        tooltip: context.l10n.guideReplayThisScreen,
        onPressed: (running || !host.guideDataReady) ? null : _onTap,
      ),
    );
  }
}

/// Bottom sheet listing "Main tips" ([GuideSection.coreId]) and [sections].
/// Pops with the chosen section id, or null when dismissed.
Future<String?> showGuideChooser(
  BuildContext context,
  List<GuideSection> sections,
) {
  final l10n = context.l10n;
  return showModalBottomSheet<String>(
    context: context,
    showDragHandle: true,
    isScrollControlled: true,
    builder: (ctx) => SafeArea(
      child: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
              child: Text(
                l10n.guideChooserTitle,
                style: Theme.of(ctx).textTheme.titleMedium,
              ),
            ),
            ListTile(
              leading: const Icon(Icons.info_outline),
              title: Text(l10n.guideChooserMainTips),
              onTap: () => Navigator.of(ctx).pop(GuideSection.coreId),
            ),
            for (final s in sections)
              ListTile(
                leading: const Icon(Icons.lightbulb_outline),
                title: Text(s.title),
                onTap: () => Navigator.of(ctx).pop(s.id),
              ),
          ],
        ),
      ),
    ),
  );
}
