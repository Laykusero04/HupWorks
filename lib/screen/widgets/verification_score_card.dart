import 'package:flutter/material.dart';
import 'package:freelancer/screen/widgets/constant.dart';
import 'package:freelancer/services/verification_service.dart';

/// Profile verification score: 50 profile photo + 50 face+ID = 100
/// (each awarded only after its own admin accept).
class VerificationScoreCard extends StatelessWidget {
  const VerificationScoreCard({
    super.key,
    required this.score,
    this.onTap,
    this.accent,
    this.compact = false,
  });

  final VerificationScore score;
  final VoidCallback? onTap;
  final Color? accent;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    final brand = accent ?? kPrimaryColor;
    final awaitingAdmin = (score.hasProfilePhoto && !score.profilePhotoAccepted) ||
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
          Row(
            children: [
              SizedBox(
                width: compact ? 56 : 72,
                height: compact ? 56 : 72,
                child: Stack(
                  alignment: Alignment.center,
                  children: [
                    SizedBox(
                      width: compact ? 56 : 72,
                      height: compact ? 56 : 72,
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
                            color: ringColor,
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
              SizedBox(width: compact ? 12 : 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      score.isComplete
                          ? 'Fully verified'
                          : awaitingAdmin
                              ? 'Awaiting admin review'
                              : 'Complete verification',
                      style: kTextStyle.copyWith(
                        color: kNeutralColor,
                        fontWeight: FontWeight.bold,
                        fontSize: compact ? 14 : 16,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Profile photo and face+ID are reviewed separately (50 pts each).',
                      style: kTextStyle.copyWith(
                        color: kSubTitleColor,
                        fontSize: compact ? 11 : 12,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          SizedBox(height: compact ? 12 : 16),
          _ScoreRow(
            state: score.profilePhotoAccepted
                ? _RowState.done
                : score.hasProfilePhoto
                    ? _RowState.pending
                    : _RowState.empty,
            title: 'Profile photo',
            subtitle: score.profilePhotoAccepted
                ? 'Accepted by admin'
                : score.hasProfilePhoto
                    ? (score.profilePhotoStatus == 'rejected'
                        ? 'Rejected — please update photo'
                        : 'Submitted — awaiting admin')
                    : 'Not uploaded yet',
            points: VerificationScore.profilePhotoPoints,
            earned: score.profilePhotoPointsEarned,
            accent: ringColor,
          ),
          const SizedBox(height: 10),
          _ScoreRow(
            state: score.identityAccepted
                ? _RowState.done
                : score.hasIdSelfie
                    ? _RowState.pending
                    : _RowState.empty,
            title: 'Face + ID selfie',
            subtitle: score.identityAccepted
                ? 'Accepted by admin'
                : score.hasIdSelfie
                    ? (score.identityStatus == 'rejected'
                        ? 'Rejected — please update selfie'
                        : 'Submitted — awaiting admin')
                    : 'Not uploaded yet',
            points: VerificationScore.identityPoints,
            earned: score.identityPointsEarned,
            accent: ringColor,
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
                Text(
                  title,
                  style: kTextStyle.copyWith(
                    color: kNeutralColor,
                    fontWeight: FontWeight.w700,
                    fontSize: 13,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  subtitle,
                  style: kTextStyle.copyWith(
                    color: kSubTitleColor,
                    fontSize: 11,
                  ),
                ),
              ],
            ),
          ),
          Text(
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
          ),
        ],
      ),
    );
  }
}
