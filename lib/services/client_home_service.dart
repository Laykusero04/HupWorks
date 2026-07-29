import 'package:freelancer/services/profile_service.dart';
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
        .select(
          'id, name, profile_image_url, country, city, rating, '
          'seller_profiles!inner(job_title, about, skills)',
        )
        .eq('role', 'seller')
        .limit(limit * 3);
    final list = List<Map<String, dynamic>>.from(data);
    final enriched = await ProfileService.enrichProfilesWithReviewStats(list);
    if (enriched.length <= limit) return enriched;
    return enriched.sublist(0, limit);
  }

  /// Search services by query (title or description)
  static Future<List<Map<String, dynamic>>> searchServices(String query) async {
    final q = query.trim();
    if (q.isEmpty) return getPopularServices(limit: 20);

    final data = await _client
        .from('services')
        .select('*, profiles!seller_id(name, profile_image_url)')
        .eq('status', 'active')
        .or('title.ilike.%$q%,description.ilike.%$q%')
        .order('rating', ascending: false)
        .limit(20);
    return List<Map<String, dynamic>>.from(data);
  }

  /// Search sellers by name or job title.
  static Future<List<Map<String, dynamic>>> searchSellers(String query, {int limit = 20}) async {
    final q = query.trim();
    if (q.isEmpty) return getTopSellers(limit: limit);

    final byNameRaw = await _client
        .from('profiles')
        .select(
          'id, name, profile_image_url, country, city, rating, '
          'seller_profiles!inner(job_title, about, skills)',
        )
        .eq('role', 'seller')
        .ilike('name', '%$q%')
        .limit(limit);

    final byTitleRaw = await _client
        .from('seller_profiles')
        .select(
          'job_title, about, skills, '
          'profiles!inner(id, name, profile_image_url, country, city, rating, role)',
        )
        .ilike('job_title', '%$q%')
        .limit(limit);

    final byId = <String, Map<String, dynamic>>{};

    for (final row in List<Map<String, dynamic>>.from(byNameRaw)) {
      final id = row['id'] as String?;
      if (id != null) byId[id] = row;
    }

    for (final row in List<Map<String, dynamic>>.from(byTitleRaw)) {
      final profile = row['profiles'];
      if (profile is! Map) continue;
      final map = Map<String, dynamic>.from(profile);
      if (map['role'] != null && map['role'] != 'seller') continue;
      final id = map['id'] as String?;
      if (id == null || byId.containsKey(id)) continue;
      map['seller_profiles'] = {
        'job_title': row['job_title'],
        'about': row['about'],
        'skills': row['skills'],
      };
      byId[id] = map;
    }

    final list = byId.values.toList();
    final enriched = await ProfileService.enrichProfilesWithReviewStats(list);
    if (enriched.length <= limit) return enriched;
    return enriched.sublist(0, limit);
  }

  /// First active service for a seller (for deep-linking from talent browse).
  static Future<String?> getFirstActiveServiceIdForSeller(String sellerUserId) async {
    final data = await _client
        .from('services')
        .select('id')
        .eq('seller_id', sellerUserId)
        .eq('status', 'active')
        .order('rating', ascending: false)
        .limit(1)
        .maybeSingle();
    if (data == null) return null;
    return data['id'] as String?;
  }
}
