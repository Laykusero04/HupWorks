import 'package:flutter/material.dart';
import 'package:freelancer/core/constants/colors.dart';
import 'package:freelancer/data/models/notification_model.dart';

/// Slide-down banner for new notifications while the app is in the foreground.
class NotificationInAppBanner extends StatefulWidget {
  const NotificationInAppBanner({
    super.key,
    required this.notification,
    required this.onTap,
    required this.onDismiss,
  });

  final AppNotification notification;
  final VoidCallback onTap;
  final VoidCallback onDismiss;

  @override
  State<NotificationInAppBanner> createState() => _NotificationInAppBannerState();
}

class _NotificationInAppBannerState extends State<NotificationInAppBanner>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late final Animation<Offset> _slide;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 280),
    );
    _slide = Tween<Offset>(begin: const Offset(0, -1), end: Offset.zero).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeOutCubic),
    );
    _controller.forward();
    Future<void>.delayed(const Duration(seconds: 5), () {
      if (mounted) _dismiss();
    });
  }

  Future<void> _dismiss() async {
    if (!_controller.isAnimating && _controller.value == 0) return;
    await _controller.reverse();
    widget.onDismiss();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final top = MediaQuery.paddingOf(context).top + 8;
    return Positioned(
      top: top,
      left: 12,
      right: 12,
      child: SlideTransition(
        position: _slide,
        child: Material(
          elevation: 6,
          borderRadius: BorderRadius.circular(12),
          color: kWhite,
          child: InkWell(
            borderRadius: BorderRadius.circular(12),
            onTap: () {
              widget.onTap();
              _dismiss();
            },
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Icon(Icons.notifications_active_outlined, color: kPrimaryColor),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          widget.notification.title,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            fontWeight: FontWeight.w600,
                            color: kNeutralColor,
                            fontSize: 15,
                          ),
                        ),
                        if (widget.notification.body != null &&
                            widget.notification.body!.trim().isNotEmpty) ...[
                          const SizedBox(height: 4),
                          Text(
                            widget.notification.body!,
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(color: kSubTitleColor, fontSize: 13),
                          ),
                        ],
                      ],
                    ),
                  ),
                  IconButton(
                    visualDensity: VisualDensity.compact,
                    icon: const Icon(Icons.close, size: 20, color: kLightNeutralColor),
                    onPressed: _dismiss,
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
