import 'package:supabase_flutter/supabase_flutter.dart';

/// Preset trade/labor skills from [skill_catalog] (factory worker, plumber, etc.).
abstract final class SkillService {
  static final _client = Supabase.instance.client;

  /// Active skills for pickers, grouped by category name then sort order.
  static Future<List<Map<String, dynamic>>> listForPicker() async {
    final data = await _client
        .from('skill_catalog')
        .select('id, name, sort_order, categories(name)')
        .eq('is_active', true)
        .order('sort_order')
        .order('name');
    return List<Map<String, dynamic>>.from(data);
  }

  static String? categoryName(Map<String, dynamic> skill) {
    final cat = skill['categories'];
    if (cat is Map<String, dynamic>) {
      return cat['name'] as String?;
    }
    return null;
  }
}
