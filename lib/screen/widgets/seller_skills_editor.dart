import 'package:flutter/material.dart';
import 'package:freelancer/core/utils/seller_skills_validation.dart';
import 'package:freelancer/data/models/seller_skill_model.dart';
import 'package:freelancer/services/skill_service.dart';

import 'constant.dart';
import 'skill_picker_field.dart';

/// Edits freelancer skills in three clear tiers using the preset catalog.
class SellerSkillsEditor extends StatefulWidget {
  const SellerSkillsEditor({
    super.key,
    required this.skills,
    required this.onChanged,
  });

  final List<SellerSkill> skills;
  final ValueChanged<List<SellerSkill>> onChanged;

  @override
  State<SellerSkillsEditor> createState() => _SellerSkillsEditorState();
}

class _SellerSkillsEditorState extends State<SellerSkillsEditor> {
  late List<_SkillRow> _fiveStar;
  late List<_SkillRow> _fourStar;
  late List<_SkillRow> _lowStar;
  List<Map<String, dynamic>> _catalog = [];
  bool _catalogLoading = true;

  @override
  void initState() {
    super.initState();
    _initFromSkills(widget.skills);
    _loadCatalog();
  }

  Future<void> _loadCatalog() async {
    try {
      final list = await SkillService.listForPicker();
      if (mounted) {
        setState(() {
          _catalog = list;
          _catalogLoading = false;
          _syncCustomFlags();
        });
      }
    } catch (_) {
      if (mounted) setState(() => _catalogLoading = false);
    }
  }

  @override
  void didUpdateWidget(covariant SellerSkillsEditor oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.skills != widget.skills) {
      _initFromSkills(widget.skills);
      _syncCustomFlags();
    }
  }

  void _initFromSkills(List<SellerSkill> skills) {
    final five = SellerSkillsValidation.skillsForTier(skills, 5);
    final four = SellerSkillsValidation.skillsForTier(skills, 4);
    final low = skills.where((s) => s.stars >= 1 && s.stars <= 3).toList();

    _fiveStar = five.map((s) => _SkillRow(name: s.name, stars: 5)).toList();
    _fourStar = four.map((s) => _SkillRow(name: s.name, stars: 4)).toList();
    _lowStar = low.map((s) => _SkillRow(name: s.name, stars: s.stars)).toList();
  }

  bool _isCatalogSkill(String name) {
    final key = name.trim().toLowerCase();
    return _catalog.any((s) => (s['name'] as String? ?? '').trim().toLowerCase() == key);
  }

  void _syncCustomFlags() {
    for (final row in [..._fiveStar, ..._fourStar, ..._lowStar]) {
      final name = row.name?.trim();
      row.isCustom = name != null && name.isNotEmpty && !_isCatalogSkill(name);
    }
  }

  Set<String> get _selectedNamesLower {
    final names = <String>{};
    for (final row in [..._fiveStar, ..._fourStar, ..._lowStar]) {
      final n = row.name?.trim();
      if (n != null && n.isNotEmpty) names.add(n.toLowerCase());
    }
    return names;
  }

  void _notify() {
    final merged = <SellerSkill>[];
    for (final row in _fiveStar) {
      final name = row.name?.trim();
      if (name != null && name.isNotEmpty) merged.add(SellerSkill(name: name, stars: 5));
    }
    for (final row in _fourStar) {
      final name = row.name?.trim();
      if (name != null && name.isNotEmpty) merged.add(SellerSkill(name: name, stars: 4));
    }
    for (final row in _lowStar) {
      final name = row.name?.trim();
      if (name != null && name.isNotEmpty) {
        merged.add(SellerSkill(name: name, stars: row.stars.clamp(1, 3)));
      }
    }
    widget.onChanged(merged);
  }

  Set<String> _excludedFor(_SkillRow? current) {
    final currentName = current?.name?.trim().toLowerCase();
    return _selectedNamesLower.where((n) => n != currentName).toSet();
  }

  void _applySkill(_SkillRow row, String name) {
    if (!mounted) return;
    setState(() {
      row.name = name;
      row.isCustom = !_isCatalogSkill(name);
    });
    _notify();
  }

  void _pickSkill(_SkillRow row, {required String title}) {
    showSkillPickerSheet(
      context: context,
      skills: _catalog,
      title: title,
      excludedNames: _excludedFor(row),
      onSelected: (name) => _applySkill(row, name),
    );
  }

  void _addOptional(List<_SkillRow> list, int stars) {
    final title = switch (stars) {
      5 => 'Add a skill you\'re best at',
      4 => 'Add a skill you\'re good at',
      _ => 'Add a skill you\'re learning',
    };
    showSkillPickerSheet(
      context: context,
      skills: _catalog,
      title: title,
      excludedNames: _excludedFor(null),
      onSelected: (name) {
        setState(() {
          list.add(_SkillRow(
            name: name,
            stars: stars,
            isCustom: !_isCatalogSkill(name),
          ));
        });
        _notify();
      },
    );
  }

  void _removeOptional(List<_SkillRow> list, int index) {
    setState(() => list.removeAt(index));
    _notify();
  }

  @override
  Widget build(BuildContext context) {
    if (_catalogLoading) {
      return const Padding(
        padding: EdgeInsets.symmetric(vertical: 24),
        child: Center(child: CircularProgressIndicator(color: kPrimaryColor)),
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        if (_catalog.isEmpty)
          Padding(
            padding: const EdgeInsets.only(bottom: 12),
            child: Text(
              'Preset skill list unavailable — you can still add custom skills.',
              style: kTextStyle.copyWith(color: kLightNeutralColor, fontSize: 12),
            ),
          ),
        _TierCard(
          badge: const SkillTierBadge(filledStars: 5, totalStars: 5),
          title: 'Best at',
          subtitle: 'Optional — pick from the list or add your own',
          children: [
            for (var i = 0; i < _fiveStar.length; i++) ...[
              if (i > 0) const SizedBox(height: 8),
              SkillSlotTile(
                index: i + 1,
                name: _fiveStar[i].name,
                isCustom: _fiveStar[i].isCustom,
                onTap: () => _pickSkill(_fiveStar[i], title: 'Change skill'),
                onClear: () => _removeOptional(_fiveStar, i),
              ),
            ],
            if (_fiveStar.length < SellerSkillsValidation.maxFiveStar) ...[
              if (_fiveStar.isNotEmpty) const SizedBox(height: 8),
              _AddSkillButton(
                label: 'Add skill',
                onTap: () => _addOptional(_fiveStar, 5),
              ),
            ],
          ],
        ),
        const SizedBox(height: 12),
        _TierCard(
          badge: const SkillTierBadge(filledStars: 4, totalStars: 5),
          title: 'Also good at',
          subtitle: 'Optional — up to 2 more skills',
          children: [
            for (var i = 0; i < _fourStar.length; i++) ...[
              if (i > 0) const SizedBox(height: 8),
              SkillSlotTile(
                index: i + 1,
                name: _fourStar[i].name,
                isCustom: _fourStar[i].isCustom,
                onTap: () => _pickSkill(_fourStar[i], title: 'Change skill'),
                onClear: () => _removeOptional(_fourStar, i),
              ),
            ],
            if (_fourStar.length < SellerSkillsValidation.maxFourStar) ...[
              if (_fourStar.isNotEmpty) const SizedBox(height: 8),
              _AddSkillButton(
                label: 'Add skill',
                onTap: () => _addOptional(_fourStar, 4),
              ),
            ],
          ],
        ),
        const SizedBox(height: 12),
        _TierCard(
          badge: const SkillTierBadge(filledStars: 2, totalStars: 5),
          title: 'Still learning',
          subtitle: 'Optional — up to 3 skills, rate 1–3 stars',
          children: [
            for (var i = 0; i < _lowStar.length; i++) ...[
              if (i > 0) const SizedBox(height: 8),
              SkillSlotTile(
                index: i + 1,
                name: _lowStar[i].name,
                isCustom: _lowStar[i].isCustom,
                onTap: () => _pickSkill(_lowStar[i], title: 'Change skill'),
                onClear: () => _removeOptional(_lowStar, i),
                trailing: LowStarPicker(
                  value: _lowStar[i].stars,
                  onChanged: (v) {
                    setState(() => _lowStar[i].stars = v);
                    _notify();
                  },
                ),
              ),
            ],
            if (_lowStar.length < SellerSkillsValidation.maxLowStar) ...[
              if (_lowStar.isNotEmpty) const SizedBox(height: 8),
              _AddSkillButton(
                label: 'Add skill',
                onTap: () => _addOptional(_lowStar, 1),
              ),
            ],
          ],
        ),
      ],
    );
  }
}

class _TierCard extends StatelessWidget {
  const _TierCard({
    required this.badge,
    required this.title,
    required this.subtitle,
    required this.children,
  });

  final Widget badge;
  final String title;
  final String subtitle;
  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: kWhite,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: kBorderColorTextField.withValues(alpha: 0.6)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              badge,
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  title,
                  style: kTextStyle.copyWith(
                    color: kNeutralColor,
                    fontWeight: FontWeight.bold,
                    fontSize: 15,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 4),
          Text(
            subtitle,
            style: kTextStyle.copyWith(color: kLightNeutralColor, fontSize: 12),
          ),
          if (children.isNotEmpty) ...[
            const SizedBox(height: 12),
            ...children,
          ],
        ],
      ),
    );
  }
}

class _AddSkillButton extends StatelessWidget {
  const _AddSkillButton({required this.label, required this.onTap});

  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return OutlinedButton.icon(
      onPressed: onTap,
      icon: const Icon(Icons.add, size: 18),
      label: Text(label),
      style: OutlinedButton.styleFrom(
        foregroundColor: kPrimaryColor,
        side: BorderSide(color: kPrimaryColor.withValues(alpha: 0.4)),
        minimumSize: const Size(double.infinity, 44),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      ),
    );
  }
}

class _SkillRow {
  _SkillRow({
    required this.name,
    required this.stars,
    this.isCustom = false,
  });

  String? name;
  int stars;
  bool isCustom;
}
