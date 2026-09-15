import 'package:flutter/material.dart';

import 'rubik_color_loader.dart';

/// Pull-to-refresh that shows the 4×4 color Rubik instead of the Material spinner.
class RubikRefreshIndicator extends StatefulWidget {
  const RubikRefreshIndicator({
    super.key,
    required this.onRefresh,
    required this.child,
    this.loaderSize = 40,
    this.notificationPredicate = defaultScrollNotificationPredicate,
    this.triggerMode = RefreshIndicatorTriggerMode.onEdge,
  });

  final RefreshCallback onRefresh;
  final Widget child;
  final double loaderSize;
  final ScrollNotificationPredicate notificationPredicate;
  final RefreshIndicatorTriggerMode triggerMode;

  @override
  State<RubikRefreshIndicator> createState() => _RubikRefreshIndicatorState();
}

class _RubikRefreshIndicatorState extends State<RubikRefreshIndicator> {
  RefreshIndicatorStatus? _status;

  bool get _visible {
    final s = _status;
    return s == RefreshIndicatorStatus.drag ||
        s == RefreshIndicatorStatus.armed ||
        s == RefreshIndicatorStatus.snap ||
        s == RefreshIndicatorStatus.refresh;
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      fit: StackFit.expand,
      children: [
        RefreshIndicator.noSpinner(
          onRefresh: widget.onRefresh,
          notificationPredicate: widget.notificationPredicate,
          triggerMode: widget.triggerMode,
          onStatusChange: (status) {
            if (!mounted) return;
            setState(() => _status = status);
          },
          child: widget.child,
        ),
        Positioned(
          top: 10,
          left: 0,
          right: 0,
          child: IgnorePointer(
            child: AnimatedOpacity(
              opacity: _visible ? 1 : 0,
              duration: const Duration(milliseconds: 160),
              child: _visible
                  ? Center(
                      child: Material(
                        color: Colors.white,
                        elevation: 3,
                        shadowColor: Colors.black26,
                        borderRadius: BorderRadius.circular(14),
                        child: Padding(
                          padding: const EdgeInsets.all(10),
                          child: RubikColorLoader(size: widget.loaderSize),
                        ),
                      ),
                    )
                  : const SizedBox.shrink(),
            ),
          ),
        ),
      ],
    );
  }
}
