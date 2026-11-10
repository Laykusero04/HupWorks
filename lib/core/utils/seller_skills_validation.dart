import 'package:freelancer/data/models/seller_skill_model.dart';
import 'package:freelancer/l10n/app_localizations.dart';

class SellerSkillsValidation {
  static const int maxFiveStar = 3;
  static const int maxFourStar = 2;
  static const int maxLowStar = 3;

  /// Returns null when valid, otherwise an error message.
  /// Skills are optional — empty list is allowed.
  static String? validate(List<SellerSkill> skills, AppLocalizations l10n) {
    final cleaned = skills
        .where((s) => s.name.trim().isNotEmpty)
        .map((s) => SellerSkill(name: s.name.trim(), stars: s.stars))
        .toList();

    if (cleaned.isEmpty) return null;

    if (cleaned.length != skills.where((s) => s.name.trim().isNotEmpty).length) {
      return l10n.skillErrNameRequired;
    }

    final seen = <String>{};
    for (final skill in cleaned) {
      final key = skill.name.toLowerCase();
      if (seen.contains(key)) {
        return l10n.skillErrDuplicate(skill.name);
      }
      seen.add(key);
    }

    final five = cleaned.where((s) => s.stars == 5).toList();
    final four = cleaned.where((s) => s.stars == 4).toList();
    final low = cleaned.where((s) => s.stars >= 1 && s.stars <= 3).toList();
    final invalid = cleaned.where((s) => s.stars < 1 || s.stars > 5).toList();

    if (invalid.isNotEmpty) {
      return l10n.skillErrStarsRange;
    }

    if (five.length > maxFiveStar) {
      return l10n.skillErrMaxFive(maxFiveStar);
    }
    if (four.length > maxFourStar) {
      return l10n.skillErrMaxFour(maxFourStar);
    }
    if (low.length > maxLowStar) {
      return l10n.skillErrMaxLow(maxLowStar);
    }

    return null;
  }

  static List<SellerSkill> skillsForTier(List<SellerSkill> skills, int tierStars) {
    if (tierStars == 5) {
      return skills.where((s) => s.stars == 5).toList();
    }
    if (tierStars == 4) {
      return skills.where((s) => s.stars == 4).toList();
    }
    return skills.where((s) => s.stars >= 1 && s.stars <= 3).toList();
  }

  static int maxForTier(int tierStars) {
    if (tierStars == 5) return maxFiveStar;
    if (tierStars == 4) return maxFourStar;
    return maxLowStar;
  }
}
