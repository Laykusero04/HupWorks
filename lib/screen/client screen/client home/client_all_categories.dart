import 'package:flutter/material.dart';
import 'package:freelancer/core/utils/category_icons.dart';
import 'package:freelancer/services/client_home_service.dart';

import '../../widgets/constant.dart';

class ClientAllCategories extends StatefulWidget {
  /// Pre-fills the search field (e.g. when opening from a category on home).
  final String? initialQuery;

  const ClientAllCategories({super.key, this.initialQuery});

  @override
  State<ClientAllCategories> createState() => _ClientAllCategoriesState();
}

class _ClientAllCategoriesState extends State<ClientAllCategories> {
  final _searchController = TextEditingController();
  List<Map<String, dynamic>> _categories = [];
  String _query = '';
  bool _loading = true;

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  List<Map<String, dynamic>> get _filtered {
    final q = _query.trim().toLowerCase();
    if (q.isEmpty) return _categories;
    return _categories
        .where((c) => ((c['name'] as String?) ?? '').toLowerCase().contains(q))
        .toList();
  }

  @override
  void initState() {
    super.initState();
    final initial = widget.initialQuery?.trim();
    if (initial != null && initial.isNotEmpty) {
      _query = initial;
      _searchController.text = initial;
    }
    _load();
  }

  Future<void> _load() async {
    try {
      final cats = await ClientHomeService.getCategories();
      if (mounted) {
        setState(() {
          _categories = cats;
          _loading = false;
        });
      }
    } catch (_) {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: kDarkWhite,
      appBar: AppBar(
        elevation: 0.0,
        backgroundColor: kDarkWhite,
        centerTitle: true,
        iconTheme: const IconThemeData(color: kNeutralColor),
        title: Text(
          'All Categories',
          style: kTextStyle.copyWith(color: kNeutralColor, fontWeight: FontWeight.bold),
        ),
      ),
      body: Padding(
        padding: const EdgeInsets.only(top: 15.0),
        child: Container(
          padding: const EdgeInsets.only(left: 15.0, right: 15),
          decoration: const BoxDecoration(
            color: kWhite,
            borderRadius: BorderRadius.only(
              topLeft: Radius.circular(30.0),
              topRight: Radius.circular(30.0),
            ),
          ),
          child: _loading
              ? const Center(child: CircularProgressIndicator(color: kPrimaryColor))
              : _categories.isEmpty
                  ? Center(
                      child: Text(
                        'No categories yet',
                        style: kTextStyle.copyWith(color: kLightNeutralColor),
                      ),
                    )
                  : Column(
                      children: [
                        Padding(
                          padding: const EdgeInsets.fromLTRB(0, 15, 0, 10),
                          child: TextField(
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
                            ),
                          ),
                        ),
                        Expanded(
                          child: _filtered.isEmpty
                              ? Center(
                                  child: Text(
                                    'No categories match your search',
                                    style: kTextStyle.copyWith(color: kLightNeutralColor),
                                  ),
                                )
                              : ListView.separated(
                      padding: const EdgeInsets.only(bottom: 24),
                      itemCount: _filtered.length,
                      separatorBuilder: (_, __) => const SizedBox(height: 10),
                      itemBuilder: (_, i) {
                        final cat = _filtered[i];
                        final name = cat['name'] as String? ?? '';
                        final desc = cat['description'] as String? ?? '';
                        final icon = cat['icon'] as String?;
                        final color = CategoryIcons.tintColor(i);

                        return Container(
                          padding: const EdgeInsets.all(14),
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(color: kBorderColorTextField),
                          ),
                          child: Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Container(
                                height: 44,
                                width: 44,
                                decoration: BoxDecoration(
                                  color: color.withValues(alpha: 0.12),
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: Icon(
                                  CategoryIcons.iconData(icon),
                                  color: color,
                                  size: 24,
                                ),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      name,
                                      style: kTextStyle.copyWith(
                                        color: kNeutralColor,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                    if (desc.isNotEmpty) ...[
                                      const SizedBox(height: 4),
                                      Text(
                                        desc,
                                        style: kTextStyle.copyWith(
                                          color: kSubTitleColor,
                                          fontSize: 12,
                                          height: 1.35,
                                        ),
                                      ),
                                    ],
                                  ],
                                ),
                              ),
                            ],
                          ),
                        );
                      },
                    ),
                        ),
                      ],
                    ),
        ),
      ),
    );
  }
}
