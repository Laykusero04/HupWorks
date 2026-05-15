import 'package:flutter/material.dart';
import 'package:freelancer/services/category_service.dart';

import 'constant.dart';

/// Searchable category list for job posts (preset + “Add category (not listed)”).
class CategoryPickerField extends StatefulWidget {
  const CategoryPickerField({
    super.key,
    required this.categories,
    required this.selectedCategoryId,
    required this.onSelected,
    this.isLoading = false,
  });

  final List<Map<String, dynamic>> categories;
  final String? selectedCategoryId;
  final ValueChanged<String?> onSelected;
  final bool isLoading;

  @override
  State<CategoryPickerField> createState() => _CategoryPickerFieldState();
}

class _CategoryPickerFieldState extends State<CategoryPickerField> {
  final _searchController = TextEditingController();
  String _query = '';

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  List<Map<String, dynamic>> get _filtered {
    final q = _query.trim().toLowerCase();
    if (q.isEmpty) return widget.categories;
    return widget.categories
        .where((c) => ((c['name'] as String?) ?? '').toLowerCase().contains(q))
        .toList();
  }

  String? get _selectedName {
    final id = widget.selectedCategoryId;
    if (id == null || id == CategoryService.otherCategoryOptionId) return null;
    for (final c in widget.categories) {
      if (c['id'] == id) return c['name'] as String?;
    }
    return null;
  }

  @override
  Widget build(BuildContext context) {
    if (widget.isLoading) {
      return const Center(child: CircularProgressIndicator(color: kPrimaryColor));
    }

    final filtered = _filtered;
    final selectedName = _selectedName;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(
          'Category *',
          style: kTextStyle.copyWith(color: kNeutralColor, fontWeight: FontWeight.bold),
        ),
        if (selectedName != null) ...[
          const SizedBox(height: 8),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
            decoration: BoxDecoration(
              color: kPrimaryColor.withValues(alpha: 0.08),
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: kPrimaryColor.withValues(alpha: 0.25)),
            ),
            child: Row(
              children: [
                const Icon(Icons.check_circle_outline, size: 18, color: kPrimaryColor),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    selectedName,
                    style: kTextStyle.copyWith(
                      color: kNeutralColor,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
        const SizedBox(height: 10),
        TextField(
          controller: _searchController,
          onChanged: (v) => setState(() => _query = v),
          cursorColor: kNeutralColor,
          decoration: kInputDecoration.copyWith(
            hintText: 'Search categories',
            hintStyle: kTextStyle.copyWith(color: kSubTitleColor),
            prefixIcon: const Icon(Icons.search, color: kLightNeutralColor),
            suffixIcon: _query.isEmpty
                ? null
                : IconButton(
                    icon: const Icon(Icons.clear, color: kLightNeutralColor),
                    onPressed: () {
                      _searchController.clear();
                      setState(() => _query = '');
                    },
                  ),
            border: const OutlineInputBorder(),
            contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
          ),
        ),
        const SizedBox(height: 8),
        Container(
          constraints: const BoxConstraints(maxHeight: 220),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: kBorderColorTextField, width: 2),
          ),
          child: filtered.isEmpty && _query.isNotEmpty
              ? Padding(
                  padding: const EdgeInsets.all(16),
                  child: Text(
                    'No categories match "$_query".',
                    style: kTextStyle.copyWith(color: kSubTitleColor, fontSize: 13),
                  ),
                )
              : ListView(
                  shrinkWrap: true,
                  children: [
                    ...filtered.map((cat) {
                      final id = cat['id'] as String?;
                      final name = cat['name'] as String? ?? '';
                      final selected = widget.selectedCategoryId == id;
                      return InkWell(
                        onTap: () => widget.onSelected(id),
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 11),
                          color: selected
                              ? kPrimaryColor.withValues(alpha: 0.07)
                              : null,
                          child: Row(
                            children: [
                              Icon(
                                selected
                                    ? Icons.radio_button_checked
                                    : Icons.radio_button_unchecked,
                                size: 20,
                                color: selected ? kPrimaryColor : kLightNeutralColor,
                              ),
                              const SizedBox(width: 10),
                              Expanded(
                                child: Text(
                                  name,
                                  style: kTextStyle.copyWith(
                                    color: kNeutralColor,
                                    fontWeight:
                                        selected ? FontWeight.w600 : FontWeight.normal,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      );
                    }),
                    InkWell(
                      onTap: () =>
                          widget.onSelected(CategoryService.otherCategoryOptionId),
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 11),
                        decoration: const BoxDecoration(
                          border: Border(top: BorderSide(color: kBorderColorTextField)),
                        ),
                        color: widget.selectedCategoryId ==
                                CategoryService.otherCategoryOptionId
                            ? kPrimaryColor.withValues(alpha: 0.07)
                            : null,
                        child: Row(
                          children: [
                            Icon(
                              widget.selectedCategoryId ==
                                      CategoryService.otherCategoryOptionId
                                  ? Icons.radio_button_checked
                                  : Icons.radio_button_unchecked,
                              size: 20,
                              color: widget.selectedCategoryId ==
                                      CategoryService.otherCategoryOptionId
                                  ? kPrimaryColor
                                  : kLightNeutralColor,
                            ),
                            const SizedBox(width: 10),
                            Expanded(
                              child: Text(
                                'Add category (not listed)',
                                style: kTextStyle.copyWith(
                                  color: kNeutralColor,
                                  fontWeight: widget.selectedCategoryId ==
                                          CategoryService.otherCategoryOptionId
                                      ? FontWeight.w600
                                      : FontWeight.normal,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
        ),
      ],
    );
  }
}
