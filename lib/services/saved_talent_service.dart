import 'package:supabase_flutter/supabase_flutter.dart';

import 'profile_service.dart';

/// Client/employer saved freelancers (`saved_sellers.seller_id`).
class SavedTalentService {
  static final _client = Supabase.instance.client;

  static Future<bool> isSaved(String sellerId) async {
    final user = _client.auth.currentUser;
    if (user == null) return false;

    final data = await _client
        .from('saved_sellers')
        .select('id')
        .eq('client_id', user.id)
        .eq('seller_id', sellerId)
        .maybeSingle();

    return data != null;
  }

  /// Returns `true` if the seller is saved after the toggle.
  static Future<bool> toggle(String sellerId) async {
    final user = _client.auth.currentUser;
    if (user == null) return false;
    if (sellerId == user.id) return false;

    final existing = await _client
        .from('saved_sellers')
        .select('id')
        .eq('client_id', user.id)
        .eq('seller_id', sellerId)
        .maybeSingle();

    if (existing != null) {
      await _client
          .from('saved_sellers')
          .delete()
          .eq('client_id', user.id)
          .eq('seller_id', sellerId);
      return false;
    }

    await _client.from('saved_sellers').insert({
      'client_id': user.id,
      'seller_id': sellerId,
    });
    return true;
  }

  static Future<List<Map<String, dynamic>>> getSaved() async {
    final user = _client.auth.currentUser;
    if (user == null) return [];

    final data = await _client
        .from('saved_sellers')
        .select(
          'id, client_id, seller_id, created_at, '
          'seller:profiles!seller_id('
          'id, name, profile_image_url, country, city, rating, '
          'seller_profiles(job_title, about, skills)'
          ')',
        )
        .eq('client_id', user.id)
        .order('created_at', ascending: false);

    final rows = List<Map<String, dynamic>>.from(data);
    final sellers = <Map<String, dynamic>>[];
    for (final row in rows) {
      final seller = row['seller'];
      if (seller is Map<String, dynamic>) {
        sellers.add(seller);
      } else if (seller is Map) {
        sellers.add(Map<String, dynamic>.from(seller));
      }
    }

    if (sellers.isEmpty) return rows;

    final enriched = await ProfileService.enrichProfilesWithReviewStats(sellers);
    final byId = <String, Map<String, dynamic>>{
      for (final s in enriched)
        if (s['id'] is String) s['id'] as String: s,
    };

    return rows.map((row) {
      final seller = row['seller'];
      final id = seller is Map ? seller['id'] as String? : null;
      if (id != null && byId.containsKey(id)) {
        return {...row, 'seller': byId[id]};
      }
      return row;
    }).toList();
  }

  static Future<void> remove(String savedId) async {
    await _client.from('saved_sellers').delete().eq('id', savedId);
  }

  /// Seller IDs the current client has saved (for list/card badges).
  static Future<Set<String>> getSavedSellerIds() async {
    final user = _client.auth.currentUser;
    if (user == null) return {};

    final data = await _client
        .from('saved_sellers')
        .select('seller_id')
        .eq('client_id', user.id);

    return {
      for (final row in List<Map<String, dynamic>>.from(data))
        if (row['seller_id'] is String) row['seller_id'] as String,
    };
  }
}
