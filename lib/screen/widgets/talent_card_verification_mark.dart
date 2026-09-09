import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:freelancer/l10n/l10n.dart';
import 'package:freelancer/services/verification_service.dart';

import 'constant.dart';

/// Compact trust mark for talent cards — progress ring + check or score.
///
/// Shows admin-accepted trust at a glance without bulky status text.
class TalentCardVerificationMark extends StatelessWidget {
  const TalentCardVerificationMark({
    super.key,
    required this.profile,
    this.size = 32,
    this.onPhoto = false,
  });

  final Map<String, dynamic>? profile;
  final double size;

  /// Stronger contrast when overlaid on a photo.
  final bool onPhoto;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final score = VerificationService.scoreFromProfile(profile);
    final status = score.status;
    final colors = _colorsFor(status);
    final progress = score.progress.clamp(0.0, 1.0);
    final fullyVerified = score.isComplete;

    final tooltip = fullyVerified
        ? '${l10n.statusVerified} · ${score.total}/100'
        : status == 'pending'
            ? '${l10n.statusPending} · ${score.total}/100'
            : status == 'rejected'
                ? '${l10n.statusRejected} · ${score.total}/100'
                : '${l10n.notVerified} · ${score.total}/100';

    final mark = SizedBox(
      width: size,
      height: size,
      child: CustomPaint(
        painter: _TrustRingPainter(
          progress: progress,
          trackColor: onPhoto
              ? Colors.white.withValues(alpha: 0.35)
              : colors.track,
          progressColor: colors.accent,
          strokeWidth: size * 0.1,
        ),
        child: Center(
          child: Container(
            width: size * 0.68,
            height: size * 0.68,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: onPhoto
                  ? Colors.black.withValues(alpha: 0.45)
                  : colors.fill,
              border: onPhoto
                  ? null
                  : Border.all(color: colors.accent.withValues(alpha: 0.25)),
            ),
            alignment: Alignment.center,
            child: fullyVerified
                ? Icon(
                    Icons.verified_rounded,
                    size: size * 0.42,
                    color: onPhoto ? Colors.white : colors.accent,
                  )
                : Icon(
                    status == 'pending'
                        ? Icons.hourglass_top_rounded
                        : status == 'rejected'
                            ? Icons.cancel_outlined
                            : Icons.shield_outlined,
                    size: size * 0.38,
                    color: onPhoto ? Colors.white : colors.accent,
                  ),
          ),
        ),
      ),
    );

    return Tooltip(
      message: tooltip,
      child: mark,
    );
  }

  static _MarkColors _colorsFor(String status) {
    switch (status) {
      case 'verified':
        return const _MarkColors(
          accent: Color(0xFF0B7A3B),
          fill: Color(0xFFE7FFED),
          track: Color(0xFFC8E6C9),
        );
      case 'pending':
        return const _MarkColors(
          accent: Color(0xFFB86E00),
          fill: Color(0xFFFFF4E0),
          track: Color(0xFFFFE0B2),
        );
      case 'rejected':
        return const _MarkColors(
          accent: Color(0xFFC62828),
          fill: Color(0xFFFFEBEE),
          track: Color(0xFFFFCDD2),
        );
      default:
        return const _MarkColors(
          accent: Color(0xFF607D8B),
          fill: Color(0xFFF5F7F8),
          track: Color(0xFFCFD8DC),
        );
    }
  }
}

/// Status line + dual-track dots (photo · ID) under a card title.
class TalentCardVerificationMeta extends StatelessWidget {
  const TalentCardVerificationMeta({
    super.key,
    required this.profile,
    this.showMark = false,
  });

  final Map<String, dynamic>? profile;

  /// When true, also shows the ring mark (use if photo has no overlay).
  final bool showMark;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final score = VerificationService.scoreFromProfile(profile);
    final photoOk = score.profilePhotoAccepted;
    final idOk = score.identityAccepted;

    final label = score.isComplete
        ? l10n.verifiedFreelancer
        : score.status == 'pending'
            ? l10n.statusPending
            : score.status == 'rejected'
                ? l10n.statusRejected
                : l10n.notVerified;

    final labelColor = score.isComplete
        ? const Color(0xFF0B7A3B)
        : score.status == 'pending'
            ? const Color(0xFFB86E00)
            : score.status == 'rejected'
                ? const Color(0xFFC62828)
                : kSubTitleColor;

    return Row(
      children: [
        if (showMark) ...[
          TalentCardVerificationMark(profile: profile, size: 28),
          const SizedBox(width: 8),
        ],
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: kTextStyle.copyWith(
                  color: labelColor,
                  fontWeight: FontWeight.w600,
                  fontSize: 11,
                ),
              ),
              const SizedBox(height: 4),
              Row(
                children: [
                  _TrackPill(
                    ok: photoOk,
                    icon: Icons.person_rounded,
                    label: l10n.profilePhotoLabel,
                  ),
                  const SizedBox(width: 6),
                  _TrackPill(
                    ok: idOk,
                    icon: Icons.badge_rounded,
                    label: l10n.faceIdSelfieLabel,
                  ),
                ],
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _TrackPill extends StatelessWidget {
  const _TrackPill({
    required this.ok,
    required this.icon,
    required this.label,
  });

  final bool ok;
  final IconData icon;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Tooltip(
      message: label,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
        decoration: BoxDecoration(
          color: ok ? const Color(0xFFE7FFED) : const Color(0xFFF1F3F5),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: ok ? const Color(0xFF0B7A3B) : const Color(0xFFCFD8DC),
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              icon,
              size: 12,
              color: ok ? const Color(0xFF0B7A3B) : const Color(0xFF90A4AE),
            ),
            const SizedBox(width: 2),
            Icon(
              ok ? Icons.check_rounded : Icons.close_rounded,
              size: 11,
              color: ok ? const Color(0xFF0B7A3B) : const Color(0xFF90A4AE),
            ),
          ],
        ),
      ),
    );
  }
}

class _MarkColors {
  const _MarkColors({
    required this.accent,
    required this.fill,
    required this.track,
  });

  final Color accent;
  final Color fill;
  final Color track;
}

class _TrustRingPainter extends CustomPainter {
  _TrustRingPainter({
    required this.progress,
    required this.trackColor,
    required this.progressColor,
    required this.strokeWidth,
  });

  final double progress;
  final Color trackColor;
  final Color progressColor;
  final double strokeWidth;

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = (math.min(size.width, size.height) - strokeWidth) / 2;
    final track = Paint()
      ..color = trackColor
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth
      ..strokeCap = StrokeCap.round;
    final active = Paint()
      ..color = progressColor
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth
      ..strokeCap = StrokeCap.round;

    canvas.drawCircle(center, radius, track);
    if (progress > 0) {
      canvas.drawArc(
        Rect.fromCircle(center: center, radius: radius),
        -math.pi / 2,
        2 * math.pi * progress,
        false,
        active,
      );
    }
  }

  @override
  bool shouldRepaint(covariant _TrustRingPainter oldDelegate) {
    return oldDelegate.progress != progress ||
        oldDelegate.trackColor != trackColor ||
        oldDelegate.progressColor != progressColor ||
        oldDelegate.strokeWidth != strokeWidth;
  }
}
