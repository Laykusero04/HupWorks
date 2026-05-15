import 'package:flutter/material.dart';
import 'package:nb_utils/nb_utils.dart';

import 'constant.dart';

/// Which shell gradient / accents to use for [ShellTabHeader].
enum ShellPersona { client, seller }

/// Gradient header for bottom-nav tab pages (matches home hero style).
class ShellTabHeader extends StatelessWidget {
  final ShellPersona persona;
  final String title;
  final Widget? subtitle;
  final Widget? leading;
  final Widget? titleIcon;
  final List<Widget> actions;

  const ShellTabHeader({
    super.key,
    required this.persona,
    required this.title,
    this.subtitle,
    this.leading,
    this.titleIcon,
    this.actions = const [],
  });

  List<Color> get _gradientColors =>
      persona == ShellPersona.client ? kClientShellGradient : kSellerShellGradient;

  Color get _shadowColor {
    if (persona == ShellPersona.client) {
      return kPrimaryColor.withValues(alpha: 0.18);
    }
    return kSellerPrimary.withValues(alpha: 0.22);
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: _gradientColors,
        ),
        borderRadius: const BorderRadius.vertical(bottom: Radius.circular(28)),
        boxShadow: [
          BoxShadow(
            color: _shadowColor,
            blurRadius: 18,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: SafeArea(
        bottom: false,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 10, 16, 18),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (leading != null) leading!,
              if (leading != null) 10.width,
              if (titleIcon != null) ...[
                titleIcon!,
                10.width,
              ],
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: kTextStyle.copyWith(
                        color: Colors.white,
                        fontWeight: FontWeight.w800,
                        fontSize: 22,
                        height: 1.1,
                      ),
                    ),
                    if (subtitle != null) ...[
                      4.height,
                      DefaultTextStyle.merge(
                        style: kTextStyle.copyWith(
                          color: Colors.white.withValues(alpha: 0.88),
                          fontSize: 12,
                          height: 1.25,
                        ),
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
        ),
      ),
    );
  }
}

/// Icon button for [ShellTabHeader] — frosted circle on gradient.
class ShellTabIconButton extends StatelessWidget {
  final IconData icon;
  final VoidCallback? onPressed;
  final String? tooltip;

  const ShellTabIconButton({
    super.key,
    required this.icon,
    this.onPressed,
    this.tooltip,
  });

  @override
  Widget build(BuildContext context) {
    final enabled = onPressed != null;
    final inner = Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onPressed,
        customBorder: const CircleBorder(),
        child: Container(
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(
            color: Colors.white.withValues(alpha: 0.18),
            shape: BoxShape.circle,
            border: Border.all(color: Colors.white.withValues(alpha: 0.35)),
          ),
          child: Icon(
            icon,
            color: enabled ? Colors.white : Colors.white.withValues(alpha: 0.45),
            size: 22,
          ),
        ),
      ),
    );
    if (tooltip == null || tooltip!.isEmpty) return inner;
    return Tooltip(message: tooltip!, child: inner);
  }
}

/// Small decorative icon tile (e.g. contracts) on gradient headers.
class ShellTabTitleBadge extends StatelessWidget {
  final IconData icon;

  const ShellTabTitleBadge({
    super.key,
    required this.icon,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.2),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.white.withValues(alpha: 0.35)),
      ),
      child: Icon(icon, color: Colors.white, size: 22),
    );
  }
}
