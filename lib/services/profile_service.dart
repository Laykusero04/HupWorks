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

  static double? parseRatingValue(dynamic value) {
    if (value is num) return value.toDouble();
    if (value is String) return double.tryParse(value.trim());
    return null;
  }

  static int ratingAsStars(dynamic value) {
    final v = parseRatingValue(value);
    if (v == null) return 0;
    return v.round().clamp(0, 5);
  }

  /// Average rating from review rows (e.g. [getReviewsReceived]).
  static double averageFromReviewRows(List<Map<String, dynamic>> reviews) {
    if (reviews.isEmpty) return 0;
    var sum = 0.0;
    var n = 0;
    for (final r in reviews) {
      final v = parseRatingValue(r['rating']);
      if (v != null) {
        sum += v;
        n++;
      }
    }
    if (n == 0) return 0;
    return double.parse((sum / n).toStringAsFixed(1));
  }

  /// Prefer live [reviews] when profile summary is missing or zero.
  static ({double rating, int count}) resolveReviewDisplay({
    required Map<String, dynamic>? profile,
    required List<Map<String, dynamic>> reviews,
  }) {
    var count = (profile?['review_count'] as num?)?.toInt() ?? 0;
    var rating = parseRatingValue(profile?['rating']) ?? 0;

    if (reviews.isNotEmpty) {
      final fromRows = averageFromReviewRows(reviews);
      if (count <= 0) count = reviews.length;
      if (rating <= 0 && fromRows > 0) rating = fromRows;
    }

    return (rating: rating, count: count);
  }

  /// Batch-merge live review averages into profile maps (Talent / Top Freelancers).
  static Future<List<Map<String, dynamic>>> enrichProfilesWithReviewStats(
    List<Map<String, dynamic>> profiles,
  ) async {
    if (profiles.isEmpty) return profiles;

    final ids = profiles
        .map((p) => p['id']?.toString())
        .whereType<String>()
        .where((id) => id.isNotEmpty)
        .toList();
    if (ids.isEmpty) return profiles;

    final rows = await _client.from('reviews').select('reviewed_id, rating').inFilter('reviewed_id', ids);

    final stats = <String, ({double sum, int count})>{};
    for (final raw in rows as List<dynamic>) {
      final r = Map<String, dynamic>.from(raw as Map);
      final id = r['reviewed_id']?.toString();
      final v = parseRatingValue(r['rating']);
      if (id == null || v == null) continue;
      final prev = stats[id];
      stats[id] = prev == null ? (sum: v, count: 1) : (sum: prev.sum + v, count: prev.count + 1);
    }

    final enriched = profiles.map((p) {
      final copy = Map<String, dynamic>.from(p);
      final id = p['id']?.toString();
      final s = id != null ? stats[id] : null;
      if (s != null && s.count > 0) {
        copy['rating'] = double.parse((s.sum / s.count).toStringAsFixed(1));
        copy['review_count'] = s.count;
      }
      return copy;
    }).toList();

    enriched.sort((a, b) {
      final ra = parseRatingValue(a['rating']) ?? 0;
      final rb = parseRatingValue(b['rating']) ?? 0;
      return rb.compareTo(ra);
    });

    return enriched;
  }

  /// Persists computed rating on `profiles` (seller only — RLS allows self-update).
  static Future<void> syncReviewStatsToProfile(String profileId) async {
    final stats = await _reviewStatsForProfile(profileId);
    final rating = stats.count > 0
        ? double.parse((stats.sum / stats.count).toStringAsFixed(1))
        : 0.0;

    try {
      await _client.from('profiles').update({'rating': rating}).eq('id', profileId);
    } catch (_) {
      // Client cannot update another user's profile; enrichment handles public UI.
    }

    final user = _client.auth.currentUser;
    if (user != null && user.id == profileId && _profileCache != null) {
      _profileCache!['rating'] = rating;
      _profileCache!['review_count'] = stats.count;
    }
  }

  /// Loads `rating` values where this user is the person being reviewed.
  static Future<({double sum, int count})> _reviewStatsForProfile(String profileId) async {
    final rows = await _client.from('reviews').select('rating').eq('reviewed_id', profileId);
    final list = (rows as List<dynamic>).map((e) => Map<String, dynamic>.from(e as Map)).toList();
    if (list.isEmpty) return (sum: 0.0, count: 0);
    var sum = 0.0;
    var n = 0;
    for (final r in list) {
      final v = parseRatingValue(r['rating']);
      if (v != null) {
        sum += v;
        n++;
      }
    }
    if (n == 0) return (sum: 0.0, count: list.length);
    return (sum: sum, count: n);
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

    final Map<String, dynamic> profile;
    if (!forceRefresh && _cacheUserId == user.id && _profileCache != null) {
      profile = Map<String, dynamic>.from(_profileCache!);
    } else {
      final data = await _client.from('profiles').select().eq('id', user.id).single();
      profile = Map<String, dynamic>.from(data);
    }

    final stats = await _reviewStatsForProfile(user.id);
    profile['review_count'] = stats.count;
    if (stats.count > 0) {
      final avg = stats.sum / stats.count;
      profile['rating'] = double.parse(avg.toStringAsFixed(1));
      try {
        await _client
            .from('profiles')
            .update({'rating': profile['rating']})
            .eq('id', user.id);
      } catch (_) {}
    } else {
      profile['rating'] = parseRatingValue(profile['rating']) ?? 0.0;
    }

    _profileCache = Map<String, dynamic>.from(profile);
    _cacheUserId = user.id;
    return Map<String, dynamic>.from(profile);
  }

  /// Live review stats for any profile (client or seller).
  static Future<({double rating, int reviewCount})> getReviewStats(
    String profileId,
  ) async {
    final stats = await _reviewStatsForProfile(profileId);
    if (stats.count <= 0) {
      return (rating: 0.0, reviewCount: 0);
    }
    return (
      rating: double.parse((stats.sum / stats.count).toStringAsFixed(1)),
      reviewCount: stats.count,
    );
  }

  /// Public client profile for sellers (find jobs, job details).
  static Future<Map<String, dynamic>?> getPublicClientProfile(
    String clientId,
  ) async {
    final data = await _client
        .from('profiles')
        .select(
          'id, role, name, email, phone, country, city, gender, '
          'profile_image_url, bio, rating, created_at',
        )
        .eq('id', clientId)
        .eq('role', 'client')
        .maybeSingle();
    if (data == null) return null;

    final profile = Map<String, dynamic>.from(data);
    final reviewStats = await getReviewStats(clientId);
    profile['review_count'] = reviewStats.reviewCount;
    profile['rating'] = reviewStats.reviewCount > 0
        ? reviewStats.rating
        : (parseRatingValue(profile['rating']) ?? 0.0);

    final jobs = await _client
        .from('job_posts')
        .select('id')
        .eq('client_id', clientId);
    profile['job_posts_count'] = (jobs as List).length;

    return profile;
  }

  /// Public seller profile for clients (Talent browse, service details).
  static Future<Map<String, dynamic>?> getPublicSellerProfile(String sellerId) async {
    final data = await _client
        .from('profiles')
        .select('*, seller_profiles(*)')
        .eq('id', sellerId)
        .eq('role', 'seller')
        .maybeSingle();
    if (data == null) return null;

    final profile = Map<String, dynamic>.from(data);
    final stats = await _reviewStatsForProfile(sellerId);
    profile['review_count'] = stats.count;
    if (stats.count > 0) {
      profile['rating'] = double.parse((stats.sum / stats.count).toStringAsFixed(1));
    } else {
      profile['rating'] = parseRatingValue(profile['rating']) ?? 0.0;
    }
    return profile;
  }

  static String? sellerAboutFromProfile(Map<String, dynamic> profile) {
    final sp = profile['seller_profiles'];
    if (sp is Map<String, dynamic>) {
      final a = sp['about'] as String?;
      return a?.trim().isEmpty == true ? null : a?.trim();
    }
    if (sp is List && sp.isNotEmpty && sp.first is Map<String, dynamic>) {
      final a = (sp.first as Map<String, dynamic>)['about'] as String?;
      return a?.trim().isEmpty == true ? null : a?.trim();
    }
    return null;
  }

  static List<String> sellerSkillsFromProfile(Map<String, dynamic> profile) {
    final sp = profile['seller_profiles'];
    Map<String, dynamic>? row;
    if (sp is Map<String, dynamic>) {
      row = sp;
    } else if (sp is List && sp.isNotEmpty && sp.first is Map<String, dynamic>) {
      row = sp.first as Map<String, dynamic>;
    }
    if (row == null) return const [];
    final skills = row['skills'];
    if (skills is List) {
      return skills.map((e) => e.toString()).where((s) => s.isNotEmpty).toList();
    }
    return const [];
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
