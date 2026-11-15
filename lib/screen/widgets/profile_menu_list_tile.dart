import 'package:flutter/material.dart';

import 'constant.dart';
import 'package:freelancer/core/guide/guide_anchor.dart';

/// Plain drawer / profile menu row.
class ProfileMenuListTile extends StatelessWidget {
  const ProfileMenuListTile({
    super.key,
    required this.icon,
    required this.title,
    required this.onTap,
    this.subtitle,
    this.guideAnchor,
  });

  /// Optional guide target around this widget; see [GuideAnchor].
  final GuideAnchor? guideAnchor;

  final IconData icon;
  final String title;
  final String? subtitle;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) =>
      GuideAnchor.wrap(guideAnchor, _buildContent(context));

  Widget _buildContent(BuildContext context) {
    // Text scale capped at 1.3 (like tooltips): drawer is navigation chrome,
    // so long Dutch words wrap at word boundaries and tiles stay compact.
    return MediaQuery.withClampedTextScaling(
      maxScaleFactor: 1.3,
      child: ListTile(
        dense: true,
        contentPadding: const EdgeInsets.symmetric(horizontal: 8),
        leading: Icon(icon, color: kNeutralColor, size: 22),
        // Up to 2 lines, wrapping at word boundaries (no mid-word breaks, no
        // shrinking to tiny text at large text scale, T-0156).
        title: Text(
          title,
          maxLines: 2,
          softWrap: true,
          overflow: TextOverflow.ellipsis,
          style: kTextStyle.copyWith(color: kNeutralColor, fontSize: 15),
        ),
        subtitle: subtitle == null
            ? null
            : Text(
                subtitle!,
                style: kTextStyle.copyWith(color: kSubTitleColor, fontSize: 12),
              ),
        trailing: const Icon(Icons.chevron_right,
            color: kLightNeutralColor, size: 20),
        onTap: onTap,
      ),
    );
  }
}
