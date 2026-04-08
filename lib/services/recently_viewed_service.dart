import 'package:shared_preferences/shared_preferences.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class RecentlyViewedService {
  static const _key = 'recently_viewed_service_ids';
  static const _maxItems = 20;
  static final _client = Supabase.instance.client;

  /// Add a service ID to recently viewed list
  static Future<void> addServiceId(String serviceId) async {
    final prefs = await SharedPreferences.getInstance();
    final ids = prefs.getStringList(_key) ?? [];

    // Remove if already exists (to move to front)
    ids.remove(serviceId);
    // Add to front
    ids.insert(0, serviceId);
    // Trim to max
    if (ids.length > _maxItems) {
      ids.removeRange(_maxItems, ids.length);
    }

    await prefs.setStringList(_key, ids);
  }

  /// Get recently viewed service IDs
  static Future<List<String>> getServiceIds() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getStringList(_key) ?? [];
  }

  /// Fetch recently viewed services with full data from Supabase
  static Future<List<Map<String, dynamic>>> getRecentlyViewedServices({int limit = 10}) async {
    final ids = await getServiceIds();
    if (ids.isEmpty) return [];

    final idsToFetch = ids.take(limit).toList();

    final data = await _client
        .from('services')
        .select('*, profiles!seller_id(name, profile_image_url)')
        .inFilter('id', idsToFetch)
        .eq('status', 'active');

    final results = List<Map<String, dynamic>>.from(data);

    // Sort results to match the order in idsToFetch
    results.sort((a, b) {
      final indexA = idsToFetch.indexOf(a['id']);
      final indexB = idsToFetch.indexOf(b['id']);
      return indexA.compareTo(indexB);
    });

    return results;
  }

  /// Clear recently viewed
  static Future<void> clear() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_key);
  }
}
