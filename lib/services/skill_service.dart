import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:freelancer/core/utils/localized_category.dart';

/// Preset trade/labor skills from [skill_catalog] (factory worker, plumber, etc.).
abstract final class SkillService {
  static final _client = Supabase.instance.client;

  /// Active skills for pickers, grouped by category name then sort order.
  static Future<List<Map<String, dynamic>>> listForPicker() async {
    final data = await _client
        .from('skill_catalog')
        .select('id, name, sort_order, categories(name, name_i18n)')
        .eq('is_active', true)
        .order('sort_order')
        .order('name');
    return List<Map<String, dynamic>>.from(data);
  }

  static String? categoryName(
    Map<String, dynamic> skill, {
    String languageCode = 'en',
  }) {
    final cat = skill['categories'];
    if (cat is Map<String, dynamic>) {
      return LocalizedCategory.name(cat, languageCode);
    }
    return null;
  }
}
