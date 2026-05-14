import 'package:flutter/material.dart';
import 'package:nb_utils/nb_utils.dart';

import 'constant.dart';

/// Reusable page header used in place of the standard AppBar across
/// bottom-nav tab screens. Sits inside the body (no AppBar slot) and is
/// typically the first child of a `Column` under `SafeArea(bottom: false)`.
class AppHeader extends StatelessWidget {
  final String title;
  final Widget? subtitle;
  final Widget? leading;
  final List<Widget> actions;

  const AppHeader({
    super.key,
    required this.title,
    this.subtitle,
    this.leading,
    this.actions = const [],
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 14, 16, 14),
      child: Row(
        children: [
          if (leading != null) ...[
            leading!,
            12.width,
          ],
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: kTextStyle.copyWith(
                      color: kNeutralColor, fontWeight: FontWeight.bold, fontSize: 22, height: 1.1),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                if (subtitle != null) ...[
                  2.height,
                  DefaultTextStyle.merge(
                    style: kTextStyle.copyWith(color: kLightNeutralColor, fontSize: 12),
                    child: subtitle!,
                  ),
                ],
              ],
            ),
          ),
          for (final a in actions) ...[
            8.width,
            a,
          ],
        ],
      ),
    );
  }
}

/// A rounded-square icon badge for the leading slot.
class AppHeaderIcon extends StatelessWidget {
  final IconData icon;
  final Color color;
  const AppHeaderIcon({super.key, required this.icon, this.color = kPrimaryColor});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Icon(icon, color: color, size: 22),
    );
  }
}

/// A circular avatar (network image with asset fallback) for the leading slot.
class AppHeaderAvatar extends StatelessWidget {
  final String? imageUrl;
  final String fallbackAsset;
  final double size;
  const AppHeaderAvatar({
    super.key,
    this.imageUrl,
    this.fallbackAsset = 'images/profile1.png',
    this.size = 44,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      height: size,
      width: size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: kDarkWhite,
        border: Border.all(color: kPrimaryColor.withValues(alpha: 0.35), width: 2),
        image: DecorationImage(
          image: imageUrl != null ? NetworkImage(imageUrl!) as ImageProvider : AssetImage(fallbackAsset),
          fit: BoxFit.cover,
        ),
      ),
    );
  }
}

/// A bordered icon button for the trailing actions slot.
class AppHeaderAction extends StatelessWidget {
  final IconData icon;
  final VoidCallback? onPressed;
  final String? tooltip;
  const AppHeaderAction({super.key, required this.icon, this.onPressed, this.tooltip});

  @override
  Widget build(BuildContext context) {
    final enabled = onPressed != null;
    return Container(
      decoration: BoxDecoration(
        color: kWhite,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: kBorderColorTextField),
      ),
      child: IconButton(
        onPressed: onPressed,
        icon: Icon(icon, color: enabled ? kNeutralColor : kLightNeutralColor, size: 20),
        tooltip: tooltip,
        splashRadius: 22,
      ),
    );
  }
}
