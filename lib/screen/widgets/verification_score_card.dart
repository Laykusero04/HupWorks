import 'package:flutter/material.dart';
import 'word_safe_text.dart';
import 'package:freelancer/l10n/l10n.dart';
import 'package:freelancer/screen/widgets/constant.dart';
import 'package:freelancer/services/verification_service.dart';
import 'package:freelancer/core/guide/guide_anchor.dart';

/// Profile verification score: 50 profile photo + 50 face+ID = 100
/// (each awarded only after its own admin accept).
class VerificationScoreCard extends StatelessWidget {
  const VerificationScoreCard({
    super.key,
    required this.score,
    this.onTap,
    this.accent,
    this.compact = false,
    this.guideAnchor,
  });

  /// Optional guide target around this widget; see [GuideAnchor].
  final GuideAnchor? guideAnchor;

  final VerificationScore score;
  final VoidCallback? onTap;
  final Color? accent;
  final bool compact;

  @override
  Widget build(BuildContext context) =>
      GuideAnchor.wrap(guideAnchor, _buildContent(context));

  Widget _buildContent(BuildContext context) {
    final l10n = context.l10n;
    final brand = accent ?? kPrimaryColor;
    // Text variant of the brand colour (AA on white); ring stays bright.
    final brandText = _textVariant(brand);
    final awaitingAdmin =
        (score.hasProfilePhoto && !score.profilePhotoAccepted) ||
            (score.hasIdSelfie && !score.identityAccepted);
    final ringColor = score.isComplete
        ? const Color(0xFF0B7A3B)
        : awaitingAdmin
            ? const Color(0xFFB86E00)
            : brand;

    final card = Container(
      width: double.infinity,
      padding: EdgeInsets.all(compact ? 14 : 18),
      decoration: BoxDecoration(
        color: kWhite,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: ringColor.withValues(alpha: 0.18)),
        boxShadow: [
          BoxShadow(
            color: ringColor.withValues(alpha: 0.08),
            blurRadius: 14,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _header(context, l10n, ringColor, brand, brandText, awaitingAdmin),
          SizedBox(height: compact ? 12 : 16),
          _ScoreRow(
            state: score.profilePhotoAccepted
                ? _RowState.done
                : score.hasProfilePhoto
                    ? _RowState.pending
                    : _RowState.empty,
            title: l10n.profilePhotoLabel,
            subtitle: score.profilePhotoAccepted
                ? l10n.acceptedByAdmin
                : score.hasProfilePhoto
                    ? (score.profilePhotoStatus == 'rejected'
                        ? l10n.rejectedPleaseUpdatePhoto
                        : l10n.submittedAwaitingAdmin)
                    : l10n.notUploadedYet,
            points: VerificationScore.profilePhotoPoints,
            earned: score.profilePhotoPointsEarned,
            accent: ringColor == brand ? brandText : ringColor,
          ),
          const SizedBox(height: 10),
          _ScoreRow(
            state: score.identityAccepted
                ? _RowState.done
                : score.hasIdSelfie
                    ? _RowState.pending
                    : _RowState.empty,
            title: l10n.faceIdSelfieLabel,
            subtitle: score.identityAccepted
                ? l10n.acceptedByAdmin
                : score.hasIdSelfie
                    ? (score.identityStatus == 'rejected'
                        ? l10n.rejectedPleaseUpdateSelfie
                        : l10n.submittedAwaitingAdmin)
                    : l10n.notUploadedYet,
            points: VerificationScore.identityPoints,
            earned: score.identityPointsEarned,
            accent: ringColor == brand ? brandText : ringColor,
          ),
        ],
      ),
    );

    if (onTap == null) return card;
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: card,
      ),
    );
  }

  /// Ring + title/hint. At large text scale the ring stacks above the text so
  /// nothing is squeezed (T-0158 B3); the ring's own digits are scale-capped
  /// because the ring has a fixed size.
  Widget _header(BuildContext context, AppLocalizations l10n, Color ringColor,
      Color brand, Color brandText, bool awaitingAdmin) {
    final size = compact ? 56.0 : 72.0;
    final large = MediaQuery.textScalerOf(context).scale(1.0) > 1.3;
    final ring = MediaQuery.withClampedTextScaling(
      maxScaleFactor: 1.0,
      child: SizedBox(
        width: size,
        height: size,
        child: Stack(
          alignment: Alignment.center,
          children: [
            SizedBox(
              width: size,
              height: size,
              child: CircularProgressIndicator(
                value: score.isComplete
                    ? 1.0
                    : score.total > 0
                        ? score.progress
                        : 0.0,
                strokeWidth: compact ? 5 : 6,
                backgroundColor: ringColor.withValues(alpha: 0.12),
                color: ringColor,
                strokeCap: StrokeCap.round,
              ),
            ),
            Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  '${score.total}',
                  style: kTextStyle.copyWith(
                    color: ringColor == brand ? brandText : ringColor,
                    fontWeight: FontWeight.bold,
                    fontSize: compact ? 16 : 20,
                  ),
                ),
                Text(
                  '/${VerificationScore.maxScore}',
                  style: kTextStyle.copyWith(
                    color: kSubTitleColor,
                    fontSize: compact ? 9 : 10,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
    final texts = Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          score.isComplete
              ? l10n.fullyVerified
              : awaitingAdmin
                  ? l10n.awaitingAdminReview
                  : l10n.completeVerification,
          style: kTextStyle.copyWith(
            color: kNeutralColor,
            fontWeight: FontWeight.bold,
            fontSize: compact ? 14 : 16,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          l10n.verificationScoreHint,
          style: kTextStyle.copyWith(
            color: kSubTitleColor,
            fontSize: compact ? 11 : 12,
          ),
        ),
      ],
    );
    if (large) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [ring, const SizedBox(height: 12), texts],
      );
    }
    return Row(
      children: [
        ring,
        SizedBox(width: compact ? 12 : 16),
        Expanded(child: texts),
      ],
    );
  }
}

/// Bright brand colours fail AA as text on white: map them to text tokens.
Color _textVariant(Color c) {
  if (c == kPrimaryColor) return kPrimaryText;
  if (c == kSellerPrimary || c == kSecondaryColor) return kSecondaryText;
  return c;
}

enum _RowState { empty, pending, done }

class _ScoreRow extends StatelessWidget {
  const _ScoreRow({
    required this.state,
    required this.title,
    required this.subtitle,
    required this.points,
    required this.earned,
    required this.accent,
  });

  final _RowState state;
  final String title;
  final String subtitle;
  final int points;
  final int earned;
  final Color accent;

  @override
  Widget build(BuildContext context) {
    const pendingColor = Color(0xFFB86E00);
    const doneColor = Color(0xFF0B7A3B);
    final isDone = state == _RowState.done;
    final isPending = state == _RowState.pending;
    final large = MediaQuery.textScalerOf(context).scale(1.0) > 1.3;
    final pointsText = Text(
      '+$earned/$points',
      style: kTextStyle.copyWith(
        color: isDone
            ? doneColor
            : isPending
                ? pendingColor
                : accent,
        fontWeight: FontWeight.bold,
        fontSize: 13,
      ),
    );

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: isDone
            ? const Color(0xFFE7FFED)
            : isPending
                ? const Color(0xFFFFF4E0)
                : kDarkWhite,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: isDone
              ? doneColor.withValues(alpha: 0.25)
              : isPending
                  ? pendingColor.withValues(alpha: 0.35)
                  : kBorderColorTextField,
        ),
      ),
      child: Row(
        children: [
          Icon(
            isDone
                ? Icons.check_circle_rounded
                : isPending
                    ? Icons.hourglass_top_rounded
                    : Icons.radio_button_unchecked,
            size: 22,
            color: isDone
                ? doneColor
                : isPending
                    ? pendingColor
                    : kLightNeutralColor,
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                WordSafeText(
                  title,
                  maxLines: 3,
                  minScale: 0.85,
                  style: kTextStyle.copyWith(
                    color: kNeutralColor,
                    fontWeight: FontWeight.w700,
                    fontSize: 13,
                  ),
                ),
                const SizedBox(height: 2),
                WordSafeText(
                  subtitle,
                  maxLines: 4,
                  minScale: 0.85,
                  style: kTextStyle.copyWith(
                    color: kSubTitleColor,
                    fontSize: 11,
                  ),
                ),
                // Large text: the points go under the text so the label keeps
                // the full row width (no "Profielfot/o").
                if (large) ...[
                  const SizedBox(height: 2),
                  pointsText,
                ],
              ],
            ),
          ),
          if (!large) pointsText,
        ],
      ),
    );
  }
}
