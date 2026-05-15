import 'dart:io';
import 'package:supabase_flutter/supabase_flutter.dart';

class ProfileService {
  static final _client = Supabase.instance.client;

  /// In-memory copy of the last [getProfile] result for the signed-in user.
  ///
  /// [Scaffold.drawer] disposes its child while closed on mobile, so the drawer
  /// profile widget is recreated on each open; caching avoids a blank skeleton
  /// and duplicate network calls.
  static Map<String, dynamic>? _profileCache;
  static String? _cacheUserId;

  static void clearProfileCache() {
    _profileCache = null;
    _cacheUserId = null;
  }

  /// Synchronous read of cached profile for the current session (same user id).
  static Map<String, dynamic>? peekCachedProfile() {
    final user = _client.auth.currentUser;
    if (user == null || _cacheUserId != user.id || _profileCache == null) {
      return null;
    }
    return Map<String, dynamic>.from(_profileCache!);
  }

  /// Loads `rating` values where this user is the person being reviewed.
  static Future<({double sum, int count})> _reviewStatsForProfile(String profileId) async {
    final rows = await _client.from('reviews').select('rating').eq('reviewed_id', profileId);
    final list = (rows as List<dynamic>).map((e) => Map<String, dynamic>.from(e as Map)).toList();
    if (list.isEmpty) return (sum: 0.0, count: 0);
    var sum = 0.0;
    for (final r in list) {
      final v = r['rating'];
      if (v is num) sum += v.toDouble();
    }
    return (sum: sum, count: list.length);
  }

  /// Fetch current user's profile.
  ///
  /// Merges live [reviews] stats: when there is at least one review, `rating` is
  /// the average (1 decimal); otherwise the `profiles.rating` column is kept.
  /// Adds `review_count` (may be 0).
  ///
  /// When [forceRefresh] is false and a cache exists for the current user,
  /// returns the cache without hitting the network.
  static Future<Map<String, dynamic>?> getProfile({bool forceRefresh = false}) async {
    final user = _client.auth.currentUser;
    if (user == null) return null;

    if (!forceRefresh && _cacheUserId == user.id && _profileCache != null) {
      return Map<String, dynamic>.from(_profileCache!);
    }

    final data = await _client.from('profiles').select().eq('id', user.id).single();
    final profile = Map<String, dynamic>.from(data);

    final stats = await _reviewStatsForProfile(user.id);
    profile['review_count'] = stats.count;
    if (stats.count > 0) {
      final avg = stats.sum / stats.count;
      profile['rating'] = double.parse(avg.toStringAsFixed(1));
    } else {
      final existing = profile['rating'];
      profile['rating'] = existing is num ? existing.toDouble() : 0.0;
    }

    _profileCache = profile;
    _cacheUserId = user.id;
    return profile;
  }

  /// Reviews written about [profileId], newest first (includes reviewer display name).
  static Future<List<Map<String, dynamic>>> getReviewsReceived(String profileId) async {
    final rows = await _client
        .from('reviews')
        .select(
          'id, rating, comment, created_at, '
          'reviewer:profiles!reviews_reviewer_id_fkey(name, profile_image_url)',
        )
        .eq('reviewed_id', profileId)
        .order('created_at', ascending: false)
        .limit(50);
    return (rows as List<dynamic>).map((e) => Map<String, dynamic>.from(e as Map)).toList();
  }

  /// Update profile fields
  static Future<void> updateProfile(Map<String, dynamic> updates) async {
    final user = _client.auth.currentUser;
    if (user == null) throw Exception('Not logged in');

    await _client.from('profiles').update(updates).eq('id', user.id);
    if (_profileCache != null && _cacheUserId == user.id) {
      _profileCache!.addAll(updates);
    }
  }

  /// Upload profile image and update profile_image_url
  static Future<String> uploadProfileImage(File imageFile) async {
    final user = _client.auth.currentUser;
    if (user == null) throw Exception('Not logged in');

    final ext = imageFile.path.split('.').last;
    final path = '${user.id}/avatar.$ext';

    await _client.storage.from('avatars').upload(
      path,
      imageFile,
      fileOptions: const FileOptions(upsert: true),
    );

    final imageUrl = _client.storage.from('avatars').getPublicUrl(path);

    await _client.from('profiles').update({
      'profile_image_url': imageUrl,
    }).eq('id', user.id);

    if (_profileCache != null && _cacheUserId == user.id) {
      _profileCache!['profile_image_url'] = imageUrl;
    }

    return imageUrl;
  }
}
