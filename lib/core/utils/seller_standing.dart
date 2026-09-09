import 'package:freelancer/l10n/app_localizations.dart';

/// Review-based freelancer standing (Newcomer → Hupper).
enum SellerStanding {
  newcomer,
  advanced,
  pro,
  expert,
  golden,
  workhorse,
  workNinja,
  legend,
  hupper,
}

extension SellerStandingX on SellerStanding {
  String get assetPath => switch (this) {
        SellerStanding.newcomer => 'images/standings/newcomer.png',
        SellerStanding.advanced => 'images/standings/advanced.png',
        SellerStanding.pro => 'images/standings/pro.png',
        SellerStanding.expert => 'images/standings/expert.png',
        SellerStanding.golden => 'images/standings/golden.png',
        SellerStanding.workhorse => 'images/standings/workhorse.png',
        SellerStanding.workNinja => 'images/standings/workninja.png',
        SellerStanding.legend => 'images/standings/legend.png',
        SellerStanding.hupper => 'images/standings/hupper.png',
      };

  String label(AppLocalizations l10n) => switch (this) {
        SellerStanding.newcomer => l10n.standingNewcomer,
        SellerStanding.advanced => l10n.standingAdvanced,
        SellerStanding.pro => l10n.standingPro,
        SellerStanding.expert => l10n.standingExpert,
        SellerStanding.golden => l10n.standingGolden,
        SellerStanding.workhorse => l10n.standingWorkhorse,
        SellerStanding.workNinja => l10n.standingWorkNinja,
        SellerStanding.legend => l10n.standingLegend,
        SellerStanding.hupper => l10n.standingHupper,
      };
}

/// Resolves standing from live review average + count.
///
/// Thresholds (highest matching wins): both min reviews and min avg required.
class SellerStandingResolver {
  SellerStandingResolver._();

  static const _tiers = <({SellerStanding standing, int minReviews, double minRating})>[
    (standing: SellerStanding.hupper, minReviews: 1000, minRating: 4.8),
    (standing: SellerStanding.legend, minReviews: 500, minRating: 4.7),
    (standing: SellerStanding.workNinja, minReviews: 200, minRating: 4.6),
    (standing: SellerStanding.workhorse, minReviews: 100, minRating: 4.5),
    (standing: SellerStanding.golden, minReviews: 50, minRating: 4.5),
    (standing: SellerStanding.expert, minReviews: 25, minRating: 4.2),
    (standing: SellerStanding.pro, minReviews: 10, minRating: 4.0),
    (standing: SellerStanding.advanced, minReviews: 5, minRating: 3.5),
  ];

  static SellerStanding resolve({
    required double rating,
    required int reviewCount,
  }) {
    for (final tier in _tiers) {
      if (reviewCount >= tier.minReviews && rating >= tier.minRating) {
        return tier.standing;
      }
    }
    return SellerStanding.newcomer;
  }
}
