import 'package:freelancer/core/utils/category_name.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

/// Sentinel dropdown value for “add category not in the list”.
abstract final class CategoryService {
  static const otherCategoryOptionId = '__other_category__';

  static final _client = Supabase.instance.client;

  /// Lists categories for pickers (preset + client-added).
  static Future<List<Map<String, dynamic>>> listForPicker() async {
    final data = await _client
        .from('categories')
        .select('id, name, is_custom')
        .order('is_custom')
        .order('name');
    return List<Map<String, dynamic>>.from(data);
  }

  /// Resolves a preset [selectedCategoryId] or creates/reuses a normalized custom name.
  static Future<String> resolveCategoryId({
    required String? selectedCategoryId,
    String? customCategoryRaw,
  }) async {
    if (selectedCategoryId != null &&
        selectedCategoryId.isNotEmpty &&
        selectedCategoryId != otherCategoryOptionId) {
      return selectedCategoryId;
    }

    if (customCategoryRaw == null || customCategoryRaw.trim().isEmpty) {
      throw Exception('Select a category or add one that is not listed');
    }

    final name = CategoryName.normalize(customCategoryRaw);
    return findOrCreateByName(name);
  }

  /// Finds an existing row (case-insensitive) or inserts a client custom category.
  static Future<String> findOrCreateByName(String normalizedName) async {
    final existing = await _client
        .from('categories')
        .select('id')
        .ilike('name', normalizedName)
        .maybeSingle();

    if (existing != null) {
      return existing['id'] as String;
    }

    final user = _client.auth.currentUser;
    if (user == null) throw Exception('Not logged in');

    try {
      final inserted = await _client
          .from('categories')
          .insert({
            'name': normalizedName,
            'icon': 'custom',
            'description': 'Added by a client',
            'is_custom': true,
            'created_by': user.id,
          })
          .select('id')
          .single();
      return inserted['id'] as String;
    } catch (_) {
      // Unique index race: another request inserted the same name.
      final retry = await _client
          .from('categories')
          .select('id')
          .ilike('name', normalizedName)
          .maybeSingle();
      if (retry != null) return retry['id'] as String;
      rethrow;
    }
  }
}
