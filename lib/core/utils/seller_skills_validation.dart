import 'package:freelancer/data/models/seller_skill_model.dart';

class SellerSkillsValidation {
  static const int maxFiveStar = 3;
  static const int maxFourStar = 2;
  static const int maxLowStar = 3;

  /// Returns null when valid, otherwise an error message.
  /// Skills are optional — empty list is allowed.
  static String? validate(List<SellerSkill> skills) {
    final cleaned = skills
        .where((s) => s.name.trim().isNotEmpty)
        .map((s) => SellerSkill(name: s.name.trim(), stars: s.stars))
        .toList();

    if (cleaned.isEmpty) return null;

    if (cleaned.length != skills.where((s) => s.name.trim().isNotEmpty).length) {
      return 'All skills must have a name.';
    }

    final seen = <String>{};
    for (final skill in cleaned) {
      final key = skill.name.toLowerCase();
      if (seen.contains(key)) {
        return 'Duplicate skill: ${skill.name}';
      }
      seen.add(key);
    }

    final five = cleaned.where((s) => s.stars == 5).toList();
    final four = cleaned.where((s) => s.stars == 4).toList();
    final low = cleaned.where((s) => s.stars >= 1 && s.stars <= 3).toList();
    final invalid = cleaned.where((s) => s.stars < 1 || s.stars > 5).toList();

    if (invalid.isNotEmpty) {
      return 'Each skill must be rated between 1 and 5 stars.';
    }

    if (five.length > maxFiveStar) {
      return 'At most $maxFiveStar skills at 5 stars.';
    }
    if (four.length > maxFourStar) {
      return 'At most $maxFourStar skills at 4 stars.';
    }
    if (low.length > maxLowStar) {
      return 'At most $maxLowStar skills at 1–3 stars.';
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
