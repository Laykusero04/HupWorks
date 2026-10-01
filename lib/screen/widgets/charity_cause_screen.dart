import 'package:flutter/material.dart';
import 'package:freelancer/core/charity/charity_cause.dart';
import 'package:freelancer/l10n/l10n.dart';
import 'package:freelancer/services/charity_cause_service.dart';

import 'constant.dart';

String charityCauseShareValue(AppLocalizations l10n, String? cause) {
  switch (CharityCause.normalize(cause)) {
    case CharityCause.food:
      return l10n.charityCauseFood;
    case CharityCause.education:
      return l10n.charityCauseEducation;
    case CharityCause.health:
      return l10n.charityCauseHealth;
    case CharityCause.shelter:
      return l10n.charityCauseShelter;
    default:
      return l10n.charityCauseShareEmpty;
  }
}

/// Cause linked to the signed-in person's platform share.
class CharityCauseScreen extends StatefulWidget {
  const CharityCauseScreen({super.key, this.initialCause});

  final String? initialCause;

  @override
  State<CharityCauseScreen> createState() => _CharityCauseScreenState();
}

class _CharityCauseScreenState extends State<CharityCauseScreen> {
  String? _selected;
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    _selected = CharityCause.normalize(widget.initialCause);
  }

  Future<void> _choose(String? cause) async {
    if (_saving || cause == _selected) {
      if (cause == _selected && mounted) Navigator.pop(context, cause ?? '');
      return;
    }
    final previous = _selected;
    setState(() {
      _saving = true;
      _selected = cause;
    });
    try {
      await CharityCauseService.save(cause);
      if (!mounted) return;
      Navigator.pop(context, cause ?? '');
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _saving = false;
        _selected = previous;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(context.l10n.errorWithDetail('$e'))),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final options = <({String? id, String title, String hint, IconData icon})>[
      (
        id: null,
        title: l10n.charityCauseNone,
        hint: l10n.charityCauseNoneHint,
        icon: Icons.do_not_disturb_on_outlined,
      ),
      (
        id: CharityCause.food,
        title: l10n.charityCauseFood,
        hint: l10n.charityCauseFoodHint,
        icon: Icons.restaurant_outlined,
      ),
      (
        id: CharityCause.education,
        title: l10n.charityCauseEducation,
        hint: l10n.charityCauseEducationHint,
        icon: Icons.school_outlined,
      ),
      (
        id: CharityCause.health,
        title: l10n.charityCauseHealth,
        hint: l10n.charityCauseHealthHint,
        icon: Icons.favorite_outline,
      ),
      (
        id: CharityCause.shelter,
        title: l10n.charityCauseShelter,
        hint: l10n.charityCauseShelterHint,
        icon: Icons.home_outlined,
      ),
    ];

    return Scaffold(
      backgroundColor: kDarkWhite,
      appBar: AppBar(
        backgroundColor: kDarkWhite,
        elevation: 0,
        iconTheme: const IconThemeData(color: kNeutralColor),
        title: Text(
          l10n.charityCauseTitle,
          style: kTextStyle.copyWith(
            color: kNeutralColor,
            fontWeight: FontWeight.bold,
          ),
        ),
        centerTitle: true,
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 28),
        children: [
          Text(
            l10n.charityCauseHeadline,
            style: kTextStyle.copyWith(
              color: kNeutralColor,
              fontSize: 16,
              height: 1.4,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            l10n.charityCauseBody,
            style: kTextStyle.copyWith(
              color: kSubTitleColor,
              fontSize: 13,
              height: 1.4,
            ),
          ),
          const SizedBox(height: 16),
          for (final option in options) ...[
            _CauseTile(
              title: option.title,
              hint: option.hint,
              icon: option.icon,
              selected: _selected == option.id,
              enabled: !_saving,
              onTap: () => _choose(option.id),
            ),
            const SizedBox(height: 10),
          ],
        ],
      ),
    );
  }
}

class _CauseTile extends StatelessWidget {
  const _CauseTile({
    required this.title,
    required this.hint,
    required this.icon,
    required this.selected,
    required this.enabled,
    required this.onTap,
  });

  final String title;
  final String hint;
  final IconData icon;
  final bool selected;
  final bool enabled;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: kWhite,
      borderRadius: BorderRadius.circular(16),
      child: InkWell(
        onTap: enabled ? onTap : null,
        borderRadius: BorderRadius.circular(16),
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Icon(
                icon,
                color: selected ? kPrimaryColor : kNeutralColor,
                size: 22,
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: kTextStyle.copyWith(
                        color: kNeutralColor,
                        fontWeight: FontWeight.w600,
                        fontSize: 15,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      hint,
                      style: kTextStyle.copyWith(
                        color: kSubTitleColor,
                        fontSize: 12,
                        height: 1.35,
                      ),
                    ),
                  ],
                ),
              ),
              Icon(
                selected ? Icons.check_circle : Icons.circle_outlined,
                color: selected ? kPrimaryColor : kLightNeutralColor,
                size: 20,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
