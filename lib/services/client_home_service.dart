import 'package:supabase_flutter/supabase_flutter.dart';

class ClientHomeService {
  static final _client = Supabase.instance.client;

  /// Fetch current user profile (name, balance, profile image)
  static Future<Map<String, dynamic>?> getUserProfile() async {
    final user = _client.auth.currentUser;
    if (user == null) return null;

    final data = await _client
        .from('profiles')
        .select()
        .eq('id', user.id)
        .single();
    return data;
  }

  /// Fetch all categories
  static Future<List<Map<String, dynamic>>> getCategories() async {
    final data = await _client
        .from('categories')
        .select()
        .order('name');
    return List<Map<String, dynamic>>.from(data);
  }

  /// Fetch popular/trending services (sorted by rating, limited)
  static Future<List<Map<String, dynamic>>> getPopularServices({int limit = 10}) async {
    final data = await _client
        .from('services')
        .select('*, profiles!seller_id(name, profile_image_url)')
        .eq('status', 'active')
        .order('rating', ascending: false)
        .order('review_count', ascending: false)
        .limit(limit);
    return List<Map<String, dynamic>>.from(data);
  }

  /// Fetch top sellers (sorted by rating)
  static Future<List<Map<String, dynamic>>> getTopSellers({int limit = 10}) async {
    final data = await _client
        .from('profiles')
        .select('*, seller_profiles!inner(*)')
        .eq('role', 'seller')
        .order('rating', ascending: false)
        .limit(limit);
    return List<Map<String, dynamic>>.from(data);
  }

  /// Search services by query
  static Future<List<Map<String, dynamic>>> searchServices(String query) async {
    final data = await _client
        .from('services')
        .select('*, profiles!seller_id(name, profile_image_url)')
        .eq('status', 'active')
        .ilike('title', '%$query%')
        .order('rating', ascending: false)
        .limit(20);
    return List<Map<String, dynamic>>.from(data);
  }
}
