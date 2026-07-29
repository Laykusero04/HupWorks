import 'package:flutter/material.dart';
import 'package:freelancer/l10n/l10n.dart';
import 'package:freelancer/services/skill_service.dart';

import 'constant.dart';

/// Opens the searchable skill list bottom sheet.
Future<void> showSkillPickerSheet({
  required BuildContext context,
  required List<Map<String, dynamic>> skills,
  required ValueChanged<String> onSelected,
  Set<String> excludedNames = const {},
  String title = 'Choose a skill',
  bool allowCustomSkill = true,
}) {
  return showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
    ),
    builder: (ctx) => _SkillPickerSheet(
      title: title,
      skills: skills,
      excludedNames: excludedNames,
      allowCustomSkill: allowCustomSkill,
      onSelected: (name) {
        Navigator.pop(ctx);
        onSelected(name);
      },
    ),
  );
}

Future<String?> showCustomSkillNameDialog(
  BuildContext context, {
  String? initialName,
  Set<String> excludedNames = const {},
}) async {
  final result = await showDialog<String>(
    context: context,
    builder: (ctx) => _CustomSkillNameDialog(initialName: initialName),
  );
  if (result == null || result.isEmpty) return null;
  if (excludedNames.contains(result.toLowerCase())) {
    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(context.l10n.skillAlreadyAdded(result))),
      );
    }
    return null;
  }
  return result;
}

class _CustomSkillNameDialog extends StatefulWidget {
  const _CustomSkillNameDialog({this.initialName});

  final String? initialName;

  @override
  State<_CustomSkillNameDialog> createState() => _CustomSkillNameDialogState();
}

class _CustomSkillNameDialogState extends State<_CustomSkillNameDialog> {
  late final TextEditingController _controller;

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController(text: widget.initialName?.trim() ?? '');
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _submit() {
    final name = _controller.text.trim();
    if (name.isEmpty) return;
    Navigator.pop(context, name);
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    return AlertDialog(
      title: Text(l10n.addCustomSkill, style: kTextStyle.copyWith(fontWeight: FontWeight.bold)),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'This skill is saved on your profile only — not added to the global list.',
            style: kTextStyle.copyWith(color: kLightNeutralColor, fontSize: 12),
          ),
          const SizedBox(height: 12),
          TextField(
            controller: _controller,
            autofocus: true,
            textCapitalization: TextCapitalization.words,
            decoration: kInputDecoration.copyWith(
              hintText: 'e.g. CNC Operator',
              border: const OutlineInputBorder(),
            ),
            onSubmitted: (_) => _submit(),
          ),
        ],
      ),
      actions: [
        TextButton(onPressed: () => Navigator.pop(context), child: Text(l10n.cancel)),
        FilledButton(onPressed: _submit, child: Text(l10n.add)),
      ],
    );
  }
}

class _SkillPickerSheet extends StatefulWidget {
  const _SkillPickerSheet({
    required this.title,
    required this.skills,
    required this.excludedNames,
    required this.onSelected,
    required this.allowCustomSkill,
  });

  final String title;
  final List<Map<String, dynamic>> skills;
  final Set<String> excludedNames;
  final ValueChanged<String> onSelected;
  final bool allowCustomSkill;

  @override
  State<_SkillPickerSheet> createState() => _SkillPickerSheetState();
}

class _SkillPickerSheetState extends State<_SkillPickerSheet> {
  final _searchController = TextEditingController();
  String _query = '';

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  List<Map<String, dynamic>> get _available {
    return widget.skills.where((s) {
      final name = (s['name'] as String? ?? '').trim();
      if (name.isEmpty) return false;
      return !widget.excludedNames.contains(name.toLowerCase());
    }).toList();
  }

  Map<String, List<Map<String, dynamic>>> get _grouped {
    final q = _query.trim().toLowerCase();
    final filtered = _available.where((s) {
      if (q.isEmpty) return true;
      final name = (s['name'] as String? ?? '').toLowerCase();
      final cat = (SkillService.categoryName(s) ?? '').toLowerCase();
      return name.contains(q) || cat.contains(q);
    }).toList();

    final groups = <String, List<Map<String, dynamic>>>{};
    for (final skill in filtered) {
      final cat = SkillService.categoryName(skill) ?? 'Other';
      groups.putIfAbsent(cat, () => []).add(skill);
    }

    final sortedKeys = groups.keys.toList()..sort();
    return {for (final k in sortedKeys) k: groups[k]!};
  }

  bool get _hasExactCatalogMatch {
    final q = _query.trim().toLowerCase();
    if (q.isEmpty) return false;
    return _available.any((s) => (s['name'] as String? ?? '').trim().toLowerCase() == q);
  }

  Future<void> _addCustom({String? prefilled}) async {
    final name = await showCustomSkillNameDialog(
      context,
      initialName: prefilled,
      excludedNames: widget.excludedNames,
    );
    if (!mounted) return;
    if (name != null && name.isNotEmpty) {
      widget.onSelected(name);
    }
  }

  @override
  Widget build(BuildContext context) {
    final groups = _grouped;
    final bottomInset = MediaQuery.viewInsetsOf(context).bottom;
    final query = _query.trim();
    final showQueryCustom = widget.allowCustomSkill &&
        query.isNotEmpty &&
        !_hasExactCatalogMatch &&
        !widget.excludedNames.contains(query.toLowerCase());

    return Padding(
      padding: EdgeInsets.only(bottom: bottomInset),
      child: DraggableScrollableSheet(
        expand: false,
        initialChildSize: 0.72,
        minChildSize: 0.4,
        maxChildSize: 0.92,
        builder: (context, scrollController) {
          return Column(
            children: [
              const SizedBox(height: 10),
              Container(
                width: 36,
                height: 4,
                decoration: BoxDecoration(
                  color: kBorderColorTextField,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 14, 20, 4),
                child: Text(
                  widget.title,
                  style: kTextStyle.copyWith(
                    color: kNeutralColor,
                    fontWeight: FontWeight.bold,
                    fontSize: 17,
                  ),
                ),
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 8, 20, 4),
                child: TextField(
                  controller: _searchController,
                  decoration: kInputDecoration.copyWith(
                    hintText: 'Search e.g. plumber, factory worker',
                    prefixIcon: const Icon(Icons.search, size: 20),
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                    contentPadding: const EdgeInsets.symmetric(vertical: 0),
                  ),
                  onChanged: (v) => setState(() => _query = v),
                ),
              ),
              Expanded(
                child: groups.isEmpty && !showQueryCustom
                    ? Center(
                        child: Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 24),
                          child: Text(
                            _query.isEmpty ? 'No preset skills loaded' : 'No match for "$_query"',
                            textAlign: TextAlign.center,
                            style: kTextStyle.copyWith(color: kLightNeutralColor),
                          ),
                        ),
                      )
                    : ListView(
                        controller: scrollController,
                        padding: const EdgeInsets.only(bottom: 8),
                        children: [
                          if (showQueryCustom)
                            ListTile(
                              leading: Icon(Icons.add_circle_outline, color: kPrimaryColor),
                              title: Text(
                                'Add "$query" to your profile',
                                style: kTextStyle.copyWith(
                                  color: kPrimaryColor,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                              subtitle: Text(
                                'Custom skill — not added to the global list',
                                style: kTextStyle.copyWith(color: kLightNeutralColor, fontSize: 11),
                              ),
                              onTap: () => _addCustom(prefilled: query),
                            ),
                          for (final entry in groups.entries) ...[
                            Padding(
                              padding: const EdgeInsets.fromLTRB(20, 14, 20, 4),
                              child: Text(
                                entry.key,
                                style: kTextStyle.copyWith(
                                  color: kPrimaryColor,
                                  fontWeight: FontWeight.w600,
                                  fontSize: 12,
                                ),
                              ),
                            ),
                            ...entry.value.map((skill) {
                              final name = skill['name'] as String? ?? '';
                              return ListTile(
                                dense: true,
                                title: Text(name, style: kTextStyle.copyWith(color: kSubTitleColor)),
                                onTap: () => widget.onSelected(name),
                              );
                            }),
                          ],
                        ],
                      ),
              ),
              if (widget.allowCustomSkill)
                Padding(
                  padding: const EdgeInsets.fromLTRB(20, 8, 20, 16),
                  child: OutlinedButton.icon(
                    onPressed: () => _addCustom(prefilled: query.isNotEmpty ? query : null),
                    icon: const Icon(Icons.edit_outlined, size: 18),
                    label: Text(context.l10n.addCustomSkill),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: kPrimaryColor,
                      minimumSize: const Size(double.infinity, 44),
                      side: BorderSide(color: kPrimaryColor.withValues(alpha: 0.4)),
                    ),
                  ),
                ),
            ],
          );
        },
      ),
    );
  }
}

/// Simple full-width row: tap to pick or change a skill.
class SkillSlotTile extends StatelessWidget {
  const SkillSlotTile({
    super.key,
    required this.index,
    required this.name,
    required this.onTap,
    this.onClear,
    this.trailing,
    this.isCustom = false,
  });

  final int index;
  final String? name;
  final VoidCallback onTap;
  final VoidCallback? onClear;
  final Widget? trailing;
  final bool isCustom;

  @override
  Widget build(BuildContext context) {
    final selected = name != null && name!.trim().isNotEmpty;
    return Material(
      color: selected ? kPrimaryColor.withValues(alpha: 0.06) : kDarkWhite,
      borderRadius: BorderRadius.circular(10),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(10),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(10),
            border: Border.all(
              color: selected ? kPrimaryColor.withValues(alpha: 0.35) : kBorderColorTextField,
            ),
          ),
          child: Row(
            children: [
              CircleAvatar(
                radius: 13,
                backgroundColor: selected ? kPrimaryColor : kBorderColorTextField.withValues(alpha: 0.5),
                child: Text(
                  '$index',
                  style: kTextStyle.copyWith(
                    color: selected ? kWhite : kLightNeutralColor,
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      selected ? name! : 'Tap to choose a skill',
                      style: kTextStyle.copyWith(
                        color: selected ? kNeutralColor : kLightNeutralColor,
                        fontWeight: selected ? FontWeight.w600 : FontWeight.normal,
                      ),
                    ),
                    if (selected && isCustom)
                      Text(
                        'Custom skill',
                        style: kTextStyle.copyWith(color: kLightNeutralColor, fontSize: 11),
                      ),
                  ],
                ),
              ),
              if (trailing != null) trailing!,
              if (selected && onClear != null)
                IconButton(
                  visualDensity: VisualDensity.compact,
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints(minWidth: 32, minHeight: 32),
                  onPressed: onClear,
                  icon: const Icon(Icons.close, size: 18, color: kLightNeutralColor),
                )
              else if (!selected)
                Icon(Icons.chevron_right, color: kLightNeutralColor.withValues(alpha: 0.8)),
            ],
          ),
        ),
      ),
    );
  }
}

/// Compact star badge for section headers.
class SkillTierBadge extends StatelessWidget {
  const SkillTierBadge({
    super.key,
    required this.filledStars,
    required this.totalStars,
  });

  final int filledStars;
  final int totalStars;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: List.generate(totalStars, (i) {
        return Icon(
          i < filledStars ? Icons.star_rounded : Icons.star_outline_rounded,
          size: 14,
          color: i < filledStars ? ratingBarColor : kBorderColorTextField,
        );
      }),
    );
  }
}

/// Inline 1–3 star picker for "learning" skills.
class LowStarPicker extends StatelessWidget {
  const LowStarPicker({
    super.key,
    required this.value,
    required this.onChanged,
  });

  final int value;
  final ValueChanged<int> onChanged;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: List.generate(3, (i) {
        final star = i + 1;
        final filled = value >= star;
        return GestureDetector(
          onTap: () => onChanged(star),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 1),
            child: Icon(
              filled ? Icons.star_rounded : Icons.star_outline_rounded,
              size: 20,
              color: filled ? ratingBarColor : kBorderColorTextField,
            ),
          ),
        );
      }),
    );
  }
}
