import 'package:flutter/material.dart';
import 'package:freelancer/data/models/seller_skill_model.dart';

import 'constant.dart';

/// Read-only grouped skill chips for public/own profile views.
class SellerSkillsDisplay extends StatelessWidget {
  const SellerSkillsDisplay({
    super.key,
    required this.skills,
    this.accentColor = kPrimaryColor,
  });

  final List<SellerSkill> skills;
  final Color accentColor;

  @override
  Widget build(BuildContext context) {
    if (skills.isEmpty) return const SizedBox.shrink();

    final five = skills.where((s) => s.stars == 5).toList();
    final four = skills.where((s) => s.stars == 4).toList();
    final low = skills.where((s) => s.stars >= 1 && s.stars <= 3).toList();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (five.isNotEmpty) _tierGroup('Top skills (5★)', five, 5),
        if (four.isNotEmpty) ...[
          if (five.isNotEmpty) const SizedBox(height: 12),
          _tierGroup('4★ skills', four, 4),
        ],
        if (low.isNotEmpty) ...[
          if (five.isNotEmpty || four.isNotEmpty) const SizedBox(height: 12),
          _tierGroup('1–3★ skills', low, null),
        ],
      ],
    );
  }

  Widget _tierGroup(String label, List<SellerSkill> tierSkills, int? fixedStars) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: kTextStyle.copyWith(
            color: accentColor,
            fontWeight: FontWeight.bold,
            fontSize: 13,
          ),
        ),
        const SizedBox(height: 8),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: tierSkills.map((skill) {
            final stars = fixedStars ?? skill.stars;
            return Chip(
              label: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(skill.name, style: kTextStyle.copyWith(fontSize: 12)),
                  const SizedBox(width: 4),
                  ...List.generate(
                    stars.clamp(1, 5),
                    (_) => Icon(Icons.star_rounded, size: 12, color: ratingBarColor),
                  ),
                ],
              ),
              backgroundColor: accentColor.withValues(alpha: 0.1),
              side: BorderSide.none,
            );
          }).toList(),
        ),
      ],
    );
  }
}
